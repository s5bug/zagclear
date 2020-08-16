const c = @import("c_types.zig");

export fn zag_request_launch_async(req: c.ZagRequestLaunchAsync, data: *[*]u8, size: *usize) c.ZagResult {
    return .ZAG_RESULT_SUCCESS;
}

export fn zag_request_launch_with_board_async(req: c.ZagRequestLaunchWithBoardAsync, data: *[*]u8, size: *usize) c.ZagResult {
    return .ZAG_RESULT_SUCCESS;
}

export fn zag_request_destroy_async(req: c.ZagRequestDestroyAsync, data: *[*]u8, size: *usize) c.ZagResult {
    return .ZAG_RESULT_SUCCESS;
}

export fn zag_free_request(data: [*]u8, size: usize) void {
    return;
}
