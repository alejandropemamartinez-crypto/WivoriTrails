extends Node3D
class_name WivoriCashEconomy

# Every coin belongs to a register, an animated pickup, a courier, or the wallet.
# Sales and pickup initiation never credit spendable money.
const Art=preload("res://scripts/art_library.gd")
const Store=preload("res://scripts/save_store.gd")
const REGISTERS=[Vector3(7.6,0,1.0),Vector3(.55,0,1.1)]
const BANK=preload("res://scripts/town_layout.gd").BANK
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
var player_held:=0
var player_remaining:=0.0
var register_nodes: Array[Node3D]=[]
var coin_piles: Array[Array]=[]
var labels: Array[Label3D]=[]
var collector_bank: Node3D
var treasury_label: Label3D
var _last_displayed: Array[int]=[-1,-1]
var fx_regions: Dictionary={}  # Visual-only coin flight parents; never money owners.

func _ready() -> void:
	name="Recaudación física"
	for i in range(2):_make_register(i)
	_make_treasury()
	set_process(false)

func _make_register(index: int) -> void:
	var node:=Node3D.new();node.position=REGISTERS[index];node.name="Caja %d" % (index+1);add_child(node);register_nodes.append(node)
	Art.place(node,"register")
	# The second box is a real collision obstacle only after it is unlocked.
	if index==0:_register_obstacle(index)
	var txt: Label3D=g.world.make_label(node,"",Vector3(0,3.18,0),47)
	txt.pixel_size=.009;labels.append(txt)
	var pieces: Array=[]
	for j in range(18):
		var piece:=Art.place(node,"coin",Vector3(.12+float(j%3)*.23,1.10+float(j/9)*.13+float(j%3)*.04,float((j/3)%3-1)*.24),Vector3.ONE*.65)
		pieces.append(piece)
	coin_piles.append(pieces)
	node.visible=index==0
	_refresh_register(index)

func _register_obstacle(index: int) -> void:
	g.world.navigation.add_obstacle(Rect2(REGISTERS[index].x-.82,REGISTERS[index].z-.61,1.64,1.22))

func _make_treasury() -> void:
	collector_bank=Art.place(self,"treasury",BANK)
	g.world.navigation.add_obstacle(Rect2(BANK.x-.82,BANK.z-.61,1.64,1.22))
	treasury_label=g.world.make_label(collector_bank,"TESORERÍA",Vector3(0,3.36,.20),50)
	treasury_label.pixel_size=.009

func total_pending() -> int:return pending[0]+pending[1]
func in_transit() -> int:return player_held+collector_held

func unlock_second_register() -> void:
	if active_registers==2:return
	active_registers=2
	register_nodes[1].visible=true
	_register_obstacle(1)
	_refresh_register(1)

func hire_collector() -> bool:
	if collector_hired or g.coins<COLLECTOR_PRICE:return false
	g.coins-=COLLECTOR_PRICE;collector_hired=true;_spawn_collector()
	g._notice("¡RECAUDADOR CONTRATADO!\nLleva el efectivo hasta tesorería.",2.7)
	g.world.celebrate_upgrade("collector")
	g._save_progress();g._refresh_ui()
	return true

func _spawn_collector() -> void:
	if collector!=null:return
	collector=preload("res://scripts/actor.gd").new()
	collector.ground_sampler=Callable(g.world,"ground_height")
	collector.setup("helper",Color("#d39a63"),"rabbit")
	collector.name="Conejo recaudador"
	g.add_child(collector)
	collector.position=g.world.navigation.nearest_free(BANK+Vector3(1.2,0,.2))
	collector.set_money_carry(collector_held)

func _refresh_register(index: int) -> void:
	var value:=pending[index]
	if value==_last_displayed[index]:return
	_last_displayed[index]=value
	labels[index].text="CAJA %d · %d" % [index+1,value]
	var count:=clampi(ceili(float(value)/10.0),1,18) if value>0 else 0
	var growth:=minf(2.0,1+maxf(0,log(float(value)/180.0+1.0))*.18)
	for j in range(coin_piles[index].size()):
		var piece: Node3D=coin_piles[index][j]
		piece.visible=j<count;piece.scale=Vector3(.65,.65*growth,.65)

func add_sale(amount: int, origin: Vector3=Vector3.ZERO) -> void:
	if amount<=0:return
	var index:=sales_sequence%active_registers;sales_sequence+=1
	pending[index]=mini(MAX_PENDING,pending[index]+amount)
	_refresh_register(index)
	# The coins now travel from the paying customer or delivery point to
	# the register, instead of materializing immediately beside the register.
	var source: Vector3=origin if origin!=Vector3.ZERO else REGISTERS[index]+Vector3(0,1,-1.25)
	_fly_money(source,REGISTERS[index]+Vector3(.35,1.22,0),mini(6,1+int(amount/12)),false)

func _coin_at(t: float, coin: Node3D, start: Vector3, finish: Vector3, follow_hero: bool) -> void:
	if not is_instance_valid(coin):return
	var target: Vector3=g.player.position+Vector3(0,1.35,0) if follow_hero else finish
	coin.position=start.lerp(target,t)+Vector3(0,sin(t*PI)*.65,0)
	coin.rotation=Vector3(t*TAU,t*PI,0)
	coin.scale=Vector3.ONE*lerpf(.7,.15,t)

func _fx_host() -> Node3D:
	# Coin flights must never appear at the same map coordinates on a
	# different island after a ferry journey. Each region gets an independent
	# visual parent, while the actual money remains in pending/held balances.
	if g.route==null or not is_instance_valid(g.route):return self
	var region_code:int=g.route.region
	# Save is loaded before the ferry world is reconstructed; the restored
	# pickup is scoped to the saved destination rather than the empty home.
	if region_code==0 and g.route.restore_region>0:
		region_code=g.route.restore_region
	if not fx_regions.has(region_code):
		var host:=Node3D.new()
		host.name="Monedas visuales · región %d" % region_code
		g.route.add_child(host)
		fx_regions[region_code]=host
	display_fx_for_region(region_code if g.route.region==0 and g.route.restore_region>0 else g.route.region)
	return fx_regions[region_code]

func display_fx_for_region(region_code: int) -> void:
	for area in fx_regions:
		var host:Node3D=fx_regions[area]
		if is_instance_valid(host):host.visible=int(area)==region_code

func _fly_money(from: Vector3, target: Vector3, count: int, to_hero: bool) -> float:
	# Visual parents belong to their source island, so departing mid-flight
	# never makes the previous island's coins appear over the new town.
	# Tweets finish while hidden; ledgers and timings are unaffected.
	var fx_host:Node3D=_fx_host()
	var duration:=0.0
	for j in range(mini(12,count)):
		var start:=from+Vector3(float(j%3-1)*.13,.06*float(j),0)
		var piece:=Art.place(fx_host,"coin",start,Vector3.ONE*.7)
		var delay:=float(j)*.035
		var tween:=fx_host.create_tween()
		tween.tween_interval(delay)
		tween.tween_method(Callable(self,"_coin_at").bind(piece,start,target,to_hero),0.0,1.0,.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		tween.tween_callback(piece.queue_free)
		duration=.55+delay
	return duration

func take_register(index: int, by_player: bool) -> int:
	if index<0 or index>=active_registers:return 0
	var value:=pending[index]
	if value<=0:return 0
	pending[index]=0;_refresh_register(index)
	if by_player:
		player_held=mini(MAX_PENDING,player_held+value)
		g.player.act("collect")
		player_remaining=maxf(player_remaining,_fly_money(REGISTERS[index]+Vector3(.3,1.2,0),g.player.position+Vector3(0,1.35,0),mini(12,3+int(log(float(value)+1))),true))
		g._save_progress();g._refresh_ui()
	return value

func _complete_player_flight(delta: float) -> void:
	if player_held<=0:return
	player_remaining=maxf(0,player_remaining-delta)
	if player_remaining>0:return
	var amount:=player_held;player_held=0
	g.coins=mini(MAX_PENDING,g.coins+amount)
	g.hud.animate_income(amount,g.camera.unproject_position(g.player.position+Vector3(0,1.3,0)))
	g._float_activity(g.player.position,"+%d RECOGIDOS" % amount,Color("#f2ce75"))
	g._cash_sound();g._refresh_ui();g._save_progress()

func _process_collect_player() -> void:
	if g.town.in_build_mode or g.shop_panel.visible:return
	for i in range(active_registers):
		if pending[i]>0 and g.player.position.distance_to(REGISTERS[i])<=COLLECTION_RADIUS:take_register(i,true)

func _process_collector(delta: float) -> void:
	if not collector_hired or collector==null:return
	collector_pause=maxf(0,collector_pause-delta)
	match collector_state:
		"idle":
			if collector_pause>0:return
			var most:=0
			for i in range(1,active_registers):
				if pending[i]>pending[most]:most=i
			if pending[most]>0:collector_destination=most;collector_state="to_register"
		"to_register":
			if g._move_actor(collector,REGISTERS[collector_destination]+Vector3(0,0,1.0),3.6,delta):
				collector_held+=take_register(collector_destination,false)
				collector.set_money_carry(collector_held)
				collector.act("collect")
				_fly_money(REGISTERS[collector_destination]+Vector3(0,1.2,0),collector.position+Vector3(0,.95,.3),6,false)
				collector_state="collecting";collector_pause=.85;g._save_progress()
		"collecting":
			if collector_pause<=0:collector_state="to_bank"
		"to_bank":
			if g._move_actor(collector,BANK+Vector3(1.2,0,.2),3.45,delta):
				collector.act("deliver")
				_fly_money(collector.position+Vector3(0,1.05,.2),BANK+Vector3(0,1.15,0),6,false)
				collector_state="deposit";collector_pause=.85;g._save_progress()
		"deposit":
			if collector_pause>0:return
			var amount:=collector_held;collector_held=0;collector.set_money_carry(0)
			collector_state="idle";collector_pause=.9
			if amount>0:
				g.coins=mini(MAX_PENDING,g.coins+amount)
				g.hud.animate_income(amount,g.camera.unproject_position(BANK+Vector3(0,1.6,0)))
				g._float_activity(BANK,"+%d EN TESORERÍA" % amount,Color("#f3c86d"))
				g._cash_sound();g._refresh_ui()
			g._save_progress()

func tick(delta: float) -> void:
	_complete_player_flight(delta)
	_process_collect_player()
	_process_collector(delta)

func save_state() -> Dictionary:
	return {"pending":pending.duplicate(),"sequence":sales_sequence,"player_held":player_held,"player_remaining":player_remaining,
		"collector_hired":collector_hired,"collector_held":collector_held,"collector_state":collector_state,
		"collector_pause":collector_pause,"collector_destination":collector_destination,
		"collector_pos":[collector.position.x,collector.position.z] if collector!=null else []}

func load_state(data: Dictionary) -> void:
	var piles: Variant=data.get("pending",[])
	if piles is Array:
		for i in range(mini(piles.size(),pending.size())):pending[i]=int(Store.number({"v":piles[i]},"v",0,0,MAX_PENDING))
	sales_sequence=int(Store.number(data,"sequence",0,0,2000000000))
	player_held=int(Store.number(data,"player_held",0,0,MAX_PENDING));player_remaining=Store.number(data,"player_remaining",.8,0,1.2)
	collector_hired=data.get("collector_hired",false)==true
	collector_held=int(Store.number(data,"collector_held",0,0,MAX_PENDING))
	collector_state=str(data.get("collector_state","idle"))
	if collector_state not in ["idle","to_register","collecting","to_bank","deposit"]:collector_state="to_bank" if collector_held>0 else "idle"
	collector_pause=Store.number(data,"collector_pause",0,0,1.2)
	collector_destination=int(Store.number(data,"collector_destination",0,0,1))
	if collector_hired:
		_spawn_collector()
		collector.position=g.world.navigation.nearest_free(Store.position(data.get("collector_pos"),BANK+Vector3(1.2,0,.2)))
		# v5 can contain cash in transit with an idle state; finish transporting it.
		if collector_held>0 and collector_state in ["idle","to_register"]:collector_state="to_bank"
	if player_held>0:
		player_remaining=_fly_money(g.player.position+Vector3(.6,1.7,0),g.player.position+Vector3(0,1.35,0),6,true)
	if g.checkout_level>=1:unlock_second_register()
	for i in range(pending.size()):_refresh_register(i)
