extends Control

var heading:=0.0
var distance:=0
var caption: Label
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE;size=Vector2(78,88)
	caption=Label.new();caption.mouse_filter=Control.MOUSE_FILTER_IGNORE;caption.position=Vector2(0,60);caption.size=Vector2(78,26);caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_font_override("font",preload("res://assets/fonts/Quicksand-Bold.ttf"));caption.add_theme_font_size_override("font_size",18)
	caption.add_theme_color_override("font_color",Color("#213d51"));caption.add_theme_color_override("font_outline_color",Color("#fff4d4"));caption.add_theme_constant_override("outline_size",5);add_child(caption)
func _draw() -> void:
	draw_circle(Vector2(39,30),29,Color("#274c5c"));draw_arc(Vector2(39,30),27,0,TAU,32,Color("#f2c478"),3,true)
	draw_set_transform(Vector2(39,30),heading)
	draw_colored_polygon(PackedVector2Array([Vector2(0,-17),Vector2(16,2),Vector2(6,0),Vector2(6,15),Vector2(-6,15),Vector2(-6,0),Vector2(-16,2)]),Color("#ffd386"))
func update_target(point: Vector2,origin: Vector2,screen: Vector2,metres: float) -> void:
	var bounds:=Rect2(Vector2(48,300),Vector2(screen.x-96,maxf(100,screen.y-960)))
	visible=not bounds.has_point(point) and metres>2.5
	position=Vector2(clampf(point.x,bounds.position.x,bounds.end.x),clampf(point.y,bounds.position.y,bounds.end.y))-Vector2(39,30)
	heading=(point-origin).angle()+PI*.5;distance=ceili(metres);caption.text="%d m" % distance;queue_redraw()
