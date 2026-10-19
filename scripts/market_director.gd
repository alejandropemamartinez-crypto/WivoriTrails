extends RefCounted

# One source of truth for the lesson, its destination and the next investment.
# Alerts stay actionable; affordability is announced once per upgrade tier.
var g
var announced := {}
var offer_cooldown := 0.0
var announcement_count := 0
var pinned_kind := ""
var pinned_price := 0

func _init(game: Node3D) -> void:
	g=game

func recommended() -> String:
	# Keep an affordable destination steady while stock and queue length change.
	if not pinned_kind.is_empty():
		var pinned: Dictionary=g._upgrade(pinned_kind)
		if not pinned["done"] and pinned["price"]==pinned_price and g.coins>=pinned_price:return pinned_kind
		pinned_kind=""
	var kind := _next_investment()
	if not kind.is_empty():
		var upgrade: Dictionary=g._upgrade(kind)
		if g.coins>=upgrade["price"]:pinned_kind=kind; pinned_price=upgrade["price"]
	return kind

func _next_investment() -> String:
	if g.worker_count<mini(2,g.run.level):return "helper"
	if g.run.level>=3 and g.run.lock_level==0:return "lock"
	if g.run.level>=4 and not g.orchard_owned:return "expand"
	if g.run.level>=5 and not g.pier_owned:return "pier"
	if g.run.level>=4 and g.run.guard_level==0:return "guard"
	if g.run.level>=3 and g.run.alarm_level==0:return "alarm"
	if g.run.level>=3 and not g.cash.collector_hired and g.earned>=500:return "collector"
	if g.run.level<=2:return "checkout" if g.run.level==2 and g.checkout_level==0 else ""
	var choice := ""
	var cheapest := 2000000001
	for kind in ["helper","checkout","bag","speed","lock","alarm","guard"]:
		var upgrade: Dictionary=g._upgrade(kind)
		if not upgrade["done"] and not upgrade["locked"] and upgrade["price"]<cheapest:
			choice=kind; cheapest=upgrade["price"]
	return choice

func tick(delta: float) -> void:
	offer_cooldown=maxf(0,offer_cooldown-delta)
	var kind := recommended()
	if kind.is_empty():return
	var upgrade: Dictionary=g._upgrade(kind)
	var token := "%s:%d" % [kind,upgrade["price"]]
	if g.coins<upgrade["price"] or announced.has(token) or offer_cooldown>0:return
	# Do not replace a delivery, level-up or purchase celebration mid-sentence.
	if g.event_fade>0:return
	announced[token]=true
	announcement_count+=1
	offer_cooldown=7.0
	g._notice("YA PODÉS: %s\nSeguí las flechas hasta la mejora." % upgrade["name"],3.3)
	# Purchasable upgrades are everyday events, not story milestones:
	# show the existing short HUD notice once, never an interrupting modal.

func alert() -> Dictionary:
	var security: Dictionary=g.run.alert()
	if not security.is_empty():return security
	var waiting: int=g._waiting_count()
	if waiting==0:return {}
	if g._total_stock()==0:
		var loaded: bool=g._total_bag()>0
		return {"id":"empty","title":"Puesto vacío · %d esperando" % waiting,
			"detail":"Entregá tu mochila para que vuelvan las ventas." if loaded else "Cosechá productos y acercate al puesto para entregarlos.",
			"button":"SEÑALAR","target":Vector3(4,0,2.5) if loaded else g._harvest_target(),"color":Color("#c46c39")}
	if waiting>=4:
		var upgrade: Dictionary=g._upgrade("checkout")
		return {"id":"queue","title":"%s · %d/6 clientes" % ["Fila llena" if waiting>=6 else "Se está formando fila",waiting],
			"detail":"Caja rápida atiende más seguido. Cuesta %d monedas." % upgrade["price"] if not upgrade["done"] else "La caja está al máximo. Mantené el puesto abastecido.",
			"button":"SEÑALAR",
			"target":upgrade["target"] if not upgrade["done"] else Vector3(8.3,0,.6),"color":Color("#b95a52")}
	return {}

func objective() -> Dictionary:
	var level_tag: String="NIVEL %02d · %s" % [g.run.level,g.run.title()]
	var data: Dictionary={"tag":level_tag,"title":"Seguí las flechas con el joystick","detail":g.run.summary(),"goal":1.0,"value":g.run.progress(),"button":"SEÑALAR"}
	if g.run.complete():
		data.merge({"title":"¡Nivel superado!","detail":"Premio: +%d monedas. Se abre una nueva meta." % g.run.reward(),"button":"CONTINUAR","upgrade":"level","ready":true},true)
		return data
	var security: Dictionary=g.run.alert()
	if security.get("id","")=="raid":
		data["title"]=security["title"]; data["target"]=security["target"]
		return data
	var bag: int=g._total_bag()
	var next_kind:=recommended()
	var saving_for_upgrade: bool=not next_kind.is_empty() and g.coins<g._upgrade(next_kind)["price"]
	if g.cash.total_pending()>0 and (g.worker_count==0 or not g.cash.collector_hired and g.cash.total_pending()>=75 or saving_for_upgrade):
		var box: int=0 if g.cash.pending[0]>=g.cash.pending[1] else 1
		data.merge({"title":"Recogé lo que ganaste","detail":"Las ventas quedan en la caja. Acercate para cobrarlas.","target":g.cash.REGISTERS[box]},true)
		return data
	if g.run.level>=4 and g.run.contract_done<g.run.contract_goal() and g.stash[g.run.contract_kind()]>0:
		if g.run.level>=7:return g.work.objective()
		data["title"]="Entregá el pedido premium ×2"; data["target"]=g.run.CART
		return data
	if g.run.level>=7:return g.work.objective()
	if bag>=g.max_capacity or g.worker_count==0 and bag>=6:
		data["title"]="Llevá tu cosecha al puesto"; data["target"]=Vector3(4,0,2.5)
		return data
	var kind:=recommended()
	if not kind.is_empty():
		var upgrade: Dictionary=g._upgrade(kind)
		if g.coins>=upgrade["price"]:
			var nearby: bool=g.player.position.distance_to(upgrade["target"])<=g.PAD_RADIUS
			data.merge({"title":"%s · %d" % [upgrade["name"],upgrade["price"]],"detail":g.run.summary(),"target":upgrade["target"],"upgrade":kind,"ready":true,"button":"COMPRAR" if nearby else "SEÑALAR"},true)
			return data
	if g.run.level>=4 and g.run.contract_done<g.run.contract_goal():
		if not g.orchard_owned and g.run.contract_kind()=="apple":data["title"]="Abrí el huerto para tu pedido"; data["target"]=g.UPGRADE_POS["expand"]
		else:data["title"]="Pedido: recolectá "+g.CROP_NAMES[g.run.contract_kind()]; data["target"]=g._harvest_kind(g.run.contract_kind())
		return data
	data["title"]="Llevá tu cosecha al puesto" if bag>0 and g.delivered>0 else "Cosechá con el joystick"
	data["target"]=Vector3(4,0,2.5) if bag>0 and g.delivered>0 else g._harvest_target()
	return data
