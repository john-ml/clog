use @import("cache.zig");
const std = @import("std");

pub const Token = union(enum) {
    Num: i64,
    Id: StringRef,
    Atom: StringRef,

    Dot,
    LParen,
    RParen,
    Question,
    ArrowLeft,
    ArrowRight,
};

pub const Lexer = struct {
    pos: u32,
    cache: *StringCache,
    
    pub fn create(cache: *StringCache) Lexer {
        return Lexer {
            .pos = 0,
            .cache = cache,
        };
    }

    fn peek(self: Lexer) u8 {
        if (self.pos >= self.cache.source.len)
            return 0;
        return self.cache.source[self.pos];
    }

    fn next(self: *Lexer) u8 {
        const char = self.peek();
        if (char != 0)
            self.pos += 1;
        return char;
    }

    fn isDigit(char: u8) bool {
        return char >= '0' and char <= '9';
    }

    fn isWhitespace(char: u8) bool {
        return char == ' ' or char == '\t' or char == '\r' or char == '\n';
    }

    fn isIdentifier(char: u8) bool {
        return switch (char) {
            '0'...'9', 'a'...'z', 'A'...'Z', '_' => true,
            else => false,
        };
    }

    pub fn read(self: *Lexer) !Token {
        while (isWhitespace(self.peek()))
            _ = self.next();

        const pos = self.pos;
        const char = self.next();

        return switch (char) {
            '.' => Token { .Dot = {} },
            '(' => Token { .LParen = {} },
            ')' => Token { .RParen = {} },
            '?' => Token { .Question = {} },

            '0'...'9' => self.readNumber(pos),
            'a'...'z', 'A'...'Z' => try self.readIdentifier(pos),

            '<' => switch (self.peek()) {
                '-' => self.skipThen(Token { .ArrowLeft = {} }),
                else => error.InvalidChar,
            },
            '-' => switch (self.peek()) {
                '>' => self.skipThen(Token { .ArrowRight = {} }),
                '0'...'9' => self.readNumber(pos),
                else => error.InvalidChar,
            },

            0 => error.Eof,
            else => error.InvalidChar,
        };
    }

    inline fn skipThen(self: *Lexer, token: Token) Token {
        _ = self.next();
        return token;
    }

    fn readNumber(self: *Lexer, pos: u32) Token {
        while (isDigit(self.peek()))
            _ = self.next();
        
        const text = self.cache.source[pos..self.pos];
        const value = std.fmt.parseInt(i64, text, 10) catch unreachable;
        return Token { .Num = value };
    }

    fn readIdentifier(self: *Lexer, pos: u32) !Token {
        while (isIdentifier(self.peek()))
            _ = self.next();

        const text = self.cache.source[pos..self.pos];
        const ref = try self.cache.upsert(text);

        return switch (text[0]) {
            'A'...'Z' => Token { .Atom = ref },
            else => Token { .Id = ref },
        };
    }
};

test "lexing tokens" {
    const assert = std.debug.assert;
    const source = "App ( Cons x xs 64 -5 ) ?xs <- Other xy .";

    var cache = try StringCache.create(source);
    var words = std.mem.separate(source, " ");
    var lexer = Lexer.create(&cache);
    defer cache.destroy();

    // TODO: probably a cleaner way to do this...
    const App = try cache.upsert(words.next().?);
    _ = words.next().?; // (
    const Cons = try cache.upsert(words.next().?);
    const x = try cache.upsert(words.next().?);
    const xs = try cache.upsert(words.next().?);
    _ = words.next().?; // 64
    _ = words.next().?; // -5
    _ = words.next().?; // )
    _ = words.next().?; // ?xs
    _ = words.next().?; // <- 
    const Other = try cache.upsert(words.next().?);
    const xy = try cache.upsert(words.next().?);

    assert((try lexer.read()).Atom == App);
    assert((try lexer.read()).LParen == {});
    assert((try lexer.read()).Atom == Cons);
    assert((try lexer.read()).Id == x);
    assert((try lexer.read()).Id == xs);
    assert((try lexer.read()).Num == 64);
    assert((try lexer.read()).Num == -5);
    assert((try lexer.read()).RParen == {});
    assert((try lexer.read()).Question == {});
    assert((try lexer.read()).Id == xs);
    assert((try lexer.read()).ArrowLeft == {});
    assert((try lexer.read()).Atom == Other);
    assert((try lexer.read()).Id == xy);
    assert((try lexer.read()).Dot == {});
}