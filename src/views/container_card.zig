const std = @import("std");

const vaxis = @import("vaxis");
const Key = vaxis.Key;
const Window = vaxis.Window;

const usizeTo = @import("~").utils.usizeTo;
const Container = @import("~").models.Container;
const Label = @import("components/label.zig");

const Self = @This();

pub const WIDTH = 12;
pub const HEIGHT = 3;

_alloc: std.mem.Allocator,
_bufferIndexLabel: Label,
_bufferContentLabel: Label,

pub fn init(self: *Self, alloc: std.mem.Allocator, index: usize) !void {
    self.* = .{
        ._alloc = alloc,
        ._bufferIndexLabel = .init(alloc),
        ._bufferContentLabel = .init(alloc),
    };
    try self._bufferIndexLabel.changeText(try std.fmt.allocPrint(alloc, "{d}", .{index}));
}

pub fn setContent(self: *Self, elem: ?*const Container.CONTAINER_ELEMENT) !void {
    try self._bufferContentLabel.changeText(
        if (elem) |e| try Container.elemToHex(self._alloc, e.*) else "",
    );
}

pub fn draw(self: *Self, win: Window) !void {
    std.debug.assert(win.width >= WIDTH and win.height >= HEIGHT);

    const container = win.child(.{
        .width = win.width,
        .height = win.height,
        .border = .{ .where = .all, .style = .{ .fg = .{ .index = 255 } } },
    });

    const indexChild = container.child(.{
        .x_off = 1,
    });
    self._bufferIndexLabel.draw(indexChild);

    const contentWidth = usizeTo(u16, self._bufferContentLabel.getWidth());
    if (contentWidth > 1) {
        const contentChild = container.child(.{
            .x_off = container.width - contentWidth,
        });
        self._bufferContentLabel.draw(contentChild);
    }
}
