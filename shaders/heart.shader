shader_type canvas_item;
uniform vec3 light_vec;

void fragment() {
	float opacity = texture(TEXTURE, UV).a;
	float brightness = dot(light_vec, NORMAL);
	brightness += 1.0;
	brightness /= 2.0;
	
	/*
	if (brightness > 0.8) {
		brightness = mix(brightness, 0.9, 0.65);
	} else if (brightness > 0.4) {
		brightness = mix(brightness, 0.72, 0.65);
	} else {
		brightness = mix(brightness, 0.5, 0.65);
	}
	*/
	vec3 color;
	
	if (brightness > 0.975) {
		color = vec3(1.0, 0.55, 0.55);
	} else if (brightness > 0.9) {
		brightness = mix(brightness, 1.0, 0.4);
		color = vec3(1.0, 0.15, 0.15);
		color *= brightness;
	} else if (brightness > 0.82) {
		color = vec3(1.0, 0.13, 0.15);
		color *= brightness;
	} else if (brightness > 0.48) {
		color = vec3(1.0, 0.1, 0.15);
		brightness = mix(brightness, 0.76, 0.45);
		color *= brightness;
	} else if (brightness > 0.28) {
		brightness = mix(brightness, 0.72, 0.65);
		color = vec3(0.9, 0.1, 0.2);
		color *= brightness;
	} else {
		brightness = mix(brightness, 0.85, 0.75);
		color = vec3(0.8, 0.13, 0.27);
		color *= brightness;
	}
	
	COLOR = vec4(color, opacity);
}