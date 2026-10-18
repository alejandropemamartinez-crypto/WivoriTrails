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
	root.mouse_filter=Control.MOUSE_FILTER_IGNORE; add_child(root)

	var header := panel(); root.add_child(header); position_top(header,24,88)
	var row := HBoxContainer.new(); row.add_theme_constant_override("separation",10); header.add_child(row)
	row.add_child(icon("coin",INK,Vector2(48,48)))
	var money := VBoxContainer.new(); money.size_flags_horizontal=Control.SIZE_EXPAND_FILL; row.add_child(money)
	money.add_child(label("MONEDAS",13,MUTED))
	g.total_label=label("50",30); money.add_child(g.total_label)
	row.add_child(icon("bag",TEAL,Vector2(37,48)))
	var bag := VBoxContainer.new(); bag.custom_minimum_size=Vector2(120,0); row.add_child(bag)
	g.backpack_label=label("0 / 12",23); bag.add_child(g.backpack_label)
	bag_progress=progress(GOLD); bag.add_child(bag_progress)

	var mission := panel(); root.add_child(mission); position_top(mission,128,136)
	var mission_row := HBoxContainer.new(); mission_row.add_theme_constant_override("separation",12); mission.add_child(mission_row)
	var mission_column := VBoxContainer.new(); mission_column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	mission_column.add_theme_constant_override("separation",3); mission_row.add_child(mission_column)
	next_label=label("TU PRIMER MERCADO",12,TEAL); mission_column.add_child(next_label)
	g.mission_label=label("Tu primera cosecha",23); mission_column.add_child(g.mission_label)
	mission_detail=label("",17,MUTED); mission_detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	mission_detail.custom_minimum_size=Vector2(370,0); mission_column.add_child(mission_detail)
	mission_progress=progress(); mission_column.add_child(mission_progress)
	guide_button=button("GUIAR",TEAL,16); guide_button.custom_minimum_size=Vector2(122,70)
	guide_button.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	guide_button.pressed.connect(func():g._follow_objective()); mission_row.add_child(guide_button)

	var status := HBoxContainer.new(); root.add_child(status); position_top(status,280,36)
	status.add_theme_constant_override("separation",12)
	var stock := panel(Color(.98,.97,.90,.90)); status.add_child(stock)
	var chip_style := style(Color(.98,.97,.90,.90),12)
	chip_style.content_margin_top=7; chip_style.content_margin_bottom=7
	stock.add_theme_stylebox_override("panel",chip_style)
	g.stock_label=label("Puesto  0",17); stock.add_child(g.stock_label)
	var team := panel(Color(.98,.97,.90,.90)); status.add_child(team)
	team.add_theme_stylebox_override("panel",chip_style)
	team_label=label("Equipo  0",17); team.add_child(team_label)
	var shipping := panel(Color(.12,.31,.31,.94)); root.add_child(shipping)
	position_top(shipping,340,58,24,-130)
	shipping.add_theme_stylebox_override("panel",style(Color(.12,.31,.31,.94),14))
	g.shipping_label=label("",16,PAPER); shipping.add_child(g.shipping_label); shipping.visible=false

	var view := button("VISTA",PAPER,14); root.add_child(view)
	view.add_theme_color_override("font_color",INK); view.add_theme_color_override("font_hover_color",INK)
	view.anchor_left=1; view.anchor_right=1
	view.offset_left=-108; view.offset_right=-24; view.offset_top=340; view.offset_bottom=398
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
	g.shop_button=button("MEJORAS",TEAL,23); root.add_child(g.shop_button)
	g.shop_button.anchor_left=1; g.shop_button.anchor_right=1
	g.shop_button.anchor_top=1; g.shop_button.anchor_bottom=1
	g.shop_button.offset_left=-286; g.shop_button.offset_right=-24
	g.shop_button.offset_top=-152; g.shop_button.offset_bottom=-68
	g.shop_button.pressed.connect(func():g._toggle_shop())

	var footer := panel(Color(.98,.97,.90,.92)); root.add_child(footer)
	footer.anchor_top=1; footer.anchor_bottom=1; footer.anchor_right=1
	footer.offset_left=242; footer.offset_right=-24; footer.offset_top=-55; footer.offset_bottom=-12
	var footer_style := style(Color(.98,.97,.90,.92),12)
	footer_style.content_margin_left=10; footer_style.content_margin_right=10
	footer_style.content_margin_top=4; footer_style.content_margin_bottom=4
	footer.add_theme_stylebox_override("panel",footer_style)
	g.hint_label=label("Movete o tocá el camino",14); g.hint_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	footer.add_child(g.hint_label)

	g.event_label=label("",23,PAPER); root.add_child(g.event_label)
	g.event_label.anchor_right=1; g.event_label.anchor_top=1; g.event_label.anchor_bottom=1
	g.event_label.offset_left=24; g.event_label.offset_right=-24
	g.event_label.offset_top=-337; g.event_label.offset_bottom=-273
	g.event_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	g.event_label.add_theme_stylebox_override("normal",style(Color(.10,.26,.26,.94),18))
	g.event_label.visible=false
	build_shop()
	_apply_safe_area()
	get_viewport().size_changed.connect(_apply_safe_area)

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
	var names := {"helper":"Ayudante automático","speed":"Pasos más rápidos","bag":"Más espacio en la mochila","expand":"Huerto de manzanas","pier":"Muelle de exportación"}
	for key in ["helper","bag","speed","expand","pier"]:
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
	g.total_label.text=_number(g.coins)
	g.backpack_label.text="%d / %d" % [g._total_bag(),g.max_capacity]
	bag_progress.max_value=g.max_capacity; bag_progress.value=g._total_bag()
	g.stock_label.text="Puesto  %s" % _number(g._total_stock())
	team_label.text="Equipo  %d" % g.worker_count
	objective=g._current_objective()
	next_label.text=objective["tag"]
	g.mission_label.text=objective["title"]
	mission_detail.text=objective["detail"]
	mission_progress.max_value=objective["goal"]; mission_progress.value=objective["value"]
	guide_button.text=objective["button"]
	g.shipping_label.get_parent().visible=g.pier_owned
	if g.shipment["kind"]=="": g.shipping_label.text="MUELLE AUTO   ·   Esperando excedente   ·   +50%"
	else:g.shipping_label.text="BARCO EN CAMINO   ·   %ds   ·   +%d monedas" % [ceili(g.shipment["remaining"]),g._shipment_income()]
	scrim.visible=g.shop_panel.visible
	shop_coins.text="Tenés %s monedas" % _number(g.coins)
	var prices := {"helper":g.helper_cost,"bag":g.bag_cost,"speed":g.speed_cost,"expand":g.expand_cost,"pier":550}
	var benefits := {"helper":"Cosecha y entrega por vos. Equipo: %d/%d." % [g.worker_count,g.MAX_HELPERS],
		"bag":"Capacidad: %d → %d productos." % [g.max_capacity,mini(300,g.max_capacity+6)],
		"speed":"Caminás un poco más rápido en cada viaje.","expand":"Desbloquea 9 cultivos. Cada manzana vale 14 monedas.",
		"pier":"Exporta el excedente automáticamente por 50% más."}
	for key in prices:
		var owned: bool=(key=="expand" and g.orchard_owned) or (key=="pier" and g.pier_owned)
		var capped: bool=(key=="helper" and g.worker_count>=g.MAX_HELPERS) or (key=="bag" and g.max_capacity>=300) or (key=="speed" and g.player_speed>=12)
		g.store_buttons[key].disabled=owned or capped or g.coins<prices[key]
		g.store_buttons[key].text="LISTO" if owned else ("AL MÁXIMO" if capped else "%s\nmonedas" % _number(prices[key]))
		shop_details[key].text=benefits[key]

func _number(value: int) -> String:
	if value>=1000000:return "%.1f M" % (float(value)/1000000)
	if value>=10000:return "%.1f mil" % (float(value)/1000)
	return str(value)
