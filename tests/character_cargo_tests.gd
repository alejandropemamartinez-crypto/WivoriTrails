extends SceneTree

# Source-only regression suite. Do not run without the later Godot QA gate.
# Visual cargo is an image of game state, NOT an economic inventory owner.
const ActorScript=preload("res://scripts/actor.gd")
var checked:=0
var failed:=0
var game: Node3D
var save_path: String="user://wivori_stage5f_cargo_%d.json" % OS.get_process_id()

func _initialize() -> void:
	call_deferred("run_tests")

func check(value: bool, message: String) -> void:
	checked+=1
	if value:print("PASS: ",message)
	else:failed+=1;push_error("FAIL: "+message)

func clean() -> void:
	for suffix in ["",".bak",".tmp",".bak.tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path+suffix))

func run_tests() -> void:
	clean()
	var actors:=Node3D.new()
	root.add_child(actors)
	var customer: MarketActor=ActorScript.new()
	customer.setup("customer",Color("#a47d65"),"fox")
	actors.add_child(customer)
	check(customer.goods_root.get_child_count()==0 and customer.stolen_bundle.get_child_count()==0,"Empty-handed customer does not instantiate five unrelated fruits")
	customer.set_cargo_kind("tomato")
	customer.set_carry(3)
	check(customer.goods_root.visible and customer.goods_root.get_child_count()==4,"Customer receiving tomatoes shows only real produce")
	for item in customer.goods_root.get_children():
		check(item.scene_file_path=="res://assets/models/produce_tomato.glb","Single-product courier never shows incorrect goods")
	customer.set_carry(0)
	check(not customer.goods_root.visible,"After finishing delivery the customer's hands are visibly empty")

	var thief: MarketActor=ActorScript.new()
	thief.setup("thief",Color("#7b8b8a"),"raccoon")
	actors.add_child(thief)
	check(thief.stolen_bundle.get_child_count()==0,"Raccoons do not spawn already holding imaginary tomatoes")
	thief.set_cargo_kind("berry")
	thief.set_carry(2)
	check(thief.stolen_bundle.visible and not thief.goods_root.visible and thief.stolen_bundle.get_child_count()==4,"Stolen berry merchandise uses thief bundle and proper item models")

	var hero: MarketActor=ActorScript.new()
	hero.setup("player",Color("#5c8e8e"),"dog")
	actors.add_child(hero)
	hero.set_visible_cargo({"tomato":1,"berry":2,"apple":0})
	hero.set_carry(3)
	check(hero.goods_root.get_child_count()==3,"A single tomato and two berries are shown as three goods, not five")
	var rendered:Dictionary={}
	for item in hero.goods_root.get_children():
		var ref:String=item.scene_file_path
		rendered[ref]=int(rendered.get(ref,0))+1
	check(int(rendered.get("res://assets/models/produce_tomato.glb",0))==1 and int(rendered.get("res://assets/models/produce_berry.glb",0))==2,"Mixed visible fruit exactly reflects each real product")
	var original_mesh:int=hero.goods_root.get_child(0).get_instance_id()
	hero.set_visible_cargo({"berry":2,"tomato":1})
	check(hero.goods_root.get_child(0).get_instance_id()==original_mesh,"Equal stock passed in different dictionary order reuses existing GLB nodes")
	hero.set_visible_cargo({"milk":1,"bread":1,"packaging":1,"kits":1,"preserves":1})
	check(hero.goods_root.get_child_count()==5,"Five region supplies render five distinct visible goods")
	rendered.clear()
	for item in hero.goods_root.get_children():rendered[item.scene_file_path]=true
	check(rendered.has("res://assets/models/goods_parcel.glb") and rendered.has("res://assets/models/goods_crate.glb") and rendered.has("res://assets/models/goods_provisions.glb"),"Industrial goods use actual imported fallback meshes, never missing GLBs")
	hero.set_visible_cargo({})
	hero.set_carry(0)
	check(hero.goods_root.get_child_count()==0 and not hero.goods_root.visible,"Completely emptied backpack contains no residual sprites or props")
	actors.queue_free()
	await process_frame

	game=load("res://Main.tscn").instantiate()
	game.save_path=save_path
	root.add_child(game)
	game.set_process(false)
	game.world.set_process(false)
	await process_frame
	var cash:int=game.coins
	var stock:Dictionary=game.counter.duplicate()
	game.stash["tomato"]=2
	game.route.bag["milk"]=1
	game.route.bag["kits"]=2
	game._sync_visible_cargo()
	check(game.player.carrying==5 and game.player.goods_root.get_child_count()==5,"Player basket combines mainland and ferry stock without inventing items")
	check(game.coins==cash and game.counter==stock,"Changing cargo art never alters spendable money or sales")
	game._save_progress()
	game.queue_free()
	await process_frame
	await process_frame
	game=load("res://Main.tscn").instantiate()
	game.save_path=save_path
	root.add_child(game)
	game.set_process(false)
	game.world.set_process(false)
	await process_frame
	check(game.player.carrying==5 and game.player.goods_root.get_child_count()==5,"Loaded v8 save restores the exact combined visible cargo mix")
	check(game.route.bag["kits"]==2 and game.stash["tomato"]==2 and game.coins==cash,"Saving visible goods has no effect on original real inventory")
	game.route.bag["kits"]=0
	game.route.bag["milk"]=0
	game.stash["tomato"]=0
	game.route._update_cargo()
	check(game.player.goods_root.get_child_count()==0 and game.player.carrying==0,"Unloading all regions removes old 3D cargo automatically")
	game.queue_free()
	await process_frame
	await process_frame
	clean()
	print("RESULT: %d checks, %d failures (never executed on this branch)" % [checked,failed])
	quit(1 if failed>0 else 0)
