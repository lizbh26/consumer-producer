const Self = @This();

impl: *anyopaque,
v_execute: *const fn (*anyopaque) void,

pub fn implBy(impl_obj: anytype) Self {
    const delegate = ProcessDelegate(impl_obj);
    return .{
        .impl = impl_obj,
        .v_execute = delegate.execute,
    };
}

inline fn ProcessDelegate(impl_object: anytype) type {
    const ImplType = @TypeOf(impl_object);
    return struct {
        fn execute(impl: *anyopaque) void {
            TPtr(ImplType, impl).execute();
        }
    };
}
fn TPtr(T: type, opaque_ptr: *anyopaque) T {
    return @as(T, @ptrCast(@alignCast(opaque_ptr)));
}
