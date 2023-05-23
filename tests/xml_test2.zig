const std = @import("std");
const xml = @import("xml");

const Node = struct {
    name: []const u8,
    tags: []const Tag,
    subNodes: []const SubNode,
    pub const tag = struct {
        name: []const u8,
        val: []const u8,
    };

    pub const SubNode = union(enum) {
        text: []const u8,
        node: Node,
    };
};

const XMLTest = struct {
    data: []const u8,
    expectedTree: Node,
};

fn subNode(name: []const u8, tags: []const Tag, subNodes: []const Node.SubNode) SubNode {
    return .{
        .name = name,
        .tags = tags,
        .subNodes = subNodes,
    };
}

const Tests = [_]XMLTest{
    .{
        .data =
        \\<note>
        \\  <to>Tove</to>
        \\  <from>Jani</from>
        \\  <heading>Reminder</heading>
        \\  <body>Don't forget me this weekend!</body>
        \\</note>
        ,
        .expectedTree = .{
            .name = "note",
            .tags = &.{},
            .subNodes = &.{
                subNode("to", &.{}, &.{.{ .text = "Tove" }}),
                subNode("from", &.{}, &.{.{ .text = "Jani" }}),
                subNode("heading", &.{}, &.{.{ .text = "Reminder" }}),
                subNode("body", &.{}, &.{.{ .text = "Don't forget me this weekend!" }}),
            },
        },
    },
};

test {
    const alloc = std.testing.allocator;

    for (Tests) |t| {
        var doc = xml.ParseDocument(t.data);
        defer doc.deinit();
    }
}
