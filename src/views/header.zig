const std = @import("std");
const Allocator = std.mem.Allocator;

const vaxis = @import("vaxis");
const Window = vaxis.Window;

const usizeTo = @import("~").utils.usizeTo;
const time = @import("~").utils.time;

const Label = @import("components/label.zig");

const Self = @This();

_alloc: Allocator,
_time: Label,

pub fn init(alloc: Allocator) Self {
    return Self{
        ._alloc = alloc,
        ._time = .init(alloc),
    };
}

pub fn updateTime(self: *Self, ellapsed_ms: i128) !void {
    try self._time.changeText(try time.time_to_string(self._alloc, time.milliseconds_to_time(ellapsed_ms)));
}

pub fn draw(self: *Self, win: Window) void {
    const container = win.child(.{ .border = .{ .where = .bottom, .style = .{ .fg = .{ .index = 255 } } } });

    const timeChild = container.child(.{ .x_off = @divFloor(container.width - usizeTo(u16, self._time.getWidth()), 2) });
    self._time.draw(timeChild);
}
