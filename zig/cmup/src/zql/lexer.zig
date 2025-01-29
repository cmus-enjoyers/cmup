const std = @import("std");
const colors = @import("../utils/colors.zig");
const err = @import("error.zig");

pub const TokenType = enum {
    Require,
    Identifier,
    String,
    EOL,
    Add,
    All,
    From,
    Where,
    MatchType,

    Unknown,
};

pub fn isNewline(value: u8) bool {
    return value == '\n';
}

pub const Token = struct {
    type: TokenType,
    lexeme: []const u8,
    line: usize,
    line_position: usize,

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

    pub fn printErr(token: Token, allocator: std.mem.Allocator, out: std.fs.File, er: err.Error, input: []const u8) !void {
        try err.printToken(
            allocator,
            out,
            er,
            token.line_position,
            token.line,
            token.lexeme,
            input,
        );
    }
};

const ContextType = enum {
    Require,
    Add,
    Where,
    Comment,
};

pub const Lexer = struct {
    input: []const u8,
    position: usize,
    tokens: std.ArrayList(Token),
    context_stack: std.ArrayList(ContextType),
    allocator: std.mem.Allocator,
    line_position: usize,
    line: usize,

    pub fn init(input: []const u8, allocator: std.mem.Allocator) Lexer {
        return Lexer{
            .input = input,
            .position = 0,
            .tokens = std.ArrayList(Token).init(allocator),
            .context_stack = std.ArrayList(ContextType).init(allocator),
            .allocator = allocator,
            .line_position = 0,
            .line = 1,
        };
    }

    pub fn deinit(lexer: *Lexer) void {
        lexer.tokens.deinit();
        lexer.context_stack.deinit();
    }

    pub fn pushContext(lexer: *Lexer, context: ContextType) !void {
        try lexer.context_stack.append(context);
    }

    pub fn popContext(lexer: *Lexer) ?ContextType {
        return lexer.context_stack.popOrNull();
    }

    pub fn peekContext(lexer: *Lexer) ?ContextType {
        if (lexer.context_stack.items.len > 0) {
            return lexer.context_stack.items[lexer.context_stack.items.len - 1];
        }

        return null;
    }

    pub inline fn getCurrentSymbol(lexer: *Lexer) u8 {
        return lexer.input[lexer.position];
    }

    pub fn getLastToken(lexer: Lexer) ?Token {
        return lexer.tokens.items[lexer.tokens.items.len - 1];
    }

    pub fn getTokenType(lexer: *Lexer, lexeme: []const u8) !TokenType {
        if (std.mem.eql(u8, lexeme, "require")) {
            try lexer.pushContext(ContextType.Require);
            return TokenType.Require;
        }

        if (std.mem.eql(u8, lexeme, "add")) {
            try lexer.pushContext(ContextType.Add);
            return TokenType.Add;
        }

        if (std.mem.eql(u8, lexeme, "from")) {
            return TokenType.From;
        }

        if (std.mem.eql(u8, lexeme, "all")) {
            return TokenType.All;
        }

        if (std.mem.eql(u8, lexeme, "where")) {
            try lexer.pushContext(ContextType.Where);
            return TokenType.Where;
        }

        if (std.mem.eql(u8, lexeme, "contains") or std.mem.eql(u8, lexeme, "is")) {
            return TokenType.MatchType;
        }

        if (lexer.peekContext()) |context| {
            return switch (context) {
                .Require, .Where, .Add => TokenType.Identifier,
                // TODO: implement comments
                .Comment => TokenType.Unknown,
            };
        }

        return TokenType.Unknown;
    }

    pub fn shouldConsume(lexer: *Lexer, is_string: bool) bool {
        if (is_string) {
            if (lexer.getCurrentSymbol() != '\'') {
                return true;
            }

            lexer.position += 1;

            return false;
        }

        return !std.ascii.isWhitespace(lexer.getCurrentSymbol());
    }

    pub fn addEolToken(lexer: *Lexer) !Token {
        const token = Token{
            .type = .EOL,
            .lexeme = "",
            .line = lexer.line,
            .line_position = lexer.line_position,
        };

        try lexer.tokens.append(token);

        return token;
    }

    pub fn handleNewLine(lexer: *Lexer) void {
        lexer.line_position = lexer.position;
        lexer.line += 1;
    }

    pub fn skipWhitespaces(lexer: *Lexer) void {
        while (std.ascii.isWhitespace(lexer.getCurrentSymbol())) {
            lexer.position += 1;

            if (isNewline(lexer.getCurrentSymbol()) and lexer.position != lexer.input.len - 1) {
                lexer.handleNewLine();
            }
        }
    }

    pub fn nextToken(lexer: *Lexer) !?Token {
        if (lexer.position == lexer.input.len - 1) {
            return try lexer.addEolToken();
        }

        lexer.skipWhitespaces();

        const start = lexer.position;

        const is_string = lexer.input[start] == '\'';

        if (is_string) {
            lexer.position += 1;
        }

        const stderr = std.io.getStdErr();

        while (lexer.shouldConsume(is_string)) {
            if (is_string) {
                if (lexer.position == lexer.input.len - 1) {
                    try err.printToken(
                        lexer.allocator,
                        stderr,
                        err.Error.UnterminatedString,
                        lexer.line_position,
                        lexer.line,
                        lexer.input[start..lexer.position],
                        lexer.input,
                    );

                    return error.UnterminatedString;
                }
            }

            lexer.position += 1;

            if (isNewline(lexer.getCurrentSymbol()) and lexer.position != lexer.input.len - 1) {
                lexer.handleNewLine();
            }
        }

        // TODO: refactor this later (or keep it because it's just simple fix)
        const lexeme = if (is_string) lexer.input[start + 1 .. lexer.position - 1] else lexer.input[start..lexer.position];

        const token = Token{
            .type = if (is_string) TokenType.String else try lexer.getTokenType(lexeme),
            .lexeme = lexeme,
            .line = lexer.line,
            .line_position = lexer.line_position,
        };

        if (isNewline(lexer.getCurrentSymbol())) {
            _ = lexer.popContext();
        }

        try lexer.tokens.append(token);

        return token;
    }

    pub fn parse(lexer: *Lexer) !void {
        while (try lexer.nextToken()) |value| {
            if (value.type == .EOL) {
                break;
            }
        }
    }
};
