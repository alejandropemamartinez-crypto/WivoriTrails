extends SceneTree

# Defines stage 5I worker behavior and persistence scenarios, but remains
# UNEXECUTED until Godot 4.4.1 import/build QA is authorized.
# Uses fixture stock so test time is not confused with the harvest economy.
var g:Node3D
var successes:=0
var failures:=0
var filepath:String="user://wivori_workers_cross_region_%d.json" % OS.get_process_id()

func _initialize() -> void:
	call_deferred("run_tests")

func verify(condition: bool, message: String) -> void:
	if condition:
		successes+=1
		print("PASS: ",message)
	else:
		failures+=1
		push_error("FAIL: "+message)

func clean() -> void:
	for suffix in ["",".bak",".tmp",".bak.tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(filepath+suffix))

func boot() -> void:
	g=load("res://Main.tscn").instantiate()
	g.save_path=filepath
	root.add_child(g)
	g.set_process(false)
	g.world.set_process(false)
	await process_frame

func restart() -> void:
	verify(g._save_progress(),"The running workers can be saved without changing schema")
	g.queue_free()
	await process_frame
	await process_frame
	await boot()

func sail(destination: int) -> void:
	var route=g.route
	g.player.position=route.DOCK if route.away() else route.HOME_DOCK
	verify(route.travel(destination),"Physical ferry departs for region %d" % destination)
	route.tick(1.4)
	verify(route.region==destination,"Travel reaches actual region %d" % destination)

func run_tests() -> void:
	clean()
	await boot()
	var route=g.route
	route.ferry=true
	route.stage=route.PROJECTS.size()
	for project in route.PROJECTS:route.built.append(project["id"])
	var wallet:int=g.coins
	# An operator works from SHIP storage, never from the protagonist's
	# personal bag, even when that player happens to be in another region.
	route.inventory["wheat"]=20
	route.bag["wheat"]=5
	route.employees["flour"]=true
	g.save_timer=8.0
	route.tick(.1)
	verify(route.jobs.has("flour") and route.jobs["flour"]["remaining"]>0,"A hired mill worker starts a real batch while Wivori is active")
	verify(route.inventory["wheat"]==17 and route.bag["wheat"]==5,"Automatic production consumes exactly three stored wheat, not carried wheat")
	verify(g.save_timer<=2.0,"The first automatic batch requests one coalesced near-term save instead of synchronous file writes")
	var remaining:float=route.jobs["flour"]["remaining"]
	route.tick(.1)
	verify(is_equal_approx(route.jobs["flour"]["remaining"],remaining-.1) and route.inventory["wheat"]==17,"Repeated frames cannot consume inputs for the same running batch")
	await sail(2)
	verify(route.region==2 and route.employees["flour"],"Remote worker persists while the player visits Puerto Nata")
	route.tick(13.0)
	verify(route.jobs["flour"]["ready"]==2 and route.inventory["wheat"]==14,"Off-island mill completes output and starts exactly one new stored-input batch")
	verify(route.jobs["flour"]["remaining"]>0.0,"Worker's second batch takes real time, no instant creation")
	# Disabling an operator prevents NEW batches but does not destroy the
	# already purchased and processing ingredients.
	route.employees["flour"]=false
	route.tick(13.0)
	verify(route.jobs["flour"]["ready"]==4 and route.jobs["flour"]["remaining"]==0.0,"Pausing an operator lets its existing paid batch finish, then stops")
	verify(route.inventory["wheat"]==14 and route.bag["wheat"]==5,"Paused operator neither steals player cargo nor restarts itself")
	var stored:int=route.jobs["flour"]["ready"]
	route.tick(26.0)
	verify(route.jobs["flour"]["ready"]==stored and route.inventory["wheat"]==14,"Repeated ticks of a paused off-island workshop never manufacture extras")
	await restart()
	route=g.route
	verify(route.region==2 and not route.employees["flour"],"A save in Puerto Nata restores the remote worker's paused status")
	verify(route.jobs["flour"]["ready"]==4 and route.inventory["wheat"]==14 and route.bag["wheat"]==5,"Four manufactured units and exact input balances survive restart")
	verify(g.coins==wallet and g.player.carrying==5,"Background production never mints coins or consumes hero cargo")
	route.employees["flour"]=true
	route.tick(.15)
	verify(route.jobs["flour"]["remaining"]>0 and route.inventory["wheat"]==11,"Resuming a saved remote employee starts only a new legitimate batch")
	route.employees["flour"]=false
	route.tick(13.0)
	verify(route.jobs["flour"]["ready"]==6,"Completed resume adds exactly one batch to the finite output buffer")
	await sail(1)
	g.player.position=route.station("flour")
	verify(route.pickup("flour") and route.bag["flour"]==6,"Physically visiting the mill transfers finished stock into backpack")
	verify(route.jobs["flour"]["ready"]==0 and g.player.carrying==11,"Pickup removes the finite output exactly once and updates the visible player load")
	verify(not route.pickup("flour"),"Picking the same finished output a second time gives nothing")
	# A manually started batch must take inputs from the carried pouch first.
	# This previously left the 3D backpack stale until the next route tick.
	var wheat_before:int=route.inventory["wheat"]
	var avatar_before:int=g.player.carrying
	g.save_timer=8.0
	verify(route.start_batch("flour",false),"Manual flour production can start after collecting a completed automated batch")
	verify(route.bag["wheat"]==2 and route.inventory["wheat"]==wheat_before,"Manual batch consumes the player's three wheat before taking warehouse stock")
	verify(g.player.carrying==avatar_before-3 and g.player.goods_root.get_child_count()==6,"Manual ingredient consumption refreshes the real 3D backpack immediately")
	verify(route.jobs["flour"]["remaining"]>0,"Manual workshop uses the same non-instant production timer as workers")
	var inventory:Dictionary=route.inventory.duplicate()
	var bag:Dictionary=route.bag.duplicate()
	await sail(0)
	verify(route.inventory==inventory and route.bag==bag and g.coins==wallet,"Travelling home never changes stored or carried production goods")
	await restart()
	verify(g.route.region==0 and g.route.inventory==inventory and g.route.bag==bag,"Remote worker goods survive a home-world restart without a new save format")
	g.queue_free()
	await process_frame
	await process_frame
	clean()
	print("RESULT: %d prepared worker checks, %d failures (not executed)" % [successes+failures,failures])
	quit(1 if failures else 0)
