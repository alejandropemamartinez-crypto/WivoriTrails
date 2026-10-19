extends SceneTree

# Real imported-art and UI checks for the v0.17 art-direction gate.
# A passing test does NOT certify artistic beauty; human review of clear
# Godot renders and on-device motion is still required before approval.
var game: Node3D
var checks:=0
var failures:=0
var save_path: String="user://wivori_art_gate_%d.json" % OS.get_process_id()

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks+=1
	if condition:
		print("PASS: ",message)
	else:
		failures+=1
		push_error("FAIL: "+message)

func run() -> void:
	game=load("res://Main.tscn").instantiate()
	game.save_path=save_path
	root.add_child(game)
	game.set_process(false)
	game.world.set_process(false)
	await process_frame

	check(game.player.name=="Protagonista", "Main character remains intentionally unnamed")
	check(game.player.body_root!=null and game.player.skeleton!=null,
		"The protagonist uses an imported mesh and an actual skeleton")
	check(game.player.animator!=null and game.player.animator.get_animation_list().size()>=14,
		"The imported protagonist has at least fourteen distinct animation clips")
	check(game.player.head_mesh!=null and game.player.head_mesh.mesh!=null,
		"The hero head is geometry rather than a disconnected billboard")
	check(game.player.character_role=="player" and game.player.species=="dog",
		"The original canine is the controllable protagonist")

	var unique_species: Array[String]=["fox","rabbit","pig","duck","raccoon"]
	var valid_count:=0
	for species in unique_species:
		var actor=load("res://scripts/actor.gd").new()
		actor.setup("customer",Color("#76a99c"),species)
		game.add_child(actor)
		if actor.body_root!=null and actor.skeleton!=null and actor.species==species:
			valid_count+=1
		actor.queue_free()
	check(valid_count==unique_species.size(),
		"NPC art comes from five different non-terrier species")

	var first_pad: Dictionary=game.world.upgrade_pads["helper"]
	var buy_label: Label3D=first_pad["label"]
	var raised: bool=buy_label.position.y>3.2 and first_pad["board"] is Sprite3D
	check(raised and buy_label.no_depth_test, "Purchase labels are elevated above the stalls and cannot be hidden behind the roof")
	check(buy_label.font_size>=50 and first_pad["price"].font_size>=43 and first_pad["emblem"] is Sprite3D,
		"Each upgrade has a raised, larger headline, distinct icon and visible price")
	check(game.cash.treasury_label.position.y>3 and game.cash.labels[0].position.y>3,
		"Treasury and collection labels stand above their buildings")
	check(game.hud.mission_detail.autowrap_mode==TextServer.AUTOWRAP_WORD_SMART and game.hud.mission_detail.clip_text,
		"Mission explanations can wrap instead of being aggressively truncated")
	game.world.focus_upgrade_labels(first_pad["node"].position,false,"")
	check(buy_label.visible and first_pad["price"].visible and first_pad["board"].visible,
		"An accessible upgrade sign stays readable when the player stands right next to it")
	game.world.focus_upgrade_labels(first_pad["node"].position,true,"")
	check(not buy_label.visible, "Building mode hides distracting market purchase overlays")
	game.world.focus_upgrade_labels(Vector3(400,0,400),false,"")
	check(not buy_label.visible, "Offscreen distant market signs are not rendered unnecessarily")

	var card: PanelContainer=game.milestone.card
	check(card.anchor_bottom-card.anchor_top>=.75 and card.anchor_right-card.anchor_left>=.75,
		"Major story milestones occupy at least three-quarters of the viewport")
	check(game.hud.rabbit_banner!=null and game.hud.rabbit_banner.animator!=null,
		"The recurring robbery warning uses an animated 3D rabbit portrait")
	game.milestone.seen["chapter:3"]=true
	game.milestone.seen["tutorial:primer_robo"]=true
	game.milestone.seen["tutorial:mercado:Recogé lo que ganaste"]=true
	game.milestone.seen["tutorial:mercado:Llevá tu cosecha al puesto"]=true
	game.run.level=3
	game.run.warning=4.0
	game.milestone.check_wait=0.0
	game.milestone.tick(.6)
	check(not game.milestone.is_open() and game.milestone.pending.is_empty(),
		"Later raccoon attacks do not reopen blocking full-screen tutorials")

	game.queue_free()
	await process_frame
	await process_frame
	for ext in ["",".bak",".tmp",".bak.tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path+ext))
	print("RESULT: %d art-direction checks, %d failures" % [checks,failures])
	quit(1 if failures>0 else 0)
