extends PanelContainer
class_name RabbitWarningBanner

# A live rigged 3D messenger in a transparent portrait viewport. The entire
# notification ignores input, leaving direct movement and defense available.
var portrait: TextureRect
var headline: Label
var detail: Label
var direction: Label
var lifetime:=0.0
var last_phase: String=""
var hiding:=false
var active_tween: Tween
var actor: Node3D
var animator: AnimationPlayer
var portrait_view: SubViewport
var face_rig: Skeleton3D
var relieved:=false
var slide_offset:=0.0
var phase_time:=0.0

func _ready() -> void:
	name="Mensajera del pueblo"
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	anchor_right=1
	offset_left=22;offset_right=-22;offset_top=284;offset_bottom=464
	var paper:=StyleBoxFlat.new()
	paper.bg_color=Color("#fff2cf");paper.border_color=Color("#cd8b57")
	paper.set_border_width_all(3);paper.border_width_bottom=7
	paper.set_corner_radius_all(27);paper.shadow_color=Color(.11,.23,.23,.25);paper.shadow_size=12;paper.shadow_offset=Vector2(0,6)
	paper.content_margin_left=6;paper.content_margin_right=17;paper.content_margin_top=8;paper.content_margin_bottom=8
	add_theme_stylebox_override("panel",paper)
	var row:=HBoxContainer.new();row.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_theme_constant_override("separation",7);add_child(row)
	portrait_view=SubViewport.new();portrait_view.size=Vector2i(240,280);portrait_view.transparent_bg=true;portrait_view.own_world_3d=true
	portrait_view.render_target_update_mode=SubViewport.UPDATE_DISABLED
	add_child(portrait_view)
	var env:=WorldEnvironment.new();var atmosphere:=Environment.new()
	atmosphere.background_mode=Environment.BG_COLOR;atmosphere.background_color=Color(0,0,0,0)
	atmosphere.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;atmosphere.ambient_light_color=Color("#fff2d8");atmosphere.ambient_light_energy=.65
	env.environment=atmosphere;portrait_view.add_child(env)
	var light:=DirectionalLight3D.new();light.rotation_degrees=Vector3(-32,-26,0);light.light_energy=.85;portrait_view.add_child(light)
	actor=load("res://assets/models/rabbit.glb").instantiate();portrait_view.add_child(actor)
	animator=_find_animator(actor)
	face_rig=_find_skeleton(actor)
	if animator!=null:
		animator.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
		animator.get_animation("alert").loop_mode=Animation.LOOP_LINEAR
		animator.get_animation("surprise").loop_mode=Animation.LOOP_LINEAR
	var camera:=Camera3D.new();portrait_view.add_child(camera)
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=2.85;camera.position=Vector3(.15,1.95,6.5);camera.look_at(Vector3(0,1.92,0));camera.current=true
	portrait=TextureRect.new();portrait.texture=portrait_view.get_texture()
	portrait.custom_minimum_size=Vector2(150,158);portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(portrait)
	var words:=VBoxContainer.new();words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;words.mouse_filter=Control.MOUSE_FILTER_IGNORE;words.add_theme_constant_override("separation",3);row.add_child(words)
	var tag:=Label.new();tag.text="MENSAJERA DE WIVORI";tag.add_theme_font_size_override("font_size",13);tag.add_theme_color_override("font_color",Color("#a77749"));words.add_child(tag)
	headline=Label.new();headline.add_theme_font_size_override("font_size",24);headline.add_theme_color_override("font_color",Color("#a65247"));headline.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;words.add_child(headline)
	detail=Label.new();detail.add_theme_font_size_override("font_size",16);detail.add_theme_color_override("font_color",Color("#426264"));detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;words.add_child(detail)
	direction=Label.new();direction.add_theme_font_size_override("font_size",14);direction.add_theme_color_override("font_color",Color("#aa7441"));words.add_child(direction)
	_ignore_input(self)
	visible=false;set_process(false)

func _ignore_input(node: Node) -> void:
	if node is Control:node.mouse_filter=Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():_ignore_input(child)

func _find_animator(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:return node
	for child in node.get_children():
		var found:=_find_animator(child)
		if found!=null:return found
	return null

func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:return node
	for child in node.get_children():
		var found:=_find_skeleton(child)
		if found!=null:return found
	return null

func sync_state(phase: String) -> void:
	if phase==last_phase:return
	last_phase=phase
	if phase.is_empty() and relieved:return
	relieved=false
	match phase:
		"warning":_announce("¡MAPACHES CERCA!","Prepará las defensas. ¡Ya vienen!","alert")
		"approach":_announce("¡NOS ESTÁN ROBANDO!","¡Corré a proteger la mercancía!","alert")
		"escape":_announce("¡SE LLEVAN LOS PRODUCTOS!","Acercate y tocá Ahuyentar.","surprise")
		"":
			if visible:lifetime=minf(lifetime,.65)

func point_to(target: Vector3, from: Vector3) -> void:
	if relieved:return
	var d:=target-from
	var horizontal: String="ESTE" if d.x>0 else "OESTE"
	var vertical: String="SUR" if d.z>0 else "NORTE"
	direction.text="HACIA EL "+(horizontal if absf(d.x)>absf(d.z)*1.4 else vertical if absf(d.z)>absf(d.x)*1.4 else vertical+" · "+horizontal)
	if actor!=null:actor.rotation.y=clampf(d.x*.025,-.25,.25)

func recovered(amount: int) -> void:
	relieved=true
	_announce("¡A SALVO!","Recuperaste %d productos. ¡Buen trabajo!" % amount if amount>0 else "¡El mercado está protegido!","relief")
	lifetime=2.8
	direction.text="GRACIAS POR AYUDAR"
	headline.add_theme_color_override("font_color",Color("#2a8775"))

func _announce(title: String, explanation: String, clip: String) -> void:
	headline.text=title;detail.text=explanation
	headline.add_theme_color_override("font_color",Color("#a65247"))
	lifetime=4.5;phase_time=0;hiding=false;visible=true;set_process(true)
	portrait_view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	if animator!=null:animator.play(clip,.15)
	if active_tween!=null:active_tween.kill()
	modulate.a=0;slide_offset=-760
	active_tween=create_tween().set_parallel(true)
	active_tween.tween_property(self,"modulate:a",1.0,.18)
	active_tween.tween_property(self,"slide_offset",0.0,.46).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _process(delta: float) -> void:
	lifetime-=delta;phase_time+=delta
	offset_left=22+slide_offset;offset_right=-22+slide_offset
	if animator!=null:animator.advance(delta)
	if face_rig!=null:
		# Bone-driven facial expressions: wide worried eyes, then a happy blink.
		var openness:=1.14+sin(phase_time*7)*.035 if not relieved else 1.0-absf(sin(phase_time*4.5))*.38
		for eye in ["eye.L","eye.R"]:
			var bone:=face_rig.find_bone(eye)
			if bone>=0:face_rig.set_bone_pose_scale(bone,Vector3(1.02,openness,1.0))
	if last_phase=="escape" and not relieved:actor.rotation.z=sin(phase_time*9)*.025
	else:actor.rotation.z=0
	if lifetime>0 or hiding:return
	hiding=true
	if active_tween!=null:active_tween.kill()
	active_tween=create_tween().set_parallel(true)
	active_tween.tween_property(self,"modulate:a",0.0,.25)
	active_tween.tween_property(self,"slide_offset",760.0,.30).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	active_tween.chain().tween_callback(_finish)

func _finish() -> void:
	visible=false;hiding=false;set_process(false)
	portrait_view.render_target_update_mode=SubViewport.UPDATE_DISABLED
