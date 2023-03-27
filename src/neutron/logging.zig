/// Base logger type
pub const Logger = @import("logging/logger.zig");

/// A logger which sends messages to different loggers based on the level
pub const MultiLevelLogger = @import("logging/multi-level-logger.zig");
