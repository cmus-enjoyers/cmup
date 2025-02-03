// NOTE: move filtering logic into separate module cuz it wlll grow

const std = @import("std");
const path = @import("../utils/path.zig");
const CmupPlaylist = @import("../cmup/cmup.zig").CmupPlaylist;
const Ast = @import("ast.zig");
const Token = @import("lexer.zig").Token;
const NodeType = Ast.NodeType;
const ASTNode = Ast.ASTNode;
const filterByName = @import("filters/filter-by-name.zig").filterByName;
const err = @import("error.zig");

pub const SideEffectType = enum {
    Remove,
};

pub const RemoveEffect = struct { playlist: []const u8 };

pub const SideEffect = union(SideEffectType) { Remove: RemoveEffect };

pub const ExecutorResult = struct {
    playlist: CmupPlaylist,
    side_effects: std.ArrayList(SideEffect),

    pub fn deinit(result: ExecutorResult) void {
        result.side_effects.deinit();
    }
};

pub const Executor = struct {
    playlists: std.StringHashMap(CmupPlaylist),
    ast: []ASTNode,
    allocator: std.mem.Allocator,
    identifiers: std.StringHashMap(CmupPlaylist),
    stderr: std.fs.File,
    input: []const u8,

    pub fn init(
        allocator: std.mem.Allocator,
        playlists: std.StringHashMap(CmupPlaylist),
        ast: []ASTNode,
        stderr: std.fs.File,
        input: []const u8,
    ) Executor {
        return Executor{
            .playlists = playlists,
            .allocator = allocator,
            .identifiers = std.StringHashMap(CmupPlaylist).init(allocator),
            .ast = ast,
            .stderr = stderr,
            .input = input,
        };
    }

    pub fn deinit(executor: *Executor) void {
        executor.identifiers.deinit();
        executor.side_effects.deinit();
    }

    pub fn printErr(executor: *Executor, token: Token, er: err.Error) !void {
        try token.printErr(
            executor.allocator,
            executor.stderr,
            er,
            executor.input,
        );
    }

    pub fn executeRequire(executor: *Executor, data: Ast.RequireData) !void {
        for (data.sources) |source| {
            if (executor.playlists.get(source.source.lexeme)) |playlist| {
                try executor.identifiers.put(
                    if (source.as) |as| as.lexeme else source.source.lexeme,
                    playlist,
                );

                continue;
            }

            try executor.printErr(source.source, err.Error.PlaylistNotFound);
            return error.NoPlaylist;
        }
    }

    pub fn filterPlaylist(executor: *Executor, filters: []Ast.ASTFilter, playlist: CmupPlaylist) !std.ArrayList([]const u8) {
        var result = std.ArrayList([]const u8).init(executor.allocator);

        for (filters) |filter| {
            if (std.mem.eql(u8, filter.data.field.lexeme, "name")) {
                try filterByName(&result, playlist, filter.data);
            }
        }

        return result;
    }

    pub fn executeAdd(executor: *Executor, result: *std.ArrayList([]const u8), data: Ast.AddData) !void {
        if (executor.identifiers.get(data.source.lexeme)) |value| {
            if (data.filters) |filters| {
                const tracks = try executor.filterPlaylist(filters, value);

                try result.appendSlice(tracks.items);

                return;
            }

            try result.appendSlice(value.content);

            return;
        }

        try executor.printErr(data.source, err.Error.ReferenceError);
        return error.ReferenceError;
    }

    pub fn executeHide(executor: *Executor, side_effects: *std.ArrayList(SideEffect), data: Ast.HideData) !void {
        const playlist: CmupPlaylist = executor.identifiers.get(data.playlist.lexeme) orelse {
            try executor.printErr(data.playlist, err.Error.ReferenceError);
            return error.ReferenceError;
        };

        try side_effects.append(SideEffect{
            .Remove = .{ .playlist = playlist.name },
        });
    }

    pub fn execute(executor: *Executor, name: []const u8) !ExecutorResult {
        var result = std.ArrayList([]const u8).init(executor.allocator);
        var side_effects = std.ArrayList(SideEffect).init(executor.allocator);

        for (executor.ast) |node| {
            try switch (node.data) {
                NodeType.RequireStatement => |data| executor.executeRequire(data),
                NodeType.AddStatement => |data| executor.executeAdd(&result, data),
                NodeType.HideStatement => |data| executor.executeHide(&side_effects, data),
            };
        }

        return ExecutorResult{
            .side_effects = side_effects,
            .playlist = CmupPlaylist{
                .name = name,
                .content = result.items,
                .path = "",
                .sub_playlists = &[_]*CmupPlaylist{},
            },
        };
    }
};
