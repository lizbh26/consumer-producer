const std = @import("std");
const Allocator = std.mem.Allocator;

const vaxis = @import("vaxis");
const Window = vaxis.Window;

const usizeTo = @import("~").utils.usizeTo;
const time = @import("~").utils.time;

const Label = @import("components/label.zig");

const Self = @This();

_alloc: Allocator,
_controls: Label,
_time: Label,

pub fn init(alloc: Allocator) Self {
    return Self{
        ._alloc = alloc,
        ._controls = .init(alloc),
        ._time = .init(alloc),
    };
}

pub fn updateTime(self: *Self, ellapsed_ms: i128) !void {
    try self._time.changeText(try time.time_to_string(self._alloc, time.milliseconds_to_time(ellapsed_ms)));
}
pub fn updateControls(self: *Self, ctx: struct { is_paused: bool }) !void {
    const ESC_MSG = "ESC - Salir";
    const PAUSED_MSG = "P - Pausar";
    const UNPAUSE_MSG = "C - Continuar";
    try self._controls.changeText(try self._alloc.print(
        "{s}    {s}",
        .{ ESC_MSG, if (ctx.is_paused) UNPAUSE_MSG else PAUSED_MSG },
    ));
}

pub fn draw(self: *Self, win: Window) void {
    const container = win.child(.{ .border = .{ .where = .bottom, .style = .{ .fg = .{ .index = 255 } } } });

    const controlsChild = container.child(.{ .x_off = 1 });
    self._controls.draw(controlsChild);

    const timeChild = container.child(.{ .x_off = container.width - usizeTo(u16, self._time.getWidth()) - 1 });
    self._time.draw(timeChild);
}
