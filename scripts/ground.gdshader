shader_type spatial;
varying vec3 world_at;
uniform bool cobbled=false;
uniform vec3 base_color : source_color=vec3(.41,.59,.37);
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float soft_noise(vec2 p){
	vec2 cell=floor(p);vec2 f=fract(p);f=f*f*(3.0-2.0*f);
	return mix(mix(hash(cell),hash(cell+vec2(1,0)),f.x),mix(hash(cell+vec2(0,1)),hash(cell+vec2(1,1)),f.x),f.y);
}
void vertex(){world_at=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
	vec2 at=world_at.xz;
	float broad=soft_noise(at*.24);
	float fine=soft_noise(at*22.0);
	vec3 color=base_color*(.94+.07*broad+.025*fine);
	if(cobbled){
		vec2 grid=at*vec2(2.4,2.1);
		grid.x+=mod(floor(grid.y),2.0)*.5;
		vec2 cell=fract(grid);
		vec2 edge=min(cell,1.0-cell);
		float rim=smoothstep(.015,.065,min(edge.x,edge.y));
		float tone=hash(floor(grid));
		color=base_color*(.89+.17*tone);
		color=mix(color*.72,color,rim);
	}
	ALBEDO=color;
	ROUGHNESS=.94;
}
