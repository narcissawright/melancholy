shader_type spatial;
render_mode blend_add, cull_disabled, unshaded; // use blend_add in the end.
uniform sampler2D noise;
uniform float external_opacity;

void fragment() {
	float viewangle = 1.0 - dot(VIEW, NORMAL);
	// at 90 degrees, viewangle is 1.0
	// when view and normal are facing each other, viewangle is 0.0
	
	
	float breathing = (sin(TIME * 1.5) + 1.0) / 2.0; // range 0.0 to 1.0
	breathing *= 0.15; // range 0.0 to 0.15
	breathing += 0.05; // range 0.05 to 0.2
	float opacity = clamp(viewangle + breathing, 0.0, 1.0);
	
	float sin_time = (sin(TIME) / 10.0);
	
	vec2 noise_pos = mod(FRAGCOORD.xy, vec2(512, 512)) / 512.0;
	float noise_value = texture(noise, noise_pos + vec2(0, TIME * 0.8)).r;
	noise_value += sin_time;
	noise_value = smoothstep(0.4, 0.6, noise_value);
	
	noise_pos = mod(FRAGCOORD.xy + vec2(256, 256), vec2(512, 512)) / 512.0;
	float noise_value2 = texture(noise, noise_pos + vec2(0, TIME * -0.35)).r;
	noise_value2 += sin_time;
	noise_value2 = smoothstep(0.4, 0.6, noise_value2);
	
	ALPHA = (opacity + (noise_value * 0.1 * opacity) - (noise_value2 * 0.07)) * 0.65 * external_opacity;
	
	vec3 blue = vec3(0.02, 0.01, 1.0);
	ALBEDO = blue + (vec3(0.08, 0.12, 0.0) * opacity);
}
