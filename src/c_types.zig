pub const ZagResult = extern enum {
    ZAG_RESULT_SUCCESS,
    ZAG_RESULT_INVALID_SESSION,
    ZAG_RESULT_OUT_OF_MEMORY,
    ZAG_RESULT_INVALID_ENUM_TAG,
    ZAG_RESULT_END_OF_STREAM,
};

pub const ZagPiece = extern enum {
    ZAG_PIECE_I,
    ZAG_PIECE_O,
    ZAG_PIECE_T,
    ZAG_PIECE_L,
    ZAG_PIECE_J,
    ZAG_PIECE_S,
    ZAG_PIECE_Z,
};

export const ZAG_PIECE_FLAG_I: u32 = 1 << @enumToInt(ZagPiece.ZAG_PIECE_I);
export const ZAG_PIECE_FLAG_O: u32 = 1 << @enumToInt(ZagPiece.ZAG_PIECE_O);
export const ZAG_PIECE_FLAG_T: u32 = 1 << @enumToInt(ZagPiece.ZAG_PIECE_T);
export const ZAG_PIECE_FLAG_L: u32 = 1 << @enumToInt(ZagPiece.ZAG_PIECE_L);
export const ZAG_PIECE_FLAG_J: u32 = 1 << @enumToInt(ZagPiece.ZAG_PIECE_J);
export const ZAG_PIECE_FLAG_S: u32 = 1 << @enumToInt(ZagPiece.ZAG_PIECE_S);
export const ZAG_PIECE_FLAG_Z: u32 = 1 << @enumToInt(ZagPiece.ZAG_PIECE_Z);

pub const ZagTSpinStatus = extern enum {
    ZAG_TSPIN_STATUS_NONE,
    ZAG_TSPIN_STATUS_MINI,
    ZAG_TSPIN_STATUS_FULL,
};

pub const ZagMovement = extern enum {
    ZAG_MOVEMENT_LEFT,
    ZAG_MOVEMENT_RIGHT,
    ZAG_MOVEMENT_CLOCKWISE,
    ZAG_MOVEMENT_COUNTER_CLOCKWISE,
    ZAG_MOVEMENT_SOFT_DROP,
};

pub const ZagMovementMode = extern enum {
    ZAG_MOVEMENT_MODE_0G,
    ZAG_MOVEMENT_MODE_20G,
    ZAG_MOVEMENT_MODE_HARD_DROP_ONLY,
};

pub const ZagSpawnRule = extern enum {
    ZAG_SPAWN_RULE_ROW_19_OR_20,
    ZAG_SPAWN_RULE_ROW_21_AND_FALL,
};

pub const ZagSessionPollStatus = extern enum {
    ZAG_SESSION_POLL_STATUS_MOVE_PROVIDED,
    ZAG_SESSION_POLL_STATUS_WAITING,
    ZAG_SESSION_POLL_STATUS_DEAD,
};

pub const ZagPlanPlacement = extern struct {
    piece: ZagPiece,
    tspin_status: ZagTSpinStatus,
    expected_x: [4]u8,
    expected_y: [4]u8,
    cleared_lines: [4]i32,
};

pub const ZagMove = extern struct {
    hold: bool,
    expected_x: [4]u8,
    expected_y: [4]u8,
    movement_count: u8,
    movements: [32]ZagMovement,
    nodes: u32,
    depth: u32,
    original_rank: u32,
};

pub const ZagOptions = extern struct {
    mode: ZagMovementMode,
    spawn_rule: ZagSpawnRule,
    use_hold: bool,
    speculate: bool,
    pcloop: bool,
    min_nodes: u32,
    max_nodes: u32,
    threads: u32,
};

pub const ZagWeights = extern struct {
    back_to_back: i32,
    bumpiness: i32,
    bumpiness_sq: i32,
    row_transitions: i32,
    height: i32,
    top_half: i32,
    top_quarter: i32,
    jeopardy: i32,
    cavity_cells: i32,
    cavity_cells_sq: i32,
    overhang_cells: i32,
    overhang_cells_sq: i32,
    covered_cells: i32,
    covered_cells_sq: i32,
    tslot: [4]i32,
    well_depth: i32,
    max_well_depth: i32,
    well_column: [10]i32,
    b2b_clear: i32,
    clear1: i32,
    clear2: i32,
    clear3: i32,
    clear4: i32,
    tspin1: i32,
    tspin2: i32,
    tspin3: i32,
    mini_tspin1: i32,
    mini_tspin2: i32,
    perfect_clear: i32,
    combo_garbage: i32,
    move_time: i32,
    wasted_time: i32,
    use_bag: bool,
    timed_jeopardy: bool,
    stack_pc_damage: bool,
};

pub const ZagRequestLaunchAsync = extern struct {
    options: ZagOptions,
    weights: ZagWeights,
};

pub const ZagResponseLaunchAsync = extern struct {
    session: u64,
};

pub const ZagRequestLaunchWithBoardAsync = extern struct {
    options: ZagOptions,
    weights: ZagWeights,
    field: [400]bool,
    bag_remain: u32,
    hold: ZagPiece,
    b2b: bool,
    combo: u32,
};

pub const ZagResponseLaunchWithBoardAsync = extern struct {
    session: u64,
};

pub const ZagRequestDestroyAsync = extern struct {
    session: u64,
};

pub const ZagResponseDestroyAsync = extern struct {};

pub const ZagRequestResetAsync = extern struct {
    session: u64,
    field: [400]bool,
    b2b: bool,
    combo: u32,
};

pub const ZagResponseResetAsync = extern struct {};

pub const ZagRequestAddNextPieceAsync = extern struct {
    session: u64,
    piece: ZagPiece,
};

pub const ZagResponseAddNextPieceAsync = extern struct {};

pub const ZagRequestStartNextMove = extern struct {
    session: u64,
    incoming: u32,
};

pub const ZagResponseStartNextMove = extern struct {};

pub const ZagRequestPollNextMove = extern struct {
    session: u64,
};

pub const ZagResponsePollNextMove = extern struct {
    status: ZagSessionPollStatus,
    move: ZagMove,
    plan_array: [*]const ZagPlanPlacement,
    plan_length: u32,
};

pub const ZagRequestJoinNextMove = extern struct {
    session: u64,
};

pub const ZagResponseJoinNextMove = extern struct {
    status: ZagSessionPollStatus,
    move: ZagMove,
    plan_array: [*]const ZagPlanPlacement,
    plan_length: u32,
};

pub const ZagRequestDefaultOptions = extern struct {};

pub const ZagResponseDefaultOptions = extern struct {
    options: ZagOptions,
};

pub const ZagRequestDefaultWeights = extern struct {};

pub const ZagResponseDefaultWeights = extern struct {
    weights: ZagWeights,
};

pub const ZagRequestFastWeights = extern struct {};

pub const ZagResponseFastWeights = extern struct {
    weights: ZagWeights,
};

pub const ZagMessageTag = extern enum {
    ZAG_MESSAGE_LAUNCH_ASYNC,
    ZAG_MESSAGE_LAUNCH_WITH_BOARD_ASYNC,
    ZAG_MESSAGE_DESTROY_ASYNC,
    ZAG_MESSAGE_RESET_ASYNC,
    ZAG_MESSAGE_ADD_NEXT_PIECE_ASYNC,
    ZAG_MESSAGE_START_NEXT_MOVE,
    ZAG_MESSAGE_POLL_NEXT_MOVE,
    ZAG_MESSAGE_JOIN_NEXT_MOVE,
    ZAG_MESSAGE_DEFAULT_OPTIONS,
    ZAG_MESSAGE_DEFAULT_WEIGHTS,
    ZAG_MESSAGE_FAST_WEIGHTS,
};

pub const ZagRequestUnion = extern union {
    launch_async: ZagRequestLaunchAsync,
    launch_with_board_async: ZagRequestLaunchWithBoardAsync,
    destroy_async: ZagRequestDestroyAsync,
    reset_async: ZagRequestResetAsync,
    add_next_piece_async: ZagRequestAddNextPieceAsync,
    start_next_move: ZagRequestStartNextMove,
    poll_next_move: ZagRequestPollNextMove,
    join_next_move: ZagRequestJoinNextMove,
    default_options: ZagRequestDefaultOptions,
    default_weights: ZagRequestDefaultWeights,
    fast_weights: ZagRequestFastWeights,
};

pub const ZagRequest = extern struct {
    tag: ZagMessageTag,
    as: ZagRequestUnion,
};

pub const ZagResponseUnion = extern union {
    launch_async: ZagResponseLaunchAsync,
    launch_with_board_async: ZagResponseLaunchWithBoardAsync,
    destroy_async: ZagResponseDestroyAsync,
    reset_async: ZagResponseResetAsync,
    add_next_piece_async: ZagResponseAddNextPieceAsync,
    start_next_move: ZagResponseStartNextMove,
    poll_next_move: ZagResponsePollNextMove,
    join_next_move: ZagResponseJoinNextMove,
    default_options: ZagResponseDefaultOptions,
    default_weights: ZagResponseDefaultWeights,
    fast_weights: ZagResponseFastWeights,
};

pub const ZagResponse = extern struct {
    data: *const c_void,
    tag: ZagMessageTag,
    as: ZagResponseUnion,
};
