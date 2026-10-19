extends Node3D
class_name WivoriArchipelago

const Finish=preload("res://scripts/scene_finish.gd")
const Art=preload("res://scripts/art_library.gd")
const Store=preload("res://scripts/save_store.gd")
const Nav=preload("res://scripts/navigation.gd")
const HOME_DOCK=preload("res://scripts/town_layout.gd").DOCK
const DOCK=Vector3(0,0,20)
const MARKET=Vector3(12,0,6)
const NAMES=["Wivori","Villa Miga","Puerto Nata","Bahía Farol"]
const GOODS={"wheat":"Trigo","flour":"Harina","feed":"Alimento","bread":"Pan","egg":"Huevos","milk":"Leche","cheese":"Queso","meat":"Carne empaquetada","provisions":"Provisiones"}
const VALUES={"wheat":8,"flour":20,"feed":16,"bread":55,"egg":24,"milk":30,"cheese":80,"meat":68,"provisions":160}
const PROJECTS=[
	{"region":1,"id":"grain","name":"Campos de Villa Miga","cost":380,"needs":{},"at":Vector3(-12,0,-16),"model":"greenhouse","why":"Abrí los campos de trigo. La harina alimentará a tres pueblos."},
	{"region":1,"id":"grainmill","name":"Molino de grano","cost":600,"needs":{"wheat":8},"at":Vector3(-12,0,4),"model":"mill","why":"Convertí trigo en harina o alimento para animales."},
	{"region":1,"id":"breadshop","name":"Panadería del puerto","cost":720,"needs":{"flour":4},"at":Vector3(0,0,-12),"model":"bakery","why":"El pan abre el comercio con el siguiente pueblo."},
	{"region":1,"id":"henhouse","name":"Granja de gallinas","cost":520,"needs":{"bread":4,"feed":4},"at":Vector3(12,0,-12),"model":"farm_coop","why":"Alimentá las gallinas y recogé huevos para los pedidos."},
	{"region":1,"id":"nata_route","name":"Abrir Puerto Nata","cost":900,"needs":{"bread":10,"egg":6},"at":DOCK,"model":"","why":"Un pueblo ganadero necesita pan y huevos. Abre una nueva isla."},
	{"region":2,"id":"cowbarn","name":"Establo de vacas","cost":900,"needs":{"feed":10},"at":Vector3(-12,0,-12),"model":"farm_barn","why":"Traé alimento de Villa Miga para producir leche."},
	{"region":2,"id":"dairy","name":"Quesería de Nata","cost":1100,"needs":{"milk":8},"at":Vector3(0,0,-12),"model":"cafe","why":"Transformá leche en queso. Cada pueblo aporta un ingrediente."},
	{"region":2,"id":"pigpen","name":"Corral de cerdos","cost":1000,"needs":{"feed":12,"cheese":4},"at":Vector3(12,0,-12),"model":"farm_corral","why":"Ampliá la granja para abastecer la carnicería del pueblo."},
	{"region":2,"id":"butcher","name":"Carnicería del puerto","cost":1200,"needs":{"feed":8,"milk":6},"at":Vector3(-12,0,4),"model":"workshop","why":"Prepará paquetes de carne para comerciar. Sin escenas violentas."},
	{"region":2,"id":"farol_route","name":"Abrir Bahía Farol","cost":1500,"needs":{"cheese":10,"meat":8,"bread":10},"at":DOCK,"model":"","why":"Llevá suministros para reconstruir el último puerto de la ruta."},
	{"region":3,"id":"harbor_depot","name":"Almacén de la bahía","cost":1200,"needs":{"bread":8,"milk":6},"at":Vector3(-12,0,-12),"model":"depot","why":"Uní la producción de los pueblos en un puerto de intercambio."},
	{"region":3,"id":"cannery","name":"Cocina de provisiones","cost":1500,"needs":{"cheese":6,"meat":6,"egg":6},"at":Vector3(0,0,-12),"model":"bakery","why":"Pan, queso y carne se convierten en provisiones para los barcos."},
	{"region":3,"id":"route_watch","name":"Vigía de la bahía","cost":1400,"needs":{"provisions":4},"at":Vector3(12,0,-12),"model":"watchtower","why":"El mirador guía a los comerciantes: los pedidos de la bahía pagan 25 % más."},
	{"region":3,"id":"beacon","name":"Reconstruir el Faro","cost":1800,"needs":{"provisions":8,"cheese":8},"at":Vector3(0,0,2),"model":"route_lighthouse","why":"El faro vuelve a guiar a los barcos de los cuatro pueblos."},
	{"region":3,"id":"festival","name":"Inaugurar la Ruta del Faro","cost":2200,"needs":{"provisions":12,"bread":12,"milk":12},"at":Vector3(0,0,7),"model":"","why":"Abastecé la inauguración y conectá definitivamente todos los pueblos."}
]
const RECIPES={
	"flour":{"region":1,"building":"grainmill","needs":{"wheat":3},"count":2,"time":12.0},
	"feed":{"region":1,"building":"grainmill","needs":{"wheat":2},"count":3,"time":10.0},
	"bread":{"region":1,"building":"breadshop","needs":{"flour":2},"count":2,"time":16.0},
	"egg":{"region":1,"building":"henhouse","needs":{"feed":2},"count":3,"time":14.0},
	"milk":{"region":2,"building":"cowbarn","needs":{"feed":3},"count":3,"time":16.0},
	"cheese":{"region":2,"building":"dairy","needs":{"milk":3},"count":2,"time":20.0},
	"meat":{"region":2,"building":"butcher","needs":{"feed":4},"count":2,"time":22.0},
	"provisions":{"region":3,"building":"cannery","needs":{"bread":2,"cheese":1,"meat":1},"count":2,"time":25.0}
}
var g
var restore_region:=0
var restored_position:=Vector3.ZERO
var ferry:=false
var region:=0
var stage:=0
var inventory: Dictionary={}
var bag: Dictionary={}
var built: Array[String]=[]
var jobs: Dictionary={}
var employees: Dictionary={}
var mastery: Dictionary={}
var total_produced: Dictionary={}
var market_money: Array[int]=[0,0,0,0]
var contracts_done:=0
var home_nav
var home_position:=Vector3.ZERO
var scenery: Node3D
var home_ferry: Node3D
var home_harbor: Node3D
const HOME_BERTH=Vector3(29,.16,19)
var home_hidden: Array[Dictionary]=[]
var station_nodes: Dictionary={}
var wheat: Array[Dictionary]=[]
var crop_timers: Array[float]=[]
var region_ferry: Node3D
var local_money_label: Label3D
var local_coins: Node3D
var residents: Array[Dictionary]=[]
var board_scrim: ColorRect
var board: PanelContainer
var listing: VBoxContainer
var board_head: Label
var route_button: Button
var focused_recipe:=""
var focused_sale:=""
var focused_deposit:=false
var animals: Array[Dictionary]=[]
var lighthouse_beam: Node3D
var mill_rotor: Node3D
var pinned:=false
var board_tab:=0
var board_wait:=0.0
var visual_wait:=0.0
var harvest_wait:=0.0
var sailing:=0.0
var sail_target:=-1
var clock:=0.0
var ship_cargo: Node3D
var cargo_visual: Node3D
var cargo_visual_kind:=""

func _ready() -> void:
	name="Ruta al Faro · pueblos persistentes"
	home_nav=g.world.navigation
	home_harbor=Node3D.new();home_harbor.name="Puerto de Wivori";add_child(home_harbor)
	for key in GOODS:inventory[key]=0;bag[key]=0
	Finish.water(g.world.shape(home_harbor,"box",Vector3(30,.07,17),Vector3(9,.14,17),Color("#6ebcc7"),"Canal del transbordador"))
	home_nav.add_obstacle(Rect2(26,8,8,18))
	for x in [24.0,25.0]:g.world.shape(home_harbor,"box",Vector3(x,.22,20),Vector3(1.0,.28,5),Color("#b8895d"),"Embarcadero")
	home_ferry=Art.place(home_harbor,"route_ferry",HOME_BERTH,Vector3.ONE*.87)
	var sign: Label3D=g.world.make_label(home_harbor,"RUTA AL FARO",HOME_DOCK+Vector3(0,2.4,0),44)
	sign.modulate=Color("#214960")
	set_process(false)
func away() -> bool:return region>0
func project() -> Dictionary:return PROJECTS[stage] if stage<PROJECTS.size() else {}
func unlocked() -> int:return 3 if built.has("farol_route") else 2 if built.has("nata_route") else 1 if ferry else 0
func bag_total() -> int:
	var count:=0
	for n in bag.values():count+=int(n)
	return count
func amount(key: String) -> int:return int(inventory.get(key,0))+int(bag.get(key,0))
func has_needs(needs: Dictionary,stored_only: bool=false) -> bool:
	for key in needs:
		if int(inventory.get(key,0))+(0 if stored_only else int(bag.get(key,0)))<int(needs[key]):return false
	return true
func consume(needs: Dictionary,stored_only: bool=false) -> void:
	for key in needs:
		var from_bag:=0 if stored_only else mini(int(bag.get(key,0)),int(needs[key]))
		bag[key]-=from_bag;inventory[key]-=int(needs[key])-from_bag
func need_text(needs: Dictionary) -> String:
	var parts: PackedStringArray=[]
	for key in needs:parts.append("%s %d/%d" % [GOODS[key],mini(amount(key),needs[key]),needs[key]])
	return " · ".join(parts) if not parts.is_empty() else "Solo necesitás monedas"
func repair_ferry() -> bool:
	if ferry or g.run.level<6 or not g.pier_owned or g.coins<900 or away():return false
	if g.player.position.distance_to(HOME_DOCK)>2.8:return false
	g.coins-=900;ferry=true;pinned=true
	g.milestone.announce("ferry:ready","¡Tu barco está listo!","Villa Miga ya está en el mapa. Embarcá en el puerto y empezá sus campos de trigo.","boat","route","NUEVA RUTA ABIERTA")
	g._save_progress();g._refresh_ui();refresh_board();return true
func build_project() -> bool:
	var p:=project()
	if p.is_empty() or region!=p["region"] or g.player.position.distance_to(p["at"]+Vector3(0,0,3.2) if not p["model"].is_empty() else p["at"])>2.8:return false
	if g.coins<p["cost"] or not has_needs(p["needs"]):return false
	g.coins-=p["cost"];consume(p["needs"]);built.append(p["id"]);stage+=1;focused_recipe=""
	if not p["model"].is_empty():_place_project(p,true)
	if p["id"]=="grain":_make_wheat()
	_update_project_marker()
	var next:=project()
	g.milestone.announce("route:stage:%d" % stage,"¡"+p["name"]+"!",("La Ruta del Faro está completa. Podés mejorar talleres, visitar tus pueblos y cumplir contratos de comercio." if next.is_empty() else "Siguiente proyecto: "+next["name"]+"\n\n"+next["why"]),"boat" if p["id"].ends_with("route") else "star","","RUTA COMPLETA" if next.is_empty() else "PROYECTO %d / %d" % [stage,PROJECTS.size()])
	g.player.act("build");g._save_progress();g._refresh_ui();refresh_board();return true
func station(key: String) -> Vector3:
	for p in PROJECTS:
		if p["id"]==RECIPES[key]["building"]:return p["at"]+Vector3(0,0,3.2)
	return DOCK
func start_batch(key: String,automatic: bool=false) -> bool:
	if not RECIPES.has(key):return false
	var recipe: Dictionary=RECIPES[key]
	if not built.has(recipe["building"]):return false
	if not automatic and (region!=recipe["region"] or g.player.position.distance_to(station(key))>2.8):return false
	var job: Dictionary=jobs.get(key,{"remaining":0.0,"ready":0})
	if job["remaining"]>0 or int(job["ready"])+int(recipe["count"])>9 or not has_needs(recipe["needs"],automatic):return false
	consume(recipe["needs"],automatic);job["remaining"]=recipe["time"]*pow(.8,int(mastery.get(key,0)));jobs[key]=job
	if not automatic:g.player.act("deliver");g._notice("Preparando "+GOODS[key]+" · Podés hacer otra tarea",2)
	g._save_progress();return true
func pickup(key: String) -> bool:
	if not jobs.has(key) or region!=RECIPES[key]["region"] or g.player.position.distance_to(station(key))>2.8:return false
	var count:=mini(int(jobs[key]["ready"]),g.max_capacity-g._total_bag())
	if count<=0:return false
	jobs[key]["ready"]-=count;bag[key]+=count;g.player.act("collect");g._notice("+%d %s en tu mochila" % [count,GOODS[key]],1.8);g._save_progress();return true
func hire(key: String) -> bool:
	if not RECIPES.has(key) or not built.has(RECIPES[key]["building"]) or employees.has(key) or g.coins<650:return false
	g.coins-=650;employees[key]=true;_spawn_operator(key);g._notice("¡Empleado contratado!\nPrepara lotes con ingredientes guardados en el barco.",2.7);g._save_progress();refresh_board();return true
func improve(key: String) -> bool:
	var tier:=int(mastery.get(key,0));var cost:=450+tier*350
	if not RECIPES.has(key) or not built.has(RECIPES[key]["building"]) or tier>=3 or g.coins<cost:return false
	g.coins-=cost;mastery[key]=tier+1;g._save_progress();refresh_board();return true
func deposit() -> bool:
	if g.player.position.distance_to(DOCK if away() else HOME_DOCK)>2.8 or bag_total()==0:return false
	var transferred:=0
	for key in bag:
		var count:=mini(int(bag[key]),100000-int(inventory[key]))
		inventory[key]+=count;bag[key]-=count;transferred+=count
	if transferred==0:g._notice("Ese producto ya llena el almacén. Vendé un lote para liberar espacio.",2);return false
	_update_cargo()
	focused_deposit=false;g.player.act("deliver");g._notice("¡CARGA GUARDADA EN EL BARCO!",1.8);g._save_progress();refresh_board();return true
func sell_bundle(key: String) -> bool:
	if not away() or not GOODS.has(key) or g.player.position.distance_to(MARKET)>2.8 or amount(key)<3:return false
	consume({key:3});market_money[region]+=sale_value(key);contracts_done+=1
	g.player.act("deliver");g._notice("Venta entregada · recogé las monedas en la caja",2);g._save_progress();return true
func travel(destination: int) -> bool:
	if destination<0 or destination>unlocked() or destination==region or sailing>0 or not ferry:return false
	if not g.run.raiders.is_empty() or g.run.warning>0:
		g._notice("Terminá la defensa antes de embarcar.",2);return false
	var dock:=DOCK if away() else HOME_DOCK
	if g.player.position.distance_to(dock)>2.8:
		close_board();g._set_world_goal(dock);g._notice("Acercate al embarcadero con el joystick.",2.5);return false
	close_board();sailing=1.3;sail_target=destination;g.input_stick._clear();g.boost_active=false;g.move_velocity=Vector3.ZERO
	g.player.act("deliver");g._notice("¡ZARPAMOS A "+NAMES[destination].to_upper()+"!",2);g._save_progress();return true
func _arrive(destination: int,restore: bool=false) -> void:
	g.has_tap_destination=false;g.destination_marker.visible=false;g.guide_override={}
	if region==0:
		home_position=g.player.position;home_hidden.clear()
		for node in g.get_children():
			if node is Node3D and node!=g.player and node!=g.camera and node!=self and not node is Light3D:
				home_hidden.append({"node":node,"visible":node.visible,"mode":node.process_mode});node.visible=false;node.process_mode=Node.PROCESS_MODE_DISABLED
		home_harbor.visible=false
	if not wheat.is_empty():
		crop_timers.clear()
		for crop in wheat:crop_timers.append(crop["remaining"])
	if scenery!=null:scenery.free();scenery=null
	region=destination;focused_recipe="";focused_sale="";focused_deposit=false;residents.clear();animals.clear();lighthouse_beam=null;mill_rotor=null;station_nodes.clear();wheat.clear();region_ferry=null;local_money_label=null;local_coins=null
	if away():
		_build_region();g.player.position=DOCK+Vector3(0,0,-2)
	else:
		g.world.navigation=home_nav
		g.player.ground_sampler=Callable(g.world,"ground_height")
		for item in home_hidden:
			var node: Node3D=item["node"]
			if is_instance_valid(node):node.visible=item["visible"];node.process_mode=item["mode"]
		home_hidden.clear();home_harbor.visible=true;home_ferry.position=HOME_BERTH;g.player.position=home_nav.nearest_free(HOME_DOCK+Vector3(-1,0,0))
	if restore:g.player.position=g.world.navigation.nearest_free(restored_position)
	g.camera_follow=g.player.position;g.camera_lead=Vector3.ZERO;g._update_camera(1)
	g.milestone.announce("arrive:%d" % region,"¡Llegaste a "+NAMES[region]+"!",("Tu mercado conserva sus edificios y empleados. Podés volver a embarcar cuando quieras." if not away() else project().get("why","Tus pueblos siguen conectados. Mejorá tus talleres o prepará un contrato.")),"boat","","NUEVO DESTINO")
	g._save_progress();g._refresh_ui()
func _build_region() -> void:
	scenery=Node3D.new();scenery.name=NAMES[region];add_child(scenery)
	g.world.navigation=Nav.new()
	g.world.navigation.land_center=Vector2(0,-2)
	g.world.navigation.land_radius=Vector2(30.4,29.4)
	g.world.navigation.bridges.append(Rect2(-2.5,16.5,5,9))
	g.player.ground_sampler=Callable(self,"ground_height")
	Finish.water(g.world.shape(scenery,"box",Vector3(0,-.35,0),Vector3(69,.5,69),Color("#6cb9ca")),true)
	g.world.shape(scenery,"cylinder",Vector3(0,-.28,-2),Vector3(62,.22,60),Color("#debd7e"))
	Finish.ground(g.world.shape(scenery,"cylinder",Vector3(0,-.14,-3),Vector3(57,.16,55),Color.WHITE),[Color("#82ae77"),Color("#94b58b"),Color("#87ada0")][region-1])
	g.world.navigation.add_obstacle(Rect2(-34,25,68,9));g.world.navigation.add_obstacle(Rect2(-34,-34,68,5))
	g.world.navigation.add_obstacle(Rect2(-34,-29,6,54));g.world.navigation.add_obstacle(Rect2(28,-29,6,54))
	Finish.ground(g.world.shape(scenery,"box",Vector3(0,.18,-1),Vector3(4.4,.10,44),Color.WHITE),Color("#d2c3a1"),true)
	for z in [-9.0,7.2]:Finish.ground(g.world.shape(scenery,"box",Vector3(0,.19,z),Vector3(30,.1,3),Color.WHITE),Color("#d2c3a1"),true)
	g.world.shape(scenery,"box",Vector3(0,.28,21),Vector3(5,.30,9),Color("#b78d5c"))
	region_ferry=Art.place(scenery,"route_ferry",Vector3(4.8,.18,23),Vector3.ONE*.9)
	g.world.navigation.add_obstacle(Rect2(2.8,20,4,8))
	g.world.make_label(scenery,NAMES[region].to_upper(),Vector3(0,3,-23),56,true)
	g.world.make_label(scenery,"EMBARCAR",DOCK+Vector3(0,1.5,0),34,true)
	Art.place(scenery,"market",Vector3(12,0,1.1),Vector3.ONE*.8);g.world.navigation.add_obstacle(Rect2(9.8,-.3,4.4,3))
	local_money_label=g.world.make_label(scenery,"CAJA LOCAL",MARKET+Vector3(0,2.5,0),42)
	local_coins=Art.place(scenery,"coin",MARKET+Vector3(.6,1.0,-.1),Vector3.ONE*1.4)
	for p in PROJECTS:
		if p["region"]==region and built.has(p["id"]) and not p["model"].is_empty():_place_project(p,false)
	if region==1 and built.has("grain"):_make_wheat()
	for i in range(10):
		var x: float=(-23 if i%2==0 else 23);var z: float=-22+float(i/2)*9
		Art.place(scenery,"tree",Vector3(x,0,z),Vector3.ONE*.78);g.world.navigation.add_obstacle(Rect2(x-.55,z-.55,1.1,1.1))
	for i in range(3):
		var a: MarketActor=g.ActorScript.new();a.setup("resident",[Color("#db9d4c"),Color("#aa7bc5"),Color("#70a368")][i],["duck","pig","fox"][i]);scenery.add_child(a);a.position=Vector3(-2+i*3,0,11)
		residents.append({"actor":a,"index":i,"wait":float(i),"route":[Vector3(-5,0,12),Vector3(5,0,13),Vector3(8,0,7)]})
	for at in [Vector3(-21,0,-17),Vector3(21,0,-17),Vector3(-21,0,10),Vector3(21,0,12)]:
		Art.place(scenery,"house",at,Vector3.ONE*.72);g.world.navigation.add_obstacle(Rect2(at.x-1.8,at.z-1.7,3.6,3.4))
	for at in [Vector3(-6,0,7),Vector3(6,0,-9),Vector3(-7,0,16)]:Art.place(scenery,"oak_bench",at)
	for at in [Vector3(7,0,10),Vector3(-7,0,-20)]:Art.place(scenery,"flower_cart",at,Vector3.ONE*.8);g.world.navigation.add_obstacle(Rect2(at.x-.8,at.z-.5,1.6,1))
	g.world.navigation.build();_update_project_marker()
	var accents:=PackedVector3Array()
	for i in range(100):
		var at:=Vector3((-1 if i%2==0 else 1)*(3.4+sin(float(i)*7.3)*.45),.04,-22+float(i/2)*.88+sin(float(i)*4.7)*.24)
		if g.world.navigation.is_walkable(at,.5) and absf(at.z+9)>2 and absf(at.z-7.2)>2:accents.append(at)
	Finish.meadow(scenery,accents)
func _place_project(p: Dictionary,animated: bool) -> void:
	if scenery==null or station_nodes.has(p["id"]):return
	var root:=Node3D.new();root.position=p["at"];scenery.add_child(root);station_nodes[p["id"]]=root
	var model:=Art.place(root,p["model"])
	if p["id"]=="beacon":_make_beam(root)
	if p["id"]=="grainmill":
		for node in model.find_children("*","Node3D",true,false):
			if "rotor" in node.name.to_lower():mill_rotor=node;break
	g.world.navigation.add_obstacle(Rect2(p["at"].x-2.4,p["at"].z-2.2,4.8,4.4))
	g.world.make_label(root,{"grain":"TRIGAL","grainmill":"MOLINO","breadshop":"PANADERÍA","henhouse":"GALLINERO","cowbarn":"ESTABLO","dairy":"QUESERÍA","pigpen":"CORRAL","butcher":"CARNICERÍA","harbor_depot":"ALMACÉN","cannery":"COCINA","route_watch":"VIGÍA","beacon":"FARO"}.get(p["id"],p["name"]),Vector3(0,4.1,0),40,true)
	if animated:
		model.scale=Vector3(1,.05,1);create_tween().tween_property(model,"scale",Vector3.ONE,.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if p["id"] in ["cowbarn","henhouse","pigpen"]:
		var kind: String={"cowbarn":"cow","henhouse":"hen","pigpen":"piglet"}[p["id"]]
		for i in range(2):
			var animal:=Art.place(root,"farm_"+kind,Vector3(-1.2+i*2.4,0,3.7),Vector3.ONE*(.8 if kind!="hen" else 1.0));animal.rotation.y=.12 if i==0 else -.25
			animals.append({"node":animal,"at":animal.position,"yaw":animal.rotation.y,"phase":float(i)*1.8})
		for x in [-2.8,2.8]:
			Art.place(root,"farm_fence",Vector3(x,0,2.1))
			g.world.navigation.add_obstacle(Rect2(p["at"].x+x-.13,p["at"].z-1, .26,6.2))
	for key in RECIPES:
		if RECIPES[key]["building"]==p["id"]:
			var output:=Art.place(root,"goods_"+key,Vector3(-1.0 if key=="flour" else 1.1,.5,2.6),Vector3.ONE*1.3);output.name="Output_"+key
			var label: Label3D=g.world.make_label(root,"",Vector3(-1.0 if key=="flour" else 1.1,1.3,3.1),27);label.name="Job_"+key
			if employees.get(key,false):_spawn_operator(key)
func _spawn_operator(key: String) -> void:
	if scenery==null or region!=RECIPES[key]["region"]:return
	var root: Node3D=station_nodes.get(RECIPES[key]["building"])
	if root==null or root.has_node("Operator_"+key):return
	var a: MarketActor=g.ActorScript.new();a.setup("helper",Color("#dfad64"),"rabbit" if key in ["flour","milk","provisions"] else "duck");root.add_child(a);a.name="Operator_"+key;a.position=Vector3(-1.8,0,2.4);a.rotation.y=PI;a.act("build")
func _make_wheat() -> void:
	if not wheat.is_empty() or scenery==null:return
	g.world.shape(scenery,"box",Vector3(-12,.22,-8),Vector3(7,.2,6),Color("#a98251"))
	for i in range(16):
		var at:=Vector3(-14.4+(i%4)*1.6,.35,-10.2+int(i/4)*1.45)
		var n:=Art.place(scenery,"goods_wheat",at,Vector3.ONE*1.2)
		wheat.append({"node":n,"remaining":crop_timers[i] if crop_timers.size()>i else 0.0})
func _update_project_marker() -> void:
	if scenery==null:return
	var old:=scenery.get_node_or_null("ProjectMarker")
	if old!=null:scenery.remove_child(old);old.queue_free()
	var p:=project()
	if p.is_empty() or p["region"]!=region:return
	var marker:=Node3D.new();marker.name="ProjectMarker";marker.position=p["at"]+(Vector3(0,0,3.2) if not p["model"].is_empty() else Vector3.ZERO);scenery.add_child(marker)
	g.world.shape(marker,"cylinder",Vector3(0,.15,0),Vector3(2.5,.12,2.5),Color("#f0bd4b"))
	g.world.make_label(marker,"CONSTRUIR",Vector3(0,1.4,0),34,true)
func _update_cargo() -> void:
	g.player.set_carry(g._total_bag())
	var key:=""
	for item in bag:
		if bag[item]>0:key=item;break
	if key!=cargo_visual_kind:
		if is_instance_valid(cargo_visual):cargo_visual.queue_free()
		cargo_visual=null;cargo_visual_kind=key
		if not key.is_empty():cargo_visual=Art.place(g.player,"goods_"+key,Vector3(0,.85,.54),Vector3.ONE*.95)
	if not key.is_empty():g.player.carrying=g._total_bag();g.player.goods_root.visible=false
func tick(delta: float) -> void:
	clock+=delta
	for animal in animals:
		animal["node"].position.y=animal["at"].y+.018*sin(clock*2+animal["phase"])
		animal["node"].rotation.y=animal["yaw"]+.12*sin(clock*.7+animal["phase"])
	if is_instance_valid(lighthouse_beam):lighthouse_beam.rotation.y=clock*.28
	if is_instance_valid(mill_rotor):mill_rotor.rotation.z+=delta*.32
	if sailing>0:
		sailing=maxf(0,sailing-delta)
		var boat: Node3D=region_ferry if away() else home_ferry
		if boat!=null:boat.position.z+=delta*2.3
		if sailing<=0:_arrive(sail_target);sail_target=-1
		return
	for key in jobs:
		if jobs[key]["remaining"]<=0:continue
		jobs[key]["remaining"]=maxf(0,jobs[key]["remaining"]-delta)
		if jobs[key]["remaining"]<=0:
			jobs[key]["ready"]+=RECIPES[key]["count"];total_produced[key]=int(total_produced.get(key,0))+RECIPES[key]["count"]
			g._notice("¡"+GOODS[key].to_upper()+" LISTO! · Recogelo en su taller",2)
	for key in employees:
		if employees[key]:start_batch(key,true)
	_update_cargo()
	if not away():return
	harvest_wait=maxf(0,harvest_wait-delta)
	if not wheat.is_empty():crop_timers.clear()
	else:
		for i in range(crop_timers.size()):crop_timers[i]=maxf(0,crop_timers[i]-delta)
	for crop in wheat:
		crop["remaining"]=maxf(0,crop["remaining"]-delta);crop["node"].scale=Vector3.ONE*clampf(1-crop["remaining"]/8,.1,1);crop_timers.append(crop["remaining"])
		if crop["remaining"]<=0 and harvest_wait<=0 and not board_visible() and g._total_bag()<g.max_capacity and g.player.position.distance_to(crop["node"].position)<1.5:
			bag["wheat"]+=1;crop["remaining"]=8.0;harvest_wait=.22;g.player.act("harvest");g._notice("+1 TRIGO",.7)
	for resident in residents:
		resident["wait"]-=delta
		if resident["wait"]>0:continue
		var actor: MarketActor=resident["actor"]
		if g._move_actor(actor,resident["route"][resident["index"]],1.7,delta):resident["index"]=(resident["index"]+1)%3;resident["wait"]=2.5
	g.cash._complete_player_flight(delta)
	if market_money[region]>0 and g.player.position.distance_to(MARKET)<2.3:
		g.cash.player_held+=market_money[region];g.cash.player_remaining=g.cash._fly_money(MARKET+Vector3(0,1,0),g.player.position,market_money[region],true);market_money[region]=0;g.player.act("collect");g._save_progress()
	visual_wait-=delta
	if visual_wait<=0:
		visual_wait=.25
		local_money_label.text="CAJA · %d" % market_money[region];local_coins.visible=market_money[region]>0
		for key in RECIPES:
			var root: Node3D=station_nodes.get(RECIPES[key]["building"])
			if root==null:continue
			var operator: MarketActor=root.get_node_or_null("Operator_"+key)
			if operator!=null and employees.get(key,false) and jobs.get(key,{}).get("remaining",0.0)>0 and operator.action_left<=0:operator.act("build")
			root.get_node("Output_"+key).visible=int(jobs.get(key,{}).get("ready",0))>0
			root.get_node("Job_"+key).text=("¡LISTO! ×%d" % jobs[key]["ready"] if jobs[key]["ready"]>0 else "%ds" % ceili(jobs[key]["remaining"])) if jobs.has(key) else ""
	
func objective() -> Dictionary:
	var result: Dictionary={"tag":"RUTA AL FARO · %d / %d" % [stage,PROJECTS.size()],"title":"Reconstruí la ruta entre pueblos","detail":"Wivori → Villa Miga → Puerto Nata → Bahía Farol","goal":15.0,"value":float(stage),"button":"VER RUTA","action":"route:board"}
	if not ferry:
		result.merge({"title":"Restaurá tu barco · 900 monedas","detail":"Nivel 6 + muelle construido. Conservás todos tus edificios.","target":HOME_DOCK,"button":"RESTAURAR" if g.player.position.distance_to(HOME_DOCK)<=2.8 else "SEÑALAR","action":"route:repair"},true);return result
	if focused_sale!="":
		result.merge({"title":"Vendé 3 "+GOODS[focused_sale],"detail":"Entregá al mercado y recogé las monedas de CAJA.","target":MARKET,"button":"VENDER","action":"route:sell:"+focused_sale},true);return result
	if bag_total()>0 and (focused_deposit or g._total_bag()>=g.max_capacity-1):
		result.merge({"title":"Guardá la carga en el barco","target":DOCK if away() else HOME_DOCK,"button":"GUARDAR","action":"route:deposit"},true);return result
	var p:=project()
	if not focused_recipe.is_empty():return recipe_objective(focused_recipe,result)
	if p.is_empty():result["title"]="¡Ruta del Faro completada!";result["detail"]="Mejorá talleres, comerciá y visitá tus pueblos.";return result
	if p["region"]!=region:
		result.merge({"title":"Embarcá hacia "+NAMES[p["region"]],"detail":p["name"]+" · "+p["why"],"target":DOCK if away() else HOME_DOCK,"action":"route:board","button":"DESTINOS"},true);return result
	for key in p["needs"]:
		if amount(key)<p["needs"][key]:
			if key=="wheat":result.merge({"title":"Cosechá trigo para el proyecto","target":Vector3(-12,0,-8),"action":"","button":"SEÑALAR","detail":need_text(p["needs"])},true);return result
			var data:=recipe_objective(key,result);data["detail"]="Para "+p["name"]+" · "+data["detail"];return data
	result.merge({"title":p["name"],"detail":"%d monedas · %s" % [p["cost"],need_text(p["needs"])],"target":p["at"]+(Vector3(0,0,3.2) if not p["model"].is_empty() else Vector3.ZERO),"button":"CONSTRUIR" if not p["model"].is_empty() else "ENTREGAR","action":"route:project"},true);return result
func recipe_objective(key: String,result: Dictionary) -> Dictionary:
	var recipe: Dictionary=RECIPES[key]
	if region!=recipe["region"]:result.merge({"title":GOODS[key]+" se produce en "+NAMES[recipe["region"]],"target":DOCK if away() else HOME_DOCK,"action":"route:board","button":"DESTINOS","detail":"Volvé a ese pueblo para producir y recoger la carga."},true);return result
	var job: Dictionary=jobs.get(key,{"remaining":0.0,"ready":0})
	if job["ready"]>0:result.merge({"title":"Recogé "+GOODS[key],"target":station(key),"action":"route:pickup:"+key,"button":"RECOGER","detail":"Lote terminado ×%d · Llevalo al barco o al proyecto." % job["ready"]},true)
	elif job["remaining"]>0:result.merge({"title":"%s · %ds" % [GOODS[key],ceili(job["remaining"])],"target":station(key),"action":"route:board","button":"OTRA TAREA","detail":"Podés cosechar, construir, comerciar o viajar mientras se prepara."},true)
	elif has_needs(recipe["needs"]):result.merge({"title":"Prepará "+GOODS[key],"target":station(key),"action":"route:make:"+key,"button":"PREPARAR","detail":need_text(recipe["needs"])},true)
	else:
		for ingredient in recipe["needs"]:
			if amount(ingredient)>=recipe["needs"][ingredient]:continue
			if ingredient=="wheat":result.merge({"title":"Cosechá trigo para "+GOODS[key],"target":Vector3(-12,0,-8),"action":"","button":"SEÑALAR","detail":need_text(recipe["needs"])},true)
			else:return recipe_objective(ingredient,result)
			break
	return result
func act(action: String) -> void:
	var parts:=action.split(":")
	match parts[1]:
		"board":open_board()
		"repair":
			if not repair_ferry():g._notice("Necesitás nivel 6, muelle y 900 monedas.",2)
		"project":
			if not build_project():g._notice("Reuní los ingredientes y las monedas del proyecto.",2)
		"deposit":deposit()
		"make":start_batch(parts[2])
		"pickup":pickup(parts[2])
		"sell":
			if sell_bundle(parts[2]):focused_sale=""
	g._refresh_ui()
func board_visible() -> bool:return board_scrim!=null and board_scrim.visible
func close_board() -> void:
	if board_scrim!=null:board_scrim.visible=false
func open_board() -> void:
	g.work.close_board();g.shop_panel.visible=false
	if g.town.in_build_mode:g.town.toggle_mode()
	g.input_stick._clear();g.boost_active=false;g.move_velocity=Vector3.ZERO
	board_scrim.visible=true;refresh_board()
func build_board() -> void:
	route_button=g.hud.button("RUTA AL FARO",Color("#3d88a6"),17);g.hud.root.add_child(route_button);route_button.offset_left=24;route_button.offset_right=242;route_button.offset_top=224;route_button.offset_bottom=288;route_button.pressed.connect(open_board)
	board_scrim=ColorRect.new();board_scrim.color=Color(.04,.14,.22,.78);board_scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);g.hud.root.add_child(board_scrim);board_scrim.visible=false
	board=g.hud.panel(Color("#fff1d0"));board_scrim.add_child(board);board.anchor_left=.04;board.anchor_right=.96;board.anchor_top=.04;board.anchor_bottom=.96
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",12);board.add_child(column)
	var heading:=HBoxContainer.new();column.add_child(heading);board_head=g.hud.label("Ruta al Faro",29);board_head.size_flags_horizontal=Control.SIZE_EXPAND_FILL;heading.add_child(board_head)
	var close: Button=g.hud.button("X",Color("#5d8394"),21);close.custom_minimum_size=Vector2(65,65);heading.add_child(close);close.pressed.connect(close_board)
	var tabs:=HBoxContainer.new();tabs.add_theme_constant_override("separation",10);column.add_child(tabs)
	for i in range(2):
		var tab: Button=g.hud.button(["MAPA Y META","GRANJA Y CARGA"][i],Color("#3c8d97"),17);tab.custom_minimum_size.y=72;tab.size_flags_horizontal=Control.SIZE_EXPAND_FILL;tabs.add_child(tab);tab.pressed.connect(func():board_tab=i;refresh_board())
	var scroll:=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;column.add_child(scroll)
	listing=VBoxContainer.new();listing.size_flags_horizontal=Control.SIZE_EXPAND_FILL;listing.add_theme_constant_override("separation",14);scroll.add_child(listing)
	var resume: Button=g.hud.button("SEGUIR JUGANDO",Color("#248f91"),22);resume.custom_minimum_size.y=86;column.add_child(resume);resume.pressed.connect(close_board)
func _text(message: String,size_: int=20,color_: Color=Color("#285269")) -> Label:
	var label: Label=g.hud.label(message,size_,color_);label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;listing.add_child(label);return label
func _button(message: String,callback: Callable,disabled: bool=false) -> Button:
	var b: Button=g.hud.button(message,Color("#388b98"),18);b.custom_minimum_size.y=76;b.disabled=disabled;listing.add_child(b);b.pressed.connect(callback);return b
func refresh_board() -> void:
	if listing==null or not board_visible():return
	# Only rebuild on explicit changes, not while a finger is pressing a control.
	for node in listing.get_children():listing.remove_child(node);node.queue_free()
	board_head.text=NAMES[region]+" · Ruta %d/15" % stage
	if board_tab==0:
		_text("RECONSTRUÍ EL FARO",24);_text("Cuatro pueblos conectados. Cada destino conserva sus edificios y aporta productos a la ruta.",18)
		if not ferry:
			_text("Tu primer viaje\nNivel 6 + muelle + 900 monedas",22)
			_button("IR A RESTAURAR EL BARCO",func():close_board();pinned=true;g._set_world_goal(HOME_DOCK);g._refresh_ui())
		if region==0 and pinned:_button("MISIONES DEL MERCADO DE WIVORI",func():pinned=false;close_board();g._refresh_ui())
		for i in range(4):
			var locked: bool=i>unlocked()
			_button(("ESTÁS EN " if region==i else "BLOQUEADO · " if locked else "VIAJAR A ")+NAMES[i].to_upper(),Callable(self,"travel").bind(i),locked or region==i)
		var p:=project()
		if not p.is_empty():
			_text("PROYECTO %d / 15 · %s" % [stage+1,p["name"]],24);_text(p["why"],19);_text("%d / %d monedas\n%s" % [g.coins,p["cost"],need_text(p["needs"])],20)
			_button("SEÑALAR MI SIGUIENTE TAREA",func():close_board();pinned=true;focused_recipe="";g._refresh_ui();g._follow_objective())
		else:_text("¡RUTA COMPLETADA!\nEl faro conecta todos tus pueblos. Quedan talleres por mejorar y comercio libre.",23)
		_text("DESTINOS POR ABRIR",20)
		for i in range(stage,PROJECTS.size()):_text("%02d  %s · %s" % [i+1,NAMES[PROJECTS[i]["region"]],PROJECTS[i]["name"]],17)
	else:
		_text("CARGA DEL BARCO",24)
		var amounts: PackedStringArray=[]
		for key in GOODS:amounts.append("%s: %d  (+%d mochila)" % [GOODS[key],inventory[key],bag[key]])
		_text("\n".join(amounts),19)
		_button("GUARDAR MOCHILA EN EL BARCO",_guide_deposit,bag_total()==0)
		for key in RECIPES:
			var recipe: Dictionary=RECIPES[key]
			if not built.has(recipe["building"]):continue
			_text(GOODS[key].to_upper()+" · "+NAMES[recipe["region"]],24)
			var job: Dictionary=jobs.get(key,{"remaining":0.0,"ready":0})
			_text(need_text(recipe["needs"])+"\n%d s · produce ×%d · listo ×%d" % [ceili(recipe["time"]*pow(.8,int(mastery.get(key,0)))),recipe["count"],job["ready"]],18)
			_button("SEÑALAR / PREPARAR / RECOGER",func():close_board();focused_recipe=key;pinned=true;g._refresh_ui();g._follow_objective())
			if not employees.has(key):_button("CONTRATAR OPERARIO · 650",Callable(self,"hire").bind(key),g.coins<650)
			else:_button("PAUSAR OPERARIO" if employees[key] else "REANUDAR OPERARIO",func():employees[key]=not employees[key];g._save_progress();refresh_board())
			var tier:=int(mastery.get(key,0));_button("TALLER AL MÁXIMO" if tier>=3 else "MEJORAR TIEMPO · %d · NIVEL %d/3" % [450+tier*350,tier+1],Callable(self,"improve").bind(key),tier>=3 or g.coins<450+tier*350)
		if away():
			_text("PEDIDOS DEL MERCADO LOCAL",23);_text("Elegí qué vender. Guardá ingredientes para tu proyecto. Cobrás al acercarte a CAJA.",18)
			for key in GOODS:
				if amount(key)>=3:_button("VENDER 3 %s · +%d" % [GOODS[key].to_upper(),sale_value(key)],Callable(self,"_guide_sale").bind(key))
func save_state() -> Dictionary:
	var crops: Array=[]
	if not wheat.is_empty():
		for crop in wheat:crops.append(crop["remaining"])
	else:crops=crop_timers.duplicate()
	return {"ferry":ferry,"region":region,"position":[g.player.position.x,g.player.position.z],"stage":stage,"inventory":inventory.duplicate(),"bag":bag.duplicate(),"jobs":jobs.duplicate(true),"employees":employees.duplicate(),"mastery":mastery.duplicate(),"produced":total_produced.duplicate(),"market_money":market_money.duplicate(),"contracts":contracts_done,"crops":crops}
func load_state(data: Dictionary) -> void:
	ferry=data.get("ferry")==true;stage=int(Store.number(data,"stage",0,0,PROJECTS.size())) if ferry else 0
	for i in range(stage):built.append(PROJECTS[i]["id"])
	for key in GOODS:
		inventory[key]=int(Store.number(data.get("inventory",{}) if data.get("inventory") is Dictionary else {},key,0,0,100000))
		bag[key]=int(Store.number(data.get("bag",{}) if data.get("bag") is Dictionary else {},key,0,0,maxi(0,g.max_capacity-g._total_bag())))
	for key in RECIPES:
		var saved: Dictionary=data.get("jobs",{}) if data.get("jobs") is Dictionary else {}
		if saved.get(key) is Dictionary and built.has(RECIPES[key]["building"]):jobs[key]={"remaining":Store.number(saved[key],"remaining",0,0,25),"ready":int(Store.number(saved[key],"ready",0,0,9))}
		if data.get("employees") is Dictionary and data["employees"].get(key) is bool and built.has(RECIPES[key]["building"]):employees[key]=data["employees"][key]
		mastery[key]=int(Store.number(data.get("mastery",{}) if data.get("mastery") is Dictionary else {},key,0,0,3))
		if data.get("produced") is Dictionary:total_produced[key]=int(Store.number(data["produced"],key,0,0,1000000))
	contracts_done=int(Store.number(data,"contracts",0,0,1000000))
	var money: Array=data["market_money"] if data.get("market_money") is Array else []
	for i in range(mini(4,money.size())):market_money[i]=int(Store.number({"n":money[i]},"n",0,0,100000000))
	var crops: Array=data["crops"] if data.get("crops") is Array else []
	for i in range(mini(16,crops.size())):crop_timers.append(Store.number({"n":crops[i]},"n",0,0,8))
	var saved_region:=int(Store.number(data,"region",0,0,unlocked()))
	restore_region=saved_region;restored_position=Store.position(data.get("position"),DOCK+Vector3(0,0,-2))

func _guide_deposit() -> void:
	close_board();focused_recipe="";focused_deposit=true;pinned=true
	g._set_world_goal(DOCK if away() else HOME_DOCK)
	if not deposit():g._notice("Acercate al embarcadero con la carga.",2)
func _guide_sale(key: String) -> void:
	close_board()
	if not sell_bundle(key):focused_sale=key;pinned=true;g._set_world_goal(MARKET);g._refresh_ui()

func sale_value(key: String) -> int:
	return int((VALUES[key]*3+30)*(1.25 if region==3 and built.has("route_watch") else 1.0))
func ground_height(at: Vector3) -> float:
	if absf(at.x)<2.6 and at.z>16:return .44
	if absf(at.x)<2.3 or absf(at.z+9)<1.6 and absf(at.x)<15 or absf(at.z-7.2)<1.6 and absf(at.x)<15:return .25
	if region==1 and built.has("grain") and absf(at.x+12)<3.5 and absf(at.z+8)<3:return .34
	if (Vector2(at.x,at.z+3)/Vector2(28.5,27.5)).length_squared()>1:return -.05
	return .04
func _make_beam(root: Node3D) -> void:
	lighthouse_beam=Node3D.new();root.add_child(lighthouse_beam);lighthouse_beam.position.y=5.5
	var mesh:=ArrayMesh.new();var arrays: Array=[];arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=PackedVector3Array([Vector3(0,0,0),Vector3(-5,-.8,-18),Vector3(5,-.8,-18)])
	arrays[Mesh.ARRAY_NORMAL]=PackedVector3Array([Vector3.UP,Vector3.UP,Vector3.UP]);mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var material:=StandardMaterial3D.new();material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;material.cull_mode=BaseMaterial3D.CULL_DISABLED;material.albedo_color=Color(1,.95,.64,.16)
	var ray:=MeshInstance3D.new();ray.mesh=mesh;ray.material_override=material;ray.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;lighthouse_beam.add_child(ray)
