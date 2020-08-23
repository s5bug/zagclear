const std = @import("std");

const c = @import("c_types.zig");
const z = @import("z_types.zig");

const s = @import("serialization.zig");

export fn zag_marshall_init(marshall_p: **s.ZagMarshall) c.ZagResult {
    const alloc = std.heap.c_allocator;
    const on_stack: s.ZagMarshall = s.ZagMarshall.init(alloc);
    const on_heap: *s.ZagMarshall = alloc.create(s.ZagMarshall) catch return c.ZagResult.ZAG_RESULT_OUT_OF_MEMORY;
    on_heap.* = on_stack;
    marshall_p.* = on_heap;
    return c.ZagResult.ZAG_RESULT_SUCCESS;
}

export fn zag_marshall_free(marshall: *s.ZagMarshall) void {
    const alloc = std.heap.c_allocator;
    marshall.deinit();
    alloc.destroy(marshall);
}

export fn zag_request_put(marshall: *s.ZagMarshall, req: *c.ZagRequest, data: *[*]u8, size: *usize) c.ZagResult {
    const result = marshall.serialize(z.requestToZ(req)) catch return c.ZagResult.ZAG_RESULT_OUT_OF_MEMORY; // TODO proper result handling
    data.* = result.ptr;
    size.* = result.len;
    return c.ZagResult.ZAG_RESULT_SUCCESS;
}

export fn zag_request_free(marshall: *s.ZagMarshall, data: [*]u8, size: usize) void {
    marshall.free_serialized(data[0..size]);
}

export fn zag_response_get(marshall: *s.ZagMarshall, resp: *c.ZagResponse, data: [*]u8, size: usize) c.ZagResult {
    const result = marshall.deserialize(z.ZagResponse, data[0..size]) catch return c.ZagResult.ZAG_RESULT_OUT_OF_MEMORY; // TODO proper result handling
    resp.* = z.responseToC(result);
    marshall.free_deserialized(result);
    return c.ZagResult.ZAG_RESULT_SUCCESS;
}

export fn zag_response_free(marshall: *s.ZagMarshall, resp: *c.ZagResponse) void {
    marshall.free_deserialized(resp);
}
