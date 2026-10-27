const std = @import("std");

const vaxis = @import("vaxis");
const Key = vaxis.Key;

const ContextController = @import("context_controller.zig");

const MainView = @import("../views/main_view.zig");

const Self = @This();

pub const MIN_SCREEN_WIDTH = 125;
pub const MIN_SCREEN_HEIGHT = 30;

// Vaxis event type
const Event = union(enum) { key_press: vaxis.Key, winsize: vaxis.Winsize, focus_in };

alloc: std.mem.Allocator,

buffer: [1024]u8,
tty: vaxis.Tty,
vx: vaxis.Vaxis,
loop: vaxis.Loop(Event),

context: *ContextController,

main_view: MainView,

pub fn init(
    self: *Self,
    alloc: std.mem.Allocator,
    init_p: *const std.process.Init,
    ctx: *ContextController,
) !void {
    self.* = .{
        .alloc = alloc,

        .buffer = undefined,
        .tty = undefined,
        .vx = undefined,
        .loop = undefined,

        .context = ctx,
        .main_view = try .init(alloc, .{
            .consumer = &ctx.consumer,
            .producer = &ctx.producer,
            .container = &ctx.monitor.container,
        }),
    };
    self.tty = try vaxis.Tty.init(init_p.io, &self.buffer);
    errdefer self.tty.deinit();

    self.vx = try vaxis.init(init_p.io, alloc, init_p.environ_map, .{});
    errdefer self.vx.deinit(alloc, self.tty.writer());

    self.loop = .init(init_p.io, &self.tty, &self.vx);
}
pub fn deinit(self: *Self) void {
    self.vx.deinit(self.alloc, self.tty.writer());
    self.tty.deinit();
}

pub fn startEventLoop(self: *Self) !void {
    try self.loop.start();

    const writer = self.tty.writer();
    // Sends queries to terminal to detect certain features. This should
    // _always_ be called, but is left to the application to decide when
    try self.vx.queryTerminal(writer, .fromSeconds(1));

    try self.vx.enterAltScreen(writer);
    defer self.vx.exitAltScreen(writer) catch {};

    try self.vx.setMouseMode(writer, false);
}
pub fn stopEventLoop(self: *Self) void {
    self.loop.stop();
}

pub fn handleEvents(self: *Self) !bool {
    while (try self.loop.tryEvent()) |event| {
        switch (event) {
            .key_press => |key| {
                if (key.matches(Key.escape, .{})) {
                    return true;
                } else if (key.matches('l', .{ .ctrl = true })) {
                    self.vx.queueRefresh();
                } else self.handleInput(key);
            },
            .winsize => |ws| {
                try self.vx.resize(self.alloc, self.tty.writer(), ws);
                self.vx.queueRefresh();
            },
            else => {},
        }
    }

    return false;
}
fn handleInput(self: *Self, key: Key) void {
    if (self.context.is_paused) {
        if (key.matches('c', .{})) self.context.is_paused = false;
    } else if (key.matches('p', .{})) {
        self.context.is_paused = true;
    }
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

    try self.main_view.draw(win);

    try self.vx.render(self.tty.writer());
    try self.tty.writer().flush();
}
