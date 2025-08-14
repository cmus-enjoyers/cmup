const std = @import("std");

pub fn clearPlaylists(path: []const u8) !void {
    var dir = try std.fs.openDirAbsolute(path, .{ .iterate = true });
    defer dir.close();

    var iter = dir.iterate();

    while (try iter.next()) |file| {
        try dir.deleteFile(file.name);
    }
}
