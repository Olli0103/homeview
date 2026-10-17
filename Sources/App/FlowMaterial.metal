#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// Independent public SwiftUI layer shader. No private Apple's glass/text implementation.
// The layer is the alpha coverage of our numeral paths; dye is the shared fluid frame.
[[ stitchable ]] half4 flowGlyphMaterial(float2 position, SwiftUI::Layer glyphs,
                                        texture2d<half> dye, float2 size) {
    half coverage = glyphs.sample(position).a;
    if (coverage <= 0) return half4(0);
    constexpr sampler linearSampler(coord::normalized, address::clamp_to_edge, filter::linear);
    // Bevel normal from the SAME glyph mask, not a rotated copy of the backdrop.
    float r = 7.0;
    float dx = float(glyphs.sample(position + float2(r, 0)).a
                   - glyphs.sample(position - float2(r, 0)).a);
    float dy = float(glyphs.sample(position + float2(0, r)).a
                   - glyphs.sample(position - float2(0, r)).a);
    float2 slope = float2(dx, dy);
    float3 normal = normalize(float3(-slope * 1.6, 1.0));
    float3 transmitted = refract(float3(0, 0, -1), normal, 1.0 / 1.45);
    float2 uv = (position + transmitted.xy * 30.0) / max(size, float2(1));
    half3 color = dye.sample(linearSampler, uv).rgb;
    float3 light = normalize(float3(-0.55, -0.65, 1.0));
    float bevel = saturate(length(slope));
    float highlight = pow(saturate(dot(normal, light)), 12.0) * bevel;
    float shade = saturate(dot(normal, light)) * 0.18 + 0.92;
    // Mild tint gives a visible transparent foreground over the separately shaded backdrop.
    color = saturate(color * half(shade) + half3(0.035) + half(highlight * 0.7));
    return half4(color * coverage, coverage);
}
