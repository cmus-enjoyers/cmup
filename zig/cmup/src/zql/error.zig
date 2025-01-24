const std = @import("std");
const colors = @import("../utils/colors.zig");

pub fn print(allocator: std.mem.Allocator, out: std.fs.File, line: usize, lexeme: []const u8, input: []const u8) !void {
    const line_end = if (std.ascii.indexOfIgnoreCasePos(input, line + 1, "\n")) |value| value else input.len;

    const err_line = input[line..line_end];

    const index = std.ascii.indexOfIgnoreCase(err_line, lexeme).?;

    const text = try colors.redUndercurledTextRuntime(allocator, lexeme);
    defer allocator.free(text);

    const msg = try std.mem.join(allocator, "", &[_][]const u8{
        err_line[0..index],
        text,
        err_line[index + lexeme.len ..],
    });

    const message = try std.fmt.allocPrint(
        allocator,
        colors.red_text("Error") ++ colors.dim_text(" => ") ++ "Unterminated string\n" ++ "{s}",
        .{msg},
    );
    defer allocator.free(message);

    try out.writeAll(message);
}
