const std = @import("std");

const c = @import("c_types.zig");
const z = @import("z_types.zig");

const s = @import("serialization.zig");

const cc = @import("coldclear.zig");

export fn handle(data: [*]const u8, size: usize, output: *[*]u8, output_size: *usize) void {
    
}

export fn free_output(data: [*]u8, size: usize) void {
    const alloc: *std.mem.Allocator = std.heap.c_allocator;
    const slice: []u8 = data[0..size];
    alloc.free(slice);
}
