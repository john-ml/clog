const std = @import("std");
const builtin = @import("builtin");

pub inline fn ptrCast(comptime Ptr: type, address: var) Ptr {
    return @intToPtr(Ptr, @ptrToInt(address));
}

pub const Arena = struct {
    const COMMIT_SIZE = 64 * 1024;

    top: usize,
    memory: []u8,
    commit_at: usize,

    pub fn create(bytes: usize) !Arena {
        const memory = try VirtualMemory.alloc(bytes);
        VirtualMemory.commit(memory[0..COMMIT_SIZE]);
        return from(memory);
    }

    pub fn from(memory: []u8) Arena {
        return Arena {
            .top = 0,
            .memory = memory,
            .commit_at = COMMIT_SIZE,
        };
    }

    pub fn destroy(self: Arena) void {
        VirtualMemory.free(self.memory);
    }

    pub fn alloc(self: *Arena, bytes: usize) ![]u8 {
        const new_top = self.top + bytes;
        if (new_top > self.memory.len)
            return error.OutOfMemory;

        if (builtin.os == .windows and new_top >= self.commit_at) {
            self.commit_at += std.math.max(COMMIT_SIZE, new_top);
            const offset = std.math.min(self.memory.len, self.commit_at);
            VirtualMemory.commit(self.memory[0..offset]);
        }

        const memory = self.memory[self.top..bytes];
        self.top = new_top;
        return memory;
    }
};

const VirtualMemory = switch (builtin.os) {
    .windows => struct {
        const windows = std.os.windows;

        pub fn alloc(bytes: usize) ![]u8 {
            const address = ptrCast(?[*]u8, windows.kernel32.VirtualAlloc(
                null,
                bytes,
                windows.MEM_RESERVE,
                windows.PAGE_READWRITE,
            )) orelse return error.OutOfMemory;
            return address[0..bytes];
        }

        pub fn free(memory: []u8) void {
            _ = windows.kernel32.VirtualFree(
                ptrCast(windows.LPVOID, memory.ptr),
                0,
                windows.MEM_RELEASE,
            );
        }

        pub fn commit(memory: []u8) void {
            _ = windows.kernel32.VirtualAlloc(
                ptrCast(?windows.LPVOID, memory.ptr),
                memory.len,
                windows.MEM_COMMIT,
                windows.PAGE_READWRITE
            );
        }
    },
    .linux => struct {
        const linux = std.os.linux;

        pub fn alloc(bytes: usize) ![]u8 {
            const address = linux.mmap(
                null,
                bytes,
                linux.PROT_READ | linux.PROT_WRITE,
                linux.MAP_PRIVATE | linux.MAP_ANONYMOUS | linux.MAP_NORESERVE,
                -1,
                0
            );
            if (linux.getErrno(address) != 0)
                return error.OutOfMemory;
            return @intToPtr([*]u8, address)[0..bytes];
        }

        pub fn free(memory: []u8) void {
            _ = linux.munmap(memory.ptr, memory.len);
        }

        pub fn commit(memory: []u8) void {
            // linux over-commits by default
        }
    },
    else => struct {
        pub fn alloc(bytes: usize) ![]u8 {
            const address = ptrCast(?[*]u8, std.c.malloc(bytes))
                orelse return error.OutOfMemory;
            return address[0..bytes];
        }

        pub fn free(memory: []u8) void {
            _ = std.c.free(ptrCast(*c_void, memory.ptr));
        }

        pub fn commit(memory: []u8) void {
            // its assume to already be committed
        }
    }
};

test "arena allocation" {
    var arena = try Arena.create(64 * 1024 * 1024);
    defer arena.destroy();

    var data = try arena.alloc(65 * 1024);
    std.mem.secureZero(u8, data);
}

test "virtual memory" {
    var memory = try VirtualMemory.alloc(64 * 1024 * 1024);
    defer VirtualMemory.free(memory);

    VirtualMemory.commit(memory[0..1]);
    memory[0] = 'x';
}

