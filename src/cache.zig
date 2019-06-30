use @import("heap.zig");
const std = @import("std");

pub const StringRef = u32;
pub const StringCache = struct {
    entries: []Entry,
    source: []const u8,

    const Entry = struct {
        pos: u32,
        len: u32,
        hash: u32,
    };

    pub fn create(source: []const u8) !StringCache {
        var arena = try Arena.create(32 * 1024 * 1024);
        const memory = try arena.alloc(arena.memory.len);

        return StringCache {
            .source = source,
            .entries = ptrCast([*]Entry, memory.ptr)[0..memory.len / @sizeOf(Entry)],
        };
    }

    pub fn destroy(self: StringCache) void {
        Arena.from(@sliceToBytes(self.entries)).destroy();
    }

    pub fn getHash(self: StringCache, ref: StringRef) u32 {
        return self.entries[ref].hash;
    }

    pub fn getText(self: StringCache, ref: StringRef) []const u8 {
        const offset = self.entries[ref].pos;
        return self.source[offset..offset + self.entries[ref].len];
    }

    pub fn upsert(self: *StringCache, text: []const u8) !StringRef {
        // make sure the text is a subset of the source in order to store its offset
        const text_ptr = @ptrToInt(text.ptr);
        const src_ptr = @ptrToInt(self.source.ptr);

        if (text.len > usize(std.math.maxInt(u32)))
            return error.InvalidText;
        if (!(text_ptr >= src_ptr and text_ptr + text.len <= src_ptr + self.source.len))
            return error.InvalidText;

        // find ref offset and insert if not there
        const hash = std.hash.Fnv1a_32.hash(text);
        const ref = try self.findStringRef(hash, text);
        if (self.entries[ref].hash == 0) {
            self.entries[ref] = Entry {
                .hash = hash,
                .len = @intCast(u32, text.len),
                .pos = @intCast(u32, text_ptr - src_ptr)
            };
        }

        return ref;
    }

    inline fn reduce(self: StringCache, probe: u32) u32 {
        return probe & @intCast(u32, self.entries.len - 1);
    }

    inline fn compare(self: StringCache, ref: StringRef, hash: u32, text: []const u8) bool {
        return self.getHash(ref) == hash and std.mem.eql(u8, self.getText(ref), text);
    }

    fn findStringRef(self: StringCache, hash: u32, text: []const u8) !StringRef {
        var ref = self.reduce(hash);
        var max_collisions = self.entries.len;

        // basic linear probing for now...
        while (max_collisions > 0) : (max_collisions -= 1) {
            if (self.entries[ref].hash == 0 or self.compare(ref, hash, text))
                return ref;
            ref = self.reduce(ref + 1);
        }

        return error.OutOfMemory;
    }
};

test "string cache" {
    const source = "this is a test";
    var words = std.mem.separate(source, " ");

    var cache = try StringCache.create(source);
    defer cache.destroy();

    while (words.next()) |word| {
        const ref = try cache.upsert(word);
        std.debug.assert(std.mem.eql(u8, word, cache.getText(ref)));
    }
}