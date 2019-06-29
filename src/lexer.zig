

pub const Token = struct {
    kind: Kind,
    text: []const u8,

    pub const Kind = enum {
        Id,
        Int,
        Atom,
        String,

        Dot,
        Comma,
        LParen,
        RParen,
        LBrace,
        RBrace,
        LCurly,
        RCurly,
        Question,
        ArrowLeft,
        ArrowRight,
    };
};

pub const Lexer = struct {
    pos: usize,
    source: []const u8,

    pub const Error = error {
        Eof,
        InvalidChar,
        UnclosedString,
    };

    pub fn new(source: []const u8) Lexer {
        return Lexer {
            .pos = 0,
            .source = source,
        };
    }

    fn peek(self: Lexer) u8 {
        if (self.pos >= self.source.len)
            return 0;
        return self.source[self.pos];
    }

    fn next(self: *Lexer) u8 {
        const char = self.peek();
        if (char != 0)
            self.pos += 1;
        return char;
    }

    fn isWhitespace(char: u8) bool {
        return char == ' ' or char == '\t' or char == '\n' or char == '\r';
    }

    fn isDigit(char: u8) bool {
        return char >= '0' and char <= '9';
    }

    fn isIdentifier(char: u8) bool {
        return isIdentifierStart(char) or isDigit(char) or char == '\'';
    }

    fn isIdentifierStart(char: u8) bool {
        return (char >= 'a' and char <= 'z') or (char >= 'A' and char <= 'Z') or char == '_';
    }

    pub fn read(self: *Lexer) Error!Token {
        // skip whitespace
        while (isWhitespace(self.peek()))
            _ = self.next();

        const pos = self.pos;
        const char = self.next();

        return switch (char) {
            0 => Error.Eof,
            '"' => self.readString(pos + 1),
            '.' => self.readSymbol(Token.Kind.Dot, pos),
            ',' => self.readSymbol(Token.Kind.Comma, pos),
            '(' => self.readSymbol(Token.Kind.LParen, pos),
            ')' => self.readSymbol(Token.Kind.RParen, pos),
            '[' => self.readSymbol(Token.Kind.LBrace, pos),
            ']' => self.readSymbol(Token.Kind.RBrace, pos),
            '{' => self.readSymbol(Token.Kind.LCurly, pos),
            '}' => self.readSymbol(Token.Kind.RCurly, pos),
            '?' => self.readSymbol(Token.Kind.Question, pos),

            '-' => switch (self.peek()) {
                '>' => self.readSymbol(Token.Kind.ArrowRight, pos),
                else => Error.InvalidChar,
            },
            '<' => switch (self.peek()) {
                '-' => self.readSymbol(Token.Kind.ArrowLeft, pos),
                else => Error.InvalidChar,
            },

            else =>
                if (isIdentifierStart(char))
                    self.readIdentifier(pos)
                else if (isDigit(char))
                    self.readNumber(pos)
                else
                    Error.InvalidChar
        };
    }

    fn readSymbol(self: *Lexer, kind: Token.Kind, pos: usize) Token {
        _ = switch (kind) {
            .ArrowLeft, .ArrowRight => self.next(),
            else => 0,
        };

        return Token {
            .kind = kind,
            .text = self.source[pos..self.pos],
        };
    }

    fn readString(self: *Lexer, pos: usize) Error!Token {
        while (self.peek() != 0 and self.peek() != '"')
            _ = self.next();
        if (self.next() != '"')
            return Error.UnclosedString;

        return Token {
            .kind = Token.Kind.String,
            .text = self.source[pos..self.pos - 1],
        };
    }

    fn readNumber(self: *Lexer, pos: usize) Token {
        while (isDigit(self.peek()))
            _ = self.next();

        return Token {
            .kind = Token.Kind.Int,
            .text = self.source[pos..self.pos],
        };
    }

    fn readIdentifier(self: *Lexer, pos: usize) Token {
        while (isIdentifier(self.peek()))
            _ = self.next();

        const text = self.source[pos..self.pos];
        return Token {
            .text = text,
            .kind = getIdentifierKind(text),
        };
    }

    fn getIdentifierKind(text: []const u8) Token.Kind {
        if (text[0] >= 'A' and text[0] <= 'Z')
            return Token.Kind.Atom;
        return Token.Kind.Id; // TODO: add keywords
    }
};

test "lexer examples" {
    const std = @import("std");
    const LexerTests = struct {
        usingnamespace Token;

        fn isToken(kind: Kind, text: []const u8, token: Token) void {
            std.debug.assert(token.kind == kind);
            std.debug.assert(std.mem.eql(u8, token.text, text));
        }

        pub fn run(lexer: *Lexer) !void {
            isToken(Kind.Atom, "Atom", try lexer.read());
            isToken(Kind.ArrowLeft, "<-", try lexer.read());
            isToken(Kind.Int, "69", try lexer.read());
            isToken(Kind.Question, "?", try lexer.read());
            isToken(Kind.Id, "var", try lexer.read());
            isToken(Kind.LParen, "(", try lexer.read());
            isToken(Kind.String, "string", try lexer.read());
            isToken(Kind.RParen, ")", try lexer.read());
            isToken(Kind.Dot, ".", try lexer.read());
        }
    };

    var lexer = Lexer.new("Atom <- 69 ?var (\"string\"). ");
    try LexerTests.run(&lexer);
}