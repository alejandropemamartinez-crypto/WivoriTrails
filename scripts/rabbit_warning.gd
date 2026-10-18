extends PanelContainer
class_name RabbitWarningBanner

# Animated, character-led robbery alert. It is deliberately noninteractive:
# joystick and all touch actions remain available beneath the notice.
const INK:=Color("#3d534d")
var portrait: TextureRect
var headline: Label
var detail: Label
var lifetime:=0.0
var last_phase: String=""
var hiding:=false
var active_tween: Tween

func _ready() -> void:
	name="Conejita mensajera de emergencias"
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	anchor_left=0; anchor_right=1
	offset_left=18; offset_right=-18; offset_top=255; offset_bottom=425
	var background:=StyleBoxFlat.new()
	background.bg_color=Color("#fff1d3")
	background.border_color=Color("#da9365")
	background.set_border_width_all(4)
	background.set_corner_radius_all(26)
	background.shadow_color=Color(.20,.18,.12,.33)
	background.shadow_size=13; background.shadow_offset=Vector2(0,7)
	for side in ["left","right","top","bottom"]:
		background.set("content_margin_"+side,9.0)
	add_theme_stylebox_override("panel",background)
	var contents:=HBoxContainer.new()
	contents.mouse_filter=Control.MOUSE_FILTER_IGNORE
	contents.add_theme_constant_override("separation",5)
	add_child(contents)
	var frame:=Control.new()
	frame.custom_minimum_size=Vector2(146,144)
	frame.mouse_filter=Control.MOUSE_FILTER_IGNORE
	contents.add_child(frame)
	var glow:=ColorRect.new()
	glow.color=Color("#a7ddd0")
	glow.position=Vector2(13,15)
	glow.size=Vector2(122,113)
	glow.mouse_filter=Control.MOUSE_FILTER_IGNORE
	frame.add_child(glow)
	portrait=TextureRect.new()
	portrait.name="Conejita alarmada - retrato vectorial"
	portrait.texture=load("res://assets/ui/rabbit_warning.svg")
	portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.position=Vector2(-3,-19); portrait.size=Vector2(159,166)
	portrait.pivot_offset=portrait.size*.5
	portrait.mouse_filter=Control.MOUSE_FILTER_IGNORE
	frame.add_child(portrait)
	var stack:=VBoxContainer.new()
	stack.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	stack.mouse_filter=Control.MOUSE_FILTER_IGNORE
	stack.add_theme_constant_override("separation",5)
	contents.add_child(stack)
	var eyebrow:=Label.new()
	eyebrow.text="¡ALERTA DEL PUEBLO!"
	eyebrow.add_theme_font_size_override("font_size",15)
	eyebrow.add_theme_color_override("font_color",Color("#a05d41"))
	stack.add_child(eyebrow)
	headline=Label.new()
	headline.text="¡TE ESTÁN ROBANDO!"
	headline.add_theme_font_size_override("font_size",25)
	headline.add_theme_color_override("font_color",Color("#9b423c"))
	headline.add_theme_color_override("font_shadow_color",Color(1,1,1,.9))
	headline.add_theme_constant_override("shadow_offset_y",2)
	headline.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(headline)
	detail=Label.new()
	detail.text="¡Hay mapaches en el almacén!"
	detail.add_theme_font_size_override("font_size",16)
	detail.add_theme_color_override("font_color",INK)
	detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(detail)
	pivot_offset=Vector2(340,90)
	modulate.a=0.0
	visible=false
	set_process(false)

func sync_state(phase: String) -> void:
	if phase==last_phase:return
	last_phase=phase
	match phase:
		"warning":_announce("¡MAPACHES CERCA!","¡Scottie, prepará las defensas!")
		"approach":_announce("¡TE ESTÁN ROBANDO!","¡Corré, vienen por la mercancía!")
		"escape":_announce("¡SE LLEVAN TODO!","¡Interceptá al mapache y recuperalo!")
		"":if visible:lifetime=minf(lifetime,.65)

func _announce(title: String, explanation: String) -> void:
	headline.text=title
	detail.text=explanation
	lifetime=4.4
	hiding=false
	visible=true
	set_process(true)
	if active_tween!=null and active_tween.is_running():active_tween.kill()
	modulate.a=0
	scale=Vector2(.85,.85)
	rotation_degrees=-4.0
	portrait.rotation_degrees=-16.0
	active_tween=create_tween().set_parallel(true)
	active_tween.tween_property(self,"modulate:a",1.0,.24)
	active_tween.tween_property(self,"scale",Vector2.ONE,.48).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	active_tween.tween_property(self,"rotation_degrees",0.0,.43).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	active_tween.tween_property(portrait,"rotation_degrees",6.0,.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	active_tween.chain().tween_property(portrait,"rotation_degrees",0.0,.30)

func _process(delta: float) -> void:
	if not visible:return
	lifetime-=delta
	if lifetime>0:
		portrait.position.y=-19.0+sin(Time.get_ticks_msec()*.015)*3.5
		return
	if hiding:return
	hiding=true
	if active_tween!=null and active_tween.is_running():active_tween.kill()
	active_tween=create_tween().set_parallel(true)
	active_tween.tween_property(self,"modulate:a",0.0,.30)
	active_tween.tween_property(self,"scale",Vector2(.9,.9),.30)
	active_tween.chain().tween_callback(_finish)

func _finish() -> void:
	visible=false
	hiding=false
	set_process(false)
