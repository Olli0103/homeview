#include <metal_stdlib>
using namespace metal;

// Own screen-space illustration, separate from the established cloud/glass shader.
// Not an original solar model, depth-occluded ray or new refraction implementation.
[[ stitchable ]] half4 weatherDaylightSpur(float2 position,half4 input,
    float2 size,float cover) {
    float2 uv=position/max(size,float2(1));
    if(cover<=0.0 || uv.x<=0.28 || uv.x>=0.58 || uv.y<=0.35 || uv.y>=0.72)
        return half4(0);
    float center=0.24+0.32*uv.y;
    float core=exp(-0.5*pow((uv.x-center)/0.019,2.0));
    float halo=0.20*exp(-0.5*pow((uv.x-center+0.035)/0.030,2.0));
    float bounds=smoothstep(0.28,0.31,uv.x)*(1.0-smoothstep(0.55,0.58,uv.x));
    float height=smoothstep(0.35,0.48,uv.y)*(1.0-smoothstep(0.70,0.72,uv.y));
    half alpha=half(0.06*(core+halo)*bounds*height*saturate(cover/0.70));
    return half4(half3(alpha),alpha); // Premultiplied white; exactly zero outside support.
}
