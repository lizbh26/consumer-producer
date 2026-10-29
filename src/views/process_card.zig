const std = @import("std");

const vaxis = @import("vaxis");
const Key = vaxis.Key;
const Window = vaxis.Window;

const usizeTo = @import("~").utils.usizeTo;
const time = @import("~").utils.time;

const Container = @import("~").models.Container;

const Label = @import("components/label.zig");

const Self = @This();

_alloc: std.mem.Allocator,

_title: Label,
_status: Label,
_time: Label,

pub fn init(self: *Self, alloc: std.mem.Allocator, title: []const u8) !void {
    self.* = .{
        ._alloc = alloc,
        ._title = .init(alloc),
        ._status = .init(alloc),
        ._time = .init(alloc),
    };
    try self._title.changeText(title);
}

pub fn changeTime(self: *Self, ellapsed_ms: i128) !void {
    try self._time.changeText(try time.time_to_string(self._alloc, time.milliseconds_to_time(ellapsed_ms)));
}
pub fn changeStatus(self: *Self, label: []const u8) !void {
    try self._status.changeText(label);
}

pub fn draw(self: *Self, win: Window) void {
    const width, const height = self.getDimensions();
    const container = win.child(.{
        .width = width,
        .height = height,
        .border = .{ .where = .all, .style = .{ .fg = .{ .index = 255 } } },
    });
    const titleChild = container.child(.{
        .height = 1,
        .y_off = 0,
        .x_off = @divFloor(container.width - usizeTo(u16, self._title.getWidth()), 2),
    });
    self._title.draw(titleChild);

    const statusChild = container.child(.{
        .height = 1,
        .y_off = 1,
        .x_off = 1,
    });
    self._status.draw(statusChild);

    if (self._time.getWidth() > 1) {
        const timeChild = container.child(.{
            .height = 1,
            .y_off = 2,
            .x_off = 1,
        });
        self._time.draw(timeChild);
    }
}

pub fn getDimensions(self: *Self) struct { u16, u16 } {
    return .{
        usizeTo(u16, @max(self._title.getWidth(), self._time.getWidth(), self._status.getWidth(), 28)) + 2,
        5,
    };
}
