#include <metal_stdlib>
using namespace metal;

// Own analytic relief; no texture or shader bytes from the reference product.
static float prismRoundBox(float2 p,float2 halfSize,float radius) {
    float2 q=abs(p)-halfSize+radius;
    return length(max(q,0.0))+min(max(q.x,q.y),0.0)-radius;
}
static float prismRelief(float2 p) {
    float edge=-prismRoundBox(p,float2(153,79),10);
    float bevel=smoothstep(0.0,22.0,edge)*18.0;
    float facet=max(0.0,44.0-abs(p.x+24.0)*0.34);
    return bevel+facet*smoothstep(0.0,18.0,edge)+p.y*0.025;
}
[[ stitchable ]] half4 homePrismScene(float2 position,half4 input,
    float2 size,float time,float theme) {
    float2 uv=position/max(size,float2(1));
    float2 world=(uv-0.5)*600.0;
    float angle=0.75+sin(time*0.035)*0.012;
    float c=cos(angle),s=sin(angle);
    float2 p=float2(c*world.x+s*world.y,-s*world.x+c*world.y);
    p+=float2(sin(time*0.07)*4.0,cos(time*0.06)*3.0);
    float row=floor((p.y+85.0)/170.0);
    p.x+=fmod(row,2.0)*160.0;
    float column=floor((p.x+160.0)/320.0);
    float2 local=float2(p.x-column*320.0,p.y-row*170.0);
    float distance=prismRoundBox(local,float2(153,79),10);
    float cover=1.0-smoothstep(-0.7,0.7,distance);
    float2 gradient=float2(prismRelief(local+float2(1,0))-prismRelief(local-float2(1,0)),
        prismRelief(local+float2(0,1))-prismRelief(local-float2(0,1)))*0.5;
    float3 normal=normalize(float3(-gradient,1));
    float light=saturate(dot(normal,normalize(float3(-0.5,-0.7,0.85))));
    float specular=pow(saturate(dot(normal,normalize(float3(-0.22,-0.4,1)))),42.0);
    float3 dark=theme<0.5 ? float3(0.035,0.025,0.34):float3(0.01,0.19,0.23);
    float3 tint=theme<0.5 ? float3(0.35,0.31,0.94):float3(0.07,0.60,0.66);
    if(theme>1.5) { dark=float3(0.20,0.21,0.19);tint=float3(0.70,0.71,0.65); }
    float reflection=smoothstep(-110.0,-75.0,local.x)-smoothstep(-30.0,15.0,local.x);
    float variation=0.92+sin(row*1.7+column*2.4)*0.08;
    float3 slab=tint*(0.25+light*0.88)*variation;
    slab+=float3(0.58,0.61,1)*specular*0.48;
    slab=mix(slab,theme<0.5 ? float3(0.72,0.70,1):float3(0.51,0.96,0.94),reflection*0.43);
    float lip=exp(-abs(distance+1.5)*1.2)*0.35;
    slab+=lip*float3(0.72,0.78,1);
    return half4(half3(saturate(mix(dark,slab,cover))),input.a);
}
