extends CanvasLayer

# Important lessons and level rewards occupy >=75% of the full viewport.
# Dismissal is explicit; income, movement and danger pause while reading.
var g
var cover: ColorRect
var card: PanelContainer
var title: Label
var detail: Label
var kicker: Label
var emblem: TextureRect
var action_button: Button
var pending: Array[Dictionary]=[]
var current: Dictionary={}
var seen: Dictionary={}
var check_wait:=0.8
var pulse:=0.0

func _ready() -> void:
	layer=18
	cover=ColorRect.new();cover.color=Color(.06,.17,.24,.82);cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(cover);cover.visible=false
	card=g.hud.panel(Color("#fff0c9"));cover.add_child(card)
	card.anchor_left=.055;card.anchor_right=.945;card.anchor_top=.06;card.anchor_bottom=.94
	var box=g.hud.style(Color("#fff0c9"),36);box.border_color=Color("#eab34c");box.set_border_width_all(7);box.content_margin_left=32;box.content_margin_right=32;box.content_margin_top=32;box.content_margin_bottom=30;card.add_theme_stylebox_override("panel",box)
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",18);card.add_child(column)
	kicker=g.hud.label("NUEVA AVENTURA",20,Color("#b77b32"));kicker.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;column.add_child(kicker)
	emblem=TextureRect.new();emblem.custom_minimum_size=Vector2(0,190);emblem.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;emblem.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;column.add_child(emblem)
	title=g.hud.label("",38,Color("#24546a"));title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;column.add_child(title)
	detail=g.hud.label("",23,Color("#496878"));detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;detail.size_flags_vertical=Control.SIZE_EXPAND_FILL;detail.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;detail.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;column.add_child(detail)
	action_button=g.hud.button("¡VAMOS!",Color("#258f91"),25);action_button.custom_minimum_size.y=102;column.add_child(action_button);action_button.pressed.connect(dismiss)
func is_open() -> bool:return cover!=null and cover.visible
func announce(id: String,heading: String,message: String,symbol: String="star",action: String="",tag: String="NUEVA META") -> void:
	if seen.has(id) or current.get("id","")==id:return
	for item in pending:
		if item["id"]==id:return
	pending.append({"id":id,"title":heading,"detail":message,"symbol":symbol,"action":action,"tag":tag})
func dismiss() -> void:
	if not is_open():return
	seen[current["id"]]=true
	var action: String=current.get("action","")
	cover.visible=false;current={}
	g.input_stick._clear();g.boost_active=false;g.move_velocity=Vector3.ZERO
	if action=="level":g.run.advance()
	elif action=="route":g.route.open_board()
	elif action=="guide":g._follow_objective()
	g._save_progress()
func tick(delta: float) -> void:
	pulse+=delta
	if is_open():
		emblem.modulate=Color(1,1,1,.91+.09*sin(pulse*3))
		return
	check_wait-=delta
	if check_wait>0:return
	check_wait=.35
	if g.shop_panel.visible or g.town.in_build_mode or g.work.board_visible() or g.route.board_visible():return
	if not g.route.away() and g.run.complete():announce("complete:%d" % g.run.level,"¡Nivel %d superado!" % g.run.level,"%s\n\nRecompensa: %d monedas\n\nLa siguiente etapa trae una meta nueva." % [g.run.title(),g.run.reward()],"star","level","¡LO LOGRASTE!")
	elif not g.route.away():announce("chapter:%d" % g.run.level,g.run.title(),g.run.lesson(),"harvest","","NIVEL %02d · TU MISIÓN" % g.run.level)
	if g.run.level>=6 and not g.route.ferry:announce("route:discovery","¡Hay pueblos al otro lado!","Restaurá el barco para abrir Villa Miga. Trigo, granjas y nuevos edificios esperan en la ruta al Faro.","boat","route","UN OBJETIVO MÁS GRANDE")
	if g.route.away() and not g.route.project().is_empty():
		var p: Dictionary=g.route.project()
		announce("route:stage:%d" % g.route.stage,p["name"],p["why"]+"\n\n%d monedas\n%s" % [p["cost"],g.route.need_text(p["needs"])],"harvest","","PROYECTO %d / 15" % (g.route.stage+1))
	if not g.route.away() and g.run.level>=3 and (g.run.warning>0 or not g.run.threat().is_empty()):
		var wave: int=g.run.wave_index+(1 if g.run.warning>0 else 0)
		announce("raid:%d" % wave,"¡Mapaches en camino!","Protegé tus productos.\n\nBuscá al mapache, acercate con el joystick y tocá AHUYENTAR. Los cerrojos y el guardia te dan tiempo para reaccionar.","defense","","¡CUIDADO CON EL MERCADO!")
	elif not g.run.complete():
		var objective: Dictionary=g._current_objective()
		var action: String=objective.get("action","")
		var task_title: String=objective.get("title","")
		var id:=""
		if g.route.away() and action.begins_with("route:") and action!="route:project" and action!="route:board":id="task:route:%d:%s" % [g.route.stage,action]
		elif not g.route.away() and task_title in ["Recogé lo que ganaste","Llevá tu cosecha al puesto"]:id="task:home:%d:%s" % [g.run.level,task_title]
		if not id.is_empty():announce(id,task_title,objective.get("detail","")+"\n\nTocá SEÑALAR y seguí las flechas con el joystick.","deliver","","TU SIGUIENTE TAREA")
	if not g.route.away() and g._waiting_count()>=6:announce("queue:%d" % g.run.level,"¡La fila está llena!","Hay seis clientes esperando.\n\nReponé productos y mejorá la caja para atender más rápido. Las flechas te indican la tarea urgente.","crew","guide","¡EL MERCADO TE NECESITA!")
	if pending.is_empty():return
	current=pending.pop_front()
	title.text=current["title"];detail.text=current["detail"];kicker.text=current["tag"]
	emblem.texture=load("res://assets/ui/signs/"+current["symbol"]+".svg")
	action_button.text="SIGUIENTE NIVEL" if current["action"]=="level" else "VER LA RUTA" if current["action"]=="route" else "¡VAMOS!"
	cover.visible=true;g.input_stick._clear();g.boost_active=false;g.move_velocity=Vector3.ZERO
	g.player.act("celebrate" if current["symbol"]=="star" else "alert")
	card.pivot_offset=card.size*.5;card.scale=Vector2.ONE*.985
	create_tween().tween_property(card,"scale",Vector2.ONE,.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
func save_state() -> Array:return seen.keys()
func load_state(data: Variant) -> void:
	if data is Array:
		for id in data.slice(0,1000):
			if id is String and id.length()<100:seen[id]=true
