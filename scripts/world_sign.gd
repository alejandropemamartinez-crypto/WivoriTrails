extends Label3D

const PLAQUE=preload("res://assets/ui/signs/plaque.svg")
var plate: Sprite3D
var pictogram: Sprite3D
var old_text:="?"
var old_pixel:=0.0
var old_font:=0
var wait:=0.0
var symbol:="deliver"

func _ready() -> void:
	font=preload("res://assets/fonts/Quicksand-Bold.ttf")
	modulate=Color("#214960");outline_size=0
	billboard=BaseMaterial3D.BILLBOARD_ENABLED
	shaded=false;no_depth_test=true;render_priority=4
	plate=Sprite3D.new();plate.texture=PLAQUE;plate.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	plate.shaded=false;plate.no_depth_test=true;plate.render_priority=1;plate.position=Vector3(0,0,-.035);add_child(plate)
	var symbol_path:String="res://assets/ui/signs/"+symbol+".svg"
	if not ResourceLoader.exists(symbol_path):
		push_error("Wivori Trails: falta pictograma 3D de señal "+symbol_path)
		symbol_path="res://assets/ui/signs/deliver.svg"
	pictogram=Sprite3D.new();pictogram.texture=load(symbol_path);pictogram.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	pictogram.shaded=false;pictogram.no_depth_test=true;pictogram.render_priority=3;pictogram.position.z=.02;add_child(pictogram)
	_update_plate()
	if text=="WIVORI":hide()

func _fit_distance() -> void:
	var camera:=get_viewport().get_camera_3d()
	if camera==null:return
	# Perspective used to turn foreground plaques into enormous billboards.
	# Cap their apparent size while keeping the world anchor above its target.
	var distance: float=camera.global_position.distance_to(global_position)
	var long_name: float=minf(1.0,14.0/maxf(14.0,float(text.length())))
	var perspective_scale: float=clampf(distance/18.0,.22,1.0) if camera.projection==Camera3D.PROJECTION_PERSPECTIVE else .88
	scale=Vector3.ONE*perspective_scale*long_name
	_fit_distance_visibility(camera)

func _fit_distance_visibility(camera: Camera3D) -> void:
	# The player can read the closest signs; distant roofs remain visible.
	var player: Node3D=get_tree().get_first_node_in_group("wivori_player") as Node3D
	var from: Vector3=player.global_position if player!=null else camera.global_position-Vector3(0,12.8,15.1)
	var planar: float=Vector2(global_position.x-from.x,global_position.z-from.z).length()
	var crop: bool=text.to_upper() in ["TOMATES","ZANAHORIAS","ARANDANOS","ARÁNDANOS"]
	modulate.a=1.0 if text!="WIVORI" and planar<=(8.0 if crop or text=="ENTREGAR" else 10.0) else 0.0
	if player!=null:
		var sign_at:=camera.unproject_position(global_position)
		var player_at:=camera.unproject_position(player.global_position+Vector3.UP*1.1)
		if absf(sign_at.x-player_at.x)<100 and absf(sign_at.y-player_at.y)<65:modulate.a=0.0
	if modulate.a<.2:modulate.a=0.0
	if plate!=null:plate.modulate.a=modulate.a
	if pictogram!=null:pictogram.modulate.a=modulate.a
	outline_modulate.a=modulate.a
func _process(delta: float) -> void:
	wait-=delta
	if wait>0:return
	wait=.2
	if old_text!=text or not is_equal_approx(old_pixel,pixel_size) or old_font!=font_size:_update_plate()
	_fit_distance()
func _update_plate() -> void:
	old_text=text;old_pixel=pixel_size;old_font=font_size
	if plate==null:return
	plate.visible=not text.is_empty();pictogram.visible=plate.visible
	var line_width:=0.0
	var lines: PackedStringArray=text.split("\n")
	for line in lines:line_width=maxf(line_width,font.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x*pixel_size)
	var width:=maxf(2.0,line_width+1.05)
	plate.pixel_size=width/512.0
	var required_height: float=maxf(.72,float(lines.size())*float(font_size)*pixel_size*1.16+.22)
	plate.scale.y=maxf(1.0,required_height/(160*plate.pixel_size))
	pictogram.pixel_size=.0072
	pictogram.position.x=-width*.5+.50
	# The text remains centred in the area to the right of the pictogram.
	offset.x=42
