const Self = @This();

impl: *anyopaque,
v_block: *const fn (*anyopaque) void,
v_unblock: *const fn (*anyopaque) void,

pub fn implBy(impl_obj: anytype) Self {
    const delegate = ProcessDelegate(impl_obj);
    return .{
        .impl = impl_obj,
        .v_block = delegate.block,
        .v_unblock = delegate.unblock,
    };
}

inline fn ProcessDelegate(impl_object: anytype) type {
    const ImplType = @TypeOf(impl_object);
    return struct {
        fn block(impl: *anyopaque) void {
            TPtr(ImplType, impl).block();
        }
        fn unblock(impl: *anyopaque) void {
            TPtr(ImplType, impl).unblock();
        }
    };
}
fn TPtr(T: type, opaque_ptr: *anyopaque) T {
    return @as(T, @ptrCast(@alignCast(opaque_ptr)));
}
