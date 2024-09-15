struct Config {
    seg1: f32,
    seg2: f32,
};

@group(0) @binding(0) var mainSampler: sampler;
@group(0) @binding(1) var mainTexture: texture_2d<f32>;
@group(0) @binding(2) var<uniform> config: Config;

struct Result {
    rotation: f32,
};

@group(1) @binding(0) var<uniform> result: Result;

struct VertexOutput {
    @builtin(position) position: vec4<f32>,
    @location(0) texcoord: vec2<f32>,
};

@vertex fn vertex_main(
    @builtin(vertex_index) VertexIndex : u32
) -> VertexOutput {
    var uvSeg1 = config.seg1 * 2 - 1;
    var uvSeg2 = config.seg2 * 2 - 1;

    var rotation = result.rotation;

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
        vec2<f32>(-1.0, uvSeg2),  // ↖
        vec2<f32>(-1.0, uvSeg2),  // ↖
        vec2<f32>(1.0, uvSeg1),  // ↘
        vec2<f32>(1.0, uvSeg2),  // ↗

        // Seg 3
        vec2<f32>(-1.0, uvSeg2),  // ↙
        vec2<f32>(1.0, uvSeg2),  // ↘
        vec2<f32>(-1.0, 1.0),  // ↖
        vec2<f32>(-1.0, 1.0),  // ↖
        vec2<f32>(1.0, uvSeg2),  // ↘
        vec2<f32>(1.0, 1.0),  // ↗
    );

    var vsOutput: VertexOutput;
    let xy = pos[VertexIndex];

    vsOutput.texcoord = xy;//flipY(xy);

    if (VertexIndex < 8 || VertexIndex == 10) {
        vsOutput.position = vec4<f32>(xy, 0.0, 1.0);
    } else {
        vsOutput.position = vec4<f32>(rotate(xy, uvSeg1 + 0.2, rotation), 0.0, 1.0);
    };
    return vsOutput;
}

fn rotate(xy: vec2<f32>, y: f32, r: f32) -> vec2<f32>{
    var angle = atan2(xy.y - y, xy.x);
    var l = length(vec2<f32>(xy.x, xy.y - y));
    return vec2<f32>(l * cos(angle - r), l * sin(angle - r) + y);
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
    return textureSample(mainTexture, mainSampler, flipY(fsInput.texcoord));
}
