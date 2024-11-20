//
//  simpleVertexShader.swift
//  EDMobile
//
//  Created by Eduard Radu Nita on 05/10/2024.
//
#include <metal_math>
#include <metal_stdlib>
using namespace metal;


constant float OCTAVE = 12;
constant float4 SPACE = float4(0.04, 0.02, 0.09, 1);
constant float4 CLOUD1_COL = float4(0.41, 0.64, 0.78, 0.3);
constant float4 CLOUD2_COL = float4(0.79, 0.59, 0.46, 0.1);
constant float4 CLOUD3_COL = float4(0.81, 0.31, 0.59, 0.2);
constant float4 CLOUD4_COL = float4(0.27, 0.15, 0.33, 0.1);
constant half size = 7.0;
constant float prob = 0.98;
constant float starscale = 70;

inline float rand(float2 st) {
    return fract(sin(dot(st, float2(23.9898, 78.233))) * 435758.5453);
}

float perlin(float2 input) {
    float2 i = floor(input);
    float2 f = fract(input);
    float2 coord = smoothstep(0., 1., f);

    float a = rand(i);
    float b = rand(i + float2(1.0, 0.0));
    float c = rand(i + float2(0.0, 1.0));
    float d = rand(i + float2(1.0, 1.0));

    return mix(mix(a, b, coord.x), mix(c, d, coord.x), coord.y);
}

float fbmCloud(float2 input, float minimum) {
    float value = 0.0;
    float scale = 0.5;

    for (int i = 0; i < OCTAVE; i++) {
        value += perlin(input) * scale;
        input *= 2.0;
        scale *= 0.5;
    }

    return smoothstep(0., 1., (smoothstep(minimum, 1., value) - minimum) / (1.0 - minimum));
}

[[ stitchable ]]
half4 simpleVertexShader(float2 pixelPos, half4 color, float t) {
    float2 screenSize = float2(300.0, 300.0);
    float2 position = float2(pixelPos.xy) / screenSize * 2 - t * 0.01;
    float4 outColor = float4(SPACE.rgb, 0.5 + 0.2 * sin(0.23 * t + position.x - position.y));

    float time = t * 0.2;
    float t1 = sin(time * 0.1) * 0.05;
    float t2 = 0.06 * cos(0.3 * time * 0.1);

    outColor += fbmCloud(position, 0.34 + t1) * CLOUD1_COL;
    outColor += fbmCloud(position * 0.9, 0.33 - t2) * CLOUD2_COL;
    outColor = mix(outColor, CLOUD3_COL, fbmCloud(0.9 * position, 0.25 + 0.33 - t2));
    outColor = mix(outColor, CLOUD4_COL, fbmCloud(position * 0.7 + 2.0, 0.4 + 0.33 - t2));

    float2 zoomstar = starscale * position;
    float2 pos = floor(zoomstar / size);
    float starValue = rand(pos);

    if (starValue > prob) {
        float2 center = size * pos + float2(size, size) * 0.5;
        float t3 = 0.5 + 0.2 * sin(time * 6.0 + (starValue - prob) / (1.0 - prob) * 3.0);
        float color = 1.0 - distance(zoomstar, center) / (0.5 * size);
        outColor = mix(outColor, float4(1.0, 1.0, 1.0, 1.0), smoothstep(0., 1., color * t3 / (abs(zoomstar.y - center.y)) * t3 / (abs(zoomstar.x - center.x))));
    } else {
        zoomstar *= 5.0 + t2;
        pos = floor(zoomstar / size);
        float starValue2 = rand(pos + float2(36, 36));

        if (starValue2 >= 0.95) {
            float2 center = size * pos + float2(size, size) * 0.5;
            float t = 0.9 + 0.2 * sin(time * 8.0 + (starValue - prob) / (1.0 - prob) * 45.0);
            float color = 1.0 - distance(zoomstar, center) / (0.5 * size);
            outColor = mix(outColor, float4(1.0, 1.0, 1.0, 1.0), fbmCloud(pos, 0.0) * smoothstep(0., 1., color * t / (abs(zoomstar.y - center.y)) * t / (abs(zoomstar.x - center.x))));
        }
    }

    return half4(half3(outColor.rgb), 1);
}
