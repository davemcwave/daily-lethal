shader_type canvas_item;

uniform sampler2D mask_texture;
uniform vec4 darken_color : source_color = vec4(0.0, 0.0, 0.0, 0.7); // Color to darken with (default: semi-transparent black)
uniform vec2 mask_position = vec2(0.5, 0.5); // Center position (0-1)
uniform vec2 mask_scale = vec2(1.0, 1.0); // Scale of mask
uniform float mask_rotation : hint_range(0.0, 360.0) = 0.0; // Rotation in degrees
uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap;

void fragment() {
    // Transform UV to apply position, scale, and rotation
    vec2 transformed_uv = UV - mask_position;

    // Apply rotation
    float angle = radians(mask_rotation);
    float cos_angle = cos(angle);
    float sin_angle = sin(angle);
    transformed_uv = vec2(
        transformed_uv.x * cos_angle - transformed_uv.y * sin_angle,
        transformed_uv.x * sin_angle + transformed_uv.y * cos_angle
    );

    // Apply scale
    transformed_uv = transformed_uv / mask_scale;

    // Recenter
    transformed_uv += vec2(0.5);

    // Sample the mask with transformed UV
    vec4 mask = texture(mask_texture, transformed_uv);

    // Get the screen content
    vec4 screen_color = texture(SCREEN_TEXTURE, SCREEN_UV);

    // Where mask is white = show clear
    // Where mask is black/transparent = apply darkening
    vec4 darkened = mix(screen_color, darken_color, darken_color.a);
    COLOR = mix(darkened, screen_color, mask.a);
}