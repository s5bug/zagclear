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

    pub fn deserialize(self: *Self, comptime T: type, data: []u8) std.mem.Allocator.Error!*T {
        return std.mem.Allocator.Error.OutOfMemory;
    }

    pub fn free_deserialized(self: *Self, ptr: anytype) void {
        const T = @TypeOf(ptr);
        comptime std.debug.assert(std.meta.trait.is(.Pointer)(T));
        self.arena.allocator.destroy(ptr);
    }

    pub fn serialize(self: *Self, ptr: anytype) std.mem.Allocator.Error![]u8 {
        return std.mem.Allocator.Error.OutOfMemory;
    }

    pub fn free_serialized(self: *Self, data: []u8) void {
        self.arena.allocator.free(data);
    }
};
