extends Control

var g
var objective := {}
var top_margin := 330.0
var bottom_margin := 290.0

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE

func _process(_delta: float) -> void:
	queue_redraw()

func indicator() -> Dictionary:
	if g==null or not objective.has("target") or g.shop_panel.visible:return {}
	var target: Vector3=objective["target"]+Vector3(0,1.2,0)
	var projected: Vector2=g.camera.unproject_position(target)
	var bounds := Rect2(Vector2(58,top_margin),Vector2(maxf(1,size.x-116),maxf(90,size.y-top_margin-bottom_margin)))
	var center := bounds.get_center()
	var direction := projected-center
	var behind: bool=g.camera.is_position_behind(target)
	if behind:direction=-direction
	if bounds.has_point(projected) and not behind:return {}
	if direction.length()<1:direction=Vector2.UP
	var factor := minf((bounds.size.x*.5)/maxf(absf(direction.x),.001),(bounds.size.y*.5)/maxf(absf(direction.y),.001))
	return {"position":center+direction*factor,"angle":direction.angle(),"distance":g.player.position.distance_to(objective["target"])}

func _draw() -> void:
	var marker := indicator()
	if marker.is_empty():return
	var at: Vector2=marker["position"]
	var color := Color("#ffe298")
	draw_circle(at+Vector2(0,4),29,Color(.06,.20,.20,.20))
	draw_circle(at,29,Color("#245d59"))
	draw_arc(at,28,0,TAU,36,color,2,true)
	var direction := Vector2.from_angle(marker["angle"])
	var side := direction.orthogonal()
	draw_line(at-direction*11,at+direction*10,color,4,true)
	draw_polyline(PackedVector2Array([at+direction*2+side*8,at+direction*11,at+direction*2-side*8]),color,4,true)
	var font := ThemeDB.fallback_font
	var text_ := "%d m" % ceili(marker["distance"])
	var width := font.get_string_size(text_,HORIZONTAL_ALIGNMENT_LEFT,-1,16).x
	draw_string(font,at+Vector2(-width*.5,49),text_,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#24494b"))
