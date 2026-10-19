extends Node3D
class_name WivoriWorkOrders

const Art=preload("res://scripts/art_library.gd")
const Store=preload("res://scripts/save_store.gd")
const DISPATCH=Vector3(-4.8,0,17)
const RECIPES={
	"jam":{"name":"Compota del valle","building":"bakery","ingredients":{"berry":3,"apple":2},"seconds":12.0,"pay":210,"level":7,"model":"goods_jam"},
	"snack":{"name":"Merienda de viaje","building":"cafe","ingredients":{"carrot":3,"apple":2},"seconds":16.0,"pay":230,"level":8,"model":"goods_parcel"},
	"basket":{"name":"Cesta del mercado","building":"depot","ingredients":{"tomato":2,"carrot":2,"berry":2},"seconds":20.0,"pay":270,"level":10,"model":"goods_crate"}
}
const REQUIRED={7:"bakery",8:"cafe",9:"watchtower",10:"depot",11:"mill",12:"park"}
var g
var active: Dictionary={}
var jobs: Dictionary={}
var cargo: Dictionary={}
var orders_done:=0
var rush_done:=0
var festival_done:=0
var patrol_wins:=0
var production_level:=0
var recipes_seen: Array[String]=[]
var patrol: Dictionary={}
var board: PanelContainer
var board_scrim: ColorRect
var cards: Dictionary={}
var board_status: Label
var patrol_button: Button
var improve_button: Button
var outputs: Dictionary={}
var parcel: Node3D
var parcel_kind:=""
var visual_wait:=0.0

func _ready() -> void:
	name="Encargos del valle"
	Art.place(self,"premium",DISPATCH+Vector3(0,0,-2.6),Vector3.ONE*.68)
	g.world.navigation.add_obstacle(Rect2(DISPATCH.x-1.7,DISPATCH.z-3.9,3.4,2.0))
	g.world.make_label(self,"ENCARGOS DEL VALLE",DISPATCH+Vector3(0,4.04,-2.6),52)
	for key in RECIPES:
		var output:=Node3D.new();add_child(output)
		Art.place(output,RECIPES[key]["model"],Vector3.ZERO,Vector3.ONE*.8)
		var tag: Label3D=g.world.make_label(output,"",Vector3(0,1.1,0),30)
		outputs[key]={"root":output,"label":tag};output.visible=false

func station(kind: String) -> Vector3:
	var index: int=g.town.constructed.find(RECIPES[kind]["building"])
	return g.town.LOCATIONS[index]+Vector3(0,0,3.2) if index>=0 else DISPATCH
func ingredient_text(kind: String) -> String:
	var parts: PackedStringArray=[]
	for item in RECIPES[kind]["ingredients"]:parts.append("%d %s" % [RECIPES[kind]["ingredients"][item],g.CROP_NAMES[item]])
	return " + ".join(parts)
func available(kind: String) -> bool:
	for item in RECIPES[kind]["ingredients"]:
		if g.stash[item]+g.counter[item]<RECIPES[kind]["ingredients"][item]:return false
	return true
func has_ready() -> bool:
	for job in jobs.values():
		if job["ready"]:return true
	return false
func cargo_total() -> int:
	var result:=0
	for amount in cargo.values():result+=int(amount)
	return result
func accept(kind: String,express: bool=false) -> bool:
	if not RECIPES.has(kind) or not active.is_empty() or g.run.level<RECIPES[kind]["level"] or express and g.run.level<8:return false
	active={"recipe":kind,"express":express,"remaining":100.0,"late":false};close_board()
	g._notice("ENCARGO ELEGIDO\n"+RECIPES[kind]["name"],2);g._save_progress();g._refresh_ui();return true
func start_batch(kind: String) -> bool:
	if not RECIPES.has(kind) or jobs.has(kind) or g.run.level<RECIPES[kind]["level"]:return false
	if not g.town.has_building(RECIPES[kind]["building"]) or g.player.position.distance_to(station(kind))>2.4 or not available(kind):return false
	for item in RECIPES[kind]["ingredients"]:
		var needed: int=RECIPES[kind]["ingredients"][item]
		var carried: int=mini(needed,g.stash[item]);g.stash[item]-=carried;g.counter[item]-=needed-carried
	jobs[kind]={"remaining":RECIPES[kind]["seconds"]*pow(.8,production_level),"ready":false}
	g.player.set_carry(g._total_bag());g.player.act("build")
	g._animate_goods(g.run.STOCK,station(kind),5,Color("#daa35b"),"apple")
	g._notice("EN PREPARACIÓN\n"+RECIPES[kind]["name"],1.5);g._save_progress();g._refresh_ui();return true
func pickup(kind: String) -> bool:
	if not jobs.has(kind) or not jobs[kind]["ready"] or cargo_total()>=3 or g.player.position.distance_to(station(kind))>2.4:return false
	jobs.erase(kind);cargo[kind]=int(cargo.get(kind,0))+1;g.player.act("collect");_update_visuals()
	g._fly_model_goods(RECIPES[kind]["model"],station(kind)+Vector3(0,1.15,0),g.player.position+Vector3(0,1.3,0),1,g.player)
	g._notice("LOTE RECOGIDO\nLlevalo al despacho del valle.",2);g._save_progress();g._refresh_ui();return true
func deliver() -> bool:
	if active.is_empty() or g.player.position.distance_to(DISPATCH)>2.6:return false
	var kind: String=active["recipe"]
	if int(cargo.get(kind,0))<=0:return false
	var fast: bool=active["express"] and not active["late"]
	var income: int=RECIPES[kind]["pay"]+(90 if fast else 0)
	cargo[kind]-=1;orders_done+=1
	if fast:rush_done+=1
	if g.run.level>=12:festival_done+=1
	if not recipes_seen.has(kind):recipes_seen.append(kind)
	active={};g._fly_model_goods(RECIPES[kind]["model"],g.player.position+Vector3(0,1.1,0),DISPATCH+Vector3(0,1.2,0),1)
	g._record_sale(1,income,DISPATCH+Vector3(0,1.4,0));g.player.act("deliver");_update_visuals()
	g.world.sale_receipt(DISPATCH,income)
	g._notice("¡ENCARGO ENTREGADO!\n+%d en caja%s" % [income," · extra de rapidez" if fast else ""],2.2)
	g._save_progress();g._refresh_ui();return true
func upgrade_production() -> bool:
	var cost:=360+production_level*300
	if g.run.level<10 or production_level>=2 or g.coins<cost:return false
	g.coins-=cost;production_level+=1;g.player.act("build")
	g._notice("TALLERES MEJORADOS\nLos siguientes lotes tardan un 20 % menos.",2);g._save_progress();refresh_board();g._refresh_ui();return true
func start_patrol() -> bool:
	if g.run.level<9 or not patrol.is_empty() or not g.run.raiders.is_empty() or g.run.warning>0 or g._total_stock()<4:return false
	patrol={"blocked":g.run.blocked,"manual":g.run.manual_blocked,"lost":g.run.lost,"started":false}
	g.run.next_raid=0;g.run.warning=5+g.town.warning_seconds();close_board()
	g._notice("RONDA DE DEFENSA\nFrená dos; al menos uno personalmente.",2.5);g._save_progress();return true
func _tick_patrol() -> void:
	if patrol.is_empty():return
	if not g.run.raiders.is_empty():patrol["started"]=true
	if not patrol["started"] or not g.run.raiders.is_empty() or g.run.warning>0:return
	var won: bool=g.run.blocked-int(patrol["blocked"])>=2 and g.run.manual_blocked>int(patrol["manual"]) and g.run.lost==int(patrol["lost"])
	patrol={}
	if won:patrol_wins+=1;g._record_sale(0,160);g.player.act("celebrate")
	g._notice("¡RONDA PROTEGIDA!\n+160 en caja." if won else "Podés repetir la ronda.\nInterceptá uno y protegé el almacén.",2.5)
	g._save_progress();g._refresh_ui()
func act(action: String) -> void:
	var kind: String=active.get("recipe","")
	match action:
		"board":toggle_board()
		"prepare":start_batch(kind)
		"pickup":pickup(kind)
		"dispatch":deliver()
		"patrol":start_patrol()
		"build":
			g.town.focus_kind=RECIPES[kind]["building"] if not kind.is_empty() else REQUIRED.get(g.run.level,"")
			if not g.town.in_build_mode:g._toggle_build_mode()
func objective() -> Dictionary:
	var result: Dictionary={"tag":"NIVEL %02d · %s" % [g.run.level,g.run.title()],"title":"Elegí un encargo del valle","detail":"Decidí qué fabricar con el stock del mercado.","goal":1.0,"value":g.run.progress(),"button":"ELEGIR","action":"board"}
	if active.is_empty():
		var required: String=REQUIRED.get(g.run.level,"")
		if not required.is_empty() and not g.town.has_building(required):
			result.merge({"title":"Construí "+g.town.TYPES[required]["name"].to_lower(),"detail":"Elegí un solar; el catálogo señala tu edificio.","button":"CONSTRUIR","action":"build"},true)
			if g.coins<g.town.TYPES[required]["price"]:result.merge({"title":"Ahorrá para "+g.town.TYPES[required]["name"].to_lower(),"detail":"Cosechá, vendé y recaudá para construir.","button":"SEÑALAR","action":"","target":Vector3(4,0,2.5) if g._total_bag()>=6 else g._harvest_target()},true)
		elif g.run.level==10 and production_level<1:result.merge({"title":"Mejorá tus talleres","detail":"Pedidos → mejorar talleres. Los lotes tardan menos."},true)
		elif (g.run.level in [9,12] or g.run.level>12 and (g.run.level-13)%3==2) and patrol_wins-int(g.run.activity_start.get("patrol",0))<1:
			if not patrol.is_empty():result.merge({"title":"Ronda de defensa en marcha","detail":"Frená dos; al menos uno personalmente.","target":g.run.STOCK,"button":"SEÑALAR","action":""},true)
			elif g._total_stock()<4:result.merge({"title":"Abastecé antes de la ronda","detail":"Dejá 4 productos en el puesto.","target":Vector3(4,0,2.5) if g._total_bag()>0 else g._harvest_target(),"button":"SEÑALAR","action":""},true)
			else:result.merge({"title":"Organizá una ronda de defensa","detail":"Vos elegís cuándo empezar; prepará guardia y cerrojo.","button":"RONDA","action":"patrol"},true)
		elif g.run.level in [8,11] and rush_done-int(g.run.activity_start.get("rush",0))<1 or g.run.level>12 and (g.run.level-13)%3==1:result.merge({"title":"Elegí un encargo exprés","detail":"En 100 s ganás +90. Después conservás el pago base."},true)
		elif g.run.level==12:result.merge({"title":"Abastecé la feria de Wivori","detail":"Meta: tres encargos entregados en este capítulo."},true)
		elif g.run.level==10 and recipes_seen.size()<2 or g.run.level>12 and (g.run.level-13)%3==0 and recipes_seen.size()<3:result.merge({"title":"Probá otra receta del valle","detail":"Cada taller prepara un producto diferente."},true)
		return result
	var kind: String=active["recipe"];var recipe: Dictionary=RECIPES[kind]
	if not g.town.has_building(recipe["building"]):result.merge({"title":"Construí "+g.town.TYPES[recipe["building"]]["name"].to_lower(),"detail":"Este edificio prepara tu encargo.","button":"CONSTRUIR","action":"build"},true)
	elif int(cargo.get(kind,0))>0:result.merge({"title":"Entregá "+recipe["name"].to_lower(),"detail":"Llevá el lote al despacho, junto a la plaza.","target":DISPATCH,"button":"ENTREGAR" if g.player.position.distance_to(DISPATCH)<2.6 else "SEÑALAR","action":"dispatch"},true)
	elif jobs.has(kind):
		var ready: bool=jobs[kind]["ready"]
		result.merge({"title":"Recogé el lote terminado" if ready else "Preparando · %ds" % ceili(jobs[kind]["remaining"]),"detail":recipe["name"]+" · Podés seguir atendiendo el mercado.","target":station(kind),"button":"RECOGER" if ready and g.player.position.distance_to(station(kind))<2.4 else "SEÑALAR","action":"pickup" if ready else ""},true)
	elif available(kind):result.merge({"title":"Prepará "+recipe["name"].to_lower(),"detail":ingredient_text(kind)+" · mochila y stock.","target":station(kind),"button":"PREPARAR" if g.player.position.distance_to(station(kind))<2.4 else "SEÑALAR","action":"prepare"},true)
	else:
		var missing:=""
		for item in recipe["ingredients"]:
			if g.stash[item]+g.counter[item]<recipe["ingredients"][item]:missing=item;break
		result.merge({"title":"Ingredientes para "+recipe["name"].to_lower(),"detail":ingredient_text(kind),"target":g._harvest_kind(missing),"button":"SEÑALAR","action":""},true)
	if active["express"]:result["detail"]=("Extra de rapidez: %ds · " % ceili(active["remaining"]) if not active["late"] else "Sin apuro · ")+result["detail"]
	return result
func tick(delta: float) -> void:
	if not active.is_empty() and active["express"] and not active["late"]:
		active["remaining"]=maxf(0,active["remaining"]-delta)
		if active["remaining"]<=0:active["late"]=true;g._notice("Sin extra de rapidez\nConservás el encargo y su pago base.",2)
	for key in jobs:
		var job: Dictionary=jobs[key]
		if job["ready"]:continue
		job["remaining"]=maxf(0,job["remaining"]-delta)
		if job["remaining"]<=0:job["ready"]=true;g._notice("¡LOTE LISTO!\n"+RECIPES[key]["name"],2)
	_tick_patrol();visual_wait-=delta
	if visual_wait<=0:visual_wait=.25;_update_visuals()
func _update_visuals() -> void:
	for key in outputs:
		outputs[key]["root"].visible=jobs.has(key)
		if jobs.has(key):outputs[key]["root"].position=station(key)+Vector3(1.05,.12,0);outputs[key]["label"].text="¡LISTO!" if jobs[key]["ready"] else "%ds" % ceili(jobs[key]["remaining"])
	var kind:=""
	for key in cargo:
		if cargo[key]>0:kind=key;break
	if kind!=parcel_kind:
		if is_instance_valid(parcel):parcel.queue_free()
		parcel=null;parcel_kind=kind
		if not kind.is_empty():parcel=Art.place(g.player,RECIPES[kind]["model"],Vector3(0,.83,.54),Vector3.ONE*.68)
	if not kind.is_empty():g.player.carrying=g._total_bag()+cargo_total();g.player.goods_root.visible=false
	else:g.player.set_carry(g._total_bag())
func board_visible() -> bool:return board_scrim!=null and board_scrim.visible
func close_board() -> void:
	if board_scrim!=null:board_scrim.visible=false
func toggle_board() -> void:
	if board_scrim==null or g.run.level<7:return
	if g.shop_panel.visible:g._toggle_shop()
	g.input_stick._clear();g.boost_active=false;g.move_velocity=Vector3.ZERO
	board_scrim.visible=not board_scrim.visible;refresh_board();g._refresh_ui()
func build_board() -> void:
	board_scrim=ColorRect.new();board_scrim.color=Color(.04,.14,.16,.60);board_scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);g.hud.root.add_child(board_scrim);board_scrim.visible=false
	board=g.hud.panel();board_scrim.add_child(board);board.set_anchors_and_offsets_preset(Control.PRESET_CENTER);board.offset_left=-326;board.offset_right=326;board.offset_top=-466;board.offset_bottom=466
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",10);board.add_child(column)
	var heading:=HBoxContainer.new();column.add_child(heading)
	var title: Label=g.hud.label("Encargos del valle",27);title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;heading.add_child(title)
	var close: Button=g.hud.button("X",Color("#698891"),18);close.custom_minimum_size=Vector2(62,62);heading.add_child(close);close.pressed.connect(func():close_board();g._refresh_ui())
	board_status=g.hud.label("",16);board_status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;column.add_child(board_status)
	var scroller:=ScrollContainer.new();scroller.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroller.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;column.add_child(scroller)
	var listing:=VBoxContainer.new();listing.size_flags_horizontal=Control.SIZE_EXPAND_FILL;listing.add_theme_constant_override("separation",10);scroller.add_child(listing)
	for key in RECIPES:
		var card: PanelContainer=g.hud.panel(Color("#f0e8d5"));listing.add_child(card)
		var stack:=VBoxContainer.new();stack.add_theme_constant_override("separation",6);card.add_child(stack)
		stack.add_child(g.hud.label(RECIPES[key]["name"],21))
		var description: Label=g.hud.label(ingredient_text(key)+"\n"+g.town.TYPES[RECIPES[key]["building"]]["name"]+" · %d s · %d en caja" % [RECIPES[key]["seconds"],RECIPES[key]["pay"]],15);description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;stack.add_child(description)
		var choices:=HBoxContainer.new();choices.add_theme_constant_override("separation",10);stack.add_child(choices)
		var normal: Button=g.hud.button("SIN APURO",g.hud.TEAL,16);normal.size_flags_horizontal=Control.SIZE_EXPAND_FILL;normal.custom_minimum_size.y=80;choices.add_child(normal)
		var rush: Button=g.hud.button("100 s · +90",Color("#bd8a43"),16);rush.size_flags_horizontal=Control.SIZE_EXPAND_FILL;rush.custom_minimum_size.y=80;choices.add_child(rush)
		normal.pressed.connect(Callable(self,"accept").bind(key,false));rush.pressed.connect(Callable(self,"accept").bind(key,true));cards[key]=[normal,rush]
	patrol_button=g.hud.button("RONDA DE DEFENSA",Color("#637b96"),17);patrol_button.custom_minimum_size.y=82;listing.add_child(patrol_button);patrol_button.pressed.connect(start_patrol)
	improve_button=g.hud.button("MEJORAR TALLERES",Color("#ad824b"),17);improve_button.custom_minimum_size.y=82;listing.add_child(improve_button);improve_button.pressed.connect(upgrade_production)
	var resume: Button=g.hud.button("SEGUIR JUGANDO",g.hud.TEAL,20);resume.custom_minimum_size.y=80;column.add_child(resume);resume.pressed.connect(func():close_board();g._refresh_ui())
func refresh_board() -> void:
	if board==null:return
	board_status.text="Meta: "+g.run.summary()+"\nElegí vender ingredientes o transformarlos." if active.is_empty() else "En curso: "+RECIPES[active["recipe"]]["name"]+". Terminá este encargo antes de tomar otro."
	for key in cards:
		cards[key][0].disabled=not active.is_empty() or g.run.level<RECIPES[key]["level"];cards[key][1].disabled=cards[key][0].disabled or g.run.level<8
		cards[key][0].text="NIVEL %d" % RECIPES[key]["level"] if g.run.level<RECIPES[key]["level"] else "SIN APURO"
	patrol_button.disabled=g.run.level<9 or not patrol.is_empty() or not g.run.raiders.is_empty() or g.run.warning>0 or g._total_stock()<4
	patrol_button.text="RONDA · NIVEL 9" if g.run.level<9 else "RONDA · FRENÁ 2 · +160 EN CAJA"
	improve_button.disabled=g.run.level<10 or production_level>=2 or g.coins<360+production_level*300
	improve_button.text="TALLERES · NIVEL 10" if g.run.level<10 else "TALLERES AL MÁXIMO" if production_level>=2 else "TALLERES · -20 % TIEMPO · %d" % (360+production_level*300)
func save_state() -> Dictionary:
	return {"active":active.duplicate(true),"jobs":jobs.duplicate(true),"cargo":cargo.duplicate(),"orders":orders_done,"rush":rush_done,"festival":festival_done,"patrol_wins":patrol_wins,"recipes":recipes_seen.duplicate(),"patrol":patrol.duplicate(),"production_level":production_level}
func load_state(data: Dictionary) -> void:
	orders_done=int(Store.number(data,"orders",0,0,1000000));rush_done=int(Store.number(data,"rush",0,0,orders_done));festival_done=int(Store.number(data,"festival",0,0,orders_done));patrol_wins=int(Store.number(data,"patrol_wins",0,0,1000000));production_level=int(Store.number(data,"production_level",0,0,2))
	var saved: Variant=data.get("active",{})
	if saved is Dictionary and RECIPES.has(saved.get("recipe","")):active={"recipe":saved["recipe"],"express":saved.get("express")==true,"remaining":Store.number(saved,"remaining",100,0,100),"late":saved.get("late")==true}
	var saved_jobs: Dictionary=data["jobs"] if data.get("jobs") is Dictionary else {}
	var saved_cargo: Dictionary=data["cargo"] if data.get("cargo") is Dictionary else {}
	var capacity:=3
	for key in RECIPES:
		if saved_jobs.get(key) is Dictionary:jobs[key]={"remaining":Store.number(saved_jobs[key],"remaining",0,0,20),"ready":saved_jobs[key].get("ready")==true}
		cargo[key]=int(Store.number(saved_cargo,key,0,0,capacity));capacity-=int(cargo[key])
		if data.get("recipes") is Array and data["recipes"].has(key):recipes_seen.append(key)
	var p: Variant=data.get("patrol",{})
	if p is Dictionary and p.has("blocked"):patrol={"blocked":int(Store.number(p,"blocked",0,0,1000000)),"manual":int(Store.number(p,"manual",0,0,1000000)),"lost":int(Store.number(p,"lost",0,0,10000000)),"started":p.get("started")==true}
	_update_visuals()
