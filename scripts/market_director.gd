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
	if g.worker_count==0:return "helper"
	if g.checkout_level==0 and g._waiting_count()>=4 and g._total_stock()>0:return "checkout"
	if g.worker_count<2:return "helper"
	if g.checkout_level==0:return "checkout"
	if not g.orchard_owned:return "expand"
	if not g.pier_owned:return "pier"
	var choice := ""
	var cheapest := 2000000001
	for kind in ["helper","checkout","bag","speed"]:
		var upgrade: Dictionary=g._upgrade(kind)
		if not upgrade["done"] and upgrade["price"]<cheapest:
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

func alert() -> Dictionary:
	var waiting: int=g._waiting_count()
	if waiting==0:return {}
	if g._total_stock()==0:
		var loaded: bool=g._total_bag()>0
		return {"id":"empty","title":"Puesto vacío · %d esperando" % waiting,
			"detail":"Entregá tu mochila para que vuelvan las ventas." if loaded else "Recolectá productos y abastecé el círculo dorado.",
			"button":"REPONER","target":Vector3(4,0,2.5) if loaded else g._harvest_target(),"color":Color("#c46c39")}
	if waiting>=4:
		var upgrade: Dictionary=g._upgrade("checkout")
		return {"id":"queue","title":"%s · %d/6 clientes" % ["Fila llena" if waiting>=6 else "Se está formando fila",waiting],
			"detail":"Caja rápida atiende más seguido. Cuesta %d monedas." % upgrade["price"] if not upgrade["done"] else "La caja está al máximo. Mantené el puesto abastecido.",
			"button":"VER CAJA" if not upgrade["done"] else "VER FILA",
			"target":upgrade["target"] if not upgrade["done"] else Vector3(8.3,0,.6),"color":Color("#b95a52")}
	return {}

func objective() -> Dictionary:
	var bag: int=g._total_bag()
	if bag>=g.max_capacity or (g.worker_count==0 and bag>=6):
		return {"tag":"PASO 2 · ABASTECÉ","title":"Llevá la cosecha al puesto","detail":"Entrá al círculo dorado. Se entrega sola.","goal":g.max_capacity,"value":bag,"button":"ENTREGAR","target":Vector3(4,0,2.5),"icon":"bag"}
	var kind := recommended()
	var upgrade: Dictionary=g._upgrade(kind) if not kind.is_empty() else {}
	if not upgrade.is_empty() and g.coins>=upgrade["price"]:
		var nearby: bool=g.player.position.distance_to(upgrade["target"])<=g.PAD_RADIUS
		return {"tag":"YA TE ALCANZA · %d MONEDAS" % upgrade["price"],"title":upgrade["name"],"detail":upgrade["benefit"],
			"goal":upgrade["price"],"value":g.coins,"button":"COMPRAR" if nearby else "IR AHÍ","target":upgrade["target"],"upgrade":kind,"ready":true,"icon":kind}
	if g.worker_count==0:
		if bag>0 and g.delivered>0:
			return {"tag":"PASO 2 · VENDÉ PARA AUTOMATIZAR","title":"Reponé y ganá tus monedas","detail":"Primer ayudante: %d / %d monedas." % [g.coins,g.helper_cost],"goal":g.helper_cost,"value":g.coins,"button":"ENTREGAR","target":Vector3(4,0,2.5),"icon":"bag"}
		return {"tag":"PASO 1 · RECOLECTÁ" if g.delivered==0 else "PRÓXIMO: AYUDANTE AUTOMÁTICO",
			"title":"Acercate a los tomates" if g.delivered==0 else "Cosechá mientras el puesto vende",
			"detail":"Seguí las flechas. Se recogen solos: %d/6." % mini(bag,6) if g.delivered==0 else "Te faltan %d monedas para contratar ayuda." % maxi(0,g.helper_cost-g.coins),
			"goal":6 if g.delivered==0 else g.helper_cost,"value":bag if g.delivered==0 else g.coins,
			"button":"GUIAR","target":g._harvest_target(),"icon":"arrow"}
	if upgrade.is_empty():
		return {"tag":"NIVEL %02d · MERCADO COMPLETO" % g.quest_level,"title":"Seguí vendiendo","detail":"Cada 20 ventas recibís 70 monedas extra.","goal":20,"value":g.sold%20,"button":"MEJORAS","upgrade":"shop","icon":"coin"}
	var work_target: Vector3=Vector3(4,0,2.5) if bag>0 else g._harvest_target()
	return {"tag":"PRÓXIMO: %s · %d" % [upgrade["short"],upgrade["price"]],
		"title":"Reponé el puesto" if bag>0 else "Tu equipo ya está trabajando",
		"detail":"%d / %d monedas · %s" % [g.coins,upgrade["price"],upgrade["benefit"]],
		"goal":upgrade["price"],"value":g.coins,"button":"ENTREGAR" if bag>0 else "COSECHAR",
		"target":work_target,"icon":"bag" if bag>0 else "arrow"}
