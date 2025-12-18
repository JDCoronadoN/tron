shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, unshaded;

uniform sampler2D mask_tex : hint_albedo; // baked gradient mask
uniform vec3 top_color : source_color = vec3(1.0, 0.8, 0.5);
uniform vec3 mid_color : source_color = vec3(0.1, 0.1, 0.1);
uniform float glow_strength : hint_range(0.0, 20.0) = 10.0;
uniform float gloss_strength : hint_range(0.0, 1.0) = 0.05;

void fragment() {
    vec2 uv = UV;
    float mask = texture(mask_tex, uv).r;

    // Emission stronger at top & bottom, weaker in the middle
    float emission_factor = smoothstep(0.0, 0.2, mask) + smoothstep(1.0, 0.8, mask);
    emission_factor = clamp(emission_factor, 0.0, 1.0);

    ALBEDO = mix(mid_color, top_color, emission_factor);
    EMISSION = ALBEDO * glow_strength * emission_factor;

    // Glossy look (low roughness)
    ROUGHNESS = gloss_strength * (1.0 - emission_factor);
    METALLIC = 0.0;
}
