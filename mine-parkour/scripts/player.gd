extends CharacterBody3D

const WALK_SPEED = 4.3
const SPRINT_SPEED = 5.6
const SNEAK_SPEED = 1.3
const JUMP_VELOCITY = 8.0
const GRAVITY = 28.0
const FALL_GRAVITY_MULT = 1.6
const GROUND_ACCEL = 40.0
const AIR_ACCEL = 18.0         # high enough to redirect snappily
const AIR_FRICTION = 1.0
const GROUND_FRICTION = 18.0
const MOVING_FRICTION = 8.0
const STEP_HEIGHT = 0.6
const COYOTE_TIME = 0.1
const JUMP_BUFFER_TIME = 0.1

const FOV_BASE = 70.0
const FOV_SPRINT_BONUS = 10.0
const FOV_SNEAK_PENALTY = 5.0
const FOV_LERP_SPEED = 8.0

@onready var head = $Head
@onready var camera = $Head/Camera
var mouse_sensitivity = 0.002
var camera_x_rotation = 0.0

var is_sprinting = false
var is_sneaking = false
var coyote_timer = 0.0
var jump_buffer_timer = 0.0
var was_on_floor = false        # track landing frame for hold-to-jump

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	Input.use_accumulated_input = false
	if event is InputEventMouseButton and event.pressed:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if event is InputEventMouseMotion:
		if event.relative.length() > 100:
			return
		head.rotate_y(-event.relative.x * mouse_sensitivity)
		camera_x_rotation -= event.relative.y * mouse_sensitivity
		camera_x_rotation = clamp(camera_x_rotation, -PI/2, PI/2)

		head.rotation.x = camera_x_rotation

func _physics_process(delta):
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

	var speed = SNEAK_SPEED if is_sneaking else (SPRINT_SPEED if is_sprinting else WALK_SPEED)

	var input_dir = Vector3(
		Input.get_axis("move_left", "move_right"),
		0,
		Input.get_axis("move_forward", "move_back")
	)
	var wish_dir = head.global_transform.basis * input_dir
	wish_dir.y = 0
	if wish_dir.length() > 0:
		wish_dir = wish_dir.normalized()
	var h_vel = Vector3(velocity.x, 0, velocity.z)

	# ── Apply movement FIRST so deceleration is baked in before jump ──
	if on_floor:
		if is_sneaking and input_dir != Vector3.ZERO and _is_sneak_edge():
			h_vel = Vector3.ZERO
		elif input_dir == Vector3.ZERO:
			# Decelerate to stop — this now happens BEFORE the jump fires
			h_vel = h_vel.move_toward(Vector3.ZERO, GROUND_ACCEL * delta * 2.0)
			if h_vel.length() < 0.05:
				h_vel = Vector3.ZERO
		else:
			var target = wish_dir * speed
			h_vel = h_vel.move_toward(target, GROUND_ACCEL * delta)
			_try_step_up(h_vel, delta)
	else:
		if input_dir == Vector3.ZERO:
			# bleed velocity when no movement keys are held
			h_vel = h_vel.move_toward(Vector3.ZERO, 6.0 * delta)
		else:
			var speed_before = h_vel.length()
			h_vel += wish_dir.normalized() * AIR_ACCEL * delta
			var speed_after = h_vel.length()
			if speed_after > speed and speed_after > speed_before:
				h_vel = h_vel.normalized() * speed
	if input_dir == Vector3.ZERO:
		h_vel = h_vel.move_toward(Vector3.ZERO, 6.0 * delta)
	velocity.x = h_vel.x
	velocity.z = h_vel.z

	# ── Jump fires AFTER deceleration is written to velocity ──
	var want_jump = (Input.is_action_pressed("jump") and just_landed) or (jump_buffer_timer > 0)

	if want_jump and coyote_timer > 0:
		velocity.y = JUMP_VELOCITY
		coyote_timer = 0.0
		jump_buffer_timer = 0.0

	was_on_floor = on_floor
	move_and_slide()
	_apply_fov(delta, h_vel.length())

func _apply_fov(delta: float, h_speed: float):
	var target_fov: float
	if is_sneaking:
		target_fov = FOV_BASE - FOV_SNEAK_PENALTY
	else:
		var speed_ref = SPRINT_SPEED if is_sprinting else WALK_SPEED
		var t = clamp(h_speed / speed_ref, 0.0, 1.0)
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

func _is_sneak_edge() -> bool:
	var space = get_world_3d().direct_space_state
	var check_pos = global_position + Vector3(velocity.x, 0, velocity.z).normalized() * 0.4
	var params = PhysicsRayQueryParameters3D.create(
		check_pos,
		check_pos + Vector3.DOWN * 0.7
	)
	params.exclude = [self]
	return space.intersect_ray(params).is_empty()

func _try_step_up(h_vel: Vector3, _delta: float):
	if h_vel.length() < 0.1:
		return
	var space = get_world_3d().direct_space_state
	var move_dir = h_vel.normalized()

	var wall_check = PhysicsRayQueryParameters3D.create(
		global_position + Vector3.UP * 0.05,
		global_position + Vector3.UP * 0.05 + move_dir * 0.4
	)
	wall_check.exclude = [self]
	if space.intersect_ray(wall_check).is_empty():
		return

	var top_pos = global_position + Vector3.UP * STEP_HEIGHT
	var top_check = PhysicsRayQueryParameters3D.create(
		top_pos,
		top_pos + move_dir * 0.4
	)
	top_check.exclude = [self]
	if not space.intersect_ray(top_check).is_empty():
		return

	var land_check = PhysicsRayQueryParameters3D.create(
		top_pos + move_dir * 0.4,
		top_pos + move_dir * 0.4 + Vector3.DOWN * STEP_HEIGHT
	)
	land_check.exclude = [self]
	var land = space.intersect_ray(land_check)
	if land.is_empty():
		return

	global_position.y = land.position.y + 0.01
