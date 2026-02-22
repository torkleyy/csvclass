const std = @import("std");
const csvclass = @import("csvclass");

fn parseFileName(args: *std.process.ArgIterator) ?[:0]const u8 {
    if (args.skip()) {
        if (args.next()) |arg| {
            return arg;
        }
    }

    return null;
}

fn openFile() !std.fs.File {
    var argBuffer: [4096]u8 = undefined;
    var alloc = std.heap.FixedBufferAllocator.init(&argBuffer);
    var args = try std.process.argsWithAllocator(alloc.allocator());

    const fileName = parseFileName(&args) orelse @panic("missing arg");

    const cwd = std.fs.cwd();
    const file = cwd.openFile(fileName, .{});

    return file;
}

/// Read next non-empty line, trimming its whitespace
fn readLine(reader: *std.Io.Reader) !?[]const u8 {
    if (try reader.takeDelimiter('\n')) |line_| {
        var line: []const u8 = line_;
        line = std.mem.trim(u8, line, " \t\n\r");
        if (line.len == 0) return readLine(reader);

        return line;
    }

    return null;
}

pub fn main() !void {
    const file = try openFile();
    var readBuffer: [4096]u8 = undefined;
    var reader = file.reader(&readBuffer);

    var columnBuffer: [@sizeOf(csvclass.Column) * 32]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&columnBuffer);

    var columns: []csvclass.Column = undefined;
    if (try readLine(&reader.interface)) |line| {
        columns = try csvclass.init(fba.allocator(), line, ',');
    } else {
        @panic("missing header");
    }

    while (try readLine(&reader.interface)) |line| {
        csvclass.advance(columns, line, ',');
    }

    std.debug.print("name,ty,len,opt\n", .{});
    for (columns) |col| {
        std.debug.print("{s},{s},{d},{}\n", .{ col.name, @tagName(col.ty), col.max_len, col.optional });
    }
}
