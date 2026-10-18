extends RefCounted

const Store=preload("res://scripts/save_store.gd")
const CART=Vector3(0,0,-13)
const STOCK=Vector3(4,0,2.5)
const ENTRIES=[Vector3(20,0,-9),Vector3(-19,0,-12),Vector3(20,0,12)]
var g
var level:=1
var start_sold:=0
var start_manual:=0
var start_shipments:=0
var start_blocked:=0
var contract_done:=0
var lock_level:=0
var alarm_level:=0
var guard_level:=0
var blocked:=0
var escaped:=0
var lost:=0
var wave_index:=0
var next_raid:=12.0
var warning:=0.0
var whistle_cooldown:=0.0
var guard_cooldown:=0.0
var guard: MarketActor
var guard_label: Label3D
var patrol_index:=0
var saved_guard_position:=Vector3(7,0,4)
var raiders: Array[Dictionary]=[]
var completion_shown:=false
var manual_blocked:=0
var activity_start: Dictionary={}

func _init(game: Node3D) -> void:g=game

func title() -> String:
	var names: Array=["Primer puesto","Hora punta","Manos largas","Pedidos de manzana","Comercio en ruta","Mercado protegido","La primera compota","Merienda en camino","La ronda del valle","Talleres en marcha","Ruta de comerciantes","La feria de Wivori"]
	return names[level-1] if level<=12 else ["Ruta de encargos","Ruta exprés","Ronda de comerciantes"][(level-13)%3]+" %d" % (1+int((level-13)/3))

func contract_kind() -> String:
	return ["apple","berry","carrot","tomato"][(maxi(4,level)-4)%4]

func contract_goal() -> int:
	return mini(30,8+maxi(0,level-4)*4)

func goals() -> Array[Dictionary]:
	var tasks: Array[Dictionary]=[]
	if level>=7:return _activity_goals()
	if level<=3:
		tasks.append({"label":"Vendidos","value":g.sold-start_sold,"goal":6+level*6})
		tasks.append({"label":"Entregados por vos","value":g.manual_delivered-start_manual,"goal":6 if level==1 else 12})
		if level<=2:tasks.append({"label":"Ayudantes","value":g.worker_count,"goal":level})
		else:
			tasks.append({"label":"Cerrojo","value":lock_level,"goal":1})
			tasks.append({"label":"Frenados","value":blocked-start_blocked,"goal":1})
	else:
		tasks.append({"label":"Pedido de "+g.CROP_NAMES[contract_kind()],"value":contract_done,"goal":contract_goal()})
		if level==4:tasks.append({"label":"Huerto","value":int(g.orchard_owned),"goal":1})
		if level==5 or level>=7 and level%2==1:
			tasks.append({"label":"Envíos","value":g.shipments_completed-start_shipments,"goal":1})
		if level==5:tasks.append({"label":"Muelle","value":int(g.pier_owned),"goal":1})
		if level==6:
			tasks.append({"label":"Alarma","value":alarm_level,"goal":1})
			tasks.append({"label":"Guardia","value":guard_level,"goal":1})
		tasks.append({"label":"Frenados","value":blocked-start_blocked,"goal":mini(3,1+int((level-3)/2))})
	return tasks

func summary() -> String:
	var parts: PackedStringArray=[]
	for goal in goals():parts.append("%s %d/%d" % [goal["label"],mini(goal["value"],goal["goal"]),goal["goal"]])
	return " · ".join(parts)

func _activity_goals() -> Array[Dictionary]:
	var tasks: Array[Dictionary]=[]
	var orders: int=g.work.orders_done-int(activity_start.get("orders",0))
	var rush: int=g.work.rush_done-int(activity_start.get("rush",0))
	var patrols: int=g.work.patrol_wins-int(activity_start.get("patrol",0))
	var building: String=g.work.REQUIRED.get(level,"")
	if not building.is_empty():tasks.append({"label":g.town.TYPES[building]["name"].capitalize(),"value":int(g.town.has_building(building)),"goal":1})
	match level:
		7:tasks.append({"label":"Encargo entregado","value":orders,"goal":1})
		8:tasks.append({"label":"Entrega exprés","value":rush,"goal":1})
		9:tasks.append({"label":"Ronda protegida","value":patrols,"goal":1})
		10:
			tasks.append({"label":"Recetas distintas","value":g.work.recipes_seen.size(),"goal":2})
			tasks.append({"label":"Talleres mejorados","value":g.work.production_level,"goal":1})
		11:
			tasks.append({"label":"Encargos","value":orders,"goal":2});tasks.append({"label":"Exprés","value":rush,"goal":1})
		12:
			tasks.append({"label":"Puestos de la feria","value":g.work.festival_done-int(activity_start.get("festival",0)),"goal":3})
			tasks.append({"label":"Ronda protegida","value":patrols,"goal":1})
		_:
			tasks.append({"label":"Encargos","value":orders,"goal":mini(4,2+int((level-13)/6))})
			if (level-13)%3==1:tasks.append({"label":"Exprés","value":rush,"goal":2})
			elif (level-13)%3==2:tasks.append({"label":"Ronda protegida","value":patrols,"goal":1})
			else:tasks.append({"label":"Recetas distintas","value":g.work.recipes_seen.size(),"goal":3})
	return tasks

func progress() -> float:
	var result:=0.0
	var tasks:=goals()
	for goal in tasks:result+=clampf(float(goal["value"])/goal["goal"],0,1)
	return result/maxi(1,tasks.size())

func complete() -> bool:
	return progress()>=.999 and raiders.is_empty() and warning<=0

func reward() -> int:return mini(800,80+(level-1)*40)

func advance() -> bool:
	if not complete():return false
	var prize:=reward()
	g.coins+=prize; level+=1
	g.player.act("celebrate")
	start_sold=g.sold; start_manual=g.manual_delivered; start_shipments=g.shipments_completed; start_blocked=blocked
	contract_done=0; completion_shown=false; warning=0; next_raid=12 if level==3 else 26
	activity_start={"orders":g.work.orders_done,"rush":g.work.rush_done,"patrol":g.work.patrol_wins,"festival":g.work.festival_done}
	g.guide_override={}; g.director.pinned_kind=""
	g._notice("NIVEL %d · %s\nPremio: +%d monedas" % [level,title(),prize],3.2)
	g._save_progress(); g._refresh_ui()
	return true

func deliver_contract() -> int:
	if level<4 or g.player.position.distance_to(CART)>2.3:return 0
	var kind:=contract_kind()
	var amount:=mini(g.stash[kind],contract_goal()-contract_done)
	if amount<=0:return 0
	g.stash[kind]-=amount; contract_done+=amount; g.manual_delivered+=amount
	var income: int=amount*int(g.SELL_VALUE[kind])*2
	g._record_sale(amount,income)
	g.player.set_carry(g._total_bag()); g.player.act("deliver")
	g.world.sale_receipt(CART,income); g._cash_sound()
	g._notice("PEDIDO PREMIUM: +%d\nVos entregaste %d %s." % [income,amount,g.CROP_NAMES[kind]],2.2)
	g._save_progress()
	return amount

func threat() -> Dictionary:
	if raiders.is_empty():return {}
	var chosen: Dictionary={}; var distance:=INF
	for raid in raiders:
		if raid["state"]=="retreat":continue
		var d: float=g.player.position.distance_to(raid["actor"].position)
		if d<distance:chosen=raid; distance=d
	return chosen

func can_intercept() -> bool:
	var raid:=threat()
	return not raid.is_empty() and whistle_cooldown<=0 and g.player.position.distance_to(raid["actor"].position)<=2.75 and not g.shop_panel.visible

func intercept() -> bool:
	if not can_intercept():return false
	whistle_cooldown=2.0
	g.player.act("intercept"); g.world.whistle_pulse(g.player.position)
	_repel(threat(),true)
	return true

func _repel(raid: Dictionary, by_player: bool) -> void:
	if raid.is_empty() or raid["state"]=="retreat":return
	var amount: int=raid["amount"]
	if amount>0:
		g.counter[raid["cargo"]]+=amount
		g._animate_goods(raid["actor"].position,STOCK,amount,Color("#ecbc69"),raid["cargo"])
		g._float_activity(raid["actor"].position,"¡RECUPERADO! +%d" % amount,Color("#338c82"))
	raid["cargo"]=""; raid["amount"]=0; raid["state"]="retreat"
	raid["actor"].set_carry(0); blocked+=1
	if by_player:manual_blocked+=1
	if g.hud!=null:g.hud.rabbit_banner.recovered(amount)
	g._notice(("¡RECUPERASTE %d PRODUCTOS!" % amount) if amount>0 else ("¡MAPACHE AHUYENTADO!" if by_player else "¡EL GUARDIA LO FRENÓ!"),1.8)
	g._save_progress()

func _spawn_raider(entry: Vector3, saved: Dictionary={}) -> void:
	var actor: MarketActor=g.ActorScript.new(); actor.setup("thief",Color("#68758c"),"raccoon"); actor.ground_sampler=Callable(g.world,"ground_height"); g.add_child(actor)
	actor.position=g.world.navigation.nearest_free(Store.position(saved.get("position"),entry))
	var cargo: String=saved.get("cargo","") if saved.get("cargo","") is String else ""
	if not g.SELL_VALUE.has(cargo):cargo=""
	var state: String=saved.get("state","approach")
	if state not in ["approach","tamper","escape","retreat"]:state="approach"
	var amount:=int(Store.number(saved,"amount",0,0,8)) if not cargo.is_empty() else 0
	actor.set_cargo_kind(cargo)
	actor.set_carry(amount)
	var label: Label3D=g.world.make_label(actor,"!",Vector3(0,3,0),55)
	label.modulate=Color("#ffbe86")
	raiders.append({"actor":actor,"entry":entry,"state":state,"remaining":Store.number(saved,"remaining",4+lock_level*4,0,16),"cargo":cargo,"amount":amount,"label":label})

func _spawn_wave() -> void:
	var count:=1 if level==3 else mini(4,2+int((level-4)/2))
	for i in range(count):_spawn_raider(ENTRIES[(wave_index+i)%ENTRIES.size()])
	wave_index+=1
	g.player.act("surprise")
	g._notice("¡LLEGARON LOS MAPACHES!\nAcercate y tocá AHUYENTAR.",2.5)
	g._save_progress()

func _tick_guard(delta: float) -> void:
	if guard_level<=0:return
	if guard==null:
		guard=g.ActorScript.new(); guard.setup("guard",Color("#547e9e"),"dog"); guard.ground_sampler=Callable(g.world,"ground_height"); g.add_child(guard); guard.position=saved_guard_position
		guard_label=g.world.make_label(guard,"GUARDIA",Vector3(0,2.8,0),35)
	guard_cooldown=maxf(0,guard_cooldown-delta)
	guard_label.text="GUARDIA · %ds" % ceili(guard_cooldown) if guard_cooldown>0 else "GUARDIA"
	var target: Dictionary={}; var distance:=8.0+guard_level
	if guard_cooldown<=0:
		for raid in raiders:
			if raid["state"]=="retreat":continue
			var d: float=guard.position.distance_to(raid["actor"].position)
			if d<distance:distance=d; target=raid
	if not target.is_empty():
		g._move_actor(guard,target["actor"].position,4.0+guard_level*.4,delta)
		if guard.position.distance_to(target["actor"].position)<1.65:
			guard.act("intercept"); _repel(target,false); guard_cooldown=14-guard_level*2
	else:
		var points: Array=[Vector3(7,0,4),Vector3(10,0,-1),Vector3(6,0,6)]
		if g._move_actor(guard,points[patrol_index],2.3,delta):patrol_index=(patrol_index+1)%points.size()

func tick(delta: float) -> void:
	whistle_cooldown=maxf(0,whistle_cooldown-delta)
	_tick_guard(delta)
	for raid in raiders.duplicate():
		var actor: MarketActor=raid["actor"]
		var state: String=raid["state"]
		var speed:=minf(5.3,3.7+level*.09)
		if alarm_level>0 and actor.position.distance_to(STOCK)<6+alarm_level:speed*=maxf(.64,1-alarm_level*.12)
		if state=="approach":
			if g._move_actor(actor,STOCK,speed,delta):raid["state"]="tamper"; raid["remaining"]=4+lock_level*4
		elif state=="tamper":
			raid["remaining"]-=delta; actor.act("harvest")
			raid["label"].text="%ds" % ceili(raid["remaining"])
			if raid["remaining"]<=0:
				var chosen: String=""
				for kind in g.counter:
					if chosen.is_empty() or g.counter[kind]>g.counter[chosen]:chosen=kind
				var amount:=mini(8,mini(3+int(level/2),g.counter[chosen]))
				if amount>0:
					g.counter[chosen]-=amount; raid["cargo"]=chosen; raid["amount"]=amount
					g._animate_goods(STOCK,actor.position,amount,Color("#d88c55"),chosen)
					g._float_activity(actor.position,"¡ROBO! -%d" % amount,Color("#cf5e51"))
					actor.set_cargo_kind(chosen);actor.set_carry(amount); raid["state"]="escape"; raid["label"].text="¡LLEVA %d!" % amount
					g._notice("¡SE LLEVA %d PRODUCTOS!\nInterceptalo para recuperarlos." % amount,2.4)
				else:raid["state"]="retreat"
				g._save_progress()
		else:
			if g._move_actor(actor,raid["entry"],speed+1.0,delta):
				if state=="escape":escaped+=1; lost+=int(raid["amount"]); g._notice("ESCAPÓ CON %d PRODUCTOS\nPodés seguir; reforzá tus defensas." % raid["amount"],2.5)
				raiders.erase(raid); actor.queue_free(); g._save_progress()
	if raiders.is_empty() and progress()>=.999:warning=0
	if level>=3 and raiders.is_empty() and progress()<.999:
		if warning>0:
			warning=maxf(0,warning-delta)
			if warning<=0:_spawn_wave(); next_raid=maxf(44,78-level*3)
		else:
			next_raid-=delta
			if next_raid<=0:warning=6+alarm_level*2+g.town.warning_seconds(); g._notice("¡MAPACHES EN CAMINO!\nPrepará las defensas o salí a interceptar.",2.8)
	if complete() and not completion_shown:
		completion_shown=true; g._notice("¡NIVEL SUPERADO!\nCobrá el premio para abrir la siguiente meta.",3)

func alert() -> Dictionary:
	var raid:=threat()
	if not raid.is_empty():
		var escape: bool=raid["state"]=="escape"
		return {"id":"raid","title":"¡Recuperá tu mercadería!" if escape else "¡Un mapache va al almacén!","detail":"Movete hasta él y tocá AHUYENTAR. La guía solo señala.","button":"SEÑALAR","target":raid["actor"].position,"color":Color("#b9574a")}
	if warning>0:return {"id":"warning","title":"Mapaches en camino · %ds" % ceili(warning),"detail":"El cerrojo demora el robo; la alarma y el guardia ayudan.","button":"DEFENSAS","target":g.UPGRADE_POS["lock"],"color":Color("#b9574a")}
	return {}

func save_state() -> Dictionary:
	var actors: Array=[]
	for raid in raiders:
		actors.append({"position":[raid["actor"].position.x,raid["actor"].position.z],"entry":[raid["entry"].x,raid["entry"].z],"state":raid["state"],"remaining":raid["remaining"],"cargo":raid["cargo"],"amount":raid["amount"]})
	return {"level":level,"activity_start":activity_start.duplicate(),"manual_blocked":manual_blocked,"start_sold":start_sold,"start_manual":start_manual,"start_shipments":start_shipments,"start_blocked":start_blocked,"contract_done":contract_done,"lock":lock_level,"alarm":alarm_level,"guard":guard_level,"blocked":blocked,"escaped":escaped,"lost":lost,"wave":wave_index,"next_raid":next_raid,"warning":warning,"raiders":actors,"guard_position":[guard.position.x,guard.position.z] if guard!=null else [saved_guard_position.x,saved_guard_position.z],"guard_cooldown":guard_cooldown,"patrol_index":patrol_index}

func load_state(data: Dictionary) -> void:
	var migrated:=1
	if g.worker_count>=1:migrated=2
	if g.worker_count>=2:migrated=3
	if g.orchard_owned:migrated=4
	if g.pier_owned:migrated=5
	level=int(Store.number(data,"level",migrated,1,10000))
	start_sold=int(Store.number(data,"start_sold",g.sold,0,g.sold))
	start_manual=int(Store.number(data,"start_manual",g.manual_delivered,0,g.manual_delivered))
	start_shipments=int(Store.number(data,"start_shipments",g.shipments_completed,0,g.shipments_completed))
	lock_level=int(Store.number(data,"lock",0,0,3)); alarm_level=int(Store.number(data,"alarm",0,0,3)); guard_level=int(Store.number(data,"guard",0,0,3))
	blocked=int(Store.number(data,"blocked",0,0,1000000)); escaped=int(Store.number(data,"escaped",0,0,1000000)); lost=int(Store.number(data,"lost",0,0,10000000))
	manual_blocked=int(Store.number(data,"manual_blocked",0,0,blocked))
	var starts: Dictionary=data["activity_start"] if data.get("activity_start") is Dictionary else {}
	activity_start={"orders":int(Store.number(starts,"orders",g.work.orders_done,0,g.work.orders_done)),"rush":int(Store.number(starts,"rush",g.work.rush_done,0,g.work.rush_done)),"patrol":int(Store.number(starts,"patrol",g.work.patrol_wins,0,g.work.patrol_wins)),"festival":int(Store.number(starts,"festival",g.work.festival_done,0,g.work.festival_done))}
	start_blocked=int(Store.number(data,"start_blocked",blocked,0,blocked))
	contract_done=int(Store.number(data,"contract_done",0,0,contract_goal()))
	wave_index=int(Store.number(data,"wave",0,0,1000000)); next_raid=Store.number(data,"next_raid",25,0,80); warning=Store.number(data,"warning",0,0,12)
	saved_guard_position=g.world.navigation.nearest_free(Store.position(data.get("guard_position"),Vector3(7,0,4)))
	guard_cooldown=Store.number(data,"guard_cooldown",0,0,14)
	patrol_index=int(Store.number(data,"patrol_index",0,0,2))
	var actors: Variant=data.get("raiders",[])
	if actors is Array:
		for saved in actors.slice(0,5):
			if saved is Dictionary:_spawn_raider(Store.position(saved.get("entry"),ENTRIES[0]),saved)
