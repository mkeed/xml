const std = @import("std");

pub const Tag = struct {
    name: std.ArrayList(u8),
    value: std.ArrayList(u8),
    pub fn init(alloc: std.mem.Allocator) Tag {
        return Tag{
            .name = std.ArrayList(u8).init(alloc),
            .value = std.ArrayList(u8).init(alloc),
        };
    }
    pub fn deinit(self: Tag) void {
        self.name.deinit();
        self.value.deinit();
    }
};

pub const Node = struct {
    name: std.ArrayList(u8),
    tags: std.ArrayList(Tag),
    subNodes: std.ArrayList(SubNode),
    pub fn init(alloc: std.mem.Allocator) Node {
        return Node{
            .name = std.ArrayList(u8).init(alloc),
            .tags = std.ArrayList(Tag).init(alloc),
            .subNodes = std.ArrayList(SubNode).init(alloc),
        };
    }
    pub fn deinit(self: Node) void {
        self.name.deinit();
        for (self.tags.items) |item| item.deinit();
        self.tags.deinit();
        for (self.subNodes.items) |sn| {
            switch (sn) {
                .text => |t| t.deinit(),
                else => {},
            }
        }
    }
    pub fn appendContent(self: Node, alloc: std.mem.Allocator, text: []const u8) !void {
        var txt = std.ArrayList(u8).init(alloc);
        errdefer txt.deinit();
        try txt.appendSlice(text);
        var subNode = SubNode{ .text = txt };
        try self.subNodes.append(subNode);
    }
    pub const SubNode = union(enum) {
        text: std.ArrayList(u8),
        subNode: *Node,
    };
};

pub fn parseDocument(reader: anytype, alloc: std.mem.Allocator) !XMLDocument {
    _ = reader;
    var doc = try XMLDocument.init(alloc);
    errdefer doc.deinit();
    var curNode = doc.root;

    var tagsBuffer = std.ArrayList(Tag).init(alloc);
    defer {
        for (tagsBuffer.items) |t| t.deinit();
    }
    defer tagsBuffer.deinit();

    var stringBuffer = std.ArrayList(u8).init(alloc);
    defer stringBuffer.deinit();

    while (true) {
        try reader.readUntilDelimiterArrayList(&stringBuffer, '<', std.math.maxInt(u32));
        {
            var trimmed = std.mem.trim(stringBuffer.items, std.ascii.whitespace);
            if (trimmed.len > 0) {
                try curNode.appendContent(alloc, trimmed);
            }
        }
    }

    return error.NotImplemented;
}

pub const XMLDocument = struct {
    alloc: std.mem.Allocator,
    nodes: std.ArrayList(*Node),
    root: *Node,
    pub fn init(alloc: std.mem.Allocator) !XMLDocument {
        var node = try alloc.create(Node);
        errdefer alloc.destroy(node);
        node.* = Node.init(alloc);
        var nodes = std.ArrayList(*Node).init(alloc);
        errdefer nodes.deinit();

        try nodes.append(node);

        return XMLDocument{
            .alloc = alloc,
            .nodes = nodes,
            .root = node,
        };
    }
    pub fn deinit(self: XMLDocument) void {
        for (self.nodes.items) |node| {
            node.deinit();
            self.alloc.destroy(node);
        }
        self.nodes.deinit();
    }
};
