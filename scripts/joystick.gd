extends Control
class_name MarketJoystick

# Real multi-touch analog stick; independent of buttons on the other side.
var axis := Vector2.ZERO
var active_finger := -1
var pressed := false
const MAX_RADIUS := 65.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process_input(true)
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	# Touch events are handled in _input so one finger continues to work outside
	# this control rectangle. Mouse works here for desktop testing.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			pressed=true
			_apply_local(event.position)
		else:
			_clear()
		accept_event()
	elif event is InputEventMouseMotion and pressed and active_finger == -1:
		_apply_local(event.position)
		accept_event()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and active_finger == -1:
		_clear()
	if event is InputEventScreenTouch:
		var local: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.position
		if event.pressed and active_finger == -1 and Rect2(Vector2.ZERO, size).has_point(local):
			active_finger=event.index
			pressed=true
			_apply_local(local)
			get_viewport().set_input_as_handled()
		elif not event.pressed and event.index == active_finger:
			_clear()
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index == active_finger:
		var local: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.position
		_apply_local(local)
		get_viewport().set_input_as_handled()

func _apply_local(local: Vector2) -> void:
	var displacement := local-size*.5
	var deadzone := 10.0
	axis = Vector2.ZERO if displacement.length()<deadzone else (displacement / MAX_RADIUS).limit_length(1.0)
	queue_redraw()

func _clear() -> void:
	pressed = false
	active_finger = -1
	axis = Vector2.ZERO
	queue_redraw()

func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_WM_WINDOW_FOCUS_OUT]:
		_clear()

func _draw() -> void:
	var center: Vector2 = size * .5
	draw_circle(center,97,Color(.07,.24,.23,.13))
	draw_circle(center,82,Color(.99,.98,.92,.89))
	draw_arc(center,83,0,TAU,64,Color(.20,.44,.40,.24),3.0,true)
	var stick := center + axis * MAX_RADIUS
	draw_circle(stick,39,Color("#2b8a7b"))
	draw_arc(stick,40,0,TAU,48,Color("#fffdf3"),4.0,true)
	draw_circle(stick,9,Color("#f3ce7b"))
