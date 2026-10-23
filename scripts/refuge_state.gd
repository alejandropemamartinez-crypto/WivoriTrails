extends RefCounted
class_name WivoriRefugeState

# The settlement economy owns no scene nodes. All commands validate their
# prerequisites here, including commands received from an old open panel.
signal changed
signal built(id: String, city: int)
signal opened(city: int)
signal message(text: String)

const Store=preload("res://scripts/save_store.gd")
const RESOURCE_NAMES={"wood":"Madera","food":"Comida","coal":"Carbón","iron":"Metal"}
const NAMES=["Paso Bruma","Valle Ámbar","Costa Cristal","Cumbre Cobre","Distrito Forja","Puerto Aurora"]
const LESSONS=["Encendé el corazón del refugio y organizá a sus primeros habitantes.","Invernaderos con 25 % más de comida y una enfermería para cuidar al pueblo.","Un puerto entre hielos: las expediciones salen un 20 % más rápido.","La cantera de altura produce un 30 % más de metal para toda la ruta.","Fundiciones de vapor con 35 % más de producción. Protegé la reserva de combustible.","Conectá los seis refugios: la producción de los otros pueblos sube al 45 %."]
const BUILDINGS={
	"core":{"name":"Corazón térmico","short":"CORAZÓN","at":Vector3.ZERO,"unlock":1,"wood":38,"coal":7,"why":"Calienta el refugio y abre nuevos edificios. Cada nivel amplía el círculo de calor."},
	"shelter":{"name":"Casas de abrigo","short":"HOGARES","at":Vector3(-7.4,0,-4.5),"unlock":1,"wood":24,"coal":0,"why":"Cada nivel suma cuatro plazas. Recibí familias desde EQUIPO para ocupar los nuevos hogares."},
	"lumber":{"name":"Aserradero","short":"ASERRADERO","at":Vector3(-8,0,5.5),"unlock":1,"wood":20,"coal":0,"resource":"wood","rate":1.15,"why":"Asigná habitantes para producir madera. Sin trabajadores, el aserradero no produce."},
	"kitchen":{"name":"Huerto de invierno","short":"INVERNADERO","at":Vector3(7.7,0,5.8),"unlock":1,"wood":28,"coal":0,"resource":"food","rate":.85,"why":"Los habitantes cultivan alimentos bajo cristal. La comida sostiene a las familias y financia las expediciones."},
	"coal":{"name":"Carbonería","short":"CARBONERÍA","at":Vector3(8.4,0,-3.8),"unlock":2,"wood":36,"coal":0,"resource":"coal","rate":.85,"why":"Produce el combustible del corazón térmico. Asigná al menos una persona cuando el pueblo crezca."},
	"mine":{"name":"Cantera de cobre","short":"CANTERA","at":Vector3(-12,0,-12.2),"unlock":3,"wood":70,"coal":12,"resource":"iron","rate":.62,"why":"El metal permite construir equipos y mejorar los refugios más avanzados."},
	"clinic":{"name":"Enfermería","short":"ENFERMERÍA","at":Vector3(-4.6,0,-12.6),"unlock":3,"wood":60,"coal":10,"why":"Mejora el bienestar de todos los habitantes y ayuda a mantener la producción durante el frío."},
	"watch":{"name":"Torre de guardia","short":"GUARDIA","at":Vector3(7,0,-12.5),"unlock":2,"wood":45,"coal":8,"why":"Protege los suministros de los mapaches. Cada nivel reduce los toques necesarios para ahuyentarlos."},
	"dock":{"name":"Muelle de exploración","short":"MUELLE","at":Vector3(-3.8,0,13.0),"unlock":4,"wood":110,"coal":22,"why":"Enviá una pareja de exploradores. Cada ruta trae recursos distintos mientras seguís construyendo."},
	"factory":{"name":"Fundición de vapor","short":"FUNDICIÓN","at":Vector3(10.3,0,13.0),"unlock":5,"wood":150,"coal":30,"resource":"iron","rate":1.7,"why":"Transforma excedentes de madera y carbón en metal. Se pausa cuando faltan insumos."}
}
const ROUTES=[
	{"id":"supplies","name":"Caravana de suministros","time":35.0,"cost":{"food":18},"reward":{"wood":110,"coal":35},"detail":"Abastecé el siguiente refugio."},
	{"id":"copper","name":"Paso del cobre","time":50.0,"cost":{"food":26},"reward":{"iron":70,"coal":45},"detail":"Materiales para los equipos de nivel alto."},
	{"id":"families","name":"Luces en la nieve","time":65.0,"cost":{"food":32,"coal":12},"reward":{"food":90,"wood":60},"people":2,"detail":"Rescatá una familia y recibí provisiones."}
]
var resources: Dictionary={"wood":72.0,"food":50.0,"coal":30.0,"iron":0.0}
var cities: Array[Dictionary]=[]
var city:=0
var unlocked:=0
var lit:=false
var heat_boost:=false
var construction: Dictionary={}
var expedition: Dictionary={}
var completed_routes: Array[String]=[]
var expeditions_done:=0
var family_cooldown:=0.0
var raid_remaining:=0.0
var raid_hits:=0
var raid_clock:=0.0
var defended:=0
var offline_gains: Dictionary={}
var last_saved:=0.0
var ticks:=0.0

func _init() -> void:
	for index in range(NAMES.size()):cities.append(_new_city(index))

func _new_city(index: int) -> Dictionary:
	var levels: Dictionary={}
	var workers: Dictionary={}
	for id in BUILDINGS:levels[id]=0;workers[id]=0
	levels["core"]=1;levels["shelter"]=1
	if index>0:
		levels["core"]=mini(index+1,4);levels["shelter"]=2
		for id in ["lumber","kitchen","coal"]:levels[id]=1;workers[id]=1
	return {"levels":levels,"workers":workers,"people":4 if index==0 else 6,"time":0.0,"storm_clock":0.0,"storm_safe":0.0,"storms":0,"morale":80.0}

func town(index: int=-1) -> Dictionary:return cities[city if index<0 else index]
func level(id: String,index: int=-1) -> int:return int(town(index)["levels"].get(id,0))
func worker_count(id: String,index: int=-1) -> int:return int(town(index)["workers"].get(id,0))
func capacity(index: int=-1) -> int:return 2+4*level("shelter",index)
func used_workers(index: int=-1) -> int:
	var total:=0
	for count in town(index)["workers"].values():total+=int(count)
	if not expedition.is_empty() and int(expedition["city"])==(city if index<0 else index):total+=2
	return total
func free_workers(index: int=-1) -> int:return maxi(0,int(town(index)["people"])-used_workers(index))
func max_workers(id: String,index: int=-1) -> int:return mini(6,2*level(id,index))
func storm(index: int=-1) -> bool:
	return fposmod(float(town(index)["storm_clock"]),180.0)>=120.0 and fposmod(float(town(index)["storm_clock"]),180.0)<152.0
func storm_in() -> float:
	var phase:=fposmod(float(town()["storm_clock"]),180.0)
	return 152.0-phase if storm() else 120.0-phase if phase<120.0 else 300.0-phase
func temperature() -> int:return -18-city*3-(12 if storm() else 0)-(5 if fposmod(float(town()["time"]),240.0)>160.0 else 0)
func warmth(index: int=-1) -> float:
	if not lit:return 12.0
	var area: int=city if index<0 else index
	var fuel: bool=float(resources["coal"])>=.05 or level("core",area)==1
	var night: float=8.0 if fposmod(float(town(area)["time"]),240.0)>160.0 else 0.0
	return clampf(54.0+12.0*level("core",area)-float(area)*12.0-night-(25.0 if storm(area) else 0.0)-(32.0 if not fuel else 0.0)+(22.0 if heat_boost and fuel and area==city else 0.0),0,100)
func efficiency(index: int=-1) -> float:return .55+.45*float(town(index)["morale"])/100.0
func background_rate() -> float:return .45 if unlocked>=5 else .35
func expedition_time(index: int,area: int=-1) -> float:return float(ROUTES[index]["time"])*(.8 if (city if area<0 else area)==2 else 1.0)
func production(id: String,index: int=-1) -> float:
	if not lit or not BUILDINGS.has(id) or not BUILDINGS[id].has("rate"):return 0.0
	if id=="factory" and (float(resources["wood"])<121.2 or float(resources["coal"])<70.6):return 0.0
	var area: int=city if index<0 else index
	var bonus: float=1.25 if area==1 and id=="kitchen" else 1.3 if area==3 and id=="mine" else 1.35 if area==4 and id=="factory" else 1.0
	return float(BUILDINGS[id]["rate"])*float(worker_count(id,index))*float(level(id,index))*efficiency(index)*bonus
func cost(id: String) -> Dictionary:
	if not BUILDINGS.has(id):return {}
	# The founding kit always contains the first sawmill. Even if the player
	# spends every starting log elsewhere, there is still a renewable source.
	if id=="lumber" and level(id)==0:return {}
	var next: int=level(id)+1
	var factor: float=pow(1.65,next-1)*(1.0+float(city)*.10)
	var data: Dictionary=BUILDINGS[id]
	var price: Dictionary={"wood":ceili(float(data["wood"])*factor)}
	if int(data["coal"])>0 and (id!="core" or next>=2):price["coal"]=ceili(float(data["coal"])*factor)
	if next>=4:price["iron"]=ceili(9.0*pow(1.6,next-4))
	return price
func requirements(id: String) -> Dictionary:
	if not BUILDINGS.has(id):return {}
	if id!="core":return {"core":maxi(int(BUILDINGS[id]["unlock"]),level(id)+1)}
	var next: int=level("core")+1
	var needed: Dictionary={"lumber":maxi(1,ceili(float(next)/2.0)-1),"shelter":maxi(1,ceili(float(next)/2.0)-1)}
	if next>=3:needed["kitchen"]=maxi(1,ceili(float(next)/3.0)-1)
	if next>=4:needed["coal"]=maxi(1,next-3)
	if next>=6:needed["clinic"]=1
	if next>=7:needed["watch"]=2
	return needed
func affordable(price: Dictionary) -> bool:
	for key in price:
		if float(resources.get(key,0))+.0001<float(price[key]):return false
	return true
func spend(price: Dictionary) -> void:
	for key in price:resources[key]=maxf(0,float(resources[key])-float(price[key]))
func blocking_requirement(id: String) -> String:
	for key in requirements(id):
		if level(key)<int(requirements(id)[key]):return key
	return ""
func upgrade_reason(id: String) -> String:
	if not BUILDINGS.has(id):return "Edificio desconocido"
	if not lit:return "Encendé el corazón térmico"
	if level(id)>=8:return "Nivel máximo alcanzado"
	if not construction.is_empty():return "Terminá la construcción en curso"
	var blocker: String=blocking_requirement(id)
	if not blocker.is_empty():return "%s · nivel %d" % [BUILDINGS[blocker]["name"],requirements(id)[blocker]]
	if not affordable(cost(id)):return "Reuní los recursos que faltan"
	return ""
func ignite() -> bool:
	if lit:return false
	lit=true;changed.emit();message.emit("El refugio vuelve a tener calor. Construí el aserradero.");return true
func start_upgrade(id: String) -> bool:
	if not upgrade_reason(id).is_empty():return false
	var duration: float=4.0+float(level(id)+1)*2.0+float(city)
	spend(cost(id));construction={"id":id,"city":city,"target":level(id)+1,"remaining":duration,"duration":duration}
	changed.emit();return true
func assign(id: String,amount: int) -> bool:
	if not BUILDINGS.has(id) or not BUILDINGS[id].has("resource") or level(id)==0 or amount not in [-1,1]:return false
	var count: int=worker_count(id)
	if amount>0 and (free_workers()==0 or count>=max_workers(id)):return false
	if amount<0 and count==0:return false
	town()["workers"][id]=count+amount;changed.emit();return true
func receive_family() -> bool:
	if not lit or family_cooldown>0 or int(town()["people"])+2>capacity() or not affordable({"food":12}):return false
	spend({"food":12});town()["people"]+=2;family_cooldown=18.0;changed.emit();message.emit("¡Dos habitantes llegaron al refugio! Podés asignarles un trabajo.");return true
func goals(index: int=-1) -> Array[Dictionary]:
	var area: int=city if index<0 else index
	var special: String=["watch","clinic","dock","mine","factory","dock"][area]
	var special_level: int=[1,1,1,3,2,4][area]
	var result: Array[Dictionary]=[
		{"id":"core","title":"Corazón térmico · nivel %d" % (area+3),"value":level("core",area),"goal":area+3},
		{"id":"shelter","title":"Hogares · nivel %d" % mini(area+2,4),"value":level("shelter",area),"goal":mini(area+2,4)},
		{"id":"people","title":"Recibir a %d habitantes" % (8+area*2),"value":int(town(area)["people"]),"goal":8+area*2},
		{"id":special,"title":BUILDINGS[special]["name"]+" · nivel %d" % special_level,"value":level(special,area),"goal":special_level},
		{"id":"storm","title":"Proteger al pueblo de una ventisca","value":mini(1,int(town(area)["storms"])),"goal":1}
	]
	if area==5:result.append({"id":"routes","title":"Completar las tres rutas de expedición","value":completed_routes.size(),"goal":3})
	return result
func goal_progress(index: int=-1) -> int:
	var count:=0
	for goal in goals(index):
		if int(goal["value"])>=int(goal["goal"]):count+=1
	return count
func ready_next() -> bool:return city==unlocked and city<5 and goal_progress()==goals().size()
func passage_cost() -> Dictionary:return {"wood":80*(city+1),"food":30+city*10,"coal":20+city*10}
func open_next() -> bool:
	if not ready_next() or not affordable(passage_cost()):return false
	spend(passage_cost());unlocked+=1;changed.emit();opened.emit(unlocked);return true
func travel(destination: int) -> bool:
	if destination<0 or destination>unlocked or destination==city or raid_remaining>0:return false
	city=destination;heat_boost=false;raid_clock=0;changed.emit();return true
func start_expedition(index: int) -> bool:
	if index<0 or index>=ROUTES.size() or not expedition.is_empty() or level("dock")==0 or free_workers()<2:return false
	var route: Dictionary=ROUTES[index]
	if not affordable(route["cost"]):return false
	spend(route["cost"]);expedition={"index":index,"city":city,"remaining":expedition_time(index),"duration":expedition_time(index)};changed.emit();return true
func repel() -> bool:
	if raid_remaining<=0:return false
	raid_hits+=1
	if raid_hits>=maxi(1,5-level("watch")):
		raid_remaining=0;defended+=1;message.emit("¡Suministros protegidos! La guardia mantiene libre el camino.");changed.emit()
	return true
func next_task() -> Dictionary:
	if not lit:return {"id":"core","title":"Encendé el corazón térmico","detail":"Tocá ENCENDER. El calor devuelve la vida al campamento.","action":"ignite","button":"ENCENDER"}
	if raid_remaining>0:return {"id":"watch","title":"¡Mapaches en el almacén!","detail":"Tocá AHUYENTAR · %d señales restantes" % maxi(1,5-level("watch")-raid_hits),"action":"repel","button":"AHUYENTAR"}
	if not construction.is_empty():
		return {"id":construction["id"],"title":"%s · %d s" % [BUILDINGS[construction["id"]]["name"],ceili(float(construction["remaining"]))],"detail":"Obra en %s. Podés asignar habitantes mientras termina." % NAMES[int(construction["city"])],"action":"team","button":"EQUIPO"}
	for id in ["lumber","kitchen","coal"]:
		if id=="coal" and level("core")<2:continue
		if level(id)==0:return _building_task(id)
		if worker_count(id)==0:return {"id":id,"title":"Asigná alguien al "+BUILDINGS[id]["name"],"detail":"Abrí el edificio y tocá +. Los habitantes producen por vos.","action":"building","button":"ASIGNAR"}
	for goal in goals():
		if int(goal["value"])>=int(goal["goal"]):continue
		var id: String=goal["id"]
		if id=="people":
			if int(town()["people"])+2>capacity():return _building_task("shelter")
			return {"id":"shelter","title":"Recibí una nueva familia","detail":"Hay lugar para %d personas más · 12 de comida por familia." % (capacity()-int(town()["people"])),"action":"team","button":"RECIBIR"}
		if id=="storm":return {"id":"core","title":"Prepará al pueblo para la ventisca","detail":"%s · %d s. Calor de al menos 50%% para proteger a las familias." % ["Termina en" if storm() else "Llega en",ceili(storm_in())],"action":"building","button":"VER CALOR"}
		if id=="routes":return {"id":"dock","title":"Conectá la red de refugios","detail":"Completá una expedición de cada tipo · %d/3" % completed_routes.size(),"action":"fleet","button":"EXPEDICIONES"}
		return _building_task(id)
	if city<unlocked:return {"id":"dock","title":NAMES[unlocked]+" está disponible","detail":"Tu nueva base te espera. Los otros refugios siguen produciendo.","action":"route","button":"VIAJAR"}
	if city<5:
		for key in passage_cost():
			var missing: int=ceili(float(passage_cost()[key])-float(resources[key]))
			if missing>0:return _resource_task(key,missing,NAMES[city+1])
		return {"id":"dock","title":"¡Siguiente refugio preparado!","detail":NAMES[city+1]+" · El cargamento está listo. Abrí la ruta para viajar.","action":"route","button":"ABRIR RUTA"}
	return {"id":"core","title":"¡Los seis refugios están conectados!","detail":"Tu red sigue creciendo. Mejorá los edificios y organizá nuevas expediciones.","action":"route","button":"VER RED"}
func _building_task(id: String) -> Dictionary:
	var blocker:=blocking_requirement(id)
	if not blocker.is_empty():return _building_task(blocker)
	for key in cost(id):
		var missing: int=ceili(float(cost(id)[key])-float(resources[key]))
		if missing<=0:continue
		return _resource_task(key,missing,BUILDINGS[id]["name"])
	return {"id":id,"title":("Construí " if level(id)==0 else "Mejorá ")+BUILDINGS[id]["name"],"detail":"Nivel %d → %d · %s" % [level(id),level(id)+1,cost_text(cost(id))],"action":"building","button":"CONSTRUIR" if level(id)==0 else "MEJORAR"}
func _resource_task(key: String,missing: int,purpose: String) -> Dictionary:
	var producer: String={"wood":"lumber","food":"kitchen","coal":"coal","iron":"mine"}[key]
	if level(producer)==0:return _building_task(producer)
	if free_workers()==0 and worker_count(producer)==0:
		return {"id":producer,"title":"Reasigná alguien a "+BUILDINGS[producer]["name"],"detail":"Retirá una persona de otro trabajo con − y asignala al recurso que falta.","action":"team","button":"EQUIPO"}
	return {"id":producer,"title":"Reuní %d %s para %s" % [missing,RESOURCE_NAMES[key].to_lower(),purpose],"detail":"Producción actual: +%.1f/min. Asigná habitantes o mejorá ese edificio." % (production(producer)*60.0),"action":"building","button":"PRODUCCIÓN"}
func cost_text(price: Dictionary) -> String:
	var parts: PackedStringArray=[]
	for key in price:parts.append("%d %s" % [int(price[key]),RESOURCE_NAMES[key].to_lower()])
	return " · ".join(parts)

func tick(delta: float,offline: bool=false) -> void:
	if delta<=0 or not is_finite(delta):return
	ticks+=delta;family_cooldown=maxf(0,family_cooldown-delta)
	if not construction.is_empty():
		construction["remaining"]=maxf(0,float(construction["remaining"])-delta)
		if float(construction["remaining"])<=0:
			var finished: Dictionary=construction.duplicate();construction.clear()
			cities[int(finished["city"])]["levels"][finished["id"]]=int(finished["target"])
			built.emit(finished["id"],int(finished["city"]));changed.emit()
	if not expedition.is_empty():
		expedition["remaining"]=maxf(0,float(expedition["remaining"])-delta)
		if float(expedition["remaining"])<=0:
			var finished: Dictionary=expedition.duplicate();expedition.clear()
			var route: Dictionary=ROUTES[int(finished["index"])]
			for key in route["reward"]:resources[key]=float(resources[key])+float(route["reward"][key])
			if not str(route["id"]) in completed_routes:completed_routes.append(route["id"])
			if route.has("people"):
				var origin: int=int(finished["city"])
				cities[origin]["people"]=mini(capacity(origin),int(cities[origin]["people"])+int(route["people"]))
			expeditions_done+=1;message.emit("Expedición completada. El cargamento ya está en el almacén.");changed.emit()
	if not lit:return
	for area in range(unlocked+1):
		var data: Dictionary=town(area)
		data["time"]=float(data["time"])+delta
		var scale_: float=1.0 if area==city else background_rate()
		for id in BUILDINGS:
			if not BUILDINGS[id].has("resource"):continue
			var quantity: float=production(id,area)*scale_*delta
			if id=="factory":
				quantity=minf(quantity,minf(maxf(0,float(resources["wood"])-120.0)/1.2,maxf(0,float(resources["coal"])-70.0)/.6))
				resources["wood"]=maxf(0,float(resources["wood"])-quantity*1.2);resources["coal"]=maxf(0,float(resources["coal"])-quantity*.6)
			var key: String=BUILDINGS[id]["resource"]
			resources[key]=minf(10000000,float(resources[key])+quantity)
		resources["food"]=maxf(0,float(resources["food"])-float(data["people"])*.018*delta*scale_)
		if level("core",area)>=2:resources["coal"]=maxf(0,float(resources["coal"])-.035*float(level("core",area))*delta*scale_*(2.8 if heat_boost and area==city else 1.0))
		var comfort: float=85.0 if warmth(area)>=50 and float(resources["food"])>=1 else 42.0
		comfort=minf(100,comfort+float(level("clinic",area))*4.0)
		data["morale"]=move_toward(float(data["morale"]),comfort,delta*.25)
		# No unseen storms or theft penalties while the app is closed.
		if not offline and area==city and level("core",area)>=2:
			var before:=fposmod(float(data["storm_clock"]),180.0)
			data["storm_clock"]=float(data["storm_clock"])+delta
			var after:=fposmod(float(data["storm_clock"]),180.0)
			if before<120.0 and after>=120.0:data["storm_safe"]=0.0
			if after>=120.0 and after<152.0 and warmth(area)>=50:data["storm_safe"]+=delta
			if before<152.0 and after>=152.0:
				if float(data["storm_safe"])>=25.0:data["storms"]+=1;message.emit("¡Ventisca superada! El pueblo sigue a salvo.");changed.emit()
				else:message.emit("El refugio resistió, pero necesita más calor para proteger a todos en la próxima ventisca.")
	if not offline and city>=2:
		raid_clock+=delta
		if raid_remaining>0:
			raid_remaining=maxf(0,raid_remaining-delta)
			if raid_remaining<=0:resources["wood"]=maxf(0,float(resources["wood"])-minf(30,float(resources["wood"])*.08));message.emit("Los mapaches se llevaron algo de madera. Mejorá la guardia para proteger el almacén.")
		elif raid_clock>=210.0:raid_clock=0;raid_remaining=14.0;raid_hits=0;message.emit("¡Mapaches en el almacén! Tocá AHUYENTAR.");changed.emit()

func snapshot(now: float=-1) -> Dictionary:
	return {"version":8,"refuge":1,"resources":resources.duplicate(true),"cities":cities.duplicate(true),"city":city,"unlocked":unlocked,"lit":lit,"heat_boost":heat_boost,"construction":construction.duplicate(true),"expedition":expedition.duplicate(true),"completed_routes":completed_routes.duplicate(),"expeditions_done":expeditions_done,"family_cooldown":family_cooldown,"raid_clock":raid_clock,"defended":defended,"last_saved":Time.get_unix_time_from_system() if now<0 else now}
func restore(data: Dictionary,now: float=-1) -> void:
	if data.get("refuge")!=1:return
	city=int(Store.number(data,"city",0,0,5));unlocked=int(Store.number(data,"unlocked",0,0,5));city=mini(city,unlocked)
	lit=data.get("lit",false)==true;heat_boost=data.get("heat_boost",false)==true
	var saved_resources: Dictionary=data.get("resources",{}) if data.get("resources") is Dictionary else {}
	for key in resources:resources[key]=Store.number(saved_resources,key,resources[key],0,10000000)
	var saved_cities: Array=data.get("cities",[]) if data.get("cities") is Array else []
	for index in range(mini(cities.size(),saved_cities.size())):
		if not saved_cities[index] is Dictionary:continue
		var saved: Dictionary=saved_cities[index]
		var levels: Dictionary=saved.get("levels",{}) if saved.get("levels") is Dictionary else {}
		for id in BUILDINGS:cities[index]["levels"][id]=int(Store.number(levels,id,1 if id in ["core","shelter"] else 0,1 if id in ["core","shelter"] else 0,8))
		cities[index]["people"]=int(Store.number(saved,"people",4,1,capacity(index)))
		var workers: Dictionary=saved.get("workers",{}) if saved.get("workers") is Dictionary else {}
		var available: int=int(cities[index]["people"])
		for id in BUILDINGS:
			var count: int=mini(available,int(Store.number(workers,id,0,0,max_workers(id,index)))) if BUILDINGS[id].has("resource") else 0
			cities[index]["workers"][id]=count;available-=count
		for key in ["time","storm_clock","storm_safe","storms","morale"]:cities[index][key]=Store.number(saved,key,cities[index][key],0,100 if key=="morale" else 100000000)
	construction.clear();expedition.clear();completed_routes.clear()
	var job: Dictionary=data.get("construction",{}) if data.get("construction") is Dictionary else {}
	var id: String=str(job.get("id",""))
	var area: int=int(Store.number(job,"city",0,0,unlocked))
	if BUILDINGS.has(id) and level(id,area)<8:
		var duration: float=4.0+float(level(id,area)+1)*2.0+float(area)
		construction={"id":id,"city":area,"target":level(id,area)+1,"duration":duration,"remaining":Store.number(job,"remaining",duration,0,duration)}
	var voyage: Dictionary=data.get("expedition",{}) if data.get("expedition") is Dictionary else {}
	var route_index: int=int(Store.number(voyage,"index",-1,-1,ROUTES.size()-1))
	area=int(Store.number(voyage,"city",0,0,unlocked))
	if route_index>=0 and level("dock",area)>0 and free_workers(area)>=2:
		expedition={"index":route_index,"city":area,"duration":expedition_time(route_index,area),"remaining":Store.number(voyage,"remaining",expedition_time(route_index,area),0,expedition_time(route_index,area))}
	var routes: Array=data.get("completed_routes",[]) if data.get("completed_routes") is Array else []
	for route in ROUTES:
		if route["id"] in routes:completed_routes.append(route["id"])
	expeditions_done=int(Store.number(data,"expeditions_done",0,0,1000000));family_cooldown=Store.number(data,"family_cooldown",0,0,18)
	raid_clock=Store.number(data,"raid_clock",0,0,210);defended=int(Store.number(data,"defended",0,0,1000000))
	var timestamp: float=Time.get_unix_time_from_system() if now<0 else now
	last_saved=Store.number(data,"last_saved",timestamp,0,4102444800)
	var offline: float=clampf(timestamp-last_saved,0,7200)
	var before: Dictionary=resources.duplicate()
	# Bounded steps preserve the same input consumption and completion order
	# as foreground play. Rewards are committed by the caller immediately.
	while offline>.001:
		var step: float=minf(.5,offline);tick(step,true);offline-=step
	for key in resources:
		if float(resources[key])-float(before[key])>=1:offline_gains[key]=floori(float(resources[key])-float(before[key]))
	last_saved=timestamp
