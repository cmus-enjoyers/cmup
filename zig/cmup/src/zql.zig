// Example of a ZQL query:
//
// require jump-bangers, vktrenokh-stwv
//
// add all from jump-bangers and add all from vktrenokh-stwv where name contains 'voj'
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
// String literals should only be created using single quotes ('').
// The single quote character (') within a string can be escaped using the backslash (\) character.

const std = @import("std");
const colors = @import("colors.zig");

pub const TokenType = enum {
    Require,
    Identifier,
    String,
    EOL,
    Add,
    Unknown, // remove in future
};

pub const Token = struct {
    type: TokenType,
    lexeme: []const u8,

    pub fn print(self: Token) void {
        const token_type_fmt = comptime colors.green_text("{s}");
        const token_type = @tagName(self.type);

        if (self.lexeme.len > 0) {
            std.debug.print(
                token_type_fmt ++ colors.dim_text(":") ++ " {s}; ",
                .{ token_type, self.lexeme },
            );
        } else {
            std.debug.print(
                token_type_fmt ++ ";",
                .{token_type},
            );
        }
    }
};

const Lexer = struct {
    input: []const u8,
    position: usize,
    tokens: std.ArrayList(Token),
    allocator: std.mem.Allocator,

    pub fn init(input: []const u8, allocator: std.mem.Allocator) Lexer {
        return Lexer{
            .input = input,
            .position = 0,
            .tokens = std.ArrayList(Token).init(allocator),
            .allocator = allocator,
        };
    }

    pub inline fn getCurrentSymbol(lexer: *Lexer) u8 {
        return lexer.input[lexer.position];
    }

    pub fn getLastToken(lexer: Lexer) ?Token {
        return lexer.tokens.items[lexer.tokens.items.len - 1];
    }

    pub fn getTokenType(lexer: Lexer, lexeme: []const u8) TokenType {
        if (std.mem.eql(u8, lexeme, "require")) {
            return TokenType.Require;
        }

        if (std.mem.eql(u8, lexeme, "add")) {
            return TokenType.Add;
        }

        if (lexer.getLastToken()) |token| {
            if (token.type == .Require or token.type == .Add) {
                return TokenType.Identifier;
            }
        }

        return TokenType.Unknown;
    }

    pub fn shouldConsume(lexer: *Lexer, isString: bool) bool {
        if (isString) {
            if (lexer.getCurrentSymbol() != '\'') {
                return true;
            }

            lexer.position += 1;

            return false;
        }

        return !std.ascii.isWhitespace(lexer.getCurrentSymbol());
    }

    pub fn addEolToken(lexer: *Lexer) !Token {
        const token = Token{ .type = .EOL, .lexeme = "" };

        try lexer.tokens.append(token);

        return token;
    }

    pub fn nextToken(lexer: *Lexer) !?Token {
        if (lexer.position == lexer.input.len - 1) {
            return try lexer.addEolToken();
        }

        while (std.ascii.isWhitespace(lexer.getCurrentSymbol())) {
            lexer.position += 1;
        }

        const start = lexer.position;

        const is_string = lexer.input[start] == '\'';

        if (is_string) {
            lexer.position += 1;
        }

        const stderr = std.io.getStdErr();

        while (lexer.shouldConsume(is_string)) {
            if (is_string) {
                if (lexer.position == lexer.input.len - 1) {
                    const message = try std.fmt.allocPrint(
                        lexer.allocator,
                        colors.red_text("Error") ++ colors.dim_text(" => ") ++ "Unterminated string at {}",
                        .{lexer.position},
                    );

                    try stderr.writeAll(message);

                    lexer.allocator.free(message);

                    return error.UnterminatedString;
                }
            }

            lexer.position += 1;
        }

        const lexeme = lexer.input[start..lexer.position];

        const token = Token{
            .type = if (is_string) TokenType.String else lexer.getTokenType(lexeme),
            .lexeme = lexeme,
        };

        try lexer.tokens.append(token);

        return token;
    }
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    var lexer = Lexer.init(@embedFile("./test.zql"), allocator);

    while (lexer.nextToken() catch return) |val| {
        if (val.type == .EOL) {
            break;
        }
    }

    for (lexer.tokens.items) |token| {
        token.print();
    }

    std.debug.print("\n\n\n{}", .{std.json.fmt(lexer.tokens.items, .{ .whitespace = .indent_4 })});
}
