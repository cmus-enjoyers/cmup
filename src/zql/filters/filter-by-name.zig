const std = @import("std");
const CmupPlaylist = @import("../../cmup/cmup.zig").CmupPlaylist;
const Filter = @import("../ast.zig").Filter;
const path = @import("../../utils/path.zig");

pub fn filterByName(result: *std.ArrayList([]const u8), playlist: CmupPlaylist, filter: Filter) !void {
    for (playlist.content) |track| {
        const name = path.getFileNameWithoutExtension(track);
        const target = filter.target.lexeme;

        switch (filter.match_type.data) {
            .Contains => {
                if (std.ascii.indexOfIgnoreCase(name, target) != null) {
                    try result.append(track);
                }
            },
            .Is => {
                if (std.mem.eql(u8, name, target)) {
                    try result.append(track);
                }
            },
        }
    }
}
