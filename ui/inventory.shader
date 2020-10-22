shader_type canvas_item;
render_mode unshaded;

uniform bool selected = false;

void fragment() {
	COLOR = texture(TEXTURE, UV);
	if (!selected) {
		float greyscale = (COLOR.r + COLOR.g + COLOR.b) / 3.0;
		greyscale *= 0.5;
		COLOR.r = mix(COLOR.r, greyscale, 0.95);
		COLOR.g = mix(COLOR.g, greyscale, 0.95);
		COLOR.b = mix(COLOR.b, greyscale, 0.95);
	}
}