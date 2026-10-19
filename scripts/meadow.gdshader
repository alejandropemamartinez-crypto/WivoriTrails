shader_type spatial;
render_mode cull_disabled;
varying vec3 tint;
void vertex(){
	vec3 at=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
	VERTEX.x+=sin(TIME*1.6+at.x*.5+at.z)*VERTEX.y*.13;
	tint=COLOR.rgb;
}
void fragment(){ALBEDO=tint;ROUGHNESS=.95;}
