const std = @import("std");

const vaxis = @import("vaxis");
const Key = vaxis.Key;
const Window = vaxis.Window;

const usizeTo = @import("~").utils.usizeTo;
const Container = @import("~").models.Container;
const Label = @import("components/label.zig");

const Self = @This();

pub const WIDTH = 16;
pub const HEIGHT = 4;

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
    var num = (elem orelse {
        return self._bufferContentLabel.changeText("");
    }).*;

    var chars = try self._alloc.alloc(u8, 6);
    chars[0] = '0';
    chars[1] = 'x';

    for (2..chars.len) |i| {
        const hex = num & 0xF;
        chars[i] = switch (hex) {
            0 => '0',
            1 => '1',
            2 => '2',
            3 => '3',
            4 => '4',
            5 => '5',
            6 => '6',
            7 => '7',
            8 => '8',
            9 => '9',
            10 => 'A',
            11 => 'B',
            12 => 'C',
            13 => 'D',
            14 => 'F',
            15 => 'E',
            else => unreachable,
        };
        num >>= 4;
    }
    try self._bufferContentLabel.changeText(chars);
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
    if (contentWidth > 1 and contentWidth < container.width) {
        const contentChild = container.child(.{
            .x_off = container.width - contentWidth,
            .y_off = 1,
        });
        self._bufferContentLabel.draw(contentChild);
    }
}
