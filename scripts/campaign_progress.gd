extends RefCounted
class_name WivoriCampaignProgress

# Map completion is separate from the hero's global bag/speed upgrades.
# Existing destinations are never revoked when a legacy save is migrated.
const MAP_TITLES=["Mercado de Wivori","Campos de Villa Miga","Granjas de Puerto Nata","Puerto de Bahía Farol","Fábricas de Distrito Forja","Astillero de Puerto Aurora"]
const MAP_LESSONS=[
	"Cosechá, atendé, contratá al equipo y protegé las cajas.",
	"Repartí el trigo entre harina, alimento, pan y gallinas.",
	"Abastecé a los animales y decidí qué leche vender o transformar.",
	"Combiná productos de varias islas y reconstruí el Faro.",
	"Organizá tres fábricas y completá una ronda de seis contratos mixtos.",
	"Construí un astillero y elegí cargamentos para expediciones de distinta duración."
]
const MARKET_KEYS=["checkout","expand","pier","collector","lock","alarm","guard"]
const EXIT_PROJECTS=["nata_route","farol_route","festival","aurora_launch"]
var route

func _init(source: Node3D) -> void:
	route=source

func upgrade_tasks(area: int) -> Array[Dictionary]:
	var tasks: Array[Dictionary]=[]
	if area==0:
		# Four field workers form the first market's base team. Additional
		# workers remain optional expansion, rather than an exponential toll
		# before the player can ever see a farm.
		if route.g.worker_count<4:
			tasks.append({"kind":"market","key":"helper","title":"Equipo del mercado · %d/4" % route.g.worker_count})
		for key in MARKET_KEYS:
			var upgrade: Dictionary=route.g._upgrade(key)
			if not upgrade["done"]:tasks.append({"kind":"market","key":key,"title":upgrade["name"]})
		return tasks
	for key in route.RECIPES:
		var recipe: Dictionary=route.RECIPES[key]
		if int(recipe["region"])!=area:continue
		if not route.built.has(recipe["building"]):
			tasks.append({"kind":"build","key":key,"title":"Construí "+route.GOODS[key]})
			continue
		# Pausing a paid operator does not undo completion or charge again.
		if not route.employees.has(key):tasks.append({"kind":"hire","key":key,"title":"Operario de "+route.GOODS[key]})
		if int(route.mastery.get(key,0))<3:tasks.append({"kind":"improve","key":key,"title":"%s · mejora %d/3" % [route.GOODS[key],int(route.mastery.get(key,0))]})
	return tasks

func upgrades_complete(area: int) -> bool:
	return upgrade_tasks(area).is_empty()

func home_ready() -> bool:
	return route.g.run.level>=6 and upgrades_complete(0)

func completed(area: int) -> bool:
	if area==0:return home_ready() and route.ferry
	for project in route.PROJECTS+route.INDUSTRY_PROJECTS+route.AURORA_PROJECTS:
		if int(project["region"])==area and not route.built.has(project["id"]):return false
	if not upgrades_complete(area):return false
	if area==4:return route.industry_orders_done>=route.INDUSTRIAL_ORDERS.size()
	if area==5:return route.expedition_routes.size()>=route.EXPEDITIONS.size()
	return true

func exit_allowed(project: Dictionary) -> bool:
	return project.get("id","") not in EXIT_PROJECTS or upgrades_complete(int(project["region"]))

func status(area: int) -> String:
	if completed(area):return "COMPLETADO"
	var remaining: int=upgrade_tasks(area).size()
	if remaining>0:return "%d mejoras pendientes" % remaining
	if area==4 and route.industry_stage==route.INDUSTRY_PROJECTS.size():
		return "Contratos mixtos · %d/%d" % [mini(route.industry_orders_done,route.INDUSTRIAL_ORDERS.size()),route.INDUSTRIAL_ORDERS.size()]
	if area==5 and route.aurora_stage==route.AURORA_PROJECTS.size():return "Rutas de expedición · %d/3" % route.expedition_routes.size()
	return "Construcciones y entrega final pendientes"

func progress(area: int) -> float:
	var done:=0.0
	var goal:=0.0
	if area==0:
		goal=float(MARKET_KEYS.size()+2)
		done=clampf(float(route.g.worker_count)/4.0,0.0,1.0)+clampf(float(route.g.run.level-1)/5.0,0.0,1.0)
		for key in MARKET_KEYS:
			if route.g._upgrade(key)["done"]:done+=1.0
	else:
		for project in route.PROJECTS+route.INDUSTRY_PROJECTS+route.AURORA_PROJECTS:
			if int(project["region"])!=area:continue
			goal+=1.0
			if route.built.has(project["id"]):done+=1.0
		for key in route.RECIPES:
			if int(route.RECIPES[key]["region"])!=area:continue
			goal+=4.0
			done+=float(route.mastery.get(key,0))+(1.0 if route.employees.has(key) else 0.0)
		if area==4:goal+=6.0;done+=float(mini(6,route.industry_orders_done))
		if area==5:goal+=3.0;done+=float(route.expedition_routes.size())
	return clampf(done/maxf(1.0,goal),0.0,1.0)
