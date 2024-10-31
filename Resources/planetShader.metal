//
//  planetShader.metal
//  EDMobile
//
//  Created by Eduard Radu Nita on 06/10/2024.
//

#include <metal_stdlib>
using namespace metal;
#include <SceneKit/scn_metal>

float noise(int x,int y)
{
    float fx = float(x);
    float fy = float(y);
    
    return 2.0 * fract(sin(dot(float2(fx, fy) ,float2(12.9898,78.233))) * 43758.5453) - 1.0;
}

float smoothNoise(int x,int y)
{
    return noise(x,y)/4.0+(noise(x+1,y)+noise(x-1,y)+noise(x,y+1)+noise(x,y-1))/8.0+(noise(x+1,y+1)+noise(x+1,y-1)+noise(x-1,y+1)+noise(x-1,y-1))/16.0;
}

float COSInterpolation(float x,float y,float n)
{
    float r = n*3.1415926;
    float f = (1.0-cos(r))*0.5;
    return x*(1.0-f)+y*f;
    
}

float InterpolationNoise(float x, float y)
{
    int ix = int(x);
    int iy = int(y);
    float fracx = x-float(int(x));
    float fracy = y-float(int(y));
    
    float v1 = smoothNoise(ix,iy);
    float v2 = smoothNoise(ix+1,iy);
    float v3 = smoothNoise(ix,iy+1);
    float v4 = smoothNoise(ix+1,iy+1);
    
    float i1 = COSInterpolation(v1,v2,fracx);
    float i2 = COSInterpolation(v3,v4,fracx);
    
    return COSInterpolation(i1,i2,fracy);
    
}

float perlinNoise2D(float x,float y)
{
    int firstOctave = 3;
    int octaves = 9;
    float persistence = 0.6;
    float sum = 0.0;
    float frequency = 10.0;
    float amplitude = 0.0;
    for(int i=firstOctave;i<octaves + firstOctave;i++)
    {
        frequency = pow(2.0,float(i));
        amplitude = pow(persistence,float(i));
        sum = sum + InterpolationNoise(x*frequency,y*frequency)*amplitude;
    }
    
    return sum;
}

float4 perlinColor(float2 pos) {
    float noiseValue = perlinNoise2D(pos.x, pos.y);
    noiseValue = noiseValue + 0.2;
// float e = perlinNoise2D(pos.x, pos.y);
// float ecuator = 0.1;
// float ecuator = 0.8;
// float equivalent_elevation = 10 * e * e + poles + (equator-poles) * sin(PI * (y / height))
    // https://www.redblobgames.com/maps/terrain-from-noise/#demo
    
    if (noiseValue < 0.17) { // water
        return float4(0, 0, noiseValue, 1);
    }
    if (noiseValue < 0.19) { // beach
        return float4(0, 0, noiseValue * 0.4, 1);
    }
    if (noiseValue < 0.20) { // SUBTROPICAL_DESERT
        return float4(noiseValue * 0.2, noiseValue * 0.6, noiseValue * 0.2, 1);
    }
    if (noiseValue < 0.22) { // GRASSLAND
        return float4(noiseValue * 0.1, noiseValue * 0.2, noiseValue * 0.1, 1);
    }
    if (noiseValue < 0.25) { // TROPICAL_RAIN_FOREST
        return float4(noiseValue / 50, noiseValue / 7, noiseValue / 50, 1);
    }
    if (noiseValue < 0.27) { // TROPICAL_SEASONAL_FOREST
        return float4(noiseValue / 100, noiseValue / 10, noiseValue / 100, 1);
    }
    // SNOW
    return float4(noiseValue, noiseValue, noiseValue, 1);
}

// Function to calculate basic Phong lighting
float3 phongLighting(float3 normal, float3 lightDirection, float3 viewDirection, float3 lightColor, float3 ambientColor, float shininess) {
    // Normalize input vectors
    normal = normalize(normal);
    lightDirection = normalize(lightDirection);
    viewDirection = normalize(viewDirection);

    // Ambient lighting
    float3 ambient = ambientColor;

    // Diffuse lighting (Lambertian reflection)
    float diff = max(dot(normal, lightDirection), 0.0);
    float3 diffuse = diff * lightColor;

    // Specular lighting (Phong reflection)
    float3 reflectDir = reflect(-lightDirection, normal);
    float spec = pow(max(dot(viewDirection, reflectDir), 0.0), shininess);
    float3 specular = spec * lightColor;

    // Combine ambient, diffuse, and specular components
    return ambient + diffuse + specular;
}

struct MyNodeBuffer {
    float4x4 modelTransform;
    float4x4 modelViewTransform;
    float4x4 normalTransform;
    float4x4 modelViewProjectionTransform;
};


struct VertexIn {
    float3 position [[attribute(SCNVertexSemanticPosition)]];
    float2 uv [[ attribute(SCNVertexSemanticTexcoord0) ]];
    float3 normal [[ attribute(SCNVertexSemanticNormal) ]];
};


struct VertexOut {
    float4 position [[position]];
    float3 normal;
    float2 uv;
    
    float3 eye_direction_cameraspace;
    float3 light_direction_cameraspace;
};

constant float3 light_position = float3(50.0, 100.0, 50.0);


vertex VertexOut planetVertexShader(
    VertexIn                 in [[stage_in]],
    constant SCNSceneBuffer& scn_frame [[buffer(0)]],
    constant MyNodeBuffer&   scn_node [[buffer(1)]]
    ) {
    VertexOut vert;

    vert.position = scn_node.modelViewProjectionTransform * float4(in.position, 1.0);
            
    vert.uv = in.uv;
    vert.normal = in.normal;
    
    float4 vertex_position_modelspace = float4(in.position, 1.0f );

    float3 vertex_position_cameraspace = ( scn_node.modelViewTransform * vertex_position_modelspace ).xyz;
    vert.eye_direction_cameraspace = float3(0.0f,0.0f,0.0f) - vertex_position_cameraspace;

        
    float3 light_position_cameraspace = ( scn_frame.viewTransform * float4(light_position,1.0f)).xyz;
    vert.light_direction_cameraspace = light_position_cameraspace + vert.eye_direction_cameraspace;

    return vert;
}

//constant float4 light_color = float4(1.0, 1.0, 1.0, 1.0);
//constant float4 materialSpecularColor = float4(1.0, 1.0, 1.0, 1.0);
//constant float  materialShine = 1.0;

fragment float4 planetFragmentShader(VertexOut in [[stage_in]]) {
    
    float3 n = normalize(in.normal);
    float3 l = normalize(in.light_direction_cameraspace);
    float n_dot_l = saturate( dot(n, l) );
    float4 diffuse_color = n_dot_l * perlinColor(in.uv);
    
//    float3 e = normalize(in.eye_direction_cameraspace);
//    float3 r = -l + 2.0f * n_dot_l * n;
//    float e_dot_r =  saturate( dot(e, r) );
//    float4 specular_color = materialSpecularColor * light_color * pow(e_dot_r, materialShine);

    
    return diffuse_color;
}
