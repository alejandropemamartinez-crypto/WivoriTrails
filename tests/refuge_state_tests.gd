extends SceneTree

const State=preload("res://scripts/refuge_state.gd")
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if ok:print("PASS: ",label)
	else:failures+=1;push_error("FAIL: "+label)
func advance(state,seconds: float,offline: bool=false) -> void:
	var remaining: float=seconds
	while remaining>.001:
		var step: float=minf(.25,remaining);state.tick(step,offline);remaining-=step
func fixture():
	var state=State.new();state.lit=true
	for id in state.BUILDINGS:state.town()["levels"][id]=4
	state.town()["people"]=14
	for id in ["lumber","kitchen","coal","mine"]:state.town()["workers"][id]=2
	state.resources={"wood":800.0,"food":300.0,"coal":250.0,"iron":100.0}
	return state
func run() -> void:
	var state=State.new()
	var before: Dictionary=state.resources.duplicate()
	advance(state,20)
	check(state.resources==before,"An unlit settlement neither produces nor consumes invisible resources")
	check(not state.start_upgrade("lumber") and not state.assign("lumber",1),"A building cannot be built or staffed before its prerequisites")
	check(state.ignite() and not state.ignite(),"Igniting the central heart is an idempotent player command")
	state.resources["wood"]=0.0
	check(state.start_upgrade("lumber"),"The founding sawmill can always be built after spending the starter logs")
	var wallet: Dictionary=state.resources.duplicate()
	check(not state.start_upgrade("lumber") and state.resources==wallet,"Repeated construction taps cannot charge twice or queue a duplicate")
	check(state.next_task()["title"].contains("6 s") and state.next_task()["action"]=="team","The guide shows the active construction timer instead of asking to build it again")
	advance(state,6)
	check(state.level("lumber")==1 and state.construction.is_empty(),"A real timer completes the building exactly once")
	advance(state,6)
	check(state.level("lumber")==1 and float(state.resources["wood"])==0,"An unstaffed sawmill does not secretly produce")
	check(state.assign("lumber",1),"A free inhabitant can be assigned to a finished work station")
	advance(state,10)
	check(float(state.resources["wood"])>10,"Assigned inhabitants produce a renewable supply of construction material")
	check(state.assign("lumber",1) and not state.assign("lumber",1),"Workstation capacity is enforced on repeated assignments")
	check(state.assign("lumber",-1) and state.free_workers()==3,"Removing a worker releases the same person for another job")
	check(not state.start_upgrade("factory"),"The advanced foundry is gated by the central building level")
	check(not state.open_next() and not state.travel(1),"A locked destination cannot be opened or entered through stale UI actions")
	check(state.next_task()["id"]=="lumber" and "Huerto de invierno" in state.next_task()["title"],"The guide identifies wood needed to build the next food station")
	state=fixture()
	check(state.start_upgrade("core"),"A valid city upgrade consumes the displayed construction resources")
	var paid: Dictionary=state.resources.duplicate()
	var snapshot: Dictionary=state.snapshot(1000)
	var restored=State.new();restored.restore(snapshot,1001)
	check(restored.level("core")==4 and not restored.construction.is_empty(),"A partially completed construction restores without replaying payment")
	check(float(restored.resources["wood"])>=float(paid["wood"]),"Offline production does not deduct the construction price again")
	advance(restored,30)
	check(restored.level("core")==5 and restored.construction.is_empty(),"Restored timers deliver precisely the purchased next level")
	state=fixture()
	check(state.start_expedition(0) and state.free_workers()==4,"Dispatching a route reserves two real inhabitants")
	check(not state.start_expedition(1),"One active expedition cannot be duplicated by another tap")
	advance(state,35)
	check(state.expedition.is_empty() and state.expeditions_done==1 and state.completed_routes==["supplies"],"The timed voyage delivers and records one distinct route")
	check(state.free_workers()==6,"Returning explorers release their two reserved work slots")
	var completed=State.new();completed.restore(state.snapshot(2000),2000)
	advance(completed,1)
	check(completed.expeditions_done==1 and completed.completed_routes.size()==1,"Reopening a completed voyage cannot replay its reward")
	var offline_source=fixture();offline_source.start_expedition(1);offline_source.start_upgrade("core")
	var offline_snapshot: Dictionary=offline_source.snapshot(1000)
	var expected=fixture();expected.restore(offline_snapshot,1000);advance(expected,100,true)
	var actual=State.new();actual.restore(offline_snapshot,1100)
	for key in actual.resources:check(absf(float(actual.resources[key])-float(expected.resources[key]))<.15,"Offline %s matches stepped economy and input consumption" % key)
	check(actual.expeditions_done==expected.expeditions_done and actual.level("core")==5,"Offline construction and expedition completions use the same transaction logic")
	check(actual.town()["storms"]==0 and actual.raid_remaining==0,"No unobserved storm or theft penalizes a closed application")
	var capped=State.new();capped.restore(offline_snapshot,1000+86400)
	var cap_expected=State.new();cap_expected.restore(offline_snapshot,1000+7200)
	check(capped.resources==cap_expected.resources,"Offline gains are capped at two hours")
	var backwards=State.new();backwards.restore(offline_snapshot,900)
	check(backwards.resources==offline_snapshot["resources"] and backwards.expeditions_done==0,"Moving the clock backwards cannot award negative time or a free voyage")
	state=fixture();state.resources["wood"]=120.0;state.resources["coal"]=70.0;state.assign("factory",1)
	var iron_before: float=float(state.resources["iron"]);state.town()["workers"]["mine"]=0
	check(state.production("factory")==0,"The foundry protects the construction and heating reserve from automatic consumption")
	state.town()["workers"]["lumber"]=0;state.town()["workers"]["coal"]=0
	advance(state,2)
	check(float(state.resources["iron"])==iron_before and float(state.resources["wood"])==120.0,"A paused foundry does not drain the last wood or invent output")
	state=fixture();state.town()["storm_clock"]=119.75;advance(state,32.5)
	check(state.town()["storms"]==1,"A continuously warm settlement earns its storm-protection milestone")
	state=fixture();state.resources["coal"]=0;state.town()["workers"]["coal"]=0;state.town()["levels"]["core"]=2;state.town()["storm_clock"]=119.75;advance(state,32.5)
	check(state.town()["storms"]==0,"A cold, fuel-starved city cannot receive an unearned survival milestone")
	state=fixture();state.town()["storms"]=1
	var saved_wood: float=float(state.resources["wood"]);state.resources["wood"]=2.0
	check(state.next_task()["id"]=="lumber" and "Valle Ámbar" in state.next_task()["title"],"Completed milestones with missing caravan cargo guide the exact remaining resource")
	state.resources["wood"]=saved_wood
	check(state.ready_next() and state.open_next() and state.unlocked==1,"Completing the visible milestones opens exactly the next destination")
	check(not state.open_next() and state.travel(1),"The same completed chapter cannot skip another map")
	check(state.level("core")==2 and state.worker_count("lumber")==1,"The founding caravan starts the next zone with a staffed basic camp")
	var old_stock: float=float(state.resources["wood"]);state.town()["workers"]["lumber"]=0;advance(state,5)
	check(float(state.resources["wood"])>old_stock,"Previous settlements continue producing through the shared logistics network")
	state=fixture();state.unlocked=2;state.city=2;state.raid_remaining=14;state.raid_hits=0
	check(not state.travel(0),"An active robbery must be resolved before leaving the city")
	state.town()["levels"]["watch"]=3
	check(state.repel() and state.repel() and state.defended==1 and state.raid_remaining==0,"The paid guard upgrade reduces the signals needed to protect the cargo")
	var malformed: Dictionary=state.snapshot(1000);malformed["resources"]={"wood":-400,"food":"bad","coal":INF,"iron":10000000000}
	malformed["cities"][2]["people"]=900;malformed["cities"][2]["workers"]={"lumber":999,"kitchen":999,"factory":999}
	var safe=State.new();safe.restore(malformed,1000)
	check(float(safe.resources["wood"])==0 and is_finite(float(safe.resources["coal"])) and float(safe.resources["iron"])==10000000,"Damaged resource fields are bounded and non-finite values rejected")
	check(safe.used_workers()<=int(safe.town()["people"]) and int(safe.town()["people"])<=safe.capacity(),"Malformed saves cannot create more assigned workers than inhabitants or homes")
	var regional=fixture();regional.unlocked=5
	for area in range(1,6):regional.cities[area]=regional.cities[0].duplicate(true)
	check(is_equal_approx(regional.production("kitchen",1),regional.production("kitchen",0)*1.25),"Valle Ámbar's food specialization changes the real production rate")
	check(is_equal_approx(regional.production("mine",3),regional.production("mine",0)*1.3),"Cumbre Cobre's metal specialization changes the real production rate")
	regional.city=2
	check(regional.start_expedition(0) and is_equal_approx(float(regional.expedition["duration"]),28.0),"Costa Cristal's expedition bonus shortens the real voyage timer")
	check(is_equal_approx(regional.background_rate(),.45),"Aurora upgrades the existing settlement network's background production")
	print("RESULT: %d refuge state checks, %d failures" % [checks,failures]);quit(1 if failures else 0)
