extends Node3D

const Art=preload("res://scripts/refuge_market_art.gd")
const Winter=preload("res://scripts/refuge_art.gd")
const Bear=preload("res://scripts/polar_bear.gd")
const Actor=preload("res://scripts/actor.gd")
const BOLD=preload("res://assets/fonts/Quicksand-Bold.ttf")
var game
var market
var area:=0
var trees: Array[Node3D]=[]
var bears: Array[Node3D]=[]
var node_ready: Dictionary={"wood":[],"meat":[]}
var node_tweens: Dictionary={}
var customers: Dictionary={}
var workers: Dictionary={}
var cashiers: Dictionary={}
var guards: Dictionary={}
var porter: Dictionary={}
var projectiles: Dictionary={}
var tower_models: Array[Node3D]=[]
var tower_count:=-1
var site_labels: Dictionary={}
var bear_status: Array[Label3D]=[]
var ground_cargo: Dictionary={"wood":[],"meat":[]}
var ground_counts: Dictionary={"wood":[],"meat":[]}
var delivery_zones: Dictionary={}
var raid_actor: Node3D
var raid_exit:=0.0
var rails: Array[Node3D]=[]
var rail_count:=-1
var train: Array[Node3D]=[]
var train_cargo: Array[Node3D]=[]
var depot_cargo: Dictionary={}
var depot_label: Label3D
var hero_cargo: Node3D
var hero_cargo_signature:=""
var hero_tool: Node3D
var tool_models: Dictionary={}
var current_tool:=""
var guide: Node3D
var guide_arrow: MeshInstance3D
var guide_label: Label3D
var guide_pointer: Control
var regrowth_labels: Dictionary={"wood":[],"meat":[]}
var breadcrumbs: MultiMeshInstance3D
var guide_clock:=0.0
var ui_clock:=0.0
var time:=0.0
var floaters: Array[Dictionary]=[]
var audio_hit: AudioStreamPlayer
var audio_coin: AudioStreamPlayer

func build(source: Node3D) -> void:
	game=source;market=game.market;area=game.state.city
	for product in market.PRODUCTS:
		var shop: Node3D=Art.piece(self,product+"_shop",market.SHOP_POSITIONS[product])
		delivery_zones[product]=_delivery_zone(market.COUNTERS[product])
		for index in range(market.positions(product).size()):
			if product=="wood":
				Art.piece(self,"stump",market.positions(product)[index])
				var tree: Node3D=Winter.make(self,"tree",1,market.positions(product)[index]);tree.scale=Vector3.ONE*.8;trees.append(tree)
			else:
				var bear:=Bear.new();bear.armor_tier=index;bear.phase=float(index)*1.7;bear.position=market.positions(product)[index];bear.rotation.y=-.6+float(index)*.65;add_child(bear);bears.append(bear)
				bear_status.append(_label(self,"",bear.position+Vector3(0,2.65,0),.016,Color("#ffdda0") if index==2 else Color("#e8f2f2")))
			node_ready[product].append(true)
			var regrowth: Label3D=_label(self,"",market.positions(product)[index]+Vector3(0,.7,0),.016);regrowth.visible=false;regrowth_labels[product].append(regrowth)
			var cargo:=Node3D.new();cargo.position=market.positions(product)[index]+Vector3(.7,.06,.6);add_child(cargo)
			ground_cargo[product].append(cargo);ground_counts[product].append(-1)
	Art.piece(self,"market_depot",market.DEPOT+Vector3(0,0,-1.7))
	depot_label=_label(self,"DEPÓSITO",market.DEPOT+Vector3(0,4.0,-1.1),.015)
	for product in market.PRODUCTS:
		var node:=Node3D.new();node.position=market.DEPOT+Vector3(-.85 if product=="wood" else .85,.5,-1.6);add_child(node);depot_cargo[product]=node
		_cargo(node,product,3);node.visible=false
	hero_cargo=Node3D.new();hero_cargo.name="Carga real · madera y carne";game.hero.goods_root.add_child(hero_cargo)
	hero_tool=_tool_attachment(game.hero)
	for id in ["axe","scythe"]:
		tool_models[id]=Art.piece(hero_tool,id);tool_models[id].visible=false
	_guide()
	audio_hit=AudioStreamPlayer.new();audio_hit.stream=preload("res://assets/harvest.wav");audio_hit.volume_db=-16;add_child(audio_hit)
	audio_coin=AudioStreamPlayer.new();audio_coin.stream=preload("res://assets/coin.wav");audio_coin.volume_db=-19;add_child(audio_coin)
	market.worked.connect(_worked);market.earned.connect(_earned)
	refresh(.01)

func _label(parent: Node3D,text: String,at: Vector3,pixel: float=.010,color_: Color=Color("#fff2d7")) -> Label3D:
	var label:=Label3D.new();label.text=text;label.font=BOLD;label.font_size=40;label.outline_size=9;label.modulate=color_;label.outline_modulate=Color("#254651")
	label.pixel_size=pixel;label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;label.position=at;label.no_depth_test=false;parent.add_child(label);return label
func _cargo(parent: Node3D,product: String,count: int) -> void:
	for index in range(mini(4,count)):
		var item: Node3D=Art.piece(parent,"cargo_meat") if product=="meat" else Winter.make(parent,"cargo_wood")
		item.position=Vector3(float(index%2)*.43-.22,float(index/2)*.30,0);item.scale=Vector3.ONE*.66
func _tool_attachment(actor: Node3D) -> Node3D:
	var attachment:=BoneAttachment3D.new();attachment.bone_name="hand.R";actor.skeleton.add_child(attachment)
	# Imported wrist bones point local +Y down. Flip the authored upright
	# shaft into the hand's frame so its blade stays above the snow.
	var grip:=Node3D.new();grip.rotation_degrees=Vector3(180,0,-12);grip.scale=Vector3.ONE*1.25;attachment.add_child(grip);return grip

func _delivery_zone(at: Vector3) -> Node3D:
	var zone:=Node3D.new();zone.position=at;add_child(zone)
	var material:=StandardMaterial3D.new();material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;material.albedo_color=Color("#70d9b2")
	var mesh:=BoxMesh.new();mesh.size=Vector3(.35,.035,.09);mesh.material=material
	var batch:=MultiMesh.new();batch.transform_format=MultiMesh.TRANSFORM_3D;batch.mesh=mesh;batch.instance_count=24
	for index in range(24):
		var angle: float=TAU*float(index)/24.0
		batch.set_instance_transform(index,Transform3D(Basis(Vector3.UP,angle),Vector3(sin(angle)*market.COUNTER_REACH,.045,cos(angle)*market.COUNTER_REACH)))
	var draw:=MultiMeshInstance3D.new();draw.multimesh=batch;draw.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;zone.add_child(draw)
	return zone

func _guide() -> void:
	guide_pointer=preload("res://scripts/refuge_direction.gd").new();game.ui.root.add_child(guide_pointer);game.ui.root.move_child(guide_pointer,game.ui.modal.get_index())
	guide=Node3D.new();add_child(guide)
	var material:=StandardMaterial3D.new();material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;material.albedo_color=Color("#ffc96f")
	var ring:=MeshInstance3D.new();var mesh:=TorusMesh.new();mesh.inner_radius=1.10;mesh.outer_radius=1.20;mesh.rings=32;mesh.ring_segments=6
	ring.mesh=mesh;ring.position.y=.06;ring.material_override=material;guide.add_child(ring)
	guide_arrow=MeshInstance3D.new();var arrow:=PrismMesh.new();arrow.size=Vector3(.65,.25,.80);guide_arrow.mesh=arrow;guide_arrow.material_override=material
	guide_arrow.rotation_degrees.x=180;guide.add_child(guide_arrow)
	guide_label=_label(guide,"",Vector3(0,3.0,0),.010)
	var multimesh:=MultiMesh.new();multimesh.transform_format=MultiMesh.TRANSFORM_3D
	var dot:=CylinderMesh.new();dot.top_radius=.09;dot.bottom_radius=.09;dot.height=.025;dot.radial_segments=8;dot.material=material;multimesh.mesh=dot
	breadcrumbs=MultiMeshInstance3D.new();breadcrumbs.multimesh=multimesh;breadcrumbs.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(breadcrumbs)

func _worked(city: int,product: String,index: int,finished: bool) -> void:
	if city!=area:return
	var target: Node3D=trees[index] if product=="wood" else bears[index]
	if product=="meat":target.react()
	if audio_hit!=null and not audio_hit.playing:audio_hit.play()
	if finished:
		var key: String=product+str(index)
		if node_tweens.has(key) and node_tweens[key]!=null:node_tweens[key].kill()
		if product=="meat":target.fallen=true
		var tween:=create_tween();node_tweens[key]=tween
		tween.set_parallel();tween.tween_property(target,"rotation:z",1.15 if product=="wood" else -.8,.36).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(target,"scale",Vector3.ONE*.01,.34).set_delay(.25)
		_float("+%d %s" % [market.yield_count(product,index),"MADERA" if product=="wood" else "CARNE"],market.positions(product)[index]+Vector3(0,2.5,0),Color("#fff0bd"))
	else:
		var tween:=create_tween();tween.tween_property(target,"scale",Vector3.ONE*(.73 if product=="wood" else .95),.08)
		tween.tween_property(target,"scale",Vector3.ONE*(.8 if product=="wood" else 1.0),.16).set_trans(Tween.TRANS_BACK)

func _earned(city: int,product: String,amount: int,_quantity: int) -> void:
	if city!=area:return
	if cashiers.has(product):cashiers[product].act("collect")
	_float("+%d MONEDAS" % amount,market.COUNTERS[product]+Vector3(0,2.4,0),Color("#ffdb85"))
	if audio_coin!=null and not audio_coin.playing:audio_coin.play()
func _float(text: String,at: Vector3,color_: Color) -> void:
	var label: Label3D=_label(self,text,at,.013,color_);label.no_depth_test=true
	floaters.append({"node":label,"time":1.4})

func refresh(delta: float) -> void:
	time+=delta;var data: Dictionary=market.town(area)
	_refresh_nodes(data)
	_refresh_workers(delta,data);_refresh_staff(delta,data);_refresh_customers(delta,data);_refresh_train(delta,data)
	var signature: String=str(market.bag)
	if signature!=hero_cargo_signature:
		hero_cargo_signature=signature
		for child in hero_cargo.get_children():hero_cargo.remove_child(child);child.queue_free()
		for product in market.PRODUCTS:
			var group:=Node3D.new();group.position=Vector3(-.30 if product=="wood" else .30,0,0);hero_cargo.add_child(group);_cargo(group,product,mini(3,int(market.bag[product])))
		game.hero.set_carry(market.bag_count());hero_cargo.visible=market.bag_count()>0
	var action: Dictionary=market.context(game.hero.position,area)
	var tool: String="axe" if action.get("product","")=="wood" else "scythe"
	var swinging: bool=game.hero.action=="harvest" and game.hero.action_left>0
	if action["kind"]!="harvest" and swinging:tool=current_tool
	else:current_tool=tool
	for id in tool_models:tool_models[id].visible=(action["kind"]=="harvest" or swinging) and id==tool and not game.ui.modal.visible
	for product in market.PRODUCTS:
		delivery_zones[product].visible=not game.ui.modal.visible and int(market.bag[product])>0 and market.flat_distance(game.hero.position,market.COUNTERS[product])<10
	ui_clock-=delta
	if ui_clock<=0:
		ui_clock=.2
		for product in market.PRODUCTS:
			var quantity: int=data["stock"][product];var count: int=data["queues"][product].size()
			var sign: Dictionary=game.ui.market_labels[product]
			sign["title"].text=("MADERA" if product=="wood" else "CARNE DE OSO")+" · %d/u" % market.unit_price(product,area)
			sign["detail"].text="%s · Stock %d/%d" % ["FILA LLENA" if count==market.QUEUE_CAPACITY else "%d clientes" % count,quantity,market.STOCK_CAPACITY]
			sign["staffing"].text="CAJERO AUTOMÁTICO" if market.cashier_for(product,area) else "ACERCATE PARA ATENDER"
			depot_cargo[product].visible=int(data["depot"][product])>0
		depot_label.text="DEPÓSITO\n%d madera · %d carne" % [data["depot"]["wood"],data["depot"]["meat"]]
	_refresh_guide(delta)
	for product in market.PRODUCTS:
		var button: Control=game.ui.market_labels[product]["button"]
		var point: Vector2=game.camera.unproject_position(market.SHOP_POSITIONS[product]+Vector3(0,3.7,0))-button.size*.5
		button.position=point;button.visible=not game.ui.modal.visible and point.y>278 and point.y+button.size.y<game.ui.root.size.y-312 and point.x>4 and point.x+button.size.x<game.ui.root.size.x-4
		for control in [game.stick,game.ui.work_button,game.ui.run_button,game.ui.camera_button]:
			if control!=null and control.visible and button.get_global_rect().intersects(control.get_global_rect().grow(6)):button.visible=false;break
	var wood_sign: Control=game.ui.market_labels["wood"]["button"];var meat_sign: Control=game.ui.market_labels["meat"]["button"]
	if wood_sign.visible and meat_sign.visible and wood_sign.get_global_rect().grow(6).intersects(meat_sign.get_global_rect()):
		meat_sign.position.y=wood_sign.position.y+wood_sign.size.y+9
		if meat_sign.position.y+meat_sign.size.y>=game.ui.root.size.y-312:meat_sign.visible=false
		for control in [game.stick,game.ui.work_button,game.ui.run_button,game.ui.camera_button]:
			if control.visible and meat_sign.get_global_rect().intersects(control.get_global_rect().grow(6)):meat_sign.visible=false;break
	for button in game.ui.placards.values():
		if not button.visible:continue
		for sign in [wood_sign,meat_sign]:
			if sign.visible and sign.get_global_rect().grow(6).intersects(button.get_global_rect()):button.visible=false;break
	for index in range(floaters.size()-1,-1,-1):
		var effect: Dictionary=floaters[index];effect["time"]-=delta;effect["node"].position.y+=delta*.75
		effect["node"].modulate.a=minf(1,float(effect["time"])*2)
		if float(effect["time"])<=0:effect["node"].queue_free();floaters.remove_at(index)

func _refresh_nodes(data: Dictionary) -> void:
	for product in market.PRODUCTS:
		for index in range(market.positions(product).size()):
			var active: bool=market.active_node(product,index,area);var node: Node3D=trees[index] if product=="wood" else bears[index]
			var close: bool=game.hero.position.distance_to(market.positions(product)[index])<8.0
			var label: Label3D=regrowth_labels[product][index];label.visible=not active and not game.ui.modal.visible and close
			if not active:label.text="%d s" % ceili(float(data["nodes"][product][index]["respawn"]))
			if product=="meat":
				var status: Label3D=bear_status[index]
				status.visible=active and not game.ui.modal.visible and close and (index>0 or int(data["nodes"][product][index]["hp"])<market.max_hp(product,index))
				status.text=(market.BEAR_NAMES[index].to_upper()+"\n" if index>0 else "")+"%d / %d" % [data["nodes"][product][index]["hp"],market.max_hp(product,index)]
			var dropped: int=market.ground_count(product,index,area)
			if dropped>0:label.visible=not game.ui.modal.visible and close;label.text="%d %s · AUTOMÁTICO" % [dropped,"MADERA" if product=="wood" else "CARNE"]
			var cargo: Node3D=ground_cargo[product][index]
			if ground_counts[product][index]!=dropped:
				for child in cargo.get_children():cargo.remove_child(child);child.queue_free()
				if dropped>0:_cargo(cargo,product,mini(4,dropped))
				ground_counts[product][index]=dropped
			cargo.visible=dropped>0
			if active and not node_ready[product][index]:
				var key: String=product+str(index)
				if node_tweens.has(key) and node_tweens[key]!=null:node_tweens[key].kill()
				node.rotation.z=0;node.scale=Vector3.ONE*(.8 if product=="wood" else 1.0);node.visible=true
				if product=="meat":node.fallen=false
			elif not active and float(data["nodes"][product][index]["respawn"])<market.respawn_time(product)-.65:node.visible=false
			node_ready[product][index]=active

func _refresh_workers(delta: float,data: Dictionary) -> void:
	for role in market.HARVEST_ROLES:
		for slot in range(market.worker_count(role,area)):
			var worker: Dictionary=market.worker_job(role,area,slot);var product: String="wood" if role=="lumberjack" else "meat"
			var key: String=role+str(slot)
			if not workers.has(key):
				var actor:=Actor.new();actor.setup("worker",[Color("#cb995d"),Color("#5b8e9d"),Color("#a17b92")][slot],["fox","duck","pig"][slot] if role=="lumberjack" else ["rabbit","fox","pig"][slot]);add_child(actor)
				actor.position=market.worker_position(role,area,slot);actor.last_position=actor.position
				var cargo:=Node3D.new();cargo.position=Vector3(0,.9,.4);actor.add_child(cargo);_cargo(cargo,product,2)
				var attachment: Node3D=_tool_attachment(actor);Art.piece(attachment,"axe" if product=="wood" else "scythe")
				workers[key]={"actor":actor,"cargo":cargo,"tool":attachment,"hit":-1}
			var record: Dictionary=workers[key];var actor: Node3D=record["actor"];var before: Vector3=actor.position
			actor.position=market.worker_position(role,area,slot);var motion: Vector3=actor.position-before
			if motion.length_squared()>.00001:actor.walk_to(motion.normalized(),motion.length()/maxf(.001,delta))
			record["cargo"].visible=int(worker["cargo"])>0;actor.set_carry(int(worker["cargo"]))
			record["tool"].visible=worker["phase"]=="work"
			if worker["phase"]=="work":
				var direction: Vector3=market.positions(product)[int(worker["target"])]-actor.position
				actor.face_direction_yaw(atan2(direction.x,direction.z))
				var hit: int=int(float(worker["clock"])*10)
				if hit<record["hit"]:actor.act("harvest")
				record["hit"]=hit

func _refresh_staff(delta: float,data: Dictionary) -> void:
	for product in market.PRODUCTS:
		if not market.cashier_for(product,area) or cashiers.has(product):continue
		var actor:=Actor.new();actor.setup("worker",Color("#a87968") if product=="wood" else Color("#779a8a"),"pig" if product=="wood" else "duck");add_child(actor)
		actor.position=market.COUNTERS[product]+Vector3(1.45,0,-.1);actor.last_position=actor.position;actor.face_direction_yaw(-.8);cashiers[product]=actor
		Art.piece(self,"cash_register",market.COUNTERS[product]+Vector3(.95,0,-.35))
	if market.worker_count("porter",area)>0:
		if porter.is_empty():
			var actor:=Actor.new();actor.setup("worker",Color("#bb945a"),"rabbit");add_child(actor);actor.position=market.carrier_position(area);actor.last_position=actor.position
			porter={"actor":actor,"signature":"","cargo":Node3D.new()};actor.goods_root.add_child(porter["cargo"])
		var actor: Node3D=porter["actor"];var before: Vector3=actor.position;actor.position=market.carrier_position(area)
		var motion: Vector3=actor.position-before
		if motion.length_squared()>.00001:actor.walk_to(motion.normalized(),motion.length()/maxf(.001,delta))
		var cargo: Dictionary=data["carrier"]["cargo"];actor.set_carry(int(cargo["wood"])+int(cargo["meat"]))
		if porter["signature"]!=str(cargo):
			porter["signature"]=str(cargo)
			for child in porter["cargo"].get_children():porter["cargo"].remove_child(child);child.queue_free()
			for product in market.PRODUCTS:
				var group:=Node3D.new();group.position.x=-.28 if product=="wood" else .28;porter["cargo"].add_child(group);_cargo(group,product,mini(2,int(cargo[product])))
	var count: int=market.worker_count("sentinel",area)
	if count!=tower_count:
		tower_count=count
		for model in tower_models:remove_child(model);model.queue_free()
		tower_models.clear();site_labels.clear()
		for index in range(2):
			var tower: Node3D=Art.piece(self,"sentinel_tower" if index<count else "tower_site",market.TOWER_POSITIONS[index]);tower_models.append(tower)
			if index>=count:site_labels[index]=_label(tower,"TORRE %d\n%d" % [index+1,220 if index==0 else 360],Vector3(0,1.45,0),.014)
	for index in site_labels:site_labels[index].visible=not game.ui.modal.visible and game.hero.position.distance_to(market.TOWER_POSITIONS[index])<5.5
	for index in range(count):
		if not guards.has(index):
			var actor:=Actor.new();actor.setup("worker",Color("#4d7494"),"rabbit" if index==0 else "fox");add_child(actor);actor.scale=Vector3.ONE*.82
			actor.position=market.TOWER_POSITIONS[index]+Vector3(0,2.6,.3);actor.last_position=actor.position;Art.piece(_tool_attachment(actor),"crossbow");guards[index]=actor
	var present: Dictionary={}
	for shot in data["shots"]:
		var id: int=shot["id"];present[id]=true
		if not projectiles.has(id):
			projectiles[id]=Art.piece(self,"bolt")
			if guards.has(int(shot["tower"])):guards[int(shot["tower"])].act("harvest")
		var start: Vector3=market.TOWER_POSITIONS[int(shot["tower"])]+Vector3(0,3.6,.3)
		var destination: Vector3=(market.BEAR_POSITIONS[int(shot["target"])] if int(shot["target"])>=0 else market.DEPOT+Vector3(0,0,1))+Vector3(0,1.0,0)
		var fraction: float=1.0-float(shot["remaining"])/float(shot["duration"])
		var node: Node3D=projectiles[id];node.position=start.lerp(destination,fraction)+Vector3(0,sin(fraction*PI)*.3,0)
		var direction: Vector3=destination-start;node.rotation=Vector3(-atan2(direction.y,Vector2(direction.x,direction.z).length()),atan2(direction.x,direction.z),0)
		if guards.has(int(shot["tower"])):guards[int(shot["tower"])].face_direction_yaw(atan2(direction.x,direction.z))
	for id in projectiles.keys():
		if not present.has(id):projectiles[id].queue_free();projectiles.erase(id)
	if game.state.raid_remaining>0:
		if not is_instance_valid(raid_actor):
			raid_actor=Actor.new();raid_actor.setup("thief",Color("#877b87"),"raccoon");add_child(raid_actor);raid_actor.position=market.DEPOT+Vector3(3,0,3);raid_actor.last_position=raid_actor.position
		raid_exit=0;_walk(raid_actor,market.DEPOT+Vector3(.6,0,.6),delta,1.8)
	elif is_instance_valid(raid_actor):
		raid_exit+=delta;_walk(raid_actor,market.DEPOT+Vector3(5,0,4),delta,3.5)
		if raid_exit>2.5:raid_actor.queue_free();raid_actor=null

func _refresh_customers(delta: float,data: Dictionary) -> void:
	var existing: Dictionary={}
	for product in market.PRODUCTS:
		var queue: Array=data["queues"][product]
		for index in range(queue.size()):
			var customer: Dictionary=queue[index];var key: String=product+str(customer["id"]);existing[key]=true
			var at: Vector3=market.COUNTERS[product]+Vector3(0,0,float(index)*1.35+.15)
			if not customers.has(key):
				var actor:=Actor.new();var skin: int=int(customer["id"])%4
				actor.setup("customer",[Color("#7a9f95"),Color("#c6a072"),Color("#ad7e79"),Color("#718fa3")][skin],["rabbit","pig","fox","duck"][skin]);add_child(actor)
				actor.position=at+(Vector3(4.5,0,2.0) if float(customer["arrival"])>0 else Vector3.ZERO);actor.last_position=actor.position
				customers[key]={"actor":actor,"product":product,"leaving":false,"exit":0.0}
			var actor: Node3D=customers[key]["actor"];_walk(actor,at,delta,3.2)
			if actor.position.distance_to(at)<.15:actor.face_direction_yaw(PI)
	for key in customers.keys():
		var record: Dictionary=customers[key];var actor: Node3D=record["actor"]
		if existing.has(key):continue
		if not record["leaving"]:
			record["leaving"]=true;actor.act("deliver")
			var cargo:=Node3D.new();cargo.position=Vector3(0,1.25,-.3);actor.add_child(cargo);_cargo(cargo,record["product"],1);actor.set_carry(1)
		record["exit"]+=delta
		var counter: Vector3=market.COUNTERS[record["product"]]
		var destination: Vector3=counter+Vector3(-3.5 if record["product"]=="wood" else 3.5,0,9)
		_walk(actor,destination,delta,3.4)
		if float(record["exit"])>4:actor.queue_free();customers.erase(key)

func _walk(actor: Node3D,target: Vector3,delta: float,speed: float) -> void:
	var difference: Vector3=target-actor.position
	if difference.length()<.04:return
	actor.position+=difference.normalized()*minf(delta*speed,difference.length());actor.walk_to(difference.normalized(),speed)

func _refresh_train(_delta: float,data: Dictionary) -> void:
	if rail_count!=int(data["rails"]):
		rail_count=int(data["rails"])
		for node in rails:remove_child(node);node.queue_free()
		rails.clear()
		for index in range(3):rails.append(Art.piece(self,("rail" if index<rail_count else "ghost_rail")+str(index)))
	if not market.operating(area):return
	if train.is_empty():
		for index in range(3):
			var vehicle: Node3D=Art.piece(self,"locomotive" if index==0 else "wagon");train.append(vehicle)
			if index>0:
				var cargo:=Node3D.new();cargo.position.y=1.0;vehicle.add_child(cargo);_cargo(cargo,"wood" if index==1 else "meat",3);train_cargo.append(cargo)
		var smoke:=CPUParticles3D.new();smoke.position=Vector3(0,2.2,.6);smoke.amount=10;smoke.lifetime=1.3;smoke.direction=Vector3.UP;smoke.gravity=Vector3(0,.1,-.2);smoke.initial_velocity_min=.5;smoke.initial_velocity_max=1.1
		var puff:=SphereMesh.new();puff.radius=.12;puff.height=.24;puff.radial_segments=6;puff.rings=3;var material:=StandardMaterial3D.new();material.albedo_color=Color("#d7e1df");puff.material=material;smoke.mesh=puff;train[0].add_child(smoke)
	for index in range(train.size()):
		var at: Vector3=market.train_position(area,float(index)*2.55);var ahead: Vector3=market.train_position(area,float(index)*2.55-.2)
		train[index].position=at;train[index].rotation.y=atan2((ahead-at).x,(ahead-at).z)
	for index in range(2):train_cargo[index].visible=int(data["train"]["cargo"][market.PRODUCTS[index]])>0

func _refresh_guide(delta: float) -> void:
	var task: Dictionary=game.current_task();var active: bool=task.has("at") and not game.ui.modal.visible
	guide.visible=active;breadcrumbs.visible=active;guide_pointer.visible=active
	if not active:return
	var at: Vector3=task["at"];guide.position=at
	guide_arrow.position.y=2.3+sin(time*3.7)*.17;guide_arrow.rotation.y=time*.6
	var distance: float=game.hero.position.distance_to(at)
	guide_pointer.update_target(game.camera.unproject_position(at+Vector3(0,1.2,0)),game.camera.unproject_position(game.hero.position),game.ui.root.size,distance)
	guide_label.text="ACÁ" if distance<market.MANUAL_REACH else "%d m" % ceili(distance)
	guide_clock-=delta
	if guide_clock>0:return
	guide_clock=.4
	var path: PackedVector3Array=game.navigation.find_path(game.hero.position,at);var points: Array[Vector3]=[game.hero.position]
	for point in path:points.append(point)
	if points.size()<2:breadcrumbs.multimesh.instance_count=0;return
	var length: float=market.path_length(points);var count: int=mini(32,floori(length/.7))
	breadcrumbs.multimesh.instance_count=count
	for index in range(count):breadcrumbs.multimesh.set_instance_transform(index,Transform3D(Basis.IDENTITY,market.path_at(points,(float(index)+.7)*.7)+Vector3(0,.055,0)))

func _exit_tree() -> void:
	if is_instance_valid(guide_pointer):guide_pointer.visible=false;guide_pointer.queue_free()
