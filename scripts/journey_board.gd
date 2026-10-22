extends RefCounted

# A readable destination preview and a live checklist, without rebuilding
# buttons underneath a held finger when money or production changes.
var route
var rows: Dictionary={}
var bar: ProgressBar
var count_label: Label
var area:=0

func render(source: Node3D) -> void:
	route=source;rows.clear();area=route.campaign.frontier_area()
	var hud=route.g.hud
	var card: PanelContainer=hud.panel(Color("#e4eee3"));route.listing.add_child(card)
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",9);card.add_child(column)
	var next_area: int=mini(area+1,5)
	var can_visit: bool=route.region<area
	var preview_area: int=area if can_visit else next_area
	column.add_child(hud.label("DESTINO DISPONIBLE · EMBARCÁ" if can_visit else "PRÓXIMO DESTINO · %d/6" % (next_area+1) if area<5 else "LA META DEL ARCHIPIÉLAGO",14,Color("#28736b")))
	var top:=HBoxContainer.new();top.add_theme_constant_override("separation",14);column.add_child(top)
	var title: Label=hud.label(route.NAMES[preview_area] if area<5 or can_visit else "Tu red comercial",31)
	title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;top.add_child(title)
	var preview:=TextureRect.new()
	preview.texture=load("res://assets/ui/buildings/%s.png" % ["greenhouse","mill","house","depot","watchtower","watchtower"][area])
	preview.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;preview.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;preview.custom_minimum_size=Vector2(116,86);top.add_child(preview)
	var reward: Label=hud.label(route.Campaign.MAP_LESSONS[preview_area] if area<5 or can_visit else "Completá una expedición de cada tipo para conectar tus seis pueblos.",18)
	reward.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;column.add_child(reward)
	count_label=hud.label("",17,Color("#397366"));column.add_child(count_label)
	bar=hud.progress();bar.custom_minimum_size.y=10;column.add_child(bar)
	if route.region<area:
		route._button("VIAJAR A "+route.NAMES[area].to_upper(),Callable(route,"plan_travel").bind(area))
	else:
		route._button("SEÑALAR MI SIGUIENTE PASO",Callable(route,"guide_campaign"))
	if not route.ferry:
		route._text("Estos 5 hitos abren Villa Miga. No necesitás alcanzar un nivel específico ni maximizar las defensas.",17)
	else:
		route._text("Para avanzar desde "+route.NAMES[area]+":",20)
	var steps: Array[Dictionary]=route.campaign.steps(area)
	for index in range(steps.size()):
		var step: Dictionary=steps[index]
		var row:=HBoxContainer.new();row.add_theme_constant_override("separation",13);route.listing.add_child(row)
		var badge: Label=hud.label("",15,Color("#28736b"));badge.custom_minimum_size=Vector2(48,45);badge.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;badge.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;row.add_child(badge)
		var content:=VBoxContainer.new();content.size_flags_horizontal=Control.SIZE_EXPAND_FILL;content.add_theme_constant_override("separation",3);row.add_child(content)
		var heading: Label=hud.label(step["title"],20);heading.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;content.add_child(heading)
		var detail: Label=hud.label(step["detail"],15,Color("#5b7273"));detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;content.add_child(detail)
		var status: Label=hud.label("",16,Color("#28736b"));content.add_child(status)
		rows[step["id"]]={"badge":badge,"status":status,"heading":heading,"index":index+1}
	route._text("Mejoras extra para volver cuando quieras",22)
	route._text("Más empleados, niveles adicionales, mochila, velocidad y defensas amplían tu negocio. El siguiente destino depende únicamente de los hitos de arriba.",17)
	if route.away():route._button("VER PRODUCCIÓN Y MEJORAS",Callable(route,"open_production"))
	else:route._button("VER MEJORAS DEL MERCADO",Callable(route.g,"_toggle_shop"))
	route._text("TUS SEIS PUEBLOS",24)
	for index in range(route.NAMES.size()):
		var locked: bool=index>route.unlocked()
		route._text("%02d · %s" % [index+1,route.NAMES[index]],21)
		if locked:
			route._text("Completá los hitos de "+route.NAMES[index-1]+" para abrir este destino.",16)
		elif index==route.region:route._text("ESTÁS AQUÍ · "+route.campaign.status(index),16,Color("#28736b"))
		else:route._button("VIAJAR A "+route.NAMES[index].to_upper(),Callable(route,"plan_travel").bind(index))
	if route.region==0:route._button("MISIONES OPCIONALES DEL MERCADO",Callable(route,"guide_market"))
	if route.g.milestone!=null and not route.g.milestone.pending.is_empty():route._button("DIARIO DE DESCUBRIMIENTOS",func():route.close_board();route.g.milestone.show_next())
	refresh()

func refresh() -> void:
	if route==null or route.board_tab!=0 or not route.board_visible() or not is_instance_valid(bar):return
	var all_steps: Array[Dictionary]=route.campaign.steps(area)
	bar.max_value=1.0;bar.value=route.campaign.progress(area)
	count_label.text="%s · %d/%d hitos" % [route.NAMES[mini(area+1,5)],route.campaign.done_count(area),all_steps.size()]
	for step in all_steps:
		if not rows.has(step["id"]):continue
		var row: Dictionary=rows[step["id"]]
		var done: bool=step["done"]
		row["badge"].text="OK" if done else "%02d" % row["index"]
		row["badge"].add_theme_color_override("font_color",Color("#28736b") if done else Color("#9a682e"))
		row["status"].text="COMPLETADO" if done else "%d / %d" % [step["value"],step["goal"]] if step["goal"]>1 else "PENDIENTE"
		if step["kind"]=="ferry" and not done:
			row["status"].text="Faltan %d monedas" % maxi(0,route.Campaign.FERRY_COST-route.g.coins) if route.g.coins<route.Campaign.FERRY_COST else "Monedas listas · completá los hitos anteriores" if not route.campaign.home_ready() else "¡LISTO! Andá al barco y tocá PREPARAR"
