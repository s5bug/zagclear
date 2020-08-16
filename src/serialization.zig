const std = @import("std");

pub fn Deserializer(comptime endian: std.builtin.Endian, comptime packing: std.io.Packing, comptime ReaderType: type) type {
    return struct {
        arena: std.heap.ArenaAllocator,

        const Self = @This();

        const AdjReaderType = if (packing == .Bit) std.io.BitReader(endian, ReaderType) else ReaderType;

        pub fn init(alloc: *std.mem.Allocator) Self {
            return Self{ .arena = std.heap.ArenaAllocator.init(alloc) };
        }

        pub fn deinit(self: *Self) void {
            self.arena.deinit();
        }

        pub fn free(self: *Self, value: anytype) void {
            const T = @TypeOf(value);
            comptime assert(std.meta.trait.is(.Pointer)(T));

            const C = comptime meta.Child(T);
            const child_type_id = @typeInfo(C);

            switch (child_type_id) {
                .Struct => |info| {
                    inline for (info.fields) |field_info| {
                        const field_name = field_info.field_name;
                        const FieldType = field_info.field_type;

                        if (comptime trait.is(.Pointer)(FieldType)) {
                            self.free(&@field(value, field_name));
                        }
                    }
                },
                .Union => |info| {
                    if (info.tag_type) |TagType| {
                        @compileError("TODO");
                    } else {
                        inline for (info.fields) |field_info| {
                            const FieldType = field_info.field_type;

                            if (comptime trait.is(.Pointer)(FieldType)) {
                                @compileError("Cannot meaningfully free " ++ @typeName(C) ++
                                    " because it is an untagged union with a pointer element.");
                            }
                        }
                    }
                },
                .Option => {
                    if (value.*.?) |*valptr| {
                        self.free(valptr);
                    }
                },
                else => {},
            }

            self.arena.allocator.destroy(value);
        }

        pub fn deserialize(self: *Self, comptime T: type, in_stream: ReaderType) std.mem.Allocator.Error!*T {
            var in_stream_adj: AdjReaderType = switch (packing) {
                .Bit => std.io.bitReader(endian, in_stream),
                .Byte => in_stream,
            };

            return self.sub_deserialize(T, in_stream_adj);
        }

        fn sub_deserialize(self: *Self, comptime T: type, in_stream: AdjReaderType) std.mem.Allocator.Error!*T {
            const new_ptr = try self.arena.allocator.create(T);

            try self.deserialize_into(new_ptr, in_stream);

            return new_ptr;
        }

        pub fn deserialize_into(self: *Self, ptr: anytype, in_stream: AdjReaderType) std.mem.Allocator.Error!void {
            const T = @TypeOf(ptr);
            comptime std.debug.assert(std.meta.trait.is(.Pointer)(T));

            const C = comptime std.meta.Child(T);
            const child_type_id = @typeInfo(C);

            switch (child_type_id) {
                .Void => return,
                .Bool => ptr.* = (try self.deserialize_int(u1, in_stream)) > 0,
                .Float, .Int => ptr.* = try self.deserialize_int(C, in_stream),
                .Struct => {
                    const info = @typeInfo(C).Struct;

                    inline for (info.fields) |*field_info| {
                        const name = field_info.name;
                        const FieldType = field_info.field_type;

                        if (FieldType == void or FieldType == u0) continue;

                        if (comptime std.meta.trait.is(.Pointer)(FieldType)) {
                            @field(ptr, name) = self.sub_deserialize(std.meta.Child(FieldType), in_stream);
                        } else {
                            try self.deserialize_into(&@field(ptr, name), in_stream);
                        }
                    }
                },
                .Union => {
                    const info = @typeInfo(C).Union;
                    if (info.tag_type) |TagType| {
                        //we avoid duplicate iteration over the enum tags
                        // by getting the int directly and casting it without
                        // safety. If it is bad, it will be caught anyway.
                        const TagInt = @TagType(TagType);
                        const tag = try self.deserializeInt(TagInt);

                        inline for (info.fields) |field_info| {
                            if (field_info.enum_field.?.value == tag) {
                                const name = field_info.name;
                                const FieldType = field_info.field_type;
                                ptr.* = @unionInit(C, name, undefined);
                                try self.deserialize_into(&@field(ptr, name), in_stream);
                                return;
                            }
                        }
                        //This is reachable if the enum data is bad
                        return error.InvalidEnumTag;
                    }
                    @compileError("Cannot meaningfully deserialize " ++ @typeName(C) ++
                        " because it is an untagged union. Use a custom deserialize().");
                },
                .Optional => {
                    const OC = comptime meta.Child(C);
                    const exists = (try self.deserialize_int(u1, in_stream)) > 0;
                    if (!exists) {
                        ptr.* = null;
                        return;
                    }

                    ptr.* = @as(OC, undefined); //make it non-null so the following .? is guaranteed safe
                    const val_ptr = &ptr.*.?;
                    try self.deserialize_into(val_ptr, in_stream);
                },
                .Enum => {
                    var value = try self.deserialize_int(@TagType(C), in_stream);
                    ptr.* = try meta.intToEnum(C, value);
                },
                .Pointer => {},
                else => {
                    @compileError("Cannot deserialize " ++ @tagName(child_type_id) ++ " types (unimplemented).");
                },
            }
        }

        fn deserialize_int(self: *Self, comptime T: type, in_stream: AdjReaderType) void {
            comptime std.debug.assert(std.meta.trait.is(.Int)(T) or trait.is(.Float)(T));

            const u8_bit_count = 8;
            const t_bit_count = comptime std.meta.bitCount(T);

            const U = std.meta.Int(false, t_bit_count);
            const Log2U = std.math.Log2Int(U);
            const int_size = (U.bit_count + 7) / 8;

            if (packing == .Bit) {
                const result = try in_stream.readBitsNoEof(U, t_bit_count);
                return @bitCast(T, result);
            }

            var buffer: [int_size]u8 = undefined;
            const read_size = try in_stream.read(buffer[0..]);
            if (read_size < int_size) return error.EndOfStream;

            if (int_size == 1) {
                if (t_bit_count == 8) return @bitCast(T, buffer[0]);
                const PossiblySignedByte = std.meta.Int(T.is_signed, 8);
                return @truncate(T, @bitCast(PossiblySignedByte, buffer[0]));
            }

            var result = @as(U, 0);
            for (buffer) |byte, i| {
                switch (endian) {
                    .Big => {
                        result = (result << u8_bit_count) | byte;
                    },
                    .Little => {
                        result |= @as(U, byte) << @intCast(Log2U, u8_bit_count * i);
                    },
                }
            }

            return @bitCast(T, result);
        }
    };
}

pub fn Serializer(comptime endian: builtin.Endian, comptime packing: Packing, comptime ReaderType: type) type {}
