@tool
class_name TouchButton
extends Control

## A Control-based button that supports multi-touch and maps to an InputMap action,
## behaving like TouchScreenButton but usable in any Control/UI layout.

@export var action: StringName = ""          ## The InputMap action to trigger
@export var passby_press: bool = false       ## Fire on finger slide-over (like TouchScreenButton)
@export var toggle_mode: bool = false        ## If true, tap toggles pressed state on/off

## Emitted when the button is pressed (finger down, or toggled on)
signal pressed
## Emitted when the button is released (finger up, slide-out, or toggled off)
signal released

var _tracking_fingers: Dictionary = {}       # finger_index -> true
var _is_pressed: bool = false

# ───────────────────────────────────────────────
#  Godot overrides
# ───────────────────────────────────────────────

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return

	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)


# ───────────────────────────────────────────────
#  Touch handling
# ───────────────────────────────────────────────

func _handle_touch(event: InputEventScreenTouch) -> void:
	var local_pos: Vector2 = get_local_mouse_position_from_global(event.position)
	var inside: bool = _point_inside(local_pos)

	if toggle_mode:
		# Only react on finger-down inside the button; ignore finger-up entirely
		if event.pressed and inside:
			_set_pressed(not _is_pressed)
		return

	if event.pressed:
		if inside or passby_press:
			if inside:
				_add_finger(event.index)
	else:
		if _tracking_fingers.has(event.index):
			_remove_finger(event.index)


func _handle_drag(event: InputEventScreenDrag) -> void:
	# Drag has no effect in toggle mode
	if toggle_mode:
		return

	if not passby_press:
		if _tracking_fingers.has(event.index):
			var local_pos: Vector2 = get_local_mouse_position_from_global(event.position)
			if not _point_inside(local_pos):
				_remove_finger(event.index)
	else:
		var local_pos: Vector2 = get_local_mouse_position_from_global(event.position)
		if _point_inside(local_pos):
			_add_finger(event.index)
		else:
			if _tracking_fingers.has(event.index):
				_remove_finger(event.index)


# ───────────────────────────────────────────────
#  Finger tracking helpers
# ───────────────────────────────────────────────

func _add_finger(index: int) -> void:
	if _tracking_fingers.has(index):
		return
	_tracking_fingers[index] = true
	if not _is_pressed:
		_set_pressed(true)


func _remove_finger(index: int) -> void:
	_tracking_fingers.erase(index)
	if _tracking_fingers.is_empty() and _is_pressed:
		_set_pressed(false)


func _set_pressed(value: bool) -> void:
	_is_pressed = value
	if action == "":
		if value:
			emit_signal("pressed")
		else:
			emit_signal("released")
		return

	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = value
	ev.strength = 1.0 if value else 0.0
	Input.parse_input_event(ev)

	if value:
		emit_signal("pressed")
	else:
		emit_signal("released")


# ───────────────────────────────────────────────
#  Utilities
# ───────────────────────────────────────────────

func is_action_pressed() -> bool:
	return _is_pressed

## Force the toggle state from code (no-op in non-toggle mode unless you want it to).
func set_toggle_state(value: bool) -> void:
	if _is_pressed != value:
		_set_pressed(value)

func get_local_mouse_position_from_global(global_pos: Vector2) -> Vector2:
	return global_pos - global_position

func _point_inside(local_pos: Vector2) -> bool:
	return Rect2(Vector2.ZERO, size).has_point(local_pos)
