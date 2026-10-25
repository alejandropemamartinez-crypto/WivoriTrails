extends SceneTree

const Market=preload("res://scripts/refuge_market.gd")
var checks:=0
var failures:=0
var sales:=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if ok:print("PASS: ",label)
	else:failures+=1;push_error("FAIL: "+label)
func harvest(market,product: String,index: int=0,area: int=0) -> void:
	for hit in range(market.max_hp(product)):market.use(market.positions(product)[index],area)
func run() -> void:
	var market=Market.new();market.earned.connect(func(_area,_product,amount,_quantity):sales+=amount)
	check(market.bag_count()==0 and market.coins==0,"A new market begins with no fabricated income or cargo")
	check(market.town(0)["queues"]["wood"].size()==3 and market.town(0)["queues"]["meat"].size()==3,"Both stalls start with actual customers and orders")
	check(market.context(market.TREE_POSITIONS[0],0)["title"].contains("HACHA"),"A pine equips the axe context")
	check(market.context(market.BEAR_POSITIONS[0],0)["title"].contains("HOZ"),"A polar bear equips the scythe context")
	var before: Dictionary=market.snapshot();market.tick(10)
	check(market.bag_count()==0 and market.coins==0,"Passing time cannot harvest, hunt or sell for an unhired player")
	check(market.use(Vector3.ZERO,0).is_empty(),"Harvest commands outside reach do nothing")
	harvest(market,"wood")
	check(market.bag["wood"]==5 and market.coins==0,"Chopping a pine produces five carried logs, never instant cash")
	check(not market.active_node("wood",0,0),"A cut tree enters a real regrowth cooldown")
	check(market.use(market.TREE_POSITIONS[0],0).is_empty(),"The same fallen tree cannot be harvested twice")
	var stock_before: int=market.town(0)["stock"]["wood"]
	var delivery: Dictionary=market.use(market.COUNTERS["wood"],0)
	check(delivery.get("quantity")==5 and market.bag_count()==0 and market.town(0)["stock"]["wood"]==stock_before+5,"Delivery transfers real backpack goods to the correct stall")
	market.tick(.25)
	check(market.coins==0,"Handing over one unit of an unfinished two-unit order cannot pay early")
	market.tick(3)
	check(market.coins==20 and sales==20 and market.town(0)["sold"]["wood"]==5,"Two completed orders consume five logs and pay exactly twenty coins")
	harvest(market,"meat")
	check(market.bag["meat"]==6 and market.town(0)["nodes"]["meat"][0]["respawn"]>0,"Four manual scythe hits yield six packages of bear meat")
	market.use(market.COUNTERS["meat"],0);market.tick(4)
	check(market.town(0)["sold"]["meat"]>0 and market.coins>20,"The independent meat queue pays its own higher unit price")
	market.tick(30)
	check(market.active_node("wood",0,0) and market.active_node("meat",0,0),"Pines and bears replenish, preventing resource exhaustion")
	for product in market.PRODUCTS:check(market.town(0)["queues"][product].size()<=6,"Waiting customers are capped for "+product)
	market.bag={"wood":15,"meat":0};before=market.snapshot();market.use(market.BEAR_POSITIONS[0],0)
	check(market.snapshot()==before,"A full backpack cannot delete a bear or lose its yield")
	check(market.next_task(0)["at"]==market.COUNTERS["wood"],"A full bag redirects the objective to a usable selling counter")
	market.coins=59
	check(not market.buy("lumberjack",0) and market.coins==59,"Hiring validates its price and never overdrafts")
	market.coins=60
	check(market.buy("lumberjack",0) and market.coins==0,"Sixty earned coins hire one persistent lumberjack")
	check(not market.buy("rail",0),"A railway cannot bypass the required hunting hire")
	market.tick(45)
	check(market.town(0)["depot"]["wood"]>0 and market.bag["wood"]==15,"The visible lumberjack delivers logs to storage without controlling the hero or its bag")
	market.bag={"wood":0,"meat":0};var depot_before: int=market.town(0)["depot"]["wood"]
	market.use(market.DEPOT,0)
	check(market.bag["wood"]>0 and market.town(0)["depot"]["wood"]+market.bag["wood"]==depot_before,"Taking worker goods preserves the stock-to-backpack ledger")
	market.coins=120;check(market.buy("hunter",0),"The hunter has a separate, coin-funded unlock")
	var hero_bag: Dictionary=market.bag.duplicate();market.tick(45)
	check(market.town(0)["depot"]["meat"]>0 and market.bag==hero_bag,"The hunter actually brings meat back and leaves the player inventory alone")
	for section in range(3):
		market.coins=market.price("rail",0);check(market.buy("rail",0),"Rail section %d purchases once at its exact increasing price" % (section+1))
		check(market.operating(0)==(section==2),"The train only operates after a closed three-section circuit")
	market.coins=0;market.town(0)["stock"]={"wood":0,"meat":0}
	market.town(0)["depot"]={"wood":8,"meat":8}
	market.tick(.5)
	check(market.town(0)["train"]["cargo"]["wood"]==8 and market.coins==0,"The train loads actual stock at the depot before it can earn money")
	check(market.town(0)["depot"]["wood"]==0,"Loaded logs leave the depot immediately; they are not copied")
	market.tick(10)
	check(market.coins>0 and market.town(0)["stock"]["meat"]<8,"The train unloads at the stalls and actual queued customers pay")
	var paid: int=market.coins;market.tick(60)
	check(market.coins>paid and market.town(0)["train"]["laps"]>=2,"Hired harvesting plus a running train sustain repeat sales without manual delivery")
	market.tick(7200)
	for product in market.PRODUCTS:
		check(market.town(0)["depot"][product]<=64 and market.town(0)["stock"][product]<=24,"Long sessions obey warehouse and stall capacities for "+product)
	check(market.charter_ready(0),"Real automated sales and the purchased circuit satisfy the first town's four visible goals")
	var saved: Dictionary=market.snapshot();var restored=Market.new();restored.restore(saved,0,0)
	check(restored.coins==market.coins and restored.bag==market.bag,"Wallet and mixed cargo survive a save round trip")
	check(restored.town(0)["workers"]==market.town(0)["workers"] and restored.operating(0),"Hires, work-in-progress cargo and completed railway survive reload")
	check(restored.town(0)["train"]==market.town(0)["train"],"Train position, waiting station and cargo survive reload without duplication")
	var resume=Market.new();resume.restore(saved,20,0)
	check(resume.coins>=restored.coins and resume.offline_coins==resume.coins-restored.coins,"Offline earnings use the same stock ledger and report the exact gain")
	var twice=Market.new();twice.restore(resume.snapshot(),0,0)
	check(twice.coins==resume.coins and twice.offline_coins==0,"A second immediate load cannot claim the offline sale twice")
	var untouched: Dictionary=market.town(1).duplicate(true);market.tick(20,0)
	check(market.town(1)==untouched,"Locked towns cannot generate resources, customers or money")
	market.tick(1,1)
	check(market.town(1)!=untouched,"An explicitly opened town begins its own market simulation")
	var malformed=Market.new();malformed.restore({"coins":-50,"pack_level":99,"bag":{"wood":900,"meat":900},"markets":[{"rails":40,"tool":NAN,"workers":{"hunter":{"phase":"teleport","level":90,"cargo":900,"target":900}},"train":{"next_stop":99,"distance":INF,"cargo":{"meat":500}},"queues":{"wood":[null,{"id":3,"quantity":100},{"id":3,"quantity":100}]}}]},0,0)
	check(malformed.coins==0 and malformed.bag_count()<=malformed.bag_capacity(),"Corrupt or old wallet and inventory values are safely bounded")
	check(malformed.town(0)["workers"]["hunter"]["level"]==3 and malformed.town(0)["workers"]["hunter"]["phase"]=="out","Corrupt employee roles, levels and targets cannot poison the simulation")
	before=malformed.snapshot();malformed.tick(NAN);malformed.tick(-10)
	check(before==malformed.snapshot(),"Invalid tick durations cannot mutate the economy")
	# Play the full manual -> hires -> rails -> charter loop without gifting
	# any money, resources, completed orders or workers to the simulation.
	var play=Market.new();var seconds:=0.0
	while seconds<600 and not (play.charter_ready(0) and play.coins>=play.charter_price(0)):
		for role in play.ROLE_NAMES:
			if int(play.town(0)["workers"][role]["level"])==0 and play.buy_reason(role,0).is_empty():play.buy(role,0)
		if play.buy_reason("rail",0).is_empty():play.buy("rail",0)
		for product in play.PRODUCTS:
			if int(play.bag[product])>0:play.use(play.COUNTERS[product],0)
		if play.bag_count()==0:
			if int(play.town(0)["depot"]["wood"])+int(play.town(0)["depot"]["meat"])>0:play.use(play.DEPOT,0)
			else:
				var product: String="meat" if play.town(0)["sold"]["wood"]>0 else "wood"
				for index in range(play.positions(product).size()):
					if play.active_node(product,index,0):play.use(play.positions(product)[index],0);break
		play.tick(.5);seconds+=.5
	check(play.charter_ready(0) and play.coins>=play.charter_price(0),"The first commercial route is reachable using only normal harvests, paid customers and bought automation")
	print("BALANCE PROBE: ",seconds," simulated seconds (commands omit travel; this is not a human playtime claim)")
	print("RESULT: %d market economy checks, %d failures" % [checks,failures]);quit(1 if failures else 0)
