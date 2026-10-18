shader_type spatial;
render_mode diffuse_burley;
uniform sampler2D atlas : source_color, filter_linear_mipmap;
uniform vec3 original_dye : source_color=vec3(.19,.55,.53);
uniform vec3 new_dye : source_color=vec3(.70,.62,.30);
void fragment(){
	vec3 painted=texture(atlas,UV).rgb;
	float high=max(painted.r,max(painted.g,painted.b));
	float low=min(painted.r,min(painted.g,painted.b));
	float saturation=(high-low)/max(high,.001);
	float similarity=dot(normalize(painted+vec3(.0001)),normalize(original_dye));
	float cloth=smoothstep(.982,.997,similarity)*smoothstep(.28,.45,saturation);
	vec3 dyed=painted*new_dye/max(original_dye,vec3(.02));
	ALBEDO=mix(painted,dyed,cloth);
	ROUGHNESS=.87;
}
