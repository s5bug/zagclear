pub const ZagResult = extern enum {
    ZAG_RESULT_SUCCESS,
    ZAG_RESULT_INVALID_SESSION,
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

pub const ZagBotPollStatus = extern enum {
    ZAG_BOT_POLL_STATUS_MOVE_PROVIDED,
    ZAG_BOT_POLL_STATUS_WAITING,
    ZAG_BOT_POLL_STATUS_DEAD,
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
};

pub const ZagRequestLaunchAsync = extern struct {
    options: ZagOptions,
    weights: ZagWeights,
};

pub const ZagResponseLaunchAsync = extern struct {
    session: u128,
};

pub const ZagRequestLaunchWithBoardAsync = extern struct {
    options: ZagOptions,
    weights: ZagWeights,
    field: [40][10]bool,
    bag_remain: u32,
    hold: ZagPiece,
    b2b: bool,
    combo: u32,
};

pub const ZagResponseLaunchBoardAsync = extern struct {
    session: u128,
};

pub const ZagRequestDestroyAsync = extern struct {
    session: u128,
};

pub const ZagResponseDestroyAsync = extern struct {};
