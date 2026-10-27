const std = @import("std");
const vaxis = @import("vaxis");
const zeit = @import("zeit");

const ContextController = @import("context_controller.zig");
const RenderController = @import("render_controller.zig");

const Self = @This();

const FRAME_DURATION: zeit.Duration = .{ .microseconds = 16667 }; //60 FPS or 16 ms per frame

arena: std.heap.ArenaAllocator,
io: std.Io,

context: ContextController,
renderer: RenderController,

pub fn init(self: *Self, init_p: *const std.process.Init) !void {
    self.* = Self{
        .arena = .init(init_p.gpa),
        .io = init_p.io,
        .context = undefined,
        .renderer = undefined,
    };

    const alloc = self.arena.allocator();
    try self.context.init(alloc, self.io);
    try self.renderer.init(alloc, init_p, &self.context);
}

pub fn deinit(self: *Self) void {
    self.arena.deinit();
}

pub fn startLoop(self: *Self) !void {
    try self.renderer.startEventLoop();
    defer self.renderer.stopEventLoop();

    var frameStart = self.getNow();

    // The main event loop. Vaxis provides a thread safe, blocking, buffered
    // queue which can serve as the primary event queue for an application
    while (true) {
        frameStart = self.getNow();

        const exit = try self.renderer.handleEvents();
        if (exit) break;

        try self.context.tick(frameStart);
        try self.renderer.draw();
        const now = self.getNow();
        try self.waitRemainingFrameTime(frameStart, now);
    }
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
