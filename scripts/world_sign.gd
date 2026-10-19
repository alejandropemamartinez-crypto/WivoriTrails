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
	pictogram=Sprite3D.new();pictogram.texture=load("res://assets/ui/signs/"+symbol+".svg");pictogram.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	pictogram.shaded=false;pictogram.no_depth_test=true;pictogram.render_priority=3;pictogram.position.z=.02;add_child(pictogram)
	_update_plate()
func _process(delta: float) -> void:
	wait-=delta
	if wait>0:return
	wait=.2
	if old_text!=text or not is_equal_approx(old_pixel,pixel_size) or old_font!=font_size:_update_plate()
func _update_plate() -> void:
	old_text=text;old_pixel=pixel_size;old_font=font_size
	if plate==null:return
	plate.visible=not text.is_empty();pictogram.visible=plate.visible
	var width:=maxf(2.8,font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x*pixel_size+1.3)
	plate.pixel_size=width/512.0
	plate.scale.y=maxf(1.0,.95/(160*plate.pixel_size))
	pictogram.pixel_size=.0072
	pictogram.position.x=-width*.5+.50
	# The text remains centred in the area to the right of the pictogram.
	offset.x=42
