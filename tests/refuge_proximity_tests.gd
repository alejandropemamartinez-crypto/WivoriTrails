extends SceneTree

const Market=preload("res://scripts/refuge_market.gd")
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if ok:print("PASS: ",label)
	else:failures+=1;push_error("FAIL: "+label)
func run() -> void:
	var market=Market.new()
	var pine: Vector3=market.TREE_POSITIONS[1]+Vector3(0,0,-1.5)
	var before: int=market.town(0)["nodes"]["wood"][1]["hp"]
	market.use(pine,0)
	check(market.town(0)["nodes"]["wood"][1]["hp"]<before,"An empty nearby depot must not block automatic axe hits on the pine")
	for product in market.PRODUCTS:
		for offset in [Vector3(-3.1,0,0),Vector3(3.1,0,0),Vector3(0,0,-1.7),Vector3(0,0,4.0)]:
			var shop=Market.new();shop.bag[product]=5
			var at: Vector3=shop.SHOP_POSITIONS[product]+offset
			shop.use(at,0)
			check(shop.bag[product]==0 and shop.town(0)["stock"][product]==5,"Approaching the %s stall from %s transfers the carried goods" % [product,offset])
			shop.tick(4,0,0,at)
			check(shop.coins==5*shop.unit_price(product,0),"The same %s delivery zone also attends the register from %s" % [product,offset])
	var far=Market.new();far.bag["wood"]=5;far.use(Vector3.ZERO,0)
	check(far.bag["wood"]==5 and far.town(0)["stock"]["wood"]==0,"Automatic delivery never moves goods across the map")
	var edge=Market.new();edge.use(edge.BEAR_POSITIONS[0]+Vector3(0,0,3.0),0)
	check(edge.town(0)["nodes"]["meat"][0]["hp"]<4,"Entering the visible bear's outer reach starts the scythe")
	var full=Market.new();full.bag["wood"]=16
	for hit in range(16):full.use(full.BEAR_POSITIONS[2],0)
	check(not full.active_node("meat",2,0),"A full backpack does not disable automatic combat against armored bears")
	check(full.bag_count()==16 and full.town(0)["field_meat"][2]==12,"A full backpack leaves the complete bear reward on the ground without overflow")
	for hit in range(3):full.use(full.TREE_POSITIONS[5],0)
	check(not full.active_node("wood",5,0) and full.town(0).get("field_wood",[]).size()==6 and full.town(0).get("field_wood",[])[5]==5,"A full backpack also allows axe hits and preserves the uncollected logs")
	var restored=Market.new();restored.restore(full.snapshot(),0,0)
	check(restored.town(0).get("field_wood",[])==full.town(0).get("field_wood",[]) and restored.town(0)["field_meat"]==full.town(0)["field_meat"],"Uncollected wood and meat survive saving and reloading")
	restored.use(restored.COUNTERS["wood"],0);restored.use(restored.TREE_POSITIONS[5],0)
	check(restored.bag["wood"]==5 and restored.town(0).get("field_wood",[]).size()==6 and restored.town(0).get("field_wood",[])[5]==0,"Returning after unloading collects the saved logs automatically")
	print("RESULT: %d proximity regression checks, %d failures" % [checks,failures]);quit(1 if failures else 0)
