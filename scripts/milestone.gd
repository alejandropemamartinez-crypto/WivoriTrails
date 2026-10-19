extends CanvasLayer

# News is read only when the player opens it from the map.
# Routine goals, upgrades, queues and raids never open blocking screens.
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
	# Only a few map milestones are queued; bound old/future callers safely.
	if pending.size()>24:pending.pop_front()
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
	if is_open():emblem.modulate=Color(1,1,1,.91+.09*sin(pulse*3))
	# No automatic popups. The mission panel always carries the next action;
	# level rewards are claimed through its CONTINUAR button.

func show_next() -> void:
	if is_open() or pending.is_empty() or g.route.sailing>0:return
	g.route.close_board();g.work.close_board();g.shop_panel.visible=false
	if g.town.in_build_mode:g.town.toggle_mode()
	current=pending.pop_front()
	title.text=current["title"];detail.text=current["detail"];kicker.text=current["tag"]
	var emblem_path:String="res://assets/ui/signs/"+str(current["symbol"])+".svg"
	if not ResourceLoader.exists(emblem_path):
		push_warning("Wivori Trails: pictograma de capítulo no disponible: "+emblem_path)
		emblem_path="res://assets/ui/signs/star.svg"
	emblem.texture=load(emblem_path)
	action_button.text="SIGUIENTE NIVEL" if current["action"]=="level" else "VER LA RUTA" if current["action"]=="route" else "¡VAMOS!"
	cover.visible=true;g.input_stick._clear();g.boost_active=false;g.move_velocity=Vector3.ZERO
	g.player.act("celebrate" if current["symbol"]=="star" else "alert")
	card.pivot_offset=card.size*.5;card.scale=Vector2.ONE*.985
	create_tween().tween_property(card,"scale",Vector2.ONE,.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
func save_state() -> Array:
	# Read history persists; unread cards are optional session news.
	# Gameplay progress is owned by the campaign, never by opening a card.
	return seen.keys()
func load_state(data: Variant) -> void:
	if data is Array:
		for id in data.slice(0,1000):
			if id is String and id.length()<100:seen[id]=true
