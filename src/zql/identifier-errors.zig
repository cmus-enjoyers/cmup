const std = @import("std");
const CmupPlaylist = @import("../cmup/cmup.zig").CmupPlaylist;
const levenshteinDistance = @import("../levenshtein/levenshtein.zig").levenshteinDistance;

pub const IdentifierLevenshteinDistance = struct {
    value: *[]const u8,
    distance: usize,
};

fn identifierDistanceLessThan(context: void, a: IdentifierLevenshteinDistance, b: IdentifierLevenshteinDistance) bool {
    _ = context;

    return a.distance < b.distance;
}

pub fn findClosestIdentifier(allocator: std.mem.Allocator, map: std.StringHashMap(CmupPlaylist), identifier: []const u8) ![]const u8 {
    var iter = map.iterator();
    var array = std.ArrayList(IdentifierLevenshteinDistance).init(allocator);
    defer array.deinit();

    while (iter.next()) |value| {
        try array.append(
            IdentifierLevenshteinDistance{
                .value = value.key_ptr,
                .distance = try levenshteinDistance(
                    allocator,
                    value.key_ptr.*,
                    identifier,
                ),
            },
        );
    }

    std.sort.insertion(IdentifierLevenshteinDistance, array.items, {}, identifierDistanceLessThan);

    return array.items[0].value.*;
}
