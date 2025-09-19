const zql = @import("zql/zql.zig");
const cmup = @import("cmup/cmup.zig");
const clear = @import("cmup/clear.zig").clearPlaylists;
const std = @import("std");
const colors = @import("utils/colors.zig");
const CmupPlaylist = cmup.CmupPlaylist;
const path_utils = @import("utils/path.zig");

pub fn printSuccess() !void {
    const writer = std.fs.File.stdout();

    try writer.writeAll("\nUpdated playlists :)\n");
}

pub fn printInfo() !void {
    const writer = std.fs.File.stdout();

    try writer.writeAll("If you wish to write playlists into your cmus config playlists\ntry adding --write flag");
}

pub fn hasArg(args: [][:0]u8, comptime arg_name: []const u8) bool {
    for (args) |arg| {
        if (std.mem.eql(u8, arg, arg_name)) {
            return true;
        }
    }
    return false;
}

pub fn getArgValue(args: [][:0]u8, comptime key: []const u8) ![]const u8 {
    for (args, 0..) |arg, i| {
        if (std.mem.eql(u8, arg, key)) {
            const next_arg = args[i + 1];

            if (std.mem.eql(u8, next_arg, &[_]u8{0})) {
                return error.NoValueForArgument;
            }

            return next_arg;
        }
    }

    return error.NoArg;
}

pub fn printQueriesInfo(out: std.fs.File.Writer, queries_amount: usize, is_pure: bool) !void {
    const pure_text = if (is_pure) " (Pure)" else "";

    try out.print(
        colors.green_text("Zql{s}" ++ colors.dim_text(": ") ++ "{} queries found \n\n"),
        .{ pure_text, queries_amount },
    );
}

pub fn putCmupPlaylist(map: *std.StringHashMap(CmupPlaylist), playlist: CmupPlaylist) !void {
    try map.put(playlist.name, playlist);

    for (playlist.sub_playlists) |sub_playlist| {
        try putCmupPlaylist(map, sub_playlist.*);
    }
}

pub fn removePlaylist(
    allocator: std.mem.Allocator,
    playlists_path: []const u8,
    path: []const u8,
) !void {
    const playlist_path = try std.fs.path.join(allocator, &[_][]const u8{ playlists_path, path });
    defer allocator.free(playlist_path);

    try std.fs.deleteFileAbsolute(playlist_path);
}

pub fn executeSideEffects(allocator: std.mem.Allocator, side_effects: []zql.SideEffect, playlist_path: []const u8) !void {
    for (side_effects) |side_effect| {
        switch (side_effect) {
            .Remove => |data| try removePlaylist(allocator, playlist_path, data.playlist),
        }
    }
}

pub fn executeZqls(
    allocator: std.mem.Allocator,
    zql_src: []cmup.ZqlSrc,
    map: std.StringHashMap(CmupPlaylist),
    playlist_path: []const u8,
    stdout: std.fs.File.Writer,
    pure: bool,
) !void {
    for (zql_src) |src| {
        var result = zql.run(allocator, map, src.src) catch {
            std.process.exit(1);
        };

        const name = path_utils.getFileNameWithoutExtension(src.src);

        if (cmup.endsWithDollar(name)) {
            // TODO: fix memory leak here
            result.playlist.name = try cmup.formatSubPlaylist(allocator, src.parent_name, name[0 .. name.len - 1]);
        }

        try cmup.writeCmupPlaylist(result.playlist, playlist_path);

        try stdout.print(colors.green_text("") ++ " {s}\n", .{result.playlist.name});

        if (!pure) {
            try executeSideEffects(allocator, result.side_effects.items, playlist_path);
        }
    }
}

pub fn cmupPlaylistsToHashMap(
    allocator: std.mem.Allocator,
    playlists: []CmupPlaylist,
) !std.StringHashMap(CmupPlaylist) {
    var map = std.StringHashMap(CmupPlaylist).init(allocator);

    for (playlists) |playlist| {
        try putCmupPlaylist(&map, playlist);
    }

    return map;
}

pub fn normalizeInputPath(allocator: std.mem.Allocator, home: []const u8, input: []const u8) ![]u8 {
    if (std.fs.path.isAbsolute(input)) {
        return @constCast(input);
    }

    return std.fs.path.join(allocator, &.{ home, input });
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    const args = try std.process.argsAlloc(allocator);

    defer std.process.argsFree(allocator, args);

    const has_write = hasArg(args, "--write");

    const input = getArgValue(args, "--input") catch null;

    const home = std.posix.getenv("HOME");

    if (home) |value| {
        const cmus_playlist_path = try std.fs.path.join(allocator, &[_][]const u8{ value, ".config/cmus/playlists" });

        const cmus_music_path = try if (input) |input_path| normalizeInputPath(allocator, value, input_path) else std.fs.path.join(allocator, &.{ value, "Music" });

        const stdout = std.fs.File.stdout();

        if (args.len == 2 and std.mem.eql(u8, args[1], "clear")) {
            try clear(cmus_playlist_path);
            try stdout.writeAll("cleared playlists\n");
            return;
        }

        var result = try cmup.cmup(allocator, has_write, cmus_music_path, cmus_playlist_path);
        defer result.deinit(allocator);

        var map = try cmupPlaylistsToHashMap(allocator, result.playlists.items);
        defer map.deinit();

        if (hasArg(args, "--print-everything")) {
            try cmup.printCmupPlaylists(allocator, result.playlists.items, "");
        }

        const is_pure = hasArg(args, "--pure");

        try printQueriesInfo(stdout, result.zql.items.len, is_pure);

        if (has_write) {
            try executeZqls(allocator, result.zql.items, map, cmus_playlist_path, stdout, hasArg(args, "--pure"));
            try printSuccess();
        } else {
            try printInfo();
        }
    } else {
        return error.NoHome;
    }
}
