extends CharacterBody3D

# ---------------- LASER TAG MODE ----------------
const PLAYER_LASER_TAG_MODE: bool = true
const PLAYER_LASER_COLOR: Color = Color(0.05, 1.0, 0.20, 1.0)
const PLAYER_LASER_LIFETIME: float = 0.10
const PLAYER_LASER_WIDTH: float = 0.08

# PLAYER SCRIPT - FUN TEAM BATTLE VERSION
# Put this on CameraRig.
#
# Important fixes:
# - Player is BlueTeam.
# - Player cannot damage BlueTeam NPCs.
# - Player can damage RedTeam NPCs.
# - Headshot kills red in one hit.
# - Body shot takes two hits.
# - You died screen and respawn still work.
# - Terrain hit = dust. Enemy hit = red particles. Friendly hit = no damage.

@onready var head: Node3D = get_node_or_null("Head")
@onready var collision: CollisionShape3D = get_node_or_null("CollisionShape3D") as CollisionShape3D
@onready var gun: Node3D = get_node_or_null("Gun")

@onready var gun_shot: Node = find_child("Gun Shot", true, false)
@onready var walk_sound: Node = find_child("Walk", true, false)
@onready var jump_sound: Node = find_child("Jump", true, false)
@onready var land_sound: Node = find_child("Land", true, false)

const SPEED: float = 6.0
const SPRINT: float = 10.0
const CROUCH_SPEED: float = 3.0
const JUMP: float = 9.0
const GRAVITY: float = 20.0

const MIN_BOUND: float = -490.0
const MAX_BOUND: float = 490.0

const PLAYER_MAX_HEALTH: int = 20
const RESPAWN_HEALTH: int = 20

var player_health: int = PLAYER_MAX_HEALTH
var player_dead: bool = false
var spawn_position: Vector3 = Vector3.ZERO
var spawn_rotation: Vector3 = Vector3.ZERO

const SOUND_VOLUME_DB: float = 24.0
const WALK_PITCH: float = 1.0
const SPRINT_WALK_PITCH: float = 1.55
const CROUCH_WALK_PITCH: float = 0.75

const FIRE_COOLDOWN: float = 0.18
const SHOOT_RANGE: float = 380.0
const BODY_DAMAGE: int = 1
const HEADSHOT_DAMAGE: int = 999

const MAX_AMMO: int = 25
const RELOAD_TIME: float = 5.0
const RELOAD_MOVE_SPEED: float = 1.6

const MAX_STAMINA: float = 500.0
const STAMINA_DRAIN_RATE: float = 28.0
const STAMINA_RECHARGE_RATE: float = 22.0
const MIN_STAMINA_TO_SPRINT: float = 12.0

const CAMERA_RECOIL_AMOUNT: float = 1.15
const CAMERA_RECOIL_RECOVER_SPEED: float = 18.0
const GUN_RECOIL_AMOUNT: float = 0.16
const GUN_RECOIL_RECOVER_SPEED: float = 22.0

const DOUBLE_TAP_TIME: float = 0.25

const STAND_HEAD_HEIGHT: float = 1.6
const CROUCH_HEAD_HEIGHT: float = 0.9
const STAND_CAPSULE_HEIGHT: float = 1.6
const CROUCH_CAPSULE_HEIGHT: float = 0.9
const CAPSULE_RADIUS: float = 0.4

var gun_idle_pos: Vector3 = Vector3(3.585, 0.08, -0.54)
var gun_move_pos: Vector3 = Vector3(-0.47, -0.08, -3.68)
var gun_crouch_offset: Vector3 = Vector3(0.0, -0.45, 0.0)

var gun_idle_rot: Vector3 = Vector3(0.0, -90.0, 0.0)
var gun_move_rot: Vector3 = Vector3(0.0, 0.0, 0.0)

var mouse_sensitivity: float = 0.1
var camera_angle: float = 0.0
var fire_timer: float = 0.0
var camera_recoil: float = 0.0
var gun_recoil: float = 0.0
var last_w_tap_time: float = -10.0
var sprinting: bool = false
var ammo: int = MAX_AMMO
var is_reloading: bool = false
var reload_timer: float = 0.0
var stamina: float = MAX_STAMINA
var walk_bob_time: float = 0.0
var camera_roll: float = 0.0
var last_mouse_x: float = 0.0

var gun_base_pos: Vector3 = Vector3.ZERO
var gun_base_rot: Vector3 = Vector3.ZERO

var ui_layer: CanvasLayer = null
var health_label: Label = null
var health_bar_back: ColorRect = null
var health_bar_fill: ColorRect = null
var stamina_label: Label = null
var stamina_bar_back: ColorRect = null
var stamina_bar_fill: ColorRect = null
var ammo_label: Label = null
var crosshair_label: Label = null
var damage_flash: ColorRect = null
var death_panel: ColorRect = null
var death_label: Label = null

# ---------------- HELICOPTER VEHICLE HANDOFF ----------------
var in_helicopter: bool = false
var active_helicopter: Node3D = null
var stored_player_visible: bool = true
var vehicle_camera: Camera3D = null
var saved_camera_top_level: bool = false
var saved_camera_transform: Transform3D = Transform3D.IDENTITY



func _ready() -> void:
	name = "CameraRig"
	add_to_group("Player")
	add_to_group("BlueTeam")
	set_meta("team", "blue")
	set_meta("is_player", true)

	if collision == null:
		collision = get_node_or_null("CollisionShape") as CollisionShape3D

	spawn_position = global_position
	spawn_rotation = rotation_degrees

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	floor_snap_length = 0.8

	setup_audio()
	create_ui()

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

	print("PLAYER READY")

func create_ui() -> void:
	ui_layer = CanvasLayer.new()
	ui_layer.name = "PlayerUI"
	add_child(ui_layer)

	health_label = Label.new()
	health_label.name = "HealthLabel"
	health_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	health_label.position = Vector2(20.0, -102.0)
	health_label.text = "HP: 20/20"
	health_label.add_theme_font_size_override("font_size", 18)
	ui_layer.add_child(health_label)

	health_bar_back = ColorRect.new()
	health_bar_back.name = "HealthBarBack"
	health_bar_back.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	health_bar_back.position = Vector2(20.0, -76.0)
	health_bar_back.size = Vector2(150.0, 14.0)
	health_bar_back.color = Color(0.05, 0.05, 0.05, 0.90)
	ui_layer.add_child(health_bar_back)

	health_bar_fill = ColorRect.new()
	health_bar_fill.name = "HealthBarFill"
	health_bar_fill.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	health_bar_fill.position = Vector2(22.0, -74.0)
	health_bar_fill.size = Vector2(146.0, 10.0)
	health_bar_fill.color = Color(0.0, 0.75, 0.15, 0.95)
	ui_layer.add_child(health_bar_fill)

	stamina_label = Label.new()
	stamina_label.name = "StaminaLabel"
	stamina_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	stamina_label.position = Vector2(20.0, -58.0)
	stamina_label.text = "STAMINA"
	stamina_label.add_theme_font_size_override("font_size", 14)
	ui_layer.add_child(stamina_label)

	stamina_bar_back = ColorRect.new()
	stamina_bar_back.name = "StaminaBarBack"
	stamina_bar_back.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	stamina_bar_back.position = Vector2(20.0, -36.0)
	stamina_bar_back.size = Vector2(150.0, 12.0)
	stamina_bar_back.color = Color(0.05, 0.05, 0.05, 0.90)
	ui_layer.add_child(stamina_bar_back)

	stamina_bar_fill = ColorRect.new()
	stamina_bar_fill.name = "StaminaBarFill"
	stamina_bar_fill.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	stamina_bar_fill.position = Vector2(22.0, -34.0)
	stamina_bar_fill.size = Vector2(146.0, 8.0)
	stamina_bar_fill.color = Color(0.1, 0.45, 1.0, 0.95)
	ui_layer.add_child(stamina_bar_fill)

	ammo_label = Label.new()
	ammo_label.name = "AmmoLabel"
	ammo_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	ammo_label.position = Vector2(20.0, -22.0)
	ammo_label.text = "AMMO: 25/25"
	ammo_label.add_theme_font_size_override("font_size", 16)
	ui_layer.add_child(ammo_label)

	crosshair_label = Label.new()
	crosshair_label.name = "Crosshair"
	crosshair_label.text = "+"
	crosshair_label.add_theme_font_size_override("font_size", 46)
	crosshair_label.set_anchors_preset(Control.PRESET_CENTER)
	crosshair_label.position = Vector2(-12.0, -28.0)
	ui_layer.add_child(crosshair_label)

	damage_flash = ColorRect.new()
	damage_flash.name = "DamageFlash"
	damage_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	damage_flash.color = Color(0.8, 0.0, 0.0, 0.0)
	damage_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(damage_flash)

	death_panel = ColorRect.new()
	death_panel.name = "DeathPanel"
	death_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	death_panel.color = Color(0.0, 0.0, 0.0, 0.72)
	death_panel.visible = false
	death_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(death_panel)

	death_label = Label.new()
	death_label.name = "DeathLabel"
	death_label.text = "YOU ARE OUT\nPRESS R TO RESPAWN"
	death_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	death_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	death_label.add_theme_font_size_override("font_size", 46)
	death_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	death_label.visible = false
	ui_layer.add_child(death_label)

func update_ui() -> void:
	if health_label:
		health_label.text = "HP: " + str(player_health) + "/" + str(PLAYER_MAX_HEALTH)

	if health_bar_fill:
		var health_ratio: float = clamp(float(player_health) / float(PLAYER_MAX_HEALTH), 0.0, 1.0)
		health_bar_fill.size.x = 146.0 * health_ratio

		if health_ratio > 0.50:
			health_bar_fill.color = Color(0.0, 0.75, 0.15, 0.95)
		elif health_ratio > 0.25:
			health_bar_fill.color = Color(0.95, 0.75, 0.05, 0.95)
		else:
			health_bar_fill.color = Color(0.95, 0.05, 0.05, 0.95)

	if stamina_bar_fill:
		var stamina_ratio: float = clamp(stamina / MAX_STAMINA, 0.0, 1.0)
		stamina_bar_fill.size.x = 146.0 * stamina_ratio

	if stamina_label:
		if sprinting:
			stamina_label.text = "STAMINA - RUN"
		elif stamina < MIN_STAMINA_TO_SPRINT:
			stamina_label.text = "STAMINA - LOW"
		else:
			stamina_label.text = "STAMINA"

	if ammo_label:
		if is_reloading:
			ammo_label.text = "RELOADING: " + str(ceil(reload_timer)) + "s"
		else:
			ammo_label.text = "AMMO: " + str(ammo) + "/" + str(MAX_AMMO)

	if crosshair_label:
		crosshair_label.visible = not player_dead

	if death_panel:
		death_panel.visible = player_dead

	if death_label:
		death_label.visible = player_dead

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



func update_reload(delta: float) -> void:
	if not is_reloading:
		return

	reload_timer -= delta

	if reload_timer <= 0.0:
		reload_timer = 0.0
		ammo = MAX_AMMO
		is_reloading = false


func start_reload() -> void:
	if player_dead:
		return

	if is_reloading:
		return

	if ammo >= MAX_AMMO:
		return

	is_reloading = true
	reload_timer = RELOAD_TIME
	sprinting = false


func update_stamina(delta: float, wants_to_sprint: bool, moving: bool, crouching: bool) -> void:
	if is_reloading or crouching or not moving:
		sprinting = false

	if wants_to_sprint and moving and not crouching and not is_reloading and stamina > MIN_STAMINA_TO_SPRINT:
		sprinting = true

	if sprinting and moving and not crouching and not is_reloading:
		stamina -= STAMINA_DRAIN_RATE * delta
		if stamina <= 0.0:
			stamina = 0.0
			sprinting = false
	else:
		stamina += STAMINA_RECHARGE_RATE * delta
		stamina = min(stamina, MAX_STAMINA)

	if stamina < MIN_STAMINA_TO_SPRINT:
		sprinting = false


func _physics_process(delta: float) -> void:
	update_reload(delta)
	update_ui()
	update_damage_flash(delta)

	if in_helicopter:
		velocity = Vector3.ZERO
		return

	if player_dead:
		velocity = Vector3.ZERO
		if Input.is_key_pressed(KEY_R):
			respawn_player()
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

	var direction: Vector3 = get_move_direction()
	var moving_input: bool = direction.length() > 0.0
	var wants_to_sprint: bool = sprinting and Input.is_key_pressed(KEY_W)
	update_stamina(delta, wants_to_sprint, moving_input, crouching)

	var speed: float = SPEED

	if is_reloading:
		speed = RELOAD_MOVE_SPEED
	elif crouching:
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

func get_move_direction() -> Vector3:
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

	return direction


func update_damage_flash(delta: float) -> void:
	if damage_flash == null:
		return

	var current_color: Color = damage_flash.color
	current_color.a = move_toward(current_color.a, 0.0, delta * 2.8)
	damage_flash.color = current_color


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


func _input(event: InputEvent) -> void:
	if in_helicopter:
		return

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
			if event.keycode == KEY_Q:
				start_reload()

			if event.keycode == KEY_W:
				var current_time: float = Time.get_ticks_msec() / 1000.0

				if current_time - last_w_tap_time <= DOUBLE_TAP_TIME and stamina > MIN_STAMINA_TO_SPRINT and not is_reloading:
					sprinting = true

				last_w_tap_time = current_time


func spawn_player_laser_ray(start_position: Vector3, end_position: Vector3) -> void:
	var direction: Vector3 = end_position - start_position

	if direction.length() < 0.01:
		return

	var laser: MeshInstance3D = MeshInstance3D.new()
	laser.name = "PlayerLaserRay"

	var cylinder: CylinderMesh = CylinderMesh.new()
	cylinder.top_radius = PLAYER_LASER_WIDTH
	cylinder.bottom_radius = PLAYER_LASER_WIDTH
	cylinder.height = direction.length()
	cylinder.radial_segments = 8
	laser.mesh = cylinder

	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = PLAYER_LASER_COLOR
	material.emission_enabled = true
	material.emission = PLAYER_LASER_COLOR
	material.emission_energy_multiplier = 3.0
	laser.material_override = material

	get_tree().current_scene.add_child(laser)

	laser.global_position = start_position + direction * 0.5
	laser.look_at(end_position, Vector3.UP)
	laser.rotate_object_local(Vector3.RIGHT, deg_to_rad(90.0))

	await get_tree().create_timer(PLAYER_LASER_LIFETIME).timeout

	if is_instance_valid(laser):
		laser.queue_free()

func shoot() -> void:
	if player_dead:
		return

	if is_reloading:
		return

	if fire_timer > 0.0:
		return

	if ammo <= 0:
		return

	ammo -= 1
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
	query.exclude = [get_rid()]
	query.collide_with_bodies = true
	query.collide_with_areas = true

	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)

	if hit.size() <= 0:
		spawn_player_laser_ray(start_position, end_position)
		return

	var hit_object: Node = hit["collider"] as Node
	var hit_position: Vector3 = hit["position"] as Vector3

	spawn_player_laser_ray(start_position, hit_position)
	var hit_normal: Vector3 = Vector3.UP

	if hit.has("normal"):
		hit_normal = hit["normal"] as Vector3

	var npc: Node3D = find_npc_from_hit_object(hit_object)
	var hit_zone: String = get_hit_zone(hit_object)

	if npc == null:
		spawn_dust_particles(hit_position, hit_normal)
		return

	var npc_team: String = get_npc_team(npc)

	if npc_team == "blue":
		print("FRIENDLY LASER - NO TAG")
		spawn_dust_particles(hit_position, hit_normal)
		return

	if hit_zone == "head":
		spawn_npc_hit_particles(hit_position, hit_normal, true)
		damage_npc(npc, HEADSHOT_DAMAGE, true)
	else:
		spawn_npc_hit_particles(hit_position, hit_normal, false)
		damage_npc(npc, BODY_DAMAGE, false)


func get_npc_team(npc: Node) -> String:
	if npc == null:
		return ""

	if npc.has_meta("team"):
		return str(npc.get_meta("team"))

	if npc.is_in_group("BlueTeam"):
		return "blue"

	if npc.is_in_group("RedTeam"):
		return "red"

	return ""


func get_hit_zone(hit_object: Node) -> String:
	if hit_object == null:
		return "body"

	var node: Node = hit_object

	while node != null:
		if node.has_meta("hit_zone"):
			return str(node.get_meta("hit_zone"))

		node = node.get_parent()

	return "body"


func find_npc_from_hit_object(hit_object: Node) -> Node3D:
	if hit_object == null:
		return null

	var node: Node = hit_object

	while node != null:
		if node.is_in_group("BattleNPC") and node is Node3D:
			return node as Node3D

		if node.has_meta("npc_root"):
			var npc_root: Node = node.get_meta("npc_root") as Node
			if npc_root != null and npc_root is Node3D:
				return npc_root as Node3D

		node = node.get_parent()

	return null


func damage_npc(npc: Node3D, amount: int, headshot: bool) -> void:
	if npc == null or not is_instance_valid(npc):
		return

	if get_npc_team(npc) == "blue":
		return

	if npc.has_method("take_damage"):
		npc.call("take_damage", amount, headshot)
		return

	if not npc.has_meta("health"):
		return

	var health: int = int(npc.get_meta("health"))
	health -= amount
	npc.set_meta("health", health)

	if health <= 0:
		npc.set_meta("dead", true)
		notify_battle_manager_player_kill(headshot)


func take_damage(amount: int) -> void:
	if player_dead:
		return

	player_health -= amount
	player_health = max(player_health, 0)

	if damage_flash != null:
		damage_flash.color = Color(0.8, 0.0, 0.0, 0.38)

	update_ui()

	if player_health <= 0:
		die()


func die() -> void:
	player_dead = true
	velocity = Vector3.ZERO
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	update_ui()




# ---------------- HELICOPTER VEHICLE HANDOFF ----------------
func enter_helicopter(helicopter: Node3D) -> void:
	if helicopter == null or not is_instance_valid(helicopter):
		return

	if player_dead:
		return

	in_helicopter = true
	active_helicopter = helicopter
	set_meta("in_helicopter", true)
	set_meta("active_helicopter_id", helicopter.get_instance_id())
	velocity = Vector3.ZERO
	stored_player_visible = visible
	vehicle_camera = get_player_camera()
	if vehicle_camera != null:
		saved_camera_top_level = vehicle_camera.top_level
		saved_camera_transform = vehicle_camera.transform
		vehicle_camera.current = true

	# Do NOT set the whole player invisible here. That can also hide the camera/UI.
	# The helicopter now moves this player's existing camera while the player is piloting.
	set_player_vehicle_visuals(false)

	if collision:
		collision.disabled = true

	if walk_sound != null:
		if walk_sound is AudioStreamPlayer:
			(walk_sound as AudioStreamPlayer).stop()
		elif walk_sound is AudioStreamPlayer2D:
			(walk_sound as AudioStreamPlayer2D).stop()
		elif walk_sound is AudioStreamPlayer3D:
			(walk_sound as AudioStreamPlayer3D).stop()

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func exit_helicopter(exit_position: Vector3, exit_rotation_y: float) -> void:
	in_helicopter = false
	active_helicopter = null
	set_meta("in_helicopter", false)
	if has_meta("active_helicopter_id"):
		remove_meta("active_helicopter_id")
	visible = stored_player_visible
	set_player_vehicle_visuals(true)
	global_position = exit_position
	rotation.y = exit_rotation_y
	velocity = Vector3.ZERO
	sprinting = false
	camera_angle = 0.0
	camera_recoil = 0.0
	gun_recoil = 0.0

	if head:
		head.rotation_degrees = Vector3.ZERO
		head.position.y = STAND_HEAD_HEIGHT

	if vehicle_camera != null and is_instance_valid(vehicle_camera):
		vehicle_camera.top_level = saved_camera_top_level
		vehicle_camera.transform = saved_camera_transform
		vehicle_camera.current = true
	vehicle_camera = null

	if collision:
		collision.disabled = false

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func set_vehicle_camera_pose(camera_world_position: Vector3, yaw_degrees: float, pitch_degrees: float) -> void:
	# Called by the helicopter while the player is inside it.
	# IMPORTANT: The actual Camera3D is placed in world space.
	# This prevents the camera from inheriting any side offset from the player's Head/Gun setup.
	if not in_helicopter:
		return

	velocity = Vector3.ZERO
	global_position = camera_world_position - Vector3(0.0, STAND_HEAD_HEIGHT, 0.0)
	rotation_degrees.y = yaw_degrees

	camera_angle = clamp(pitch_degrees, -75.0, 55.0)
	camera_recoil = lerp(camera_recoil, 0.0, 0.25)
	gun_recoil = lerp(gun_recoil, 0.0, 0.25)

	if head:
		head.position.y = STAND_HEAD_HEIGHT
		head.rotation_degrees = Vector3.ZERO

	if vehicle_camera == null or not is_instance_valid(vehicle_camera):
		vehicle_camera = get_player_camera()

	if vehicle_camera != null:
		vehicle_camera.top_level = true
		vehicle_camera.current = true
		vehicle_camera.global_position = camera_world_position
		vehicle_camera.global_rotation_degrees = Vector3(camera_angle - camera_recoil, yaw_degrees, 0.0)


func set_player_vehicle_visuals(show_visuals: bool) -> void:
	# Hide first-person gun while flying, but keep the camera and UI alive.
	if gun:
		gun.visible = show_visuals

	# Hide obvious body meshes if they are direct children, but never hide Head or PlayerUI.
	for child in get_children():
		if child == head or child == ui_layer:
			continue

		if child is MeshInstance3D:
			(child as MeshInstance3D).visible = show_visuals


func get_player_camera() -> Camera3D:
	var current_camera: Camera3D = get_viewport().get_camera_3d()
	if current_camera != null:
		return current_camera

	var cameras: Array[Node] = find_children("*", "Camera3D", true, false)
	for node in cameras:
		if node is Camera3D:
			return node as Camera3D

	return null



func respawn_player() -> void:
	in_helicopter = false
	active_helicopter = null
	set_meta("in_helicopter", false)
	if has_meta("active_helicopter_id"):
		remove_meta("active_helicopter_id")
	visible = stored_player_visible
	set_player_vehicle_visuals(true)
	if vehicle_camera != null and is_instance_valid(vehicle_camera):
		vehicle_camera.top_level = saved_camera_top_level
		vehicle_camera.transform = saved_camera_transform
		vehicle_camera.current = true
	vehicle_camera = null

	set_meta("team", "blue") # keep team on respawn
	set_meta("is_player", true)
	player_dead = false
	player_health = RESPAWN_HEALTH
	ammo = MAX_AMMO
	is_reloading = false
	reload_timer = 0.0
	stamina = MAX_STAMINA
	sprinting = false
	global_position = spawn_position
	rotation_degrees = spawn_rotation
	velocity = Vector3.ZERO
	camera_angle = 0.0
	camera_recoil = 0.0
	gun_recoil = 0.0

	if head:
		head.rotation_degrees = Vector3.ZERO

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	update_ui()


func spawn_dust_particles(hit_position: Vector3, hit_normal: Vector3) -> void:
	if PLAYER_LASER_TAG_MODE:
		return

	spawn_particle_burst(
		hit_position + hit_normal * 0.03,
		hit_normal,
		Color(0.55, 0.48, 0.38, 1.0),
		Color(0.85, 0.77, 0.62, 1.0),
		30,
		0.35,
		0.045,
		0.11,
		2.0,
		7.0
	)


func spawn_npc_hit_particles(hit_position: Vector3, hit_normal: Vector3, headshot: bool) -> void:
	if PLAYER_LASER_TAG_MODE:
		return

	var amount: int = 38

	if headshot:
		amount = 65

	spawn_particle_burst(
		hit_position + hit_normal * 0.04,
		hit_normal,
		Color(0.42, 0.0, 0.0, 1.0),
		Color(0.95, 0.04, 0.02, 1.0),
		amount,
		0.35,
		0.035,
		0.09,
		4.0,
		11.0
	)


func spawn_particle_burst(
	hit_position: Vector3,
	hit_normal: Vector3,
	color_a: Color,
	color_b: Color,
	amount: int,
	lifetime: float,
	scale_min: float,
	scale_max: float,
	velocity_min: float,
	velocity_max: float
) -> void:
	if PLAYER_LASER_TAG_MODE:
		return

	var particles: GPUParticles3D = GPUParticles3D.new()
	particles.name = "ImpactParticles"
	particles.amount = amount
	particles.lifetime = lifetime
	particles.one_shot = true
	particles.emitting = true
	particles.local_coords = false

	var particle_material: ParticleProcessMaterial = ParticleProcessMaterial.new()
	particle_material.direction = hit_normal.normalized()
	particle_material.spread = 70.0
	particle_material.initial_velocity_min = velocity_min
	particle_material.initial_velocity_max = velocity_max
	particle_material.gravity = Vector3(0.0, -7.5, 0.0)
	particle_material.scale_min = scale_min
	particle_material.scale_max = scale_max
	particle_material.color = color_a
	particle_material.color_ramp = make_two_color_ramp(color_a, color_b)

	particles.process_material = particle_material

	var particle_mesh: SphereMesh = SphereMesh.new()
	particle_mesh.radius = 0.04
	particle_mesh.height = 0.08
	particles.draw_pass_1 = particle_mesh

	get_tree().current_scene.add_child(particles)
	particles.global_position = hit_position

	await get_tree().create_timer(lifetime + 0.25).timeout

	if is_instance_valid(particles):
		particles.queue_free()


func make_two_color_ramp(color_a: Color, color_b: Color) -> GradientTexture1D:
	var gradient: Gradient = Gradient.new()
	gradient.set_color(0, color_a)
	gradient.set_color(1, color_b)

	var texture: GradientTexture1D = GradientTexture1D.new()
	texture.gradient = gradient
	return texture


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


func notify_battle_manager_player_kill(headshot: bool) -> void:
	var battle_manager: Node = get_tree().current_scene.find_child("BattleManager", true, false)

	if battle_manager == null:
		battle_manager = get_tree().current_scene.find_child("EnemyManager", true, false)

	if battle_manager == null:
		return

	if battle_manager.has_method("record_player_kill"):
		battle_manager.call("record_player_kill", headshot)
