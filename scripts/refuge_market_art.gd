extends "res://scripts/refuge_art.gd"
class_name WivoriWinterMarketArt

const Market=preload("res://scripts/refuge_market.gd")

static func piece(parent: Node3D,id: String,at: Vector3=Vector3.ZERO) -> WivoriWinterMarketArt:
	var node:=WivoriWinterMarketArt.new();node.building=id;node.position=at;parent.add_child(node);return node

func _build_winter() -> void:
	match building:
		"wood_shop":_trade_stall(Color("#548d83"),false)
		"meat_shop":_trade_stall(Color("#ba735b"),true)
		"market_depot":_depot()
		"sentinel_tower":_market_guard_tower()
		"tower_site":
			_box(Vector3(0,.05,0),Vector3(1.9,.10,1.9),Color("#a6bdc2"),0,.14)
			for side in [-1.0,1.0]:_box(Vector3(side*.8,.5,-.7),Vector3(.12,1.0,.12),LOG)
			_box(Vector3(0,.88,-.7),Vector3(1.8,.64,.12),SLATE)
		"crossbow":
			_box(Vector3(0,.16,.26),Vector3(.13,.22,.75),TIMBER)
			_box(Vector3(0,.29,.34),Vector3(.13,.10,.86),DARK,1)
			_box(Vector3(0,.24,.55),Vector3(.85,.08,.14),COPPER,1)
			for side in [-1.0,1.0]:_box(Vector3(side*.34,.25,.47),Vector3(.34,.06,.07),DARK,1,.02,Basis(Vector3.UP,side*.55))
		"bolt":
			_cylinder(Vector3.ZERO,.035,.7,COPPER,1,6,Basis(Vector3.RIGHT,PI*.5))
			_box(Vector3(0,0,.34),Vector3(.10,.10,.18),LIT,2)
		"cash_register":
			_box(Vector3(0,.70,0),Vector3(.85,.13,.62),LOG)
			for x in [-.33,.33]:_box(Vector3(x,.33,0),Vector3(.10,.66,.43),DARK)
			_box(Vector3(0,.96,0),Vector3(.47,.40,.45),COPPER,1)
			_box(Vector3(0,1.19,0),Vector3(.35,.16,.32),DARK,1)
		"axe":
			_cylinder(Vector3(0,.36,0),.045,.90,TIMBER,0,8)
			_box(Vector3(.12,.71,0),Vector3(.46,.32,.14),DARK,1,.04)
			_box(Vector3(.14,.72,.075),Vector3(.37,.23,.035),Color("#b9d3db"),1,.02)
			_box(Vector3(.30,.70,0),Vector3(.065,.33,.13),SNOW,1,.02)
			for y in [.02,.11,.20]:_box(Vector3(0,y,0),Vector3(.10,.05,.11),COPPER)
		"scythe":
			_cylinder(Vector3(0,.42,0),.045,1.12,TIMBER,0,8)
			_box(Vector3(.12,.22,0),Vector3(.28,.08,.09),LOG)
			# A continuous curved blade, rather than a floating facial/weapon decal.
			for index in range(10):
				var a: float=float(index)/10.0*1.75;var b: float=float(index+1)/10.0*1.75
				var p:=Vector3(sin(a)*.62,.80+cos(a)*.25,0);var q:=Vector3(sin(b)*.62,.80+cos(b)*.25,0)
				var width: float=.14*(1.0-float(index)/12.0)
				var basis_:=Basis(Vector3.BACK,atan2(q.y-p.y,q.x-p.x))
				_box((p+q)*.5,Vector3(p.distance_to(q)+.035,width+.045,.075),DARK,1,.01,basis_)
				_box((p+q)*.5+Vector3(0,0,.045),Vector3(p.distance_to(q)+.02,width,.025),Color("#d2e4e9"),1,.01,basis_)
		"cargo_meat":
			_box(Vector3(0,.18,0),Vector3(.78,.35,.60),Color("#c29176"),0,.12)
			_box(Vector3(0,.37,0),Vector3(.80,.06,.62),Color("#f0d6b4"),0,.02)
			_box(Vector3(0,.24,0),Vector3(.10,.45,.63),Color("#7f9c91"),0,.015)
			_box(Vector3(0,.24,0),Vector3(.81,.45,.09),Color("#7f9c91"),0,.015)
		"stump":
			_cylinder(Vector3(0,.18,0),.38,.36,TIMBER,0,10);_cylinder(Vector3(0,.37,0),.34,.025,Color("#d0ae7a"),0,10)
		"locomotive":_engine()
		"wagon":_wagon()
		"rail0","rail1","rail2","ghost_rail0","ghost_rail1","ghost_rail2":
			var section: int=int(building.right(1));var built_: bool=not building.begins_with("ghost")
			var points: Array=Market.RAIL_POINTS
			if section==0:_track(points[0],points[1],built_)
			elif section==1:_track(points[1],points[2],built_);_track(points[2],points[3],built_)
			else:_track(points[3],points[4],built_)
		_ :super._build_winter()

func _market_guard_tower() -> void:
	for x in [-.72,.72]:
		for z in [-.72,.72]:_box(Vector3(x,1.3,z),Vector3(.20,2.6,.20),TIMBER)
	_box(Vector3(0,2.45,0),Vector3(1.95,.25,1.95),LOG)
	for x in [-.86,.86]:
		_box(Vector3(x,3.04,0),Vector3(.12,1.1,1.85),SLATE)
		_box(Vector3(x,3.96,-.75),Vector3(.12,2.5,.12),LOG)
	_box(Vector3(0,3.03,-.88),Vector3(1.85,1.0,.12),SLATE)
	_box(Vector3(0,2.85,.90),Vector3(1.85,.30,.12),COPPER,1)
	_box(Vector3(0,4.86,-.20),Vector3(2.35,.20,2.4),SNOW,0,.12)
	for i in range(7):_box(Vector3(-1.12,.2+float(i)*.34,.93-float(i)*.15),Vector3(.60,.14,.30),LOG)
	_cylinder(Vector3(0,3.1,.98),.26,.10,COPPER,1,12,Basis(Vector3.RIGHT,PI*.5))

func _trade_stall(paint: Color,meat: bool) -> void:
	_box(Vector3(0,.12,0),Vector3(4.7,.24,2.7),Color("#708d98"),0,.13)
	_box(Vector3(0,.85,0),Vector3(4.1,1.25,1.6),paint,0,.12)
	for x in [-1.9,1.9]:_box(Vector3(x,1.70,-.65),Vector3(.16,3.15,.17),LOG)
	_box(Vector3(0,1.54,.1),Vector3(4.4,.20,2.1),LOG,0,.05)
	_box(Vector3(0,2.87,0),Vector3(4.75,.17,2.8),SNOW,0,.05)
	for index in range(8):
		_box(Vector3(-2.08+float(index)*.59,2.64,1.22),Vector3(.57,.40,.15),paint if index%2==0 else Color("#f0dbb5"),0,.045)
	_box(Vector3(0,3.15,-.4),Vector3(3.5,.71,.18),DARK,0,.08)
	_box(Vector3(0,3.15,-.28),Vector3(3.27,.53,.06),paint,0,.04)
	for index in range(3):
		var at:=Vector3(-1.28+float(index)*1.18,1.70,.3)
		if meat:
			_box(at,Vector3(.9,.35,.65),Color("#c39278"),0,.1)
			_box(at+Vector3(0,.19,0),Vector3(.94,.07,.69),Color("#edd8b7"))
			_box(at,Vector3(.09,.43,.68),Color("#779a8b"))
		else:_cylinder(at,.21,.95,LOG,0,10,Basis(Vector3.RIGHT,PI*.5))
	_box(Vector3(1.3,1.81,.6),Vector3(.55,.45,.45),COPPER,1,.05)
	_box(Vector3(1.3,2.08,.6),Vector3(.45,.16,.37),DARK,1)

func _depot() -> void:
	_box(Vector3(0,.14,-1.05),Vector3(4.2,.28,3.0),TIMBER)
	for x in [-1.8,1.8]:_box(Vector3(x,1.4,-1.1),Vector3(.18,2.8,.18),LOG)
	_box(Vector3(0,2.76,-1.1),Vector3(4.4,.18,3.3),SNOW)
	_box(Vector3(0,2.45,.5),Vector3(3.6,.62,.16),Color("#537b87"))
	for x in [-.95,.95]:
		_box(Vector3(x,.60,-1.1),Vector3(1.55,.95,1.3),LOG)
		for y in [.35,.85]:_box(Vector3(x,y,-.42),Vector3(1.6,.08,.10),TIMBER)

func _track(a: Vector3,b: Vector3,built_: bool) -> void:
	var difference: Vector3=b-a;var distance: float=difference.length();var basis_:=Basis(Vector3.UP,-atan2(difference.z,difference.x))
	if built_:
		for side in [-.48,.48]:_box((a+b)*.5+Vector3(0,.13,0)+basis_*Vector3(0,0,side),Vector3(distance+.1,.14,.12),Color("#748f9b"),1,.02,basis_)
	for index in range(ceili(distance/.85)):
		if not built_ and index%3!=0:continue
		var at: Vector3=a+difference.normalized()*(float(index)*.85+.25)
		_box(at+Vector3(0,.05,0),Vector3(.20,.10,1.45 if built_ else .75),TIMBER if built_ else Color("#a2ad99"),0,.02,basis_)

func _wheels(length: float) -> void:
	for x in [-.68,.68]:
		for z in [-length*.32,length*.32]:
			_cylinder(Vector3(x,.34,z),.31,.15,DARK,1,12,Basis(Vector3.BACK,PI*.5))
			_cylinder(Vector3(x*1.07,.34,z),.14,.16,COPPER,1,10,Basis(Vector3.BACK,PI*.5))

func _engine() -> void:
	_box(Vector3(0,.51,0),Vector3(1.3,.25,2.5),DARK,1)
	_cylinder(Vector3(0,.96,.15),.54,1.65,Color("#4b8983"),1,16,Basis(Vector3.RIGHT,PI*.5))
	_cylinder(Vector3(0,1.02,1.02),.46,.13,COPPER,1,16,Basis(Vector3.RIGHT,PI*.5))
	_cylinder(Vector3(0,1.02,1.12),.22,.10,LIT,2,12,Basis(Vector3.RIGHT,PI*.5))
	_box(Vector3(0,1.17,-.87),Vector3(1.38,1.30,.90),Color("#4d737d"),1)
	_box(Vector3(0,1.91,-.87),Vector3(1.65,.18,1.15),SNOW)
	_box(Vector3(0,1.43,-.37),Vector3(.85,.50,.08),Color("#e7c58e"),2)
	_cylinder(Vector3(0,1.68,.60),.17,.76,DARK,1,10);_cylinder(Vector3(0,2.07,.60),.28,.18,COPPER,1,10)
	_box(Vector3(0,.43,1.45),Vector3(1.6,.42,.4),COPPER,1)
	_wheels(2.0)

func _wagon() -> void:
	_box(Vector3(0,.51,0),Vector3(1.40,.22,2.0),DARK,1)
	_box(Vector3(0,.78,0),Vector3(1.50,.40,2.1),LOG)
	for x in [-.72,.72]:_box(Vector3(x,1.0,0),Vector3(.09,.54,2.05),Color("#a87b50"))
	for z in [-1.0,1.0]:_box(Vector3(0,1.0,z),Vector3(1.50,.54,.10),TIMBER)
	_wheels(1.8)
