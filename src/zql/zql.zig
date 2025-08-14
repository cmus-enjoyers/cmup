// Example of a ZQL query:
//
// require jump-bangers, vktrenokh-stwv
//
// add all from jump-bangers
// add all from vktrenokh-stwv where name contains 'voj'
//

// The name of the new playlist should be derived from the ZQL file name
// (e.g., "vktrenokh-eurobeat.zql" => "vktrenokh-eurobeat").
//
// The `require` statement specifies which playlists will be used to create the new playlist.
// - If a playlist is referenced later in the query but is not defined using `require`,
//   the query should terminate with an error.
// - If a playlist is defined in the `require` statement but is not found by the `zmup` program,
//   the query should also terminate with an error.
//
// String literals should only be created using double quotes ("").
// The double quote character (") within a string can be escaped using the backslash (\) character.

const std = @import("std");
const getFileNameWithoutExtension = @import("../utils/path.zig").getFileNameWithoutExtension;

const Lexer = @import("lexer.zig").Lexer;
const Parser = @import("ast.zig").Parser;
const executr = @import("executor.zig");
const Executor = executr.Executor;

const cmup = @import("../cmup/cmup.zig");
const CmupPlaylist = cmup.CmupPlaylist;

pub const SideEffect = executr.SideEffect;

const colors = @import("../utils/colors.zig");

pub fn run(
    parent_allocator: std.mem.Allocator,
    map: std.StringHashMap(CmupPlaylist),
    path: []const u8,
) !executr.ExecutorResult {
    var arena = std.heap.ArenaAllocator.init(parent_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    var file = try std.fs.cwd().openFile(path, .{ .mode = .read_only });
    var buf_reader = std.io.bufferedReader(file.reader());
    var stream = buf_reader.reader();

    const query = try stream.readAllAlloc(allocator, 102400);

    var lexer = Lexer.init(query, allocator);
    defer lexer.deinit();

    try lexer.parse();

    var parser = Parser.init(&lexer, allocator);
    defer parser.deinit();

    try parser.parse();

    var executor = Executor.init(allocator, map, parser.nodes.items, std.io.getStdErr(), query);

    return executor.execute(getFileNameWithoutExtension(path));
}
