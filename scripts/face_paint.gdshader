shader_type spatial;
render_mode cull_disabled, specular_schlick_ggx;

// Facial features are painted on the same smooth head mesh as the snout.
// No free-floating eye, nose, tooth or moustache geometry.
uniform vec4 skin : source_color = vec4(0.9, 0.7, 0.5, 1.0);
uniform bool animal = true;
uniform bool canine = false;
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
	// Warm cheek shadows add volume without extra floating mesh parts.
	float cheeks = ellipse(p, vec2(0.0,-0.08), vec2(0.39,0.30));
	base *= 1.0 - 0.045 * cheeks * front;
	if (masked) {
		float dark_mask = ellipse(p, vec2(0.0,0.085), vec2(0.335,0.17));
		base = mix(base,vec3(0.20,0.26,0.29),dark_mask*front*0.93);
	}
	float muzzle = ellipse(p,vec2(0.0,-0.158),vec2(canine ? 0.28 : 0.22,0.155));
	if (animal) {
		base = mix(base,mix(skin.rgb,vec3(0.97,0.88,0.73),0.73),muzzle*front*0.95);
	}
	float blush = max(ellipse(p,vec2(-0.31,-0.09),vec2(0.075,0.045)),
		ellipse(p,vec2(0.31,-0.09),vec2(0.075,0.045)));
	base = mix(base,vec3(0.89,0.48,0.39),blush*front*0.26);
	float eye_left = ellipse(p,vec2(-0.174,0.072),vec2(0.055,eye_height));
	float eye_right = ellipse(p,vec2(0.174,0.072),vec2(0.055,eye_height));
	float eyes = max(eye_left,eye_right);
	base = mix(base,vec3(0.095,0.13,0.14),eyes*front);
	float shine = max(ellipse(p,vec2(-0.19,0.094),vec2(0.017,0.020)),
		ellipse(p,vec2(0.158,0.094),vec2(0.017,0.020)));
	base = mix(base,vec3(1.0,0.97,0.88),shine*front*(1.0-blinking));
	float nose = ellipse(p,vec2(0.0,-0.119),vec2(canine ? 0.066 : 0.043,0.037));
	base = mix(base,animal ? vec3(0.22,0.16,0.16) : vec3(0.59,0.31,0.29),nose*front);
	float smile_radius = abs(length((p-vec2(0.0,-0.19))*vec2(1.0,1.45))-0.085);
	float smile = (1.0 - smoothstep(0.005,0.012,smile_radius))*step(p.y,-0.205);
	base = mix(base,vec3(0.31,0.20,0.17),smile*front*0.85);
	ALBEDO = base;
	ROUGHNESS = 0.96;
	SPECULAR = 0.22;
}
