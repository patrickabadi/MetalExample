//
//  ShaderDefinitions.h
//  MetalExample
//
//  Created by Patrick Abadi on 2020-12-23.
//

#ifndef ShaderDefinitions_h
#define ShaderDefinitions_h

#include <simd/simd.h>

struct Vertex {
    vector_float4 color;
    vector_float2 pos;
};

enum TextureIndices {
    kTextureY = 0,
    KTextureCbCr = 1,
    kTextureDepth = 2,
    kTextureConfidence = 3
};

enum BufferIndices {
    kPointCloudUniforms = 0,
    kParticleUniforms = 1,
    kGridPoints = 2
};

struct RGBUniforms {
    matrix_float3x3 viewToCamera;
    float viewRatio;
    float radius;
};

struct PointCloudUniforms {
    matrix_float4x4 viewProjectionMatrix;
    matrix_float4x4 localToWorld;
    matrix_float3x3 cameraIntrinsicsInversed;
    simd_float2 cameraResolution;
    
    float particleSize;
    int maxPoints;
    int pointCloudCurrentIndex;
    int confidenceThreshold;
};

struct ParticleUniforms {
    simd_float3 position;
    simd_float3 color;
    float confidence;
};


#endif /* ShaderDefinitions_h */
