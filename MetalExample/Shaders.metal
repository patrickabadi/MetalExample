//
//  Shaders.metal
//  MetalExample
//
//  Created by Patrick Abadi on 2020-12-23.
//

#include <metal_stdlib>
#include <simd/simd.h>
#include "ShaderDefinitions.h"
using namespace metal;

// Camera's RGB vertex shader outputs
struct RGBVertexOut {
    float4 position [[position]];
    float2 texCoord;
    float4 color;
};

// Particle vertex shader outputs and fragment shader inputs
struct ParticleVertexOut {
    float4 position [[position]];
    float pointSize [[point_size]];
    float4 color;
};

constexpr sampler colorSampler(mip_filter::linear, mag_filter::linear, min_filter::linear);
constant auto yCbCrToRGB = float4x4(float4(+1.0000f, +1.0000f, +1.0000f, +0.0000f),
                                    float4(+0.0000f, -0.3441f, +1.7720f, +0.0000f),
                                    float4(+1.4020f, -0.7141f, +0.0000f, +0.0000f),
                                    float4(-0.7010f, +0.5291f, -0.8860f, +1.0000f));
constant float2 viewVertices[] = { float2(-1, 1), float2(-1, -1), float2(1, 1), float2(1, -1) };
//constant float2 viewTexCoords[] = { float2(0, 0), float2(0, 1), float2(1, 0), float2(1, 1) };
constant float2 viewTexCoords[] = { float2(0, 1), float2(0, 0), float2(1, 1), float2(1, 0) };
/// Retrieves the world position of a specified camera point with depth
static simd_float4 worldPoint(simd_float2 cameraPoint, float depth, matrix_float3x3 cameraIntrinsicsInversed, matrix_float4x4 localToWorld) {
    const auto localPoint = cameraIntrinsicsInversed * simd_float3(cameraPoint, 1) * depth;
    const auto worldPoint = localToWorld * simd_float4(localPoint, 1);
    
    return worldPoint / worldPoint.w;
}

vertex RGBVertexOut rgbVertex(uint vertexID [[vertex_id]],
                              constant RGBUniforms &uniforms [[buffer(0)]]) {
    const float3 texCoord = float3(viewTexCoords[vertexID], 1) * uniforms.viewToCamera;

    RGBVertexOut out;
    out.position = float4(viewVertices[vertexID], 0, 1);
    out.texCoord = texCoord.xy;
    out.color = float4(1.0,1.0,0.0,1);
    return out;
}

fragment float4 rgbFragment(RGBVertexOut in[[stage_in]],
                            constant RGBUniforms &uniforms [[buffer(0)]],
                            texture2d<float, access::sample> capturedImageTextureY [[texture(kTextureY)]],
                            texture2d<float, access::sample> capturedImageTextureCbCr [[texture(KTextureCbCr)]]) {
//    const float2 offset = (in.texCoord - 0.5) * float2(1,1/uniforms.viewRatio) * 2;
//    const float visibility = saturate(uniforms.radius * uniforms.radius - length_squared(offset));
    const float4 ycbcr = float4(capturedImageTextureY.sample(colorSampler, in.texCoord.xy).r, capturedImageTextureCbCr.sample(colorSampler, in.texCoord.xy).rg, 1);

    // convert and save the color back to the buffer
    const float3 sampledColor = (yCbCrToRGB * ycbcr).rgb;
    return float4(sampledColor, 1);
}
