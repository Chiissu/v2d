struct Config {
    seg1: f32,
};

@group(0) @binding(0) var mainSampler: sampler;
@group(0) @binding(1) var mainTexture: texture_2d<f32>;
@group(0) @binding(2) var<uniform> config: Config;

struct Result {
    head_tilt: f32,
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

    var pos = array<vec2<f32>, 18>(
        // Seg 1
        vec2<f32>(-1.0, -1.0),  // ↙
        vec2<f32>(1.0, -1.0),  // ↘
        vec2<f32>(-1.0, uvSeg1),  // ↖
        vec2<f32>(-1.0, uvSeg1),  // ↖
        vec2<f32>(1.0, -1.0),  // ↘
        vec2<f32>(1.0, uvSeg1),  // ↗

        // Seg 2
        vec2<f32>(-1.0, uvSeg1),  // ↙
        vec2<f32>(1.0, uvSeg1),  // ↘
        vec2<f32>(-1.0, 1),  // ↖
        vec2<f32>(-1.0, 1),  // ↖
        vec2<f32>(1.0, uvSeg1),  // ↘
        vec2<f32>(1.0, 1),  // ↗
    );

    var vsOutput: VertexOutput;
    let xy = pos[VertexIndex];

    vsOutput.texcoord = xy;//flipY(xy);
    vsOutput.position = vec4<f32>(xy, 0.0, 1.0);
    vsOutput.rotate = VertexIndex > 5;
    return vsOutput;
}

fn rotate(xy: vec2<f32>, y: f32, r: f32) -> vec2<f32>{
    var a = atan2(xy.y - y, xy.x);
    var l = length(vec2<f32>(xy.x, xy.y - y));
    var t = a - r * (1 - pow(2.718281828459045, - (xy.y - y) * 2.5));
    return vec2<f32>(l * cos(t), l * sin(t) + y);
}

fn flipY(xy: vec2<f32>) -> vec2<f32> {
    return xy * vec2<f32>(0.5, -0.5) + 0.5;
}

// fn mapping(pos: vec2<f32>) -> vec2<f32> {
//     let modulus: f32 = length(pos);
//     let rotation: f32 = atan2(pos.y, pos.x) + pow(modulus / 1.414 - 1, 3) * 2;
//     return vec2<f32>(cos(rotation), sin(rotation)) * modulus;
// }
fn mapping(pos: vec2<f32>) -> vec2<f32> {
    let modulus: f32 = length(pos);
    let rotation: f32 = atan2(pos.y, pos.x) + pow(modulus / 1.414 - 1, 3) * 2;
    return vec2<f32>(cos(rotation), sin(rotation)) * modulus;
}

@fragment fn frag_main(fsInput: VertexOutput) -> @location(0) vec4<f32> {
    var uvSeg1 = config.seg1 * 2 - 1;
    var head_tilt = result.head_tilt;
    var texcoord = fsInput.texcoord;
    if (fsInput.rotate) {
        texcoord = rotate(texcoord, uvSeg1, head_tilt);
    }
    return textureSample(mainTexture, mainSampler, flipY(texcoord));
}
