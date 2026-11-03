const std = @import("std");

const vaxis = @import("vaxis");
const Window = vaxis.Window;

const Consumer = @import("~").models.Consumer;
const Producer = @import("~").models.Producer;
const Container = @import("~").models.Container;
const Monitor = @import("~").models.Monitor;

const Label = @import("components/label.zig");

const Header = @import("header.zig");
const ContainerView = @import("container_view.zig");
const ProcessCard = @import("process_card.zig");

const Self = @This();

const RenderContext = struct {
    consumer: *const Consumer,
    producer: *const Producer,
    container: *const Container,
    monitor: *const Monitor,
    ellapsed: *const i128,
};

alloc: std.mem.Allocator,
ctx: RenderContext,
header: Header,
container_view: ContainerView,
producer_card: ProcessCard,
consumer_card: ProcessCard,

pub fn init(self: *Self, alloc: std.mem.Allocator, ctx: RenderContext) !void {
    self.* = .{
        .alloc = alloc,
        .ctx = ctx,
        .header = .init(alloc),
        .container_view = undefined,
        .producer_card = undefined,
        .consumer_card = undefined,
    };
    try self.container_view.init(alloc, ctx.container);
    try self.producer_card.init(alloc, "Producidor");
    try self.consumer_card.init(alloc, "Consumidor");
}

pub fn handleScroll(self: *Self, direction: i2) void {
    self.container_view.handleScroll(direction);
}

pub fn draw(self: *Self, win: Window) !void {
    try self.header.updateTime(self.ctx.ellapsed.*);
    const headerContainer = win.child(.{ .height = 2 });
    self.header.draw(headerContainer);

    const mainContainer = win.child(.{ .y_off = 2 });
    const halfWidth = @divFloor(mainContainer.width, 2);
    const halfHeight = @divFloor(mainContainer.height, 2);

    try self.updateProducerCard();
    const producerChild = mainContainer.child(.{ .width = halfWidth, .height = halfHeight });
    self.drawProducerCard(producerChild);

    try self.updateConsumerCard();
    const consumerChild = mainContainer.child(.{ .x_off = halfWidth, .height = halfHeight });
    self.drawConsumerCard(consumerChild);

    const containerChild = mainContainer.child(.{
        .y_off = halfHeight,
        .width = mainContainer.width,
        .height = halfHeight,
    });
    try self.container_view.draw(containerChild);
}

fn drawProducerCard(self: *Self, win: Window) void {
    const producerW, const producerH = self.producer_card.getDimensions();
    const producerChild = win.child(.{
        .x_off = @divFloor(win.width - producerW, 2),
        .y_off = @divFloor(win.height - producerH, 2),
        .width = producerW,
        .height = producerH,
    });
    self.producer_card.draw(producerChild);
}
fn updateProducerCard(self: *Self) !void {
    const p = self.ctx.producer;
    const card = &self.producer_card;
    if (p.isBlocked()) {
        try card.changeTime(0);
        try card.changeStatus("Bloqueado...");
    } else if (p.isSleeping()) {
        try card.changeTime(p.ms_to_sleep);
        try self.producer_card.changeStatus("Durmiendo...");
    } else if (p.isTryingToWrite()) {
        try card.changeTime(0);
        try card.changeStatus("Intentando escribir...");
    } else if (p.isWriting()) {
        try card.changeTime(self.ctx.monitor.ms_left);
        try card.changeStatus("Escribiendo...");
    }
}

fn drawConsumerCard(self: *Self, win: Window) void {
    const consumerW, const consumerH = self.consumer_card.getDimensions();
    const consumerChild = win.child(.{
        .x_off = @divFloor(win.width - consumerW, 2),
        .y_off = @divFloor(win.height - consumerH, 2),
        .width = consumerW,
        .height = consumerH,
    });
    self.consumer_card.draw(consumerChild);
}
fn updateConsumerCard(self: *Self) !void {
    const c = self.ctx.consumer;
    const card = &self.consumer_card;
    if (c.isBlocked()) {
        try card.changeTime(0);
        try card.changeStatus("Bloqueado...");
    } else if (c.isSleeping()) {
        try card.changeTime(c.ms_to_sleep);
        try card.changeStatus("Durmiendo...");
    } else if (c.isTryingToRead()) {
        try card.changeTime(0);
        try card.changeStatus("Intentando leer...");
    } else if (c.isReading()) {
        try card.changeTime(self.ctx.monitor.ms_left);
        try card.changeStatus("Leyendo...");
    }
}
