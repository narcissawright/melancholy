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
	
	
	if (brightness > 0.9) {
		brightness = mix(brightness, 0.9, 0.5);
	} else if (brightness > 0.8) {
		brightness = mix(brightness, 0.75, 0.45);
	} else if (brightness > 0.45) {
		brightness = mix(brightness, 0.66, 0.65);
	} else if (brightness > 0.25) {
		brightness = mix(brightness, 0.5, 0.65);
	} else {
		brightness = mix(brightness, 0.3, 0.75);
	}
	
	
	vec3 coldness = vec3(0.0, 0.1, 0.4);
	vec3 color = vec3(1.0, 0.1, 0.15);
	color += coldness * (1.0 - brightness);
	//color -= coldness * (brightness);
	color *= brightness;
	COLOR = vec4(color, opacity);
}