const c = @import("c_types.zig");

pub const ZagRequest = union(c.ZagMessageTag) {
    ZAG_MESSAGE_LAUNCH_ASYNC: c.ZagRequestLaunchAsync,
    ZAG_MESSAGE_LAUNCH_WITH_BOARD_ASYNC: c.ZagRequestLaunchWithBoardAsync,
    ZAG_MESSAGE_DESTROY_ASYNC: c.ZagRequestDestroyAsync,
    ZAG_MESSAGE_RESET_ASYNC: c.ZagRequestResetAsync,
    ZAG_MESSAGE_ADD_NEXT_PIECE_ASYNC: c.ZagRequestAddNextPieceAsync,
    ZAG_MESSAGE_START_NEXT_MOVE: c.ZagRequestStartNextMove,
    ZAG_MESSAGE_POLL_NEXT_MOVE: c.ZagRequestPollNextMove,
    ZAG_MESSAGE_JOIN_NEXT_MOVE: c.ZagRequestJoinNextMove,
    ZAG_MESSAGE_DEFAULT_OPTIONS: c.ZagRequestDefaultOptions,
    ZAG_MESSAGE_DEFAULT_WEIGHTS: c.ZagRequestDefaultWeights,
    ZAG_MESSAGE_FAST_WEIGHTS: c.ZagRequestFastWeights,
};

pub fn requestToZ(request: *c.ZagRequest) ZagRequest {
    return switch (request.tag) {
        .ZAG_MESSAGE_LAUNCH_ASYNC => ZagRequest{
            .ZAG_MESSAGE_LAUNCH_ASYNC = request.as.launch_async,
        },
        else => unreachable, // TODO
    };
}

pub const ZagZResponsePollNextMove = struct {
    status: c.ZagSessionPollStatus,
    move: c.ZagMove,
    plan: []c.ZagPlanPlacement,
};

pub const ZagZResponseJoinNextMove = struct {
    status: c.ZagSessionPollStatus,
    move: c.ZagMove,
    plan: []c.ZagPlanPlacement,
};

pub const ZagResponse = union(c.ZagMessageTag) {
    ZAG_MESSAGE_LAUNCH_ASYNC: c.ZagResponseLaunchAsync,
    ZAG_MESSAGE_LAUNCH_WITH_BOARD_ASYNC: c.ZagResponseLaunchWithBoardAsync,
    ZAG_MESSAGE_DESTROY_ASYNC: c.ZagResponseDestroyAsync,
    ZAG_MESSAGE_RESET_ASYNC: c.ZagResponseResetAsync,
    ZAG_MESSAGE_ADD_NEXT_PIECE_ASYNC: c.ZagResponseAddNextPieceAsync,
    ZAG_MESSAGE_START_NEXT_MOVE: c.ZagResponseStartNextMove,
    ZAG_MESSAGE_POLL_NEXT_MOVE: ZagZResponsePollNextMove,
    ZAG_MESSAGE_JOIN_NEXT_MOVE: ZagZResponseJoinNextMove,
    ZAG_MESSAGE_DEFAULT_OPTIONS: c.ZagResponseDefaultOptions,
    ZAG_MESSAGE_DEFAULT_WEIGHTS: c.ZagResponseDefaultWeights,
    ZAG_MESSAGE_FAST_WEIGHTS: c.ZagResponseFastWeights,
};

pub fn responseToC(response: *ZagResponse) c.ZagResponse {
    return switch (response.*) {
        .ZAG_MESSAGE_LAUNCH_ASYNC => |resp| c.ZagResponse{
            .tag = .ZAG_MESSAGE_LAUNCH_ASYNC,
            .as = .{
                .launch_async = resp,
            },
        },
        else => unreachable, // TODO
    };
}
