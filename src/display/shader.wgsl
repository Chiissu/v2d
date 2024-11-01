struct Config {
    seg1: f32,
    shoulder: f32,
};

@group(0) @binding(0) var mainSampler: sampler;
@group(0) @binding(1) var mainTexture: texture_2d<f32>;
@group(0) @binding(2) var<uniform> config: Config;

struct Result {
    head_x: f32,
    head_y: f32,
    head_z: f32,
    body_pos_x: f32,
    body_pos_y: f32,
    body_rot_x: f32,
    body_rot_z: f32,
};

@group(1) @binding(0) var<uniform> result: Result;

struct VertexOutput {
    @builtin(position) position: vec4<f32>,
    @location(0) texcoord: vec2<f32>,
    rotate: bool,
};

@vertex fn vertex_main(
    @builtin(vertex_index) VertexIndex : u32
) -> VertexOutput {
    var uvSeg1 = config.seg1 * 2 - 1;

    var pos = array<vec2<f32>, 6>(
        // Seg 1
        vec2<f32>(-1.0, -1.0),  // ↙
        vec2<f32>(1.0, -1.0),  // ↘
        //vec2<f32>(-1.0, uvSeg1),  // ↖
        //vec2<f32>(-1.0, uvSeg1),  // ↖
        //vec2<f32>(1.0, -1.0),  // ↘
        //vec2<f32>(1.0, uvSeg1),  // ↗
        vec2<f32>(-1.0, 1),  // ↖

        // Seg 2
        //vec2<f32>(-1.0, uvSeg1),  // ↙
        //vec2<f32>(1.0, uvSeg1),  // ↘
        vec2<f32>(-1.0, 1),  // ↖
        //vec2<f32>(-1.0, 1),  // ↖
        //vec2<f32>(1.0, uvSeg1),  // ↘
        vec2<f32>(1.0, 1),  // ↗
        vec2<f32>(1.0, -1.0),  // ↘
    );

    var vsOutput: VertexOutput;
    let xy = pos[VertexIndex];

    vsOutput.texcoord = xy;
    vsOutput.position = vec4<f32>(xy, 0.0, 1.0);
    vsOutput.rotate = VertexIndex > 5;
    return vsOutput;
}

fn stage1(p: vec3<f32>) -> vec3<f32>{
    var y = (config.seg1) * 2 - 1;
    if (p.y < y) {
        return p;
    }
    var r = result.head_x + result.body_rot_x;

    var a = atan2(p.y - y, p.x);
    var l = length(vec2<f32>(p.x, p.y - y));
    var t = a - r * (1 - pow(2.718281828459045, - (p.y - y) * 4)) * 0.4;
    return vec3<f32>(l * cos(t), l * sin(t) + y, p.z);
}

fn stage2(p: vec3<f32>) -> vec3<f32>{
    var y = (config.seg1) * 2 - 1;
    var r = result.head_y;

    var t = 1.5 * r / (1 + pow(2.718281828459045, -18 * (p.y - y))); //(1 - pow(2.718281828459045, - (p.y - y) * 12));
    //return vec3<f32>(p.x, p.y, 0.3 * sin(t));
    return vec3<f32>(p.x, (p.y - y) / cos(t) + y, sin(t));
}

fn stage3(p: vec3<f32>) -> vec3<f32>{
    var y = (config.seg1) * 2 - 1;
    var r = result.head_z;// + result.body_rot_z;

    var t = r * 0.8 / (1 + pow(2.718281828459045, -18 * (p.y - y)));//(1 - pow(2.718281828459045, - (p.y - y) * 12)) * r;
    return vec3<f32>(p.x / cos(t), p.y, p.z * sin(t));
}

fn stage4(p: vec3<f32>) -> vec3<f32>{
    var r = result.body_rot_z;
    return vec3<f32>(p.x / cos(r) + p.z * sin(r), p.y, 0);
}

fn stage5(p: vec3<f32>) -> vec3<f32>{
    var r = result.body_rot_x;
    var shoulderUV = config.shoulder * 2 - 1;
    return vec3<f32>(p.x * cos(r) - (p.y - shoulderUV) * sin(r), p.x * sin(r) + (p.y - shoulderUV) * cos(r) + shoulderUV, 0);
}

fn toTexCoord(xy: vec2<f32>) -> vec2<f32> {
    return xy * vec2<f32>(0.5, -0.5) + 0.5;
}

@fragment fn frag_main(fsInput: VertexOutput) -> @location(0) vec4<f32> {
    var coord = vec3<f32>(fsInput.texcoord, 0);

    // Stage 1: head x
    coord = stage1(coord);

    // Stage 2: head y
    coord = stage2(coord);

    // Stage 3: head z
    coord = stage3(coord);

    // Stage 4: body rotate z
    coord = stage4(coord);

    // Stage 5: body rotate x
    coord = stage5(coord);

    // Stage 6: transform
    coord = coord + vec3<f32>(result.body_pos_x, result.body_pos_y, 0);

    // Squash to 2d
    var texcoord = vec2<f32>(coord.x, coord.y);

    // convert the coordinate
    texcoord = toTexCoord(texcoord);

    // Render output
    return textureSample(mainTexture, mainSampler, texcoord);
}
