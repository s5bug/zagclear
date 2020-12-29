const std = @import("std");

pub const ZagMarshall = struct {
    arena: std.heap.ArenaAllocator,

    const Self = @This();

    pub const Error = error{EndOfStream} || std.mem.Allocator.Error || std.meta.IntToEnumError;

    pub fn init(alloc: *std.mem.Allocator) Self {
        return Self{
            .arena = std.heap.ArenaAllocator.init(alloc),
        };
    }

    pub fn deinit(self: *Self) void {
        self.arena.deinit();
    }

    pub fn deserialize(self: *Self, comptime T: type, data: []const u8) Error!*T {
        const Fbs = std.io.FixedBufferStream([]const u8);
        var fbs: Fbs = std.io.fixedBufferStream(data);
        const ReaderT = Fbs.Reader;
        var reader: ReaderT = fbs.reader();

        return try self.deserializeP(T, reader);
    }

    fn deserializeP(self: *Self, comptime T: type, reader: std.io.FixedBufferStream([]const u8).Reader) Error!*T {
        var new_p: *T = try self.arena.allocator.create(T);

        new_p.* = try self.deserializeC(T, reader);

        return new_p;
    }

    fn deserializeC(self: *Self, comptime T: type, reader: std.io.FixedBufferStream([]const u8).Reader) Error!T {
        var v: T = undefined;
        try self.deserializeN(T, &v, reader);
        return v;
    }

    fn deserializeN(self: *Self, comptime T: type, p: *T, reader: std.io.FixedBufferStream([]const u8).Reader) Error!void {
        const type_id: std.builtin.TypeInfo = @typeInfo(T);

        switch (type_id) {
            .Void => {},
            .Bool => p.* = (try self.deserializeI(u8, reader)) > 0,
            .Float, .Int => p.* = (try self.deserializeI(T, reader)),
            .Struct => |sdata| {
                inline for (sdata.fields) |field_info| {
                    const name = field_info.name;
                    const FieldType = field_info.field_type;

                    try self.deserializeN(FieldType, &@field(p, name), reader);
                }
            },
            .Union => |udata| {
                if (udata.tag_type) |TagType| {
                    const ETagType = @typeInfo(TagType).Enum.tag_type;
                    const tag: ETagType = try self.deserializeI(ETagType, reader);

                    inline for (udata.fields) |field_info| {
                        if (@enumToInt(@field(TagType, field_info.name)) == tag) {
                            const name = field_info.name;
                            const FieldType = field_info.field_type;
                            p.* = @unionInit(T, name, undefined);
                            try self.deserializeN(FieldType, &@field(p, name), reader);
                            return;
                        }
                    }
                } else @compileError("cannot deserialize untagged union");
            },
            .Optional => @compileError("not implemented"),
            .Enum => {
                var value = try self.deserializeI(@TagType(T), reader);
                p.* = try std.meta.intToEnum(T, value);
            },
            .Pointer => |pdata| {
                switch (pdata.size) {
                    .One => p.* = try self.deserializeP(pdata.child, reader),
                    .Slice => {
                        const length = try self.deserializeI(u64, reader);

                        var slice = try self.arena.allocator.alloc(pdata.child, length);

                        for (slice) |*e| {
                            try self.deserializeN(pdata.child, e, reader);
                        }
                    },
                    else => @compileError("cannot deserialize non-singular or non-slice pointer"),
                }
            },
            .Array => |adata| {
                for (p) |*v| {
                    try self.deserializeN(adata.child, v, reader);
                }
            },
            else => @compileError("not implemented"),
        }
    }

    fn deserializeI(self: *Self, comptime T: type, reader: std.io.FixedBufferStream([]const u8).Reader) Error!T {
        return try reader.readInt(T, std.builtin.Endian.Little);
    }

    pub fn free_deserialized(self: *Self, ptr: anytype) void {
        const T = @TypeOf(ptr);
        comptime std.debug.assert(std.meta.trait.is(.Pointer)(T));
        self.arena.allocator.destroy(ptr);
    }

    pub fn serialize(self: *Self, ptr: anytype) std.mem.Allocator.Error![]u8 {
        var arr = std.ArrayList(u8).init(&self.arena.allocator);
        defer arr.deinit();

        const P = @TypeOf(ptr);
        try self.serializeP(P, ptr, &arr);

        return arr.toOwnedSlice();
    }

    fn serializeP(self: *Self, comptime P: type, p: P, arr: *std.ArrayList(u8)) std.mem.Allocator.Error!void {
        comptime std.debug.assert(std.meta.trait.isSingleItemPtr(P));

        const C = comptime std.meta.Child(P);
        try self.serializeC(C, p, arr);
    }

    fn serializeC(self: *Self, comptime C: type, p: *const C, arr: *std.ArrayList(u8)) std.mem.Allocator.Error!void {
        const child_type_id: std.builtin.TypeInfo = @typeInfo(C);

        switch (child_type_id) {
            .Void => {},
            .Bool => try self.serializeI(u8, if (p.*) @as(u8, 1) else @as(u8, 0), arr),
            .Float, .Int => try self.serializeI(C, p.*, arr),
            .Struct => |sdata| {
                inline for (sdata.fields) |field_info| {
                    const name = field_info.name;
                    const FieldType = field_info.field_type;

                    try self.serializeP(*const FieldType, &@field(p, name), arr);
                }
            },
            .Union => |udata| {
                if (udata.tag_type) |TagType| {
                    const ETagType = @typeInfo(TagType).Enum.tag_type;
                    const tag: ETagType = @enumToInt(std.meta.activeTag(p.*));
                    try self.serializeI(ETagType, tag, arr);

                    inline for (udata.fields) |field_info| {
                        if (@enumToInt(@field(TagType, field_info.name)) == tag) {
                            const name = field_info.name;
                            const FieldType = field_info.field_type;
                            try self.serializeP(*const FieldType, &@field(p, name), arr);
                        }
                    }
                } else @compileError("cannot serialize untagged union");
            },
            .Optional => @compileError("not implemented"),
            .Enum => |edata| {
                const ETagType = edata.tag_type;
                const tag: ETagType = @enumToInt(p.*);
                try self.serializeI(ETagType, tag, arr);
            },
            .Pointer => |pdata| {
                switch (pdata.size) {
                    .One => try self.serializeP(pdata.child, p.*, arr),
                    .Slice => {
                        const length: u64 = @intCast(u64, p.*.len);
                        try self.serializeI(u64, length, arr);

                        const ChildPtrT = @Type(.{
                            .Pointer = .{
                                .size = .One,
                                .is_const = pdata.is_const,
                                .is_volatile = pdata.is_volatile,
                                .alignment = pdata.alignment,
                                .is_allowzero = pdata.is_allowzero,
                                .child = pdata.child,
                                .sentinel = null,
                            }
                        });

                        for (p.*) |*e| {
                            try self.serializeP(ChildPtrT, e, arr);
                        }
                    },
                    else => @compileError("cannot serialize non-singular or non-slice pointer"),
                }
            },
            else => {},
        }
    }

    fn serializeI(self: *Self, comptime T: type, t: T, arr: *std.ArrayList(u8)) std.mem.Allocator.Error!void {
        var buf: [(@typeInfo(T).Int.bits + 7) / 8]u8 = undefined;
        std.mem.writeIntLittle(T, &buf, t);
        try arr.appendSlice(&buf);
    }

    pub fn free_serialized(self: *Self, data: []const u8) void {
        self.arena.allocator.free(data);
    }
};

test "foobar" {
    var marshall = ZagMarshall.init(std.testing.allocator);
    defer marshall.deinit();

    const foo = struct {
        a: i32,
    };

    var myfoo = foo{ .a = 3 };

    var bytes: []u8 = try marshall.serialize(&myfoo);
    var expected: [4]u8 = [_]u8{ 3, 0, 0, 0 };

    std.testing.expectEqualSlices(u8, bytes, &expected);

    var deser: *foo = try marshall.deserialize(foo, bytes);
    std.testing.expectEqual(myfoo, deser.*);
}
