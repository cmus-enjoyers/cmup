const std = @import("std");

pub const reset = "\x1b[0m";
pub const green = "\x1b[32m";
pub const red = "\x1b[31m";
pub const dim = "\x1b[2m";
pub const red_undercurled_text = "\x1b[4:3;31m";

pub fn dim_text(comptime text: []const u8) []const u8 {
    return dim ++ text ++ reset;
}

pub fn green_text(comptime text: []const u8) []const u8 {
    return green ++ text ++ reset;
}

pub fn red_text(comptime text: []const u8) []const u8 {
    return red ++ text ++ reset;
}

pub fn redUndercurledText(comptime text: []const u8) []const u8 {
    return red_undercurled_text ++ text ++ reset;
}

pub fn redUndercurledTextRuntime(allocator: std.mem.Allocator, text: []const u8) ![]const u8 {
    return try std.mem.join(allocator, "", &[_][]const u8{ red_undercurled_text, text, reset });
}
