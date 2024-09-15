const std = @import("std");
const mach = @import("mach");
const gpu = mach.gpu;
const zigimg = @import("zigimg");
const landmark = @import("./landmark.zig");

pub const name = .app;
pub const Mod = mach.Mod(@This());

pub const systems = .{
    .init = .{ .handler = init },
    .after_init = .{ .handler = afterInit },
    .deinit = .{ .handler = deinit },
    .tick = .{ .handler = tick },
};

title_timer: mach.Timer,
pipeline: *gpu.RenderPipeline,
landmarker: landmark,

var binding0: *gpu.BindGroup = undefined;
var texture: *gpu.Texture = undefined;

pub fn deinit(core: *mach.Core.Mod, game: *Mod) void {
    texture.release();
    binding0.release();
    game.state().landmarker.deinit();
    game.state().pipeline.release();
    core.schedule(.deinit);
}

fn init(game: *Mod, core: *mach.Core.Mod) !void {
    core.schedule(.init);
    game.schedule(.after_init);
}

const Config = struct {
    seg1: f32,
    seg2: f32,
};

fn afterInit(game: *Mod, core: *mach.Core.Mod) !void {
    const device: *gpu.Device = core.state().device;
    const queue: *gpu.Queue = core.state().queue;

    // Create our shader module
    const shader_module = device.createShaderModuleWGSL("shader.wgsl", @embedFile("shader.wgsl"));
    defer shader_module.release();

    // Blend state describes how rendered colors get blended
    const blend = gpu.BlendState{
        .color = .{ .src_factor = .src_alpha, .dst_factor = .one_minus_src_alpha },
    };

    // Color target describes e.g. the pixel format of the window we are rendering to.
    const color_target = gpu.ColorTargetState{
        .format = core.get(core.state().main_window, .framebuffer_format).?,
        .blend = &blend,
    };

    // Fragment state describes which shader and entrypoint to use for rendering fragments.
    const fragment = gpu.FragmentState.init(.{
        .module = shader_module,
        .entry_point = "frag_main",
        .targets = &.{color_target},
    });

    // Read the image file
    const asset_name = "main";
    var file = try std.fs.cwd().openFile("assets/img/" ++ asset_name ++ ".png", .{});
    defer file.close();

    var img = try zigimg.Image.fromFile(core.state().allocator, &file);
    defer img.deinit();

    const img_size = gpu.Extent3D{ .width = @as(u32, @intCast(img.width)), .height = @as(u32, @intCast(img.height)) };

    texture = device.createTexture(&.{
        .label = asset_name ++ ".loadTexture",
        .size = img_size,
        .format = .rgba8_unorm,
        .usage = .{ .texture_binding = true, .copy_dst = true, .render_attachment = true },
    });

    const data_layout = gpu.Texture.DataLayout{
        .bytes_per_row = @as(u32, @intCast(img.width * 4)),
        .rows_per_image = @as(u32, @intCast(img.height)),
    };
    switch (img.pixels) {
        .rgba32 => |pixels| queue.writeTexture(&.{ .texture = texture }, &data_layout, &img_size, pixels),
        .rgb24 => |pixels| {
            const data = try rgb24ToRgba32(core.state().allocator, pixels);
            defer data.deinit(core.state().allocator);
            queue.writeTexture(&.{ .texture = texture }, &data_layout, &img_size, data.rgba32);
        },
        else => @panic("unsupported image color format"),
    }
    var texture_view = texture.createView(&.{ .label = "main" });
    defer texture_view.release();

    // Create our render pipeline that will ultimately get pixels onto the screen.
    const label = @tagName(name) ++ ".init";
    const pipeline_descriptor = gpu.RenderPipeline.Descriptor{
        .label = label,
        .fragment = &fragment,
        .vertex = gpu.VertexState{
            .module = shader_module,
            .entry_point = "vertex_main",
        },
    };
    const pipeline = device.createRenderPipeline(&pipeline_descriptor);
    const layout0 = pipeline.getBindGroupLayout(0);
    defer layout0.release();

    var sampler = device.createSampler(&.{ .mag_filter = .nearest, .min_filter = .nearest });
    //var sampler = device.createSampler(&.{});
    defer sampler.release();

    const config = Config{
        .seg1 = 0.21875,
        .seg2 = 0.375,
    };
    const config_buffer = device.createBuffer(&.{
        .label = "config",
        .usage = .{ .uniform = true, .copy_dst = true },
        .size = @sizeOf(Config),
        .mapped_at_creation = gpu.Bool32.false,
    });
    queue.writeBuffer(config_buffer, 0, &std.mem.toBytes(config));

    binding0 = device.createBindGroup(&gpu.BindGroup.Descriptor.init(.{
        .layout = layout0,
        .entries = &.{
            gpu.BindGroup.Entry.sampler(0, sampler),
            gpu.BindGroup.Entry.textureView(1, texture_view),
            gpu.BindGroup.Entry.buffer(2, config_buffer, 0, @sizeOf(Config), 0),
        },
    }));

    // Store our render pipeline in our module's state, so we can access it later on.
    game.init(.{
        .title_timer = try mach.Timer.start(),
        .pipeline = pipeline,
        .landmarker = try landmark.init(.{ .camera_id = 2 }),
    });
    try updateWindowTitle(core);

    core.schedule(.start);
}

fn rgb24ToRgba32(allocator: std.mem.Allocator, in: []zigimg.color.Rgb24) !zigimg.color.PixelStorage {
    const out = try zigimg.color.PixelStorage.init(allocator, .rgba32, in.len);
    var i: usize = 0;
    while (i < in.len) : (i += 1) {
        out.rgba32[i] = zigimg.color.Rgba32{ .r = in[i].r, .g = in[i].g, .b = in[i].b, .a = 255 };
    }
    return out;
}

fn tick(core: *mach.Core.Mod, game: *Mod) !void {
    // TODO(important): event polling should occur in mach.Core module and get fired as ECS event.
    // TODO(Core)
    var iter = mach.core.pollEvents();
    while (iter.next()) |event| {
        switch (event) {
            .close => core.schedule(.exit), // Tell mach.Core to exit the app
            else => {},
        }
    }

    const device: *gpu.Device = core.state().device;
    const queue: *gpu.Queue = core.state().queue;

    // Create variable binding
    const result: landmark.Result = try game.state().landmarker.poll();
    const result_buffer = device.createBuffer(&.{
        .label = "result",
        .usage = .{ .uniform = true, .copy_dst = true },
        .size = @sizeOf(landmark.Result),
        .mapped_at_creation = gpu.Bool32.false,
    });
    const layout1 = game.state().pipeline.getBindGroupLayout(1);
    defer layout1.release();
    queue.writeBuffer(result_buffer, 0, &std.mem.toBytes(result));
    var binding1 = device.createBindGroup(&gpu.BindGroup.Descriptor.init(.{
        .layout = layout1,
        .entries = &.{
            gpu.BindGroup.Entry.buffer(0, result_buffer, 0, @sizeOf(landmark.Result), 0),
        },
    }));
    defer binding1.release();

    // Grab the back buffer of the swapchain
    // TODO(Core)
    const back_buffer_view = mach.core.swap_chain.getCurrentTextureView().?;
    defer back_buffer_view.release();

    // Create a command encoder
    const label = @tagName(name) ++ ".tick";
    const encoder = core.state().device.createCommandEncoder(&.{ .label = label });
    defer encoder.release();

    // Begin render pass
    const sky_blue_background = gpu.Color{ .r = 0.776, .g = 0.988, .b = 1, .a = 1 };
    const color_attachments = [_]gpu.RenderPassColorAttachment{.{
        .view = back_buffer_view,
        .clear_value = sky_blue_background,
        .load_op = .clear,
        .store_op = .store,
    }};
    const render_pass = encoder.beginRenderPass(&gpu.RenderPassDescriptor.init(.{
        .label = label,
        .color_attachments = &color_attachments,
    }));
    defer render_pass.release();

    // Draw
    render_pass.setPipeline(game.state().pipeline);
    render_pass.setBindGroup(0, binding0, null);
    render_pass.setBindGroup(1, binding1, null);
    render_pass.draw(18, 1, 0, 0);

    // Finish render pass
    render_pass.end();

    // Submit our commands to the queue
    var command = encoder.finish(&.{ .label = label });
    defer command.release();
    core.state().queue.submit(&[_]*gpu.CommandBuffer{command});

    // Present the frame
    core.schedule(.present_frame);

    // update the window title every second
    if (game.state().title_timer.read() >= 1.0) {
        game.state().title_timer.reset();
        try updateWindowTitle(core);
    }
}

fn updateWindowTitle(core: *mach.Core.Mod) !void {
    try mach.Core.printTitle(
        core,
        core.state().main_window,
        "core-custom-entrypoint [ {d}fps ] [ Input {d}hz ]",
        .{
            // TODO(Core)
            mach.core.frameRate(),
            mach.core.inputRate(),
        },
    );
    core.schedule(.update);
}
