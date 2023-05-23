const std = @import("std");
const xml = @import("xml");

const NodeCount = struct {
    query: []const []const u8,
    expectedResult: usize,
};

const Test = union(enum) {
    nodeCount: NodeCount,
};

const TestCase = struct {
    input: []const u8,
    tests: []const Test,
};

const tcs = [_]TestCase{
    .{
        .input =
        \\<?xml version="1.0" encoding="UTF-8"?>
        \\<protocol name="wayland">
        \\</protocol>
        ,
        .tests = &.{
            .{
                .nodeCount = .{
                    .query = &.{"protocol"},
                    .expectedResult = 1,
                },
            },
        },
    },
};

test {
    var alloc = std.testing.allocator;
    var nodes = std.ArrayList(*xml.XMLNode).init(alloc);
    defer nodes.deinit();
    for (tcs) |tc| {
        var tree = try xml.ParseXML(alloc, tc.input);
        defer tree.deinit();
        for (tc.tests) |subTest| {
            switch (subTest) {
                .nodeCount => |nc| {
                    nodes.clearRetainingCapacity();
                    try tree.getNodes(&nodes, nc.query);
                    try std.testing.expectEqual(nodes.items.len, nc.expectedResult);
                },
            }
        }
    }
}

const xmlTest =
    \\<?xml version="1.0" encoding="UTF-8"?>
    \\<a name="1">
    \\  <a name="11">
    \\  </a>
    \\  <a name="12">
    \\  </a>
    \\  <a name="13">
    \\  </a>
    \\  <b name="14">
    \\  </b>
    \\  <b name="15">
    \\  </b>
    \\  <a name="16">
    \\  </a>
    \\</a>
    \\<a name="2">
    \\</a>
    \\<a name="3">
    \\</a>
    \\<b name="4">
    \\</b>
    \\<b name="5">
    \\</b>
    \\<a name="6">
    \\</a>
;

const IterTest = struct {
    query: []const []const u8,
    expectedResults: []const []const u8,
    tagName: []const u8,
};

test {
    var alloc = std.testing.allocator;
    var tree = try xml.ParseXML(alloc, xmlTest);
    defer tree.deinit();

    const tests = [_]IterTest{
        .{ .query = &.{"a"}, .expectedResults = &.{ "1", "2", "3", "6" }, .tagName = "name" },
        .{ .query = &.{ "a", "b" }, .expectedResults = &.{ "14", "15" }, .tagName = "name" },
    };

    for (tests, 0..) |tc, testIdx| {
        var iter = tree.nodesIter(tc.query);
        for (tc.expectedResults, 0..) |r, idx| {
            if (iter.next()) |val| {
                const tagVal = val.getTag(tc.tagName);
                if (tagVal) |tv| {
                    try std.testing.expectEqualStrings(r, tv);
                } else {
                    std.log.err("Tag {s} not found", .{tc.tagName});
                    try std.testing.expect(false);
                }
            } else {
                std.log.err("expected another value got null[test:{} {}]", .{ testIdx, idx });
                try std.testing.expect(false);
            }
        }
    }
}
