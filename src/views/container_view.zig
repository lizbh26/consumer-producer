const std = @import("std");

const vaxis = @import("vaxis");
const Key = vaxis.Key;
const Window = vaxis.Window;

const usize_to = @import("~").utils.usize_to;
const Container = @import("~").models.Container;
const Label = @import("components/label.zig");

const Self = @This();

const ContainerCard = struct {
    const WIDTH = 12;
    const HEIGHT = 4;

    _alloc: std.mem.Allocator,
    _bufferIndexLabel: Label,
    _bufferContentLabel: Label,

    pub fn init(alloc: std.mem.Allocator, index: usize) !ContainerCard {
        const self = ContainerCard{
            ._alloc = alloc,
            ._bufferIndexLabel = .init(alloc),
            ._bufferContentLabel = .init(alloc),
        };
        try self._bufferIndexLabel.changeText(try std.fmt.allocPrint(alloc, "{d}", .{index}));
        return self;
    }

    pub fn setContent(self: *ContainerCard, elem: ?*const Container.CONTAINER_ELEMENT) !void {
        if (elem) |num| {
            var chars = try self._alloc.alloc(u8, 6);
            chars[0] = "0";
            chars[1] = "x";
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
            self._bufferContentLabel.changeText(chars);
        } else {
            self._bufferContentLabel.changeText("");
        }
    }

    pub fn draw(self: *ContainerCard, win: Window) !void {
        std.debug.assert(win.width >= WIDTH and win.height >= HEIGHT);

        const container = win.child(.{
            .width = win.width,
            .height = win.height,
            .border = .{ .where = .all, .style = .{ .fg = .{ .index = 255 } } },
        });

        const indexChild = container.child(.{
            .x_off = 1,
            .y_off = 1,
            .width = @min(self._bufferIndexLabel.getWidth(), container.width - 2),
        });
        self._bufferIndexLabel.draw(indexChild);

        const contentWidth = self._bufferContentLabel.getWidth();
        const contentChild = container.child(.{
            .x_off = container.width - contentWidth,
            .y_off = 2,
            .width = contentWidth,
        });
        self._bufferContentLabel.draw(contentChild);
    }
};

_cards: [Container.CONTAINER_SIZE]ContainerCard,
_container: *const Container,

_title: Label,
_scroll: u16,

_current_width: u16,

pub fn init(alloc: std.mem.Allocator, container: *const Container) !Self {
    const self = Self{
        ._cards = .{},
        ._container = container,
        ._title = .init(alloc),
        ._scroll = 0,
        ._current_width = 0,
    };

    for (0..self._cards.len) |i| {
        self._cards[i] = try .init(alloc, i);
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

pub fn draw(self: *Self, win: Window) void {
    var idx = self._container.head;
    for (0..self._cards.len) |i| {
        idx = self._container.getNext(idx);
        self._cards[idx].setContent(if (i < self._container.len) self._container[idx] else null);
    }

    const winContainer = win.child(.{
        .width = win.width,
        .height = win.height,
        .border = .{ .where = .top, .style = .{ .fg = .{ .index = 255 } } },
    });

    const titleWidth = usize_to(u16, self._title.getWidth());
    const titleChild = winContainer.child(.{
        .x_off = @divFloor(winContainer.width - titleWidth, 2),
        .y_off = 1,
        .width = titleWidth,
    });
    self._title.draw(titleChild);

    self._current_width = winContainer.width;
    const measures = self.getCardTableMeasurements();

    for (self._scroll..measures.rows) |i| {
        for (0..measures.cols) |j| {
            const child = winContainer.child(.{
                .x_off = measures.padLeft + (ContainerCard.WIDTH + 2) * j,
                .y_off = 1 + (ContainerCard.WIDTH + 2) * j,
                .width = ContainerCard.WIDTH,
                .height = ContainerCard.HEIGHT,
            });
            self._cards[i * measures.cols + j].draw(child);
        }
    }
}
fn getCardTableMeasurements(self: *Self) struct { rows: u16, cols: u16, padLeft: u16 } {
    const cardWidth = ContainerCard.WIDTH + 2;
    const cardsPerRow = @divFloor(self._current_width, cardWidth);

    const paddingLeft = @divFloor(self._current_width - cardWidth * cardsPerRow, 2);

    return .{ .cols = cardsPerRow, .padLeft = paddingLeft, .rows = @divFloor(self._cards.len, cardsPerRow) + 1 };
}
