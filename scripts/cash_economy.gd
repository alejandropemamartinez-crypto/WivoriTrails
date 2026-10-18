extends Node3D
class_name WivoriCashEconomy

# Money is physical inventory until Scottie or a paid collector retrieves it.
# Never credit wallet on sale: cash belongs to one register or courier in transit.
const REGISTERS=[Vector3(7.6,0,1.0),Vector3(.55,0,1.1)]
const BANK=Vector3(-.2,0,9.2)
const COLLECTION_RADIUS=2.05
const COLLECTOR_PRICE=620
const MAX_PENDING=1950000000
var g: Node3D
var pending: Array[int]=[0,0]
var active_registers:=1
var sales_sequence:=0
var collector_hired:=false
var collector: MarketActor
var collector_held:=0
var collector_state: String="idle"
var collector_destination:=0
var collector_pause:=0.0
var register_nodes: Array[Node3D]=[]
var coin_piles: Array[Array]=[]
var labels: Array[Label3D]=[]
var collector_bank: Node3D
var treasury_label: Label3D
var _last_displayed: Array[int]=[-1,-1]

func _ready() -> void:
	name="Recaudación visible"
	for i in range(2):
		_make_register(i)
	_make_treasury()
	set_process(false)

func _make_register(index: int) -> void:
	var node:=Node3D.new()
	node.position=REGISTERS[index]
	node.name="Caja recaudadora %d" % (index+1)
	add_child(node)
	register_nodes.append(node)
	# Two clearly distinct cash registers, with a raised collection box.
	g.world.shape(node,"box",Vector3(0,.14,0),Vector3(2.05,.26,1.65),Color("#ae8156"))
	for dx in [-.78,.78]:
		g.world.shape(node,"box",Vector3(dx,.52,-.49),Vector3(.12,.63,.14),Color("#8a6446"))
	g.world.shape(node,"box",Vector3(0,.57,0),Vector3(1.68,.67,1.15),Color("#7eae9d"),"Caja de efectivo")
	g.world.shape(node,"box",Vector3(0,.95,.05),Vector3(1.70,.17,1.19),Color("#e1b568"),"Borde dorado")
	g.world.shape(node,"box",Vector3(0,.71,.61),Vector3(.70,.24,.06),Color("#f3d78b"),"Cerradura")
	var txt: Label3D=g.world.make_label(node,"CAJA %d" % (index+1),Vector3(0,2.75,.35),46)
	txt.font_size=56
	txt.pixel_size=.008
	txt.modulate=Color("#ffefd1")
	txt.outline_size=13
	txt.outline_modulate=Color("#294e45")
	txt.no_depth_test=true
	labels.append(txt)
	# Max 18 meshes, regardless of amount: large sums scale visually.
	var pieces: Array=[]
	for j in range(18):
		var coin: MeshInstance3D=g.world.shape(node,"cylinder",
			Vector3(float(j%3-1)*.39,1.10+float(j/9)*.16+float(j%3)*.065,float((j/3)%3-1)*.33),
			Vector3(.31,.09,.31),Color("#f3c85c") if j%3 else Color("#ffe6a3"),"Moneda recaudada")
		pieces.append(coin)
	coin_piles.append(pieces)
	node.visible=index==0
	_refresh_register(index)

func _make_treasury() -> void:
	collector_bank=Node3D.new()
	collector_bank.name="Depósito de recaudación"
	collector_bank.position=BANK
	add_child(collector_bank)
	g.world.shape(collector_bank,"box",Vector3(0,.20,0),Vector3(1.9,.3,1.6),Color("#b58c66"))
	g.world.shape(collector_bank,"box",Vector3(0,.76,0),Vector3(1.5,1,.95),Color("#578e7c"))
	g.world.shape(collector_bank,"box",Vector3(0,1.32,0),Vector3(1.73,.19,1.1),Color("#d5b470"))
	treasury_label=g.world.make_label(collector_bank,"TESORERÍA",Vector3(0,2.55,.22),43)
	treasury_label.outline_size=13
	treasury_label.outline_modulate=Color("#31524b")
	treasury_label.modulate=Color("#fff4d8")
	treasury_label.no_depth_test=true
	treasury_label.pixel_size=.009

func total_pending() -> int:
	return pending[0]+pending[1]

func unlock_second_register() -> void:
	active_registers=2
	register_nodes[1].visible=true
	_refresh_register(1)

func hire_collector() -> bool:
	if collector_hired or g.coins<COLLECTOR_PRICE:return false
	g.coins-=COLLECTOR_PRICE
	collector_hired=true
	_spawn_collector()
	g._notice("¡RECAUDADOR CONTRATADO!\nRecoge efectivo y lo lleva a tesorería.",2.7)
	g._save_progress()
	g._refresh_ui()
	return true

func _spawn_collector() -> void:
	if collector!=null:return
	collector=preload("res://scripts/actor.gd").new()
	collector.ground_sampler=Callable(g.world,"ground_height")
	collector.setup("helper",Color("#d38d5f"),"rabbit")
	collector.name="Conejo recaudador del pueblo"
	g.add_child(collector)
	collector.position=g.world.navigation.nearest_free(BANK+Vector3(1.0,0,0))
	if collector_held>0:collector.set_carry(6)

func _refresh_register(index: int) -> void:
	var value:=pending[index]
	if value==_last_displayed[index]:return
	_last_displayed[index]=value
	labels[index].text="CAJA %d  ·  $%d" % [index+1,value]
	# One coin stack represents small sales; multiple layers represent growth.
	var count:=0
	if value>0:
		count=clampi(1+int(log(float(value)+1.0)/log(1.65)),1,18)
	for j in range(coin_piles[index].size()):
		coin_piles[index][j].visible=j<count

func add_sale(amount: int) -> void:
	if amount<=0:return
	var index:=sales_sequence%active_registers
	sales_sequence+=1
	pending[index]=mini(MAX_PENDING,pending[index]+amount)
	_refresh_register(index)
	# Coins visibly burst into the chosen cashier rather than the wallet HUD.
	_fly_money(REGISTERS[index]+Vector3(0,.9,-1.25),REGISTERS[index]+Vector3(0,1.24,0),mini(6,1+int(amount/12)),false)

func _fly_money(from: Vector3, target: Vector3, count: int, to_hero: bool) -> void:
	for j in range(mini(12,count)):
		var piece: MeshInstance3D=g.world.shape(self,"cylinder",from+Vector3(float(j%3-1)*.16,.09*float(j),0),
			Vector3(.24,.075,.24),Color("#f4c65b"),"Moneda animada")
		var tween:=create_tween().set_parallel(true)
		var delay:=float(j)*.047
		var end_at:=target+Vector3(float(j%3-1)*.12,float(j/3)*.12,0)
		tween.tween_property(piece,"position",end_at,.55+float(j)*.028).set_delay(delay).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(piece,"scale",Vector3(.09,.025,.09),.43).set_delay(.27+delay)
		tween.chain().tween_callback(piece.queue_free)

func take_register(index: int, by_player: bool) -> int:
	if index<0 or index>=active_registers:return 0
	var value:=pending[index]
	if value<=0:return 0
	pending[index]=0
	_refresh_register(index)
	if by_player:
		g.coins=mini(MAX_PENDING,g.coins+value)
		g.player.act("collect")
		_fly_money(REGISTERS[index]+Vector3(0,1.20,0),g.player.position+Vector3(0,1.55,.25),mini(12,3+int(log(float(value)+1.0))),true)
		g.hud.animate_income(value,g.camera.unproject_position(REGISTERS[index]+Vector3(0,1.3,0)))
		g._cash_sound()
		g._float_activity(REGISTERS[index],"+$%d RECOGIDOS" % value,Color("#f2cf73"))
		g._refresh_ui()
		g._save_progress()
	return value

func _process_collect_player() -> void:
	if g.town.in_build_mode or g.shop_panel.visible:return
	for i in range(active_registers):
		if pending[i]>0 and g.player.position.distance_to(REGISTERS[i])<=COLLECTION_RADIUS:
			take_register(i,true)

func _process_collector(delta: float) -> void:
	if not collector_hired or collector==null:return
	collector_pause=maxf(0,collector_pause-delta)
	if collector_state=="idle":
		collector.walk_amount=0
		if collector_pause>0:return
		var most:=0
		for i in range(1,active_registers):
			if pending[i]>pending[most]:most=i
		if pending[most]>0:
			collector_destination=most
			collector_state="to_register"
	elif collector_state=="to_register":
		if g._move_actor(collector,REGISTERS[collector_destination]+Vector3(0,0,.8),3.6,delta):
			collector_held+=take_register(collector_destination,false)
			collector.set_carry(6 if collector_held>0 else 0)
			collector.act("harvest")
			collector_state="to_bank"
	elif collector_state=="to_bank":
		if g._move_actor(collector,BANK+Vector3(1.0,0,0),3.45,delta):
			if collector_held>0:
				var amount:=collector_held
				collector_held=0
				collector.set_carry(0)
				g.coins=mini(MAX_PENDING,g.coins+amount)
				g.hud.animate_income(amount,g.camera.unproject_position(BANK+Vector3(0,1.8,0)))
				_fly_money(collector.position+Vector3(0,1.3,0),BANK+Vector3(0,1.5,0),6,false)
				g._float_activity(BANK,"+$%d A TESORERÍA" % amount,Color("#f3c86d"))
				g._cash_sound()
				g._refresh_ui()
				g._save_progress()
			collector_state="idle"
			collector_pause=.9

func tick(delta: float) -> void:
	_process_collect_player()
	_process_collector(delta)

func save_state() -> Dictionary:
	return {"pending":pending.duplicate(),"sequence":sales_sequence,
		"collector_hired":collector_hired,"collector_held":collector_held,
		"collector_state":collector_state,"collector_destination":collector_destination,
		"collector_pos":[collector.position.x,collector.position.z] if collector!=null else []}

func load_state(data: Dictionary) -> void:
	var piles: Variant=data.get("pending",[])
	if piles is Array:
		for i in range(mini(piles.size(),pending.size())):
			pending[i]=clampi(int(piles[i]),0,MAX_PENDING)
	sales_sequence=clampi(int(data.get("sequence",0)),0,2000000000)
	collector_hired=data.get("collector_hired",false)==true
	collector_held=clampi(int(data.get("collector_held",0)),0,MAX_PENDING)
	collector_state=str(data.get("collector_state","idle"))
	if collector_state not in ["idle","to_register","to_bank"]:collector_state="idle"
	collector_destination=clampi(int(data.get("collector_destination",0)),0,1)
	if collector_hired:
		_spawn_collector()
		collector.position=g.world.navigation.nearest_free(
			preload("res://scripts/save_store.gd").position(data.get("collector_pos"),BANK+Vector3(1,0,0)))
	if g.checkout_level>=1:unlock_second_register()
	for i in range(pending.size()):_refresh_register(i)
