const std = @import("std");

const vaxis = @import("vaxis");
const Key = vaxis.Key;

const ContextController = @import("context_controller.zig");

const Self = @This();

pub const MIN_SCREEN_WIDTH = 125;
pub const MIN_SCREEN_HEIGHT = 30;

alloc: std.mem.Allocator,

buffer: [1024]u8,
tty: vaxis.Tty,
vx: vaxis.Vaxis,

context: *const ContextController,

pub fn init(alloc: std.mem.Allocator, io: std.Io, ctx: *const ContextController) !Self {
    const self = Self{
        .alloc = alloc,
        .buffer = undefined,
        .tty = undefined,
        .vx = undefined,
        .context = ctx,
    };
    self.tty = try vaxis.Tty.init(io, &self.buffer);
    errdefer self.tty.deinit();

    self.vx = try vaxis.init(io, alloc, .{}, .{});
    errdefer self.vx.deinit(alloc, self.tty.writer());

    const writer = self.tty.writer();
    // Sends queries to terminal to detect certain features. This should
    // _always_ be called, but is left to the application to decide when
    try self.vx.queryTerminal(writer, .fromSeconds(1));

    try self.vx.enterAltScreen(writer);
    defer self.vx.exitAltScreen(writer) catch {};

    try self.vx.setMouseMode(writer, false);

    return self;
}
pub fn deinit(self: *Self) void {
    self.vx.deinit(self.alloc, self.tty.writer());
    self.tty.deinit();
}

pub fn handleInput(self: *Self, key: Key) void {
    if (key.matches(Key.Escape)) {
        return true;
    } else if (key.matches('l', .{ .ctrl = true })) {
        self.vx.queueRefresh();
    } else if (self.context.is_paused) {
        if (key.matches('c', .{})) self.context.is_paused = false;
    } else if (key.matches('p', .{})) {
        self.context.is_paused = true;
    }
}
pub fn handleWindowResize(self: *Self, ws: vaxis.Winsize) !void {
    try self.vx.resize(self.arena.allocator(), self.tty.writer(), ws);
    self.vx.queueRefresh();
}

pub fn draw(self: *Self) !void {
    // vx.window() returns the root window. This window is the size of the
    // terminal and can spawn child windows as logical areas. Child windows
    // cannot draw outside of their bounds
    const win = self.vx.window();

    // Clear the entire space because we are drawing in immediate mode.
    // vaxis double buffers the screen. This new frame will be compared to
    // the old and only updated cells will be drawn
    win.clear();

    if (win.width < MIN_SCREEN_WIDTH or win.height < MIN_SCREEN_HEIGHT) return error.TerminalSize;

    try self.orchestrator.draw(win);

    try self.vx.render(self.tty.writer());
    try self.tty.writer().flush();
}
