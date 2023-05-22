const TestCase = struct {
    input: []const u8,
};

const TCs = [_]TestCase{
    .{ .input = 
    \\<note>
    \\  <to>Tove</to>
    \\  <from>Jani</from>
    \\  <heading>Reminder</heading>
    \\  <body>Don't forget me this weekend!</body>
    \\</note>
    },
};
