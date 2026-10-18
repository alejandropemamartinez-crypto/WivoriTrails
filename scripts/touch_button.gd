extends Button

# Native Button handles mouse/keyboard. Handle real touch separately so each
# button can own a different finger while the joystick is held elsewhere.
var touch_index := -1
var touch_inside := false
var touch_origin := Vector2.ZERO
var touch_cancelled := false
var visual_tween: Tween

func _ready() -> void:
	pivot_offset=size*.5
	resized.connect(func():pivot_offset=size*.5)
	button_down.connect(func():_animate_press(true))
	button_up.connect(func():_animate_press(false))

func _animate_press(down: bool) -> void:
	if not is_inside_tree():return
	if visual_tween!=null:visual_tween.kill()
	visual_tween=create_tween()
	visual_tween.tween_property(self,"scale",Vector2.ONE*(.96 if down else 1.0),.10 if down else .18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and not disabled and touch_index==-1:
			touch_index=event.index
			touch_origin=event.position
			touch_cancelled=false
			_set_touch_inside(true)
			accept_event()
		elif not event.pressed and event.index==touch_index:
			var activate: bool=not event.canceled and not touch_cancelled and not disabled and Rect2(Vector2.ZERO,size).has_point(event.position)
			_release_touch()
			accept_event()
			if activate:pressed.emit()
	elif event is InputEventScreenDrag and event.index==touch_index:
		if event.position.distance_to(touch_origin)>22:
			touch_cancelled=true
		_set_touch_inside(not touch_cancelled and Rect2(Vector2.ZERO,size).has_point(event.position))
		accept_event()

func _set_touch_inside(inside: bool) -> void:
	if inside==touch_inside:return
	touch_inside=inside
	self_modulate=Color(.86,.91,.89) if inside else Color.WHITE
	if inside:button_down.emit()
	else:button_up.emit()

func _release_touch() -> void:
	_set_touch_inside(false)
	touch_index=-1
	touch_cancelled=false

func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_PAUSED,NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_EXIT_TREE,NOTIFICATION_SCROLL_BEGIN,NOTIFICATION_DRAG_BEGIN]:
		_release_touch()
	elif what==NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree():
		_release_touch()
