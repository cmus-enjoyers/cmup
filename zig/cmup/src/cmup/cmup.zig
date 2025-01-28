const std = @import("std");

pub const CmupPlaylist = struct {
    name: []const u8,
    content: [][]const u8,
    path: []const u8,
    sub_playlists: []*CmupPlaylist,
};

const CmupReadPlaylist = struct {
    items: [][]const u8,
    sub_playlists: []*CmupPlaylist,
};

const cmup_used_music_extensions: []const []const u8 = &[_][]const u8{
    "flac",
    "mp3",
    "opus",
};

const reset = "\x1b[0m";
const green = "\x1b[32m";
const red = "\x1b[31m";

pub fn isMusic(file_name: []const u8) bool {
    for (cmup_used_music_extensions) |ext| {
        if (file_name.len <= ext.len) {
            return false;
        }

        if (std.ascii.endsWithIgnoreCase(file_name, ext)) {
            return true;
        }
    }

    return false;
}

pub fn getDirEntryNames(allocator: std.mem.Allocator, path: []const u8) anyerror!std.ArrayList([]const u8) {
    var dir = try std.fs.openDirAbsolute(path, .{ .iterate = true });
    defer dir.close();
    var iterator = dir.iterate();

    var result = std.ArrayList([]const u8).init(allocator);

    while (try iterator.next()) |value| {
        switch (value.kind) {
            .directory => try result.append(try allocator.dupe(u8, value.name)),
            else => try printUnsuportedEntryError(value.name),
        }
    }

    return result;
}

pub fn addMusicToPlaylist(allocator: std.mem.Allocator, path: []const u8, result: *std.ArrayList([]const u8), entry: std.fs.Dir.Entry) !void {
    if (isMusic(entry.name)) {
        try result.append(try std.fs.path.join(allocator, &.{ path, entry.name }));
    }
}
pub fn printUnsuportedEntryError(name: []const u8) !void {
    const writer = std.io.getStdErr().writer();

    try writer.print(red ++ "CmupErr" ++ reset ++ ": Unknown entry format at {s}\n", .{name});
}

pub fn endsWithDollar(string: []const u8) bool {
    return std.ascii.endsWithIgnoreCase(string, "$");
}

pub fn createCmusSubPlaylist(
    allocator: std.mem.Allocator,
    ptrs: *std.ArrayList(*CmupPlaylist),
    cmus_path: []const u8,
    parent_path: []const u8,
    name: []const u8,
) anyerror!void {
    const playlist = try allocator.create(CmupPlaylist);

    playlist.* = try createCmupPlaylist(allocator, try allocator.dupe(u8, name), cmus_path, parent_path);

    if (playlist.content.len > 0) {
        try ptrs.append(playlist);
    }
}

pub fn readCmupPlaylist(allocator: std.mem.Allocator, path: []const u8, cmus_path: []const u8) anyerror!CmupReadPlaylist {
    var dir = try std.fs.openDirAbsolute(path, .{ .iterate = true });
    var iterator = dir.iterate();

    var ptrs = std.ArrayList(*CmupPlaylist).init(allocator);

    var result = std.ArrayList([]const u8).init(allocator);

    while (try iterator.next()) |item| {
        switch (item.kind) {
            .file => try addMusicToPlaylist(allocator, path, &result, item),
            .directory => try createCmusSubPlaylist(allocator, &ptrs, cmus_path, path, item.name),
            else => try printUnsuportedEntryError(item.name),
        }
    }

    return CmupReadPlaylist{
        .items = result.items,
        .sub_playlists = ptrs.items,
    };
}

pub fn removeLast(string: []const u8) []const u8 {
    return string[0 .. string.len - 1];
}

pub fn expandDollar(allocator: std.mem.Allocator, path: []const u8, entry: []const u8) anyerror![]const u8 {
    return try std.mem.join(allocator, "-", &[_][]const u8{ std.fs.path.basename(path), entry });
}

pub fn createCmupPlaylist(allocator: std.mem.Allocator, entry: []const u8, cmus_path: []const u8, cmus_parent_path: ?[]const u8) anyerror!CmupPlaylist {
    const is_dollared = endsWithDollar(entry);

    const true_name = if (is_dollared) try expandDollar(allocator, cmus_parent_path orelse cmus_path, removeLast(entry)) else entry;

    const path = try std.fs.path.join(allocator, &.{ cmus_parent_path orelse cmus_path, entry });

    const content = try readCmupPlaylist(allocator, path, cmus_path);

    return CmupPlaylist{
        .name = true_name,
        .path = path,
        .content = content.items,
        .sub_playlists = content.sub_playlists,
    };
}

pub fn writeCmupPlaylist(playlist: CmupPlaylist, path: []const u8) !void {
    if (playlist.content.len > 0) {
        var dir = try std.fs.openDirAbsolute(path, .{});
        defer dir.close();

        var file = try dir.createFile(playlist.name, .{});
        defer file.close();

        const newline = comptime "\n";

        for (playlist.content) |music| {
            try file.writeAll(music);
            try file.writeAll(newline);
        }
    }

    for (playlist.sub_playlists) |sub_playlist| {
        if (sub_playlist.content.len > 0) {
            try writeCmupPlaylist(sub_playlist.*, path);
        }
    }
}

pub fn cmup(allocator: std.mem.Allocator, write: ?bool, music_path: []const u8, playlist_path: []const u8) anyerror!std.ArrayList(CmupPlaylist) {
    const playlists = getDirEntryNames(allocator, music_path) catch blk: {
        break :blk try getDirEntryNames(allocator, try std.fs.path.join(allocator, &.{
            std.fs.path.dirname(music_path).?,
            "music",
        }));
    };

    var result = std.ArrayList(CmupPlaylist).init(allocator);

    for (playlists.items) |value| {
        if (std.ascii.startsWithIgnoreCase(value, ".")) {
            continue;
        }

        const playlist = try createCmupPlaylist(allocator, value, music_path, null);

        if (write orelse false) {
            try writeCmupPlaylist(playlist, playlist_path);
        }

        try result.append(playlist);
    }

    return result;
}

pub fn printCmupPlaylist(playlist: CmupPlaylist, comptime spacing: []const u8) !void {
    const writer = std.io.getStdOut().writer();

    try writer.print("Playlist" ++ green ++ " {s} " ++ reset ++ "on path {s} with musics amount {}\n", .{ playlist.name, playlist.path, playlist.content.len });

    for (playlist.content) |value| {
        try writer.print(spacing ++ "  {s}\n", .{value});
    }

    for (playlist.sub_playlists) |sub_playlist| {
        try printCmupPlaylist(sub_playlist.*, "  ");
    }
}

pub fn printCmupPlaylists(playlists: []const CmupPlaylist, comptime spacing: []const u8) !void {
    for (playlists) |item| {
        try printCmupPlaylist(item, spacing);
    }
}

pub fn hasArg(args: [][]u8, comptime arg_name: []const u8) bool {
    for (args) |arg| {
        if (std.mem.eql(u8, arg, arg_name)) {
            return true;
        }
    }
    return false;
}
