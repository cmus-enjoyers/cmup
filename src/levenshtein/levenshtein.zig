const std = @import("std");

pub fn levenshteinDistance(allocator: std.mem.Allocator, s1: []const u8, s2: []const u8) !usize {
    const len1 = s1.len;
    const len2 = s2.len;

    var matrix = try allocator.alloc(usize, (len1 + 1) * (len2 + 1));
    defer allocator.free(matrix);

    for (0..len1 + 1) |i| {
        matrix[i * (len2 + 1)] = i;
    }
    for (0..len2 + 1) |j| {
        matrix[j] = j;
    }

    for (1..len1 + 1) |i| {
        for (1..len2 + 1) |j| {
            const cost: usize = if (s1[i - 1] == s2[j - 1]) 0 else 1;
            matrix[i * (len2 + 1) + j] = @min(
                @min(matrix[(i - 1) * (len2 + 1) + j] + 1, matrix[i * (len2 + 1) + (j - 1)] + 1),
                matrix[(i - 1) * (len2 + 1) + (j - 1)] + cost,
            );
        }
    }

    return matrix[len1 * (len2 + 1) + len2];
}
