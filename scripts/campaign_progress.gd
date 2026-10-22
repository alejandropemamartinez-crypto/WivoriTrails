extends RefCounted
class_name WivoriCampaignProgress

# One set of milestones drives access, the checklist and navigation.
const MAP_TITLES=["Mercado de Wivori","Campos de Villa Miga","Granjas de Puerto Nata","Puerto de Bahía Farol","Fábricas de Distrito Forja","Astillero de Puerto Aurora"]
const MAP_LESSONS=[
	"Cosechá, vendé y dejá un ayudante al frente de tu mercado.",
	"Prepará harina, pan y alimento. Las gallinas te darán huevos.",
	"Criá animales y transformá leche en queso para comerciar.",
	"Reuní productos de tus pueblos y reconstruí el Faro.",
	"Conectá tres fábricas y entregá seis contratos de varios productos.",
	"Construí tu barco mercante y completá tres rutas de expedición."
]
const FERRY_COST=250
const FIRST_DELIVERY=6
const FIRST_SALES=18
const CORE_RECIPE={1:"flour",2:"milk",3:"provisions",4:"packaging"}
const EXIT_PROJECTS=["nata_route","farol_route","festival","aurora_launch"]
var route

func _init(source: Node3D) -> void:route=source

func _step(id: String,title: String,detail: String,value: int,goal: int,kind: String="",key: String="") -> Dictionary:
	return {"id":id,"title":title,"detail":detail,"value":mini(value,goal),"goal":goal,"done":value>=goal,"kind":kind,"key":key}

func steps(area: int) -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	if area==0:
		result.append(_step("delivery","Entregá tu primera cosecha","Llevá 6 productos al puesto ENTREGAR.",route.g.manual_delivered,FIRST_DELIVERY,"deliver"))
		result.append(_step("helper","Contratá un ayudante","80 monedas. Cosecha y abastece el puesto.",route.g.worker_count,1,"market","helper"))
		result.append(_step("checkout","Mejorá la caja una vez","140 monedas. Atendés más rápido y abrís otra caja.",route.g.checkout_level,1,"market","checkout"))
		result.append(_step("sales","Vendé 18 productos","Los clientes compran del puesto. Cobrá en CAJA.",route.g.sold,FIRST_SALES,"sell"))
		result.append(_step("ferry","Prepará tu barco","%d monedas. Incluye el primer terreno de trigo." % FERRY_COST,int(route.ferry),1,"ferry"))
		return result
	for project in route.PROJECTS+route.INDUSTRY_PROJECTS+route.AURORA_PROJECTS:
		if int(project["region"])!=area:continue
		if project["id"] in EXIT_PROJECTS:_append_workshop_steps(area,result)
		var needs: PackedStringArray=[]
		for key in project["needs"]:needs.append("%d %s" % [project["needs"][key],route.GOODS[key]])
		var price: String="Incluido con tu barco" if project["cost"]==0 else "%d monedas" % project["cost"]
		result.append(_step(project["id"],project["name"],price+(" · "+", ".join(needs) if not needs.is_empty() else ""),int(route.built.has(project["id"])),1,"build",project["id"]))
	if area==4:
		_append_workshop_steps(area,result)
		result.append(_step("contracts","Entregá los contratos industriales","Seis pedidos distintos en la caja de Forja.",route.industry_orders_done,route.INDUSTRIAL_ORDERS.size(),"contracts"))
	if area==5:
		result.append(_step("expeditions","Completá las tres rutas","Correo, abastecimiento y gran travesía.",route.expedition_routes.size(),route.EXPEDITIONS.size(),"expeditions"))
	return result

func _append_workshop_steps(area: int,result: Array[Dictionary]) -> void:
	if not CORE_RECIPE.has(area):return
	var key: String=CORE_RECIPE[area]
	result.append(_step("hire_"+key,"Contratá el operario de "+route.GOODS[key],"650 monedas. Trabaja con ingredientes guardados en el barco.",int(route.employees.has(key)),1,"hire",key))
	result.append(_step("improve_"+key,"Mejorá "+route.GOODS[key]+" una vez","450 monedas. Los siguientes niveles son opcionales.",int(route.mastery.get(key,0)),1,"improve",key))

func upgrade_tasks(area: int) -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	for step in steps(area):
		if not step["done"] and step["kind"] in ["market","hire","improve"]:result.append(step)
	return result

func upgrades_complete(area: int) -> bool:return upgrade_tasks(area).is_empty()

func home_ready() -> bool:
	for step in steps(0):
		if step["kind"]!="ferry" and not step["done"]:return false
	return true

func completed(area: int) -> bool:
	if area==0:return route.ferry
	for step in steps(area):
		if not step["done"]:return false
	return true

func exit_allowed(project: Dictionary) -> bool:
	return project.get("id","") not in EXIT_PROJECTS or upgrades_complete(int(project["region"]))

func done_count(area: int) -> int:
	var count:=0
	for step in steps(area):
		if step["done"]:count+=1
	return count

func status(area: int) -> String:
	if completed(area):return "ETAPA COMPLETADA"
	return "%d de %d hitos completados" % [done_count(area),steps(area).size()]

func progress(area: int) -> float:
	var done:=0.0
	var all_steps:=steps(area)
	for step in all_steps:done+=clampf(float(step["value"])/float(step["goal"]),0.0,1.0)
	return done/maxi(1,all_steps.size())

func frontier_area() -> int:return mini(route.unlocked(),5)

func next_step(area: int) -> Dictionary:
	for step in steps(area):
		if not step["done"]:return step
	return {}

func ready_to_open() -> bool:
	if not route.ferry:return home_ready() and route.g.coins>=FERRY_COST
	if frontier_area()>=5:return false
	var project: Dictionary=route.active_project()
	return not project.is_empty() and project["id"] in EXIT_PROJECTS and exit_allowed(project) and route.g.coins>=int(project["cost"]) and route.has_needs(project["needs"])
