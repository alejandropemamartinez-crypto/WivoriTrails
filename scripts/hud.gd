extends CanvasLayer

const IconScript=preload("res://scripts/ui_icon.gd")
const TouchButtonScript=preload("res://scripts/touch_button.gd")
const RabbitWarning=preload("res://scripts/rabbit_warning.gd")
const INK=Color("#2c4e54")
const Bold=preload("res://assets/fonts/Quicksand-Bold.ttf")
const Medium=preload("res://assets/fonts/Quicksand-Medium.ttf")
const MUTED=Color("#718783")
const PAPER=Color("#fffaf0")
const TEAL=Color("#238577")
const GOLD=Color("#efb34c")
# Accent colours are semantic: players recognise an upgrade by its hue as
# well as its icon, even when text becomes small in portrait orientation.
const UPGRADE_ACCENTS={
	"helper":Color("#327f75"),"collector":Color("#488f88"),
	"checkout":Color("#ab7840"),"lock":Color("#687a9a"),
	"alarm":Color("#bd6855"),"guard":Color("#536f95"),
	"bag":Color("#9b6d4f"),"speed":Color("#4f8bba"),
	"expand":Color("#668850"),"pier":Color("#47899b")
}
const BUILDING_ACCENTS={
	"house":Color("#c07757"),"cafe":Color("#98644c"),"depot":Color("#628a80"),
	"bakery":Color("#c18b43"),"greenhouse":Color("#6b9c69"),"workshop":Color("#6e819b"),
	"park":Color("#68a38b"),"watchtower":Color("#8a7997"),"mill":Color("#ac8756")
}
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
var uncollected_label: Label
var run_button: Button
var shop_details := {}
var objective := {}
var level_caption: Label
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
var rabbit_banner: RabbitWarningBanner
var move_button: Button
var shop_cards: Dictionary={}
var shop_category: String="team"
var shop_tabs: Dictionary={}
var shop_states: Dictionary={}
var town_cards: Dictionary={}
var town_statuses: Dictionary={}
var previous_wallet: int=-1
var activity_button: Button
var town_scroll: ScrollContainer
var focused_building:=""

func _fit_one_line(node: Label, value: String, available_width: float, ideal_size: int, minimum_size: int) -> void:
	# Long mission names should shrink a little instead of being cut off.
	# Quicksand remains consistent with the rest of the HUD.
	var font: Font=Bold
	var chosen: int=ideal_size
	while chosen>minimum_size and font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,chosen).x>available_width:
		chosen-=1
	node.add_theme_font_size_override("font_size",chosen)
	node.text=value
	node.tooltip_text=value

func semantic_color(kind: String) -> Color:
	return UPGRADE_ACCENTS.get(kind,TEAL)

func _accent_card(base_color: Color, accent: Color) -> StyleBoxFlat:
	var card_style:=style(base_color,17)
	card_style.border_color=accent.lightened(.33)
	card_style.border_width_left=7
	card_style.border_width_right=1
	card_style.border_width_top=1
	card_style.border_width_bottom=3
	card_style.content_margin_left=13;card_style.content_margin_right=13
	card_style.content_margin_top=12;card_style.content_margin_bottom=12
	card_style.shadow_color=Color(.11,.22,.20,.12)
	card_style.shadow_size=7
	card_style.shadow_offset=Vector2(0,3)
	return card_style

func label(text_: String, size_: int, color_: Color=INK) -> Label:
	var node := Label.new()
	node.text=text_
	node.add_theme_font_size_override("font_size",size_)
	node.add_theme_font_override("font",Bold if size_>=19 else Medium)
	node.add_theme_color_override("font_color",color_)
	node.add_theme_color_override("font_shadow_color",Color(1,1,1,.31))
	node.add_theme_constant_override("shadow_offset_y",1)
	node.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return node

func style(color_: Color, radius_: int=22) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color=color_
	box.set_corner_radius_all(radius_)
	box.border_color=color_.lightened(.10)
	box.set_border_width_all(2)
	box.border_width_bottom=4
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

func action_icon(index: int) -> Texture2D:
	return load("res://assets/ui/icons/button_"+["town","shop","speed","arrow","guard"][index]+".svg")

func button(text_: String, color_: Color=TEAL, font_size_: int=21) -> Button:
	var node := TouchButtonScript.new()
	node.expand_icon=false
	node.add_theme_constant_override("icon_max_width",28)
	node.text=text_
	node.add_theme_font_size_override("font_size",font_size_)
	node.add_theme_font_override("font",Bold)
	node.add_theme_color_override("font_shadow_color",Color(.06,.20,.21,.28))
	node.add_theme_constant_override("shadow_offset_y",2)
	node.add_theme_color_override("font_color",PAPER)
	node.add_theme_color_override("font_hover_color",PAPER)
	node.add_theme_color_override("font_pressed_color",PAPER)
	node.add_theme_color_override("font_disabled_color",Color("#7f9690"))
	var normal:=style(color_,21)
	normal.border_color=color_.darkened(.30)
	normal.border_width_bottom=5; normal.border_width_left=2; normal.border_width_right=2
	normal.shadow_color=Color(.06,.19,.18,.24)
	normal.shadow_size=8; normal.shadow_offset=Vector2(0,5)
	var hover:=style(color_.lightened(.11),21)
	hover.border_color=color_.darkened(.16);hover.border_width_bottom=5
	var pressed:=style(color_.darkened(.11),21)
	pressed.border_color=color_.darkened(.29);pressed.border_width_bottom=2
	node.add_theme_stylebox_override("normal",normal)
	node.add_theme_stylebox_override("hover",hover)
	node.add_theme_stylebox_override("pressed",pressed)
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
	ui_theme.default_font=Bold
	root.theme=ui_theme
	root.mouse_filter=Control.MOUSE_FILTER_IGNORE; add_child(root)

	var header:=panel(Color("#28565b"));root.add_child(header);position_top(header,16,80)
	var header_style:=style(Color("#28565b"),25);header_style.content_margin_top=8;header_style.content_margin_bottom=8;header.add_theme_stylebox_override("panel",header_style)
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",14);header.add_child(row)
	row.add_child(icon("coin",GOLD,Vector2(43,43)))
	var wallet:=VBoxContainer.new();wallet.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(wallet)
	g.total_label=label("50",29,Color("#fff5d7"));wallet.add_child(g.total_label)
	uncollected_label=label("En cajas  0",12,Color("#bed9c9"));uncollected_label.clip_text=true;wallet.add_child(uncollected_label)
	var badge:=panel(Color("#e8b95e"));badge.custom_minimum_size=Vector2(76,0);row.add_child(badge)
	var badge_style:=style(Color("#e8b95e"),19);badge_style.content_margin_top=5;badge_style.content_margin_bottom=5;badge_style.content_margin_left=12;badge_style.content_margin_right=12;badge.add_theme_stylebox_override("panel",badge_style)
	var level:=VBoxContainer.new();badge.add_child(level)
	var small:=label("NIVEL",11,Color("#76532b"));small.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;level.add_child(small);level_caption=small
	level_label=label("01",23,Color("#fff5dc"));level_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;level.add_child(level_label)
	level_progress=progress(Color("#fdf0c5"));level_progress.custom_minimum_size.y=5;level.add_child(level_progress)
	row.add_child(icon("bag",Color("#e8cb9b"),Vector2(35,45)))
	var bag:=VBoxContainer.new();bag.custom_minimum_size=Vector2(111,0);row.add_child(bag)
	bag.add_child(label("MOCHILA",11,Color("#bed9c9")))
	g.backpack_label=label("0 / 12",24,Color("#fff4d9"));bag.add_child(g.backpack_label)
	bag_progress=progress(GOLD);bag.add_child(bag_progress)

	var mission := panel(); root.add_child(mission); position_top(mission,106,108)
	var mission_style:=style(PAPER,22);mission_style.content_margin_top=6;mission_style.content_margin_bottom=6;mission.add_theme_stylebox_override("panel",mission_style)
	mission_panel=mission
	var mission_row := HBoxContainer.new(); mission_row.add_theme_constant_override("separation",12); mission.add_child(mission_row)
	var mission_column := VBoxContainer.new(); mission_column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	mission_column.add_theme_constant_override("separation",3); mission_row.add_child(mission_column)
	next_label=label("TU PRIMER MERCADO",12,TEAL); mission_column.add_child(next_label)
	g.mission_label=label("Tu primera cosecha",21); mission_column.add_child(g.mission_label)
	g.mission_label.clip_text=true
	next_label.clip_text=true
	mission_detail=label("",14,MUTED)
	mission_detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	mission_detail.max_lines_visible=2
	mission_detail.clip_text=true
	mission_detail.custom_minimum_size=Vector2.ZERO
	mission_column.add_child(mission_detail)
	mission_progress=progress(); mission_column.add_child(mission_progress)
	guide_button=button("GUIAR",TEAL,14); guide_button.icon=action_icon(3);guide_button.icon_alignment=HORIZONTAL_ALIGNMENT_LEFT;guide_button.custom_minimum_size=Vector2(119,76)
	guide_button.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	guide_button.pressed.connect(func():g._follow_objective()); mission_row.add_child(guide_button)

	var status := HBoxContainer.new(); root.add_child(status); position_top(status,281,36)
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
	view.offset_left=-108; view.offset_right=-24; view.offset_top=224; view.offset_bottom=270
	view.pressed.connect(func():g._toggle_camera_view())
	view.tooltip_text="Acercar o alejar la cámara"

	g.input_stick=load("res://scripts/joystick.gd").new(); root.add_child(g.input_stick);g.input_stick.input_allowed=Callable(g,"_movement_input_allowed")
	g.input_stick.anchor_top=1; g.input_stick.anchor_bottom=1
	g.input_stick.offset_left=18; g.input_stick.offset_right=223
	g.input_stick.offset_top=-252; g.input_stick.offset_bottom=-37
	var run := button("CORRER",Color("#cb8b46"),18); root.add_child(run)
	run_button=run
	run.icon=action_icon(2);run.icon_alignment=HORIZONTAL_ALIGNMENT_LEFT
	run.anchor_left=1; run.anchor_right=1; run.anchor_top=1; run.anchor_bottom=1
	run.offset_left=-182; run.offset_right=-24; run.offset_top=-272; run.offset_bottom=-176
	run.button_down.connect(func():g.boost_active=true)
	run.button_up.connect(func():g.boost_active=false)
	g.shop_button=button("MEJORAS",TEAL,17); g.shop_button.icon=action_icon(1);g.shop_button.icon_alignment=HORIZONTAL_ALIGNMENT_LEFT; root.add_child(g.shop_button)
	g.shop_button.anchor_left=1; g.shop_button.anchor_right=1
	g.shop_button.anchor_top=1; g.shop_button.anchor_bottom=1
	g.shop_button.offset_left=-154; g.shop_button.offset_right=-24
	g.shop_button.offset_top=-160; g.shop_button.offset_bottom=-64
	g.shop_button.pressed.connect(func():g._toggle_shop())
	town_button=button("PUEBLO",Color("#5d8490"),17);town_button.icon=action_icon(0);town_button.icon_alignment=HORIZONTAL_ALIGNMENT_LEFT;root.add_child(town_button)
	town_button.anchor_left=1; town_button.anchor_right=1; town_button.anchor_top=1; town_button.anchor_bottom=1
	town_button.offset_left=-286; town_button.offset_right=-163
	town_button.offset_top=-160; town_button.offset_bottom=-64
	town_button.pressed.connect(func():g._toggle_build_mode())
	activity_button=button("PEDIDOS",Color("#5d8490"),17);root.add_child(activity_button)
	activity_button.anchor_top=1;activity_button.anchor_bottom=1
	activity_button.offset_left=242;activity_button.offset_right=425;activity_button.offset_top=-160;activity_button.offset_bottom=-64
	activity_button.pressed.connect(func():g.work.toggle_board());activity_button.visible=false

	intercept_button=button("AHUYENTAR",Color("#b55d50"),19);intercept_button.icon=action_icon(4);intercept_button.icon_alignment=HORIZONTAL_ALIGNMENT_LEFT;root.add_child(intercept_button)
	intercept_button.anchor_left=1; intercept_button.anchor_right=1; intercept_button.anchor_top=1; intercept_button.anchor_bottom=1
	intercept_button.offset_left=-286; intercept_button.offset_right=-24; intercept_button.offset_top=-384; intercept_button.offset_bottom=-288
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
	rabbit_banner=RabbitWarning.new()
	root.add_child(rabbit_banner)
	# The emergency interception control must win hit-testing over any nearby
	# contextual purchase panels when several UI elements overlap.
	root.move_child(intercept_button,root.get_child_count()-1)
	_apply_safe_area()
	get_viewport().size_changed.connect(_apply_safe_area)

func build_action_cards() -> void:
	alert_panel=panel(Color("#fff1de")); root.add_child(alert_panel)
	position_top(alert_panel,224,98,24,-120)
	var compact:=style(Color("#fff1de"),18);compact.content_margin_top=5;compact.content_margin_bottom=5;alert_panel.add_theme_stylebox_override("panel",compact)
	var row := HBoxContainer.new(); row.add_theme_constant_override("separation",12); alert_panel.add_child(row)
	var column := VBoxContainer.new(); column.size_flags_horizontal=Control.SIZE_EXPAND_FILL; row.add_child(column)
	alert_title=label("",17,Color("#ab593d"));alert_title.clip_text=true; column.add_child(alert_title)
	alert_detail=label("",13,MUTED);alert_detail.clip_text=true
	alert_detail.custom_minimum_size=Vector2(260,0); column.add_child(alert_detail)
	alert_button=button("REPONER",Color("#b96a40"),13); alert_button.custom_minimum_size=Vector2(116,88)
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
	pad_detail.custom_minimum_size=Vector2(340,0);pad_detail.max_lines_visible=2; description.add_child(pad_detail)
	pad_button=button("COMPRAR",TEAL,18); pad_button.custom_minimum_size=Vector2(156,96)
	pad_button.size_flags_vertical=Control.SIZE_SHRINK_CENTER; pad_row.add_child(pad_button)
	pad_button.pressed.connect(func():g._purchase_nearby())
	pad_panel.visible=false

func build_town_controls() -> void:
	# Township-inspired compact horizontal catalog: the town stays on screen.
	town_panel=panel(Color("#fff8e9"))
	root.add_child(town_panel)
	town_panel.anchor_left=0; town_panel.anchor_right=1
	town_panel.anchor_top=1; town_panel.anchor_bottom=1
	town_panel.offset_left=20; town_panel.offset_right=-20
	town_panel.offset_top=-458; town_panel.offset_bottom=-169
	var column:=VBoxContainer.new(); column.add_theme_constant_override("separation",5)
	town_panel.add_child(column)
	var top:=HBoxContainer.new()
	top.add_theme_constant_override("separation",10)
	column.add_child(top)
	var title:=label("CONSTRUIR",20,INK)
	title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	top.add_child(title)
	move_button=button("MOVER EDIFICIO",Color("#6d8797"),13)
	move_button.pressed.connect(func():g.town.begin_move())
	top.add_child(move_button)
	top.add_child(label("Deslizá",13,MUTED))
	town_description=label("Elegí un solar tocándolo en el mapa",15,MUTED)
	town_description.clip_text=true
	column.add_child(town_description)
	var scroller:=ScrollContainer.new()
	town_scroll=scroller
	scroller.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO
	scroller.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	scroller.size_flags_vertical=Control.SIZE_EXPAND_FILL
	column.add_child(scroller)
	var listing:=HBoxContainer.new()
	listing.add_theme_constant_override("separation",10)
	scroller.add_child(listing)
	for kind in ["house","cafe","depot","bakery","greenhouse","workshop","park","watchtower","mill"]:
		var detail: Dictionary=g.town.TYPES[kind]
		var accent: Color=BUILDING_ACCENTS.get(kind,TEAL)
		var card:=panel(Color("#fff9ed"))
		card.custom_minimum_size=Vector2(203,0)
		card.add_theme_stylebox_override("panel",_accent_card(Color("#fff9ed"),accent))
		town_cards[kind]=card
		listing.add_child(card)
		var stack:=VBoxContainer.new()
		stack.add_theme_constant_override("separation",3)
		card.add_child(stack)
		var picture_frame:=panel(accent.lightened(.72))
		var frame_style:=style(accent.lightened(.72),12)
		frame_style.content_margin_top=3;frame_style.content_margin_bottom=3
		frame_style.content_margin_left=4;frame_style.content_margin_right=4
		frame_style.set_border_width_all(1);frame_style.border_color=accent.lightened(.32)
		picture_frame.add_theme_stylebox_override("panel",frame_style)
		stack.add_child(picture_frame)
		var picture:=TextureRect.new()
		picture.texture=load("res://assets/ui/buildings/"+kind+".png")
		picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		picture.custom_minimum_size=Vector2(0,74)
		picture.mouse_filter=Control.MOUSE_FILTER_IGNORE
		picture_frame.add_child(picture)
		var heading:=label(detail["name"],15,INK)
		heading.clip_text=true;heading.tooltip_text=detail["name"]
		stack.add_child(heading)
		var info:=label(detail["benefit"],12,MUTED)
		info.clip_text=true;info.tooltip_text=detail["benefit"]
		stack.add_child(info)
		var status:=label("DISPONIBLE",12,accent)
		stack.add_child(status);town_statuses[kind]=status
		var buy:=button("%d MON." % detail["price"],accent,15)
		buy.custom_minimum_size=Vector2(0,49)
		stack.add_child(buy)
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
	# Animated real coins converge on the treasury, rather than just a number.
	var origin:=Vector2(clampf(source.x,32,600),clampf(source.y,260,1000))
	for i in range(5):
		var coin:=icon("coin",GOLD,Vector2(29,29))
		coin.mouse_filter=Control.MOUSE_FILTER_IGNORE
		root.add_child(coin)
		coin.position=origin+Vector2(float(i-2)*12.0,-absf(float(i-2))*4.0)
		coin.pivot_offset=Vector2(15,15)
		var coin_tween:=create_tween().set_parallel(true)
		var target:=Vector2(79+float(i%2)*13.0,77)
		coin_tween.tween_property(coin,"position",target,.63+float(i)*.055).set_delay(.04*float(i)).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		coin_tween.tween_property(coin,"scale",Vector2.ONE*.30,.63+float(i)*.055).set_delay(.04*float(i))
		coin_tween.chain().tween_callback(coin.queue_free)
	note.position=origin
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
	var title := label("El taller de Wivori",29); title.size_flags_horizontal=Control.SIZE_EXPAND_FILL; heading.add_child(title)
	var close := button("X",Color("#dbe7dc"),20); close.add_theme_color_override("font_color",INK)
	close.custom_minimum_size=Vector2(52,52); heading.add_child(close); close.pressed.connect(func():g._toggle_shop())
	shop_coins=label("",20,TEAL); column.add_child(shop_coins)
	var tabs:=HBoxContainer.new();tabs.add_theme_constant_override("separation",10);column.add_child(tabs)
	for category in ["team","tools"]:
		var tab:=button("CONTRATAR" if category=="team" else "MEJORAR",TEAL if category=="team" else Color("#6d8797"),17)
		tab.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		tab.custom_minimum_size.y=52;tabs.add_child(tab)
		shop_tabs[category]=tab
		tab.pressed.connect(func():shop_category=category;_filter_shop())
	var scroll := ScrollContainer.new(); scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL; column.add_child(scroll)
	var upgrades := VBoxContainer.new(); upgrades.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	upgrades.add_theme_constant_override("separation",12); scroll.add_child(upgrades)
	var names := {}
	for kind in g.UPGRADE_POS:names[kind]=g._upgrade(kind)["name"]
	for key in ["helper","collector","checkout","lock","alarm","guard","bag","speed","expand","pier"]:
		var accent: Color=semantic_color(key)
		var card:=panel(Color("#fffaef"))
		shop_cards[key]=card
		card.add_theme_stylebox_override("panel",_accent_card(Color("#fffaef"),accent))
		upgrades.add_child(card)
		var row:=HBoxContainer.new()
		row.add_theme_constant_override("separation",13)
		card.add_child(row)
		# An illustrated, colour-coded relief emblem anchors the card.
		var medallion:=panel(accent.lightened(.68))
		var medallion_style:=style(accent.lightened(.68),18)
		medallion_style.set_border_width_all(2)
		medallion_style.border_color=accent.lightened(.32)
		medallion_style.content_margin_left=8;medallion_style.content_margin_right=8
		medallion_style.content_margin_top=8;medallion_style.content_margin_bottom=8
		medallion.add_theme_stylebox_override("panel",medallion_style)
		medallion.custom_minimum_size=Vector2(72,76)
		row.add_child(medallion)
		medallion.add_child(icon(key,accent,Vector2(54,56)))
		var description:=VBoxContainer.new()
		description.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		description.add_theme_constant_override("separation",3)
		row.add_child(description)
		var category_caption:=label("EQUIPO DEL PUEBLO" if key in ["helper","collector","guard"] else "MEJORA DEL NEGOCIO",11,accent)
		description.add_child(category_caption)
		var heading:=label(names[key],19,INK)
		heading.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		description.add_child(heading)
		var detail:=label("",14,MUTED)
		detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		detail.max_lines_visible=2
		detail.clip_text=true
		description.add_child(detail)
		shop_details[key]=detail
		var status:=label("",12,accent)
		description.add_child(status)
		shop_states[key]=status
		var buy:=button("",accent,17)
		buy.custom_minimum_size=Vector2(119,90)
		buy.size_flags_vertical=Control.SIZE_SHRINK_CENTER
		row.add_child(buy)
		buy.pressed.connect(Callable(g,"_buy").bind(key))
		g.store_buttons[key]=buy
	var done := button("VOLVER AL MERCADO",TEAL,20); done.custom_minimum_size=Vector2(0,62)
	done.pressed.connect(func():g._toggle_shop()); column.add_child(done)
	_filter_shop()

func _filter_shop() -> void:
	for key in shop_cards:
		shop_cards[key].visible=(key in ["helper","collector","guard"]) if shop_category=="team" else (key not in ["helper","collector","guard"])
	for category in shop_tabs:
		shop_tabs[category].self_modulate=Color.WHITE if category==shop_category else Color(.82,.86,.85,.85)


func refresh() -> void:
	var city_mode: bool=g.town!=null and g.town.in_build_mode
	mission_panel.visible=not city_mode
	status_row.visible=false
	view_button.visible=not city_mode
	footer_panel.visible=false
	g.input_stick.visible=not city_mode
	run_button.visible=not city_mode
	g.shop_button.visible=not city_mode and not g.route.away()
	activity_button.visible=g.run.level>=7 and not city_mode and not g.route.away()
	activity_button.text="PEDIDO LISTO" if g.work.has_ready() else "PEDIDOS"
	if g.work.board_visible():g.work.refresh_board()
	town_panel.visible=city_mode
	town_button.text="VOLVER" if city_mode else "GRANJA" if g.route.away() else "PUEBLO"
	if city_mode:
		if not g.town.focus_kind.is_empty() and focused_building!=g.town.focus_kind:
			focused_building=g.town.focus_kind;town_scroll.set_deferred("scroll_horizontal",maxi(0,g.town.TYPES.keys().find(focused_building))*196)
		town_description.text=g.town.selection_description()
		if not g.town.focus_kind.is_empty() and not g.town.has_building(g.town.focus_kind):town_description.text="Construí "+g.town.TYPES[g.town.focus_kind]["name"].to_lower()+" · elegí un solar vacío."
		move_button.visible=not g.town.constructed[g.town.selected].is_empty()
		move_button.text="ELEGÍ UN SOLAR" if g.town.move_source>=0 else "MOVER EDIFICIO"
		for kind in town_choices:
			var detail: Dictionary=g.town.TYPES[kind]
			var built: bool=g.town.has_building(kind)
			town_choices[kind].disabled=built or not g.town.constructed[g.town.selected].is_empty() or g.coins<detail["price"] or not g.town.can_build(kind)
			town_choices[kind].text="CONSTRUIDO" if built else ("NIVEL %d" % g.town.BUILDING_LEVELS[kind] if g.run.level<g.town.BUILDING_LEVELS[kind] else "%d MON." % detail["price"])
			var shortfall: int=maxi(0,int(detail["price"])-g.coins)
			town_statuses[kind].text="CONSTRUIDO" if built else "BLOQUEADO" if not g.town.can_build(kind) else "FALTAN %d" % shortfall if shortfall>0 else "LISTO PARA CONSTRUIR"
			town_statuses[kind].add_theme_color_override("font_color",Color("#2b8a6b") if not town_choices[kind].disabled else MUTED)
	g.total_label.text=_number(g.coins)
	if previous_wallet>=0 and previous_wallet!=g.coins:
		g.total_label.pivot_offset=g.total_label.size*.5
		g.total_label.scale=Vector2.ONE*1.10
		create_tween().tween_property(g.total_label,"scale",Vector2.ONE,.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	previous_wallet=g.coins
	uncollected_label.text=("Caja local · %d" % g.route.market_money[g.route.region]) if g.route.away() else "En cajas · %s" % _number(g.cash.total_pending())
	uncollected_label.modulate=Color.WHITE
	if g.cash.in_transit()>0:uncollected_label.text+=" · EN CAMINO %d" % g.cash.in_transit()
	g.backpack_label.text="%d / %d" % [g._total_bag(),g.max_capacity]
	bag_progress.max_value=g.max_capacity; bag_progress.value=g._total_bag()
	g.stock_label.text="Puesto  %s" % _number(g._total_stock())
	team_label.text="Equipo  %d" % g.worker_count
	queue_label.text="Fila  %d/6" % g._waiting_count()
	queue_label.add_theme_color_override("font_color",Color("#af5845") if g._waiting_count()>=4 else INK)
	level_caption.text="ETAPA" if g.route.away() else "NIVEL"
	level_label.text="%02d" % (mini(15,g.route.stage+1) if g.route.away() else g.run.level)
	level_progress.max_value=1.0; level_progress.value=g.run.progress()
	if g.route.route_button!=null:
		g.route.route_button.visible=not city_mode
		g.route.route_button.text="RUTA %d/15" % g.route.stage if g.route.ferry else "RUTA AL FARO"
	objective=g._current_objective()
	next_label.text=objective["tag"]
	var mission_width: float=maxf(195.0,root.size.x-252.0)
	_fit_one_line(g.mission_label,str(objective["title"]),mission_width,21,15)
	mission_detail.text=str(objective["detail"])
	mission_detail.tooltip_text=mission_detail.text
	mission_progress.max_value=objective["goal"]; mission_progress.value=objective["value"]
	guide_button.text=objective["button"]
	guide_button.modulate=Color("#ffe3a2") if objective.get("ready",false) else Color.WHITE
	wayfinder.objective=objective
	var alert: Dictionary=g.director.alert()
	var raid_phase: String=""
	if not city_mode and not g.shop_panel.visible:
		if g.run.warning>0:raid_phase="warning"
		if not g.run.threat().is_empty():
			raid_phase="escape" if g.run.threat()["state"]=="escape" else "approach"
	rabbit_banner.sync_state(raid_phase)
	if not g.run.threat().is_empty():rabbit_banner.point_to(g.run.threat()["actor"].position,g.player.position)
	alert_panel.visible=not alert.is_empty() and raid_phase.is_empty() and not g.shop_panel.visible and not city_mode
	if not alert.is_empty():
		alert_title.text=alert["title"]; alert_detail.text=alert["detail"]; alert_button.text=alert["button"]
		alert_title.add_theme_color_override("font_color",alert["color"])
	pad_panel.visible=not g.route.away() and not g.active_pad.is_empty() and not g.shop_panel.visible and not city_mode and not g.work.board_visible() and g.run.threat().is_empty() and not rabbit_banner.visible
	if not g.active_pad.is_empty():
		var upgrade: Dictionary=g._upgrade(g.active_pad)
		pad_title.text=upgrade["name"]
		pad_detail.text=upgrade["benefit"]
		pad_button.text="COMPRAR\n%d monedas" % upgrade["price"]
		pad_button.disabled=g.coins<upgrade["price"] or upgrade["locked"]
		if pad_button.disabled and g.coins<upgrade["price"]:pad_detail.text+=" Te faltan %d monedas." % (upgrade["price"]-g.coins)
	var raiding: bool=not g.run.threat().is_empty()
	intercept_button.visible=raiding and not g.shop_panel.visible and not city_mode
	intercept_button.disabled=not g.run.can_intercept()
	intercept_button.text="AHUYENTAR" if not intercept_button.disabled else "ACERCATE AL MAPACHE"
	intercept_button.add_theme_font_size_override("font_size",19 if not intercept_button.disabled else 15)
	pad_panel.offset_top=-544 if raiding else -424
	pad_panel.offset_bottom=-404 if raiding else -292
	g.event_label.offset_top=(-634 if raiding else -542) if pad_panel.visible else (-420 if raiding else -337)
	g.event_label.offset_bottom=g.event_label.offset_top+72
	wayfinder.visible=not city_mode
	wayfinder.bottom_margin=(590 if raiding else 500) if pad_panel.visible else (380 if raiding else 290)
	wayfinder.top_margin=330 if alert_panel.visible or rabbit_banner.visible else 228
	g.shipping_label.get_parent().visible=not g.route.away() and g.pier_owned and g.shipment["kind"]!="" and not city_mode
	position_top(g.shipping_label.get_parent(),330 if alert_panel.visible else 224,40)
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
		var ready: bool=not upgrade["done"] and not upgrade["locked"] and g.coins>=upgrade["price"]
		if upgrade["done"]:
			shop_states[key].text="MEJORA CONSEGUIDA"
		elif upgrade["locked"]:
			shop_states[key].text="SE DESBLOQUEA CON EL PROGRESO"
		elif ready:
			shop_states[key].text="¡PODÉS COMPRARLA!"
		else:
			shop_states[key].text="TE FALTAN %s MONEDAS" % _number(upgrade["price"]-g.coins)
		shop_states[key].add_theme_color_override("font_color",Color("#2a8871") if ready else MUTED)
		if ready:affordable+=1
	g.shop_button.text="MEJORAS"

func _number(value: int) -> String:
	if value>=1000000:return "%.1f M" % (float(value)/1000000)
	if value>=10000:return "%.1f mil" % (float(value)/1000)
	return str(value)
