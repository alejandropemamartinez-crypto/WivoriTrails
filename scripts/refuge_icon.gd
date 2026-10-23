extends Control

var kind:="wood"
var tint:=Color("#eab96d")

func _ready() -> void:mouse_filter=Control.MOUSE_FILTER_IGNORE
func _draw() -> void:
	var factor: float=minf(size.x,size.y)/40.0
	draw_set_transform((size-Vector2.ONE*40.0*factor)*.5,0,Vector2.ONE*factor)
	match kind:
		"wood":
			draw_style_box(_box(Color("#a76d42")),Rect2(7,11,23,20))
			draw_circle(Vector2(29,21),10,Color("#dfaf70"));draw_arc(Vector2(29,21),6,0,TAU,18,Color("#946340"),2,true)
			draw_line(Vector2(8,15),Vector2(22,15),Color("#764d37"),2,true);draw_line(Vector2(8,25),Vector2(22,25),Color("#764d37"),2,true)
		"food":
			draw_circle(Vector2(20,22),14,Color("#748d55"));draw_circle(Vector2(20,21),11,Color("#b2bd73"))
			draw_colored_polygon(PackedVector2Array([Vector2(10,20),Vector2(30,20),Vector2(26,33),Vector2(15,33)]),Color("#e9cfa5"))
			for at in [Vector2(14,19),Vector2(21,16),Vector2(27,20)]:draw_circle(at,5,Color("#da8b5b"))
			draw_line(Vector2(17,10),Vector2(22,15),Color("#d6e0aa"),2,true)
		"coal":
			for at in [Vector2(13,25),Vector2(27,26),Vector2(21,14)]:
				draw_colored_polygon(PackedVector2Array([at+Vector2(-9,6),at+Vector2(-8,-5),at+Vector2(0,-9),at+Vector2(9,-3),at+Vector2(7,7)]),Color("#576e81"))
				draw_line(at+Vector2(-5,-3),at+Vector2(1,-5),Color("#9aafbf"),2,true)
		"iron":
			for at in [Vector2(7,20),Vector2(21,20),Vector2(14,9)]:
				draw_colored_polygon(PackedVector2Array([at+Vector2(0,10),at+Vector2(4,0),at+Vector2(13,0),at+Vector2(17,10)]),Color("#b4c8d1"))
				draw_line(at+Vector2(4,2),at+Vector2(12,2),Color("#eef4f5"),2,true)
		"core":
			draw_colored_polygon(PackedVector2Array([Vector2(20,2),Vector2(32,19),Vector2(30,32),Vector2(21,38),Vector2(9,33),Vector2(6,24),Vector2(12,13),Vector2(14,24),Vector2(20,19)]),Color("#e5944f"))
			draw_colored_polygon(PackedVector2Array([Vector2(21,16),Vector2(27,26),Vector2(25,33),Vector2(18,34),Vector2(14,28)]),Color("#ffda8b"))
		"people":
			draw_circle(Vector2(20,12),7,tint);draw_arc(Vector2(20,33),12,PI,TAU,16,tint,6,true)
			draw_circle(Vector2(6,17),4,tint.darkened(.15));draw_circle(Vector2(34,17),4,tint.darkened(.15))
		"route":
			draw_arc(Vector2(20,20),15,0,TAU,28,tint,2,true)
			draw_colored_polygon(PackedVector2Array([Vector2(29,8),Vector2(23,23),Vector2(9,32),Vector2(16,17)]),tint)
			draw_circle(Vector2(20,20),3,Color("#294352"))
		"shield":
			draw_colored_polygon(PackedVector2Array([Vector2(5,7),Vector2(20,3),Vector2(35,7),Vector2(32,26),Vector2(20,37),Vector2(8,26)]),tint)
			draw_line(Vector2(13,20),Vector2(18,25),Color("#294352"),3,true);draw_line(Vector2(18,25),Vector2(28,13),Color("#294352"),3,true)
		_:
			draw_colored_polygon(PackedVector2Array([Vector2(3,19),Vector2(20,4),Vector2(37,19)]),tint)
			draw_style_box(_box(tint),Rect2(8,18,24,18));draw_rect(Rect2(17,25,7,11),Color("#294352"))
func _box(color_: Color) -> StyleBoxFlat:
	var box:=StyleBoxFlat.new();box.bg_color=color_;box.set_corner_radius_all(3);return box
