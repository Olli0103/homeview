#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// Own small volumetric field; no original textures or private weather framework.
static float weatherHash(float3 p) {
    p=fract(p*0.1031);
    p+=dot(p,p.yzx+33.33);
    return fract((p.x+p.y)*p.z);
}
static float weatherNoise(float3 p) {
    float3 cell=floor(p),f=fract(p);
    f=f*f*(3.0-2.0*f);
    float a=mix(mix(weatherHash(cell),weatherHash(cell+float3(1,0,0)),f.x),
                mix(weatherHash(cell+float3(0,1,0)),weatherHash(cell+float3(1,1,0)),f.x),f.y);
    float b=mix(mix(weatherHash(cell+float3(0,0,1)),weatherHash(cell+float3(1,0,1)),f.x),
                mix(weatherHash(cell+float3(0,1,1)),weatherHash(cell+1),f.x),f.y);
    return mix(a,b,f.z);
}
static float weatherField(float3 p) {
    return weatherNoise(p)*0.50+weatherNoise(p*2.07+float3(4.3,8.1,2.7))*0.25
         +weatherNoise(p*4.21+float3(13.7,9.5,6.1))*0.14
         +weatherNoise(p*8.7+float3(7.3,2.1,9.2))*0.07
         +weatherNoise(p*17.7+float3(3.1,16.7,4.9))*0.04;
}
static float weatherDensity(float3 p,float cover,float daylight) {
    // Own wind-sheared daylight layers. Keep the established night field;
    // this is an illustration, not a measured cloud height or solar position.
    float3 layered=float3(p.x*0.75+p.y*0.15,p.y*1.20,p.z*0.65);
    float3 fieldPoint=mix(p,layered,daylight);
    float ceiling=mix(0.90,0.30,saturate(cover))
        +smoothstep(0.18,0.65,p.y/4.0)*mix(0.30,0.20,daylight);
    // Close excessive upper daylight gaps without adding density samples.
    if(daylight>0.5)
        ceiling-=0.035*(1.0-smoothstep(0.08,0.22,p.y/4.0))*saturate(cover/0.70);
    return max(0.0,weatherField(fieldPoint*2.0)-ceiling)*mix(5.0,9.0,daylight);
}
// Both the backdrop and refracted text evaluate this same sky. UI05's lower
// sky is a light blue, not the saturated mid-blue of the earlier illustration.
static float3 weatherSky(float2 uv,float night) {
    float3 top=mix(float3(0.08,0.32,0.57),float3(0.12,0.16,0.31),night);
    float3 bottom=mix(float3(0.41,0.64,0.88),float3(0.02,0.07,0.18),night);
    return mix(top,bottom,saturate(uv.y));
}
static float3 weatherScene(float2 uv,float time,float cover,float night) {
    float3 base=weatherSky(uv,night);
    if(cover<=0.0) return base;
    float daylight=1.0-night;
    float topBand=1.0-smoothstep(0.28,0.54,uv.y);
    float3 origin=float3(uv*4.0,1.37)+float3(time*0.018,0,0);
    float3 sunlight=normalize(float3(-0.5,-0.7,-0.5));
    float transmission=1.0;
    float3 cloudLight=float3(0);
    for(int i=0;i<16;i++) {
        float3 p=origin+float3(0,0,float(i)*0.19);
        float density=weatherDensity(p,cover,daylight)*topBand;
        float nearShadow=weatherDensity(p+sunlight*0.35,cover,daylight);
        // Two bounded light samples distinguish lit edges and shaded bodies.
        // No ray/step count depends on remote weather data.
        float farShadow=weatherDensity(p+sunlight*0.75,cover,daylight);
        float layeredLight=0.18+0.82*exp(-(density*0.40+nearShadow*0.50+farShadow*0.90)*2.6);
        float nightLight=0.30+0.70*exp(-nearShadow*2.1);
        float light=mix(nightLight,layeredLight,daylight);
        // Lift only the daylight shadow floor; keep density, light and night unchanged.
        float3 shadow=mix(float3(0.45,0.54,0.67),float3(0.66,0.74,0.85),daylight);
        float3 color=mix(shadow,float3(1.0,0.995,0.98),light);
        color*=1.0-smoothstep(0.05,0.45,uv.y)*0.16;
        color=mix(color,color*float3(0.34,0.39,0.57),night*0.7);
        float opacity=1.0-exp(-density*0.85);
        cloudLight+=transmission*opacity*color;
        transmission*=1.0-opacity;
    }
    float glow=exp(-length((uv-float2(0.27,0.04))*float2(5.0,6.0))*3.5)*(1.0-night);
    base=mix(base,float3(1.0,0.99,0.95),glow*0.70);
    return base*transmission+cloudLight;
}
[[ stitchable ]] half4 weatherCloudField(float2 position,half4 input,
    float2 size,float time,float cover,float night) {
    return half4(half3(weatherScene(position/max(size,float2(1)),time,cover,night)),input.a);
}
// Runtime system-text alpha mask, not redistributed font outlines.
[[ stitchable ]] half4 weatherGlassNumber(float2 position,SwiftUI::Layer mask,
    float2 origin,float2 size,float time,float cover,float night) {
    float coverage=smoothstep(0.35,0.65,float(mask.sample(position).a));
    if(coverage<=0.0) return half4(0);
    float2 slope=float2(0);
    const float radii[5]={1,3,6,10,14};
    const float weights[5]={0.10,0.17,0.25,0.26,0.22};
    for(int i=0;i<5;i++) {
        float r=radii[i];
        slope+=float2(float(mask.sample(position+float2(r,0)).a-mask.sample(position-float2(r,0)).a),
                      float(mask.sample(position+float2(0,r)).a-mask.sample(position-float2(0,r)).a))*weights[i];
    }
    float3 normal=normalize(float3(-slope*1.5,1));
    float3 ray=refract(float3(0,0,-1),normal,1.0/1.45);
    float2 uv=(origin+position+ray.xy*12.0)/max(size,float2(1));
    float3 color=weatherScene(uv,time,cover,night);
    float bevel=saturate(length(slope));
    float highlight=pow(saturate(dot(normal,normalize(float3(-0.5,-0.7,1)))),18.0)*bevel;
    float upper=max(0.0,coverage-float(mask.sample(position-float2(0.8,0.8)).a));
    float lower=max(0.0,coverage-float(mask.sample(position+float2(0.8,0.8)).a));
    // Broad translucent body plus a narrow white/cyan lip, as visible in UI05.
    // Keep the field legible through the body rather than painting opaque text.
    float bodyLight=mix(0.43,0.24,night);
    color=mix(color,float3(0.84,0.94,1),bodyLight);
    color=color*(1.0-lower*0.12)+highlight*0.40+upper*0.58;
    return half4(half3(saturate(color)*coverage),half(coverage));
}
