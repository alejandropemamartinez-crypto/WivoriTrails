extends SceneTree

const Market=preload("res://scripts/refuge_market.gd")
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if ok:print("PASS: ",label)
	else:failures+=1;push_error("FAIL: "+label)
func cut(market,product: String,index: int=0) -> void:
	for hit in range(market.max_hp(product,index)):market.use(market.positions(product)[index],0)
func run() -> void:
	var market=Market.new()
	check(market.coins==0 and market.bag_count()==0,"A fresh market grants neither money nor cargo")
	check(market.town(0)["queues"]["wood"].size()==3 and market.town(0)["queues"]["meat"].size()==3,"Both goods have independent customer queues")
	market.tick(15)
	check(market.coins==0 and market.bag_count()==0,"Unhired workers never harvest or move the protagonist by passing time")
	check(market.use(Vector3.ZERO,0).is_empty(),"Proximity commands cannot harvest out of reach")
	cut(market,"wood")
	check(market.bag["wood"]==5 and not market.active_node("wood",0,0),"One pine yields five real backpack logs and enters regrowth")
	market.use(market.COUNTERS["wood"],0);market.tick(4)
	check(market.coins==0 and market.town(0)["stock"]["wood"]==5,"An unattended register does not sell before a cashier is hired")
	market.tick(4,0,0,market.COUNTERS["wood"])
	check(market.coins==20 and market.town(0)["sold"]["wood"]==5,"Standing at the counter completes orders and pays exactly for five logs")
	check(market.bag_count()==0,"Delivery transfers cargo rather than copying it")
	for index in range(3):
		market.bag={"wood":0,"meat":0};cut(market,"meat",index)
		check(market.bag["meat"]==[6,9,12][index],"Bear tier %d yields its matching meat quantity" % index)
		check(not market.active_node("meat",index,0),"Bear tier %d cannot be harvested twice" % index)
	check(market.max_hp("meat",0)<market.max_hp("meat",1) and market.max_hp("meat",1)<market.max_hp("meat",2),"Armored variants require progressively more hits")
	market.tick(20)
	check(market.active_node("wood",0,0) and market.active_node("meat",2,0),"Trees and every armored bear respawn")
	market.bag={"wood":15,"meat":0};var before: Dictionary=market.snapshot();market.use(market.BEAR_POSITIONS[2],0)
	check(market.snapshot()==before,"A full bag never destroys an armored bear or loses its larger reward")
	check(market.next_task(0)["at"]==market.COUNTERS["wood"],"A full bag is guided to a selling counter")
	var hires=Market.new();hires.coins=9999
	check(not hires.buy("lumberjack",0) and hires.buy_reason("lumberjack",0).contains("4"),"Money alone cannot bypass the visible sales unlock")
	hires.town(0)["sold"]["wood"]=4;hires.coins=60
	check(hires.buy("lumberjack",0) and hires.coins==0,"Four wood sales and sixty coins hire the first lumberjack")
	hires.coins=500;check(not hires.buy("lumberjack",0),"The second lumberjack requires its own twenty-sales milestone")
	hires.town(0)["sold"]["meat"]=20;hires.coins=120
	check(hires.buy("lumberjack",0) and hires.worker_count("lumberjack",0)==2,"The second purchase owns a second independent lumberjack")
	check(hires.worker_job("lumberjack",0)!=hires.worker_job("lumberjack",0,1),"Each hired lumberjack has a separate job and target")
	hires.tick(45)
	check(hires.town(0)["depot"]["wood"]>0 and hires.bag_count()==0,"Both lumberjacks bring real logs to storage without using the hero inventory")
	hires.coins=80;check(hires.buy("cashier",0) and hires.cashier_for("wood",0) and not hires.cashier_for("meat",0),"The first cashier staffs only the wood register")
	hires.town(0)["stock"]={"wood":5,"meat":5};hires.coins=0;hires.tick(5)
	check(hires.coins>0 and hires.town(0)["stock"]["meat"]==5,"A wood cashier cannot also run the unstaffed meat counter")
	hires.coins=120;check(hires.buy("cashier",0) and hires.cashier_for("meat",0),"The second cashier has a separate unlock and paid hire")
	hires.coins=0;hires.tick(5);check(hires.coins>0,"A hired meat cashier completes real orders while the player is away")
	hires.coins=120;check(hires.buy("hunter",0),"Meat sales unlock the independently purchased hunter")
	hires.tick(60);check(hires.town(0)["depot"]["meat"]>0,"The hunter fights and returns with normal or armored meat")
	hires.coins=160;check(hires.buy("porter",0),"Twenty sales and both cashiers unlock the porter for 160 coins")
	hires.town(0)["stock"]={"wood":0,"meat":0};var paid: int=hires.coins
	hires.tick(60)
	check(hires.coins>paid and int(hires.town(0)["carrier"]["cargo"]["wood"])+int(hires.town(0)["carrier"]["cargo"]["meat"])<=12,"The porter transports bounded cargo that cashiers sell, before a train exists")
	check(not hires.operating(0),"Foot delivery does not secretly construct a railway")
	var guards=Market.new();guards.town(0)["workers"]["sentinel"]["level"]=1
	guards.tick(.1);check(guards.town(0)["nodes"]["meat"][2]["hp"]==16 and guards.town(0)["shots"].size()==1,"A tower launches an actual delayed shot before damage is applied")
	guards.tick(.3);check(guards.town(0)["nodes"]["meat"][2]["hp"]==14,"The projectile damages the armored bear on arrival")
	guards.tick(10);check(guards.town(0)["field_meat"][2]==12 and guards.town(0)["depot"]["meat"]==0,"A tower kill leaves twelve real meat packages for collection instead of teleporting them to storage")
	guards.use(guards.BEAR_POSITIONS[2],0)
	check(guards.bag["meat"]==12 and guards.town(0)["field_meat"][2]==0,"The player can collect tower loot by entering its reach")
	guards.town(0)["field_meat"][1]=9;guards.town(0)["workers"]["hunter"]["level"]=1
	var hunter: Dictionary=guards.worker_job("hunter",0);hunter["phase"]="work";hunter["target"]=1;hunter["progress"]=1.0;guards.tick(.7)
	check(hunter["cargo"]==9 and guards.town(0)["field_meat"][1]==0,"A hunter picks up a sentinel's meat with the same conserved cargo ledger")
	guards.tick(15);check(guards.town(0)["depot"]["meat"]>=9,"Collected tower loot must physically return with the hunter before entering the depot")
	var defense=Market.new();defense.town(0)["workers"]["sentinel"]["level"]=1;defense.tick(4,0,-1,Vector3.INF,0)
	check(defense.town(0)["nodes"]["meat"][2]["hp"]==16,"A tower prioritizes protecting a raided depot over hunting bears")
	var train=Market.new();train.town(0)["sold"]={"wood":20,"meat":20};train.coins=10000
	for id in ["lumberjack","hunter","cashier","cashier"]:check(train.buy(id,0),"A normal paid team prerequisite can be hired: "+id)
	for index in range(3):check(train.buy("rail",0) and train.operating(0)==(index==2),"The train only starts after track section "+str(index+1))
	train.town(0)["depot"]={"wood":8,"meat":8};train.coins=0;train.tick(.5)
	check(train.town(0)["train"]["cargo"]["wood"]==8 and train.town(0)["depot"]["wood"]==0 and train.coins==0,"Train loading transfers goods and cannot pay before a customer buys")
	train.tick(12);check(train.coins>0,"The train and hired cashiers sell the carried stock together")
	train.town(0)["workers"]["sentinel"]["level"]=2;train.tick(.1)
	var saved: Dictionary=train.snapshot();var restored=Market.new();restored.restore(saved,0,0)
	check(restored.coins==train.coins and restored.bag==train.bag,"The wallet and backpack survive reload")
	check(restored.town(0)["train"]==train.town(0)["train"] and restored.town(0)["carrier"]==train.town(0)["carrier"],"Train and porter cargo and travel survive reload without duplication")
	check(restored.town(0)["shots"]==train.town(0)["shots"] and restored.worker_count("sentinel",0)==2,"Pending arrows and both sentinels survive reload")
	var offline=Market.new();offline.restore(saved,30,0);check(offline.coins>=train.coins and offline.offline_coins==offline.coins-train.coins,"Offline earnings use the same cashiers and real inventories")
	var twice=Market.new();twice.restore(offline.snapshot(),0,0);check(twice.coins==offline.coins and twice.offline_coins==0,"Immediate reload cannot claim an offline order twice")
	var old: Dictionary=saved.duplicate(true);old.erase("schema");old["markets"][0]["workers"].erase("cashier")
	var migrated=Market.new();migrated.restore(old,0,0)
	check(migrated.coins==train.coins and migrated.worker_count("cashier",0)==2 and migrated.operating(0),"A v0.22 update preserves the previously unattended stalls and all owned railway progress")
	check(migrated.worker_count("cashier",1)==0,"Old locked towns are not given free future staff")
	var untouched: Dictionary=train.town(1).duplicate(true);train.tick(10,0);check(train.town(1)==untouched,"Locked towns cannot earn or work")
	var malformed=Market.new();malformed.restore({"schema":2,"coins":-20,"pack_level":90,"bag":{"wood":900,"meat":900},"markets":[{"workers":{"hunter":{"level":99,"target":99,"cargo":INF,"phase":"teleport"},"sentinel":{"level":99}},"carrier":{"phase":"steal","cargo":{"wood":900,"meat":900}},"field_meat":[900,-2,NAN],"shots":[{"id":2,"tower":90,"target":90,"remaining":INF}]}]},0,0)
	check(malformed.bag_count()<=malformed.bag_capacity() and malformed.coins==0,"Damaged wallet and bag values remain bounded")
	check(malformed.worker_count("hunter",0)==3 and malformed.worker_count("sentinel",0)==2,"Staff cannot exceed the visible slot limits")
	check(malformed.town(0)["field_meat"][0]==48 and malformed.town(0)["field_meat"][1]==0,"Ground loot cannot overflow or become negative")
	before=malformed.snapshot();malformed.tick(NAN);malformed.tick(-2);check(before==malformed.snapshot(),"Invalid simulation durations cannot alter the economy")
	var play=Market.new();var seconds:=0.0
	while seconds<900 and not (play.charter_ready(0) and play.coins>=play.charter_price(0)):
		for req in [["lumberjack",1],["cashier",1],["hunter",1],["cashier",2],["porter",1],["sentinel",1]]:
			if play.worker_count(req[0],0)<req[1] and play.buy_reason(req[0],0).is_empty():play.buy(req[0],0)
		if play.buy_reason("rail",0).is_empty():play.buy("rail",0)
		var at: Vector3=Vector3.ZERO
		for product in play.PRODUCTS:
			if int(play.bag[product])>0:
				at=play.COUNTERS[product];play.use(at,0);play.tick(3,0,0,at);seconds+=3
		if play.bag_count()==0:
			if int(play.town(0)["depot"]["wood"])+int(play.town(0)["depot"]["meat"])>0:at=play.DEPOT;play.use(at,0)
			else:
				var product: String="wood" if int(play.town(0)["sold"]["wood"])<4 else "meat"
				for index in range(play.positions(product).size()):
					if play.active_node(product,index,0):at=play.positions(product)[index];play.use(at,0);break
		play.tick(.5,0,0,at);seconds+=.5
	check(play.charter_ready(0) and play.coins>=play.charter_price(0),"The first town, both registers, porter, sentinel and train are attainable using only normal harvests and paid customer orders")
	print("BALANCE PROBE: ",seconds," simulated seconds; movement omitted, not a human playtime claim")
	print("RESULT: %d market economy checks, %d failures" % [checks,failures]);quit(1 if failures else 0)
