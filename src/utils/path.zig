const std = @import("std");

pub fn getFileNameWithoutExtension(path: []const u8) []const u8 {
    const file_name = std.fs.path.basename(path);

    if (std.mem.lastIndexOfScalar(u8, file_name, '.')) |dot_index| {
        return file_name[0..dot_index];
    }

    return file_name;
}
