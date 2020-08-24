const std = @import("std");

pub const ZagMarshall = struct {
    arena: std.heap.ArenaAllocator,

    const Self = @This();

    pub fn init(alloc: *std.mem.Allocator) Self {
        return Self{
            .arena = std.heap.ArenaAllocator.init(alloc),
        };
    }

    pub fn deinit(self: *Self) void {
        self.arena.deinit();
    }

    pub fn deserialize(self: *Self, comptime T: type, data: []const u8) std.mem.Allocator.Error!*T {
        return std.mem.Allocator.Error.OutOfMemory;
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
        const child_type_id = @typeInfo(C);

        switch (child_type_id) {
            .Void => {},
            .Bool => arr.append(if(p.*) 1 else 0),
            .Float, .Int => @compileError("not implemented"),
            .Struct => @compileError("not implementend"),
            .Union => @compileError("not implemented"),
            .Optional => @compileError("not implemented"),
            .Enum => @compileError("not implemented"),
            else => @compileError("not implementend"),
        }
    }

    pub fn free_serialized(self: *Self, data: []const u8) void {
        self.arena.allocator.free(data);
    }
};
