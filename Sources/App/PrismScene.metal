#include <metal_stdlib>
using namespace metal;

// Own analytic arrangement of layered straight-sided prisms. No reference texture.
static float prismRoundBox(float2 p,float2 halfSize,float radius) {
    float2 q=abs(p)-halfSize+radius;
    return length(max(q,0.0))+min(max(q.x,q.y),0.0)-radius;
}
static float prismRelief(float2 p,float2 halfSize) {
    float edge=-prismRoundBox(p,halfSize,5);
    float bevel=clamp(edge,0.0,9.0)*1.8;
    float facet=max(0.0,22.0-abs(p.y+12.0)*0.30);
    return bevel+facet*clamp(edge/9.0,0.0,1.0);
}
static float3 prismSlab(float3 behind,float2 world,float2 center,float angle,
    float2 halfSize,float3 tint,float variation) {
    float c=cos(angle),s=sin(angle);
    float2 d=world-center;
    float2 p=float2(c*d.x+s*d.y,-s*d.x+c*d.y);
    float distance=prismRoundBox(p,halfSize,5);
    float cover=1.0-smoothstep(-0.7,0.7,distance);
    float2 gradient=float2(prismRelief(p+float2(1,0),halfSize)-prismRelief(p-float2(1,0),halfSize),
        prismRelief(p+float2(0,1),halfSize)-prismRelief(p-float2(0,1),halfSize))*0.5;
    float3 normal=normalize(float3(-gradient,1));
    float light=saturate(dot(normal,normalize(float3(-0.5,-0.7,0.85))));
    float specular=pow(saturate(dot(normal,normalize(float3(-0.22,-0.4,1)))),42.0);
    float reflection=smoothstep(-halfSize.y*0.90,-halfSize.y*0.90+2.0,p.y)
        -smoothstep(halfSize.y*0.0,halfSize.y*0.0+2.0,p.y);
    float3 slab=tint*(0.48+light*0.78)*variation;
    // A distinct planar side face, rather than a smooth glossy tube.
    slab*=mix(1.0,0.55,smoothstep(-2.0,2.0,p.y));
    slab+=float3(0.58,0.61,1)*specular*0.25;
    slab=mix(slab,min(tint*1.65,float3(1)),reflection*0.42);
    float lip=exp(-abs(distance+1.0)*1.8)*0.18;
    slab+=lip*float3(0.72,0.78,1);
    return mix(behind,slab,cover);
}
[[ stitchable ]] half4 homePrismScene(float2 position,half4 input,
    float2 size,float time,float theme) {
    float2 uv=position/max(size,float2(1));
    float2 world=(uv-0.5)*600.0;
    world+=float2(sin(time*0.07)*4.0,(cos(time*0.06)-1.0)*3.0);
    float rotation=sin(time*0.035)*0.012;
    float3 tint=theme<0.5 ? float3(0.40,0.37,0.95):float3(0.07,0.60,0.66);
    if(theme>1.5) tint=float3(0.70,0.71,0.65);
    float3 scene=tint*0.65;
    scene=prismSlab(scene,world,float2(-80,-140),0.75+rotation,float2(350,85),tint,0.98);
    scene=prismSlab(scene,world,float2(-35,-150),1.57+rotation,float2(280,44),tint,0.84);
    scene=prismSlab(scene,world,float2(220,-160),-0.75+rotation,float2(230,38),tint,0.77);
    scene=prismSlab(scene,world,float2(-140,180),0.75+rotation,float2(300,95),tint,0.93);
    scene=prismSlab(scene,world,float2(180,180),0.75+rotation,float2(320,80),tint,0.95);
    scene=prismSlab(scene,world,float2(-95,75),-0.78+rotation,float2(340,62),tint,1.04);
    return half4(half3(saturate(scene)),input.a);
}
