const std = @import("std");

const vaxis = @import("vaxis");
const Key = vaxis.Key;
const Window = vaxis.Window;

const usize_to = @import("~").utils.usize_to;

const Consumer = @import("~").models.Consumer;
const Producer = @import("~").models.Producer;
const Container = @import("~").models.Container;

const Label = @import("components/label.zig");
const ContainerView = @import("container_view.zig");
const ProcessCard = @import("process_card.zig");

const Self = @This();

const RenderContext = struct {
    consumer: *const Consumer,
    producer: *const Producer,
    container: *const Container,
};

ctx: RenderContext,
container_view: ContainerView,
producer_card: ProcessCard,
consumer_card: ProcessCard,

pub fn init(self: *Self, alloc: std.mem.Allocator, ctx: RenderContext) !void {
    self.* = .{
        .ctx = ctx,
        .container_view = undefined,
        .producer_card = undefined,
        .consumer_card = undefined,
    };
    try self.container_view.init(alloc, ctx.container);
    try self.producer_card.init(alloc, "Producidor");
    try self.consumer_card.init(alloc, "Consumidor");
}

pub fn draw(self: *Self, win: Window) !void {
    const halfWidth = @divFloor(win.width, 2);
    const halfHeight = @divFloor(win.height, 2);

    try self.updateProducerCard();
    const producerW, const producerH = self.producer_card.getDimensions();
    const producerChild = win.child(.{
        .x_off = @divFloor(halfWidth - producerW, 2),
        .y_off = @divFloor(halfHeight - producerH, 2),
        .width = producerW,
        .height = producerH,
    });
    self.producer_card.draw(producerChild);

    try self.updateConsumerCard();
    const consumerW, const consumerH = self.consumer_card.getDimensions();
    const consumerChild = win.child(.{
        .x_off = halfWidth + @divFloor(halfWidth - consumerW, 2),
        .y_off = @divFloor(halfHeight - consumerH, 2),
        .width = consumerW,
        .height = consumerH,
    });
    self.consumer_card.draw(consumerChild);

    const containerChild = win.child(.{
        .y_off = halfHeight,
        .width = win.width,
        .height = halfHeight - 1,
    });
    try self.container_view.draw(containerChild);
}

fn updateProducerCard(self: *Self) !void {
    const p = self.ctx.producer;
    if (p.isBlocked()) {
        try self.producer_card.changeStatus("Bloqueado...");
    } else if (p.isSleeping()) {
        try self.producer_card.changeTime(p.ms_to_sleep);
        try self.producer_card.changeStatus("Durmiendo...");
    } else if (p.isProducing()) {
        try self.producer_card.changeTime(p.ms_to_produce);
        try self.producer_card.changeStatus("Produciendo...");
    }
}

fn updateConsumerCard(self: *Self) !void {
    const c = self.ctx.consumer;
    if (c.isBlocked()) {
        try self.consumer_card.changeStatus("Bloqueado...");
    } else if (c.isSleeping()) {
        try self.consumer_card.changeTime(c.ms_to_sleep);
        try self.consumer_card.changeStatus("Durmiendo...");
    } else if (c.isConsuming()) {
        try self.consumer_card.changeTime(c.ms_to_consume);
        try self.consumer_card.changeStatus("Consumiendo...");
    }
}
