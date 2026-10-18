shader_type spatial;
render_mode specular_schlick_ggx;

uniform vec4 skin : source_color = vec4(0.9, 0.7, 0.5, 1.0);
uniform bool animal = false;
uniform bool masked = false;
uniform float phase = 0.0;
varying vec3 head_position;

float oval(vec2 p, vec2 center, vec2 radii) {
	return 1.0 - smoothstep(0.88, 1.0, length((p-center)/radii));
}

void vertex() { head_position = VERTEX; }

void fragment() {
	vec3 color = skin.rgb;
	vec2 p = head_position.xy;
	float front = smoothstep(0.18, 0.28, head_position.z);
	float blink = pow(max(0.0, cos(TIME*1.5+phase)), 48.0);
	float eye_height = mix(0.047, 0.006, blink);
	float mask = oval(p, vec2(0.0, 0.055), vec2(0.30, 0.105));
	if (masked) { color = mix(color, vec3(0.13, 0.18, 0.22), mask*front); }
	float muzzle = oval(p, vec2(0.0, -0.105), vec2(0.17, 0.105));
	if (animal) { color = mix(color, mix(skin.rgb, vec3(1.0, 0.94, 0.82), 0.72), muzzle*front); }
	float eyes = max(oval(p, vec2(-0.145, 0.055), vec2(0.034, eye_height)), oval(p, vec2(0.145, 0.055), vec2(0.034, eye_height)));
	color = mix(color, vec3(0.09, 0.13, 0.16), eyes*front);
	float glint = max(oval(p, vec2(-0.155, 0.068), vec2(0.010)), oval(p, vec2(0.135, 0.068), vec2(0.010)))*(1.0-blink);
	color = mix(color, vec3(1.0, 0.98, 0.93), glint*front);
	float nose = oval(p, vec2(0.0, -0.055), vec2(0.033, 0.023));
	color = mix(color, animal ? vec3(0.35, 0.22, 0.22) : mix(skin.rgb, vec3(0.72, 0.32, 0.30), 0.5), nose*front);
	float smile = (1.0-smoothstep(0.006, 0.012, abs(length((p-vec2(0.0,-0.075))*vec2(1.0,1.4))-0.06)))*step(p.y,-0.09);
	color = mix(color, vec3(0.36, 0.23, 0.24), smile*front);
	ALBEDO=color;
	ROUGHNESS=0.9;
}
