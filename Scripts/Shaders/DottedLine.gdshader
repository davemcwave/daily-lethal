shader_type canvas_item;

void fragment() {
    vec2 uv = FRAGCOORD.xy / SCREEN_PIXEL_SIZE;
    float dot_size = 0.05;  // Size of the dots
    float spacing = 0.2;    // Spacing between the dots

    // Border distance calculation (for creating an outline)
    vec4 color = vec4(0.0, 0.0, 0.0, 1.0); // Color for the dotted outline (black)
    float border = min(uv.x, uv.y);  // Determines how far from the edge of the rectangle

    // Check if we're close to the edges of the custom control for a dotted outline
    if (mod(uv.x / spacing, 1.0) < dot_size || mod(uv.y / spacing, 1.0) < dot_size) {
        COLOR = color;
    } else {
        discard;
    }
}
