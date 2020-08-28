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

pub fn requestToZ(request: *const c.ZagRequest) ZagRequest {
    return switch (request.tag) {
        .ZAG_MESSAGE_LAUNCH_ASYNC => ZagRequest{
            .ZAG_MESSAGE_LAUNCH_ASYNC = request.as.launch_async,
        },
        .ZAG_MESSAGE_LAUNCH_WITH_BOARD_ASYNC => ZagRequest{
            .ZAG_MESSAGE_LAUNCH_WITH_BOARD_ASYNC = request.as.launch_with_board_async,
        },
        .ZAG_MESSAGE_DESTROY_ASYNC => ZagRequest{
            .ZAG_MESSAGE_DESTROY_ASYNC = request.as.destroy_async,
        },
        .ZAG_MESSAGE_RESET_ASYNC => ZagRequest{
            .ZAG_MESSAGE_RESET_ASYNC = request.as.reset_async,
        },
        .ZAG_MESSAGE_ADD_NEXT_PIECE_ASYNC => ZagRequest{
            .ZAG_MESSAGE_ADD_NEXT_PIECE_ASYNC = request.as.add_next_piece_async,
        },
        .ZAG_MESSAGE_START_NEXT_MOVE => ZagRequest{
            .ZAG_MESSAGE_START_NEXT_MOVE = request.as.start_next_move,
        },
        .ZAG_MESSAGE_POLL_NEXT_MOVE => ZagRequest{
            .ZAG_MESSAGE_POLL_NEXT_MOVE = request.as.poll_next_move,
        },
        .ZAG_MESSAGE_JOIN_NEXT_MOVE => ZagRequest{
            .ZAG_MESSAGE_JOIN_NEXT_MOVE = request.as.join_next_move,
        },
        .ZAG_MESSAGE_DEFAULT_OPTIONS => ZagRequest{
            .ZAG_MESSAGE_DEFAULT_OPTIONS = request.as.default_options,
        },
        .ZAG_MESSAGE_DEFAULT_WEIGHTS => ZagRequest{
            .ZAG_MESSAGE_DEFAULT_WEIGHTS = request.as.default_weights,
        },
        .ZAG_MESSAGE_FAST_WEIGHTS => ZagRequest{
            .ZAG_MESSAGE_FAST_WEIGHTS = request.as.fast_weights,
        },
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

pub fn responseToC(response: *const ZagResponse) c.ZagResponse {
    return switch (response.*) {
        .ZAG_MESSAGE_LAUNCH_ASYNC => |resp| c.ZagResponse{
            .data = @ptrCast(*const c_void, response),
            .tag = .ZAG_MESSAGE_LAUNCH_ASYNC,
            .as = .{
                .launch_async = resp,
            },
        },
        .ZAG_MESSAGE_LAUNCH_WITH_BOARD_ASYNC => |resp| c.ZagResponse{
            .data = @ptrCast(*const c_void, response),
            .tag = .ZAG_MESSAGE_LAUNCH_WITH_BOARD_ASYNC,
            .as = .{
                .launch_with_board_async = resp,
            },
        },
        .ZAG_MESSAGE_DESTROY_ASYNC => |resp| c.ZagResponse{
            .data = @ptrCast(*const c_void, response),
            .tag = .ZAG_MESSAGE_DESTROY_ASYNC,
            .as = .{
                .destroy_async = resp,
            },
        },
        .ZAG_MESSAGE_RESET_ASYNC => |resp| c.ZagResponse{
            .data = @ptrCast(*const c_void, response),
            .tag = .ZAG_MESSAGE_RESET_ASYNC,
            .as = .{
                .reset_async = resp,
            },
        },
        .ZAG_MESSAGE_ADD_NEXT_PIECE_ASYNC => |resp| c.ZagResponse{
            .data = @ptrCast(*const c_void, response),
            .tag = .ZAG_MESSAGE_ADD_NEXT_PIECE_ASYNC,
            .as = .{
                .add_next_piece_async = resp,
            },
        },
        .ZAG_MESSAGE_START_NEXT_MOVE => |resp| c.ZagResponse{
            .data = @ptrCast(*const c_void, response),
            .tag = .ZAG_MESSAGE_START_NEXT_MOVE,
            .as = .{
                .start_next_move = resp,
            },
        },
        .ZAG_MESSAGE_POLL_NEXT_MOVE => |resp| c.ZagResponse{
            .data = @ptrCast(*const c_void, response),
            .tag = .ZAG_MESSAGE_POLL_NEXT_MOVE,
            .as = .{
                .poll_next_move = c.ZagResponsePollNextMove{
                    .status = resp.status,
                    .move = resp.move,
                    .plan_array = resp.plan.ptr,
                    .plan_length = @intCast(u32, resp.plan.len),
                },
            },
        },
        .ZAG_MESSAGE_JOIN_NEXT_MOVE => |resp| c.ZagResponse{
            .data = @ptrCast(*const c_void, response),
            .tag = .ZAG_MESSAGE_JOIN_NEXT_MOVE,
            .as = .{
                .join_next_move = c.ZagResponseJoinNextMove{
                    .status = resp.status,
                    .move = resp.move,
                    .plan_array = resp.plan.ptr,
                    .plan_length = @intCast(u32, resp.plan.len),
                },
            },
        },
        .ZAG_MESSAGE_DEFAULT_OPTIONS => |resp| c.ZagResponse{
            .data = @ptrCast(*const c_void, response),
            .tag = .ZAG_MESSAGE_DEFAULT_OPTIONS,
            .as = .{
                .default_options = resp,
            },
        },
        .ZAG_MESSAGE_DEFAULT_WEIGHTS => |resp| c.ZagResponse{
            .data = @ptrCast(*const c_void, response),
            .tag = .ZAG_MESSAGE_DEFAULT_WEIGHTS,
            .as = .{
                .default_weights = resp,
            },
        },
        .ZAG_MESSAGE_FAST_WEIGHTS => |resp| c.ZagResponse{
            .data = @ptrCast(*const c_void, response),
            .tag = .ZAG_MESSAGE_FAST_WEIGHTS,
            .as = .{
                .fast_weights = resp,
            },
        },
    };
}
