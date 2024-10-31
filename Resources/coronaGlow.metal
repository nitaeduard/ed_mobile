#include <metal_stdlib>
using namespace metal;
#include <SceneKit/scn_metal>

struct VertexIn {
    float3 position [[attribute(SCNVertexSemanticPosition)]];
    float2 uv [[ attribute(SCNVertexSemanticTexcoord0) ]];
};

struct MyNodeBuffer {
    float4x4 modelTransform;
    float4x4 modelViewTransform;
    float4x4 normalTransform;
    float4x4 modelViewProjectionTransform;
};

struct VertexOut {
    float4 position [[position]];
    float2 uv;
    float4 worldPos;
};

vertex VertexOut vertexShader(
    VertexIn in [[stage_in]],
    constant SCNSceneBuffer& scn_frame [[buffer(0)]],
    constant MyNodeBuffer& scn_node [[buffer(1)]]
) {
    VertexOut vert;
    vert.position = scn_node.modelViewProjectionTransform * float4(in.position, 1.0);
    vert.uv = in.uv;
    return vert;
}

fragment float4 coronaGlow(
    VertexOut in [[stage_in]],
    texture2d<float, access::sample> diffuseTexture [[texture(0)]]
) {
    float2 uv = in.uv;
    
    constexpr sampler sampler2d(coord::normalized, filter::linear, address::repeat);
    float4 texColor = diffuseTexture.sample(sampler2d, uv);
    
    float2 center = float2(0.5, 0.5);
    float dist = distance(uv, center);

    float glowIntensity = smoothstep(0.9, 0.1, dist);

    // float4 glowColor = float4(1.0, 0.7, 0.2, 1.0);
    float4 glowColor = float4(
        texColor.x + 1.7,// 1.0,
        texColor.y + 1.7,// 0.7,
        texColor.z + 1.7,//0.2,
        1.0
    );

    return mix(glowColor, texColor, glowIntensity);
}
