#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// Independent public SwiftUI layer shader. No private Apple's glass/text implementation.
// The layer is the alpha coverage of our numeral paths; dye is the shared fluid frame.
[[ stitchable ]] half4 flowGlyphMaterial(float2 position, SwiftUI::Layer glyphs,
                                        texture2d<half> dye, float2 size) {
    half coverage = half(smoothstep(0.40, 0.60, float(glyphs.sample(position).a)));
    if (coverage <= 0) return half4(0);
    constexpr sampler linearSampler(coord::normalized, address::clamp_to_edge, filter::linear);
    // Bevel normal from the SAME glyph mask, not a rotated copy of the backdrop.
    float2 slope = float2(0);
    const float radii[6] = {2, 5, 9, 14, 20, 28};
    const float weights[6] = {0.08, 0.12, 0.18, 0.22, 0.22, 0.18};
    for (int i = 0; i < 6; ++i) {
      float r = radii[i];
      float dx = float(glyphs.sample(position + float2(r, 0)).a
                     - glyphs.sample(position - float2(r, 0)).a);
      float dy = float(glyphs.sample(position + float2(0, r)).a
                     - glyphs.sample(position - float2(0, r)).a);
      slope += float2(dx,dy) * weights[i];
    }
    float3 normal = normalize(float3(-slope * 1.6, 1.0));
    float3 transmitted = refract(float3(0, 0, -1), normal, 1.0 / 1.45);
    float2 uv = (position + transmitted.xy * 30.0) / max(size, float2(1));
    half3 color = dye.sample(linearSampler, uv).rgb;
    float3 light = normalize(float3(-0.55, -0.65, 1.0));
    float bevel = saturate(length(slope));
    float highlight = pow(saturate(dot(normal, light)), 12.0) * bevel;
    float shade = 1.0 - bevel * 0.06 + saturate(dot(normal, light)) * bevel * 0.04;
    // A faint body veil and broad edge highlight, with the SAME vivid field
    // behind and through the glyph. The reference is not dark wallpaper with
    // opaque neon text pasted over it.
    float rim = saturate(float(coverage) - smoothstep(0.40, 0.60,
      float(glyphs.sample(position - float2(1.2, 1.2)).a)));
    color = mix(color * half(shade), half3(1), half(0.06 + highlight * 0.18 + rim * 0.45));
    return half4(color * coverage, coverage);
}

// Own photo-clock material. Only own/runtime-public glyph alpha and the selected
// image enter this effect; the face's crop/destination also drive transmission.
[[ stitchable ]] half4 photoGlassGlyph(float2 position, SwiftUI::Layer glyphs,
    texture2d<half> photo, float2 origin, float2 cropOrigin, float2 cropSize,
    float2 destinationOrigin, float2 destinationSize) {
    float coverage = smoothstep(0.35, 0.65, float(glyphs.sample(position).a));
    if (coverage <= 0.001) return half4(0);
    constexpr sampler linearSampler(coord::normalized, address::clamp_to_edge, filter::linear);
    float2 slope = float2(0);
    const float radii[4] = {1, 3, 7, 12};
    const float weights[4] = {0.12, 0.22, 0.34, 0.32};
    for (int i = 0; i < 4; ++i) {
      float r = radii[i];
      slope += float2(
        float(glyphs.sample(position + float2(r, 0)).a - glyphs.sample(position - float2(r, 0)).a),
        float(glyphs.sample(position + float2(0, r)).a - glyphs.sample(position - float2(0, r)).a)) * weights[i];
    }
    float3 normal = normalize(float3(-slope * 1.5, 1));
    float2 refracted = refract(float3(0, 0, -1), normal, 1.0 / 1.45).xy * 6;
    float2 viewport = (position + origin + refracted) / 600.0;
    float2 relative = (viewport - destinationOrigin) / max(destinationSize, float2(0.0001));
    float2 uv = cropOrigin + relative * cropSize;
    float3 color = all(relative >= 0) && all(relative <= 1)
      ? float3(photo.sample(linearSampler, uv).rgb) : float3(0);
    float bevel = saturate(length(slope));
    float highlight = pow(saturate(dot(normal, normalize(float3(-0.55, -0.65, 1)))), 14.0) * bevel;
    float upper = max(0.0, coverage - float(glyphs.sample(position - float2(0.8, 0.8)).a));
    float lower = max(0.0, coverage - float(glyphs.sample(position + float2(0.8, 0.8)).a));
    color = mix(color, float3(1), 0.08);
    color = color * (1.0 - lower * 0.14) + highlight * 0.30 + upper * 0.42;
    return half4(half3(saturate(color) * coverage), half(coverage));
}
