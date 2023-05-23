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

    pub fn init(alloc: std.mem.Allocator) Node {
        return Node{
            .name = std.ArrayList(u8).init(alloc),
            .tags = std.ArrayList(Tag).init(alloc),
        };
    }
    pub fn deinit(self: Node) void {
        self.name.deinit();
        for (self.tags.items) |item| item.deinit();
        self.tags.deinit();
    }
    pub const SubNode = union(enum) {
        text: std.ArrayList(u8),
        subNode: *Node,
    };
};

pub const XMLDocument = struct {
    nodes: std.ArrayList(*Node),

    pub fn init(alloc: std.mem.Allocator) XMLDocument {
        return XMLDocument{
            .nodes = std.ArrayList(Node).init(alloc),
            .strings = std.ArrayList(*std.ArrayList(u8)).init(alloc),
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
