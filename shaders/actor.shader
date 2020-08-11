shader_type spatial;
render_mode shadows_disabled, unshaded, ambient_light_disabled;

uniform vec3 light_vec;

uniform bool opacity_dither = true;
uniform bool celshaded = true;
uniform bool enable_rim = false;
uniform bool not_shaded = false;
uniform bool use_vertex_color = false;

uniform bool vertex_color_as_occlusion = false;

uniform vec4 color_lit : hint_color = vec4(0.5, 0.5, 0.6, 1.0);
uniform vec4 color_dim : hint_color = vec4(0.1, 0.1, 0.12, 1.0);

uniform bool use_texture = false;
uniform sampler2D tex_lit : hint_albedo;
uniform sampler2D tex_shaded : hint_albedo;

uniform bool damaged = false;
const vec3 damaged_lit = vec3(1.0, 0.03, 0.03);
const vec3 damaged_dim = vec3(0.5, 0.0, 0.0);

uniform bool locked = false;
const vec3 locked_lit = vec3(0.2, 0.6, 0.8);
const vec3 locked_dim = vec3(0.0, 0.3, 0.4);

void vertex() {
	// use world space normals
	NORMAL = (CAMERA_MATRIX * vec4(NORMAL, 0.0)).xyz;
	//COLOR.rgb = mix( pow((COLOR.rgb + vec3(0.055)) * (1.0 / (1.0 + 0.055)), vec3(2.4)), COLOR.rgb* (1.0 / 12.92), lessThan(COLOR.rgb,vec3(0.04045)) );
}

void fragment() {
	
	if (opacity_dither) {
	
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
		float linear_depth = -view.z * 2.0; // this *2 is experiment
		if (linear_depth < limit) { discard; }
	}
	
	//
	//
	//
	//
	//
	
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

	
	
	/*
	if (enable_rim) {
		float NdotV = dot(VIEW, NORMAL);
		float rim = smoothstep(0.0, 1.0, NdotV);
	}*/
}

/*
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
	
	if (damaged) {
		final_lit = damaged_lit;
		final_dim = damaged_dim;
	} else if (locked) {
		final_lit = locked_lit;
		final_dim = locked_dim;
	}

	float threshold = 0.5;
	if (vertex_color_as_occlusion) {
		threshold = 1.0 - ALBEDO.r; // should be 1.0 - 0.5. wtf????
	}
	
	if (enable_rim) {
		float NdotV = dot(VIEW, NORMAL);
		
		if (NdotV < 0.2) {
			threshold = -0.7;
		}
	}
	
	
	if (not_shaded) { lit = 1.0; }
	if (celshaded) {
		if (lit > threshold) { 
			DIFFUSE_LIGHT = final_lit; 
		} else { 
			DIFFUSE_LIGHT = final_dim;
		}
	} else {
		DIFFUSE_LIGHT = mix(final_dim, final_lit, lit);
	}
}
*/