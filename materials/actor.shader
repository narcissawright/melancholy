shader_type spatial;
render_mode shadows_disabled, ambient_light_disabled;

// RIM
uniform bool enable_rim = false;
uniform bool only_rim = false;
uniform bool not_shaded = false;
uniform bool use_vertex_color = false;

uniform vec4 color_lit : hint_color = vec4(0.5, 0.5, 0.6, 1.0);
uniform vec4 color_dim : hint_color = vec4(0.1, 0.1, 0.12, 1.0);

uniform bool damaged = false;
const vec3 damaged_lit = vec3(1.0, 0.03, 0.03);
const vec3 damaged_dim = vec3(0.5, 0.0, 0.0);

uniform bool locked = false;
const vec3 locked_lit = vec3(0.2, 0.6, 0.8);
const vec3 locked_dim = vec3(0.0, 0.3, 0.4);

void fragment() {
	if (use_vertex_color) { ALBEDO = COLOR.rgb; }
	
	// Opacity Dithering...
	int x = int(FRAGCOORD.x / 2.0) % 4;
	int y = int(FRAGCOORD.y / 2.0) % 4;
	int index = x + y * 4;
	float limit = 0.0;
	
	// Dither pattern
	switch (index) {
		case 0:  limit = 0.0625; break;
		case 1:  limit = 0.5625; break;
		case 2:  limit = 0.1875; break;
		case 3:  limit = 0.6875; break;
		case 4:  limit = 0.8125; break;
		case 5:  limit = 0.3125; break;
		case 6:  limit = 0.9375; break;
		case 7:  limit = 0.4375; break;
		case 8:  limit = 0.25;   break;
		case 9:  limit = 0.75;   break;
		case 10: limit = 0.125;  break;
		case 11: limit = 0.625;  break;
		case 12: limit = 1.0;    break;
		case 13: limit = 0.5;    break;
		case 14: limit = 0.875;  break;
		case 15: limit = 0.375;  break;
	}
	
	// Depth Test
	float depth = FRAGCOORD.z;
	vec3 ndc = vec3(SCREEN_UV, depth) * 2.0 - 1.0;
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	float linear_depth = -view.z;
	if (linear_depth < limit) { discard; }
	
	if (enable_rim) {
		float NdotV = dot(VIEW, NORMAL);
		float rim = smoothstep(0.0, 1.0, NdotV);
		if ((only_rim) && (rim > 0.2)) { discard; } 
	}
}


void light() {
	// Cel Shading
	float NdotL = dot(LIGHT, NORMAL);
	float lit = smoothstep(0.0, 1.0, NdotL);
	
	// god I would love a way to use MULTIPLE LIGHTS with cel shading.
	//vec3 extra_light = LIGHT_COLOR * ATTENUATION;
	
	vec3 final_lit;
	vec3 final_dim;
	
	if (damaged) {
		final_lit = damaged_lit;
		final_dim = damaged_dim;
	} else if (locked) {
		final_lit = locked_lit;
		final_dim = locked_dim;
	} else if (use_vertex_color) {
		final_lit = ALBEDO;
		final_dim = ALBEDO * 0.5;
	} else {
		final_lit = color_lit.rgb;
		final_dim = color_dim.rgb;
	}
	
	if (not_shaded) { lit = 1.0; }
	
	if (enable_rim) {
		float NdotV = dot(VIEW, NORMAL);
		float rim = smoothstep(0.0, 1.0, NdotV);
		if (rim < 0.2) { lit = 0.0; } 
	}
	
	
	if (lit > 0.5) { 
		DIFFUSE_LIGHT = final_lit; 
	} else { 
		DIFFUSE_LIGHT = final_dim;
	}
}