extends Node3D
class_name WivoriFactoryFacade

# A lightweight authored facade kit. Each industrial building must be
# visually distinguishable even at mobile zoom. It augments the existing
# imported structure and deliberately owns no inventory or collision.
#
# Animated props run only while their scene is active; the player and
# factory recipe scripts remain the sole owners of gameplay.
var world: MarketWorld
var kind: String=""
var clock:=0.0
var moving_parts: Array[Dictionary]=[]
var illumination: Array[MeshInstance3D]=[]
var window_batches: Array[MultiMeshInstance3D]=[]

const INK=Color("#344c58")
const METAL=Color("#748994")
const IVORY=Color("#f6ead2")
const BRASS=Color("#d8ac62")
const COPPER=Color("#b57755")
const SEA=Color("#6eaaa6")
const GLASS=Color("#b7dbe1")

func configure(source: MarketWorld, id: String) -> void:
	world=source
	kind=id

func _ready() -> void:
	if world==null:return
	name="Arquitectura singular · "+kind
	match kind:
		"dockworks":_crane_and_harbor()
		"packaging_plant":_stamping_and_sawtooth()
		"preserves_line":_preserves_and_steam()
		"shipping_hub":_freight_and_loading()
		"trade_center":_trade_hall_and_clock()
	_add_window_batch()
	set_process(not moving_parts.is_empty() or not illumination.is_empty())

func _part(parent: Node3D, shape: String, pos: Vector3, dim: Vector3, color_: Color, title: String) -> MeshInstance3D:
	var part:=world.shape(parent,shape,pos,dim,color_,title)
	if dim.length_squared()<1.0:part.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return part

func _new_pivot(title: String, pos: Vector3) -> Node3D:
	var pivot:=Node3D.new()
	pivot.name=title
	pivot.position=pos
	add_child(pivot)
	return pivot

func _add_window_batch() -> void:
	# Six tiny architectural windows use a single MultiMesh rather than
	# six independent MeshInstances. Windows face the camera-facing facade.
	var unit:=BoxMesh.new()
	unit.size=Vector3(.54,.62,.08)
	var mat:=StandardMaterial3D.new()
	mat.albedo_color=GLASS
	mat.metallic=.16
	mat.roughness=.27
	mat.emission_enabled=true
	mat.emission=Color("#285769")
	mat.emission_energy_multiplier=.16
	unit.material=mat
	var batch:=MultiMesh.new()
	batch.transform_format=MultiMesh.TRANSFORM_3D
	batch.mesh=unit
	batch.instance_count=6
	for i in range(6):
		var x:float=-1.6+float(i%3)*1.6
		# The playable approach and camera are on positive Z; windows must
		# face that side rather than being hidden behind the imported GLB.
		var base_y:float=3.20 if kind in ["packaging_plant","shipping_hub"] else 1.62
		var step_y:float=.56 if kind in ["packaging_plant","shipping_hub"] else 1.22
		var y:float=base_y+float(i/3)*step_y
		batch.set_instance_transform(i,Transform3D(Basis.IDENTITY,Vector3(x,y,1.75)))
	var visible_windows:=MultiMeshInstance3D.new()
	visible_windows.name="Seis ventanas acristaladas · un draw call"
	visible_windows.multimesh=batch
	visible_windows.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(visible_windows)
	window_batches.append(visible_windows)

func _crane_and_harbor() -> void:
	# Dockworks: a broad ochre overhead gantry with a sliding hoist.
	var frame:=Color("#c99053")
	for x in [-2.43,2.43]:
		_part(self,"box",Vector3(x,2.40,-.10),Vector3(.27,4.64,.28),frame,"Pilar de grúa pórtico")
		for h in [1.05,2.95]:
			var brace:=_part(self,"box",Vector3(x*.91,h,-.10),Vector3(.12,1.42,.18),INK,"Riostra oblicua")
			brace.rotation.z=.33 if x>0 else -.33
	_part(self,"box",Vector3(0,4.72,-.10),Vector3(5.22,.34,.46),frame,"Viga de grúa")
	_part(self,"box",Vector3(0,4.45,-.10),Vector3(4.80,.14,.48),BRASS,"Rail de rodadura")
	var trolley:=_new_pivot("Carro suspendido que se desplaza",Vector3(0,4.24,-.10))
	_part(trolley,"box",Vector3.ZERO,Vector3(.75,.48,.55),INK,"Carro del polipasto")
	_part(trolley,"cylinder",Vector3(0,-.78,0),Vector3(.09,1.24,.09),METAL,"Cable de elevación")
	var hook:=_part(trolley,"cylinder",Vector3(0,-1.46,0),Vector3(.20,.28,.20),BRASS,"Gancho")
	hook.rotation.z=.18
	moving_parts.append({"node":trolley,"type":"crane","at":trolley.position})
	_part(self,"box",Vector3(0,.45,1.05),Vector3(3.2,.42,.48),INK,"Tope de carga")
	for i in range(5):
		_part(self,"box",Vector3(-1.2+float(i)*.6,.84,1.31),Vector3(.27,.08,.12),BRASS,"Marca de seguridad")

func _stamping_and_sawtooth() -> void:
	# Packaging: recognisable sawtooth roof, a stamping ram and yellow
	# bundle chute. Unlike dockworks it has no overhead crane or chimney.
	for i in range(3):
		var x:float=-1.70+float(i)*1.65
		var panel:=_part(self,"box",Vector3(x,3.66,-.28),Vector3(1.52,.18,3.35),Color("#718fa0"),"Cubierta diente de sierra")
		panel.rotation.z=-.24
		_part(self,"box",Vector3(x-.55,3.43,-1.90),Vector3(.15,.78,.14),IVORY,"Celosía de techo")
	_part(self,"box",Vector3(-.25,.50,1.10),Vector3(3.25,.41,.60),INK,"Mesa de impresión")
	_part(self,"box",Vector3(-.25,.83,1.12),Vector3(3.10,.08,.52),BRASS,"Banda de empaque")
	for i in range(4):
		_part(self,"box",Vector3(-1.4+float(i)*.76,1.13,1.10),Vector3(.47,.34,.34),Color("#d4b58b"),"Paquete clasificado")
	for i in range(3):
		_part(self,"box",Vector3(-1.70+float(i)*1.7,3.23,-1.79),Vector3(.14,.54,.13),BRASS,"Remache visible del tejado")
	var ram:=_new_pivot("Prensa vertical activa",Vector3(.10,2.25,1.0))
	_part(ram,"box",Vector3.ZERO,Vector3(.78,.64,.72),COPPER,"Cabezal de prensa")
	_part(ram,"box",Vector3(0,.54,0),Vector3(.22,1.10,.28),METAL,"Émbolo")
	moving_parts.append({"node":ram,"type":"press","at":ram.position})

func _preserves_and_steam() -> void:
	# Preserves: hygienic cylindrical tanks, copper bridges and low
	# opacity vapour plumes. The steam is ambient, never a smoke hazard.
	# One shared transparent resource avoids the former opaque white blobs.
	var steam_material:=StandardMaterial3D.new()
	steam_material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	steam_material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	steam_material.albedo_color=Color(.88,.97,.94,.21)
	steam_material.roughness=1.0
	for x in [-1.54,1.54]:
		_part(self,"cylinder",Vector3(x,1.36,.20),Vector3(1.22,2.65,1.22),Color("#b3cac7"),"Tanque de conservas")
		_part(self,"cylinder",Vector3(x,2.76,.20),Vector3(1.30,.16,1.30),INK,"Tapa del tanque")
		_part(self,"cylinder",Vector3(x,3.67,.20),Vector3(.34,1.70,.34),METAL,"Conducto de ventilación")
		_part(self,"cylinder",Vector3(x,4.56,.20),Vector3(.58,.17,.58),COPPER,"Remate de chimenea")
		var plume:=_new_pivot("Vapor suave",Vector3(x,4.95,.20))
		for i in range(3):
			var vapor:=_part(plume,"sphere",Vector3(.15*sin(float(i)*2.1),float(i)*.28,.0),Vector3(.34+float(i)*.09,.28+float(i)*.06,.34+float(i)*.09),Color("#cfebe5"),"Nube de vapor decorativa")
			vapor.material_override=steam_material
			vapor.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		moving_parts.append({"node":plume,"type":"steam","at":plume.position,"phase":x})
	_part(self,"box",Vector3(0,2.46,.20),Vector3(2.50,.19,.20),COPPER,"Puente de canalizaciones")
	for i in range(4):
		_part(self,"cylinder",Vector3(-1.15+float(i)*.77,.69,1.47),Vector3(.40,.56,.40),BRASS,"Conserva sellada")

func _freight_and_loading() -> void:
	# Shipping hub: stacked rolling shutters, dock numbering and a
	# moving pallet-lift track. Cargo display elsewhere remains tied
	# to REAL inventory and is not duplicated by this decorative facade.
	for x in [-1.55,1.55]:
		_part(self,"box",Vector3(x,1.72,1.80),Vector3(1.72,2.75,.22),INK,"Portón de nave de carga")
		for i in range(5):
			_part(self,"box",Vector3(x,.66+float(i)*.45,1.91),Vector3(1.60,.065,.07),METAL,"Lama de portón enrollable")
		_part(self,"box",Vector3(x,3.31,1.88),Vector3(1.80,.22,.37),BRASS,"Dintel de muelle")
	_part(self,"box",Vector3(0,.45,1.10),Vector3(4.00,.28,.48),Color("#7f9c9c"),"Transportador de mercancías")
	var pallet:=_new_pivot("Palé de almacén en traslado",Vector3(-1.36,.78,1.10))
	_part(pallet,"box",Vector3.ZERO,Vector3(.79,.18,.48),COPPER,"Tarima de madera")
	_part(pallet,"box",Vector3(0,.33,0),Vector3(.56,.47,.42),IVORY,"Paquete transportado")
	moving_parts.append({"node":pallet,"type":"pallet","at":pallet.position})

func _trade_hall_and_clock() -> void:
	# Trade centre: a civic building instead of a factory. A tall light
	# clock and two symmetrical colonnades define an identifiable skyline.
	for x in [-1.98,1.98]:
		_part(self,"cylinder",Vector3(x,1.40,1.54),Vector3(.34,2.70,.34),IVORY,"Columna comercial")
		_part(self,"cylinder",Vector3(x,2.79,1.54),Vector3(.55,.20,.55),BRASS,"Capitel")
	_part(self,"box",Vector3(0,3.04,1.54),Vector3(4.7,.42,1.16),INK,"Cornisa central")
	var clock_frame:=_part(self,"cylinder",Vector3(0,3.95,1.80),Vector3(1.40,.20,1.40),BRASS,"Carátula del reloj")
	clock_frame.rotation.x=PI/2
	var clock_face:=_part(self,"cylinder",Vector3(0,3.95,1.95),Vector3(1.20,.21,1.20),IVORY,"Esfera del reloj")
	clock_face.rotation.x=PI/2
	var hand:=_new_pivot("Aguja de la plaza",Vector3(0,3.95,2.08))
	_part(hand,"box",Vector3(0,.25,0),Vector3(.070,.54,.09),INK,"Aguja del reloj")
	moving_parts.append({"node":hand,"type":"clock","at":hand.position})
	for x in [-1.4,1.4]:
		_part(self,"box",Vector3(x,.53,1.63),Vector3(.26,.72,.26),SEA,"Baliza del comercio")

func _process(delta: float) -> void:
	clock+=delta
	for entry in moving_parts:
		var node: Node3D=entry["node"]
		if not is_instance_valid(node):continue
		var original:Vector3=entry["at"]
		match entry["type"]:
			"crane":node.position=original+Vector3(1.35*sin(clock*.37),.09*sin(clock*1.8),0)
			"press":node.position=original+Vector3(0,-.28*absf(sin(clock*1.35)),0)
			"steam":
				var phase:float=entry["phase"]
				node.position=original+Vector3(.12*sin(clock*.6+phase),fposmod(clock*.22+phase*.08,.48),0)
				node.scale=Vector3.ONE*(.9+.13*sin(clock*.8+phase))
			"pallet":node.position=original+Vector3(2.7*(.5+.5*sin(clock*.42)),0,0)
			"clock":node.rotation.z=-clock*.12
