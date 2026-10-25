shader_type spatial;
uniform float warm_radius=7.0;
uniform float warmth=1.0;
uniform vec3 snow_tint : source_color=vec3(.72,.83,.89);
varying vec3 world_at;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p);vec2 f=fract(p);f=f*f*(3.-2.*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
void vertex(){world_at=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;}
void fragment(){
	vec2 p=world_at.xz;
	float broad=noise(p*.30);
	float grains=noise(p*12.0);
	vec3 snow=snow_tint*(.94+.08*broad+.015*grains);
	float radius=length(p);
	float melted=(1.-smoothstep(warm_radius-1.5,warm_radius+1.5+broad*1.8,radius))*warmth;
	vec3 earth=mix(vec3(.38,.40,.40),vec3(.53,.47,.37),broad);
	float paths=1.-smoothstep(.65,1.15,min(abs(p.x),abs(p.y)));
	paths=max(paths,(1.-smoothstep(.55,1.1,abs(radius-6.7)))*.75);
	vec2 stones=fract(p*1.5);
	float edge=smoothstep(.04,.11,min(min(stones.x,1.-stones.x),min(stones.y,1.-stones.y)));
	vec3 path=mix(vec3(.37,.41,.42),vec3(.58,.59,.55),edge);
	vec3 color=mix(snow,earth,melted*.92);
	color=mix(color,path,paths*melted*.8);
	// Shovelled market lanes connect depot, queues and the two sales counters.
	float lane=(1.-smoothstep(.65,1.1,abs(p.y-20.3)))*(1.-smoothstep(17.5,19.,abs(p.x)));
	float queue_lane=(1.-smoothstep(.45,.85,min(abs(p.x+6.),abs(p.x-2.5))))*smoothstep(18.5,20.,p.y)*(1.-smoothstep(28.,29.,p.y));
	color=mix(color,mix(snow,vec3(.52,.64,.65),.48),max(lane,queue_lane)*.75);
	color+=vec3(.065,.026,0.)*melted*(1.-smoothstep(0.,5.0,radius));
	ALBEDO=color;ROUGHNESS=.95;
}
