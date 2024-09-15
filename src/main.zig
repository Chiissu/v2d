const mach = @import("mach");

pub const modules = .{
    mach.Core,
    @import("views/main.zig"),
};

pub fn main() !void {
    // Initialize mach.Core
    try mach.core.initModule();

    // Main loop
    while (try mach.core.tick()) {}
}
