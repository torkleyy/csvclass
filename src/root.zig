const std = @import("std");

pub const Ty = enum {
    Never,
    Int,
    Float,
    String,
    Bool,
};
pub const Column = struct { name: [32]u8, ty: Ty, max_len: usize, optional: bool };

fn number_type(lit: []const u8) ?Ty {
    // TODO: optimize
    if (std.fmt.parseInt(i64, lit, 10) catch null) |_| {
        return Ty.Int;
    }

    if (std.fmt.parseFloat(f64, lit) catch null) |_| {
        return Ty.Float;
    }

    return null;
}

fn extend_type(from: Ty, lit: []const u8) Ty {
    if (@inComptime()) @compileError("This function must be run at runtime");

    if (lit.len == 0) return from;
    if (from == Ty.String) return from;

    const is_bool = std.mem.eql(u8, lit, "true") or std.mem.eql(u8, lit, "false");
    const num_ty = number_type(lit);

    if (from == Ty.Bool) {
        if (is_bool) {
            return from;
        } else {
            return Ty.String;
        }
    }

    if (from == Ty.Int) {
        return num_ty orelse Ty.String;
    }

    if (from == Ty.Float) {
        if (num_ty) |_| {
            return Ty.Float;
        } else {
            return Ty.String;
        }
    }

    if (from == Ty.Never) {
        if (num_ty) |ty| return ty;
        if (is_bool) return Ty.Bool;
    }

    // fallthrough
    return Ty.String;
}

pub fn init(alloc: std.mem.Allocator, header_: []const u8, delim: u8) ![]Column {
    var header = header_;
    var cols: usize = 1;
    for (header) |c| {
        if (c == delim) {
            cols += 1;
        }
    }

    var columns = try alloc.alloc(Column, cols);
    for (0..cols) |col| {
        const until = std.mem.indexOfScalar(u8, header, delim) orelse header.len;
        var name: [32]u8 = .{0} ** 32;
        std.mem.copyForwards(u8, &name, header[0..@min(until, 32)]);
        std.debug.print("found column: \"{s}\"\n", .{name});
        columns[col] = .{
            .name = name,
            .max_len = 0,
            .optional = false,
            .ty = Ty.Never,
        };
        if (header.len < until + 1) {
            break;
        }
        header = header[until + 1 ..];
    }

    return columns;
}

pub fn advance(columns: []Column, row_: []const u8, delim: u8) void {
    var row = row_;
    for (columns) |*col| {
        const until = std.mem.indexOfScalar(u8, row, delim) orelse row.len;
        const lit = row[0..until];
        col.max_len = @max(col.max_len, lit.len);
        col.ty = extend_type(col.ty, lit);
        col.optional = col.optional or lit.len == 0;
        if (row.len > until + 1) {
            row = row[until + 1 ..];
        } else {
            // needed for optionality
            row = "";
        }
    }
}

test "slicing to end" {
    const slice: [3]i32 = .{ 1, 2, 3 };
    try std.testing.expect(slice[3..].len == 0);
}

test "type extension" {
    try std.testing.expectEqual(extend_type(Ty.Int, "3.1"), Ty.Float);
}
