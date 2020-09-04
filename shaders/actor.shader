shader_type spatial;
render_mode ambient_light_disabled;

uniform float opacity = 1.0;
uniform bool opacity_depth_calc = true;
uniform bool celshaded = true;
uniform bool enable_rim = false;
uniform bool not_shaded = false;
uniform bool use_vertex_color = false;

uniform bool vertex_color_as_occlusion = false;

uniform vec4 color_lit : hint_color = vec4(0.5, 0.5, 0.6, 1.0);
uniform vec4 color_dim : hint_color = vec4(0.1, 0.1, 0.12, 1.0);

// not using these right now
uniform bool use_custom_rim_color = false;
uniform vec4 custom_rim_color : hint_color = vec4(0.0, 0.82, 0.73, 1.0);

uniform bool use_texture = false;
uniform sampler2D tex_lit : hint_albedo;
uniform sampler2D tex_shaded : hint_albedo;

uniform bool damaged = false;
const vec3 damaged_lit = vec3(1.0, 0.03, 0.03);
const vec3 damaged_dim = vec3(0.5, 0.0, 0.0);

uniform bool locked = false;
const vec3 locked_lit = vec3(0.2, 0.6, 0.8);
const vec3 locked_dim = vec3(0.0, 0.3, 0.4);

void fragment() {

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

	if (opacity_depth_calc) {
		// Depth Test
		float depth = FRAGCOORD.z;
		vec3 ndc = vec3(SCREEN_UV, depth) * 2.0 - 1.0;
		vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
		view.xyz /= view.w;
		float linear_depth = -view.z * 2.0; // this *2 is experiment
		if (linear_depth < limit) { discard; }
	} else {
		if (opacity < limit) { discard; }
	}
	
	//
	//
	//
	//
	//
	
	/*
	
	vec3 final_lit;
	vec3 final_shaded;
	
	float NdotL = dot(light_vec, NORMAL);

	if (use_texture) {
		final_lit = texture(tex_lit, UV).rgb;
		final_shaded = texture(tex_shaded, UV).rgb;
	}
	
	float threshold = 0.5;
	// 1.0 - COLOR.r; // stupid
	//threshold = 0.78;
	
	if (NdotL > threshold) {
		ALBEDO = final_lit;
	} else {
		ALBEDO = final_shaded;
	}

	if (enable_rim) {
		float NdotV = dot(VIEW, NORMAL);
		float rim = smoothstep(0.0, 1.0, NdotV);
	}
	
	*/
}


void light() {
	// Cel Shading
	float NdotL = dot(LIGHT, NORMAL);
	float lit = NdotL; //clamp(NdotL, 0.0, 1.0); //smoothstep(0.0, 1.0, NdotL);
	
	vec3 final_lit;
	vec3 final_dim;

	if (use_texture) {
		final_lit = texture(tex_lit, UV).rgb;
		final_dim = texture(tex_shaded, UV).rgb;
	} else if (use_vertex_color) {
		final_lit = ALBEDO;
		final_dim = ALBEDO * 0.5;
	} else {
		final_lit = color_lit.rgb;
		final_dim = color_dim.rgb;
	}
	
	vec3 final_diff = final_lit - final_dim;
	vec3 light_energy = min(vec3(1,1,1), ATTENUATION * LIGHT_COLOR);
	final_diff *= light_energy; // min(final_diff, final_diff + light_energy);
	
	if (damaged) {
		final_lit = damaged_lit;
		final_dim = damaged_dim;
	} else if (locked) {
		final_lit = locked_lit;
		final_dim = locked_dim;
	}

	float threshold = 0.5;
	
	if (vertex_color_as_occlusion) {
		threshold = 1.0 - ALBEDO.r; // this fails to do reading it as SRGB
	}
	
	if (enable_rim) { 
		float NdotV = dot(VIEW, NORMAL);
		// this has no antialiasing right now.
		if (NdotV < 0.3) {
			threshold = 0.0;
//			if (use_custom_rim_color) {
//				DIFFUSE_LIGHT = custom_rim_color.rgb;
//			}
		}
	}
	
	
	if (not_shaded) { lit = 1.0; }
	
	if (celshaded) {
		float E = fwidth(lit) / 2.0;
		if (lit > threshold - E && lit < threshold + E) {
			lit = smoothstep(threshold - E, threshold + E, lit);
			//lit = clamp(threshold * (lit - threshold + E) / E, 0.0, 1.0);
		} else {
			lit = step(threshold, lit);
	    }
	 }
	
	 DIFFUSE_LIGHT = max(DIFFUSE_LIGHT, mix(final_dim, final_dim + final_diff, lit));
	 //DIFFUSE_LIGHT = ATTENUATION;
}
