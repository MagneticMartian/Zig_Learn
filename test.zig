const std = @import("std");
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const print = std.debug.print;
const assert = std.debug.assert;
const mem = std.mem;

const message = [_]u8{ 'h', 'e', 'l', 'l', 'o' };
comptime {
    assert(message.len == 5);
}
const same_message = "hello";
comptime {
    assert(mem.eql(u8, &message, same_message));
}

var some_integers: [100]i32 = undefined;
const part_one = [_]i32{ 1, 2, 3, 4 };
const part_two = [_]i32{ 5, 6, 7, 8 };
const all_of_it = part_one ++ part_two;

const hello = "hello";
const world = "world";
const hello_world = hello ++ " " ++ world;
comptime {
    assert(mem.eql(u8, hello_world, "hello world"));
}

const pattern = "ab" ** 3;
comptime {
    assert(mem.eql(u8, pattern, "ababab"));
}

const all_zero = [_]u16{0} ** 10;
comptime {
    assert(all_zero.len == 10);
    assert(all_zero[5] == 0);
}

const Point = struct {
    x: i32,
    y: i32,
};

fn makePoint(x: i32) Point {
    return Point{
        .x = x,
        .y = x * 2,
    };
}
var more_points = [_]Point{makePoint(3)} ** 10;

// compile-time code to initialize an array
var fancy_array = init: {
    var initial_value: [10]Point = undefined;
    for (&initial_value, 0..) |*pt, i| {
        pt.* = Point{
            .x = @intCast(i),
            .y = @intCast(i * 2),
        };
    }
    break :init initial_value;
};

const mat4x4 = [4][4]f32{
    [_]f32{ 1.0, 0.0, 0.0, 0.0 },
    [_]f32{ 0.0, 1.0, 0.0, 1.0 },
    [_]f32{ 0.0, 0.0, 1.0, 0.0 },
    [_]f32{ 0.0, 0.0, 0.0, 1.0 },
};

test "iterate over an array" {
    var sum: usize = 0;
    for (message) |byte| {
        sum += byte;
    }
    try expect(sum == 'h' + 'e' + 'l' * 2 + 'o');
}

test "modify an array" {
    for (&some_integers, 0..) |*item, i| {
        item.* = @intCast(i);
    }
    try expect(some_integers[10] == 10);
    try expect(some_integers[99] == 99);
}

test "compile-time array initialization" {
    try expect(fancy_array[4].x == 4);
    try expect(fancy_array[4].y == 8);
}

test "array initialization with function calls" {
    try expect(more_points[4].x == 3);
    try expect(more_points[4].y == 6);
    try expect(more_points.len == 10);
}

test "multidimensional arrays" {
    try expect(@TypeOf(mat4x4) == [4][4]f32);
    try expect(mat4x4[1][1] == 1.0);

    for (mat4x4, 0..) |row, row_index| {
        for (row, 0..) |cell, column_index| {
            if (row_index == column_index) {
                try expect(cell == 1.0);
            }
        }
    }
}

test "null terminated array" {
    const array = [_:'\xFF']u8{ 1, 2, 3, 4 };

    try expect(@TypeOf(array) == [4:'\xFF']u8);
    try expect(array.len == 4);
    try expect(array[4] == '\xFF');
}

test "Basic vector usage" {
    const a = @Vector(4, i32){ 1, 2, 3, 4 };
    const b = @Vector(4, i32){ 5, 6, 7, 8 };

    const c = a + b;

    try expectEqual(6, c[0]);
    try expectEqual(8, c[1]);
    try expectEqual(10, c[2]);
    try expectEqual(12, c[3]);
}
test "Conversion between vectors, arrays, and slices" {
    var arr1: [4]f32 = [_]f32{ 1.1, 3.2, 4.5, 5.6 };
    var vec: @Vector(4, f32) = arr1;
    var arr2: [4]f32 = vec;
    try expectEqual(arr1, arr2);

    const vec2: @Vector(2, f32) = arr1[1..3].*;

    var slice: []const f32 = &arr1;
    var offset: u32 = 1;

    const vec3: @Vector(2, f32) = slice[offset..][0..2].*;
    try expectEqual(slice[offset], vec2[0]);
    try expectEqual(slice[offset + 1], vec2[1]);
    try expectEqual(vec2, vec3);
}

test "addess of syntax" {
    const x: i32 = 1234;
    const x_ptr = &x;

    try expect(x_ptr.* == 1234);
    try expect(@TypeOf(x_ptr) == *const i32);

    var y: i32 = 5678;
    const y_ptr = &y;

    try expect(@TypeOf(y_ptr) == *i32);
    y_ptr.* += 1;
    try expect(y == 5679);
}

test "pointer array access" {
    var array = [_]u8{ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 };
    const ptr = &array[2];
    try expect(@TypeOf(ptr) == *u8);

    // The following lines are not allowed in Zig:
    //   const ptr = &array[0];
    //   ptr = ptr + 1;
    //   try expect(ptr.* == array[1]);

    try expect(array[2] == 3);
    ptr.* += 1;
    try expect(array[2] == 4);
}
test "pointer arithmetic with many-item pointers" {
    const array = [_]i32{ 1, 2, 3, 4 };
    var ptr: [*]const i32 = &array;

    const n: usize = 3; // pointer shift amount
    try expect(ptr[0] == 1);
    ptr = ptr + n; // changing the starting location of the multi-item reference
    try expect(ptr[0] == array[n]);
}
test "pointer arithmetic with slices" {
    var array = [_]i32{ 1, 2, 3, 4 };
    var length: usize = 0;
    var slice = array[length..array.len];

    try expect(slice[0] == array[0]);
    try expect(slice.len == 4);

    slice.ptr += 1;

    try expect(slice[0] == array[1]);
    try expect(slice.len == 4);
}
test "pointer slicing" {
    var array = [_]u8{ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 };
    var start: usize = 2;
    const slice = array[start..4];
    try expect(slice.len == 2);

    try expect(array[3] == 4);
    slice[1] += 1;
    try expect(array[3] == 5);
}
test "comptime pointers" {
    comptime {
        var x: i32 = 1;
        const ptr = &x;
        ptr.* += 1;
        x += 1;
        try expect(ptr.* == 3);
    }
}
test "@intFromPtr and @ptrFromInt" {
    const ptr: *i32 = @ptrFromInt(0xdeadbee0);
    const addr = @intFromPtr(ptr);
    try expect(@TypeOf(addr) == usize);
    try expect(addr == 0xdeadbee0);
}
test "comptime @intFromPtr and @ptrFromInt" {
    comptime {
        const ptr: *i32 = @ptrFromInt(0xdeadbee0);
        const addr = @intFromPtr(ptr);
        try expect(@TypeOf(addr) == usize);
        try expect(addr == 0xdeadbee0);
    }
}
test "volatile" {
    const mmio_ptr: *volatile u8 = @ptrFromInt(0x12345678);
    try expect(@TypeOf(mmio_ptr) == *volatile u8);
}
test "pointer casting" {
    const bytes align(@alignOf(u32)) = [_]u8{ 0x12, 0x12, 0x12, 0x12 };
    const u32_ptr: *const u32 = @ptrCast(&bytes);
    try expect(u32_ptr.* == 0x12121212);

    const u32_value = std.mem.bytesAsSlice(u32, bytes[0..])[0];
    try expect(u32_value == 0x12121212);

    try expect(@as(u32, @bitCast(bytes)) == 0x12121212);
}
test "pointer child type" {
    try expect(@typeInfo(*u32).Pointer.child == u32);
}
