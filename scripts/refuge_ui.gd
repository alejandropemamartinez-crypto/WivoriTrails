extends RefCounted

const Icon=preload("res://scripts/refuge_icon.gd")
const Touch=preload("res://scripts/touch_button.gd")
const BOLD=preload("res://assets/fonts/Quicksand-Bold.ttf")
const MEDIUM=preload("res://assets/fonts/Quicksand-Medium.ttf")
const INK=Color("#243f51")
const MUTED=Color("#647d8a")
const GOLD=Color("#eab76c")
const PAPER=Color("#f3f5ee")
const NAVY=Color("#213d51")
const TEAL=Color("#447f7d")
var game
var state
var root: Control
var resource_labels: Dictionary={}
var city_name: Label
var chapter: Label
var weather: Label
var comfort: Label
var progress: ProgressBar
var task_title: Label
var task_detail: Label
var task_button: Button
var task_count: Label
var route_button: Button
var toast: Label
var toast_time:=0.0
var placards: Dictionary={}
var modal: ColorRect
var modal_card: PanelContainer
var modal_heading: Label
var modal_subtitle: Label
var listing: VBoxContainer
var view:=""
var selected:=""
var refs: Dictionary={}
var goal_rows: Array[Dictionary]=[]
var worker_rows: Dictionary={}
var route_rows: Array[Dictionary]=[]
var build_bar: ProgressBar
var pending_building:=""
var task_card: PanelContainer
var camera_button: Button
var run_button: Button
var move_hint: Control
var nav_buttons: Dictionary={}
var work_button: Button
var work_hint: Label
var shop_rows: Dictionary={}
var shop_balance: Label
var market_labels: Dictionary={}

func _label(text_: String,size_: int=20,color_: Color=INK) -> Label:
	var label:=Label.new();label.text=text_;label.add_theme_font_override("font",BOLD if size_>=19 else MEDIUM)
	label.add_theme_font_size_override("font_size",size_);label.add_theme_color_override("font_color",color_)
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE;return label
func _wrap(text_: String,size_: int=18,color_: Color=INK) -> Label:
	var label:=_label(text_,size_,color_);label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;return label
func _style(color_: Color,radius: int=20) -> StyleBoxFlat:
	var style:=StyleBoxFlat.new();style.bg_color=color_;style.set_corner_radius_all(radius)
	style.content_margin_left=18;style.content_margin_right=18;style.content_margin_top=14;style.content_margin_bottom=14
	style.border_color=color_.lightened(.16);style.border_width_top=1;style.border_width_bottom=3
	style.shadow_color=Color(.04,.12,.19,.17);style.shadow_size=7;style.shadow_offset=Vector2(0,4);return style
func _panel(color_: Color=PAPER) -> PanelContainer:
	var panel:=PanelContainer.new();panel.add_theme_stylebox_override("panel",_style(color_));return panel
func _button(text_: String,callback: Callable,color_: Color=TEAL,size_: int=20) -> Button:
	var button:=Touch.new();button.text=text_;button.custom_minimum_size.y=62
	button.add_theme_font_override("font",BOLD);button.add_theme_font_size_override("font_size",size_)
	button.add_theme_color_override("font_color",Color("#183b4b") if color_==GOLD else Color("#f7f6ed"))
	button.add_theme_color_override("font_disabled_color",Color("#77909a"))
	button.add_theme_stylebox_override("normal",_style(color_,16));button.add_theme_stylebox_override("hover",_style(color_.lightened(.05),16))
	button.add_theme_stylebox_override("pressed",_style(color_.darkened(.12),16));button.add_theme_stylebox_override("disabled",_style(Color("#d8e1df"),16))
	button.pressed.connect(callback);return button
func _icon(kind: String,size_: float=32,tint: Color=GOLD) -> Control:
	var node:=Icon.new();node.kind=kind;node.tint=tint;node.custom_minimum_size=Vector2.ONE*size_;return node
func _column(parent: Node,separation: int=10) -> VBoxContainer:
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",separation);parent.add_child(column);return column
func _row(parent: Node,separation: int=10) -> HBoxContainer:
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",separation);parent.add_child(row);return row
func _place(node: Control,left: float,top: float,right: float,bottom: float) -> void:
	root.add_child(node);node.anchor_right=1;node.offset_left=left;node.offset_top=top;node.offset_right=right;node.offset_bottom=bottom
func _bottom(node: Control,left: float,top: float,right: float,bottom: float) -> void:
	_place(node,left,top,right,bottom);node.anchor_top=1;node.anchor_bottom=1

func build(source: Node3D) -> void:
	game=source;state=game.state
	var layer:=CanvasLayer.new();game.add_child(layer);root=Control.new();root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);root.mouse_filter=Control.MOUSE_FILTER_IGNORE;layer.add_child(root)
	var header_backdrop:=ColorRect.new();header_backdrop.color=Color("#d5e6eb");header_backdrop.anchor_right=1;header_backdrop.offset_bottom=214;root.add_child(header_backdrop)
	var header:=HBoxContainer.new();header.add_theme_constant_override("separation",14);_place(header,22,18,-22,74)
	var names:=_column(header,0);names.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	names.add_child(_label("WIVORI  /  REFUGIOS DEL NORTE",12,Color("#486777")))
	city_name=_label("",27);names.add_child(city_name)
	chapter=_label("",15);chapter.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;header.add_child(chapter)
	var menu:=_button("···",show_menu,NAVY,28);menu.custom_minimum_size=Vector2(58,54);header.add_child(menu)
	var resources:=HBoxContainer.new();resources.add_theme_constant_override("separation",8);_place(resources,20,88,-20,154)
	for key in ["coins","wood","meat"]:
		var card:=_panel(NAVY);card.size_flags_horizontal=Control.SIZE_EXPAND_FILL;resources.add_child(card)
		var style:=_style(NAVY,17);style.content_margin_left=10;style.content_margin_right=8;style.content_margin_top=8;style.content_margin_bottom=8;card.add_theme_stylebox_override("panel",style)
		var row:=_row(card,8);row.add_child(_icon(key,31));var col:=_column(row,0);col.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		resource_labels[key]=_label("0",24,Color("#fff3d8"));col.add_child(resource_labels[key]);col.add_child(_label({"coins":"MONEDAS","wood":"MOCHILA · MADERA","meat":"MOCHILA · CARNE"}[key],12,Color("#b9cfdb")))
		card.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
		card.gui_input.connect(func(event: InputEvent):
			if event is InputEventScreenTouch and event.pressed or event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
				card.accept_event();show_market())
	var status_card:=_panel(PAPER);var status_style:=_style(PAPER,12);status_style.content_margin_left=12;status_style.content_margin_right=12;status_style.content_margin_top=5;status_style.content_margin_bottom=5;status_style.shadow_size=2
	status_card.add_theme_stylebox_override("panel",status_style);_place(status_card,20,164,-20,208)
	var status:=_row(status_card,10)
	weather=_label("",17,Color("#355c70"));weather.size_flags_horizontal=Control.SIZE_EXPAND_FILL;status.add_child(weather)
	comfort=_label("",17,Color("#355c70"));status.add_child(comfort)
	toast=_wrap("",17,Color("#fff4d9"));toast.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	toast.max_lines_visible=2;toast.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	# Ellipsis + wrapping may report a one-pixel minimum before shaping.
	# Keep two real lines instead of centering an invisible strip in the card.
	toast.custom_minimum_size.y=44;toast.size_flags_vertical=Control.SIZE_EXPAND_FILL
	var toast_card:=_panel(Color("#38596c"));var toast_style:=_style(Color("#38596c"));toast_style.content_margin_top=8;toast_style.content_margin_bottom=8;toast_card.add_theme_stylebox_override("panel",toast_style)
	toast_card.mouse_filter=Control.MOUSE_FILTER_IGNORE;toast_card.add_child(toast);_place(toast_card,35,216,-35,276);toast_card.visible=false
	task_card=_panel(PAPER);_bottom(task_card,20,-282,-20,-114)
	var col:=_column(task_card,7);var heading:=_row(col,10)
	task_count=_label("",13,Color("#54847e"));task_count.size_flags_horizontal=Control.SIZE_EXPAND_FILL;heading.add_child(task_count)
	progress=ProgressBar.new();progress.show_percentage=false;progress.custom_minimum_size=Vector2(120,7);progress.size_flags_vertical=Control.SIZE_SHRINK_CENTER;heading.add_child(progress);_progress_skin(progress)
	var task_row:=_row(col,12);var text:=_column(task_row,5);text.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	task_title=_wrap("",23);task_title.max_lines_visible=2;text.add_child(task_title)
	task_detail=_wrap("",16,MUTED);task_detail.max_lines_visible=2;text.add_child(task_detail)
	task_button=_button("IR",game.follow_task,GOLD,18);task_button.custom_minimum_size=Vector2(156,79);task_row.add_child(task_button)
	var nav:=HBoxContainer.new();nav.add_theme_constant_override("separation",10);_bottom(nav,20,-94,-20,-20)
	for item in [["CENTRAR",Callable(self,"home"),"home"],["TALLER",Callable(self,"show_market"),"team"],["RUTA",Callable(self,"show_route"),"route"]]:
		var button:=_button(item[0],item[1],NAVY,18);button.size_flags_horizontal=Control.SIZE_EXPAND_FILL;nav.add_child(button)
		nav_buttons[item[2]]=button
		if item[0]=="RUTA":route_button=button
	move_hint=_panel(PAPER);var hint_style:=_style(PAPER,10);hint_style.content_margin_left=8;hint_style.content_margin_right=8;hint_style.content_margin_top=4;hint_style.content_margin_bottom=4;hint_style.shadow_size=2
	move_hint.add_theme_stylebox_override("panel",hint_style);move_hint.mouse_filter=Control.MOUSE_FILTER_IGNORE;root.add_child(move_hint);move_hint.add_child(_label("DESLIZÁ PARA MOVERTE",12,INK))
	move_hint.anchor_top=1;move_hint.anchor_bottom=1;move_hint.offset_left=22;move_hint.offset_right=212;move_hint.offset_top=-548;move_hint.offset_bottom=-520
	camera_button=_button("VER PUEBLO",game.toggle_camera_view,NAVY,16);root.add_child(camera_button)
	camera_button.anchor_left=1;camera_button.anchor_right=1;camera_button.anchor_top=1;camera_button.anchor_bottom=1
	camera_button.offset_left=-188;camera_button.offset_right=-22;camera_button.offset_top=-620;camera_button.offset_bottom=-556
	run_button=_button("CORRER",func():pass,GOLD,17);root.add_child(run_button)
	run_button.anchor_left=1;run_button.anchor_right=1;run_button.anchor_top=1;run_button.anchor_bottom=1
	run_button.offset_left=-188;run_button.offset_right=-22;run_button.offset_top=-538;run_button.offset_bottom=-474
	run_button.button_down.connect(game.begin_sprint);run_button.button_up.connect(game.end_sprint)
	work_button=_button("ACERCATE",func():pass,GOLD,18);root.add_child(work_button)
	work_button.anchor_left=1;work_button.anchor_right=1;work_button.anchor_top=1;work_button.anchor_bottom=1
	work_button.offset_left=-232;work_button.offset_right=-22;work_button.offset_top=-452;work_button.offset_bottom=-356
	work_button.button_down.connect(game.begin_work);work_button.button_up.connect(game.end_work)
	work_hint=_wrap("",13,INK);root.add_child(work_hint);work_hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;work_hint.max_lines_visible=2
	work_hint.anchor_left=1;work_hint.anchor_right=1;work_hint.anchor_top=1;work_hint.anchor_bottom=1;work_hint.offset_left=-260;work_hint.offset_right=-22;work_hint.offset_top=-350;work_hint.offset_bottom=-312
	for product in game.market.PRODUCTS:
		var button:=_button("",Callable(game,"focus_trade_counter").bind(product),TEAL if product=="wood" else Color("#a6634e"),17)
		button.custom_minimum_size=Vector2(192,64);button.size=Vector2(192,64)
		var style:=_style(TEAL if product=="wood" else Color("#a6634e"),12);style.set_content_margin_all(7);style.shadow_size=4;button.add_theme_stylebox_override("normal",style)
		var sign_col:=VBoxContainer.new();sign_col.mouse_filter=Control.MOUSE_FILTER_IGNORE;button.add_child(sign_col);sign_col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var title:=_label("",18,Color("#fff0ce"));title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;sign_col.add_child(title)
		var detail:=_label("",13,Color("#edf2e9"));detail.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;sign_col.add_child(detail)
		root.add_child(button);market_labels[product]={"button":button,"title":title,"detail":detail}
	for id in state.BUILDINGS:
		var button:=_button("",Callable(self,"show_building").bind(id),Color("#e8efec"),13)
		button.add_theme_color_override("font_color",INK);button.custom_minimum_size=Vector2(146,37);button.size=Vector2(146,37)
		var style:=_style(Color("#e8efec"),10);style.content_margin_left=8;style.content_margin_right=8;style.content_margin_top=5;style.content_margin_bottom=5;style.shadow_size=3;button.add_theme_stylebox_override("normal",style)
		root.add_child(button);placards[id]=button
	modal=ColorRect.new();modal.color=Color(.04,.10,.16,.54);modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);root.add_child(modal);modal.visible=false
	modal.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:close()
		elif event is InputEventScreenTouch and event.pressed:close())
	refresh(0)

func _progress_skin(bar: ProgressBar) -> void:
	var bg:=_style(Color("#d5dfdb"),6);bg.set_content_margin_all(0);bg.shadow_size=0;bg.set_border_width_all(0)
	var fill:=bg.duplicate() as StyleBoxFlat;fill.bg_color=TEAL
	bar.add_theme_stylebox_override("background",bg);bar.add_theme_stylebox_override("fill",fill);bar.max_value=1

func notice(text: String) -> void:
	toast.text=text;toast.get_parent().visible=true;toast_time=4.0
func close() -> void:
	modal.visible=false;view="";selected="";pending_building="";game.clear_controls();game.sync_controls()
func home() -> void:
	close();game.center_camera()

func _sheet(title: String,subtitle: String="") -> void:
	if modal_card!=null:modal.remove_child(modal_card);modal_card.queue_free()
	refs.clear();worker_rows.clear();goal_rows.clear();route_rows.clear();shop_rows.clear();build_bar=null
	modal_card=_panel(PAPER);modal.add_child(modal_card);modal_card.anchor_left=.035;modal_card.anchor_right=.965;modal_card.anchor_top=.10;modal_card.anchor_bottom=.92
	modal_card.mouse_filter=Control.MOUSE_FILTER_STOP
	var col:=_column(modal_card,14);var header:=_row(col,8);var names:=_column(header,4);names.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	modal_heading=_wrap(title,28);names.add_child(modal_heading);modal_subtitle=_wrap(subtitle,16,MUTED);names.add_child(modal_subtitle)
	var exit_button:=_button("×",close,NAVY,28);exit_button.custom_minimum_size=Vector2(60,60);header.add_child(exit_button)
	var scroll:=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;col.add_child(scroll)
	listing=_column(scroll,14);listing.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var footer:=_button("VOLVER AL REFUGIO",close,TEAL,19);col.add_child(footer)
	modal.visible=true;game.clear_controls();game.sync_controls()
func _info_card(title: String,detail: String="",color_: Color=Color("#e1e9e4")) -> VBoxContainer:
	var card:=_panel(color_);listing.add_child(card);var col:=_column(card,7)
	col.add_child(_wrap(title,22));if not detail.is_empty():col.add_child(_wrap(detail,17,MUTED))
	return col
func _cost_row(price: Dictionary,parent: Node) -> void:
	var row:=_row(parent,8)
	for key in price:
		var cell:=_column(row,4);cell.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		var top:=_row(cell,6);top.add_child(_icon(key,29));var count:=_label("",18);top.add_child(count)
		count.set_meta("resource",key);count.set_meta("cost",int(price[key]));refs["cost:"+key]=count
		cell.add_child(_label(state.RESOURCE_NAMES[key],13,MUTED))

func show_building(id: String) -> void:
	if not state.BUILDINGS.has(id):return
	view="building";selected=id;pending_building=""
	_sheet(state.BUILDINGS[id]["name"],state.NAMES[state.city]+" · NIVEL %d" % state.level(id))
	# A building sheet leaves the upper settlement visible on tall phones.
	modal_card.anchor_top=.35
	listing.add_child(_wrap(state.BUILDINGS[id]["why"],18,MUTED))
	var status_card:=_info_card("ESTADO DEL EDIFICIO")
	refs["status"]=_wrap("",20);status_card.add_child(refs["status"])
	build_bar=ProgressBar.new();build_bar.custom_minimum_size.y=9;build_bar.show_percentage=false;_progress_skin(build_bar);status_card.add_child(build_bar)
	if id=="core":
		refs["heat"]=_wrap("",18);status_card.add_child(refs["heat"])
		refs["boost"]=_button("",func():state.heat_boost=not state.heat_boost;game.save();refresh(0),NAVY,18);status_card.add_child(refs["boost"])
	if state.BUILDINGS[id].has("resource") and state.level(id)>0:
		_add_worker_row(id,listing)
	if state.level(id)<8 and (id!="core" or state.lit):
		var upgrade:=_info_card("SIGUIENTE MEJORA · NIVEL %d" % (state.level(id)+1))
		if state.cost(id).is_empty():upgrade.add_child(_wrap("Incluido en el kit de fundación · sin costo",17,TEAL))
		_cost_row(state.cost(id),upgrade)
		refs["reason"]=_wrap("",16,MUTED);upgrade.add_child(refs["reason"])
	refs["upgrade"]=_button("",_upgrade_action,GOLD);listing.add_child(refs["upgrade"])
	if id=="dock":listing.add_child(_button("VER EXPEDICIONES",show_fleet,NAVY,19))
	if id=="shelter":listing.add_child(_button("RECIBIR Y ASIGNAR HABITANTES",show_team,NAVY,18))
	game.focus_building(id);refresh(0)

func _upgrade_action() -> void:
	if selected=="core" and not state.lit:
		state.ignite();game.save();show_building("core");return
	var blocker: String=state.blocking_requirement(selected)
	if not blocker.is_empty():show_building(blocker);return
	if state.start_upgrade(selected):game.save();refresh(0)

func _add_worker_row(id: String,parent: Node) -> void:
	var panel:=_panel(Color("#e2e9e4"));parent.add_child(panel);var col:=_column(panel,9)
	col.add_child(_wrap(state.BUILDINGS[id]["name"],20))
	var top:=_row(col,9);var info:=_column(top,3);info.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var count:=_label("",18);info.add_child(count);var rate:=_wrap("",15,MUTED);info.add_child(rate)
	var minus:=_button("−",func():if state.assign(id,-1):game.save();refresh(0),NAVY,27);minus.custom_minimum_size=Vector2(64,62);top.add_child(minus)
	var plus:=_button("+",func():if state.assign(id,1):game.save();refresh(0),TEAL,27);plus.custom_minimum_size=Vector2(64,62);top.add_child(plus)
	worker_rows[id]={"count":count,"rate":rate,"minus":minus,"plus":plus}

func show_team() -> void:
	view="team";selected="";_sheet("Tu gente, tu refugio","Asigná habitantes a cada trabajo. Podés retirarlos y cambiarlos de edificio.")
	var census:=_info_card("HABITANTES DEL REFUGIO")
	refs["census"]=_wrap("",24);census.add_child(refs["census"])
	refs["free"]=_wrap("",17,MUTED);census.add_child(refs["free"])
	refs["family"]=_button("",func():if state.receive_family():game.save();refresh(0),GOLD,19);census.add_child(refs["family"])
	refs["family_hint"]=_wrap("",15,MUTED);census.add_child(refs["family_hint"])
	_info_card("ALMACÉN DEL REFUGIO",state.cost_text(state.resources))
	for id in state.BUILDINGS:
		if state.BUILDINGS[id].has("resource") and state.level(id)>0:_add_worker_row(id,listing)
	listing.add_child(_button("MEJORAR LOS HOGARES",Callable(self,"show_building").bind("shelter"),NAVY,18))
	refresh(0)

func show_route() -> void:
	view="route";selected="";_sheet("Tu ruta comercial","Vendé, contratá al equipo y completá las vías. El mercado anterior sigue trabajando cuando viajás.")
	var next: int=mini(state.unlocked+1,5)
	var preview:=_info_card("PRÓXIMO: "+state.NAMES[next] if state.unlocked<5 else "LA RED DE PUERTO AURORA",state.LESSONS[next])
	refs["next_progress"]=_wrap("",20);preview.add_child(refs["next_progress"])
	var route_goals: Array[Dictionary]=game.market.goals(state.unlocked)
	for goal in route_goals:
		var row:=_row(preview,10);var badge:=_label("",18,TEAL);badge.custom_minimum_size.x=40;row.add_child(badge)
		var text:=_wrap(goal["title"],17);row.add_child(text);var count:=_label("",17);row.add_child(count)
		goal_rows.append({"id":goal["id"],"badge":badge,"count":count})
	if state.city==state.unlocked and state.city<5:
		refs["charter"]=_wrap("",18,TEAL);preview.add_child(refs["charter"])
		refs["open"]=_button("",func():if game.open_trade_route():show_route(),GOLD,19);preview.add_child(refs["open"])
	for index in range(state.NAMES.size()):
		var card:=_info_card("%02d  %s" % [index+1,state.NAMES[index]],state.LESSONS[index],Color("#e3e9e5") if index<=state.unlocked else Color("#e1e5e6"))
		var available: bool=index<=state.unlocked
		if index==state.city:card.add_child(_label("ESTÁS AQUÍ",15,TEAL))
		elif available:
			card.add_child(_button("VIAJAR A "+state.NAMES[index].to_upper(),Callable(game,"travel").bind(index),TEAL,18))
		else:card.add_child(_wrap("Completá las cuatro metas comerciales de "+state.NAMES[index-1]+". El pasaje cuesta %d monedas." % game.market.charter_price(index-1),16,MUTED))
	refresh(0)

func show_market(highlight: String="") -> void:
	view="market";selected=highlight;_sheet("Taller y ferrocarril","Los trabajadores cosechan y llevan la carga al depósito. El tren la entrega a los puestos y los clientes pagan.")
	shop_balance=_label("",24,TEAL);listing.add_child(shop_balance)
	var ids: Array[String]=["lumberjack","hunter","rail","tool","pack","train","supplies"]
	if highlight in ids:ids.erase(highlight);ids.push_front(highlight)
	for id in ids:
		var card:=_info_card("", "",Color("#f0e4c8") if id==highlight else Color("#e1e9e4"))
		var title: Label=card.get_child(0);var detail:=_wrap("",17,MUTED);card.add_child(detail)
		var reason:=_wrap("",16,TEAL);card.add_child(reason)
		var button:=_button("",Callable(game,"buy_market").bind(id),GOLD,18);card.add_child(button)
		shop_rows[id]={"title":title,"detail":detail,"reason":reason,"button":button}
	listing.add_child(_button("HABITANTES Y EDIFICIOS",show_team,NAVY,18))
	refresh(0)

func _refresh_market() -> void:
	var market=game.market;var data: Dictionary=market.town(state.city)
	shop_balance.text="%d MONEDAS · %d PRODUCTOS VENDIDOS" % [market.coins,market.sold_total(state.city)]
	for id in shop_rows:
		var row: Dictionary=shop_rows[id];var price: int=market.price(id,state.city);var reason: String=market.buy_reason(id,state.city)
		var title: String="";var detail: String=""
		match id:
			"lumberjack","hunter":
				var level_: int=data["workers"][id]["level"]
				title=("CONTRATAR · "+market.ROLE_NAMES[id].to_upper()) if level_==0 else "%s · NIVEL %d/3" % [market.ROLE_NAMES[id].to_upper(),level_]
				detail="Corta pinos con su hacha y lleva la madera al depósito. El personaje sigue bajo tu control." if id=="lumberjack" else "Caza osos polares con su hoz y lleva la carne al depósito. Las mejoras aceleran su recorrido y sus golpes."
			"rail":
				title="FERROCARRIL · %d/3 TRAMOS" % data["rails"]
				detail=["Tramo 1: depósito y puestos de venta.","Tramo 2: curva y vía de regreso.","Tramo 3: cerrá el circuito y estrená tu tren de carga.","Tren activo: carga en el depósito y descarga en ambos puestos. Los clientes compran esa mercancía."][int(data["rails"])]
			"tool":title="HACHA Y HOZ · NIVEL %d/3" % data["tool"];detail="Más daño por golpe. Seguí acercándote y manteniendo pulsado para trabajar."
			"pack":title="MOCHILA · %d ESPACIOS" % market.bag_capacity();detail="Ocho espacios más por mejora. La madera y la carne comparten capacidad."
			"train":title="TREN · NIVEL %d/3" % data["train_level"];detail="Más velocidad y seis espacios adicionales por producto en cada viaje."
			"supplies":title="ABASTECER EL REFUGIO";detail="80 madera, 50 comida y 30 carbón para construir edificios. Esta compra no se revende en los puestos."
		row["title"].text=title;row["detail"].text=detail;row["reason"].text="Disponible · %d monedas" % price if reason.is_empty() else reason
		row["button"].text="CIRCUITO COMPLETO" if id=="rail" and market.operating(state.city) else ("CONTRATAR" if id in market.ROLE_NAMES and int(data["workers"][id]["level"])==0 else "CONSTRUIR TRAMO" if id=="rail" else "COMPRAR MEJORA")+" · %d" % price
		row["button"].disabled=not reason.is_empty()

func show_fleet() -> void:
	view="fleet";selected="";_sheet("Expediciones","Dos habitantes salen de viaje. El cargamento se recibe al terminar, una sola vez.")
	refs["voyage"]=_wrap("",20);listing.add_child(refs["voyage"])
	if state.level("dock")==0:
		listing.add_child(_wrap("Construí un muelle con el corazón térmico en nivel 4.",18,MUTED));listing.add_child(_button("VER MUELLE",Callable(self,"show_building").bind("dock"),GOLD));return
	for index in range(state.ROUTES.size()):
		var route: Dictionary=state.ROUTES[index]
		var card:=_info_card(route["name"],route["detail"])
		card.add_child(_wrap("Viaje: %d s · Costo: %s" % [state.expedition_time(index),state.cost_text(route["cost"])],17,MUTED))
		card.add_child(_wrap("Recibís: "+state.cost_text(route["reward"])+(" y 2 habitantes, si hay lugar" if route.has("people") else ""),18))
		var button:=_button("",Callable(self,"_send_route").bind(index),GOLD,18);card.add_child(button);route_rows.append({"index":index,"button":button})
	refresh(0)
func _send_route(index: int) -> void:
	if state.start_expedition(index):game.save();refresh(0)

func show_menu() -> void:
	view="menu";selected="";_sheet("Tu aventura","Wivori Trails · Mercado del Norte · 0.22.0")
	_info_card("Cosechá, vendé y automatizá","Cortá pinos con el hacha y cazá osos polares con la hoz, manteniendo el botón de acción. Llevá la carga a los clientes. Comprá un leñador, un cazador y tres tramos de vías desde TALLER.")
	listing.add_child(_button("TALLER Y FERROCARRIL",show_market,TEAL,18))
	listing.add_child(_button("HABITANTES Y EDIFICIOS",show_team,NAVY,18))
	_info_card("Movete y construí","Usá el joystick de la izquierda para caminar. Mantené CORRER con otro dedo para acelerar. Tocá un edificio para mejorarlo o asignar habitantes.")
	_info_card("Cámara libre","Arrastrá el terreno para mirar otra zona y pellizcá para acercarte. CENTRAR vuelve a seguir al personaje. VER PUEBLO abre la vista general; el joystick sigue disponible.")
	listing.add_child(_button("EXPEDICIONES",show_fleet,NAVY,19))
	_info_card("Tu archipiélago anterior","Tus monedas, edificios y mapas de la partida anterior se conservan. Podés seguir jugándola y volver al refugio desde MAPA Y META.")
	listing.add_child(_button("CONTINUAR MI ARCHIPIÉLAGO",game.open_archipelago,NAVY,18))
	_info_card("Producción cuando volvés","Los habitantes trabajan durante tu ausencia, hasta dos horas. Las construcciones y expediciones también terminan. No hay robos ni ventiscas fuera de pantalla.")
	listing.add_child(_label("Un jugador · Sin compras en esta versión",15,MUTED))

func refresh(delta: float) -> void:
	toast_time=maxf(0,toast_time-delta)
	if toast_time<=0:toast.get_parent().visible=false
	for key in resource_labels:
		var number: float=float(game.market.coins) if key=="coins" else float(game.market.bag[key]);resource_labels[key].text=("%.1f mil" % (number/1000.0)) if number>=10000 else str(floori(number))
	city_name.text=state.NAMES[state.city];chapter.text="REFUGIO\n%02d / 06" % (state.city+1)
	weather.text="MOCHILA %d / %d" % [game.market.bag_count(),game.market.bag_capacity()]
	comfort.text="VENDIDO %d · VÍAS %d/3" % [game.market.sold_total(state.city),game.market.town(state.city)["rails"]]
	var task: Dictionary=game.current_task()
	task_count.text="%s · %d/4 METAS" % ["PRÓXIMO: "+state.NAMES[state.city+1].to_upper() if state.city<5 else "META: RED COMERCIAL",game.market.goal_progress(state.city)]
	progress.value=float(game.market.goal_progress(state.city))/4.0
	task_title.text=task["title"];task_detail.text=task["detail"];task_button.text=task["button"]
	route_button.text="RUTA · %d/6" % (state.unlocked+1)
	camera_button.text="SEGUIRME" if game.camera_detached else "VER MERCADO" if game.hero.position.z>14 else "VER PUEBLO"
	var context: Dictionary=game.market.context(game.hero.position,state.city)
	work_button.text={"harvest":"HACHA\nCORTAR PINO" if context.get("product","")=="wood" else "HOZ\nCAZAR OSO","deliver":"ENTREGAR\n"+("MADERA" if context.get("product","")=="wood" else "CARNE"),"load":"CARGAR\nMOCHILA","walk":"ACERCATE"}[context["kind"]]
	if context["kind"]=="harvest" and not context["enabled"]:work_button.text="VENDÉ\nTU CARGA"
	work_button.disabled=not context["enabled"];work_hint.text=context["detail"];work_hint.visible=not modal.visible
	task_button.self_modulate=Color.WHITE.lerp(Color("#ffe19b"),.32+.25*sin(game.elapsed*4.0)) if task["action"]=="shop" and task.has("buy") else Color.WHITE
	if not modal.visible:return
	if not pending_building.is_empty():
		var held: bool=Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		for node in modal.find_children("*","Button",true,false):
			if node is Touch and node.is_visible_in_tree() and node.touch_index>=0:held=true;break
		if not held:
			var id: String=pending_building;pending_building="";show_building(id);return
		if refs.has("upgrade"):refs["upgrade"].disabled=true
		return
	for key in refs:
		if key.begins_with("cost:"):
			var label: Label=refs[key];var resource: String=label.get_meta("resource");var need: int=label.get_meta("cost")
			label.text="%d/%d" % [mini(floori(float(state.resources[resource])),need),need]
			label.add_theme_color_override("font_color",TEAL if float(state.resources[resource])>=need else Color("#a05843"))
	for id in worker_rows:
		var row: Dictionary=worker_rows[id];var count: int=state.worker_count(id)
		row["count"].text="%d/%d trabajando" % [count,state.max_workers(id)]
		row["rate"].text="+%.1f %s / min" % [state.production(id)*60.0,state.RESOURCE_NAMES[state.BUILDINGS[id]["resource"]].to_lower()]
		if id=="factory" and count>0 and state.production(id)==0:row["rate"].text="En pausa: faltan madera o carbón"
		row["minus"].disabled=count==0;row["plus"].disabled=count>=state.max_workers(id) or state.free_workers()==0
	if view=="building":_refresh_building()
	elif view=="team":
		refs["census"].text="%d / %d habitantes" % [state.town()["people"],state.capacity()]
		refs["free"].text="%d sin asignar · %d trabajando o de expedición" % [state.free_workers(),state.used_workers()]
		var full: bool=int(state.town()["people"])+2>state.capacity()
		refs["family"].text="HOGARES LLENOS" if full else "LLEGAN EN %d s" % ceili(state.family_cooldown) if state.family_cooldown>0 else "RECIBIR FAMILIA · 12 COMIDA"
		refs["family"].disabled=full or state.family_cooldown>0 or float(state.resources["food"])<12 or not state.lit
		refs["family_hint"].text="Mejorá los hogares para recibir más familias." if full else "Cada familia aporta dos personas. Cambiá los trabajos con − y +."
	elif view=="route":
		refs["next_progress"].text="%s · %d/4 metas comerciales" % [state.NAMES[state.unlocked],game.market.goal_progress(state.unlocked)]
		var goals: Array[Dictionary]=game.market.goals(state.unlocked)
		for row in goal_rows:
			for goal in goals:
				if goal["id"]!=row["id"]:continue
				var done: bool=int(goal["value"])>=int(goal["goal"]);row["badge"].text="✓" if done else "○";row["count"].text="%d/%d" % [mini(int(goal["value"]),int(goal["goal"])),goal["goal"]]
		if refs.has("open"):
			var ready: bool=game.route_can_open()
			refs["charter"].text="Pasaje: %d / %d monedas. Los cuatro hitos de arriba son los únicos requisitos comerciales." % [game.market.coins,game.market.charter_price(state.city)]
			refs["open"].text="ABRIR "+state.NAMES[state.city+1].to_upper() if ready else "REUNÍ %d MONEDAS PARA VIAJAR" % game.market.charter_price(state.city) if game.market.charter_ready(state.city) else "COMPLETÁ LAS CUATRO METAS"
			refs["open"].disabled=not ready
	elif view=="market":_refresh_market()
	elif view=="fleet":
		refs["voyage"].text="%s · %d s restantes" % [state.ROUTES[int(state.expedition["index"])]["name"],ceili(float(state.expedition["remaining"]))] if not state.expedition.is_empty() else "Elegí una ruta · %d/3 distintas completadas" % state.completed_routes.size()
		for row in route_rows:
			var route: Dictionary=state.ROUTES[row["index"]]
			row["button"].text="ENVIAR · %d s%s" % [state.expedition_time(row["index"])," · YA EXPLORADA" if route["id"] in state.completed_routes else ""]
			row["button"].disabled=not state.expedition.is_empty() or state.free_workers()<2 or not state.affordable(route["cost"])

func _refresh_building() -> void:
	var id: String=selected;var level_: int=state.level(id)
	modal_subtitle.text=state.NAMES[state.city]+" · NIVEL %d" % level_
	var working: bool=not state.construction.is_empty() and int(state.construction["city"])==state.city and state.construction["id"]==id
	build_bar.visible=working
	if working:
		refs["status"].text="Construyendo · %d s" % ceili(float(state.construction["remaining"]))
		build_bar.value=1.0-float(state.construction["remaining"])/float(state.construction["duration"])
	elif level_==0:refs["status"].text="Solar disponible · construí para activarlo"
	elif id=="shelter":refs["status"].text="%d habitantes · %d plazas" % [state.town()["people"],state.capacity()]
	elif state.BUILDINGS[id].has("resource"):refs["status"].text="+%.1f %s por minuto" % [state.production(id)*60.0,state.RESOURCE_NAMES[state.BUILDINGS[id]["resource"]].to_lower()]
	else:refs["status"].text="Edificio activo · nivel %d" % level_
	if id=="core":
		refs["heat"].text="Calor %d%% · Carbón: %.1f por minuto" % [roundi(state.warmth()),.035*float(level_)*60.0*(2.8 if state.heat_boost else 1.0) if level_>=2 else 0.0]
		refs["boost"].text="CALOR INTENSO: ACTIVADO" if state.heat_boost else "ACTIVAR CALOR INTENSO"
		refs["boost"].disabled=not state.lit
	var reason: String=state.upgrade_reason(id)
	if refs.has("reason"):refs["reason"].text="Recursos listos. La obra tarda %d segundos." % (4+(level_+1)*2+state.city) if reason.is_empty() else reason
	var button: Button=refs["upgrade"]
	if id=="core" and not state.lit:button.text="ENCENDER EL CORAZÓN";button.disabled=false
	elif level_>=8:button.text="NIVEL MÁXIMO";button.disabled=true
	elif not state.blocking_requirement(id).is_empty():button.text="VER REQUISITO";button.disabled=false
	else:button.text="EN CONSTRUCCIÓN…" if working else "CONSTRUIR" if level_==0 else "MEJORAR A NIVEL %d" % (level_+1);button.disabled=not reason.is_empty()
