shader_type spatial;
render_mode diffuse_burley;
uniform sampler2D atlas : source_color, filter_linear_mipmap, repeat_disable;
uniform float cut_height=100.0;
varying vec3 local_at;
varying vec3 paint;
void vertex(){local_at=VERTEX;paint=COLOR.rgb;}
void fragment(){
	if(local_at.y>cut_height)discard;
	int finish=int(UV2.x+.5);
	vec3 col=paint;
	vec2 tile=vec2(1.0,0.0);
	float normalization=1.5;
	float strength=.19;
	if(finish==1){
		tile=vec2(0.0,0.0);normalization=4.0;strength=.46;
	}else if(finish==2){
		tile=vec2(2.0,0.0);normalization=5.4;strength=.24;
	}else if(finish==4){
		tile=vec2(1.0,1.0);normalization=8.0;strength=.68;
	}else if(finish==5){
		tile=vec2(2.0,1.0);normalization=10.0;strength=.33;
	}
	if(finish!=3){
		vec2 coord=finish==4 ? UV*.46 : UV*.63;
		vec3 sample_=texture(atlas,(tile+fract(coord)*.994+.003)/vec2(3.0,2.0)).rgb;
		float value=dot(sample_,vec3(.25,.55,.20));
		col*=mix(1.0,clamp(value*normalization,.55,1.20),strength);
		if(finish==4)col=mix(col,sample_*1.05,.74);
	}
	col*=.84+.16*smoothstep(.15,1.4,local_at.y);
	ALBEDO=col;
	ROUGHNESS=finish==3 ? .34 : .89;
	METALLIC=finish==3 ? .12 : 0.0;
	SPECULAR=.24;
}
