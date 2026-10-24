const std = @import("std");

const vaxis = @import("vaxis");
const Key = vaxis.Key;
const Window = vaxis.Window;

const usize_to = @import("~").utils.usize_to;

const Consumer = @import("~").models.Consumer;
const Producer = @import("~").models.Producer;
const Container = @import("~").models.Container;

const Label = @import("components/label.zig");
const ContainerView = @import("container_view.zig");

const Self = @This();

const RenderContext = struct {
    consumer: *const Consumer,
    producer: *const Producer,
    container: *const Container,
};

ctx: RenderContext,
container_view: ContainerView,

pub fn init(alloc: std.mem.Allocator, ctx: RenderContext) Self {
    return .{
        .ctx = ctx,
        .container_view = .init(alloc, ctx.container),
    };
}

pub fn draw(self: *Self, win: Window) void {
    const containerChild = win.child(.{
        .width = win.width,
        .height = @divFloor(win.height, 2),
    });
    self.container_view.draw(containerChild);
}
