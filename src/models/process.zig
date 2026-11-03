const Self = @This();

impl: *anyopaque,
v_enterMonitor: *const fn (*anyopaque) void,
v_exitMonitor: *const fn (*anyopaque) void,
v_blockByWait: *const fn (*anyopaque) void,
v_unblock: *const fn (*anyopaque) void,

pub fn implBy(impl_obj: anytype) Self {
    const delegate = ProcessDelegate(impl_obj);
    return .{
        .impl = impl_obj,
        .v_enterMonitor = delegate.enterMonitor,
        .v_exitMonitor = delegate.exitMonitor,
        .v_blockByWait = delegate.blockByWait,
        .v_unblock = delegate.unblock,
    };
}

pub fn enterMonitor(self: *Self) void {
    self.v_enterMonitor(self.impl);
}
pub fn exitMonitor(self: *Self) void {
    self.v_exitMonitor(self.impl);
}
pub fn blockByWait(self: *Self) void {
    self.v_blockByWait(self.impl);
}
pub fn unblock(self: *Self) void {
    self.v_unblock(self.impl);
}

inline fn ProcessDelegate(impl_object: anytype) type {
    const ImplType = @TypeOf(impl_object);
    return struct {
        fn enterMonitor(impl: *anyopaque) void {
            TPtr(ImplType, impl).enterMonitor();
        }
        fn exitMonitor(impl: *anyopaque) void {
            TPtr(ImplType, impl).exitMonitor();
        }
        fn blockByWait(impl: *anyopaque) void {
            TPtr(ImplType, impl).blockByWait();
        }
        fn unblock(impl: *anyopaque) void {
            TPtr(ImplType, impl).unblock();
        }
    };
}
fn TPtr(T: type, opaque_ptr: *anyopaque) T {
    return @as(T, @ptrCast(@alignCast(opaque_ptr)));
}
