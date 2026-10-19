extends Node3D
class_name WivoriPremiumSign

# Fixed-size order board. Changing crop names never stretches a world sign
# across the street; locked, active and completed states share one layout.
const FONT=preload("res://assets/fonts/Quicksand-Bold.ttf")
const BOARD=preload("res://assets/ui/signs/order_board.svg")
var heading: Label3D
var product: Label3D
var quantity: Label3D
var last_signature:=""

func _ready() -> void:
	name="Tablero de pedidos · tamaño fijo"
	var panel:=Sprite3D.new()
	panel.texture=BOARD;panel.pixel_size=.008
	panel.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	panel.shaded=false;panel.render_priority=1
	add_child(panel)
	heading=_line("PEDIDOS ×2",.49,42,Color("#fff5d7"))
	product=_line("SE ABRE EN NIVEL 4",-.11,31,Color("#285269"))
	quantity=_line("",-.48,30,Color("#a26927"))

func _line(message: String,y: float,size_: int,color_: Color) -> Label3D:
	var label:=Label3D.new()
	label.font=FONT;label.font_size=size_;label.pixel_size=.008
	label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	label.shaded=false;label.outline_size=0;label.modulate=color_
	label.position=Vector3(0,y,.025);label.render_priority=3
	label.text=message
	add_child(label)
	return label

func update_order(run) -> void:
	var signature: String="%d:%d:%s" % [run.level,run.contract_done,run.contract_kind()]
	if signature==last_signature:return
	last_signature=signature
	if run.level<4:
		product.text="SE ABRE EN NIVEL 4";quantity.text="VENDÉ · MEJORÁ · AVANZÁ"
		return
	var complete: bool=run.contract_done>=run.contract_goal()
	product.text="¡PEDIDO COMPLETADO!" if complete else str(run.g.CROP_NAMES[run.contract_kind()]).to_upper()
	quantity.text="%d / %d" % [run.contract_done,run.contract_goal()]
	product.font_size=31 if complete else 36
