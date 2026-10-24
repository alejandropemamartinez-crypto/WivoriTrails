extends Control
class_name MarketJoystick

# Real multi-touch analog stick; independent of buttons on the other side.
var axis := Vector2.ZERO
var input_allowed: Callable
var active_finger := -1
var pressed := false
const MAX_RADIUS := 65.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process_input(true)
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if input_allowed.is_valid() and not input_allowed.call():_clear();return
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
	if not is_visible_in_tree():return
	if input_allowed.is_valid() and not input_allowed.call():_clear();return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and active_finger == -1:
		_clear()
	if event is InputEventScreenTouch:
		var local: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.position
		if event.canceled and event.index==active_finger:
			_clear();get_viewport().set_input_as_handled();return
		if event.pressed and not event.canceled and active_finger == -1 and Rect2(Vector2.ZERO, size).has_point(local):
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
	var strength:=clampf((displacement.length()-deadzone)/(MAX_RADIUS-deadzone),0,1)
	axis=displacement.normalized()*pow(strength,1.15) if strength>0 else Vector2.ZERO
	queue_redraw()

func _clear() -> void:
	pressed = false
	active_finger = -1
	axis = Vector2.ZERO
	queue_redraw()

func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_WM_WINDOW_FOCUS_OUT]:
		_clear()
	elif what==NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree():_clear()

func _draw() -> void:
	var center: Vector2 = size * .5
	draw_circle(center+Vector2(0,6),94,Color(.06,.19,.22,.17))
	draw_circle(center,86,Color(.17,.34,.37,.64))
	draw_arc(center,86,0,TAU,64,Color(.99,.91,.70,.73),3.0,true)
	draw_circle(center,74,Color(.95,.91,.78,.20))
	for i in range(4):
		var at:=center+Vector2.from_angle(float(i)*PI*.5)*64
		draw_circle(at,3,Color(.99,.94,.78,.55))
	var stick := center + axis * MAX_RADIUS
	draw_circle(stick+Vector2(0,5),40,Color("#1f555a"))
	draw_circle(stick,39,Color("#65b0a0"))
	draw_circle(stick+Vector2(0,-5),32,Color("#7cbead"))
	draw_arc(stick,39,PI,TAU,48,Color("#d7ead0"),3.0,true)
	draw_circle(stick,8,Color("#f2d99c"))
