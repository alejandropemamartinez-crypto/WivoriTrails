shader_type spatial;
render_mode specular_schlick_ggx;

// Facial features are painted on the same smooth head mesh as the snout.
// No free-floating eye, nose, tooth or moustache geometry.
uniform vec4 skin : source_color = vec4(0.9, 0.7, 0.5, 1.0);
uniform bool animal = true;
uniform bool canine = false;
uniform bool scottie = false;
uniform bool masked = false;
uniform float phase = 0.0;
varying vec3 local_head;

float ellipse(vec2 p, vec2 center, vec2 radius) {
	return 1.0 - smoothstep(0.83, 1.0, length((p - center) / radius));
}
void vertex() {
	local_head = VERTEX;
}
void fragment() {
	vec2 p = local_head.xy;
	float front = smoothstep(0.18, 0.34, local_head.z);
	float blinking = pow(max(0.0, cos(TIME * 1.18 + phase)), 58.0);
	float eye_height = mix(0.063, 0.007, blinking);
	vec3 base = skin.rgb;
	if (scottie) {
		// Soft grey brindle coat painted across the SAME head surface.
		float brindle = sin(local_head.x * 64.0 + 6.2 * sin(local_head.y * 23.0)) * sin(local_head.y * 17.0 + local_head.z * 12.0);
		base *= 0.96 + 0.040 * brindle;
	}
	// Warm cheek shadows add volume without extra floating mesh parts.
	float cheeks = ellipse(p, vec2(0.0,-0.08), vec2(0.39,0.30));
	base *= 1.0 - 0.045 * cheeks * front;
	if (masked) {
		float dark_mask = ellipse(p, vec2(0.0,0.085), vec2(0.335,0.17));
		base = mix(base,vec3(0.20,0.26,0.29),dark_mask*front*0.93);
	}
	float muzzle = ellipse(p,vec2(0.0,-0.158),vec2(canine ? 0.28 : 0.22,0.155));
	if (animal) {
		base = mix(base,mix(skin.rgb,scottie ? vec3(0.59,0.62,0.63) : vec3(0.97,0.88,0.73),scottie ? .46 : .73),muzzle*front*.95);
		if (scottie) {
			float beard = ellipse(p,vec2(0.0,-0.326),vec2(.235,.135));
			base = mix(base,vec3(.72,.74,.74),beard*front*.82);
			float brow1 = ellipse(p,vec2(-.172,.160),vec2(.118,.036));
			float brow2 = ellipse(p,vec2(.172,.160),vec2(.118,.036));
			base = mix(base,vec3(.70,.71,.69),max(brow1,brow2)*front*.93);
		}
	}
	float blush = max(ellipse(p,vec2(-0.31,-0.09),vec2(0.075,0.045)),
		ellipse(p,vec2(0.31,-0.09),vec2(0.075,0.045)));
	base = mix(base,vec3(0.89,0.48,0.39),blush*front*(scottie ? .035 : .26));
	float eye_left = ellipse(p,vec2(-0.174,0.072),vec2(scottie ? .044 : .055,scottie ? eye_height*.83 : eye_height));
	float eye_right = ellipse(p,vec2(0.174,0.072),vec2(scottie ? .044 : .055,scottie ? eye_height*.83 : eye_height));
	float eyes = max(eye_left,eye_right);
	base = mix(base,vec3(0.095,0.13,0.14),eyes*front);
	float shine = max(ellipse(p,vec2(-0.19,0.094),vec2(0.017,0.020)),
		ellipse(p,vec2(0.158,0.094),vec2(0.017,0.020)));
	base = mix(base,vec3(1.0,0.97,0.88),shine*front*(1.0-blinking));
	float nose = ellipse(p,vec2(0.0,scottie ? -.191 : -.119),vec2(scottie ? .068 : (canine ? .066 : .043),scottie ? .042 : .037));
	base = mix(base,scottie ? vec3(.16,.17,.17) : (animal ? vec3(0.22,0.16,0.16) : vec3(0.59,0.31,0.29)),nose*front);
	float smile_radius = abs(length((p-vec2(0.0,-0.19))*vec2(1.0,1.45))-0.085);
	float smile = (1.0 - smoothstep(0.005,0.012,smile_radius))*step(p.y,-0.205);
	base = mix(base,vec3(0.31,0.20,0.17),smile*front*(scottie ? .22 : .85));
	ALBEDO = base;
	ROUGHNESS = 0.96;
	SPECULAR = 0.22;
}
