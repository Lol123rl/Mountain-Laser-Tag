extends CharacterBody3D

@onready var head: Node3D = get_node_or_null("Head")
@onready var collision: CollisionShape3D = get_node_or_null("CollisionShape3D")
@onready var gun: Node3D = get_node_or_null("Gun")

@onready var gun_shot: Node = find_child("Gun Shot", true, false)
@onready var walk_sound: Node = find_child("Walk", true, false)
@onready var jump_sound: Node = find_child("Jump", true, false)
@onready var land_sound: Node = find_child("Land", true, false)

var mouse_sensitivity: float = 0.1
var camera_angle: float = 0.0

const SPEED: float = 6.0
const SPRINT: float = 10.0
const CROUCH_SPEED: float = 3.0
const JUMP: float = 9.0
const GRAVITY: float = 20.0

const MIN_BOUND: float = -490.0
const MAX_BOUND: float = 490.0

# ---------------- PLAYER HEALTH ----------------
const PLAYER_MAX_HEALTH: int = 100
var player_health: int = PLAYER_MAX_HEALTH
var player_dead: bool = false

var ui_layer: CanvasLayer = null
var health_label: Label = null
var crosshair_label: Label = null

# ---------------- AUDIO ----------------
const SOUND_VOLUME_DB: float = 24.0
const WALK_PITCH: float = 1.0
const SPRINT_WALK_PITCH: float = 1.55
const CROUCH_WALK_PITCH: float = 0.75

# ---------------- SHOOTING ----------------
const FIRE_COOLDOWN: float = 0.45
const SHOOT_RANGE: float = 300.0
const PLAYER_DAMAGE: int = 1

var fire_timer: float = 0.0

# ---------------- RECOIL ----------------
const CAMERA_RECOIL_AMOUNT: float = 2.0
const CAMERA_RECOIL_RECOVER_SPEED: float = 14.0
const GUN_RECOIL_AMOUNT: float = 0.25
const GUN_RECOIL_RECOVER_SPEED: float = 18.0

var camera_recoil: float = 0.0
var gun_recoil: float = 0.0

# ---------------- DOUBLE-TAP W SPRINT ----------------
const DOUBLE_TAP_TIME: float = 0.25
var last_w_tap_time: float = -10.0
var sprinting: bool = false

# ---------------- CROUCH ----------------
const STAND_HEAD_HEIGHT: float = 1.6
const CROUCH_HEAD_HEIGHT: float = 0.9
const STAND_CAPSULE_HEIGHT: float = 1.6
const CROUCH_CAPSULE_HEIGHT: float = 0.9
const CAPSULE_RADIUS: float = 0.4

# ---------------- GUN POSITIONS ----------------
var gun_idle_pos: Vector3 = Vector3(3.585, 0.08, -0.54)
var gun_move_pos: Vector3 = Vector3(-0.47, -0.08, -3.68)

var gun_crouch_offset: Vector3 = Vector3(0.0, -0.45, 0.0)

var gun_idle_rot: Vector3 = Vector3(0.0, -90.0, 0.0)
var gun_move_rot: Vector3 = Vector3(0.0, 0.0, 0.0)

var gun_base_pos: Vector3 = Vector3.ZERO
var gun_base_rot: Vector3 = Vector3.ZERO

var walk_bob_time: float = 0.0
var camera_roll: float = 0.0
var last_mouse_x: float = 0.0


func _ready() -> void:
	name = "CameraRig"
	add_to_group("Player")

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	global_position.y += 2.0
	floor_snap_length = 0.8

	setup_audio()
	create_ui()

	print("PLAYER READY")

	if head:
		head.position.y = STAND_HEAD_HEIGHT

	if collision and collision.shape and collision.shape is CapsuleShape3D:
		var capsule: CapsuleShape3D = collision.shape as CapsuleShape3D
		capsule.height = STAND_CAPSULE_HEIGHT
		capsule.radius = CAPSULE_RADIUS

	if gun:
		gun_base_pos = gun_idle_pos
		gun_base_rot = gun_idle_rot
		gun.position = gun_base_pos
		gun.rotation_degrees = gun_base_rot


func create_ui() -> void:
	ui_layer = CanvasLayer.new()
	ui_layer.name = "PlayerUI"
	add_child(ui_layer)

	health_label = Label.new()
	health_label.name = "HealthLabel"
	health_label.position = Vector2(20.0, 20.0)
	health_label.text = "HEALTH: 100/100"
	health_label.add_theme_font_size_override("font_size", 32)
	ui_layer.add_child(health_label)

	crosshair_label = Label.new()
	crosshair_label.name = "Crosshair"
	crosshair_label.text = "+"
	crosshair_label.add_theme_font_size_override("font_size", 46)
	crosshair_label.set_anchors_preset(Control.PRESET_CENTER)
	crosshair_label.position = Vector2(-12.0, -28.0)
	ui_layer.add_child(crosshair_label)


func update_ui() -> void:
	if health_label == null:
		return

	if player_dead:
		health_label.text = "YOU DIED"
	else:
		health_label.text = "HEALTH: " + str(player_health) + "/" + str(PLAYER_MAX_HEALTH)


func setup_audio() -> void:
	setup_one_audio(gun_shot)
	setup_one_audio(walk_sound)
	setup_one_audio(jump_sound)
	setup_one_audio(land_sound)


func setup_one_audio(sound_node: Node) -> void:
	if sound_node == null:
		return

	if sound_node is AudioStreamPlayer:
		var audio: AudioStreamPlayer = sound_node as AudioStreamPlayer
		audio.volume_db = SOUND_VOLUME_DB
		audio.bus = "Master"
		audio.autoplay = false

	elif sound_node is AudioStreamPlayer2D:
		var audio_2d: AudioStreamPlayer2D = sound_node as AudioStreamPlayer2D
		audio_2d.volume_db = SOUND_VOLUME_DB
		audio_2d.bus = "Master"
		audio_2d.autoplay = false

	elif sound_node is AudioStreamPlayer3D:
		var audio_3d: AudioStreamPlayer3D = sound_node as AudioStreamPlayer3D
		audio_3d.volume_db = SOUND_VOLUME_DB
		audio_3d.bus = "Master"
		audio_3d.autoplay = false
		audio_3d.max_distance = 1000.0
		audio_3d.unit_size = 1.0


func _physics_process(delta: float) -> void:
	update_ui()

	if player_dead:
		return

	var was_on_floor: bool = is_on_floor()

	if fire_timer > 0.0:
		fire_timer -= delta

	camera_recoil = lerp(camera_recoil, 0.0, delta * CAMERA_RECOIL_RECOVER_SPEED)
	gun_recoil = lerp(gun_recoil, 0.0, delta * GUN_RECOIL_RECOVER_SPEED)

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		if velocity.y < 0.0:
			velocity.y = 0.0

		if Input.is_key_pressed(KEY_SPACE):
			velocity.y = JUMP
			play_sound(jump_sound)

	var crouching: bool = Input.is_key_pressed(KEY_SHIFT)

	if crouching:
		sprinting = false

	if head:
		var target_head_height: float = CROUCH_HEAD_HEIGHT if crouching else STAND_HEAD_HEIGHT
		head.position.y = lerp(head.position.y, target_head_height, delta * 12.0)

	if collision and collision.shape and collision.shape is CapsuleShape3D:
		var capsule: CapsuleShape3D = collision.shape as CapsuleShape3D
		var target_capsule_height: float = CROUCH_CAPSULE_HEIGHT if crouching else STAND_CAPSULE_HEIGHT
		capsule.height = lerp(capsule.height, target_capsule_height, delta * 12.0)
		capsule.radius = CAPSULE_RADIUS

	var direction: Vector3 = Vector3.ZERO

	var forward: Vector3 = -global_transform.basis.z
	var right: Vector3 = global_transform.basis.x

	forward.y = 0.0
	right.y = 0.0

	forward = forward.normalized()
	right = right.normalized()

	if Input.is_key_pressed(KEY_W):
		direction += forward
	else:
		sprinting = false

	if Input.is_key_pressed(KEY_S):
		direction -= forward
		sprinting = false

	if Input.is_key_pressed(KEY_A):
		direction -= right

	if Input.is_key_pressed(KEY_D):
		direction += right

	if direction.length() > 0.0:
		direction = direction.normalized()

	var speed: float = SPEED

	if crouching:
		speed = CROUCH_SPEED
	elif sprinting and Input.is_key_pressed(KEY_W):
		speed = SPRINT

	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

	move_and_slide()

	if not was_on_floor and is_on_floor():
		play_sound(land_sound)

	var moving: bool = direction.length() > 0.0 and is_on_floor()
	update_walk_sound(moving, sprinting, crouching)

	var target_roll: float = clamp(last_mouse_x * -0.4, -6.0, 6.0)
	camera_roll = lerp(camera_roll, target_roll, delta * 8.0)

	if head:
		head.rotation_degrees.x = camera_angle - camera_recoil
		head.rotation_degrees.z = camera_roll

	update_gun(delta, moving, crouching)

	global_position.x = clamp(global_position.x, MIN_BOUND, MAX_BOUND)
	global_position.z = clamp(global_position.z, MIN_BOUND, MAX_BOUND)


func update_gun(delta: float, moving: bool, crouching: bool) -> void:
	if gun == null:
		return

	var target_pos: Vector3 = gun_idle_pos
	var target_rot: Vector3 = gun_idle_rot

	if moving:
		target_pos = gun_move_pos
		target_rot = gun_move_rot

	gun_base_pos = gun_base_pos.lerp(target_pos, delta * 8.0)
	gun_base_rot = gun_base_rot.lerp(target_rot, delta * 8.0)

	var bob_offset: Vector3 = Vector3.ZERO
	var rot_offset: Vector3 = Vector3.ZERO

	if moving:
		var bob_speed: float = 8.0
		var bob_strength: float = 0.08
		var rot_strength: float = 2.0

		if sprinting and not crouching:
			bob_speed = 12.0
			bob_strength = 0.15
			rot_strength = 4.0
		elif crouching:
			bob_speed = 5.0
			bob_strength = 0.035
			rot_strength = 1.0

		walk_bob_time += delta * bob_speed

		bob_offset.y = sin(walk_bob_time) * bob_strength
		bob_offset.x = cos(walk_bob_time * 0.5) * (bob_strength * 0.5)

		rot_offset.z = sin(walk_bob_time * 0.5) * rot_strength
		rot_offset.x = cos(walk_bob_time) * (rot_strength * 0.5)
	else:
		walk_bob_time = 0.0
		var pitch: float = clamp(camera_angle, -70.0, 70.0)
		rot_offset.x = -pitch * 0.15

	var crouch_offset: Vector3 = Vector3.ZERO

	if crouching:
		crouch_offset = gun_crouch_offset

	var gun_recoil_offset: Vector3 = Vector3(0.0, gun_recoil * 0.12, gun_recoil * 0.35)

	gun.position = gun_base_pos + bob_offset + crouch_offset + gun_recoil_offset
	gun.rotation_degrees = gun_base_rot + rot_offset
	gun.rotation_degrees.z += camera_roll
	gun.rotation_degrees.x -= gun_recoil * 8.0


func play_sound(sound_node: Node) -> void:
	if sound_node == null:
		return

	if sound_node is AudioStreamPlayer:
		var audio: AudioStreamPlayer = sound_node as AudioStreamPlayer
		if audio.stream == null:
			return
		audio.volume_db = SOUND_VOLUME_DB
		audio.stop()
		audio.play(0.0)

	elif sound_node is AudioStreamPlayer2D:
		var audio_2d: AudioStreamPlayer2D = sound_node as AudioStreamPlayer2D
		if audio_2d.stream == null:
			return
		audio_2d.volume_db = SOUND_VOLUME_DB
		audio_2d.stop()
		audio_2d.play(0.0)

	elif sound_node is AudioStreamPlayer3D:
		var audio_3d: AudioStreamPlayer3D = sound_node as AudioStreamPlayer3D
		if audio_3d.stream == null:
			return
		audio_3d.volume_db = SOUND_VOLUME_DB
		audio_3d.max_distance = 1000.0
		audio_3d.unit_size = 1.0
		audio_3d.stop()
		audio_3d.play(0.0)


func update_walk_sound(moving: bool, sprinting_now: bool, crouching_now: bool) -> void:
	if walk_sound == null:
		return

	var pitch: float = WALK_PITCH

	if sprinting_now and not crouching_now:
		pitch = SPRINT_WALK_PITCH
	elif crouching_now:
		pitch = CROUCH_WALK_PITCH

	if walk_sound is AudioStreamPlayer:
		var audio: AudioStreamPlayer = walk_sound as AudioStreamPlayer
		if audio.stream == null:
			return
		audio.volume_db = SOUND_VOLUME_DB
		audio.pitch_scale = pitch

		if moving and not audio.playing:
			audio.play(0.0)
		elif not moving and audio.playing:
			audio.stop()

	elif walk_sound is AudioStreamPlayer2D:
		var audio_2d: AudioStreamPlayer2D = walk_sound as AudioStreamPlayer2D
		if audio_2d.stream == null:
			return
		audio_2d.volume_db = SOUND_VOLUME_DB
		audio_2d.pitch_scale = pitch

		if moving and not audio_2d.playing:
			audio_2d.play(0.0)
		elif not moving and audio_2d.playing:
			audio_2d.stop()

	elif walk_sound is AudioStreamPlayer3D:
		var audio_3d: AudioStreamPlayer3D = walk_sound as AudioStreamPlayer3D
		if audio_3d.stream == null:
			return
		audio_3d.volume_db = SOUND_VOLUME_DB
		audio_3d.pitch_scale = pitch
		audio_3d.max_distance = 1000.0
		audio_3d.unit_size = 1.0

		if moving and not audio_3d.playing:
			audio_3d.play(0.0)
		elif not moving and audio_3d.playing:
			audio_3d.stop()


func _input(event: InputEvent) -> void:
	if player_dead:
		return

	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))

		camera_angle -= event.relative.y * mouse_sensitivity
		camera_angle = clamp(camera_angle, -90.0, 90.0)

		last_mouse_x = event.relative.x

		if head:
			head.rotation_degrees.x = camera_angle - camera_recoil

	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			shoot()

	if event is InputEventKey:
		if event.pressed and not event.echo:
			if event.keycode == KEY_W:
				var current_time: float = Time.get_ticks_msec() / 1000.0

				if current_time - last_w_tap_time <= DOUBLE_TAP_TIME:
					sprinting = true

				last_w_tap_time = current_time


func shoot() -> void:
	if player_dead:
		return

	if fire_timer > 0.0:
		return

	fire_timer = FIRE_COOLDOWN

	play_sound(gun_shot)

	camera_recoil += CAMERA_RECOIL_AMOUNT
	camera_recoil = clamp(camera_recoil, 0.0, 8.0)

	gun_recoil += GUN_RECOIL_AMOUNT
	gun_recoil = clamp(gun_recoil, 0.0, 0.6)

	var camera: Camera3D = get_viewport().get_camera_3d()

	if camera == null:
		print("No camera found.")
		return

	var start_position: Vector3 = camera.global_position
	var end_position: Vector3 = start_position + (-camera.global_transform.basis.z * SHOOT_RANGE)

	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(start_position, end_position)
	query.exclude = [self]
	query.collide_with_bodies = true
	query.collide_with_areas = false

	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)

	if hit.size() <= 0:
		print("SHOT MISSED")
		return

	var hit_object: Node = hit["collider"] as Node
	var hit_position: Vector3 = hit["position"] as Vector3

	spawn_hit_particles(hit_position)

	print("SHOT HIT: ", hit_object.name)

	var enemy: Node3D = find_enemy_from_hit_object(hit_object)

	if enemy == null:
		print("Hit was not enemy.")
		return

	damage_enemy(enemy)


func damage_enemy(enemy: Node3D) -> void:
	if enemy == null or not is_instance_valid(enemy):
		return

	if enemy.has_method("take_damage"):
		enemy.call("take_damage", PLAYER_DAMAGE)
		return

	if not enemy.has_meta("health"):
		print("Enemy has no health meta.")
		return

	var health: int = int(enemy.get_meta("health"))
	health -= PLAYER_DAMAGE
	enemy.set_meta("health", health)

	print("ENEMY DAMAGED: ", enemy.name, " health=", health)

	if health <= 0:
		enemy.set_meta("dead", true)
		print("ENEMY DEAD: ", enemy.name)


func find_enemy_from_hit_object(hit_object: Node) -> Node3D:
	if hit_object == null:
		return null

	var node: Node = hit_object

	while node != null:
		if node.is_in_group("Enemies") and node is Node3D:
			return node as Node3D

		if node.has_meta("is_enemy") and bool(node.get_meta("is_enemy")) and node is Node3D:
			return node as Node3D

		node = node.get_parent()

	return null


func spawn_hit_particles(hit_position: Vector3) -> void:
	var particles: GPUParticles3D = GPUParticles3D.new()
	particles.name = "HitParticles"

	particles.amount = 40
	particles.lifetime = 0.25
	particles.one_shot = true
	particles.emitting = true
	particles.local_coords = false

	var particle_material: ParticleProcessMaterial = ParticleProcessMaterial.new()
	particle_material.direction = Vector3.UP
	particle_material.spread = 180.0
	particle_material.initial_velocity_min = 3.0
	particle_material.initial_velocity_max = 8.0
	particle_material.gravity = Vector3(0.0, -6.0, 0.0)
	particle_material.scale_min = 0.035
	particle_material.scale_max = 0.08
	particle_material.color = Color(0.9, 0.9, 1.0, 1.0)

	particles.process_material = particle_material

	var particle_mesh: SphereMesh = SphereMesh.new()
	particle_mesh.radius = 0.04
	particle_mesh.height = 0.08
	particles.draw_pass_1 = particle_mesh

	get_tree().current_scene.add_child(particles)
	particles.global_position = hit_position

	await get_tree().create_timer(0.5).timeout

	if is_instance_valid(particles):
		particles.queue_free()


func take_damage(amount: int) -> void:
	if player_dead:
		return

	player_health -= amount
	player_health = max(player_health, 0)

	print("PLAYER TOOK DAMAGE: ", amount, " health=", player_health)
	update_ui()

	if player_health <= 0:
		player_dead = true
		print("PLAYER DIED")

		update_ui()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		set_physics_process(false)
