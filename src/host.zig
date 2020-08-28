const std = @import("std");

const c = @import("c_types.zig");
const z = @import("z_types.zig");

const s = @import("serialization.zig");

pub fn main() anyerror!void {
    if (std.os.argv.len == 2) {
        const fname = std.os.argv[1];
        const fnames = std.mem.span(fname);
        const file = try std.fs.cwd().openFile(fnames, .{ .read = true });
        defer file.close();

        var bytes: []u8 = try file.readAllAlloc(std.heap.page_allocator, (try file.stat()).size, 0xFFFFFFFF);
        defer std.heap.page_allocator.free(bytes);

        var marshall = s.ZagMarshall.init(std.heap.page_allocator);
        defer marshall.deinit();

        var req = try marshall.deserialize(z.ZagRequest, bytes);
        defer marshall.free_deserialized(req);

        std.debug.warn("{}\n", .{req.*});
    } else std.debug.warn("./zagclear_host [file]\n", .{});
}
