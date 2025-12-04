const std = @import("std");

// Constants
const START_VALUE: u8 = 50;
const MODULO: u32 = 100;
const BUF_SIZE = 4096; // size is 1 memory page, to minimize syscalls needed

pub fn main() !void {
    // Use raw file reading for minimal overhead
    var file = std.fs.cwd().openFile("input.txt", .{}) catch |err| {
        std.debug.print("Error: Could not open input.txt: {}\n", .{err});
        return;
    };
    defer file.close();

    var buffer: [BUF_SIZE]u8 = undefined;

    var dial_position: u8 = START_VALUE;
    var zero_crossed: usize = 0;
    var stopped_at_zero: usize = 0;

    var num: u32 = 0;
    var is_left: bool = false;

    // Timer for benchmarking
    var timer = try std.time.Timer.start();

    while (true) {
        const bytes_read = file.read(&buffer) catch 0;
        if (bytes_read == 0) break;

        for (buffer[0..bytes_read]) |byte| {
            switch (byte) {
                '0'...'9' => {
                    num = num *% 10 +% (byte - '0');
                },
                'L', 'R' => {
                    if (num > 0) {
                        processMath(&dial_position, num, is_left, &zero_crossed, &stopped_at_zero);
                        num = 0;
                    }
                    is_left = (byte == 'L');
                },
                else => {
                    if (num > 0) {
                        processMath(&dial_position, num, is_left, &zero_crossed, &stopped_at_zero);
                        num = 0;
                    }
                },
            }
        }
    }

    if (num > 0) {
        processMath(&dial_position, num, is_left, &zero_crossed, &stopped_at_zero);
    }

    // Get benchmark time
    const elapsed_ns = timer.read();

    std.debug.print("\n     Final Results    \n", .{});
    std.debug.print("Final dial Value: {d}\n", .{dial_position});
    std.debug.print("Stopped at Zero:      {d}\n", .{stopped_at_zero});
    std.debug.print("Zeros Crossed:        {d}\n", .{zero_crossed});

    // Time formatting logic
    if (elapsed_ns < 1000) {
        std.debug.print("Execution Time:       {d} ns\n", .{elapsed_ns});
    } else if (elapsed_ns < 1_000_000) {
        std.debug.print("Execution Time:       {d:.3} us\n", .{@as(f64, @floatFromInt(elapsed_ns)) / 1000.0});
    } else {
        std.debug.print("Execution Time:       {d:.3} ms\n", .{@as(f64, @floatFromInt(elapsed_ns)) / 1_000_000.0});
    }
}

// calculate new dial position and crossings
fn processMath(dial_pos: *u8, steps: u32, is_left: bool, crossed: *usize, stopped: *usize) void {
    const start_val = dial_pos.*;

    if (is_left) {
        // Calculate Crossings (Left)
        // Distance to first zero is 'start_val', unless start_val is 0, then it's 100
        const dist_to_zero = if (start_val == 0) 100 else @as(u32, start_val);

        if (steps >= dist_to_zero) {
            crossed.* += 1 + (steps - dist_to_zero) / MODULO;
        }

        // Update Dial Position
        const remainder = @as(u8, @intCast(steps % MODULO));
        if (remainder > start_val) {
            dial_pos.* = (start_val + 100) - remainder;
        } else {
            dial_pos.* = start_val - remainder;
        }
    } else {
        // Calculate Crossings
        crossed.* += (start_val + steps) / MODULO;

        // Update Dial Position
        dial_pos.* = @as(u8, @intCast((start_val + steps) % MODULO));
    }

    // Check if stopped on zero
    if (dial_pos.* == 0) {
        stopped.* += 1;
    }
}
