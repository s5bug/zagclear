const std = @import("std");

const c = @import("c_types.zig");
const z = @import("z_types.zig");

const s = @import("serialization.zig");

const cc = @import("coldclear.zig");

fn error_to_result(err: s.ZagMarshall.Error) c.ZagResult {
    return switch (err) {
        s.ZagMarshall.Error.OutOfMemory => c.ZagResult.ZAG_RESULT_OUT_OF_MEMORY,
        s.ZagMarshall.Error.InvalidEnumTag => c.ZagResult.ZAG_RESULT_INVALID_ENUM_TAG,
        s.ZagMarshall.Error.EndOfStream => c.ZagResult.ZAG_RESULT_END_OF_STREAM,
    };
}

export fn zag_marshall_init(marshall_p: **s.ZagMarshall) c.ZagResult {
    const alloc = std.heap.c_allocator;
    const on_stack: s.ZagMarshall = s.ZagMarshall.init(alloc);
    const on_heap: *s.ZagMarshall = alloc.create(s.ZagMarshall) catch |err| return error_to_result(err);
    on_heap.* = on_stack;
    marshall_p.* = on_heap;
    return c.ZagResult.ZAG_RESULT_SUCCESS;
}

export fn zag_marshall_free(marshall: *s.ZagMarshall) void {
    const alloc = std.heap.c_allocator;
    marshall.deinit();
    alloc.destroy(marshall);
}

export fn zag_request_handle(marshall: *s.ZagMarshall, data: [*]const u8, size: usize, output: *[*]u8, output_size: *usize) c.ZagResult {
    const req: *z.ZagRequest = marshall.deserialize(z.ZagRequest, data[0..size]) catch |err| return error_to_result(err);
    const resp: z.ZagResponse = handle(req);
    const resp_ser: []u8 = marshall.serialize(&resp) catch |err| return error_to_result(err);
    output.* = resp_ser.ptr;
    output_size.* = resp_ser.len;
    return c.ZagResult.ZAG_RESULT_SUCCESS;
}

export fn zag_free_response(marshall: *s.ZagMarshall, data: [*]u8, size: usize) void {
    const alloc: *std.mem.Allocator = &marshall.arena.allocator;
    const slice: []u8 = data[0..size];
    alloc.free(slice);
}

fn handle(req: *z.ZagRequest) z.ZagResponse {
    return .{
        .ZAG_MESSAGE_LAUNCH_ASYNC = .{
            .session = 69,
        }
    };
}
