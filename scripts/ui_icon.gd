extends Control

var kind := "coin"
var tint := Color("#24494b")

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var center := size*.5
	var radius := minf(size.x,size.y)*.35
	var width := maxf(2.0,radius*.14)
	match kind:
		"coin":
			draw_circle(center,radius,Color("#f1b84d"))
			draw_arc(center,radius*.72,0,TAU,32,Color("#fff4c8"),width,true)
			draw_line(center+Vector2(0,-radius*.4),center+Vector2(0,radius*.4),Color("#997129"),width,true)
		"bag":
			var box := Rect2(center-Vector2(radius*.8,radius*.6),Vector2(radius*1.6,radius*1.4))
			draw_style_box(_box_style(tint),box)
			draw_arc(center-Vector2(0,radius*.5),radius*.4,PI,TAU,16,tint,width,true)
			draw_line(center-Vector2(radius*.4,0),center+Vector2(radius*.4,0),Color("#fff8e9"),width,true)
		"arrow":
			draw_line(center-Vector2(radius,0),center+Vector2(radius,0),tint,width,true)
			draw_polyline(PackedVector2Array([center+Vector2(0,-radius),center+Vector2(radius,0),center+Vector2(0,radius)]),tint,width,true)
		"helper":
			draw_circle(center-Vector2(0,radius*.55),radius*.43,tint)
			draw_arc(center+Vector2(0,radius*.75),radius*.77,PI,TAU,24,tint,width*2,true)
		"speed":
			draw_colored_polygon(PackedVector2Array([center+Vector2(radius*.2,-radius),center+Vector2(-radius*.7,radius*.1),center+Vector2(0,radius*.1),center+Vector2(-radius*.2,radius),center+Vector2(radius*.7,-radius*.1),center+Vector2(0,-radius*.1)]),tint)
		"shop":
			draw_rect(Rect2(center-Vector2(radius*.8,radius*.3),Vector2(radius*1.6,radius*1.2)),tint,false,width)
			draw_colored_polygon(PackedVector2Array([center+Vector2(-radius,-radius*.25),center+Vector2(-radius*.7,-radius*.9),center+Vector2(radius*.7,-radius*.9),center+Vector2(radius,-radius*.25)]),tint)
			draw_line(center+Vector2(0,radius*.9),center+Vector2(0,radius*.1),tint,width,true)
		"expand":
			draw_rect(Rect2(center-Vector2.ONE*radius,Vector2.ONE*radius*2),tint,false,width)
			draw_line(center-Vector2(radius*.55,0),center+Vector2(radius*.55,0),tint,width,true)
			draw_line(center-Vector2(0,radius*.55),center+Vector2(0,radius*.55),tint,width,true)
		"pier":
			draw_colored_polygon(PackedVector2Array([center+Vector2(-radius,-radius*.1),center+Vector2(radius,-radius*.1),center+Vector2(radius*.5,radius*.65),center+Vector2(-radius*.5,radius*.65)]),tint)
			draw_line(center-Vector2(0,radius),center+Vector2(0,-radius*.15),tint,width,true)
			draw_arc(center+Vector2(0,radius*.9),radius*.8,0,PI,16,tint,width,true)
		"view":
			draw_arc(center,radius,0,TAU,32,tint,width,true)
			draw_line(center-Vector2(radius*.45,0),center+Vector2(radius*.45,0),tint,width,true)
			draw_line(center-Vector2(0,radius*.45),center+Vector2(0,radius*.45),tint,width,true)

func _box_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color=color
	style.set_corner_radius_all(4)
	return style
