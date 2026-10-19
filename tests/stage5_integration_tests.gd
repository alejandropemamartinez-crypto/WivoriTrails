extends SceneTree

# First cross-system QA gate for v0.18 (source-only, not run in this branch).
# Measures UI interruption discipline and preserves major stage celebrations.
var game: Node3D
var checks:=0
var failures:=0
var test_path: String="user://wivori_stage5_gate_%d.json" % OS.get_process_id()

func _initialize() -> void:
	call_deferred("run_tests")

func check(condition: bool, message: String) -> void:
	checks+=1
	if condition:
		print("PASS: ",message)
	else:
		failures+=1
		push_error("FAIL: "+message)

func run_tests() -> void:
	for suffix in ["",".bak",".tmp",".bak.tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path+suffix))
	game=load("res://Main.tscn").instantiate()
	game.save_path=test_path
	root.add_child(game)
	game.set_process(false)
	game.world.set_process(false)
	await process_frame

	# Affordable ordinary upgrades should make one soft HUD announcement,
	# never queue a full-screen tutorial on every cost tier.
	game.coins=3000
	game.event_fade=0.0
	game.director.announced.clear()
	game.director.offer_cooldown=0.0
	var first_count:int=game.director.announcement_count
	game.director.tick(.1)
	check(game.director.announcement_count==first_count+1,"Newly affordable improvements are announced once")
	check(game.milestone.pending.is_empty() and not game.milestone.is_open(),"Routine improvement guidance stays nonmodal")
	game.director.tick(.1)
	check(game.director.announcement_count==first_count+1,"Same affordable tier cannot spam repeat announcements")

	# Major campaign cards are explicitly allowed and are not silently erased
	# by the everyday popup suppression.
	game.milestone.announce("stage5:test:major","Ruta desbloqueada","Ya podés navegar a una región nueva.","boat","","NUEVO CAPÍTULO")
	game.milestone.check_wait=0.0
	game.milestone.tick(.4)
	check(game.milestone.is_open(),"Important storyline milestones still open an explicit card")
	check(game.milestone.card.anchor_bottom-game.milestone.card.anchor_top>=.75,"Story card preserves the large presentation requested by the creator")
	game.milestone.dismiss()
	check(not game.milestone.is_open() and game.milestone.seen.has("stage5:test:major"),"A confirmed major milestone does not reopen")

	# Complete an old route in memory without granting bonus coins, and
	# confirm Forja remains a selectable world alongside the existing market.
	game.route.ferry=true
	game.route.stage=game.route.PROJECTS.size()
	for p in game.route.PROJECTS:game.route.built.append(p["id"])
	game.route.refresh_board()
	check(game.route.route_button.text=="DISTRITO FORJA","Post-Faro save or progress switches route launcher to the industrial destination")
	check(game.route.unlocked()==4 and game.route.NAMES[0]=="Wivori","All five destinations retain home-market identity")
	check(not game.route.industry_order().size()>0,"Orders stay gated behind all five paid factories")
	check(game._save_data()["version"]==8,"Industry additions keep backward-compatible outer save version")

	game.queue_free()
	await process_frame
	await process_frame
	for suffix in ["",".bak",".tmp",".bak.tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path+suffix))
	print("RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures>0 else 0)
