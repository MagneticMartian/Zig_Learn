const std = @import("std");
const expect = std.testing.expect;

test "if statement" {
    const a = true;
    var x: u16 = 0;
    if (a) {
        x += 1;
    } else {
        x += 2;
    }
    try expect(x == 1);
}
test "if statement expression" {
    const a = true;
    var x: u16 = 0;
    x += if (a) 1 else 2;
    try expect(x == 1);
}
test "while" {
    var i: u8 = 2;
    while (i < 100) {
        i *= 2;
    }
    try expect(i == 128);
}
test "while with a continue expresssion" {
    var sum: u8 = 0;
    var i: u8 = 1;
    while (i <= 10) : (i += 1) {
        sum += i;
    }
    try expect(sum == 55);
}
test "while with continue" {
    var sum: u8 = 0;
    var i: u8 = 0;
    while (i <= 3) : (i += 1) {
        if (i == 2) continue;
        sum += i;
    }
    try expect(sum == 4);
}
test "while with break" {
    var sum: u8 = 0;
    var i: u8 = 0;
    while (i <= 3) : (i += 1) {
        if (i == 2) break;
        sum += i;
    }
    try expect(sum == 1);
}
test "for" {
    const string = [_]u8{ 'a', 'b', 'c' };

    for (string, 0..) |character, index| {
        _ = character;
        _ = index;
    }
    for (string) |character| {
        _ = character;
    }
    for (string, 0..) |_, index| {
        _ = index;
    }
    for (string) |_| {}
}
fn addFive(x: u32) u32 {
    return x + 5;
}
test "function" {
    const y = addFive(0);
    try expect(@TypeOf(y) == u32);
    try expect(y == 5);
}
fn fib(n: u16) u16 {
    if (n == 0 or n == 1) return n;
    return fib(n - 1) + fib(n - 2);
}
test "function recusion" {
    const x = fib(10);
    try expect(x == 55);
}
test "defer" {
    var x: i16 = 5;
    {
        defer x += 2;
        try expect(x == 5);
    }
    try expect(x == 7);
}
test "multi defer" {
    var x: f32 = 5;
    {
        defer x += 2; // executes 2nd leaving scope
        defer x /= 2; // executes 1st leaving scope
    }
    try expect(x == 4.5);
}
const FileOpenError = error{
    AccessDenied,
    OutOfMemory,
    FileNotFound,
};
const AllocationError = error{OutOfMemory};

test "coerce error from from a subset to a superset" {
    const err: FileOpenError = AllocationError.OutOfMemory;
    try expect(err == FileOpenError.OutOfMemory);
}
test "error union" {
    const maybe_error: AllocationError!u16 = 10;
    const no_error = maybe_error catch 0;

    try expect(@TypeOf(no_error) == u16);
    try expect(no_error == 10);
}
fn failingFunction() error{Oops}!void {
    return error.Oops;
}
test "returning an error" {
    failingFunction() catch |err| {
        try expect(err == error.Oops);
        return;
    };
}
fn failFn() error{Oops}!i32 {
    try failingFunction();
    return 12;
}
test "try" {
    var v = failFn() catch |err| {
        try expect(err == error.Oops);
        return;
    };
    try expect(v == 12);
}
var problems: u32 = 98;

fn failFnCounter() error{Oops}!void {
    errdefer problems += 1;
    try failingFunction();
}
test "errdefer" {
    failFnCounter() catch |err| {
        try expect(err == error.Oops);
        try expect(problems == 99);
        return;
    };
}
fn createFile() !void {
    return error.AccessDenied;
}
test "infered from error set" {
    // type coercion succefully takes place
    const x: error{AccessDenied}!void = createFile();
    // Zig does not let us ignore error unions via _ = x;
    // we must unwrap it with 'try', 'catch', 'if' by any means
    _ = x catch {};
}
const A = error{ NotDir, PathNotFound };
const B = error{ OutOfMemory, PathNotFound };
const C = A || B;
test "switch statement" {
    var x: i8 = 10;
    switch (x) {
        -1...1 => {
            x = -x;
        },
        10, 100 => {
            x = @divExact(x, 10);
        },
        else => {},
    }
    try expect(x == 1);
}
test "switch expression" {
    var x: i8 = 10;
    x = switch (x) {
        -1...1 => -x,
        10, 100 => @divExact(x, 10),
        else => x,
    };
    try expect(x == 1);
}
//test "out of bounds" {
//    const a = [3]u8{ 1, 2, 3 };
//    var index: u8 = 5;
//    const b = a[index];
//    _ = b;
//}
test "out of bounds, no safety" {
    @setRuntimeSafety(false);
    const a = [3]u8{ 1, 2, 3 };
    var index: u8 = 5;
    const b = a[index];
    _ = b;
}
test "unreachable" {
    const x: i32 = 1;
    const y: u32 = if (x == 1) 5 else unreachable;
    _ = y;
}
fn asciiToUpper(x: u8) u8 {
    return switch (x) {
        'a'...'z' => x + 'A' - 'a',
        'A'...'Z' => x,
        else => unreachable,
    };
}
test "unreachable switch" {
    try expect(asciiToUpper('a') == 'A');
    try expect(asciiToUpper('A') == 'A');
}
fn increment(num: *u8) void {
    num.* += 1;
}
test "pointer" {
    var x: u8 = 1;
    increment(&x);
    try expect(x == 2);
}
//test "naughty pointer" {
//    var x: u16 = 0;
//    var y: *u8 = @ptrFromInt(x);
//    _ = y;
//}
fn total(values: []const u8) usize {
    var sum: usize = 0;
    for (values) |v| sum += v;
    return sum;
}
test "slices" {
    const array = [_]u8{ 1, 2, 3, 4, 5 };
    const slice = array[0..3];
    try expect(total(slice) == 6);
}
test "slice 2" {
    const array = [_]u8{ 1, 2, 3, 4, 5 };
    const slice = array[0..3];
    try expect(@TypeOf(slice) == *const [3]u8);
}
test "slice 3" {
    const array = [_]u8{ 1, 2, 3, 4, 5 };
    var slice = array[0..];
    _ = slice;
}
const Direction = enum { north, south, east, west };
const Value = enum(u2) { zero, one, two };
test "enum ordinal value" {
    try expect(@intFromEnum(Value.zero) == 0);
    try expect(@intFromEnum(Value.one) == 1);
    try expect(@intFromEnum(Value.two) == 2);
}
const Value2 = enum(u32) { hundred = 100, thousand = 1000, million = 1000000, next };
test "set enum ordinal value" {
    try expect(@intFromEnum(Value2.hundred) == 100);
    try expect(@intFromEnum(Value2.thousand) == 1000);
    try expect(@intFromEnum(Value2.million) == 1000000);
    try expect(@intFromEnum(Value2.next) == 1000001);
}
const Suit = enum {
    clubs,
    spades,
    diamonds,
    hearts,
    pub fn isClubs(self: Suit) bool {
        return self == Suit.clubs;
    }
};
test "enum method" {
    try expect(Suit.spades.isClubs() == Suit.isClubs(.spades));
}
const Mode = enum {
    var count: u32 = 0;
    on,
    off,
};
test "hmm" {
    Mode.count += 1;
    try expect(Mode.count == 1);
}
const Vec3 = struct { x: f32, y: f32, z: f32 };
test "struct usage" {
    const my_vec = Vec3{
        .x = 3.4,
        .y = 63.1,
        .z = 56.7,
    };
    _ = my_vec;
}
//test "missing struct argument" {
//    const my_vec = Vec3{
//        .x = 6.7,
//        .z = 4.2,
//    };
//    _ = my_vec;
//}
const Vec4 = struct { x: f32, y: f32, z: f32 = 0, w: f32 = undefined };
test "struct defaults" {
    const my_vec = Vec4{
        .x = 3,
        .y = 7,
    };
    _ = my_vec;
}
const Stuff = struct {
    x: f32,
    y: f32,
    fn swap(self: *Stuff) void {
        const temp = self.x;
        self.x = self.y;
        self.y = temp;
    }
};
test "automatic dereference" {
    var thing = Stuff{ .x = 5, .y = 10 };
    thing.swap();
    try expect(thing.x == 10);
    try expect(thing.y == 5);
}
//const Result = union {
//    int: i64,
//    float: f64,
//    bool: bool,
//};
// detectable illegal behavior
// Bare unions have no guaranteed memory layout
// bare unions can't be used to reinterp memory
//test "simple union" {
//    var result = Result{.int = 1678};
//    result.float = 12.54;
//}
const Tag = enum { a, b, c };
const Tagged = union(Tag) { a: u8, b: f32, c: bool };

// The switch statement uses payload capture |x|
// This makes the captured value immutable
// It is also using pointer capture |*x|
// This allows the dereferencing of the value
// making it mutable.
test "switch on tagged union" {
    var val = Tagged{ .b = 1.5 };
    switch (val) {
        .a => |*byte| byte.* += 1,
        .b => |*float| float.* *= 2,
        .c => |*b| b.* = !b.*,
    }
    try expect(val.b == 3);
}
// void member types can have their type ommited
const Tagged2 = union(Tag) { a: u8, b: f32, c: bool, none };

const decimal_int: i32 = 98222;
const hex_int: u8 = 0xff;
const another_hex_int: u8 = 0xC7;
const octal_int: u16 = 0o755;
const binary_int: u8 = 0b10010011;

const one_billion: u64 = 1_000_000_000;
const binary_mask: u64 = 0b1_1111_1111;
const permissions: u64 = 0o7_5_5;
const big_address: u64 = 0x18f3_07d2_ac13_fffe;

test "integer widening" {
    const a: u8 = 250;
    const b: u16 = a;
    const c: u32 = b;
    try expect(c == a);
}
test "@intCast" {
    const x: u64 = 250;
    const y = @as(u8, @intCast(x));
    try expect(@TypeOf(y) == u8);
}
test "well defined int overflow" {
    var x: u8 = 255;
    x +%= 1;
    try expect(x == 0);
}
test "float widening" {
    const a: f16 = 0.1;
    const b: f32 = a;
    const c: f128 = b;
    try expect(c == @as(f128, a));
}
const floating_point: f64 = 123.0E+77;
const another_float: f64 = 123.0;
const yet_another: f64 = 123.0e+77;

const hex_floating_point: f64 = 0x103.70P-5;
const another_hex_float: f64 = 0x103.70;
const yet_another_hex: f64 = 0x103.70p-5;

const lightspeed: f64 = 299_792_458.000_000;
const nanosecond: f64 = 0.000_000_001;
const more_hex: f64 = 0x1234_5678_9abc_cdefP-10;

test "int-float conversion" {
    const a: i32 = 0;
    const b = @as(f32, @floatFromInt(a));
    const c = @as(i32, @intFromFloat(b));
    try expect(c == a);
}
test "labelled block" {
    const count = blk: {
        var sum: u32 = 0;
        var i: u32 = 0;
        while (i < 10) : (i += 1) sum += i;
        break :blk sum;
    };
    try expect(count == 45);
    try expect(@TypeOf(count) == u32);
}
test "nested continue" {
    var count: usize = 0;
    outer: for ([_]i32{ 1, 2, 3, 4, 5, 6, 7, 8 }) |_| {
        for ([_]i32{ 1, 2, 3, 4, 5 }) |_| {
            count += 1;
            continue :outer; // exits the inner loop immediately
        }
    }
    try expect(count == 8);
}
fn rangeHasNumber(begin: usize, end: usize, number: usize) bool {
    var i = begin;
    return while (i < end) : (i += 1) {
        if (i == number) {
            break true;
        }
    } else false;
}
test "while loop expression" {
    try expect(rangeHasNumber(0, 10, 3));
}
test "optionals" {
    var found_index: ?usize = null;
    const data = [_]i32{ 1, 2, 3, 4, 5, 6, 7, 8, 12 };
    for (data, 0..) |v, i| {
        if (v == 10) found_index = i;
    }
}
test "orelse" {
    var a: ?f32 = null;
    var b = a orelse 0;
    try expect(b == 0);
    try expect(@TypeOf(b) == f32);
}
test "orelse unreachable" {
    const a: ?f32 = 5;
    const b = a orelse unreachable;
    const c = a.?; // equivalent to "a orelse unreachable"
    try expect(b == c);
    try expect(@TypeOf(c) == f32);
}
test "if optional payload capture" {
    const a: ?f32 = 5;
    if (a != null) {
        const value = a.?;
        _ = value;
    }
    var b: ?i32 = 5;
    if (b) |*value| {
        value.* += 1;
    }
    try expect(b.? == 6);
}
var numbers_left: u32 = 4;
fn eventuallyNullSequence() ?u32 {
    if (numbers_left == 0) return null;
    numbers_left -= 1;
    return numbers_left;
}
test "while null capture" {
    var sum: u32 = 0;
    while (eventuallyNullSequence()) |value| {
        sum += value;
    }
    try expect(sum == 6);
}
test "comptime blocks" {
    var x = comptime fib(10);
    _ = x;
    var y = blk: {
        break :blk fib(10);
    };
    _ = y;
}
test "comptime_int" {
    const a = 12;
    const b = a + 10;

    const c: u4 = a;
    _ = c;
    const d: f32 = b;
    _ = d;
}
test "branching on types" {
    const a: u8 = 5;
    const b: if (a < 10) f32 else i32 = 5;
    _ = b;
}
fn Matrix(
    comptime T: type,
    comptime height: comptime_int,
    comptime width: comptime_int,
) type {
    return [height][width]T;
}
test "returning a type" {
    try expect(Matrix(f32, 4, 4) == [4][4]f32);
}
fn addSmallInts(comptime T: type, a: T, b: T) T {
    return switch (@typeInfo(T)) {
        .ComptimeInt => a + b,
        .Int => |info| if (info.bits <= 16) a + b else @compileError("ints to large"),
        else => @compileError("only ints accepted"),
    };
}
test "typeinfo switch" {
    const x = addSmallInts(u16, 20, 30);
    try expect(@TypeOf(x) == u16);
    try expect(x == 50);
}
fn GetBiggerInt(comptime T: type) type {
    return @Type(.{ // .{ is anon struct syntax
        .Int = .{
            .bits = @typeInfo(T).Int.bits + 1,
            .signedness = @typeInfo(T).Int.signedness,
        },
    });
}
test "@Type" {
    try expect(GetBiggerInt(u8) == u9);
    try expect(GetBiggerInt(u31) == u32);
}
fn Vec(
    comptime count: comptime_int,
    comptime T: type,
) type {
    return struct {
        data: [count]T,
        const Self = @This();
        fn abs(self: Self) Self {
            var tmp = Self{ .data = undefined };
            for (self.data, 0..) |elem, i| {
                tmp.data[i] = if (elem < 0) -elem else elem;
            }
            return tmp;
        }
        fn init(data: [count]T) Self {
            return Self{ .data = data };
        }
    };
}
const eql = @import("std").mem.eql;
test "generic vector" {
    const x = Vec(3, f32).init([_]f32{ 10, -10, 5 });
    const y = x.abs();
    try expect(eql(f32, &y.data, &[_]f32{ 10, 10, 5 }));
}
fn plusOne(x: anytype) @TypeOf(x) {
    return x + 1;
}
test "inferred function parameter" {
    try expect(plusOne(@as(u32, 1)) == 2);
}
test "optional-if" {
    var maybe_num: ?usize = 10;
    if (maybe_num) |n| {
        try expect(@TypeOf(n) == usize);
        try expect(n == 10);
    } else {
        unreachable;
    }
}
test "error union if" {
    var ent_num: error{UnknownEntity}!u32 = 5;
    if (ent_num) |entity| {
        try expect(@TypeOf(entity) == u32);
        try expect(entity == 5);
    } else |err| {
        _ = err catch {};
        unreachable;
    }
}
test "while optional" {
    var i: ?u32 = 10;
    while (i) |num| : (i.? -= 1) {
        try expect(@TypeOf(num) == u32);
        if (i == 1) {
            i = null;
            break;
        }
    }
    try expect(i == null);
}
var numbers_left2: u32 = undefined;
fn eventuallyErrorSequence() !u32 {
    return if (numbers_left2 == 0) error.ReachedZero else blk: {
        numbers_left2 -= 1;
        break :blk numbers_left2;
    };
}

test "while error union capture" {
    var sum: u32 = 0;
    numbers_left2 = 3;
    while (eventuallyErrorSequence()) |value| {
        sum += value;
    } else |err| {
        try expect(err == error.ReachedZero);
    }
}

test "for capture" {
    const x = [_]i8{ 1, 5, 120, -5 };
    for (x) |v| try expect(@TypeOf(v) == i8);
}
const Info = union(enum) {
    a: u32,
    b: []const u8,
    c,
    d: u32,
};

test "switch capture" {
    var f = Info{ .a = 10 };
    const x = switch (f) {
        .b => |str| blk: {
            try expect(@TypeOf(str) == []const u8);
            break :blk 1;
        },
        .c => 2,
        .a, .d => |num| blk: {
            try expect(@TypeOf(num) == u32);
            break :blk num * 2;
        },
    };
    try expect(x == 20);
}

test "for with pointer capture" {
    var data = [_]u8{ 1, 2, 3 };
    for (&data) |*byte| byte.* += 1;
    try expect(eql(u8, &data, &[_]u8{ 2, 3, 4 }));
}
test "inline for" {
    const types = [_]type{ u32, i8, bool, f32 };
    var sum: u8 = 0;
    inline for (types) |T| sum += @sizeOf(T);
    try expect(sum == 10);
}

//extern fn show_window(*Window) callconv(.C) void;
//const Window = opaque {
//    fn show(self: *Window) void {
//        show_window(self);
//    }
//};
//test "opaque with declarations" {
//    var main_window: *Window = undefined;
//    main_window.show();
//}
test "anonymous struct literal" {
    const Point = struct { x: i32, y: i32 };

    var pt: Point = .{
        .x = 13,
        .y = 67,
    };
    try expect(pt.x == 13);
    try expect(pt.y == 67);
}

fn dump(args: anytype) !void {
    try expect(args.int == 1234);
    try expect(args.float == 12.34);
    try expect(args.b);
    try expect(args.s[0] == 'h');
    try expect(args.s[1] == 'i');
}
test "fully ananymous struct" {
    try dump(.{
        .int = @as(u32, 1234),
        .float = @as(f64, 12.34),
        .b = true,
        .s = "hi",
    });
}
test "tuple" {
    const values = .{
        @as(u32, 1234),
        @as(f64, 12.34),
        true,
        "hi",
    } ++ .{false} ++ .{2};
    try expect(values[0] == 1234);
    try expect(values[1] == 12.34);
    try expect(values[2] == true);
    try expect(eql(u8, &[_]u8{ 'h', 'i' }, values[3]));
    try expect(values[4] == false);
    try expect(values[5] == 2);
    inline for (values, 0..) |v, i| {
        if (i != 2) continue;
        try expect(v);
    }
    try expect(values.len == 6);
    // @"i" is referencing field i of the tuple
    // it also allows for further indexing on
    // types that allow for indexing like strings
    try expect(values.@"3"[0] == 'h');
    try expect(values.@"3"[1] == 'i');
}

test "C strings" {
    const c_string: [*:0]const u8 = "hello";
    var array: [5]u8 = undefined;

    var i: usize = 0;
    while (c_string[i] != 0) : (i += 1) {
        array[i] = c_string[i];
    }
}
test "sentinal terminated slicing" {
    var x = [_:0]u8{255} ** 3;
    const y = x[0..3 :0];
    _ = y;
}

// Zig vectors that are invoked with @Vector are SIMD optimized vectors.
// These are not like vectors in C++
const meta = std.meta;
test "vector add" {
    const x: @Vector(4, f32) = .{ 1, -10, 20, -1 };
    const y: @Vector(4, f32) = .{ 2, 10, 0, 1 };
    const z = x + y;
    try expect(meta.eql(z, @Vector(4, f32){ 3, 0, 20, 0 }));
}
test "vector indexing" {
    const x: @Vector(4, u8) = .{ 255, 0, 255, 0 };
    try expect(x[2] == 255);
}
test "vector * scalar" {
    const x: @Vector(3, f32) = .{ 12.5, 37.5, 2.5 };
    const y = x * @as(@Vector(3, f32), @splat(2));
    try expect(meta.eql(y, @Vector(3, f32){ 25, 75, 5 }));
}
test "vector looping" {
    const x = @Vector(4, u8){ 255, 0, 255, 0 };
    var sum = blk: {
        var tmp: u10 = 0;
        var i: u8 = 0;
        while (i < 4) : (i += 1) tmp += x[i];
        break :blk tmp;
    };
    try expect(sum == 510);
}
