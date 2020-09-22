const std = @import("std");

const c = @import("c_types.zig");
const z = @import("z_types.zig");

const s = @import("serialization.zig");

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

export fn zag_request_put(marshall: *s.ZagMarshall, req: *const c.ZagRequest, data: *[*]u8, size: *usize) c.ZagResult {
    const zreq = z.requestToZ(req);
    const result = marshall.serialize(&zreq) catch |err| return error_to_result(err);
    data.* = result.ptr;
    size.* = result.len;
    return c.ZagResult.ZAG_RESULT_SUCCESS;
}

export fn zag_request_free(marshall: *s.ZagMarshall, data: [*]const u8, size: usize) void {
    marshall.free_serialized(data[0..size]);
}

export fn zag_response_get(marshall: *s.ZagMarshall, resp: *c.ZagResponse, data: [*]const u8, size: usize) c.ZagResult {
    const result = marshall.deserialize(z.ZagResponse, data[0..size]) catch |err| return error_to_result(err);
    resp.* = z.responseToC(result);
    return c.ZagResult.ZAG_RESULT_SUCCESS;
}

export fn zag_response_free(marshall: *s.ZagMarshall, resp: *c.ZagResponse) void {
    marshall.free_deserialized(@ptrCast(*const z.ZagResponse, @alignCast(8, resp.data)));
}

export fn zag_write_size(size: u32, data: *[4]u8) void {
    std.mem.writeIntLittle(u32, data, size);
}
