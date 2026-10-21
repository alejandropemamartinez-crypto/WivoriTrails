shader_type spatial;
varying vec3 world_at;
uniform bool cobbled=false;
uniform vec3 base_color : source_color=vec3(.41,.59,.37);
uniform sampler2D stone_atlas : source_color, filter_linear_mipmap, repeat_disable;
uniform bool painted=false;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float soft_noise(vec2 p){
	vec2 cell=floor(p);vec2 f=fract(p);f=f*f*(3.0-2.0*f);
	return mix(mix(hash(cell),hash(cell+vec2(1,0)),f.x),mix(hash(cell+vec2(0,1)),hash(cell+vec2(1,1)),f.x),f.y);
}
void vertex(){world_at=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
	vec2 at=world_at.xz;
	float broad=soft_noise(at*.24);
	float fine=soft_noise(at*12.0);
	vec3 color=base_color*(.88+.17*broad+.018*fine);
	// Broad painted patches, not a uniform green carpet or noisy checkerboard.
	color=mix(color,color*vec3(.93,1.015,.91),soft_noise(at*.70)*.20);
	if(cobbled){
		vec2 grid=mat2(vec2(.992,-.126),vec2(.126,.992))*at*vec2(1.42,1.17);
		grid.x+=mod(floor(grid.y),2.0)*.48+hash(vec2(floor(grid.y),0.0))*.22;
		vec2 cell=fract(grid);
		vec2 corner=max(abs(cell-.5)-vec2(.37,.36),vec2(0.0));
		float rim=1.0-smoothstep(.09,.13,length(corner));
		float tone=hash(floor(grid));
		color=base_color*(.91+.13*tone)+vec3(.018,.010,-.008)*tone;
		color=mix(base_color*vec3(.76,.73,.67),color,rim);
		color+=smoothstep(.08,.14,cell.y)*(1.0-smoothstep(.14,.19,cell.y))*.023*rim;
		if(painted){
			vec3 stone=texture(stone_atlas,(vec2(0.0,1.0)+fract(at*.36)*.994+.003)/vec2(3.0,2.0)).rgb;
			color*=mix(.90,1.06,clamp(dot(stone,vec3(.30,.50,.20))*1.5,0.0,1.0));
		}
	}
	ALBEDO=color;
	ROUGHNESS=.94;
}
