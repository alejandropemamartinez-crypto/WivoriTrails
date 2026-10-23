extends SceneTree

# A player-command simulation starts with the actual founding kit. No wallet
# grants, level edits, skipped construction timers or precompleted chapters.
const State=preload("res://scripts/refuge_state.gd")
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if ok:print("PASS: ",label)
	else:failures+=1;push_error("FAIL: "+label)
func prioritize(state,id: String) -> void:
	if state.worker_count(id)>=mini(4,state.max_workers(id)):return
	if state.free_workers()==0:
		for other in ["factory","kitchen","mine","coal","lumber"]:
			if other!=id and state.worker_count(other)>1:state.assign(other,-1);break
	if state.free_workers()>0:state.assign(id,1)
func run() -> void:
	var state=State.new();var elapsed:=0.0;var opened_at: Array[float]=[]
	var recorded:=-1;var max_wait:=0.0;var previous_task:="";var unchanged:=0.0
	for frame in range(72000):
		if state.city!=recorded:
			recorded=state.city;opened_at.append(elapsed);print("REFUGE ECONOMY: ",state.NAMES[state.city]," at ",elapsed," simulated seconds")
		if state.city==5 and state.goal_progress()==state.goals().size():break
		if frame%4==0:
			var task: Dictionary=state.next_task()
			var tag: String=task["action"]+":"+task["id"]+":"+str(state.level(task["id"]))
			unchanged=unchanged+1.0 if tag==previous_task else 0.0;previous_task=tag;max_wait=maxf(max_wait,unchanged)
			if state.receive_family():pass
			match task["action"]:
				"ignite":state.ignite()
				"repel":state.repel()
				"route":
					if state.city<state.unlocked:state.travel(state.unlocked)
					elif state.open_next():state.travel(state.unlocked)
					else:prioritize(state,"lumber");prioritize(state,"coal")
				"fleet":
					for index in range(state.ROUTES.size()):
						if state.ROUTES[index]["id"] not in state.completed_routes:
							# Free two explorers as a player would from the team panel.
							for id in ["mine","lumber","kitchen","coal"]:
								while state.free_workers()<2 and state.worker_count(id)>1:state.assign(id,-1)
							state.start_expedition(index);break
				"team":
					if task["id"] in ["lumber","kitchen","coal","mine"]:prioritize(state,task["id"])
				"building":
					var id: String=task["id"]
					if state.BUILDINGS[id].has("resource") and state.level(id)>0:prioritize(state,id)
					if state.construction.is_empty() and not str(task["button"]) in ["PRODUCCIÓN","ASIGNAR"]:state.start_upgrade(id)
					# Improving a producing station is a deliberate alternative
					# when its output would otherwise be a long wait.
					elif task["button"]=="PRODUCCIÓN" and unchanged>35.0 and state.level(id)<mini(4,state.level("core")):
						state.start_upgrade(id)
			# One baseline worker keeps each essential supply renewable.
			for id in ["lumber","kitchen","coal","mine"]:
				if state.level(id)>0 and state.worker_count(id)==0 and state.free_workers()>0:state.assign(id,1)
		state.tick(.25);elapsed+=.25
		if frame%400==0:await process_frame
	check(state.city==5,"All six sequential settlements are reachable from the real founding economy")
	check(state.goal_progress()==state.goals().size(),"The final settlement and all three expedition routes can be completed without grants")
	check(state.completed_routes.size()==3 and state.expeditions_done==3,"Each expedition type counts once toward the network goal")
	check(opened_at.size()==6 and opened_at[1]<900,"The first new destination is reachable within fifteen simulated minutes")
	check(elapsed<9000,"The campaign has no multi-hour resource or prerequisite dead end in the command simulation")
	for key in state.resources:check(float(state.resources[key])>=0,"The %s balance remains nonnegative throughout the route" % key)
	if failures:print("FINAL STATE: ",state.next_task()," · ",state.resources," · ",state.town()," · queue ",state.construction)
	print("RESULT: %d refuge economy checks, %d failures; %.1f simulated seconds; longest unchanged objective %.1f s" % [checks,failures,elapsed,max_wait]);quit(1 if failures else 0)
