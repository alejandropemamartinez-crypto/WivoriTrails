extends RefCounted
class_name WivoriWinterMarket

# A real goods ledger, shared by the visible workers, shoppers and train.
# The hero only works in response to a held action; hiring never drives it.
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
const HIRE_PRICES={"lumberjack":60,"hunter":120}
const ROLE_NAMES={"lumberjack":"Leñador","hunter":"Cazador"}
const MANUAL_REACH=2.5

var coins:=0
var bag: Dictionary={"wood":0,"meat":0}
var pack_level:=1
var markets: Array[Dictionary]=[]
var offline_coins:=0
var clock:=0.0

func _init() -> void:
	for area in range(6):markets.append(_new_market())

func _new_market() -> Dictionary:
	var nodes: Dictionary={}
	for product in PRODUCTS:
		var row: Array[Dictionary]=[]
		for index in range(positions(product).size()):row.append({"hp":max_hp(product),"respawn":0.0})
		nodes[product]=row
	var queues: Dictionary={"wood":[],"meat":[]}
	var id:=0
	for product in PRODUCTS:
		for index in range(3):
			queues[product].append({"id":id,"quantity":2+index%2,"remaining":2+index%2,"arrival":0.0 if index==0 else float(index)*.65});id+=1
	return {"nodes":nodes,"stock":{"wood":0,"meat":0},"depot":{"wood":0,"meat":0},"queues":queues,"next_customer":id,
		"arrivals":{"wood":3.0,"meat":5.0},"service":{"wood":0.0,"meat":0.0},"sold":{"wood":0,"meat":0},"customers":0,
		"workers":{"lumberjack":_new_worker(),"hunter":_new_worker()},"rails":0,"tool":1,"train_level":1,
		"train":{"distance":0.0,"next_stop":0,"wait":0.0,"cargo":{"wood":0,"meat":0},"laps":0}}

func _new_worker() -> Dictionary:return {"level":0,"phase":"out","progress":0.0,"target":0,"cargo":0,"clock":0.0}
func town(area: int) -> Dictionary:return markets[clampi(area,0,5)]
func positions(product: String) -> Array:return TREE_POSITIONS if product=="wood" else BEAR_POSITIONS
func max_hp(product: String) -> int:return 3 if product=="wood" else 4
func yield_count(product: String) -> int:return 5 if product=="wood" else 6
func respawn_time(product: String) -> float:return 14.0 if product=="wood" else 18.0
func unit_price(product: String,area: int) -> int:return (4 if product=="wood" else 6)+area*2
func bag_count() -> int:return int(bag["wood"])+int(bag["meat"])
func bag_capacity() -> int:return 16+(pack_level-1)*8
func bag_free() -> int:return maxi(0,bag_capacity()-bag_count())
func active_node(product: String,index: int,area: int) -> bool:
	return product in PRODUCTS and index>=0 and index<positions(product).size() and float(town(area)["nodes"][product][index]["respawn"])<=0
func sold_total(area: int) -> int:return int(town(area)["sold"]["wood"])+int(town(area)["sold"]["meat"])
func operating(area: int) -> bool:return int(town(area)["rails"])==3

func context(at: Vector3,area: int) -> Dictionary:
	# Counter/depot interactions take priority over a nearby harvest target.
	for product in PRODUCTS:
		if at.distance_to(COUNTERS[product])<=MANUAL_REACH:
			var count: int=mini(int(bag[product]),STOCK_CAPACITY-int(town(area)["stock"][product]))
			return {"kind":"deliver","product":product,"at":COUNTERS[product],"title":"ENTREGAR "+("MADERA" if product=="wood" else "CARNE"),"detail":"%d en mochila · %d/%d en el puesto" % [bag[product],town(area)["stock"][product],STOCK_CAPACITY],"enabled":count>0}
	if at.distance_to(DEPOT)<=MANUAL_REACH:
		var count: int=int(town(area)["depot"]["wood"])+int(town(area)["depot"]["meat"])
		return {"kind":"load","at":DEPOT,"title":"CARGAR MOCHILA","detail":"Depósito: %d madera · %d carne" % [town(area)["depot"]["wood"],town(area)["depot"]["meat"]],"enabled":count>0 and bag_free()>0}
	var best: Dictionary={};var distance:=MANUAL_REACH
	for product in PRODUCTS:
		for index in range(positions(product).size()):
			if not active_node(product,index,area):continue
			var candidate: float=at.distance_to(positions(product)[index])
			if candidate>distance:continue
			distance=candidate
			var room: bool=bag_free()>=yield_count(product)
			best={"kind":"harvest","product":product,"index":index,"at":positions(product)[index],"title":("HACHA · CORTAR" if product=="wood" else "HOZ · CAZAR") if room else "VENDÉ TU CARGA", "detail":"Mantené pulsado · %d golpes · +%d %s" % [ceili(float(town(area)["nodes"][product][index]["hp"])/float(town(area)["tool"])),yield_count(product),"madera" if product=="wood" else "carne"] if room else "Necesitás %d espacios libres en la mochila" % yield_count(product),"enabled":room}
	if not best.is_empty():return best
	return {"kind":"walk","at":at,"title":"ACERCATE","detail":"Pinos a la izquierda · Osos a la derecha","enabled":false}

func use(at: Vector3,area: int) -> Dictionary:
	var action: Dictionary=context(at,area)
	if not action["enabled"]:return {}
	match action["kind"]:
		"harvest":
			var product: String=action["product"];var index: int=action["index"]
			var result: Dictionary=_hit(product,index,area,int(town(area)["tool"]))
			if result["finished"]:bag[product]=int(bag[product])+yield_count(product)
			changed.emit();return action.merged(result)
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
	return {"finished":finished,"quantity":yield_count(product) if finished else 0}

func price(id: String,area: int) -> int:
	var data: Dictionary=town(area)
	if HIRE_PRICES.has(id):return int(HIRE_PRICES[id])*(1+int(data["workers"][id]["level"])*2)
	if id=="rail":return RAIL_PRICES[int(data["rails"])] if int(data["rails"])<3 else 0
	if id=="tool":return 100*int(data["tool"])
	if id=="pack":return 90*pack_level
	if id=="train":return 300*int(data["train_level"])
	if id=="supplies":return 80
	return 0
func buy_reason(id: String,area: int) -> String:
	var data: Dictionary=town(area)
	if not id in ["lumberjack","hunter","rail","tool","pack","train","supplies"]:return "Mejora desconocida"
	if HIRE_PRICES.has(id) and int(data["workers"][id]["level"])>=3:return "Equipo al máximo"
	if id=="rail":
		if operating(area):return "Circuito ferroviario completo"
		if int(data["workers"]["lumberjack"]["level"])==0 or int(data["workers"]["hunter"]["level"])==0:return "Contratá primero al leñador y al cazador"
	if id=="tool" and int(data["tool"])>=3:return "Herramientas al máximo"
	if id=="pack" and pack_level>=3:return "Mochila al máximo"
	if id=="train" and not operating(area):return "Completá los tres tramos de vías"
	if id=="train" and int(data["train_level"])>=3:return "Tren al máximo"
	if coins<price(id,area):return "Faltan %d monedas" % (price(id,area)-coins)
	return ""
func pay(amount: int) -> bool:
	if amount<0 or coins<amount:return false
	coins-=amount;changed.emit();return true
func buy(id: String,area: int) -> bool:
	if not buy_reason(id,area).is_empty():return false
	pay(price(id,area))
	var data: Dictionary=town(area)
	if HIRE_PRICES.has(id):data["workers"][id]["level"]+=1
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
		if int(data["sold"][product])>=2:continue
		if int(bag[product])>0:return _delivery_task(product,area)
		if int(data["stock"][product])>0:return {"id":"trade","title":"Los clientes están comprando","detail":"Cada pedido completo paga monedas. Podés seguir cosechando.","action":"guide","button":"VER FILA","at":COUNTERS[product]}
		return _harvest_task(product,area)
	for role in ["lumberjack","hunter"]:
		if int(data["workers"][role]["level"])==0:
			if coins>=price(role,area):return {"id":"trade","title":"Ya podés contratar al "+ROLE_NAMES[role].to_lower(),"detail":"%d monedas · Trabaja y lleva la carga al depósito." % price(role,area),"action":"shop","button":"CONTRATAR","buy":role,"at":DEPOT}
			return _funding_task(area,"Ahorrá para el "+ROLE_NAMES[role].to_lower(),price(role,area))
	if not operating(area):
		if coins>=price("rail",area):return {"id":"trade","title":"Construí las vías · tramo %d de 3" % (int(data["rails"])+1),"detail":"%d monedas · El tren llevará la carga a los puestos." % price("rail",area),"action":"shop","button":"CONSTRUIR","buy":"rail","at":Vector3(0,0,16.5)}
		return _funding_task(area,"Completá las vías · %d/3" % int(data["rails"]),price("rail",area))
	if not charter_ready(area):return {"id":"trade","title":"El tren ya vende por vos","detail":"%d/%d productos vendidos. Cazá o cortá más para acelerar." % [sold_total(area),40+area*30],"action":"guide","button":"VER TREN","at":DEPOT}
	return {"id":"trade","title":"Próximo pueblo disponible" if area<5 else "Red comercial completada", "detail":"Pasaje: %d monedas. Tu tren sigue vendiendo acá." % charter_price(area) if area<5 else "Seis pueblos conectados. Mejorá los equipos y ampliá tu negocio.","action":"route" if area<5 else "shop","button":"ABRIR RUTA" if area<5 else "MEJORAR","at":DEPOT}

func _harvest_task(product: String,area: int) -> Dictionary:
	var index:=0
	for candidate in range(positions(product).size()):
		if active_node(product,candidate,area):index=candidate;break
	return {"id":"trade","title":"Cortá un pino con el hacha" if product=="wood" else "Cazá un oso polar con la hoz","detail":"Movete hasta la flecha y mantené pulsado "+("HACHA." if product=="wood" else "HOZ."),"action":"guide","button":"SEÑALAR","at":positions(product)[index]}
func _delivery_task(product: String,area: int) -> Dictionary:
	return {"id":"trade","title":"Llevá "+("madera" if product=="wood" else "carne")+" a los clientes","detail":"Acercate al puesto y pulsá ENTREGAR. Cada unidad vale %d monedas." % unit_price(product,area),"action":"guide","button":"VER PUESTO","at":COUNTERS[product]}
func _funding_task(area: int,title: String,target: int) -> Dictionary:
	for product in PRODUCTS:
		if int(bag[product])>0:return _delivery_task(product,area)
	var available: int=int(town(area)["depot"]["wood"])+int(town(area)["depot"]["meat"])
	if available>0:return {"id":"trade","title":"Retirá la carga de tus trabajadores","detail":"Depósito → mochila → puestos. El tren hará este recorrido por vos.","action":"guide","button":"VER DEPÓSITO","at":DEPOT}
	var task: Dictionary=_harvest_task("meat" if int(town(area)["stock"]["meat"])<6 else "wood",area)
	task["title"]=title;task["detail"]="%d/%d monedas. Seguí cosechando y vendiendo." % [coins,target];return task

func worker_route(role: String,area: int) -> Array[Vector3]:
	var worker: Dictionary=town(area)["workers"][role]
	var product: String="wood" if role=="lumberjack" else "meat"
	var target: Vector3=positions(product)[int(worker["target"])%positions(product).size()]+Vector3(0,0,-1.5)
	if role=="lumberjack":return [DEPOT,Vector3(-17.6,0,20.1),target]
	return [DEPOT,Vector3(-12,0,20.0),Vector3(6.2,0,20.0),Vector3(6.2,0,22.3),target]
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
func worker_position(role: String,area: int) -> Vector3:
	var data: Dictionary=town(area)["workers"][role];var points: Array[Vector3]=worker_route(role,area)
	var ratio: float=float(data["progress"])
	if data["phase"]=="work":ratio=1.0
	if data["phase"]=="back":ratio=1.0-ratio
	return path_at(points,path_length(points)*ratio)
func train_position(area: int,behind: float=0) -> Vector3:
	var points: Array[Vector3]=[];points.assign(RAIL_POINTS)
	return path_at(points,fposmod(float(town(area)["train"]["distance"])-behind,TRACK_LENGTH))

func tick(delta: float,unlocked: int=0) -> void:
	if not is_finite(delta) or delta<=0:return
	var remaining: float=minf(delta,7200.0)
	while remaining>.0001:
		var step: float=minf(.25,remaining);remaining-=step;clock+=step
		for area in range(clampi(unlocked,0,5)+1):_tick_town(step,area)

func _tick_town(delta: float,area: int) -> void:
	var data: Dictionary=town(area)
	for product in PRODUCTS:
		for node in data["nodes"][product]:
			if float(node["respawn"])>0:
				node["respawn"]=maxf(0,float(node["respawn"])-delta)
				if float(node["respawn"])<=0:node["hp"]=max_hp(product)
		var queue: Array=data["queues"][product]
		data["arrivals"][product]=maxf(0,float(data["arrivals"][product])-delta)
		if queue.size()<QUEUE_CAPACITY and float(data["arrivals"][product])<=0:
			var id: int=int(data["next_customer"]);data["next_customer"]=id+1
			var quantity: int=2+id%3
			queue.append({"id":id,"quantity":quantity,"remaining":quantity,"arrival":2.6});data["arrivals"][product]=5.5
		for customer in queue:customer["arrival"]=maxf(0,float(customer["arrival"])-delta)
		data["service"][product]=maxf(0,float(data["service"][product])-delta)
		if not queue.is_empty() and float(queue[0]["arrival"])<=0 and float(data["service"][product])<=0 and int(data["stock"][product])>0:
			data["stock"][product]-=1;queue[0]["remaining"]-=1;data["service"][product]=.38
			if int(queue[0]["remaining"])==0:
				var buyer: Dictionary=queue.pop_front();var quantity: int=buyer["quantity"]
				var payment: int=quantity*unit_price(product,area)
				coins=mini(1000000000,coins+payment);data["sold"][product]+=quantity;data["customers"]+=1
				earned.emit(area,product,payment,quantity);changed.emit()
	for role in ROLE_NAMES:_tick_worker(delta,role,area)
	if operating(area):_tick_train(delta,area)

func _tick_worker(delta: float,role: String,area: int) -> void:
	var data: Dictionary=town(area);var worker: Dictionary=data["workers"][role]
	if int(worker["level"])==0:return
	var product: String="wood" if role=="lumberjack" else "meat"
	var duration: float=path_length(worker_route(role,area))/(3.3+float(worker["level"])*.7)
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
			if active_node(product,next,area):worker["target"]=next;break
	elif worker["phase"]=="work":
		worker["clock"]+=delta
		if float(worker["clock"])<.65:return
		worker["clock"]=0.0
		if not active_node(product,int(worker["target"]),area):worker["phase"]="back";worker["progress"]=0.0;return
		var hit: Dictionary=_hit(product,int(worker["target"]),area,int(worker["level"]))
		if hit["finished"]:worker["cargo"]=yield_count(product);worker["phase"]="back";worker["progress"]=0.0;changed.emit()

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
	return {"coins":coins,"bag":bag.duplicate(),"pack_level":pack_level,"markets":markets.duplicate(true)}

func restore(saved: Variant,offline_seconds: float,unlocked: int) -> void:
	if not saved is Dictionary:return
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
		for key in ["rails","tool","train_level","customers","next_customer"]:data[key]=int(Store.number(entry,key,data[key],0 if key in ["rails","customers","next_customer"] else 1,3 if key in ["rails","tool","train_level"] else 100000000))
		var nodes: Dictionary=entry.get("nodes",{}) if entry.get("nodes") is Dictionary else {}
		for product in PRODUCTS:
			var row: Array=nodes.get(product,[]) if nodes.get(product) is Array else []
			for index in range(mini(row.size(),positions(product).size())):
				if not row[index] is Dictionary:continue
				var target: Dictionary=data["nodes"][product][index]
				target["respawn"]=Store.number(row[index],"respawn",0,0,respawn_time(product));target["hp"]=int(Store.number(row[index],"hp",max_hp(product),1,max_hp(product)))
		var workers: Dictionary=entry.get("workers",{}) if entry.get("workers") is Dictionary else {}
		for role in ROLE_NAMES:
			if not workers.get(role) is Dictionary:continue
			var worker: Dictionary=data["workers"][role];var source: Dictionary=workers[role]
			worker["level"]=int(Store.number(source,"level",0,0,3));worker["phase"]=source.get("phase","out") if source.get("phase") in ["out","work","back"] else "out"
			worker["target"]=int(Store.number(source,"target",0,0,positions("wood" if role=="lumberjack" else "meat").size()-1))
			worker["cargo"]=int(Store.number(source,"cargo",0,0,6));worker["progress"]=Store.number(source,"progress",0,0,1);worker["clock"]=Store.number(source,"clock",0,0,.65)
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
