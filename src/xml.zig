const std = @import("std");
const xmlOpenToken = "<?";
const xmlCloseToken = ">";

const commentOpen = "<!--";
const commentClose = "-->";

const openTag = "<";
const openCloseTag = "</";

const xmlTag = struct {
    name: []const u8,
    val: []const u8,
};

const XMLContents = union(enum) {
    str: []const u8,
    node: *XMLNode,
};
pub const XMLNode = struct {
    alloc: std.mem.Allocator,
    parent: ?*XMLNode,
    name: []const u8,
    tags: []xmlTag,
    contents: std.ArrayList(XMLContents),
    fn print_indent(num: usize) void {
        var count: usize = 0;
        while (count < num) : (count += 1) {
            std.debug.print(" ", .{});
        }
    }
    pub fn print(self: *XMLNode, indent: usize) void {
        print_indent(indent);
        std.debug.print("start=>[{s}]\n", .{self.name});
        for (self.tags) |val| {
            print_indent(indent);
            std.debug.print("arg[{s}] => [{s}]\n", .{ val.name, val.val });
        }
        for (self.contents.items) |content| {
            switch (content) {
                .str => |val| {
                    print_indent(indent + 1);
                    std.debug.print("{s}\n", .{val});
                },
                .node => |n| {
                    n.print(indent + 1);
                },
            }
        }
        print_indent(indent);
        std.debug.print("end=>[{s}]\n", .{self.name});
    }
    pub fn deinit(self: *XMLNode) void {
        self.alloc.free(self.tags);
        for (self.contents.items) |c| {
            switch (c) {
                .node => |n| {
                    n.deinit();
                    //self.alloc.destroy(n);
                },
                else => {},
            }
        }
        self.contents.deinit();
        self.alloc.destroy(self);
    }

    const GetNodesError = error{
        AllocError,
    };
    pub fn getTag(self: *XMLNode, name: []const u8) ?[]const u8 {
        for (self.tags) |tag| {
            if (std.mem.eql(u8, name, tag.name)) {
                return tag.val;
            }
        }
        return null;
    }

    pub const NodesIterator = struct {
        root: *XMLNode,
        query: []const []const u8,
        curNode: ?*XMLNode = null,
        pub fn next(self: *NodesIterator) ?*XMLNode {
            var curNode = self.root;
            var queryIdx: usize = 0;
            var nodeIdx: usize = 0;
            if (self.curNode) |cn| {
                queryIdx = self.query.len - 1;
                if (cn.parent) |p| {
                    for (p.contents.items) |c, idx| {
                        switch (c) {
                            .node => |n| {
                                if (n == cn) {
                                    nodeIdx = idx + 1;
                                    break;
                                }
                            },
                            else => {},
                        }
                    }
                    curNode = p;
                } else {
                    self.curNode = null;
                    return null;
                }
            }
            queryLoop: while (queryIdx < self.query.len) {
                while (nodeIdx < curNode.contents.items.len) : (nodeIdx += 1) {
                    switch (curNode.contents.items[nodeIdx]) {
                        .node => |node| {
                            if (std.mem.eql(u8, self.query[queryIdx], node.name)) {
                                curNode = node;
                                queryIdx += 1;
                                if (queryIdx == self.query.len) {
                                    self.curNode = curNode;
                                    return curNode;
                                }
                                nodeIdx = 0;
                                continue :queryLoop;
                            }
                        },
                        else => {},
                    }
                }
                if (queryIdx == 0) {
                    self.curNode = null;
                    return null;
                }
                queryIdx -= 1;
                if (curNode.parent) |p| {
                    for (p.contents.items) |c, idx| {
                        switch (c) {
                            .node => |n| {
                                if (n == curNode) {
                                    nodeIdx = idx + 1;
                                }
                            },
                            else => {},
                        }
                        curNode = p;
                    }
                } else {
                    self.curNode = null;
                    return null;
                }
            }
            self.curNode = null;
            return null;
        }
    };

    pub fn nodesIter(self: *XMLNode, query: []const []const u8) NodesIterator {
        return .{ .root = self, .query = query };
    }

    pub fn getSingleNode(self: *XMLNode, name: []const u8) ?*XMLNode {
        for (self.contents.items) |i| {
            switch (i) {
                .node => |n| {
                    if (std.mem.eql(u8, n.name, name)) {
                        return n;
                    }
                },
                else => {},
            }
        }
        return null;
    }

    pub fn getNodes(self: *XMLNode, nodes: *std.ArrayList(*XMLNode), queries: []const []const u8) !void {
        var iter = self.nodesIter(queries);

        while (iter.next()) |node| {
            try nodes.append(node);
        }
    }
};

const Counter = struct {
    val: []const u8,
    count: usize,
    pub fn increment(self: *Counter, count: usize, colour: usize) void {
        _ = colour;
        self.count += count;
    }
};

pub fn ParseXML(
    alloc: std.mem.Allocator,
    val: []const u8,
) !*XMLNode {
    var idx = Counter{
        .val = val,
        .count = 0,
    };
    var rootNode = try alloc.create(XMLNode);

    rootNode.* = XMLNode{
        .alloc = alloc,
        .parent = null,
        .name = "root",
        .tags = try alloc.alloc(xmlTag, 0),
        .contents = std.ArrayList(XMLContents).init(alloc),
    };
    var curNode: *XMLNode = rootNode;

    while (true) {
        const point = std.mem.indexOf(u8, val[idx.count..], "<") orelse {
            break;
        };
        if (point != 0) {
            try curNode.contents.append(.{
                .str = val[idx.count .. idx.count + point],
            });
        }
        idx.increment(point, 0);
        switch (val[idx.count + 1]) {
            '?' => { //version
                const end = std.mem.indexOf(u8, val[idx.count..], "?>") orelse return error.UnFinished;
                idx.increment(end + 2, 1);
            },
            '!' => { //comment
                const end = std.mem.indexOf(u8, val[idx.count..], "-->") orelse return error.UnFinished;
                idx.increment(end + 3, 2);
            },
            '/' => {
                //TODO match names
                const end = std.mem.indexOf(u8, val[idx.count..], ">") orelse return error.UnFinished;
                idx.increment(end + 1, 3);
                if (curNode.parent) |c| {
                    curNode = c;
                } else {
                    return rootNode;
                }
            },
            else => {
                const end = std.mem.indexOf(u8, val[idx.count..], ">") orelse return error.UnFinished;
                const starting_tag = val[idx.count + 1 .. idx.count + 1 + end];
                idx.increment(end + 2, 4);
                //std.debug.print("starting_tag=>[{s}]\n", .{starting_tag});
                const end_name = std.mem.indexOfAny(u8, starting_tag, std.ascii.spaces[0..]);
                const name = if (end_name) |e| starting_tag[0..e] else starting_tag;

                var tags = std.ArrayList(xmlTag).init(alloc);
                if (end_name) |e| {
                    const tag_area = std.mem.trim(
                        u8,
                        starting_tag[e..],
                        std.ascii.spaces ++ "/>",
                    );
                    //std.debug.print("name=>({s})\tTAG_AREA[[{s}]]\n", .{ name, tag_area });
                    var tag_idx: usize = 0;
                    while (tag_idx < tag_area.len) {
                        const eql_pos = std.mem.indexOf(u8, tag_area[tag_idx..], "=") orelse return error.InvalidTag;
                        const name_tag = std.mem.trim(u8, tag_area[tag_idx .. tag_idx + eql_pos], std.ascii.spaces[0..]);
                        const end_pos = std.mem.indexOf(u8, tag_area[tag_idx + eql_pos + 2 ..], "\"") orelse return error.InvalidTag;
                        const value_tag = tag_area[(tag_idx + eql_pos + 2)..(tag_idx + eql_pos + 2 + end_pos)];
                        try tags.append(.{
                            .name = name_tag,
                            .val = value_tag,
                        });
                        tag_idx += eql_pos + 2 + end_pos + 1;
                    }
                }
                //var end_count: usize = 0;
                //while (end_count < 6) : (end_count += 1) {
                //std.debug.print("|[{}={c}||\n", .{ @intCast(isize, end_count) - 3, val[idx.count + end_count - 3] });
                //}
                if (val[idx.count - 3] == '/') {
                    var newNode = try alloc.create(XMLNode);
                    newNode.* = XMLNode{
                        .alloc = alloc,
                        .parent = curNode,
                        .name = name,
                        .tags = tags.items,
                        .contents = std.ArrayList(XMLContents).init(alloc),
                    };
                    try curNode.contents.append(.{
                        .node = newNode,
                    });
                } else {
                    var newNode = try alloc.create(XMLNode);

                    newNode.* = XMLNode{
                        .alloc = alloc,
                        .parent = curNode,
                        .name = name,
                        .tags = tags.items,
                        .contents = std.ArrayList(XMLContents).init(alloc),
                    };
                    try curNode.contents.append(.{
                        .node = newNode,
                    });
                    curNode = newNode;
                }
            },
        }
    }

    return rootNode;
}
