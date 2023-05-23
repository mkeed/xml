const Tag = struct {
    name: []const u8,
    val: []const u8,
};

fn tag(name: []const u8, val: []const u8) Tag {
    return .{ .name = name, .val = val };
}

const Node = struct {
    name: []const u8,
    tags: []const Tag,
    contents: []const NodeContents,
    pub const NodeContents = union(enum) {
        child: Node,
        val: []const u8,
    };
};

const TestCase = struct {
    input: []const u8,
    structure: Node,
};

const TCs = [_]TestCase{
    .{
        .input =
        ,
        .structure = .{
            .name = "note",
            .tag = &.{},
            .contents = &.{
                .{},
            },
        },
    },
};
