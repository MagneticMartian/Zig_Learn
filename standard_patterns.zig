const std = @import("std");
const expect = std.testing.expect;

// This is the simplest allocator. It request pages of
// memory based on the amount you give.
test "page_allocation" {
    const allocator = std.heap.page_allocator;

    const memory = try allocator.alloc(u8, 100);
    defer allocator.free(memory);

    try expect(memory.len == 100);
    try expect(@TypeOf(memory) == []u8);
}

// This allocator allocates memory of a fixed size and
// does not allocate any memory on the heap.
test "fixed buffer allocator" {
    var buf: [1000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buf);
    const allocator = fba.allocator();

    const memory = try allocator.alloc(u8, 100);
    defer allocator.free(memory);

    try expect(memory.len == 100);
    try expect(@TypeOf(memory) == []u8);
}

// This allows the allocation multiple times and only needing
// to free once
test "Arena allocator" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit(); // Frees all the memory at end of scope.
    const allocator = arena.allocator();

    _ = try allocator.alloc(u8, 1);
    _ = try allocator.alloc(u8, 10);
    _ = try allocator.alloc(u8, 100);
}

// For single item allocation use creat and destroy
test "create and destroy" {
    const byte = try std.heap.page_allocator.create(u8);
    defer std.heap.page_allocator.destroy(byte);
    byte.* = 128;
}

// The General Purpose Allocator is designed with saftey in mind
// However, it can still be more perfomant than page_allocator
test "GPA" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) expect(false) catch @panic("TEST FAIL");
    }
    const bytes = try allocator.alloc(u8, 100);
    defer allocator.free(bytes);
}

// Array list is a resizable array similar to std::vector<T> in c++
const eql = std.mem.eql;
const ArrayList = std.ArrayList;
const test_allocator = std.testing.allocator;

test "ArrayList" {
    var list = ArrayList(u8).init(test_allocator);
    defer list.deinit();
    try list.append('H');
    try list.append('e');
    try list.append('l');
    try list.append('l');
    try list.append('o');
    try list.appendSlice(" World!");

    try expect(eql(u8, list.items, "Hello World!"));
}

test "cearteFile, write, seekTo, read" {
    const file = try std.fs.cwd().createFile(
        "junk_file.txt",
        .{ .read = true },
    );
    defer file.close();

    const bytes_written = try file.writeAll("Hello File!");
    _ = bytes_written;

    var buf: [100]u8 = undefined;
    try file.seekTo(0);
    const bytes_read = try file.readAll(&buf);

    try expect(eql(u8, buf[0..bytes_read], "Hello File!"));
}
test "file stat" {
    const file = try std.fs.cwd().createFile(
        "junk_file2.txt",
        .{ .read = true },
    );
    defer file.close();
    const stat = try file.stat();
    try expect(stat.size == 0);
    try expect(stat.kind == .file);
    try expect(stat.ctime <= std.time.nanoTimestamp());
    try expect(stat.mtime <= std.time.nanoTimestamp());
    try expect(stat.atime <= std.time.nanoTimestamp());
}
test "make_dir" {
    try std.fs.cwd().makeDir("test-tmp");
    var iter_dir = try std.fs.cwd().openIterableDir(
        "test-tmp",
        .{},
    );
    defer {
        iter_dir.close();
        std.fs.cwd().deleteTree("test-tmp") catch unreachable;
    }
    _ = try iter_dir.dir.createFile("x", .{});
    _ = try iter_dir.dir.createFile("y", .{});
    _ = try iter_dir.dir.createFile("z", .{});

    var file_count: usize = 0;
    var iter = iter_dir.iterate();
    while (try iter.next()) |entry| {
        if (entry.kind == .file) file_count += 1;
    }
    try expect(file_count == 3);
}
