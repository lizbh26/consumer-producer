const std = @import("std");

const vaxis = @import("vaxis");
const Key = vaxis.Key;
const Window = vaxis.Window;

const usizeTo = @import("~").utils.usizeTo;
const Container = @import("~").models.Container;

const Label = @import("components/label.zig");
const ContainerCard = @import("container_card.zig");

const Self = @This();

_cards: [Container.CONTAINER_SIZE]ContainerCard,
_container: *const Container,

_title: Label,
_scroll: u16,

_current_width: u16,

pub fn init(alloc: std.mem.Allocator, container: *const Container) !Self {
    var self = Self{
        ._cards = undefined,
        ._container = container,
        ._title = .init(alloc),
        ._scroll = 0,
        ._current_width = 0,
    };

    for (0..self._cards.len) |i| {
        self._cards[i] = try .init(alloc, i + 1);
    }
    try self._title.changeText("Vista del contenedor");

    return self;
}

pub fn handleInput(self: *Self, key: Key) void {
    if (key.matches(Key.down, .{})) {
        if (self.getCardTableMeasurements().rows - self._scroll > 1) self._scroll += 1;
    } else if (key.matches(Key.up, .{})) {
        if (self._scroll > 0) self._scroll -= 1;
    }
}

pub fn draw(self: *Self, win: Window) !void {
    var idx = self._container.head;
    for (0..self._cards.len) |i| {
        try self._cards[idx].setContent(if (i < self._container.len) &self._container.buffer[idx] else null);
        idx = self._container.getNext(idx);
    }

    const winContainer = win.child(.{
        .width = win.width,
        .height = win.height,
        .border = .{ .where = .top, .style = .{ .fg = .{ .index = 255 } } },
    });

    const titleWidth = usizeTo(u16, self._title.getWidth());
    const titleChild = winContainer.child(.{
        .x_off = @divFloor(winContainer.width - titleWidth, 2),
        .width = titleWidth,
    });
    self._title.draw(titleChild);

    self._current_width = winContainer.width;
    try self.renderCards(winContainer);
}
fn renderCards(self: *Self, winContainer: Window) !void {
    const measures = self.getCardTableMeasurements();

    var accHeight: u16 = ContainerCard.HEIGHT;
    var idx: usize = 0;

    for (self._scroll..measures.rows) |i| {
        if (accHeight > winContainer.height) break;

        for (0..measures.cols) |j| {
            if (idx == self._cards.len) return;

            const child = winContainer.child(.{
                .x_off = usizeTo(i17, measures.padLeft + (ContainerCard.WIDTH + 2) * j),
                .y_off = usizeTo(i17, 1 + (ContainerCard.HEIGHT + 2) * i),
                .width = ContainerCard.WIDTH,
                .height = ContainerCard.HEIGHT,
            });
            try self._cards[idx].draw(child);
            idx += 1;
        }
        accHeight += ContainerCard.HEIGHT;
    }
}

fn getCardTableMeasurements(self: *Self) struct { rows: u16, cols: u16, padLeft: u16 } {
    const cardWidth = ContainerCard.WIDTH + 2;
    const cardsPerRow: u16 = @divFloor(self._current_width, cardWidth);

    const paddingLeft: u16 = @divFloor(self._current_width - cardWidth * cardsPerRow, 2);

    return .{
        .cols = cardsPerRow,
        .rows = @divFloor(usizeTo(u16, self._cards.len), @max(cardsPerRow, 1)) + 1,
        .padLeft = paddingLeft,
    };
}
