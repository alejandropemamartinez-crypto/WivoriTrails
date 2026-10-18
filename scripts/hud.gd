extends CanvasLayer

const IconScript=preload("res://scripts/ui_icon.gd")
const TouchButtonScript=preload("res://scripts/touch_button.gd")
const INK=Color("#24494b")
const MUTED=Color("#718783")
const PAPER=Color("#fffaf0")
const TEAL=Color("#238577")
const GOLD=Color("#efb34c")
var g
var root: Control
var scrim: ColorRect
var mission_detail: Label
var mission_progress: ProgressBar
var bag_progress: ProgressBar
var guide_button: Button
var next_label: Label
var team_label: Label
var shop_coins: Label
var run_button: Button
var shop_details := {}
var objective := {}
var level_label: Label
var level_progress: ProgressBar
var queue_label: Label
var alert_panel: PanelContainer
var alert_title: Label
var alert_detail: Label
var alert_button: Button
var pad_panel: PanelContainer
var pad_title: Label
var pad_detail: Label
var pad_button: Button
var wayfinder
var intercept_button: Button
var town_button: Button
var town_panel: PanelContainer
var town_description: Label
var town_choices: Dictionary={}
var mission_panel: PanelContainer
var status_row: HBoxContainer
var view_button: Button
var footer_panel: PanelContainer

func label(text_: String, size_: int, color_: Color=INK) -> Label:
	var node := Label.new()
	node.text=text_
	node.add_theme_font_size_override("font_size",size_)
	node.add_theme_color_override("font_color",color_)
	node.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return node

func style(color_: Color, radius_: int=22) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color=color_
	box.set_corner_radius_all(radius_)
	box.content_margin_left=20; box.content_margin_right=20
	box.content_margin_top=16; box.content_margin_bottom=16
	return box

func panel(color_: Color=PAPER) -> PanelContainer:
	var node := PanelContainer.new()
	var box := style(color_)
	box.shadow_color=Color(.08,.22,.21,.13)
	box.shadow_size=10; box.shadow_offset=Vector2(0,4)
	node.add_theme_stylebox_override("panel",box)
	return node

func icon(kind: String, tint: Color=INK, dimensions: Vector2=Vector2(42,42)) -> Control:
	var node=IconScript.new()
	node.kind=kind; node.tint=tint
	node.custom_minimum_size=dimensions
	return node

func button(text_: String, color_: Color=TEAL, font_size_: int=21) -> Button:
	var node := TouchButtonScript.new()
	node.text=text_
	node.add_theme_font_size_override("font_size",font_size_)
	node.add_theme_color_override("font_color",PAPER)
	node.add_theme_color_override("font_hover_color",PAPER)
	node.add_theme_color_override("font_pressed_color",PAPER)
	node.add_theme_color_override("font_disabled_color",Color("#7f9690"))
	node.add_theme_stylebox_override("normal",style(color_,18))
	node.add_theme_stylebox_override("hover",style(color_.lightened(.08),18))
	node.add_theme_stylebox_override("pressed",style(color_.darkened(.12),18))
	node.add_theme_stylebox_override("disabled",style(Color("#e3ebe4"),18))
	node.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
	node.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	return node

func progress(color_: Color=TEAL) -> ProgressBar:
	var node := ProgressBar.new()
	node.show_percentage=false
	node.custom_minimum_size=Vector2(0,7)
	var background := style(Color("#e0e9df"),4)
	var fill := style(color_,4)
	for box in [background,fill]:
		box.content_margin_left=0; box.content_margin_right=0
		box.content_margin_top=0; box.content_margin_bottom=0
	node.add_theme_stylebox_override("background",background)
	node.add_theme_stylebox_override("fill",fill)
	node.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return node

func position_top(node: Control, y: float, height: float, left: float=24, right: float=-24) -> void:
	node.anchor_right=1.0
	node.offset_left=left; node.offset_right=right
	node.offset_top=y; node.offset_bottom=y+height

func build(game: Node3D) -> void:
	g=game
	name="Interfaz móvil"
	root=Control.new(); root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var ui_theme := Theme.new()
	ui_theme.default_font=ThemeDB.fallback_font.duplicate()
	root.theme=ui_theme
	root.mouse_filter=Control.MOUSE_FILTER_IGNORE; add_child(root)

	var header := panel(); root.add_child(header); position_top(header,24,88)
	var row := HBoxContainer.new(); row.add_theme_constant_override("separation",10); header.add_child(row)
	row.add_child(icon("coin",INK,Vector2(48,48)))
	var money := VBoxContainer.new(); money.size_flags_horizontal=Control.SIZE_EXPAND_FILL; row.add_child(money)
	money.add_child(label("MONEDAS",13,MUTED))
	g.total_label=label("50",30); money.add_child(g.total_label)
	var level := VBoxContainer.new(); level.custom_minimum_size=Vector2(91,0); row.add_child(level)
	level.add_child(label("NIVEL",12,TEAL))
	level_label=label("01",23,TEAL); level.add_child(level_label)
	level_progress=progress(); level_progress.max_value=20; level.add_child(level_progress)
	row.add_child(icon("bag",TEAL,Vector2(37,48)))
	var bag := VBoxContainer.new(); bag.custom_minimum_size=Vector2(120,0); row.add_child(bag)
	g.backpack_label=label("0 / 12",23); bag.add_child(g.backpack_label)
	bag_progress=progress(GOLD); bag.add_child(bag_progress)

	var mission := panel(); root.add_child(mission); position_top(mission,123,113)
	mission_panel=mission
	var mission_row := HBoxContainer.new(); mission_row.add_theme_constant_override("separation",12); mission.add_child(mission_row)
	var mission_column := VBoxContainer.new(); mission_column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	mission_column.add_theme_constant_override("separation",3); mission_row.add_child(mission_column)
	next_label=label("TU PRIMER MERCADO",12,TEAL); mission_column.add_child(next_label)
	g.mission_label=label("Tu primera cosecha",23); mission_column.add_child(g.mission_label)
	g.mission_label.clip_text=true
	next_label.clip_text=true
	mission_detail=label("",17,MUTED); mission_detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	mission_detail.custom_minimum_size=Vector2(370,0); mission_column.add_child(mission_detail)
	mission_progress=progress(); mission_column.add_child(mission_progress)
	guide_button=button("GUIAR",TEAL,16); guide_button.custom_minimum_size=Vector2(122,70)
	guide_button.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	guide_button.pressed.connect(func():g._follow_objective()); mission_row.add_child(guide_button)

	var status := HBoxContainer.new(); root.add_child(status); position_top(status,248,36)
	status_row=status
	status.add_theme_constant_override("separation",12)
	var stock := panel(Color(.98,.97,.90,.90)); status.add_child(stock)
	var chip_style := style(Color(.98,.97,.90,.90),12)
	chip_style.content_margin_top=7; chip_style.content_margin_bottom=7
	stock.add_theme_stylebox_override("panel",chip_style)
	g.stock_label=label("Puesto  0",17); stock.add_child(g.stock_label)
	var team := panel(Color(.98,.97,.90,.90)); status.add_child(team)
	team.add_theme_stylebox_override("panel",chip_style)
	team_label=label("Equipo  0",17); team.add_child(team_label)
	var queue := panel(Color(.98,.97,.90,.90)); status.add_child(queue)
	queue.add_theme_stylebox_override("panel",chip_style)
	queue_label=label("Fila  0/6",17); queue.add_child(queue_label)
	var shipping := panel(Color(.12,.31,.31,.94)); root.add_child(shipping)
	position_top(shipping,300,50,24,-130)
	shipping.add_theme_stylebox_override("panel",style(Color(.12,.31,.31,.94),14))
	g.shipping_label=label("",16,PAPER); shipping.add_child(g.shipping_label); shipping.visible=false

	var view := button("VISTA",PAPER,14); root.add_child(view)
	view_button=view
	view.add_theme_color_override("font_color",INK); view.add_theme_color_override("font_hover_color",INK)
	view.anchor_left=1; view.anchor_right=1
	view.offset_left=-108; view.offset_right=-24; view.offset_top=248; view.offset_bottom=287
	view.pressed.connect(func():g._toggle_camera_view())
	view.tooltip_text="Acercar o alejar la cámara"

	g.input_stick=load("res://scripts/joystick.gd").new(); root.add_child(g.input_stick)
	g.input_stick.anchor_top=1; g.input_stick.anchor_bottom=1
	g.input_stick.offset_left=18; g.input_stick.offset_right=223
	g.input_stick.offset_top=-252; g.input_stick.offset_bottom=-37
	var run := button("CORRER",Color("#d79b41"),18); root.add_child(run)
	run_button=run
	run.anchor_left=1; run.anchor_right=1; run.anchor_top=1; run.anchor_bottom=1
	run.offset_left=-182; run.offset_right=-24; run.offset_top=-240; run.offset_bottom=-168
	run.button_down.connect(func():g.boost_active=true)
	run.button_up.connect(func():g.boost_active=false)
	g.shop_button=button("MEJORAS",TEAL,17); root.add_child(g.shop_button)
	g.shop_button.anchor_left=1; g.shop_button.anchor_right=1
	g.shop_button.anchor_top=1; g.shop_button.anchor_bottom=1
	g.shop_button.offset_left=-154; g.shop_button.offset_right=-24
	g.shop_button.offset_top=-152; g.shop_button.offset_bottom=-68
	g.shop_button.pressed.connect(func():g._toggle_shop())
	town_button=button("PUEBLO",Color("#537f69"),17); root.add_child(town_button)
	town_button.anchor_left=1; town_button.anchor_right=1; town_button.anchor_top=1; town_button.anchor_bottom=1
	town_button.offset_left=-286; town_button.offset_right=-163
	town_button.offset_top=-152; town_button.offset_bottom=-68
	town_button.pressed.connect(func():g._toggle_build_mode())

	intercept_button=button("AHUYENTAR",Color("#b55d50"),19); root.add_child(intercept_button)
	intercept_button.anchor_left=1; intercept_button.anchor_right=1; intercept_button.anchor_top=1; intercept_button.anchor_bottom=1
	intercept_button.offset_left=-286; intercept_button.offset_right=-24; intercept_button.offset_top=-330; intercept_button.offset_bottom=-254
	intercept_button.pressed.connect(func():g._intercept())
	intercept_button.visible=false

	var footer := panel(Color(.98,.97,.90,.92)); root.add_child(footer)
	footer_panel=footer
	footer.anchor_top=1; footer.anchor_bottom=1; footer.anchor_right=1
	footer.offset_left=242; footer.offset_right=-24; footer.offset_top=-55; footer.offset_bottom=-12
	var footer_style := style(Color(.98,.97,.90,.92),12)
	footer_style.content_margin_left=10; footer_style.content_margin_right=10
	footer_style.content_margin_top=4; footer_style.content_margin_bottom=4
	footer.add_theme_stylebox_override("panel",footer_style)
	g.hint_label=label("Vos movés al personaje con el joystick",14); g.hint_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	footer.add_child(g.hint_label)

	g.event_label=label("",23,PAPER); root.add_child(g.event_label)
	g.event_label.anchor_right=1; g.event_label.anchor_top=1; g.event_label.anchor_bottom=1
	g.event_label.offset_left=24; g.event_label.offset_right=-24
	g.event_label.offset_top=-337; g.event_label.offset_bottom=-273
	g.event_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	g.event_label.add_theme_stylebox_override("normal",style(Color(.10,.26,.26,.94),18))
	g.event_label.visible=false
	build_action_cards()
	build_town_controls()
	wayfinder=load("res://scripts/wayfinder.gd").new(); wayfinder.g=g
	root.add_child(wayfinder); wayfinder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	build_shop()
	_apply_safe_area()
	get_viewport().size_changed.connect(_apply_safe_area)

func build_action_cards() -> void:
	alert_panel=panel(Color("#fff1de")); root.add_child(alert_panel)
	position_top(alert_panel,336,88)
	var row := HBoxContainer.new(); row.add_theme_constant_override("separation",12); alert_panel.add_child(row)
	var column := VBoxContainer.new(); column.size_flags_horizontal=Control.SIZE_EXPAND_FILL; row.add_child(column)
	alert_title=label("",19,Color("#ab593d")); column.add_child(alert_title)
	alert_detail=label("",15,MUTED); alert_detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	alert_detail.custom_minimum_size=Vector2(350,0); column.add_child(alert_detail)
	alert_button=button("REPONER",Color("#b96a40"),15); alert_button.custom_minimum_size=Vector2(132,54)
	alert_button.size_flags_vertical=Control.SIZE_SHRINK_CENTER; row.add_child(alert_button)
	alert_button.pressed.connect(func():g._follow_alert())
	alert_panel.visible=false
	pad_panel=panel(Color("#fff5d9")); root.add_child(pad_panel)
	pad_panel.anchor_top=1; pad_panel.anchor_bottom=1; pad_panel.anchor_right=1
	pad_panel.offset_left=24; pad_panel.offset_right=-24; pad_panel.offset_top=-458; pad_panel.offset_bottom=-316
	var pad_row := HBoxContainer.new(); pad_row.add_theme_constant_override("separation",16); pad_panel.add_child(pad_row)
	var description := VBoxContainer.new(); description.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	description.add_theme_constant_override("separation",5); pad_row.add_child(description)
	description.add_child(label("ESTÁS EN UNA ZONA DE MEJORA",12,TEAL))
	pad_title=label("",23); pad_title.clip_text=true; description.add_child(pad_title)
	pad_detail=label("",17,MUTED); pad_detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	pad_detail.custom_minimum_size=Vector2(340,0); description.add_child(pad_detail)
	pad_button=button("COMPRAR",TEAL,18); pad_button.custom_minimum_size=Vector2(156,76)
	pad_button.size_flags_vertical=Control.SIZE_SHRINK_CENTER; pad_row.add_child(pad_button)
	pad_button.pressed.connect(func():g._purchase_nearby())
	pad_panel.visible=false

func build_town_controls() -> void:
	town_panel=panel(Color("#fff9ec"))
	root.add_child(town_panel)
	town_panel.anchor_left=0; town_panel.anchor_right=1
	town_panel.anchor_top=1; town_panel.anchor_bottom=1
	town_panel.offset_left=24; town_panel.offset_right=-24
	town_panel.offset_top=-500; town_panel.offset_bottom=-176
	var column:=VBoxContainer.new(); column.add_theme_constant_override("separation",9)
	town_panel.add_child(column)
	var title:=label("CONSTRUIR EL PUEBLO",24,INK); column.add_child(title)
	town_description=label("Elegí un solar tocándolo en el mapa",17,MUTED)
	town_description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	column.add_child(town_description)
	for kind in ["house","cafe","depot"]:
		var detail: Dictionary=g.town.TYPES[kind]
		var row:=HBoxContainer.new()
		row.add_theme_constant_override("separation",9); column.add_child(row)
		var about:=VBoxContainer.new(); about.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		row.add_child(about)
		about.add_child(label(detail["name"],17,INK))
		about.add_child(label(detail["benefit"],13,MUTED))
		var buy:=button("CONSTRUIR",TEAL,15)
		buy.custom_minimum_size=Vector2(158,60)
		row.add_child(buy)
		buy.pressed.connect(Callable(g,"_build_town").bind(kind))
		town_choices[kind]=buy
	town_panel.visible=false

func animate_income(amount: int, source: Vector2) -> void:
	if root==null:return
	var note:=label("+%d" % amount,26,Color("#e0a33b"))
	note.mouse_filter=Control.MOUSE_FILTER_IGNORE
	note.add_theme_color_override("font_shadow_color",Color(0.13,0.21,0.18,.36))
	note.add_theme_constant_override("shadow_offset_y",2)
	root.add_child(note)
	note.position=Vector2(clampf(source.x,30,600),clampf(source.y,280,1000))
	note.scale=Vector2.ONE*1.15
	var tween:=create_tween().set_parallel(true)
	tween.tween_property(note,"position",Vector2(110,62),.86).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(note,"scale",Vector2.ONE*.75,.86)
	tween.tween_property(note,"modulate:a",0.0,.86).set_delay(.04)
	tween.chain().tween_callback(note.queue_free)

func _apply_safe_area() -> void:
	if OS.get_name()!="Android":return
	var safe := DisplayServer.get_display_safe_area()
	var physical := DisplayServer.window_get_size()
	if safe.size.y<=0 or physical.y<=0:return
	var factor := get_viewport().get_visible_rect().size.y/float(physical.y)
	root.offset_top=maxf(0,safe.position.y)*factor
	root.offset_bottom=-maxf(0,physical.y-safe.end.y)*factor

func build_shop() -> void:
	scrim=ColorRect.new(); scrim.color=Color(.04,.14,.16,.58)
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); root.add_child(scrim)
	scrim.visible=false
	scrim.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
			g._toggle_shop(); scrim.accept_event()
		elif event is InputEventScreenTouch and event.pressed:
			g._toggle_shop(); scrim.accept_event())
	g.shop_panel=panel(); scrim.add_child(g.shop_panel)
	g.shop_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	g.shop_panel.offset_left=-326; g.shop_panel.offset_right=326
	g.shop_panel.offset_top=-455; g.shop_panel.offset_bottom=455
	g.shop_panel.visible=false
	var column := VBoxContainer.new(); g.shop_panel.add_child(column)
	column.add_theme_constant_override("separation",12)
	var heading := HBoxContainer.new(); column.add_child(heading)
	var title := label("Hacé crecer tu mercado",29); title.size_flags_horizontal=Control.SIZE_EXPAND_FILL; heading.add_child(title)
	var close := button("X",Color("#dbe7dc"),20); close.add_theme_color_override("font_color",INK)
	close.custom_minimum_size=Vector2(52,52); heading.add_child(close); close.pressed.connect(func():g._toggle_shop())
	shop_coins=label("",20,TEAL); column.add_child(shop_coins)
	column.add_child(label("Cada mejora cambia cómo trabajás.",17,MUTED))
	var scroll := ScrollContainer.new(); scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL; column.add_child(scroll)
	var upgrades := VBoxContainer.new(); upgrades.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	upgrades.add_theme_constant_override("separation",12); scroll.add_child(upgrades)
	var names := {}
	for kind in g.UPGRADE_POS:names[kind]=g._upgrade(kind)["name"]
	for key in ["helper","checkout","lock","alarm","guard","bag","speed","expand","pier"]:
		var card := panel(Color("#eef2e6")); upgrades.add_child(card)
		card.add_theme_stylebox_override("panel",style(Color("#eef2e6"),16))
		var row := HBoxContainer.new(); row.add_theme_constant_override("separation",14); card.add_child(row)
		row.add_child(icon(key,TEAL,Vector2(42,50)))
		var description := VBoxContainer.new(); description.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		row.add_child(description)
		description.add_child(label(names[key],20))
		var detail := label("",16,MUTED); detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		detail.custom_minimum_size=Vector2(270,0); description.add_child(detail); shop_details[key]=detail
		var buy := button("",TEAL,18); buy.custom_minimum_size=Vector2(132,64)
		buy.size_flags_vertical=Control.SIZE_SHRINK_CENTER; row.add_child(buy)
		buy.pressed.connect(Callable(g,"_buy").bind(key)); g.store_buttons[key]=buy
	var done := button("VOLVER AL MERCADO",TEAL,20); done.custom_minimum_size=Vector2(0,62)
	done.pressed.connect(func():g._toggle_shop()); column.add_child(done)

func refresh() -> void:
	var city_mode: bool=g.town!=null and g.town.in_build_mode
	mission_panel.visible=not city_mode
	status_row.visible=not city_mode
	view_button.visible=not city_mode
	footer_panel.visible=not city_mode
	g.input_stick.visible=not city_mode
	run_button.visible=not city_mode
	g.shop_button.visible=not city_mode
	town_panel.visible=city_mode
	town_button.text="VOLVER" if city_mode else "PUEBLO"
	if city_mode:
		town_description.text=g.town.selection_description()
		for kind in town_choices:
			var detail: Dictionary=g.town.TYPES[kind]
			var built: bool=g.town.has_building(kind)
			town_choices[kind].disabled=built or not g.town.constructed[g.town.selected].is_empty() or g.coins<detail["price"]
			town_choices[kind].text="LISTO" if built else "%d MON." % detail["price"]
	g.total_label.text=_number(g.coins)
	g.backpack_label.text="%d / %d" % [g._total_bag(),g.max_capacity]
	bag_progress.max_value=g.max_capacity; bag_progress.value=g._total_bag()
	g.stock_label.text="Puesto  %s" % _number(g._total_stock())
	team_label.text="Equipo  %d" % g.worker_count
	queue_label.text="Fila  %d/6" % g._waiting_count()
	queue_label.add_theme_color_override("font_color",Color("#af5845") if g._waiting_count()>=4 else INK)
	level_label.text="%02d" % g.run.level
	level_progress.max_value=1.0; level_progress.value=g.run.progress()
	objective=g._current_objective()
	next_label.text=objective["tag"]
	g.mission_label.text=objective["title"]
	mission_detail.text=objective["detail"]
	mission_progress.max_value=objective["goal"]; mission_progress.value=objective["value"]
	guide_button.text=objective["button"]
	guide_button.modulate=Color("#ffe3a2") if objective.get("ready",false) else Color.WHITE
	wayfinder.objective=objective
	var alert: Dictionary=g.director.alert()
	alert_panel.visible=not alert.is_empty() and not g.shop_panel.visible and not city_mode
	if not alert.is_empty():
		alert_title.text=alert["title"]; alert_detail.text=alert["detail"]; alert_button.text=alert["button"]
		alert_title.add_theme_color_override("font_color",alert["color"])
	pad_panel.visible=not g.active_pad.is_empty() and not g.shop_panel.visible and not city_mode
	if not g.active_pad.is_empty():
		var upgrade: Dictionary=g._upgrade(g.active_pad)
		pad_title.text=upgrade["name"]
		pad_detail.text=upgrade["benefit"]
		pad_button.text="COMPRAR\n%d monedas" % upgrade["price"]
		pad_button.disabled=g.coins<upgrade["price"] or upgrade["locked"]
		if pad_button.disabled:pad_detail.text+=" Te faltan %d monedas." % (upgrade["price"]-g.coins)
	var raiding: bool=not g.run.threat().is_empty()
	intercept_button.visible=raiding and not g.shop_panel.visible and not city_mode
	intercept_button.disabled=not g.run.can_intercept()
	intercept_button.text="AHUYENTAR" if not intercept_button.disabled else "ACERCATE AL MAPACHE"
	intercept_button.add_theme_font_size_override("font_size",19 if not intercept_button.disabled else 15)
	pad_panel.offset_top=-550 if raiding else -458
	pad_panel.offset_bottom=-408 if raiding else -316
	g.event_label.offset_top=(-634 if raiding else -542) if pad_panel.visible else (-420 if raiding else -337)
	g.event_label.offset_bottom=g.event_label.offset_top+72
	wayfinder.visible=not city_mode
	wayfinder.bottom_margin=(590 if raiding else 500) if pad_panel.visible else (380 if raiding else 290)
	wayfinder.top_margin=438 if alert_panel.visible else 332
	g.shipping_label.get_parent().visible=g.pier_owned and g.shipment["kind"]!="" and not city_mode
	position_top(g.shipping_label.get_parent(),348 if alert_panel.visible else 296,50)
	if g.pier_owned:wayfinder.top_margin+=64
	if g.shipment["kind"]=="": g.shipping_label.text="MUELLE AUTO   ·   Esperando excedente   ·   +50%"
	else:g.shipping_label.text="BARCO EN CAMINO   ·   %ds   ·   +%d monedas" % [ceili(g.shipment["remaining"]),g._shipment_income()]
	scrim.visible=g.shop_panel.visible
	shop_coins.text="Tenés %s monedas" % _number(g.coins)
	var affordable := 0
	for key in g.UPGRADE_POS:
		var upgrade: Dictionary=g._upgrade(key)
		g.store_buttons[key].disabled=upgrade["done"] or upgrade["locked"] or g.coins<upgrade["price"]
		g.store_buttons[key].text=("NIVEL 4" if key=="guard" else "NIVEL 3") if upgrade["locked"] else ("LISTO" if upgrade["done"] else "%s\nmonedas" % _number(upgrade["price"]))
		shop_details[key].text=upgrade["benefit"]
		if not upgrade["done"] and not upgrade["locked"] and g.coins>=upgrade["price"]:affordable+=1
	g.shop_button.text="MEJORAS"

func _number(value: int) -> String:
	if value>=1000000:return "%.1f M" % (float(value)/1000000)
	if value>=10000:return "%.1f mil" % (float(value)/1000)
	return str(value)
