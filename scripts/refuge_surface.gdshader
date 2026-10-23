shader_type spatial;
render_mode diffuse_burley;
uniform bool metal=false;
varying vec3 local_at;
varying vec3 paint;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p);vec2 f=fract(p);f=f*f*(3.-2.*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
void vertex(){local_at=VERTEX;paint=COLOR.rgb;}
void fragment(){
	// COLOR already arrives in linear light. A second gamma conversion
	// would crush the timber and fir trees to black.
	vec3 base=paint;
	float variation=.96+.07*noise(UV*3.7);
	bool timber=paint.r>paint.b*1.15 && paint.b<.65;
	if(timber){
		float grain=noise(vec2(UV.x*2.1,UV.y*39.0));
		variation*=.94+.09*grain;
	}
	ALBEDO=base*variation;
	ROUGHNESS=metal ? .47 : .91;
	METALLIC=metal ? .24 : 0.0;
	SPECULAR=.22;
	AO=.76+.24*smoothstep(.12,1.25,local_at.y);
}
