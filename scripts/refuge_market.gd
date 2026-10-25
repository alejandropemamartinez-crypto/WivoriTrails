extends RefCounted
class_name WivoriWinterMarket

# A real goods ledger, shared by the visible workers, shoppers and train.
# The hero works in reach, but hiring never drives its movement.
signal changed
signal earned(area: int, product: String, amount: int, quantity: int)
signal worked(area: int, product: String, index: int, finished: bool)

const Store=preload("res://scripts/save_store.gd")
const PRODUCTS=["wood","meat"]
const LABELS={"wood":"Madera","meat":"Carne de oso polar"}
const TREE_POSITIONS=[Vector3(-11,0,20.8),Vector3(-15,0,22.3),Vector3(-11.5,0,25.2),Vector3(-17,0,26),Vector3(-8.5,0,27.6),Vector3(-14,0,29)]
const BEAR_POSITIONS=[Vector3(10.1,0,21.8),Vector3(14.6,0,25.0),Vector3(8.4,0,27.6)]
const SHOP_POSITIONS={"wood":Vector3(-6,0,18.0),"meat":Vector3(2.5,0,18.0)}
const COUNTERS={"wood":Vector3(-6,0,20.4),"meat":Vector3(2.5,0,20.4)}
const DEPOT=Vector3(-15,0,18.6)
const RAIL_POINTS=[Vector3(-18,0,16.5),Vector3(18,0,16.5),Vector3(18,0,30),Vector3(-18,0,30),Vector3(-18,0,16.5)]
const STOPS=[3.0,12.0,20.5]
const TRACK_LENGTH=99.0
const RAIL_PRICES=[90,140,210]
const STOCK_CAPACITY=24
const DEPOT_CAPACITY=64
const QUEUE_CAPACITY=6
const HARVEST_ROLES=["lumberjack","hunter"]
const HIRE_PRICES={"lumberjack":60,"hunter":120,"cashier":80,"porter":160,"sentinel":220}
const ROLE_NAMES={"lumberjack":"Leñadores","hunter":"Cazadores","cashier":"Cajeros","porter":"Porteador","sentinel":"Centinelas"}
const ROLE_LIMITS={"lumberjack":3,"hunter":3,"cashier":2,"porter":1,"sentinel":2}
const TOWER_POSITIONS=[Vector3(16.3,0,20.2),Vector3(4.7,0,27.7)]
const BEAR_NAMES=["Oso polar","Oso blindado","Oso acorazado"]
const FIELD_CAPACITY=48
const MANUAL_REACH=3.2
const COUNTER_REACH=2.8
const STALL_REACH=1.35

var coins:=0
var bag: Dictionary={"wood":0,"meat":0}
var pack_level:=1
var markets: Array[Dictionary]=[]
var offline_coins:=0
var clock:=0.0
static var worker_paths: Array=[]
static var worker_seconds: Array[float]=[]
static var carrier_paths: Dictionary={}
static var carrier_seconds: Dictionary={}

func _init() -> void:
	if worker_paths.is_empty():
		for product in PRODUCTS:
			for point in positions(product):
				var destination: Vector3=point+Vector3(0,0,-1.5)
				var route: Array[Vector3]=[]
				route.assign([DEPOT,Vector3(-17.6,0,20.1),destination] if product=="wood" else [DEPOT,Vector3(-12,0,20.0),Vector3(6.2,0,20.0),Vector3(6.2,0,22.3),destination])
				worker_paths.append(route);worker_seconds.append(path_length(route)/4.2)
		for origin in ["depot","wood","meat"]:
			for target in ["depot","wood","meat"]:
				var start: Vector3=DEPOT if origin=="depot" else COUNTERS[origin];var finish: Vector3=DEPOT if target=="depot" else COUNTERS[target]
				var route: Array[Vector3]=[];route.assign([start,Vector3(-12,0,20.0),finish] if origin=="depot" or target=="depot" else [start,finish])
				carrier_paths[origin+":"+target]=route;carrier_seconds[origin+":"+target]=path_length(route)/4.6
	for area in range(6):markets.append(_new_market())

func _new_market() -> Dictionary:
	var nodes: Dictionary={}
	for product in PRODUCTS:
		var row: Array[Dictionary]=[]
		for index in range(positions(product).size()):row.append({"hp":max_hp(product,index),"respawn":0.0})
		nodes[product]=row
	var queues: Dictionary={"wood":[],"meat":[]}
	var id:=0
	for product in PRODUCTS:
		for index in range(3):
			queues[product].append({"id":id,"quantity":2+index%2,"remaining":2+index%2,"arrival":0.0 if index==0 else float(index)*.65});id+=1
	return {"nodes":nodes,"stock":{"wood":0,"meat":0},"depot":{"wood":0,"meat":0},"queues":queues,"next_customer":id,
		"arrivals":{"wood":3.0,"meat":5.0},"service":{"wood":0.0,"meat":0.0},"sold":{"wood":0,"meat":0},"customers":0,
		"workers":{"lumberjack":_new_worker(),"hunter":_new_worker(),"cashier":_new_worker(),"porter":_new_worker(),"sentinel":_new_worker()},
		"extras":{"lumberjack":[_new_worker(),_new_worker()],"hunter":[_new_worker(),_new_worker()]},
		"field_wood":[0,0,0,0,0,0],"field_meat":[0,0,0],"shots":[],"next_shot":0,"guard_clock":[0.0,.55],
		"carrier":{"phase":"load","from":"depot","to":"wood","progress":0.0,"cargo":{"wood":0,"meat":0}},"rails":0,"tool":1,"train_level":1,
		"train":{"distance":0.0,"next_stop":0,"wait":0.0,"cargo":{"wood":0,"meat":0},"laps":0}}

func _new_worker() -> Dictionary:return {"level":0,"phase":"out","progress":0.0,"target":0,"cargo":0,"clock":0.0}
func town(area: int) -> Dictionary:return markets[clampi(area,0,5)]
func positions(product: String) -> Array:return TREE_POSITIONS if product=="wood" else BEAR_POSITIONS
func max_hp(product: String,index: int=0) -> int:return 3 if product=="wood" else [4,9,16][clampi(index,0,2)]
func yield_count(product: String,index: int=0) -> int:return 5 if product=="wood" else [6,9,12][clampi(index,0,2)]
func worker_count(role: String,area: int) -> int:return int(town(area)["workers"][role]["level"]) if ROLE_NAMES.has(role) else 0
func cashier_for(product: String,area: int) -> bool:return worker_count("cashier",area)>=(1 if product=="wood" else 2)
func arrival_interval(product: String,area: int) -> float:
	if not cashier_for(product,area):return 5.5
	return maxf(1.35,(1.7 if operating(area) or worker_count("porter",area)>0 else 2.4)-float(area)*.06)
func respawn_time(product: String) -> float:return 14.0 if product=="wood" else 18.0
func unit_price(product: String,area: int) -> int:return (4 if product=="wood" else 6)+area*2
func bag_count() -> int:return int(bag["wood"])+int(bag["meat"])
func bag_capacity() -> int:return 16+(pack_level-1)*8
func bag_free() -> int:return maxi(0,bag_capacity()-bag_count())
func active_node(product: String,index: int,area: int) -> bool:
	return product in PRODUCTS and index>=0 and index<positions(product).size() and float(town(area)["nodes"][product][index]["respawn"])<=0
func sold_total(area: int) -> int:return int(town(area)["sold"]["wood"])+int(town(area)["sold"]["meat"])
func operating(area: int) -> bool:return int(town(area)["rails"])==3

func flat_distance(a: Vector3,b: Vector3) -> float:return Vector2(a.x-b.x,a.z-b.z).length()
func shop_bounds(product: String) -> Rect2:
	var at: Vector3=SHOP_POSITIONS[product]
	return Rect2(Vector2(at.x-2.4,at.z-1.1),Vector2(4.8,2.4))
func counter_in_reach(at: Vector3,product: String) -> bool:
	# The visible stall is a footprint, not a hidden point at its front.
	var bounds: Rect2=shop_bounds(product);var point:=Vector2(at.x,at.z)
	var nearest:=Vector2(clampf(point.x,bounds.position.x,bounds.end.x),clampf(point.y,bounds.position.y,bounds.end.y))
	return point.distance_to(nearest)<=STALL_REACH or flat_distance(at,COUNTERS[product])<=COUNTER_REACH
func ground_count(product: String,index: int,area: int) -> int:return int(town(area)["field_"+product][index])

func context(at: Vector3,area: int) -> Dictionary:
	# Only actionable transfers take priority. An empty depot/counter or loot
	# that does not fit must never hide a living tree or bear in the same area.
	var idle: Dictionary={}
	for product in PRODUCTS:
		if counter_in_reach(at,product):
			var count: int=mini(int(bag[product]),STOCK_CAPACITY-int(town(area)["stock"][product]))
			var action: Dictionary={"kind":"deliver","product":product,"at":COUNTERS[product],"title":"ENTREGA AUTOMÁTICA","detail":"%d en mochila · %d/%d en el puesto" % [bag[product],town(area)["stock"][product],STOCK_CAPACITY],"enabled":count>0}
			if int(bag[product])>0 and int(town(area)["stock"][product])>=STOCK_CAPACITY:action["detail"]="Puesto lleno · Se entrega apenas los clientes liberan espacio"
			if action["enabled"]:return action
			if idle.is_empty():idle=action
	if flat_distance(at,DEPOT)<=2.5:
		var count: int=int(town(area)["depot"]["wood"])+int(town(area)["depot"]["meat"])
		var action: Dictionary={"kind":"load","at":DEPOT,"title":"CARGA AUTOMÁTICA","detail":"Depósito: %d madera · %d carne" % [town(area)["depot"]["wood"],town(area)["depot"]["meat"]],"enabled":count>0 and bag_free()>0}
		if action["enabled"]:return action
		if idle.is_empty():idle=action
	var pickup: Dictionary={};var pickup_distance:=MANUAL_REACH
	for product in PRODUCTS:
		for index in range(positions(product).size()):
			var dropped: int=ground_count(product,index,area);var distance: float=flat_distance(at,positions(product)[index])
			if dropped<=0 or distance>pickup_distance:continue
			pickup_distance=distance
			pickup={"kind":"collect","product":product,"index":index,"at":positions(product)[index],"title":"RECOGIDA AUTOMÁTICA","detail":"%d %s en el suelo · Se conserva hasta recogerlo" % [dropped,"maderas" if product=="wood" else "carnes"],"enabled":bag_free()>0}
	if not pickup.is_empty() and pickup["enabled"]:return pickup
	var best: Dictionary={};var distance:=MANUAL_REACH
	for product in PRODUCTS:
		for index in range(positions(product).size()):
			if not active_node(product,index,area):continue
			var candidate: float=flat_distance(at,positions(product)[index])
			if candidate>distance:continue
			var room: bool=bag_free()+FIELD_CAPACITY-ground_count(product,index,area)>=yield_count(product,index)
			var title: String="CORTANDO PINO" if product=="wood" else "CAZANDO · "+BEAR_NAMES[index].to_upper()
			var detail: String="Automático · %d golpes" % ceili(float(town(area)["nodes"][product][index]["hp"])/float(town(area)["tool"]))
			detail+=" · Mochila llena: el botín queda acá" if bag_free()<yield_count(product,index) else " · +%d %s" % [yield_count(product,index),"madera" if product=="wood" else "carne"]
			var action: Dictionary={"kind":"harvest","product":product,"index":index,"at":positions(product)[index],"title":title if room else "RETIRÁ EL BOTÍN","detail":detail if room else "El suelo está lleno. Vendé tu carga y recogé el botín.","enabled":room}
			if not room:
				if idle.is_empty():idle=action
				continue
			distance=candidate;best=action
	if not best.is_empty():return best
	if not pickup.is_empty():return pickup
	if not idle.is_empty():return idle
	return {"kind":"walk","at":at,"title":"ACERCATE","detail":"Pinos a la izquierda · Osos a la derecha","enabled":false}

func use(at: Vector3,area: int) -> Dictionary:
	var action: Dictionary=context(at,area)
	if not action["enabled"]:return {}
	match action["kind"]:
		"harvest":
			var product: String=action["product"];var index: int=action["index"]
			var result: Dictionary=_hit(product,index,area,int(town(area)["tool"]))
			if result["finished"]:
				var collected: int=mini(bag_free(),yield_count(product,index))
				bag[product]+=collected;town(area)["field_"+product][index]+=yield_count(product,index)-collected
			changed.emit();return action.merged(result)
		"collect":
			var product: String=action["product"];var index: int=action["index"];var count: int=mini(bag_free(),ground_count(product,index,area))
			town(area)["field_"+product][index]-=count;bag[product]+=count;changed.emit();return action.merged({"quantity":count})
		"deliver":
			var product: String=action["product"]
			var quantity: int=mini(int(bag[product]),STOCK_CAPACITY-int(town(area)["stock"][product]))
			bag[product]-=quantity;town(area)["stock"][product]+=quantity;changed.emit();return action.merged({"quantity":quantity})
		"load":
			var loaded:=0
			# Alternate products, so a depot full of logs cannot prevent meat sales.
			while bag_free()>0:
				var moved:=false
				for product in PRODUCTS:
					if bag_free()>0 and int(town(area)["depot"][product])>0:
						town(area)["depot"][product]-=1;bag[product]+=1;loaded+=1;moved=true
				if not moved:break
			changed.emit();return action.merged({"quantity":loaded})
	return {}

func _hit(product: String,index: int,area: int,damage: int) -> Dictionary:
	if not active_node(product,index,area):return {"finished":false}
	var node: Dictionary=town(area)["nodes"][product][index]
	node["hp"]=maxi(0,int(node["hp"])-damage)
	var finished: bool=int(node["hp"])==0
	if finished:node["respawn"]=respawn_time(product)
	worked.emit(area,product,index,finished)
	return {"finished":finished,"quantity":yield_count(product,index) if finished else 0}

func price(id: String,area: int) -> int:
	var data: Dictionary=town(area)
	if id=="cashier":return [80,120,0][worker_count(id,area)]
	if id=="sentinel":return [220,360,0][worker_count(id,area)]
	if HIRE_PRICES.has(id):return int(HIRE_PRICES[id])*(1+worker_count(id,area))
	if id=="rail":return RAIL_PRICES[int(data["rails"])] if int(data["rails"])<3 else 0
	if id=="tool":return 100*int(data["tool"])
	if id=="pack":return 90*pack_level
	if id=="train":return 300*int(data["train_level"])
	if id=="supplies":return 80
	return 0
func buy_reason(id: String,area: int) -> String:
	var data: Dictionary=town(area)
	if not id in ["lumberjack","hunter","cashier","porter","sentinel","rail","tool","pack","train","supplies"]:return "Mejora desconocida"
	if ROLE_NAMES.has(id):
		if worker_count(id,area)>=int(ROLE_LIMITS[id]):return "Equipo completo"
		var gate: Dictionary=hire_requirement(id,area)
		if not gate["ready"]:return gate["text"]
	if id=="rail":
		if operating(area):return "Circuito ferroviario completo"
		if int(data["workers"]["lumberjack"]["level"])==0 or int(data["workers"]["hunter"]["level"])==0:return "Contratá primero al leñador y al cazador"
		if worker_count("cashier",area)<2:return "Contratá a los dos cajeros para vender sin estar presente"
	if id=="tool" and int(data["tool"])>=3:return "Herramientas al máximo"
	if id=="pack" and pack_level>=3:return "Mochila al máximo"
	if id=="train" and not operating(area):return "Completá los tres tramos de vías"
	if id=="train" and int(data["train_level"])>=3:return "Tren al máximo"
	if coins<price(id,area):return "Faltan %d monedas" % (price(id,area)-coins)
	return ""
func hire_requirement(role: String,area: int) -> Dictionary:
	var count: int=worker_count(role,area);var data: Dictionary=town(area);var value:=0;var goal:=0;var text:=""
	match role:
		"lumberjack":
			value=int(data["sold"]["wood"]) if count==0 else sold_total(area);goal=[4,20,50][mini(count,2)]
			text="Vendé %d %s · %d/%d" % [goal,"maderas" if count==0 else "productos",mini(value,goal),goal]
		"hunter":
			value=int(data["sold"]["meat"]) if count==0 else sold_total(area);goal=[4,35,70][mini(count,2)]
			text="Vendé %d %s · %d/%d" % [goal,"carnes" if count==0 else "productos",mini(value,goal),goal]
		"cashier":
			var product: String=PRODUCTS[mini(count,1)];value=int(data["sold"][product]);goal=4
			text="Vendé 4 %s · %d/4" % ["maderas" if product=="wood" else "carnes",mini(value,4)]
		"porter":
			if worker_count("cashier",area)<2:return {"ready":false,"text":"Contratá a los dos cajeros"}
			if worker_count("lumberjack",area)+worker_count("hunter",area)==0:return {"ready":false,"text":"Contratá un leñador o un cazador"}
			value=sold_total(area);goal=20;text="Vendé 20 productos · %d/20" % mini(value,20)
		"sentinel":
			if worker_count("hunter",area)==0:return {"ready":false,"text":"Contratá primero un cazador para recoger su botín"}
			value=sold_total(area);goal=30 if count==0 else 80;text="Vendé %d productos · %d/%d" % [goal,mini(value,goal),goal]
	return {"ready":value>=goal,"text":text}
func pay(amount: int) -> bool:
	if amount<0 or coins<amount:return false
	coins-=amount;changed.emit();return true
func buy(id: String,area: int) -> bool:
	if not buy_reason(id,area).is_empty():return false
	pay(price(id,area))
	var data: Dictionary=town(area)
	if HIRE_PRICES.has(id):
		data["workers"][id]["level"]+=1
		if id in HARVEST_ROLES and worker_count(id,area)>1:
			var job: Dictionary=data["extras"][id][worker_count(id,area)-2];job["target"]=(worker_count(id,area)-1)%positions("wood" if id=="lumberjack" else "meat").size()
	elif id=="rail":data["rails"]+=1
	elif id=="tool":data["tool"]+=1
	elif id=="pack":pack_level+=1
	elif id=="train":data["train_level"]+=1
	changed.emit();return true

func goals(area: int) -> Array[Dictionary]:
	var data: Dictionary=town(area)
	return [
		{"id":"sales","title":"Vender %d productos" % (40+area*30),"value":sold_total(area),"goal":40+area*30},
		{"id":"lumberjack","title":"Contratar al leñador","value":mini(1,int(data["workers"]["lumberjack"]["level"])),"goal":1},
		{"id":"hunter","title":"Contratar al cazador","value":mini(1,int(data["workers"]["hunter"]["level"])),"goal":1},
		{"id":"cashier","title":"Contratar a los dos cajeros","value":worker_count("cashier",area),"goal":2},
		{"id":"rail","title":"Conectar los tres tramos del tren","value":int(data["rails"]),"goal":3}
	]
func goal_progress(area: int) -> int:
	var completed:=0
	for goal in goals(area):
		if int(goal["value"])>=int(goal["goal"]):completed+=1
	return completed
func charter_price(area: int) -> int:return 80*(area+1)
func charter_ready(area: int) -> bool:return goal_progress(area)==goals(area).size()

func next_task(area: int) -> Dictionary:
	var data: Dictionary=town(area)
	if bag_free()<6 and bag_count()>0:
		for product in PRODUCTS:
			if int(bag[product])>0:return _delivery_task(product,area)
	# Sell a little of BOTH resources before introducing a hire. No menu tutorial
	# replaces the player's first manual harvest -> delivery -> paid sale.
	for product in PRODUCTS:
		if int(data["sold"][product])>=4:continue
		if int(bag[product])>0:return _delivery_task(product,area)
		if int(data["stock"][product])>0:
			if not cashier_for(product,area):return {"id":"trade","title":"Atendé la caja de "+("madera" if product=="wood" else "carne"),"detail":"Quedate cerca para cobrar los pedidos. Un cajero podrá atender cuando te alejés.","action":"guide","button":"VER CAJA","at":COUNTERS[product]}
			return {"id":"trade","title":"Los clientes están comprando","detail":"Tu cajero cobra los pedidos. Podés seguir cosechando.","action":"guide","button":"VER FILA","at":COUNTERS[product]}
		return _harvest_task(product,area)
	for requirement in [["lumberjack",1],["cashier",1],["hunter",1],["cashier",2]]:
		var role: String=requirement[0]
		if worker_count(role,area)<int(requirement[1]):
			if buy_reason(role,area).is_empty():return _hire_task(role,area)
			var gate: Dictionary=hire_requirement(role,area)
			if not gate["ready"]:return _harvest_task("wood" if role=="lumberjack" or role=="cashier" and worker_count(role,area)==0 else "meat",area)
			return _funding_task(area,"Ahorrá para "+("el cajero de madera" if role=="cashier" and worker_count(role,area)==0 else "el cajero de carne" if role=="cashier" else "un "+("leñador" if role=="lumberjack" else "cazador")),price(role,area))
	for role in ["porter","sentinel"]:
		if worker_count(role,area)==0 and buy_reason(role,area).is_empty():return _hire_task(role,area)
	if not operating(area):
		if coins>=price("rail",area):return {"id":"trade","title":"Construí las vías · tramo %d de 3" % (int(data["rails"])+1),"detail":"%d monedas · El tren llevará la carga a los puestos." % price("rail",area),"action":"shop","button":"CONSTRUIR","buy":"rail","at":Vector3(0,0,16.5)}
		return _funding_task(area,"Completá las vías · %d/3" % int(data["rails"]),price("rail",area))
	if not charter_ready(area):return {"id":"trade","title":"El tren ya vende por vos","detail":"%d/%d productos vendidos. Cazá o cortá más para acelerar." % [sold_total(area),40+area*30],"action":"guide","button":"VER TREN","at":DEPOT}
	return {"id":"trade","title":"Próximo pueblo disponible" if area<5 else "Red comercial completada", "detail":"Pasaje: %d monedas. Tu tren sigue vendiendo acá." % charter_price(area) if area<5 else "Seis pueblos conectados. Mejorá los equipos y ampliá tu negocio.","action":"route" if area<5 else "shop","button":"ABRIR RUTA" if area<5 else "MEJORAR","at":DEPOT}

func _hire_task(role: String,area: int) -> Dictionary:
	var name_: String={"lumberjack":"un leñador","hunter":"un cazador","cashier":"al cajero de madera" if worker_count(role,area)==0 else "al cajero de carne","porter":"un porteador","sentinel":"un centinela"}.get(role,role)
	return {"id":"trade","title":"Ya podés contratar "+name_,"detail":"%d monedas · Desbloqueado por tus ventas. Elegí CONTRATAR en Taller." % price(role,area),"action":"shop","button":"CONTRATAR","buy":role,"at":TOWER_POSITIONS[0] if role=="sentinel" else COUNTERS["wood" if worker_count(role,area)==0 else "meat"] if role=="cashier" else DEPOT}
func _harvest_task(product: String,area: int) -> Dictionary:
	var index:=0
	for candidate in range(positions(product).size()):
		if ground_count(product,candidate,area)>0 and bag_free()>0:return {"id":"trade","title":"Recogé la madera que quedó" if product=="wood" else "Recogé la carne que quedó","detail":"Acercate al botín: la recogida es automática.","action":"guide","button":"SEÑALAR","at":positions(product)[candidate]}
		if active_node(product,candidate,area):index=candidate;break
	return {"id":"trade","title":"Acercate al pino" if product=="wood" else "Acercate al oso polar","detail":"Los golpes y la recogida son automáticos. Vos dirigís al personaje.","action":"guide","button":"SEÑALAR","at":positions(product)[index]}
func _delivery_task(product: String,area: int) -> Dictionary:
	return {"id":"trade","title":"Llevá "+("madera" if product=="wood" else "carne")+" a los clientes","detail":"Entregás al acercarte. %d monedas por unidad; atendé hasta contratar cajero." % unit_price(product,area),"action":"guide","button":"VER PUESTO","at":COUNTERS[product]}
func _funding_task(area: int,title: String,target: int) -> Dictionary:
	for product in PRODUCTS:
		if int(bag[product])>0:return _delivery_task(product,area)
	var available: int=int(town(area)["depot"]["wood"])+int(town(area)["depot"]["meat"])
	if available>0 and worker_count("porter",area)==0 and not operating(area):return {"id":"trade","title":"Retirá la carga de tus trabajadores","detail":"Acercate al depósito y luego a los puestos. Podés contratar un porteador.","action":"guide","button":"VER DEPÓSITO","at":DEPOT}
	var task: Dictionary=_harvest_task("meat" if int(town(area)["stock"]["meat"])<6 else "wood",area)
	task["title"]=title;task["detail"]="%d/%d monedas. Seguí cosechando y vendiendo." % [coins,target];return task

func worker_job(role: String,area: int,slot: int=0) -> Dictionary:
	return town(area)["workers"][role] if slot==0 else town(area)["extras"][role][slot-1]
func worker_route(role: String,area: int,slot: int=0) -> Array[Vector3]:
	var worker: Dictionary=worker_job(role,area,slot)
	# These map routes are immutable. Reuse them during offline catch-up
	# instead of allocating and measuring a route for every worker step.
	return worker_paths[int(worker["target"])+(TREE_POSITIONS.size() if role=="hunter" else 0)]
func path_length(points: Array[Vector3]) -> float:
	var length:=0.0
	for index in range(points.size()-1):length+=points[index].distance_to(points[index+1])
	return length
func path_at(points: Array[Vector3],distance: float) -> Vector3:
	for index in range(points.size()-1):
		var span: float=points[index].distance_to(points[index+1])
		if distance<=span:return points[index].lerp(points[index+1],clampf(distance/maxf(.001,span),0,1))
		distance-=span
	return points[-1]
func worker_position(role: String,area: int,slot: int=0) -> Vector3:
	var data: Dictionary=worker_job(role,area,slot);var points: Array[Vector3]=worker_route(role,area,slot)
	var ratio: float=float(data["progress"])
	if data["phase"]=="work":ratio=1.0
	if data["phase"]=="back":ratio=1.0-ratio
	return path_at(points,path_length(points)*ratio)
func train_position(area: int,behind: float=0) -> Vector3:
	var points: Array[Vector3]=[];points.assign(RAIL_POINTS)
	return path_at(points,fposmod(float(town(area)["train"]["distance"])-behind,TRACK_LENGTH))

func tick(delta: float,unlocked: int=0,player_area: int=-1,player_at: Vector3=Vector3.INF,defending_area: int=-1) -> void:
	if not is_finite(delta) or delta<=0:return
	var remaining: float=minf(delta,7200.0)
	while remaining>.0001:
		var step: float=minf(.25,remaining);remaining-=step;clock+=step
		for area in range(clampi(unlocked,0,5)+1):_tick_town(step,area,player_area,player_at,area==defending_area)

func _tick_town(delta: float,area: int,player_area: int,player_at: Vector3,defending: bool) -> void:
	var data: Dictionary=town(area)
	for product in PRODUCTS:
		for index in range(data["nodes"][product].size()):
			var node: Dictionary=data["nodes"][product][index]
			if float(node["respawn"])>0:
				node["respawn"]=maxf(0,float(node["respawn"])-delta)
				if float(node["respawn"])<=0:node["hp"]=max_hp(product,index)
		var queue: Array=data["queues"][product]
		data["arrivals"][product]=maxf(0,float(data["arrivals"][product])-delta)
		if queue.size()<QUEUE_CAPACITY and float(data["arrivals"][product])<=0:
			var id: int=int(data["next_customer"]);data["next_customer"]=id+1
			var quantity: int=2+id%3
			queue.append({"id":id,"quantity":quantity,"remaining":quantity,"arrival":2.6});data["arrivals"][product]=arrival_interval(product,area)
		for customer in queue:customer["arrival"]=maxf(0,float(customer["arrival"])-delta)
		data["service"][product]=maxf(0,float(data["service"][product])-delta)
		var attended: bool=cashier_for(product,area) or area==player_area and counter_in_reach(player_at,product)
		if attended and not queue.is_empty() and float(queue[0]["arrival"])<=0 and float(data["service"][product])<=0 and int(data["stock"][product])>0:
			data["stock"][product]-=1;queue[0]["remaining"]-=1;data["service"][product]=.38
			if int(queue[0]["remaining"])==0:
				var buyer: Dictionary=queue.pop_front();var quantity: int=buyer["quantity"]
				var payment: int=quantity*unit_price(product,area)
				coins=mini(1000000000,coins+payment);data["sold"][product]+=quantity;data["customers"]+=1
				earned.emit(area,product,payment,quantity);changed.emit()
	for role in HARVEST_ROLES:
		for slot in range(worker_count(role,area)):_tick_worker(delta,role,area,slot)
	_tick_carrier(delta,area);_tick_guards(delta,area,defending)
	if operating(area):_tick_train(delta,area)

func _tick_worker(delta: float,role: String,area: int,slot: int=0) -> void:
	var data: Dictionary=town(area);var worker: Dictionary=worker_job(role,area,slot)
	var product: String="wood" if role=="lumberjack" else "meat"
	var duration: float=worker_seconds[int(worker["target"])+(TREE_POSITIONS.size() if role=="hunter" else 0)]
	if worker["phase"] in ["out","back"]:
		worker["progress"]=minf(1,float(worker["progress"])+delta/maxf(.1,duration))
		if float(worker["progress"])<1:return
		if worker["phase"]=="out":worker["phase"]="work";worker["clock"]=0;return
		var amount: int=mini(int(worker["cargo"]),DEPOT_CAPACITY-int(data["depot"][product]))
		data["depot"][product]+=amount;worker["cargo"]-=amount
		if int(worker["cargo"])>0:return # A full warehouse preserves the carried goods.
		worker["phase"]="out";worker["progress"]=0.0
		worker["target"]=(int(worker["target"])+1)%positions(product).size()
		for offset in range(positions(product).size()):
			var next: int=(int(worker["target"])+offset)%positions(product).size()
			if active_node(product,next,area) or ground_count(product,next,area)>0:worker["target"]=next;break
	elif worker["phase"]=="work":
		worker["clock"]+=delta
		if float(worker["clock"])<.65:return
		worker["clock"]=0.0
		if ground_count(product,int(worker["target"]),area)>0:
			var quantity: int=mini(5 if product=="wood" else 12,ground_count(product,int(worker["target"]),area))
			data["field_"+product][int(worker["target"]) ]-=quantity;worker["cargo"]=quantity;worker["phase"]="back";worker["progress"]=0.0;changed.emit();return
		if not active_node(product,int(worker["target"]),area):worker["phase"]="back";worker["progress"]=0.0;return
		var hit: Dictionary=_hit(product,int(worker["target"]),area,int(data["tool"]))
		if hit["finished"]:worker["cargo"]=yield_count(product,int(worker["target"]));worker["phase"]="back";worker["progress"]=0.0;changed.emit()

func carrier_route(area: int) -> Array[Vector3]:
	var job: Dictionary=town(area)["carrier"]
	return carrier_paths[job["from"]+":"+job["to"]]
func carrier_position(area: int) -> Vector3:
	var job: Dictionary=town(area)["carrier"]
	if job["phase"]=="load":return DEPOT
	var points: Array[Vector3]=carrier_route(area)
	return path_at(points,path_length(points)*float(job["progress"]))
func _tick_carrier(delta: float,area: int) -> void:
	if worker_count("porter",area)==0:return
	var data: Dictionary=town(area);var job: Dictionary=data["carrier"];var cargo: Dictionary=job["cargo"]
	if job["phase"]=="load":
		var capacity: int=12-int(cargo["wood"])-int(cargo["meat"])
		while capacity>0:
			var moved:=false
			for product in PRODUCTS:
				if capacity>0 and int(data["depot"][product])>0:data["depot"][product]-=1;cargo[product]+=1;capacity-=1;moved=true
			if not moved:break
		if int(cargo["wood"])+int(cargo["meat"])==0:return
		job["from"]="depot";job["to"]="wood" if int(cargo["wood"])>0 else "meat";job["progress"]=0.0;job["phase"]="travel";return
	if job["phase"]=="travel":
		job["progress"]=minf(1,float(job["progress"])+delta/maxf(.1,float(carrier_seconds[job["from"]+":"+job["to"]])))
		if float(job["progress"])<1:return
		job["phase"]="load" if job["to"]=="depot" else "unload";return
	if job["phase"]=="unload":
		var product: String=job["to"];var quantity: int=mini(int(cargo[product]),STOCK_CAPACITY-int(data["stock"][product]))
		cargo[product]-=quantity;data["stock"][product]+=quantity
		if int(cargo[product])>0:return
		job["from"]=product;job["to"]="meat" if product=="wood" and int(cargo["meat"])>0 else "depot";job["progress"]=0.0;job["phase"]="travel"

func _launch(area: int,tower: int,target: int) -> void:
	var data: Dictionary=town(area)
	if data["shots"].size()>=8:return
	data["shots"].append({"id":data["next_shot"],"tower":tower,"target":target,"remaining":.28,"duration":.28})
	data["next_shot"]=(int(data["next_shot"])+1)%1000000000
func guard_signal(area: int) -> void:
	for tower in range(worker_count("sentinel",area)):_launch(area,tower,-1)
func _tick_guards(delta: float,area: int,defending: bool) -> void:
	var data: Dictionary=town(area)
	for index in range(data["shots"].size()-1,-1,-1):
		var shot: Dictionary=data["shots"][index];shot["remaining"]=maxf(0,float(shot["remaining"])-delta)
		if float(shot["remaining"])>0:continue
		var target: int=shot["target"]
		if target>=0 and active_node("meat",target,area) and int(data["field_meat"][target])+yield_count("meat",target)<=FIELD_CAPACITY:
			var hit: Dictionary=_hit("meat",target,area,int(data["tool"])+1)
			if hit["finished"]:data["field_meat"][target]+=int(hit["quantity"]);changed.emit()
		data["shots"].remove_at(index)
	if defending:return
	for tower in range(worker_count("sentinel",area)):
		data["guard_clock"][tower]=maxf(0,float(data["guard_clock"][tower])-delta)
		if float(data["guard_clock"][tower])>0:continue
		for target in [2,1,0]:
			if not active_node("meat",target,area) or int(data["field_meat"][target])+yield_count("meat",target)>FIELD_CAPACITY:continue
			_launch(area,tower,target);data["guard_clock"][tower]=1.1;break

func _tick_train(delta: float,area: int) -> void:
	var data: Dictionary=town(area);var train: Dictionary=data["train"]
	if float(train["wait"])>0:train["wait"]=maxf(0,float(train["wait"])-delta);return
	var stop: int=int(train["next_stop"])
	var destination: float=STOPS[stop] if stop<3 else TRACK_LENGTH
	train["distance"]=minf(destination,float(train["distance"])+delta*(7.0+float(data["train_level"]-1)*2.0))
	if float(train["distance"])<destination:return
	if stop==3:
		train["distance"]=0.0;train["next_stop"]=0;train["laps"]+=1;return
	if stop==0:
		for product in PRODUCTS:
			var quantity: int=mini(int(data["depot"][product]),8+6*(int(data["train_level"])-1)-int(train["cargo"][product]))
			data["depot"][product]-=quantity;train["cargo"][product]+=quantity
	else:
		var product: String=PRODUCTS[stop-1]
		var quantity: int=mini(int(train["cargo"][product]),STOCK_CAPACITY-int(data["stock"][product]))
		train["cargo"][product]-=quantity;data["stock"][product]+=quantity
	train["next_stop"]=stop+1;train["wait"]=1.0

func snapshot() -> Dictionary:
	return {"schema":3,"coins":coins,"bag":bag.duplicate(),"pack_level":pack_level,"markets":markets.duplicate(true)}

func _restore_job(source: Dictionary,target: Dictionary,product: String,slot: int=0) -> void:
	target["phase"]=source.get("phase","out") if source.get("phase") in ["out","work","back"] else "out"
	target["target"]=int(Store.number(source,"target",slot,0,positions(product).size()-1))
	target["cargo"]=int(Store.number(source,"cargo",0,0,5 if product=="wood" else 12))
	target["progress"]=Store.number(source,"progress",0,0,1);target["clock"]=Store.number(source,"clock",0,0,.65)

func restore(saved: Variant,offline_seconds: float,unlocked: int) -> void:
	if not saved is Dictionary:return
	var legacy: bool=saved.has("markets") and int(Store.number(saved,"schema",1,1,3))<2
	coins=int(Store.number(saved,"coins",0,0,1000000000));pack_level=int(Store.number(saved,"pack_level",1,1,3))
	var saved_bag: Dictionary=saved.get("bag",{}) if saved.get("bag") is Dictionary else {}
	bag["wood"]=int(Store.number(saved_bag,"wood",0,0,bag_capacity()));bag["meat"]=int(Store.number(saved_bag,"meat",0,0,bag_capacity()-int(bag["wood"])))
	var entries: Array=saved.get("markets",[]) if saved.get("markets") is Array else []
	for area in range(mini(entries.size(),markets.size())):
		if not entries[area] is Dictionary:continue
		var entry: Dictionary=entries[area];var data: Dictionary=town(area)
		for key in ["stock","depot","sold"]:
			var values: Dictionary=entry.get(key,{}) if entry.get(key) is Dictionary else {}
			for product in PRODUCTS:data[key][product]=int(Store.number(values,product,0,0,STOCK_CAPACITY if key=="stock" else DEPOT_CAPACITY if key=="depot" else 100000000))
		for key in ["arrivals","service"]:
			var values: Dictionary=entry.get(key,{}) if entry.get(key) is Dictionary else {}
			for product in PRODUCTS:data[key][product]=Store.number(values,product,data[key][product],0,6 if key=="arrivals" else .38)
		for key in ["rails","tool","train_level","customers","next_customer"]:data[key]=int(Store.number(entry,key,data[key],0 if key in ["rails","customers","next_customer"] else 1,3 if key in ["rails","tool","train_level"] else 100000000))
		var nodes: Dictionary=entry.get("nodes",{}) if entry.get("nodes") is Dictionary else {}
		for product in PRODUCTS:
			var row: Array=nodes.get(product,[]) if nodes.get(product) is Array else []
			for index in range(mini(row.size(),positions(product).size())):
				if not row[index] is Dictionary:continue
				var node: Dictionary=data["nodes"][product][index];var maximum: int=max_hp(product,index)
				node["respawn"]=Store.number(row[index],"respawn",0,0,respawn_time(product))
				var previous: int=int(Store.number(row[index],"hp",maximum,1,4 if legacy and product=="meat" else maximum))
				node["hp"]=ceili(float(previous)*float(maximum)/4.0) if legacy and product=="meat" else previous
		var workers: Dictionary=entry.get("workers",{}) if entry.get("workers") is Dictionary else {}
		for role in ROLE_NAMES:
			var source: Dictionary=workers.get(role,{}) if workers.get(role) is Dictionary else {}
			data["workers"][role]["level"]=int(Store.number(source,"level",0,0,ROLE_LIMITS[role]))
			if role in HARVEST_ROLES:_restore_job(source,data["workers"][role],"wood" if role=="lumberjack" else "meat")
		# Existing v0.22 stalls already sold unattended. Preserve that purchased
		# behaviour, including in older towns, rather than charging for it again.
		if legacy and area<=unlocked:data["workers"]["cashier"]["level"]=2
		var extras: Dictionary=entry.get("extras",{}) if entry.get("extras") is Dictionary else {}
		for role in HARVEST_ROLES:
			var jobs: Array=extras.get(role,[]) if extras.get(role) is Array else []
			for slot in range(2):
				var source: Dictionary=jobs[slot] if slot<jobs.size() and jobs[slot] is Dictionary else {}
				_restore_job(source,data["extras"][role][slot],"wood" if role=="lumberjack" else "meat",slot+1)
		for product in PRODUCTS:
			var field: Array=entry.get("field_"+product,[]) if entry.get("field_"+product) is Array else []
			for index in range(positions(product).size()):data["field_"+product][index]=int(Store.number({"count":field[index]} if index<field.size() else {},"count",0,0,FIELD_CAPACITY))
		var clocks: Array=entry.get("guard_clock",[]) if entry.get("guard_clock") is Array else []
		for index in range(2):data["guard_clock"][index]=Store.number({"count":clocks[index]} if index<clocks.size() else {},"count",0,0,1.1)
		data["next_shot"]=int(Store.number(entry,"next_shot",0,0,999999999))
		var shots: Array=entry.get("shots",[]) if entry.get("shots") is Array else []
		var shot_ids: Array[int]=[]
		for shot in shots.slice(0,8):
			if not shot is Dictionary or worker_count("sentinel",area)==0:continue
			var id: int=int(Store.number(shot,"id",data["next_shot"],0,999999999))
			if id in shot_ids:continue
			shot_ids.append(id);data["next_shot"]=maxi(data["next_shot"],id+1)%1000000000
			data["shots"].append({"id":id,"tower":int(Store.number(shot,"tower",0,0,worker_count("sentinel",area)-1)),"target":int(Store.number(shot,"target",0,-1,2)),"duration":.28,"remaining":Store.number(shot,"remaining",.28,0,.28)})
		var carrier: Dictionary=entry.get("carrier",{}) if entry.get("carrier") is Dictionary else {};var job: Dictionary=data["carrier"]
		for key in ["from","to"]:job[key]=carrier[key] if carrier.get(key) in ["depot","wood","meat"] else job[key]
		job["phase"]=carrier.get("phase","load") if carrier.get("phase") in ["load","travel","unload"] else "load"
		job["progress"]=Store.number(carrier,"progress",0,0,1)
		if job["phase"]=="unload" and job["to"]=="depot":job["phase"]="load"
		var carried: Dictionary=carrier.get("cargo",{}) if carrier.get("cargo") is Dictionary else {}
		job["cargo"]["wood"]=int(Store.number(carried,"wood",0,0,12));job["cargo"]["meat"]=int(Store.number(carried,"meat",0,0,12-int(job["cargo"]["wood"])))
		var train: Dictionary=entry.get("train",{}) if entry.get("train") is Dictionary else {};var target: Dictionary=data["train"]
		target["next_stop"]=int(Store.number(train,"next_stop",0,0,3));target["wait"]=Store.number(train,"wait",0,0,1);target["laps"]=int(Store.number(train,"laps",0,0,100000000))
		var next: int=target["next_stop"];var minimum: float=STOPS[next-1] if next>0 else 0.0;var maximum: float=STOPS[next] if next<3 else TRACK_LENGTH
		target["distance"]=Store.number(train,"distance",minimum,minimum,maximum)
		var cargo: Dictionary=train.get("cargo",{}) if train.get("cargo") is Dictionary else {}
		for product in PRODUCTS:target["cargo"][product]=int(Store.number(cargo,product,0,0,8+6*(int(data["train_level"])-1)))
		var queues: Dictionary=entry.get("queues",{}) if entry.get("queues") is Dictionary else {}
		for product in PRODUCTS:
			if not queues.get(product) is Array:continue
			data["queues"][product]=[]
			var ids: Array[int]=[]
			for customer in queues[product].slice(0,QUEUE_CAPACITY):
				if not customer is Dictionary:continue
				var id: int=int(Store.number(customer,"id",data["next_customer"],0,100000000))
				if id in ids:continue
				ids.append(id);data["next_customer"]=maxi(data["next_customer"],id+1)
				var quantity: int=int(Store.number(customer,"quantity",2,2,4))
				data["queues"][product].append({"id":id,"quantity":quantity,"remaining":int(Store.number(customer,"remaining",quantity,1,quantity)),"arrival":Store.number(customer,"arrival",0,0,3)})
	var before: int=coins
	tick(clampf(offline_seconds,0,7200),unlocked);offline_coins=coins-before
