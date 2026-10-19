shader_type spatial;
render_mode specular_schlick_ggx;
varying vec2 world_xz;
uniform bool island=false;
void vertex(){ world_xz=(MODEL_MATRIX*vec4(VERTEX,1.0)).xz; }
void fragment(){
	vec2 p=world_xz;
	float waves=sin(p.x*1.6+p.y*.7+TIME*.85)*sin(p.y*2.1-p.x*.4-TIME*.65);
	float shore=length((p-vec2(0.0,-2.0))/vec2(31.0,30.0));
	float shallow=island ? 1.0-smoothstep(1.0,1.20,shore) : .35;
	vec3 deep=vec3(.13,.49,.62);vec3 lagoon=vec3(.30,.72,.73);
	vec3 water=mix(deep,lagoon,shallow)+waves*.016;
	float foam=island ? (1.0-smoothstep(.005,.018,abs(shore-1.025-sin(TIME*.8)*.006))) : 0.0;
	float glint=smoothstep(.92,.985,waves)*.18;
	ALBEDO=mix(water,vec3(.80,.96,.88),foam*.65)+glint;
	ROUGHNESS=.32;METALLIC=.08;
	NORMAL=normalize(NORMAL+vec3(waves*.025,0.0,cos(p.x+TIME)*.025));
}
