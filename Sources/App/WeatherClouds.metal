#include <metal_stdlib>
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
static float weatherDensity(float3 p,float cover) {
    float ceiling=mix(0.90,0.30,saturate(cover))+smoothstep(0.18,0.65,p.y/4.0)*0.30;
    return max(0.0,weatherField(p*2.0)-ceiling)*5.0;
}
[[ stitchable ]] half4 weatherCloudField(float2 position,half4 input,
    float2 size,float time,float cover,float night) {
    float2 uv=position/max(size,float2(1));
    if(cover<=0.0) return input;
    float topBand=1.0-smoothstep(0.28,0.54,uv.y);
    float3 origin=float3(uv*4.0,1.37)+float3(time*0.018,0,0);
    float3 sunlight=normalize(float3(-0.5,-0.7,-0.5));
    float transmission=1.0;
    float3 cloudLight=float3(0);
    for(int i=0;i<16;i++) {
        float3 p=origin+float3(0,0,float(i)*0.19);
        float density=weatherDensity(p,cover)*topBand;
        float shadow=weatherDensity(p+sunlight*0.35,cover);
        float light=0.30+0.70*exp(-shadow*2.1);
        float3 color=mix(float3(0.45,0.54,0.67),float3(1.0,0.995,0.98),light);
        color*=1.0-smoothstep(0.05,0.45,uv.y)*0.16;
        color=mix(color,color*float3(0.34,0.39,0.57),night*0.7);
        float opacity=1.0-exp(-density*0.85);
        cloudLight+=transmission*opacity*color;
        transmission*=1.0-opacity;
    }
    float3 sky=float3(input.rgb);
    float glow=exp(-length((uv-float2(0.27,0.04))*float2(5.0,6.0))*3.5)*(1.0-night);
    sky=mix(sky,float3(1.0,0.99,0.95),glow*0.70);
    return half4(half3(sky*transmission+cloudLight),input.a);
}
