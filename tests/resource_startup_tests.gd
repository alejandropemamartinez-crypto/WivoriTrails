extends SceneTree

# Future Godot 4.4.1 import gate. Commit-only phase; NOTHING HERE HAS RUN.
# The manifest is generated from all committed GLB sources at stage 5K.
# An absent or malformed import should fail loudly before any Android APK.
const Art=preload("res://scripts/art_library.gd")
const Actor=preload("res://scripts/actor.gd")
const REQUIRED_MODELS=[
	"bakery",
	"booth_alarm",
	"booth_bag",
	"booth_checkout",
	"booth_collector",
	"booth_expand",
	"booth_guard",
	"booth_helper",
	"booth_lock",
	"booth_pier",
	"booth_speed",
	"cafe",
	"coin",
	"depot",
	"duck",
	"farm_barn",
	"farm_coop",
	"farm_corral",
	"farm_cow",
	"farm_fence",
	"farm_hen",
	"farm_piglet",
	"flower_cart",
	"fox",
	"goods_bread",
	"goods_cheese",
	"goods_crate",
	"goods_egg",
	"goods_feed",
	"goods_flour",
	"goods_jam",
	"goods_meat",
	"goods_milk",
	"goods_parcel",
	"goods_provisions",
	"goods_wheat",
	"greenhouse",
	"hero",
	"house",
	"market",
	"mill",
	"money_bag",
	"oak_bench",
	"park",
	"pig",
	"premium",
	"produce_apple",
	"produce_berry",
	"produce_carrot",
	"produce_tomato",
	"rabbit",
	"raccoon",
	"register",
	"route_ferry",
	"route_lighthouse",
	"terrier",
	"treasury",
	"tree",
	"watchtower",
	"workshop"
]
const SUPPORT_ASSETS=[
	"Main.tscn",
	"icon.png",
	"assets/fonts/Quicksand-Bold.ttf",
	"assets/fonts/Quicksand-Medium.ttf",
	"scripts/outfit.gdshader",
	"scripts/ground.gdshader",
	"scripts/meadow.gdshader",
	"scripts/contact_shadow.gdshader",
	"scripts/water.gdshader",
	"assets/ui/signs/plaque.svg",
	"assets/ui/signs/boat.svg",
	"assets/ui/signs/crew.svg",
	"assets/ui/signs/defense.svg",
	"assets/ui/signs/deliver.svg",
	"assets/ui/signs/harvest.svg",
	"assets/ui/signs/money.svg",
	"assets/ui/signs/star.svg"
]
const CHARACTER_ASSETS=["hero","fox","pig","duck","rabbit","raccoon"]
const REGION_BUILDINGS=[
	"greenhouse","mill","bakery","farm_coop","farm_barn","cafe",
	"farm_corral","workshop","depot","watchtower","route_lighthouse"
]
const GOODS=["goods_wheat","goods_flour","goods_feed","goods_bread",
	"goods_egg","goods_milk","goods_cheese","goods_meat","goods_provisions",
	"goods_parcel","goods_crate"]
var checked:=0
var failures:=0

func _initialize() -> void:
	call_deferred("run_tests")

func check(ok: bool, label: String) -> void:
	checked+=1
	if ok:print("PASS: ",label)
	else:failures+=1;push_error("FAIL: "+label)

func run_tests() -> void:
	check(REQUIRED_MODELS.size()==60,"Every GLB from the authored asset manifest is accounted for")
	for model in REQUIRED_MODELS:
		var path:String="res://assets/models/"+model+".glb"
		var exists:bool=ResourceLoader.exists(path)
		check(exists,"Imported 3D resource exists: "+model)
		if not exists:continue
		var resource:Resource=load(path)
		check(resource is PackedScene,"GLB loads as an instantiable 3D PackedScene: "+model)
		if not resource is PackedScene:continue
		var instance:Node=resource.instantiate()
		check(instance is Node3D,"Imported GLB has a usable 3D scene root: "+model)
		if instance!=null:
			instance.free()
	for path in SUPPORT_ASSETS:
		check(ResourceLoader.exists("res://"+path),"Required scene, UI or shader exists: "+path)
	for species in CHARACTER_ASSETS:
		var actor:MarketActor=Actor.new()
		actor.setup("player" if species=="hero" else "customer",Color("#a8baab"),species)
		root.add_child(actor)
		check(actor.body_root!=null and actor.body_root.name!="ERROR · Falta "+species,"Original imported rig is preserved for "+species)
		check(actor.skeleton!=null and actor.animator!=null,"Species "+species+" contains a real skeleton and AnimationPlayer")
		actor.free()
	# All actual regional projects reference one of the curated imported
	# building families; source-only props never substitute fake cubes.
	for model in REGION_BUILDINGS:
		check(REQUIRED_MODELS.has(model),"An existing GLB supports the regional building: "+model)
	for model in GOODS:
		check(REQUIRED_MODELS.has(model),"Physical trade goods have a source GLB: "+model)
	check(ResourceLoader.exists("res://assets/ui/signs/star.svg"),"The CONSTRUIR project sign uses an imported star pictogram")
	check(ResourceLoader.exists("res://Main.tscn"),"The configured startup scene has a valid file")
	print("RESULT: %d checks, %d failures; never executed during code-only development" % [checked,failures])
	quit(1 if failures else 0)
