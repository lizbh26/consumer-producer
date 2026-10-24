const std = @import("std");
const vaxis = @import("vaxis");
const zeit = @import("zeit");

const ContextController = @import("context_controller.zig");
const RenderController = @import("render_controller.zig");

const Self = @This();

const FRAME_DURATION: zeit.Duration = .{ .microseconds = 16667 }; //60 FPS or 16 ms per frame

// Vaxis event type
const Event = union(enum) { key_press: vaxis.Key, winsize: vaxis.Winsize, focus_in };

arena: std.heap.ArenaAllocator,
io: std.Io,

loop: vaxis.Loop(Event),

context: ContextController,
renderer: RenderController,

pub fn init(init_p: *const std.process.Init) !Self {
    const arena = std.heap.ArenaAllocator.init(init_p.gpa);
    const alloc = arena.allocator();

    const self = Self{
        .arena = arena,
        .io = init_p.io,
        .loop = undefined,
        .context = .init(alloc, init_p.io),
        .renderer = undefined,
    };
    errdefer self.deinit();

    self.loop = .init(self.io, &self.tty, &self.vx);
    self.renderer = try .init(&self.context);

    return self;
}

pub fn deinit(self: *Self) void {
    self.arena.deinit();
}

pub fn startLoop(self: *Self) !void {
    try self.loop.start();
    defer self.loop.stop();

    var frameStart = self.getNow();

    // The main event loop. Vaxis provides a thread safe, blocking, buffered
    // queue which can serve as the primary event queue for an application
    while (true) {
        frameStart = self.getNow();

        const exit = try self.handlePendingEvents();
        if (exit) break;

        try self.context.tick(frameStart);
        try self.renderer.draw();
        const now = self.getNow();
        try self.waitRemainingFrameTime(frameStart, now);
    }
}

fn handlePendingEvents(self: *Self) !bool {
    while (try self.loop.tryEvent()) |event| {
        switch (event) {
            .key_press => |key| {
                self.renderer.handleInput(key);
            },
            .winsize => |ws| {
                try self.renderer.handleWindowResize(ws);
            },
            else => {},
        }
    }

    return false;
}

fn waitRemainingFrameTime(self: *Self, begin: zeit.Instant, now: zeit.Instant) !void {
    const diffFromCurrFrame = now.timestamp - begin.timestamp;
    const totalFrameDiff = FRAME_DURATION.inNanoseconds() catch unreachable;

    const sleepNanos: i96 = @intCast(totalFrameDiff - diffFromCurrFrame);
    if (sleepNanos > 0) try std.Io.sleep(self.io, .{ .nanoseconds = sleepNanos }, .awake);
}

fn getNow(self: *Self) zeit.Instant {
    return zeit.instant(.{ .now = self.io }, &zeit.utc);
}
