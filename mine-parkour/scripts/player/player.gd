extends CharacterBody3D

const WALK_SPEED = 4.3
const SPRINT_SPEED = 5.6
const SNEAK_SPEED = 1.3
const JUMP_VELOCITY = 8.0
const GRAVITY = 28.0
const FALL_GRAVITY_MULT = 1.6
const GROUND_ACCEL = 40.0
const AIR_ACCEL = 18.0
const STEP_HEIGHT = 0.6
const COYOTE_TIME = 0.1
const JUMP_BUFFER_TIME = 0.1

const FOV_BASE = 70.0
const FOV_SPRINT_BONUS = 10.0
const FOV_SNEAK_PENALTY = 5.0
const FOV_LERP_SPEED = 8.0

const HEAD_Y_STAND  = 0.65
const HEAD_Y_CROUCH = 0.45
const HEAD_LERP_SPEED = 12.0

const CAPSULE_HEIGHT_STAND  = 1.8
const CAPSULE_HEIGHT_CROUCH = 1.1

const FOOTSTEP_INTERVAL_WALK   = 0.45
const FOOTSTEP_INTERVAL_SPRINT = 0.30
const FOOTSTEP_INTERVAL_SNEAK  = 0.65

@onready var head      = $Head
@onready var camera    = $Head/Camera
@onready var col_shape = $CollisionShape3D

@onready var footstep_player = $FootstepPlayer
@onready var death_sound = $DeathPlayer
@onready var victory_sound = $VictoryPlayer

var camera_x_rotation = 0.0
var wish_dir := Vector3.ZERO
var is_sprinting = false
var is_sneaking  = false
var coyote_timer      = 0.0
var jump_buffer_timer = 0.0
var was_on_floor      = false
var on_ice            := false
var last_velocity_y   := 0.0
var last_bounce_launch_y := 0.0
var camera_touch_index := -1
var camera_touch_start := Vector2.ZERO

var footstep_sounds = []
var footstep_timer = 0.0
var last_footstep_idx = -1

func _ready():
	footstep_sounds = [
		preload("res://sounds/stone1.ogg"),
		preload("res://sounds/stone2.ogg"),
		preload("res://sounds/stone3.ogg"),
		preload("res://sounds/stone4.ogg"),
		preload("res://sounds/stone5.ogg"),
		preload("res://sounds/stone6.ogg"),
	]
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if DisplayServer.is_touchscreen_available():
		for action in ["pause", "move_forward", "move_back", "move_left", "move_right", "jump", "sprint", "sneak"]:
			Input.action_release(action)

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if not DisplayServer.is_touchscreen_available() and not Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		$PauseMenu.show()
	if $PauseMenu.visible:
		return
	Input.use_accumulated_input = false
	if not DisplayServer.is_touchscreen_available():
		if event is InputEventMouseButton and event.pressed:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		if event is InputEventMouseMotion:
			if event.relative.length() > 100:
				return
			head.rotate_y(-event.relative.x * Startup.mouse_sens)
			camera_x_rotation -= event.relative.y * Startup.mouse_sens
			camera_x_rotation = clamp(camera_x_rotation, -PI/2, PI/2)
			camera.rotation.x = camera_x_rotation
		return

	var screen_width = get_viewport().get_visible_rect().size.x

	if event is InputEventScreenTouch:
		if event.pressed:
			if event.position.x > screen_width / 2.0 and camera_touch_index == -1:
				camera_touch_index = event.index
				camera_touch_start = event.position
		else:
			if event.index == camera_touch_index:
				camera_touch_index = -1

	if event is InputEventScreenDrag:
		if event.index == camera_touch_index:
			var rel = event.relative
			if rel.length() > 100:
				return
			head.rotate_y(-rel.x * Startup.mouse_sens)
			camera_x_rotation -= rel.y * Startup.mouse_sens
			camera_x_rotation = clamp(camera_x_rotation, -PI/2, PI/2)
			camera.rotation.x = camera_x_rotation

func _physics_process(delta):
	if $PauseMenu.visible:
		return

	var on_floor = is_on_floor()
	var just_landed = on_floor and not was_on_floor

	# Coyote time
	if on_floor:
		coyote_timer = COYOTE_TIME
	else:
		coyote_timer -= delta

	# Jump buffer
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER_TIME
	else:
		jump_buffer_timer -= delta

	# Gravity
	if not on_floor:
		var grav = GRAVITY * (FALL_GRAVITY_MULT if velocity.y < 0 else 1.0)
		velocity.y -= grav * delta
		if velocity.y > 0 and _is_hitting_ceiling():
			velocity.y = 0.0

	# Sneak / Sprint
	is_sneaking = Input.is_action_pressed("sneak") and on_floor
	if Input.is_action_pressed("sprint") and not Input.is_action_pressed("move_back") and not is_sneaking:
		is_sprinting = true
	if not Input.is_action_pressed("move_forward") or is_sneaking:
		is_sprinting = false
	if is_sprinting and _is_hitting_wall():
		is_sprinting = false
	if DisplayServer.is_touchscreen_available():
		is_sprinting = true

	# Crouch
	var target_head_y = HEAD_Y_CROUCH if is_sneaking else HEAD_Y_STAND
	head.position.y = lerp(head.position.y, target_head_y, HEAD_LERP_SPEED * delta)
	if col_shape.shape is CapsuleShape3D:
		var target_height = CAPSULE_HEIGHT_CROUCH if is_sneaking else CAPSULE_HEIGHT_STAND
		col_shape.shape.height = lerp(col_shape.shape.height, target_height, HEAD_LERP_SPEED * delta)

	var speed = SNEAK_SPEED if is_sneaking else (SPRINT_SPEED if is_sprinting else WALK_SPEED)

	var input_dir = Vector3(
		Input.get_axis("move_left", "move_right"),
		0,
		Input.get_axis("move_forward", "move_back")
	)

	var flat_basis = Basis(Vector3.UP, head.rotation.y)
	wish_dir = flat_basis * input_dir
	wish_dir.y = 0
	if wish_dir.length() > 0:
		wish_dir = wish_dir.normalized()

	var h_vel = Vector3(velocity.x, 0, velocity.z)
	var floor_friction = _get_floor_friction()

	if on_floor:
		if input_dir == Vector3.ZERO:
			h_vel = h_vel.move_toward(Vector3.ZERO, GROUND_ACCEL * floor_friction * delta * 2.0)
			if h_vel.length() < 0.05:
				h_vel = Vector3.ZERO
		elif is_sneaking and _is_sneak_edge():
			if wish_dir.length() > 0.0:
				h_vel -= h_vel.project(wish_dir)
		else:
			var target = wish_dir * speed
			h_vel = h_vel.move_toward(target, GROUND_ACCEL * floor_friction * delta)
			if not is_sneaking:
				_try_step_up(h_vel, delta)
	else:
		if input_dir == Vector3.ZERO:
			h_vel = h_vel.move_toward(Vector3.ZERO, 6.0 * delta)
		else:
			var speed_before = h_vel.length()
			h_vel += wish_dir.normalized() * AIR_ACCEL * delta
			var speed_after = h_vel.length()
			if speed_after > speed and speed_after > speed_before:
				if on_ice:
					speed *= 1.5
				h_vel = h_vel.normalized() * speed

	velocity.x = h_vel.x
	velocity.z = h_vel.z

	var want_jump = Input.is_action_pressed("jump") and (just_landed or jump_buffer_timer > 0)
	if want_jump and coyote_timer > 0:
		velocity.y = JUMP_VELOCITY
		coyote_timer = 0.0
		jump_buffer_timer = 0.0

	was_on_floor = on_floor

	var pre_slide_vel_y = velocity.y
	move_and_slide()

	# Slime bounce
	if is_on_floor() and not _is_on_slime():
		last_bounce_launch_y = 0.0
	if is_on_floor() and _is_on_slime() and pre_slide_vel_y < -0.5:
		if is_sneaking:
			velocity.y = 0.0
		else:
			var bounce = -pre_slide_vel_y * 0.8
			if last_bounce_launch_y > 0.0:
				bounce = min(bounce, last_bounce_launch_y * 0.8)
			velocity.y = bounce
			last_bounce_launch_y = bounce

	_apply_fov(delta, h_vel.length(), speed)
	_tick_footsteps(delta, h_vel.length())
	if velocity.y < 0:
		last_velocity_y = velocity.y

func _is_sneak_edge() -> bool:
	var move_dir = wish_dir if wish_dir.length() > 0.1 else Vector3(velocity.x, 0, velocity.z).normalized()
	if move_dir.length() < 0.1:
		return false
	var space = get_world_3d().direct_space_state
	var check_pos = global_position + move_dir * 0.01
	var params = PhysicsRayQueryParameters3D.create(
		check_pos + Vector3.UP * 0.05,
		check_pos + Vector3.DOWN * 1.5
	)
	params.exclude = [self]
	return space.intersect_ray(params).is_empty()

func _is_on_slime() -> bool:
	var space = get_world_3d().direct_space_state
	var offsets = [
		Vector3.ZERO,
		Vector3(0.3, 0, 0),
		Vector3(-0.3, 0, 0),
		Vector3(0, 0, 0.3),
		Vector3(0, 0, -0.3),
		Vector3(0.3, 0, 0.3),
		Vector3(-0.3, 0, 0.3),
		Vector3(0.3, 0, -0.3),
		Vector3(-0.3, 0, -0.3),
	]
	for offset in offsets:
		var params = PhysicsRayQueryParameters3D.create(
			global_position + Vector3.UP * 0.1 + offset,
			global_position + Vector3.DOWN * 1.8 + offset
		)
		params.exclude = [self]
		var result = space.intersect_ray(params)
		if not result.is_empty() and result["collider"].is_in_group("slime"):
			return true
	return false

func _apply_fov(delta: float, h_speed: float, current_speed_cap: float):
	var target_fov: float
	if is_sneaking:
		target_fov = FOV_BASE - FOV_SNEAK_PENALTY
	else:
		var t = clamp(h_speed / current_speed_cap, 0.0, 1.0)
		var bonus = FOV_SPRINT_BONUS if is_sprinting else 0.0
		target_fov = FOV_BASE + bonus * t
	camera.fov = lerp(camera.fov, target_fov, FOV_LERP_SPEED * delta)

func _is_hitting_ceiling() -> bool:
	var space = get_world_3d().direct_space_state
	var params = PhysicsRayQueryParameters3D.create(
		global_position,
		global_position + Vector3.UP * 1.1
	)
	params.exclude = [self]
	return space.intersect_ray(params).size() > 0

func _is_hitting_wall() -> bool:
	for i in range(get_slide_collision_count()):
		var col = get_slide_collision(i)
		if abs(col.get_normal().y) < 0.3:
			return true
	return false

func _try_step_up(h_vel: Vector3, _delta: float):
	if h_vel.length() < 0.1:
		return
	var space = get_world_3d().direct_space_state
	var move_dir = h_vel.normalized()

	var probe_dist = clamp(h_vel.length() * _delta + 0.2, 0.2, 0.45)

	var wall_check = PhysicsRayQueryParameters3D.create(
		global_position + Vector3.UP * 0.05,
		global_position + Vector3.UP * 0.05 + move_dir * probe_dist
	)
	wall_check.exclude = [self]
	if space.intersect_ray(wall_check).is_empty():
		return

	var top_pos = global_position + Vector3.UP * STEP_HEIGHT
	var top_check = PhysicsRayQueryParameters3D.create(
		top_pos,
		top_pos + move_dir * probe_dist
	)
	top_check.exclude = [self]
	if not space.intersect_ray(top_check).is_empty():
		return

	var land_check = PhysicsRayQueryParameters3D.create(
		top_pos + move_dir * probe_dist,
		top_pos + move_dir * probe_dist + Vector3.DOWN * STEP_HEIGHT
	)
	land_check.exclude = [self]
	var land = space.intersect_ray(land_check)
	if land.is_empty():
		return

	var step_height = land["position"].y - global_position.y
	if step_height < 0.01 or step_height > STEP_HEIGHT:
		return

	global_position.y = land["position"].y + 0.01

func _get_floor_friction() -> float:
	var space = get_world_3d().direct_space_state
	var offsets = [
		Vector3.ZERO,
		Vector3(0.3, 0, 0),
		Vector3(-0.3, 0, 0),
		Vector3(0, 0, 0.3),
		Vector3(0, 0, -0.3),
	]
	var air = 0
	for offset in offsets:
		var params = PhysicsRayQueryParameters3D.create(
			global_position + Vector3.UP * 0.1 + offset,
			global_position + Vector3.DOWN * 1.8 + offset
		)
		params.exclude = [self]
		var result = space.intersect_ray(params)
		if result.is_empty():
			air += 1
			continue
		if result["collider"].is_in_group("ice"):
			on_ice = true
			return 0.02
		if result["collider"].is_in_group("slime"):
			return 0.4
	if air < 5:
		on_ice = false
	return 1.0

func _tick_footsteps(delta: float, h_speed: float):
	if not is_on_floor() or h_speed < 0.5:
		footstep_timer = 0.0
		return

	var interval = FOOTSTEP_INTERVAL_WALK
	if is_sprinting:
		interval = FOOTSTEP_INTERVAL_SPRINT
	elif is_sneaking:
		interval = FOOTSTEP_INTERVAL_SNEAK

	footstep_timer -= delta
	if footstep_timer <= 0.0:
		footstep_timer = interval
		_play_footstep()

func _play_footstep():
	var idx = randi() % footstep_sounds.size()
	while footstep_sounds.size() > 1 and idx == last_footstep_idx:
		idx = randi() % footstep_sounds.size()
	last_footstep_idx = idx

	footstep_player.stream = footstep_sounds[idx]
	footstep_player.pitch_scale = randf_range(0.92, 1.08)  # slight pitch variation
	footstep_player.play()

func die():
	set_physics_process(false)
	set_process_unhandled_input(false)
	death_sound.play()
	await death_sound.finished
	get_tree().reload_current_scene()

func victory():
	set_physics_process(false)
	set_process_unhandled_input(false)
	victory_sound.play()
	await victory_sound.finished
	var scene_name = get_tree().current_scene.scene_file_path.get_file()
	var level_index = int(scene_name.lstrip("level_").rstrip(".tscn"))
	Startup.complete_level(level_index)
	Startup.show_level_select_on_load = true
	get_tree().call_deferred("change_scene_to_file", "res://scenes/panorama.tscn")
