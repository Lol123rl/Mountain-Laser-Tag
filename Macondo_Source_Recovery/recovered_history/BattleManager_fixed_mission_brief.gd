extends Node3D

# ---------------- ACTUAL MODE TIMER CONSTANTS ----------------
const MATCH_TIME_LIMIT: float = 15.0 * 60.0
const TEAM_ELIMINATION_TIME_LIMIT: float = 15.0 * 60.0
const MANHUNT_TIME_LIMIT: float = 4.0 * 60.0
const CTF_TIME_LIMIT: float = 12.0 * 60.0
const COMMANDER_TIME_LIMIT: float = 12.0 * 60.0
const KING_HILL_TIME_LIMIT: float = 10.0 * 60.0
const FINAL_BOSS_TIME_LIMIT: float = 999999.0


# ---------------- MINI MAP DRAW CONTROL ----------------
class MiniMapPanel:
	extends Control

	var manager: Node = null
	var redraw_timer: float = 0.0
	const REDRAW_INTERVAL: float = 0.15 # 10 minimap redraws per second is smoother than redrawing every frame.

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_process(true)

	func _process(delta: float) -> void:
		redraw_timer -= delta
		if redraw_timer <= 0.0:
			redraw_timer = REDRAW_INTERVAL
			queue_redraw()

	func _draw() -> void:
		if manager == null:
			return

		if manager.has_method("draw_minimap_content"):
			manager.call("draw_minimap_content", self)


# ---------------- MOUNTAIN LASER TAG TITLE DRAW CONTROL ----------------
class MountainTitlePanel:
	extends Control

	var anim_time: float = 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		process_mode = Node.PROCESS_MODE_ALWAYS
		set_process(true)

	func _process(delta: float) -> void:
		anim_time += delta
		queue_redraw()

	func _draw() -> void:
		var s: Vector2 = size
		if s.x <= 1.0 or s.y <= 1.0:
			return

		# Night sky layers.
		draw_rect(Rect2(Vector2.ZERO, s), Color(0.01, 0.015, 0.045, 1.0), true)
		draw_rect(Rect2(Vector2(0.0, s.y * 0.35), Vector2(s.x, s.y * 0.65)), Color(0.02, 0.035, 0.085, 0.72), true)

		# Stars.
		for i in range(80):
			var x: float = fposmod(float(i * 97), s.x)
			var y: float = fposmod(float(i * 43), s.y * 0.46)
			var pulse: float = 0.45 + 0.35 * sin(anim_time * 1.7 + float(i))
			draw_circle(Vector2(x, y), 1.0 + pulse, Color(0.7, 0.9, 1.0, 0.25 + pulse * 0.45))

		# Moon.
		var moon_pos: Vector2 = Vector2(s.x * 0.80, s.y * 0.16)
		draw_circle(moon_pos, 42.0, Color(0.62, 0.76, 1.0, 0.12))
		draw_circle(moon_pos, 26.0, Color(0.78, 0.88, 1.0, 0.75))
		draw_circle(moon_pos + Vector2(10.0, -7.0), 24.0, Color(0.01, 0.015, 0.045, 0.88))

		# Back mountains.
		var back: PackedVector2Array = PackedVector2Array([
			Vector2(0.0, s.y * 0.64),
			Vector2(s.x * 0.14, s.y * 0.42),
			Vector2(s.x * 0.28, s.y * 0.58),
			Vector2(s.x * 0.44, s.y * 0.32),
			Vector2(s.x * 0.61, s.y * 0.57),
			Vector2(s.x * 0.76, s.y * 0.39),
			Vector2(s.x, s.y * 0.62),
			Vector2(s.x, s.y),
			Vector2(0.0, s.y)
		])
		draw_colored_polygon(back, Color(0.07, 0.10, 0.16, 1.0))

		# Snow caps.
		draw_colored_polygon(PackedVector2Array([Vector2(s.x*0.10,s.y*0.48),Vector2(s.x*0.14,s.y*0.42),Vector2(s.x*0.19,s.y*0.48),Vector2(s.x*0.15,s.y*0.46)]), Color(0.58,0.75,0.95,0.65))
		draw_colored_polygon(PackedVector2Array([Vector2(s.x*0.39,s.y*0.40),Vector2(s.x*0.44,s.y*0.32),Vector2(s.x*0.50,s.y*0.42),Vector2(s.x*0.44,s.y*0.38)]), Color(0.64,0.82,1.0,0.72))
		draw_colored_polygon(PackedVector2Array([Vector2(s.x*0.71,s.y*0.45),Vector2(s.x*0.76,s.y*0.39),Vector2(s.x*0.82,s.y*0.46),Vector2(s.x*0.76,s.y*0.43)]), Color(0.58,0.75,0.95,0.65))

		# Front mountains / tree line.
		var front: PackedVector2Array = PackedVector2Array([
			Vector2(0.0, s.y * 0.82),
			Vector2(s.x * 0.14, s.y * 0.66),
			Vector2(s.x * 0.29, s.y * 0.75),
			Vector2(s.x * 0.45, s.y * 0.58),
			Vector2(s.x * 0.60, s.y * 0.76),
			Vector2(s.x * 0.78, s.y * 0.61),
			Vector2(s.x, s.y * 0.78),
			Vector2(s.x, s.y),
			Vector2(0.0, s.y)
		])
		draw_colored_polygon(front, Color(0.025, 0.055, 0.065, 1.0))

		# Laser beams sweeping over the mountains.
		var sweep: float = sin(anim_time * 1.15)
		var left_origin: Vector2 = Vector2(s.x * 0.10, s.y * 0.78)
		var right_origin: Vector2 = Vector2(s.x * 0.90, s.y * 0.73)
		var left_target: Vector2 = Vector2(s.x * (0.48 + sweep * 0.10), s.y * (0.34 + 0.04 * cos(anim_time)))
		var right_target: Vector2 = Vector2(s.x * (0.52 - sweep * 0.10), s.y * (0.36 + 0.05 * sin(anim_time * 1.2)))
		draw_line(left_origin, left_target, Color(0.0, 1.0, 0.20, 0.22), 12.0)
		draw_line(left_origin, left_target, Color(0.0, 1.0, 0.20, 0.92), 3.0)
		draw_line(right_origin, right_target, Color(1.0, 0.05, 0.03, 0.22), 12.0)
		draw_line(right_origin, right_target, Color(1.0, 0.05, 0.03, 0.92), 3.0)

		# Small laser-tag players.
		draw_circle(left_origin, 9.0, Color(0.0, 1.0, 0.20, 1.0))
		draw_circle(right_origin, 9.0, Color(1.0, 0.05, 0.03, 1.0))
		draw_circle(left_origin, 14.0, Color(0.0, 1.0, 0.20, 0.16))
		draw_circle(right_origin, 14.0, Color(1.0, 0.05, 0.03, 0.16))

		# Center glass command card behind the whole menu.
		# Taller and slightly higher so every title button stays inside the border.
		var card_size: Vector2 = Vector2(min(1180.0, s.x * 0.87), min(830.0, s.y * 0.92))
		var card_pos: Vector2 = Vector2((s.x - card_size.x) * 0.5, max(34.0, s.y * 0.045))
		draw_rect(Rect2(card_pos + Vector2(7.0, 9.0), card_size), Color(0.0, 0.0, 0.0, 0.36), true)
		draw_rect(Rect2(card_pos, card_size), Color(0.02, 0.04, 0.08, 0.72), true)
		draw_rect(Rect2(card_pos, card_size), Color(0.25, 0.85, 1.0, 0.35), false, 2.0)


# ---------------- RESULT SCREEN ART DRAW CONTROL ----------------
class ResultArtPanel:
	extends Control

	var manager: Node = null
	var anim_time: float = 0.0
	var result_text: String = ""
	var mode_name: String = ""

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		process_mode = Node.PROCESS_MODE_ALWAYS
		set_process(true)

	func _process(delta: float) -> void:
		anim_time += delta
		queue_redraw()

	func _draw() -> void:
		var s: Vector2 = size
		if s.x <= 1.0 or s.y <= 1.0:
			return

		var is_victory: bool = result_text.begins_with("VICTORY")
		var is_defeat: bool = result_text.begins_with("DEFEAT")
		var is_boss: bool = mode_name == "final_boss"

		draw_result_background(s, is_victory, is_defeat)

		if is_boss and is_victory:
			draw_final_boss_fireworks(s)
		elif mode_name == "capture_the_flag":
			draw_capture_the_flag_art(s, is_victory)
		elif mode_name == "manhunt":
			draw_manhunt_art(s, is_victory)
		elif mode_name == "king_of_the_hill":
			draw_king_hill_art(s, is_victory)
		elif mode_name == "commander":
			draw_commander_art(s, is_victory)
		else:
			draw_team_elimination_art(s, is_victory)

	func draw_result_background(s: Vector2, is_victory: bool, is_defeat: bool) -> void:
		var top_color: Color = Color(0.02, 0.03, 0.08, 0.95)
		var lower_color: Color = Color(0.0, 0.0, 0.0, 0.92)

		if is_victory:
			top_color = Color(0.0, 0.08, 0.12, 0.96)
			lower_color = Color(0.0, 0.02, 0.04, 0.94)
		elif is_defeat:
			top_color = Color(0.12, 0.02, 0.02, 0.96)
			lower_color = Color(0.03, 0.0, 0.0, 0.94)

		draw_rect(Rect2(Vector2.ZERO, s), lower_color, true)
		draw_rect(Rect2(Vector2.ZERO, Vector2(s.x, s.y * 0.50)), top_color, true)

		for i in range(36):
			var x: float = fposmod(float(i * 89) + anim_time * 10.0, s.x)
			var y: float = fposmod(float(i * 47), s.y)
			var alpha: float = 0.08 + 0.05 * sin(anim_time * 1.5 + float(i))
			draw_circle(Vector2(x, y), 2.0, Color(0.65, 0.9, 1.0, alpha))

	func draw_team_elimination_art(s: Vector2, is_victory: bool) -> void:
		var center: Vector2 = Vector2(s.x * 0.5, s.y * 0.50)
		var left: Vector2 = Vector2(s.x * 0.23, s.y * 0.56)
		var right: Vector2 = Vector2(s.x * 0.77, s.y * 0.56)

		draw_line(left, right, Color(0.05, 1.0, 0.25, 0.22), 20.0)
		draw_line(left, right, Color(0.05, 1.0, 0.25, 0.95), 4.0)
		draw_line(Vector2(left.x, right.y), Vector2(right.x, left.y), Color(1.0, 0.05, 0.03, 0.22), 20.0)
		draw_line(Vector2(left.x, right.y), Vector2(right.x, left.y), Color(1.0, 0.05, 0.03, 0.95), 4.0)

		draw_soldier(left, Color(0.05, 1.0, 0.25, 1.0))
		draw_soldier(right, Color(1.0, 0.05, 0.03, 1.0))
		draw_circle(center, 26.0 + sin(anim_time * 5.0) * 3.0, Color(1.0, 0.9, 0.2, 0.35))

	func draw_capture_the_flag_art(s: Vector2, is_victory: bool) -> void:
		var base: Vector2 = Vector2(s.x * 0.50, s.y * 0.72)
		var runner: Vector2 = Vector2(s.x * (0.37 + 0.03 * sin(anim_time * 2.0)), s.y * 0.58)
		var flag_top: Vector2 = runner + Vector2(18.0, -78.0)

		draw_line(Vector2(s.x * 0.15, s.y * 0.73), Vector2(s.x * 0.85, s.y * 0.73), Color(0.25, 0.55, 0.30, 1.0), 8.0)
		draw_soldier(runner, Color(0.05, 1.0, 0.25, 1.0))
		draw_line(runner + Vector2(18.0, -10.0), flag_top, Color(0.9, 0.9, 0.9, 1.0), 4.0)

		var flag: PackedVector2Array = PackedVector2Array([
			flag_top,
			flag_top + Vector2(92.0, 14.0),
			flag_top + Vector2(0.0, 36.0)
		])
		draw_colored_polygon(flag, Color(0.05, 1.0, 0.25, 0.95) if is_victory else Color(1.0, 0.05, 0.03, 0.95))

		draw_rect(Rect2(base - Vector2(70.0, 18.0), Vector2(140.0, 36.0)), Color(0.2, 0.25, 0.28, 1.0), true)
		draw_rect(Rect2(base - Vector2(72.0, 20.0), Vector2(144.0, 40.0)), Color(0.8, 0.9, 1.0, 0.35), false, 3.0)

	func draw_manhunt_art(s: Vector2, is_victory: bool) -> void:
		var target_pos: Vector2 = Vector2(s.x * 0.52, s.y * 0.52)
		var hunter_pos: Vector2 = Vector2(s.x * 0.26, s.y * 0.62)
		var scan_radius: float = 70.0 + 8.0 * sin(anim_time * 3.0)

		draw_circle(target_pos, scan_radius, Color(1.0, 0.85, 0.2, 0.10))
		draw_arc(target_pos, scan_radius, 0.0, TAU, 48, Color(1.0, 0.85, 0.2, 0.6), 3.0)
		draw_soldier(target_pos, Color(0.05, 1.0, 0.25, 1.0) if is_victory else Color(1.0, 0.05, 0.03, 1.0))
		draw_soldier(hunter_pos, Color(1.0, 0.05, 0.03, 1.0))
		draw_line(hunter_pos + Vector2(16.0, -26.0), target_pos, Color(1.0, 0.05, 0.03, 0.85), 3.0)

	func draw_king_hill_art(s: Vector2, is_victory: bool) -> void:
		var hill: PackedVector2Array = PackedVector2Array([
			Vector2(s.x * 0.22, s.y * 0.75),
			Vector2(s.x * 0.50, s.y * 0.36),
			Vector2(s.x * 0.78, s.y * 0.75)
		])
		draw_colored_polygon(hill, Color(0.12, 0.22, 0.16, 1.0))
		draw_arc(Vector2(s.x * 0.50, s.y * 0.56), 120.0, 0.0, TAU, 80, Color(0.05, 1.0, 0.25, 0.75) if is_victory else Color(1.0, 0.05, 0.03, 0.75), 5.0)
		draw_soldier(Vector2(s.x * 0.50, s.y * 0.45), Color(0.05, 1.0, 0.25, 1.0) if is_victory else Color(1.0, 0.05, 0.03, 1.0))

	func draw_commander_art(s: Vector2, is_victory: bool) -> void:
		var commander: Vector2 = Vector2(s.x * 0.50, s.y * 0.52)
		draw_circle(commander, 76.0, Color(0.05, 1.0, 0.25, 0.10) if is_victory else Color(1.0, 0.05, 0.03, 0.10))
		draw_arc(commander, 76.0, 0.0, TAU, 72, Color(0.85, 0.95, 1.0, 0.8), 3.0)
		draw_soldier(commander, Color(0.05, 1.0, 0.25, 1.0) if is_victory else Color(1.0, 0.05, 0.03, 1.0))
		draw_line(commander + Vector2(-120.0, 70.0), commander, Color(0.05, 1.0, 0.25, 0.65), 4.0)
		draw_line(commander + Vector2(120.0, 70.0), commander, Color(0.05, 1.0, 0.25, 0.65), 4.0)
		draw_soldier(commander + Vector2(-120.0, 70.0), Color(0.05, 1.0, 0.25, 0.75))
		draw_soldier(commander + Vector2(120.0, 70.0), Color(0.05, 1.0, 0.25, 0.75))

	func draw_final_boss_fireworks(s: Vector2) -> void:
		var boss_center: Vector2 = Vector2(s.x * 0.50, s.y * 0.58)

		draw_circle(boss_center, 96.0, Color(1.0, 0.05, 0.03, 0.15))
		draw_soldier(boss_center, Color(0.55, 0.05, 0.05, 1.0), 2.2)
		draw_line(Vector2(s.x * 0.25, s.y * 0.78), Vector2(s.x * 0.75, s.y * 0.78), Color(0.05, 1.0, 0.25, 0.9), 6.0)

		for i in range(7):
			var burst_center: Vector2 = Vector2(
				s.x * (0.18 + 0.11 * float(i)),
				s.y * (0.20 + 0.10 * sin(float(i) * 1.9))
			)
			var phase: float = anim_time * 3.0 + float(i)
			var radius: float = 22.0 + 16.0 * abs(sin(phase))
			for j in range(12):
				var angle: float = TAU * float(j) / 12.0
				var a: Vector2 = burst_center + Vector2(cos(angle), sin(angle)) * radius * 0.35
				var b: Vector2 = burst_center + Vector2(cos(angle), sin(angle)) * radius
				var color: Color = Color(1.0, 0.78, 0.18, 0.75)
				if i % 2 == 0:
					color = Color(0.05, 1.0, 0.35, 0.75)
				draw_line(a, b, color, 3.0)

	func draw_soldier(pos: Vector2, color: Color, scale_value: float = 1.0) -> void:
		draw_circle(pos + Vector2(0.0, -36.0) * scale_value, 13.0 * scale_value, color)
		draw_rect(Rect2(pos + Vector2(-13.0, -24.0) * scale_value, Vector2(26.0, 42.0) * scale_value), color, true)
		draw_line(pos + Vector2(-13.0, -4.0) * scale_value, pos + Vector2(-34.0, 12.0) * scale_value, color, 5.0 * scale_value)
		draw_line(pos + Vector2(13.0, -4.0) * scale_value, pos + Vector2(40.0, -12.0) * scale_value, color, 5.0 * scale_value)
		draw_line(pos + Vector2(-7.0, 18.0) * scale_value, pos + Vector2(-22.0, 52.0) * scale_value, color, 5.0 * scale_value)
		draw_line(pos + Vector2(7.0, 18.0) * scale_value, pos + Vector2(22.0, 52.0) * scale_value, color, 5.0 * scale_value)



# ---------------- SIMPLE RESULT FIREWORKS DRAW CONTROL ----------------
class SimpleResultFireworksPanel:
	extends Control

	var anim_time: float = 0.0
	var enabled_fireworks: bool = false

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		process_mode = Node.PROCESS_MODE_ALWAYS
		set_process(true)

	func _process(delta: float) -> void:
		anim_time += delta
		queue_redraw()

	func _draw() -> void:
		if not enabled_fireworks:
			return

		var s: Vector2 = size
		if s.x <= 1.0 or s.y <= 1.0:
			return

		for i in range(9):
			var cx: float = s.x * (0.12 + float(i) * 0.095)
			var cy: float = s.y * (0.18 + 0.10 * sin(float(i) * 1.7))
			var radius: float = 26.0 + 22.0 * abs(sin(anim_time * 2.4 + float(i)))
			for j in range(16):
				var angle: float = TAU * float(j) / 16.0
				var a: Vector2 = Vector2(cx, cy) + Vector2(cos(angle), sin(angle)) * radius * 0.35
				var b: Vector2 = Vector2(cx, cy) + Vector2(cos(angle), sin(angle)) * radius
				var color: Color = Color(0.05, 1.0, 0.35, 0.75)
				if i % 3 == 1:
					color = Color(1.0, 0.75, 0.10, 0.75)
				elif i % 3 == 2:
					color = Color(0.4, 0.8, 1.0, 0.75)

				draw_line(a, b, color, 3.0)


# ---------------- LASER TAG MODE ----------------
const LASER_TAG_MODE: bool = true
const RED_LASER_COLOR: Color = Color(1.0, 0.05, 0.03, 1.0)
const BLUE_LASER_COLOR: Color = Color(0.05, 1.0, 0.20, 1.0)
const LASER_LIFETIME: float = 0.10
const LASER_WIDTH: float = 0.08
const CHEST_PLATE_SCALE: Vector3 = Vector3(0.88, 0.54, 0.08)


# ---------------- FUN TARGETING / REPATH FIX CONSTANTS ----------------
const PLAYER_TARGET_SCORE_RANDOM_MIN: float = -35.0
const PLAYER_TARGET_SCORE_RANDOM_MAX: float = 25.0
const RED_PLAYER_SLIGHT_TARGET_BONUS: float = 28.0
const RED_PLAYER_TARGET_CLOSE_EXTRA_BONUS: float = 35.0
const RED_PLAYER_TARGET_CLOSE_DISTANCE: float = 75.0
const STUCK_REPATH_TIME: float = 0.85
const STUCK_REPATH_SIDE_STEP: float = 36.0
const STUCK_REPATH_FORWARD_STEP: float = 22.0

# ---------------- SMOOTHER GAMEPLAY SETTINGS ----------------
# Lower active NPC count if the game stutters. 6 per side keeps the teams balanced.
const SMOOTH_GAMEPLAY_MODE: bool = true
const SMOOTH_MAX_ACTIVE_UNITS_PER_TEAM: int = 7
const BATTLE_UI_UPDATE_INTERVAL: float = 0.16
var battle_ui_update_timer: float = 0.0
var expensive_cleanup_timer: float = 0.0
var expensive_sanitize_timer: float = 0.0

# ---------------- SMARTER NPC SEARCH / PATHING ----------------
# These values stop soldiers from magically locking onto enemies across the whole map.
# Far away soldiers search, scout, flank, or hide until an enemy gets close enough.
const NPC_DETECT_DISTANCE: float = 135.0
const NPC_LOS_DETECT_DISTANCE: float = 230.0
const NPC_LOST_TARGET_DISTANCE: float = 175.0
const NPC_SEARCH_POINT_REACHED_DISTANCE: float = 10.0
const NPC_SEARCH_REPICK_TIME_MIN: float = 4.5
const NPC_SEARCH_REPICK_TIME_MAX: float = 9.0
const NPC_AMBUSH_DETECT_DISTANCE: float = 95.0
const NPC_AMBUSH_SHOOT_DISTANCE_BONUS: float = 35.0
const NPC_REPATH_TEST_DISTANCE: float = 42.0
const NPC_REPATH_TIME: float = 2.35
const NPC_WALL_RAY_HEIGHT_LOW: float = 0.45
const NPC_WALL_RAY_HEIGHT_HIGH: float = 1.35


# BATTLE MANAGER - CRASH SAFE SHOOTING FIX
#
# This version is built to stop the crash that happens when red tries to shoot.
# Main safety changes:
# - Bullets no longer store the shooter node. They store only team text.
# - Bullets exclude whole friendly teams from raycasts.
# - Target checks are safer before reading global_position.
# - Line-of-sight ignores friendly soldiers so red can actually shoot.
# - No friendly fire.
# - NPCs stay inside the same x/z bounds as the player.
# - Spawn immunity fades white-to-color instead of blinking.
# - Red does not only target the player. Red splits targets between player and blue.

const PLAYER_NODE_NAME: String = "CameraRig"


const MIN_BOUND: float = -490.0
const MAX_BOUND: float = 490.0
const FALL_RESET_Y: float = -120.0

# ---------------- MINI MAP ----------------
const MINIMAP_SIZE: float = 200.0
const MINIMAP_MARGIN_RIGHT: float = 20.0
const MINIMAP_MARGIN_TOP: float = 20.0
const MINIMAP_DOT_SIZE: float = 4.5
const MINIMAP_PLAYER_DOT_SIZE: float = 6.5
const MINIMAP_HELI_DOT_SIZE: float = 7.5
const MINIMAP_FLAG_DOT_SIZE: float = 8.5

# ---------------- GAME MODES ----------------
const GAME_MODE_ELIMINATION: String = "elimination"
const GAME_MODE_CTF: String = "capture_the_flag"
const GAME_MODE_MANHUNT: String = "manhunt"
const GAME_MODE_COMMANDER: String = "commander"
const GAME_MODE_KING_HILL: String = "king_of_the_hill"
const GAME_MODE_FINAL_BOSS: String = "final_boss"

const GAME_MODE_LIST: Array[String] = [
	GAME_MODE_ELIMINATION,
	GAME_MODE_CTF,
	GAME_MODE_MANHUNT,
	GAME_MODE_COMMANDER,
	GAME_MODE_KING_HILL,
	GAME_MODE_FINAL_BOSS
]

const CTF_CAPTURE_LIMIT: int = 2
const CTF_FLAG_PICKUP_DISTANCE: float = 6.5
const CTF_FLAG_CAPTURE_DISTANCE: float = 8.5
const CTF_FLAG_RETURN_HEIGHT: float = 2.0
const CTF_CARRIER_FLAG_HEIGHT: float = 2.8
const CTF_FLAG_BOB_SPEED: float = 2.2
const CTF_FLAG_BOB_AMOUNT: float = 0.35

# Better Capture the Flag CPU behavior.
const CTF_ATTACKER_ROLE: String = "attacker"
const CTF_DEFENDER_ROLE: String = "defender"
const CTF_HUNTER_ROLE: String = "hunter"
const CTF_ESCORT_ROLE: String = "escort"
const CTF_MIDFIELD_ROLE: String = "midfield"
const CTF_DEFENDER_RADIUS: float = 42.0
const CTF_HUNTER_REPATH_TIME_MIN: float = 0.45
const CTF_HUNTER_REPATH_TIME_MAX: float = 0.95
const CTF_NORMAL_REPATH_TIME_MIN: float = 1.0
const CTF_NORMAL_REPATH_TIME_MAX: float = 2.2
const CTF_ATTACK_FLANK_WIDTH: float = 115.0
const CTF_ESCORT_DISTANCE: float = 15.0

# ---------------- EXTRA GAME MODES ----------------
const MANHUNT_HIDE_RADIUS: float = 210.0
const MANHUNT_HUNTER_REPATH_TIME: float = 0.55
const MANHUNT_ESCORT_RADIUS: float = 32.0
const MANHUNT_TARGET_MARKER_HEIGHT: float = 3.8

const COMMANDER_MARKER_HEIGHT: float = 4.2
const COMMANDER_GUARD_RADIUS: float = 35.0
const COMMANDER_ATTACKER_RATIO: float = 0.55

const HILL_POSITION: Vector3 = Vector3(0.0, 0.0, 0.0)
const HILL_RADIUS: float = 48.0
const HILL_SCORE_TO_WIN: float = 500.0
const HILL_SCORE_RATE: float = 7.0
const HILL_CONTEST_RANGE: float = 52.0
const HILL_MARKER_HEIGHT: float = 0.35


# ---------------- FINAL BOSS MODE ----------------
const BOSS_MODE_UNLOCKED_META: String = "boss_mode_unlocked"
const FINAL_BOSS_HEALTH: int = 500
const FINAL_BOSS_PLAYER_FINISH_HP: int = 30
const FINAL_BOSS_BLUE_HELP_DAMAGE: int = 1
const FINAL_BOSS_ATTACK_PLAYER_WEIGHT: int = 2
const FINAL_BOSS_ATTACK_BLUE_WEIGHT: int = 3
const FINAL_BOSS_END_FADE_SECONDS: float = 2.75
const FINAL_BOSS_COMPLETION_SAVE_KEY: String = "final_boss_reward_power_unlocked"
const FINAL_BOSS_CREDITS_TITLE: String = "THANK YOU FOR PLAYING"
const FINAL_BOSS_PHASE_TWO_HEALTH: int = 250
const FINAL_BOSS_BODY_HIT_DAMAGE: int = 1
const FINAL_BOSS_HEADSHOT_MULTIPLIER: int = 2
const FINAL_BOSS_MAX_DAMAGE_PER_PLAYER_HIT: int = 2
const FINAL_BOSS_GUARD_COUNT: int = 0
const FINAL_BOSS_SCALE_MIN: float = 5.0
const FINAL_BOSS_SCALE_MAX: float = 10.0
const FINAL_BOSS_DAMAGE_MULTIPLIER: float = 4.0
const FINAL_BOSS_FIRE_COOLDOWN_MULTIPLIER_STRONG: float = 0.25
const FINAL_BOSS_SIZE_SCALE: Vector3 = Vector3(3.2, 3.2, 3.2)
const FINAL_BOSS_CENTER: Vector3 = Vector3(0.0, 0.0, 0.0)
const FINAL_BOSS_SPAWN_NODE_NAME: String = "FinalBossSpawn"
const FINAL_BOSS_LOCKED_POSITION: Vector3 = FINAL_BOSS_CENTER
const FINAL_BOSS_VISUAL_SCALE_LIGHT: Vector3 = Vector3(3.2, 3.2, 3.2)
const FINAL_BOSS_SHOWDOWN_RADIUS: float = 115.0
const FINAL_BOSS_RED_FIRE_MULTIPLIER: float = 0.25
const FINAL_BOSS_REWARD_MONEY: int = 2000
const FINAL_BOSS_SHOTGUN_PELLETS: int = 0
const FINAL_BOSS_SHOTGUN_COOLDOWN: float = 999999.0
const FINAL_BOSS_RING_COOLDOWN: float = 999999.0
const FINAL_BOSS_CHARGE_COOLDOWN: float = 999999.0
const FINAL_BOSS_SUMMON_COOLDOWN: float = 999999.0
const FINAL_BOSS_MAX_EXTRA_GUARDS: int = 0
const FINAL_BOSS_RING_BULLETS: int = 0
const FINAL_BOSS_SPECIAL_DAMAGE: int = 18
const FINAL_BOSS_BULLET_DAMAGE: int = 4
const FINAL_BOSS_RIFLE_BURST_SHOTS: int = 3
const FINAL_BOSS_PHASE_TWO_RIFLE_BURST_SHOTS: int = 4
const FINAL_BOSS_RIFLE_SHOT_GAP_SECONDS: float = 0.0
const FINAL_BOSS_BULLET_HIT_RADIUS: float = 0.72
const FINAL_BOSS_PLAYER_DAMAGE_COOLDOWN: float = 0.55
const FINAL_BOSS_BURST_SHOTS: int = 3
const FINAL_BOSS_PHASE_TWO_BURST_SHOTS: int = 5
const FINAL_BOSS_BURST_SPREAD_DEGREES: float = 4.5
const FINAL_BOSS_SWEEP_SHOTS: int = 5
const FINAL_BOSS_SWEEP_ARC_DEGREES: float = 28.0
const FINAL_BOSS_SUPPRESSION_SHOTS: int = 5
const FINAL_BOSS_SUPPRESSION_SPREAD_DEGREES: float = 18.0
const FINAL_BOSS_MISS_CHANCE: float = 0.10
const FINAL_BOSS_SINGLE_SHOT_COOLDOWN: float = 1.75
const FINAL_BOSS_MAX_GUN_RANGE: float = 220.0
const FINAL_BOSS_MIN_GUN_RANGE: float = 12.0
const FINAL_BOSS_ATTACK_DECISION_COOLDOWN_MIN: float = 1.05
const FINAL_BOSS_ATTACK_DECISION_COOLDOWN_MAX: float = 1.85
const FINAL_BOSS_PHASE_TWO_ATTACK_COOLDOWN_MULTIPLIER: float = 0.62
const FINAL_BOSS_FAIR_AIM_ERROR_NEAR: float = 0.85
const FINAL_BOSS_FAIR_AIM_ERROR_MID: float = 1.75
const FINAL_BOSS_FAIR_AIM_ERROR_LONG: float = 4.25
const FINAL_BOSS_PHASE_TWO_SHOT_COOLDOWN_MULTIPLIER: float = 0.58
const FINAL_BOSS_ATTACK_LOS_INTERVAL: float = 0.28
const FINAL_BOSS_TARGET_UPDATE_INTERVAL: float = 0.35
const FINAL_BOSS_PATH_RECALC_INTERVAL: float = 0.45
const FINAL_BOSS_CHARGE_SPEED: float = 0.0
const FINAL_BOSS_CHARGE_TIME: float = 0.0
const FINAL_BOSS_MIN_WIN_TIME: float = 2.0
const FINAL_BOSS_ATTACK_DISTANCE: float = 32.0
const FINAL_BOSS_CHASE_DISTANCE: float = 44.0
const FINAL_BOSS_RETREAT_DISTANCE: float = 14.0
const FINAL_BOSS_STRAFE_DISTANCE: float = 26.0
const FINAL_BOSS_CLOSE_BLAST_DISTANCE: float = 48.0
const FINAL_BOSS_CLOSE_BLAST_COOLDOWN: float = 7.0
const FINAL_BOSS_CLOSE_BLAST_SHOTS: int = 8
const FINAL_BOSS_CHASE_SPEED_MULTIPLIER: float = 0.82
const FINAL_BOSS_BODY_HITBOX_RADIUS: float = 1.35
const FINAL_BOSS_BODY_HITBOX_HEIGHT: float = 2.85
const FINAL_BOSS_HEAD_HITBOX_RADIUS: float = 0.72
const FINAL_BOSS_OFFENSE_UPDATE_INTERVAL: float = 0.25
const FINAL_BOSS_MAX_MOVE_SPEED: float = 4.2
const FINAL_BOSS_DASH_SPEED: float = 9.5
const FINAL_BOSS_DASH_DURATION: float = 0.70
const FINAL_BOSS_DASH_COOLDOWN: float = 4.50
const FINAL_BOSS_DASH_MIN_RANGE: float = 38.0
const FINAL_BOSS_DASH_MAX_RANGE: float = 260.0
const FINAL_BOSS_NO_GUN_RANGE: float = 245.0
const FINAL_BOSS_FIXED_SYSTEM_VERSION: String = "boss_kept_in_arrays_skip_ai_v1"
const FINAL_BOSS_LOW_LAG_SIMPLE_MODE: bool = true

# ---------------- TITLE MUSIC ----------------
# Add one of these audio files to your project, or add an AudioStreamPlayer child
# named TitleMusic / MenuMusic / Music to the BattleManager node.
const TITLE_MUSIC_VOLUME_DB: float = 25.0
const TITLE_MUSIC_FADE_SECONDS: float = 1.8
const TITLE_MUSIC_PATH_1: String = "res://title_music.ogg"
const TITLE_MUSIC_PATH_2: String = "res://title_music.wav"
const TITLE_MUSIC_PATH_3: String = "res://music/title_music.ogg"

# ---------------- GENERATED UI SOUND EFFECTS ----------------
const UI_SOUNDS_ENABLED: bool = true
const UI_HOVER_VOLUME_DB: float = -10.0
const UI_CLICK_VOLUME_DB: float = -6.0

var ui_hover_player: AudioStreamPlayer = null
var ui_click_player: AudioStreamPlayer = null

const RED_ACTIVE_LIMIT: int = 7
const BLUE_ACTIVE_LIMIT: int = 7

const RED_TOTAL_RESERVES: int = 25
const BLUE_TOTAL_RESERVES: int = 25
const TEAM_ELIMINATION_RESERVES: int = 25
const MANHUNT_HUNTER_RESERVES: int = 25
const MANHUNT_HUNTER_ACTIVE_LIMIT: int = 7

# ---------------- MODE BALANCE ----------------


const DEFAULT_MODE_TIME_LIMIT: float = 12.0 * 60.0


const RED_SPAWN_POSITION: Vector3 = Vector3(309.3, 13.96, 465.1)
const BLUE_SPAWN_POSITION: Vector3 = Vector3(-374.0, 53.41, -473.0)

const SPAWN_SPACING: float = 6.0
const SPAWN_COLUMNS: int = 5
const RESPAWN_DELAY_MIN: float = 1.2
const RESPAWN_DELAY_MAX: float = 3.0

const SPAWN_IMMUNITY_TIME: float = 5.0

const RED_PLAYER_MAX_TARGET_DISTANCE: float = 150.0
const RED_PLAYER_TARGET_CHANCE: float = 0.45
const RED_PLAYER_VISIBLE_BONUS: float = 15.0

const NPC_MAX_HEALTH: int = 2
const NPC_BODY_DAMAGE: int = 1
const NPC_HEADSHOT_DAMAGE: int = 2

const NPC_SPEED_MIN: float = 3.0
const NPC_SPEED_MAX: float = 5.4
const NPC_STOP_DISTANCE_MIN: float = 18.0
const NPC_STOP_DISTANCE_MAX: float = 34.0
const NPC_SEPARATION_DISTANCE: float = 3.2

const NPC_SHOOT_DISTANCE_MIN: float = 110.0
const NPC_SHOOT_DISTANCE_MAX: float = 210.0
const NPC_FIRE_COOLDOWN_MIN: float = 0.70
const NPC_FIRE_COOLDOWN_MAX: float = 1.75
const RED_FIRE_COOLDOWN_MULTIPLIER: float = 0.88 # Red shoots about 12% faster, but gets no extra units.
const RED_FIRE_COOLDOWN_MINIMUM: float = 0.50
const NPC_RELOAD_TIME_MIN: float = 1.3
const NPC_RELOAD_TIME_MAX: float = 2.6
const NPC_MAGAZINE_MIN: int = 8
const NPC_MAGAZINE_MAX: int = 16

const NPC_BULLET_SPEED: float = 135.0
const NPC_BULLET_LIFE: float = 5.0
const NPC_BULLET_DAMAGE: int = 8
const PLAYER_BULLET_HIT_RADIUS: float = 0.55

const NPC_AIM_ERROR_BASE: float = 3.4
const NPC_AIM_ERROR_DISTANCE_FACTOR: float = 0.035

# Fairness against the player.
# Red CPUs can still shoot, but they cannot laser-tag the player perfectly from far away.
const NPC_CHANCE_TO_HIT_PLAYER: float = 0.75
const NPC_MAX_PLAYER_HIT_RANGE: float = 200.0

const GRAVITY: float = 30.0
const JUMP_FORCE: float = 9.0
const FLOOR_SNAP_LENGTH: float = 1.2

const NPC_CAPSULE_RADIUS: float = 0.38
const NPC_CAPSULE_HEIGHT: float = 1.72

# Same jump power as the player and NPC sprint support.
const NPC_SPRINT_MULTIPLIER: float = 1.65
const NPC_SPRINT_DISTANCE: float = 85.0
const NPC_SPRINT_SEARCH_DISTANCE: float = 95.0

# ---------------- NPC 3D SOUND ----------------
const NPC_SOUND_MAX_DISTANCE: float = 85.0
const NPC_SOUND_UNIT_SIZE: float = 18.0
const NPC_GUNSHOT_VOLUME_DB: float = -6.0
const NPC_FOOTSTEP_VOLUME_DB: float = -18.0
const NPC_HURT_VOLUME_DB: float = -10.0
const NPC_DEATH_VOLUME_DB: float = -8.0

const PLAN_RETHINK_TIME_MIN: float = 6.0
const PLAN_RETHINK_TIME_MAX: float = 11.0

# ---------------- HELICOPTER STRATEGY ----------------
# NPCs can decide to capture and fly a helicopter if one exists in the scene.
# Put the helicopter in the "Helicopter" group; the helicopter script adds this automatically.
const HELICOPTER_STRATEGY_ENABLED: bool = true
const HELICOPTER_STRATEGY_CHECK_TIME: float = 1.75
const HELICOPTER_ASSIGN_DISTANCE: float = 260.0
const HELICOPTER_BOARD_DISTANCE: float = 9.5
const HELICOPTER_MAX_ACTIVE_PILOTS_PER_TEAM: int = 1
const HELICOPTER_MIN_UNIT_COUNT_TO_USE: int = 4
const HELICOPTER_PLAYER_PRIORITY_SECONDS: float = 7.0
# If the player lands with fuel left, the nearest CPU should try to take that helicopter.
const HELICOPTER_ABANDONED_ASSIGN_DISTANCE: float = 99999.0

# ---------------- MATCH TIMER ----------------
const MATCH_TIME_SECONDS: float = 480.0 # 8 minutes


enum BattlePlan {
	ASSAULT,
	HOLD,
	FLANK_LEFT,
	FLANK_RIGHT,
	FALL_BACK
}

var player: CharacterBody3D = null
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var red_units: Array[CharacterBody3D] = []
var blue_units: Array[CharacterBody3D] = []
var all_units: Array[CharacterBody3D] = []
var bullets: Array[Area3D] = []

var red_spawned_total: int = 0
var blue_spawned_total: int = 0

var red_respawn_timer: float = 0.0
var blue_respawn_timer: float = 0.0

var red_plan: int = BattlePlan.ASSAULT
var blue_plan: int = BattlePlan.ASSAULT
var red_plan_timer: float = 0.0
var blue_plan_timer: float = 0.0

var battle_ui_layer: CanvasLayer = null
var battle_label: Label = null
var minimap_panel: Control = null
var title_panel: Control = null
var title_label: Label = null
var title_subtitle_label: Label = null
var title_hint_label: Label = null
var title_brief_label: Label = null
var title_start_button: Button = null
var title_shop_button: Button = null
var title_achievements_button: Button = null
var title_reset_progress_button: Button = null
var title_brief_button: Button = null
var title_mode_button: Button = null
var title_quit_button: Button = null

# ---------------- BUILT-IN ONLINE MENU / LOBBY ----------------
# This puts the old OnlineNetworkManager.gd and OnlineMenu.gd logic directly inside BattleManager.
# It still uses Godot built-in ENetMultiplayerPeer + RPC. For true web play, run this same
# BattleManager scene on a dedicated server, then clients connect to that server IP.
const ONLINE_DEFAULT_PORT: int = 8910
# CHANGE THIS ONE LINE after you put your dedicated Godot server online.
# Players will NOT have to type the server IP in the menu.
const ONLINE_DEFAULT_SERVER_IP: String = "127.0.0.1"
const ONLINE_CONNECT_TIMEOUT_SECONDS: float = 5.0
const ONLINE_MAX_SERVER_CLIENTS: int = 64
const ONLINE_MAX_ROOM_PLAYERS: int = 10

var online_rooms: Dictionary = {}
var online_player_room: Dictionary = {}
var online_public_room_ids: Array[String] = []

var online_panel: PanelContainer = null
var online_server_ip_line_edit: LineEdit = null
var online_host_public_button: Button = null
var online_host_private_button: Button = null
var online_refresh_public_button: Button = null
var online_join_code_line_edit: LineEdit = null
var online_join_private_button: Button = null
var online_public_rooms_item_list: ItemList = null
var online_join_selected_public_button: Button = null
var online_status_label: Label = null
var online_open_button: Button = null
var online_back_button: Button = null
var online_lobby_title_label: Label = null
var online_lobby_state_label: Label = null
var online_party_count_label: Label = null
var online_private_code_label: Label = null

var online_current_room_id: String = ""
var online_current_join_code: String = ""
var online_current_room_private: bool = false
var online_current_room_host_id: int = 0
var online_current_party_count: int = 1
var online_current_party_max: int = ONLINE_MAX_ROOM_PLAYERS

var title_brief_visible: bool = false
var game_started: bool = false
var title_input_lock_timer: float = 0.25
var title_music_player: AudioStreamPlayer = null
var title_music_tween: Tween = null
var selected_game_mode: String = GAME_MODE_ELIMINATION
var result_menu_button: Button = null
var boss_health_panel: PanelContainer = null
var boss_health_bar: ProgressBar = null
var boss_health_label: Label = null
var economy_manager: Node = null

# ---------------- INTEGRATED SHOP / ECONOMY ----------------
# ---------------- MONEY REWARDS ----------------
const MONEY_PER_ELIMINATION: int = 100
const MONEY_TEAM_ELIMINATION_ELIMINATION: int = 100
const MONEY_TEAM_ELIMINATION_HEADSHOT_BONUS: int = 50
const MONEY_CTF_DEFENSE_ELIMINATION: int = 35
const MONEY_COMMANDER_ELIMINATION: int = 45
const MONEY_HILL_ELIMINATION: int = 25
const MONEY_HEADSHOT_BONUS: int = 50
const MONEY_HELICOPTER_BONUS: int = 25
const MONEY_FLAG_PICKUP: int = 50
const MONEY_FLAG_CAPTURE: int = 250
const MONEY_MANHUNT_SURVIVE_TICK: int = 25
const MONEY_MANHUNT_ESCAPE_TICK: int = 35
const MONEY_MANHUNT_FAST_HUNT_BASE: int = 350
const MONEY_MANHUNT_FAST_HUNT_TIME_BONUS_MAX: int = 450
const MONEY_MANHUNT_SURVIVE_BONUS: int = 200
const MONEY_HILL_CONTROL_TICK: int = 20
const MONEY_SAVE_BONUS_NONE: int = 0

const AUTO_SAVE_INTERVAL_SECONDS: float = 300.0
const MANHUNT_REWARD_INTERVAL_SECONDS: float = 30.0
const HILL_REWARD_INTERVAL_SECONDS: float = 20.0

# ---------------- SHOP KEYS ----------------
const SHOP_TOGGLE_KEY: int = KEY_U
const CONFIRM_YES_KEY: int = KEY_ENTER
const CONFIRM_NO_KEY: int = KEY_ESCAPE

# ---------------- PLAYER UPGRADE EFFECTS ----------------
const SPRINT_BONUS_PER_LEVEL: float = 0.75
const STAMINA_BONUS_PER_LEVEL: float = 75.0
const STAMINA_REGEN_BONUS_PER_LEVEL: float = 7.0
const HEALTH_BONUS_PER_LEVEL: int = 5

# ---------------- HELICOPTER / RADAR UPGRADE EFFECTS ----------------
const HCOP_FUEL_BONUS_SECONDS_PER_LEVEL: float = 35.0

# Gun cooldown starts slower now, then the shop can improve it.
const PLAYER_FIRE_COOLDOWN_BASE: float = 0.32
const PLAYER_FIRE_COOLDOWN_REDUCTION_PER_LEVEL: float = 0.035
const PLAYER_FIRE_COOLDOWN_MIN: float = 0.12
const PLAYER_RELOAD_TIME_BASE: float = 5.0
const PLAYER_RELOAD_TIME_REDUCTION_PER_LEVEL: float = 0.55
const PLAYER_RELOAD_TIME_MIN: float = 2.0
const PLAYER_AMMO_BASE: int = 25
const PLAYER_AMMO_PER_LEVEL: int = 5

# ---------------- SAVE DATA ----------------
const SAVE_PATH: String = "user://mountain_laser_tag_shop.save"

const ACHIEVEMENT_SAVE_PATH: String = "user://mountain_laser_tag_achievements.save"

# ---------------- SECRET UNLOCK CODE ----------------
const SECRET_UNLOCK_CODE: String = "qwerty123"
var secret_unlock_progress: int = 0
var secret_unlock_last_char: String = ""


# Achievement rules:
# Hidden means the page shows "???" until unlocked, like Hollow Knight-style secrets.
# The final boss achievement stays hidden until all normal achievements are done.
var achievement_data: Dictionary = {
	"first_elim": {"title":"First Contact", "desc":"Get your first elimination.", "hidden":false, "icon":"◎"},
	"five_elims_match": {"title":"Patrol Breaker", "desc":"Get 5 eliminations in one match.", "hidden":true, "icon":"✦"},
	"ten_elims_match": {"title":"One-Person Squad", "desc":"Get 10 eliminations in one match.", "hidden":true, "icon":"✹"},
	"first_headshot": {"title":"Clean Sightline", "desc":"Get one headshot.", "hidden":true, "icon":"⌖"},
	"ten_headshots_match": {"title":"Sharpshooter", "desc":"Get 10 headshots in one match.", "hidden":true, "icon":"◉"},
	"flag_pickup": {"title":"Hands on the Flag", "desc":"Pick up an enemy flag.", "hidden":true, "icon":"⚑"},
	"flag_capture": {"title":"Flag Runner", "desc":"Capture one enemy flag.", "hidden":true, "icon":"⚐"},
	"two_flags_match": {"title":"Double Run", "desc":"Capture 2 flags in one match.", "hidden":true, "icon":"⚑⚐"},
	"manhunt_played": {"title":"The Hunt Begins", "desc":"Play a Manhunt match.", "hidden":true, "icon":"◇"},
	"manhunt_survivor": {"title":"Ghost in the Fog", "desc":"Survive a Manhunt match as the hunted target.", "hidden":true, "icon":"☾"},
	"red_hunted_survivor": {"title":"Red Escape", "desc":"Win a Manhunt round while Red is hunted.", "hidden":true, "icon":"◆"},
	"hill_entered": {"title":"Into the Circle", "desc":"Enter the King of the Hill zone.", "hidden":true, "icon":"○"},
	"hill_holder": {"title":"Hold the High Ground", "desc":"Earn a hill-control reward.", "hidden":true, "icon":"▲"},
	"helicopter_boarded": {"title":"Rotor Rookie", "desc":"Board a helicopter.", "hidden":true, "icon":"↥"},
	"helicopter_ace": {"title":"Rotor Ace", "desc":"Get 5 helicopter eliminations in one match.", "hidden":true, "icon":"✈"},
	"commander_played": {"title":"Chain of Command", "desc":"Play Commander mode.", "hidden":true, "icon":"♜"},
	"commander_breaker": {"title":"Command Breaker", "desc":"Win Commander mode.", "hidden":true, "icon":"♛"},
	"team_elim_win": {"title":"Linebreaker", "desc":"Win Team Elimination.", "hidden":true, "icon":"⚔"},
	"hundred_elims": {"title":"Century Tagger", "desc":"Get 100 lifetime eliminations.", "hidden":true, "icon":"100"},
	"five_hundred_elims": {"title":"Laser Legend", "desc":"Get 500 lifetime eliminations.", "hidden":true, "icon":"500"},
	"team_elim_25_elims": {"title":"Team Wrecker", "desc":"Get 25 lifetime Team Elimination knockouts.", "hidden":true, "icon":"⚔+"},
	"manhunt_escape_money": {"title":"Paid Escape", "desc":"Earn money while surviving as the hunted target.", "hidden":true, "icon":"☾$"},
	"fast_hunter": {"title":"Fast Hunter", "desc":"Win Manhunt quickly while hunting the Red target.", "hidden":true, "icon":"◇!"},
	"ctf_specialist": {"title":"Flag Specialist", "desc":"Win Capture the Flag.", "hidden":true, "icon":"⚑★"},
	"king_hill_win": {"title":"Crowned the Hill", "desc":"Win King of the Hill.", "hidden":true, "icon":"▲★"},
	"boss_unlocked": {"title":"The Gate Opens", "desc":"Complete every other challenge to unlock the Final Showdown.", "hidden":true, "icon":"▣"},

	"first_upgrade": {"title":"First Upgrade", "desc":"Buy any upgrade from the shop.", "hidden":true, "icon":"⬡"},
	"sprint_maxed": {"title":"Lightning Boots", "desc":"Fully upgrade Sprint Boots.", "hidden":true, "icon":"↯"},
	"stamina_maxed": {"title":"Long Haul", "desc":"Fully upgrade Endurance Pack.", "hidden":true, "icon":"∞"},
	"stamina_regen_maxed": {"title":"Second Wind", "desc":"Fully upgrade Stamina Charger.", "hidden":true, "icon":"↻"},
	"health_maxed": {"title":"Walking Tank", "desc":"Fully upgrade Armor Vest.", "hidden":true, "icon":"⬢"},
	"hcop_fuel_maxed": {"title":"Full Tank", "desc":"Fully upgrade HCop Fuel Tank.", "hidden":true, "icon":"⛽"},
	"fire_rate_maxed": {"title":"Fast Trigger", "desc":"Fully upgrade Trigger Tuner.", "hidden":true, "icon":"✧"},
	"reload_speed_maxed": {"title":"Fast Hands", "desc":"Fully upgrade Quick Mag.", "hidden":true, "icon":"⇄"},
	"ammo_capacity_maxed": {"title":"Loaded Up", "desc":"Fully upgrade Ammo Pouch.", "hidden":true, "icon":"▤"},
	"all_geared_up": {"title":"All Geared Up", "desc":"Fully upgrade everything in the shop.", "hidden":true, "icon":"★"},
	"final_boss": {"title":"The Mountain Falls", "desc":"Beat the final boss.", "hidden":true, "super_hidden":true, "icon":"♔"}
}

var money: int = 0
var lifetime_money_earned: int = 0
var lifetime_eliminations: int = 0
var lifetime_headshots: int = 0
var lifetime_flag_captures: int = 0
var lifetime_manhunt_survival_ticks: int = 0
var lifetime_manhunt_hunts_won: int = 0
var lifetime_hill_eliminations: int = 0
var lifetime_commander_eliminations: int = 0
var lifetime_ctf_eliminations: int = 0
var lifetime_team_elimination_eliminations: int = 0

var auto_save_timer: float = 0.0
var manhunt_survival_reward_timer: float = 0.0
var hill_reward_timer: float = 0.0

var upgrade_levels: Dictionary = {
	"sprint": 0,
	"stamina": 0,
	"stamina_regen": 0,
	"health": 0,
	"hcop_fuel": 0,
	"fire_rate": 0,
	"reload_speed": 0,
	"ammo_capacity": 0
}

# Different upgrade types, prices, max levels, descriptions, and button text.
var upgrade_data: Dictionary = {
	"sprint": {
		"title": "Sprint Boots",
		"short": "Move faster while sprinting.",
		"effect": "+0.75 sprint speed per level",
		"max_level": 5,
		"base_cost": 250,
		"cost_step": 175
	},
	"stamina": {
		"title": "Endurance Pack",
		"short": "Run longer before stamina runs out.",
		"effect": "+75 max stamina per level",
		"max_level": 5,
		"base_cost": 225,
		"cost_step": 150
	},
	"stamina_regen": {
		"title": "Stamina Charger",
		"short": "Recover stamina faster after sprinting.",
		"effect": "+7 stamina regeneration per second per level",
		"max_level": 5,
		"base_cost": 240,
		"cost_step": 170
	},
	"health": {
		"title": "Armor Vest",
		"short": "Take more hits before being eliminated.",
		"effect": "+5 max health per level",
		"max_level": 6,
		"base_cost": 300,
		"cost_step": 225
	},
	"hcop_fuel": {
		"title": "HCop Fuel Tank",
		"short": "Fly helicopters longer.",
		"effect": "+35 seconds helicopter fuel per level",
		"max_level": 4,
		"base_cost": 350,
		"cost_step": 275
	},
	"fire_rate": {
		"title": "Trigger Tuner",
		"short": "Shoot lasers faster by reducing cooldown time.",
		"effect": "-0.035 seconds cooldown per level. Minimum cooldown: 0.12 seconds.",
		"max_level": 6,
		"base_cost": 275,
		"cost_step": 210
	},
	"reload_speed": {
		"title": "Quick Mag",
		"short": "Reload faster.",
		"effect": "-0.55 seconds reload time per level. Minimum reload: 2 seconds.",
		"max_level": 6,
		"base_cost": 260,
		"cost_step": 190
	},
	"ammo_capacity": {
		"title": "Ammo Pouch",
		"short": "Carry more ammo before reloading.",
		"effect": "+5 max ammo per level.",
		"max_level": 6,
		"base_cost": 240,
		"cost_step": 180
	}
}

var shop_open: bool = false
var shop_allowed_from_main_menu: bool = true

var shop_ui_layer: CanvasLayer = null
var shop_root: Control = null
var dim_background: ColorRect = null
var main_panel: PanelContainer = null
var money_label: Label = null
var status_label: Label = null
var detail_label: Label = null
var upgrade_buttons: Dictionary = {}
var close_button: Button = null

var confirm_panel: PanelContainer = null
var confirm_title_label: Label = null
var confirm_body_label: Label = null
var confirm_yes_button: Button = null
var confirm_no_button: Button = null
var pending_upgrade_id: String = ""

var key_was_down: bool = false
var early_quit_key_was_down: bool = false
var ammo_refill_key_was_down: bool = false
var save_button: Button = null
var reset_progress_button: Button = null
var achievements_button: Button = null
var achievement_panel: PanelContainer = null
var achievement_list_label: Label = null
var achievement_grid: GridContainer = null
var achievement_scroll: ScrollContainer = null
var achievement_cards: Dictionary = {}
var achievement_close_button: Button = null
var achievement_unlocked: Dictionary = {}
var achievement_seen: Dictionary = {}
var achievement_notice_label: Label = null
var achievement_notice_timer: float = 0.0

var match_eliminations: int = 0
var match_headshots: int = 0
var match_helicopter_eliminations: int = 0
var match_flag_captures: int = 0
var match_hill_rewards: int = 0
var boss_unit: CharacterBody3D = null
var final_boss_has_spawned: bool = false
var final_boss_spawn_grace_timer: float = 0.0
var final_boss_match_timer: float = 0.0
var final_boss_current_hp: int = FINAL_BOSS_HEALTH
var final_boss_shotgun_timer: float = 1.2
var final_boss_ring_timer: float = 3.0
var final_boss_single_shot_timer: float = 2.0
var final_boss_dash_timer: float = 0.0
var final_boss_dash_cooldown_timer: float = 0.0
var final_boss_dash_direction: Vector3 = Vector3.ZERO
var final_boss_last_attack_name: String = ""
var final_boss_player_damage_cooldown_timer: float = 0.0
var final_boss_close_blast_timer: float = 2.5
var final_boss_charge_timer: float = 4.5
var final_boss_summon_timer: float = 6.0
var final_boss_is_charging: bool = false
var final_boss_charge_time_left: float = 0.0
var final_boss_charge_direction: Vector3 = Vector3.ZERO
var final_boss_offense_update_timer: float = 0.0
var final_boss_target_update_timer: float = 0.0
var final_boss_path_update_timer: float = 0.0
var final_boss_los_update_timer: float = 0.0
var final_boss_has_line_of_sight: bool = false
var final_boss_move_direction: Vector3 = Vector3.ZERO
var final_boss_locked_position: Vector3 = FINAL_BOSS_LOCKED_POSITION
var boss_mode_unlocked: bool = false
var final_boss_reward_power_unlocked: bool = false
var final_boss_finale_quit_started: bool = false
var final_boss_ui_timer: float = 0.0
var final_boss_credits_layer: CanvasLayer = null
var final_boss_credits_root: Control = null
var final_boss_credits_button: Button = null
var final_boss_credits_active: bool = false
var final_completion_blackout_layer: CanvasLayer = null
var final_completion_blackout_label: Label = null
var final_completion_blackout_active: bool = false


# ---------------- INTEGRATED SUPPLY CRATES ----------------
const SUPPLY_CRATE_PICKUP_DISTANCE: float = 4.0
const SUPPLY_CRATE_RESPAWN_SECONDS: float = 45.0
var supply_crate_respawn_timers: Dictionary = {}

var red_flag_node: Node3D = null
var blue_flag_node: Node3D = null
var red_flag_carrier: Node3D = null
var blue_flag_carrier: Node3D = null
var red_flag_at_base: bool = true
var blue_flag_at_base: bool = true
var red_ctf_score: int = 0
var blue_ctf_score: int = 0
var ctf_anim_time: float = 0.0

var manhunt_hunted_team: String = ""
var manhunt_hunted_target: Node3D = null
var manhunt_target_marker: Node3D = null
var red_commander: Node3D = null
var blue_commander: Node3D = null
var commander_markers: Array[Node3D] = []
var hill_node: Node3D = null
var blue_hill_score: float = 0.0
var red_hill_score: float = 0.0
var objective_nodes: Array[Node3D] = []
var player_deaths: int = 0
var player_kills: int = 0
var player_headshots: int = 0
var red_kills: int = 0
var blue_kills: int = 0
var game_over: bool = false
var game_result: String = ""
var result_panel: ColorRect = null
var result_label: Label = null
var result_art_panel: ResultArtPanel = null
var result_card_panel: PanelContainer = null
var result_title_label: Label = null
var result_detail_label: Label = null
var simple_fireworks_panel: SimpleResultFireworksPanel = null
var match_time_remaining: float = MATCH_TIME_SECONDS
var helicopter_strategy_timer: float = 0.0
var helicopter_strategy_delay_timer: float = HELICOPTER_PLAYER_PRIORITY_SECONDS

# Online match start guard. This prevents clients from starting the match twice
# when the server broadcasts the start signal.
var online_starting_from_server: bool = false


# ---------------- FINAL BOSS HEALTH BAR ----------------
func create_boss_health_ui() -> void:
	if battle_ui_layer == null:
		return

	if boss_health_panel != null:
		return

	boss_health_panel = PanelContainer.new()
	boss_health_panel.name = "BossHealthPanel"
	boss_health_panel.anchor_left = 0.5
	boss_health_panel.anchor_right = 0.5
	boss_health_panel.anchor_top = 0.0
	boss_health_panel.anchor_bottom = 0.0
	boss_health_panel.offset_left = -390.0
	boss_health_panel.offset_right = 390.0
	boss_health_panel.offset_top = 58.0
	boss_health_panel.offset_bottom = 126.0
	boss_health_panel.visible = false
	boss_health_panel.z_index = 160
	boss_health_panel.add_theme_stylebox_override("panel", make_panel_style(Color(0.020, 0.006, 0.008, 0.94), Color(1.0, 0.10, 0.06, 1.0), 3))
	battle_ui_layer.add_child(boss_health_panel)

	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	boss_health_panel.add_child(box)

	boss_health_label = Label.new()
	boss_health_label.text = "FINAL BOSS  500 / 500"
	boss_health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_health_label.add_theme_font_size_override("font_size", 24)
	boss_health_label.add_theme_color_override("font_color", Color(1.0, 0.28, 0.20, 1.0))
	box.add_child(boss_health_label)

	boss_health_bar = ProgressBar.new()
	boss_health_bar.min_value = 0.0
	boss_health_bar.max_value = float(FINAL_BOSS_HEALTH)
	boss_health_bar.value = float(FINAL_BOSS_HEALTH)
	boss_health_bar.custom_minimum_size = Vector2(735.0, 24.0)
	boss_health_bar.show_percentage = false
	box.add_child(boss_health_bar)

func show_boss_health_ui() -> void:
	create_boss_health_ui()

	if boss_health_panel != null:
		boss_health_panel.visible = true

	update_boss_health_ui()


func hide_boss_health_ui() -> void:
	if boss_health_panel != null:
		boss_health_panel.visible = false


func update_boss_health_ui() -> void:
	if selected_game_mode != GAME_MODE_FINAL_BOSS or game_over:
		hide_boss_health_ui()
		return

	sync_final_boss_hp_from_unit()
	create_boss_health_ui()

	if boss_health_panel == null or boss_health_bar == null or boss_health_label == null:
		return

	boss_health_panel.visible = true
	boss_health_bar.max_value = float(FINAL_BOSS_HEALTH)

	var target_value: float = float(max(final_boss_current_hp, 0))
	var current_value: float = float(boss_health_bar.value)
	var delta_value: float = max(1.0, 1400.0 * get_physics_process_delta_time())
	boss_health_bar.value = move_toward(current_value, target_value, delta_value)

	if boss_unit == null or not is_instance_valid(boss_unit):
		if final_boss_has_spawned and final_boss_current_hp > 0:
			boss_health_label.text = "FINAL BOSS  " + str(final_boss_current_hp) + " / " + str(FINAL_BOSS_HEALTH) + "  LOCATING..."
		elif not final_boss_has_spawned:
			boss_health_label.text = "FINAL BOSS  SPAWNING..."
		else:
			boss_health_label.text = "FINAL BOSS  0 / " + str(FINAL_BOSS_HEALTH)
		return

	var phase_text: String = "PHASE 2" if final_boss_current_hp <= FINAL_BOSS_PHASE_TWO_HEALTH else "PHASE 1"
	boss_health_label.text = "FINAL BOSS  " + str(max(final_boss_current_hp, 0)) + " / " + str(FINAL_BOSS_HEALTH) + "  " + phase_text

func online_is_active() -> bool:
	return false


func online_is_server_or_single_player() -> bool:
	return true


@rpc("any_peer", "reliable")
func request_start_game_from_server(mode_name: String) -> void:
	if online_is_active() and not multiplayer.is_server():
		return

	selected_game_mode = mode_name
	start_game_from_server.rpc(mode_name)


@rpc("authority", "call_local", "reliable")
func start_game_from_server(mode_name: String) -> void:
	selected_game_mode = mode_name
	online_starting_from_server = true
	start_game_from_title()
	online_starting_from_server = false


func _ready() -> void:
	rng.randomize()
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("BATTLE MANAGER READY - TITLE SCREEN VERSION")
	Engine.physics_ticks_per_second = 60
	Engine.max_fps = 0

	find_player()
	create_battle_ui()
	setup_ui_sounds()
	setup_economy_manager()
	create_minimap()
	create_title_screen()
	show_title_screen()



func sanitize_vector3_meta_values() -> void:
	for unit in all_units:
		if unit == null or not is_instance_valid(unit):
			continue

		for key in ["target_position", "search_position", "move_target", "wander_target", "last_position", "desired_position"]:
			if unit.has_meta(key):
				var value: Variant = unit.get_meta(key)
				if not value is Vector3:
					unit.set_meta(key, unit.global_position)

	for bullet in bullets:
		if bullet == null or not is_instance_valid(bullet):
			continue

		if bullet.has_meta("velocity"):
			var bullet_velocity_value: Variant = bullet.get_meta("velocity")
			if not bullet_velocity_value is Vector3:
				bullet.set_meta("velocity", Vector3.ZERO)


func _physics_process(delta: float) -> void:
	if final_completion_blackout_active:
		return

	if final_boss_credits_active:
		if Input.is_key_pressed(KEY_ENTER) or Input.is_key_pressed(KEY_KP_ENTER) or Input.is_key_pressed(KEY_SPACE):
			save_and_close_after_finale()
		return

	update_secret_unlock_code_input()
	update_shop_input(delta)
	update_auto_save_timer(delta)
	update_early_quit_input()
	update_ammo_refill_input()
	update_achievement_notice(delta)

	if not game_started:
		set_player_ui_visible(false)
		update_title_screen_input(delta)
		return

	if game_over:
		if Input.is_key_pressed(KEY_ENTER) or Input.is_key_pressed(KEY_KP_ENTER) or Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_R):
			return_to_main_menu()
		return

	if player == null or not is_instance_valid(player):
		find_player()

	# In online play, only the dedicated server runs NPCs, bullets, respawns,
	# objectives, and timers. Clients display UI/camera/player input only.
	if online_is_active() and not multiplayer.is_server():
		update_battle_ui()
		return

	expensive_cleanup_timer -= delta
	expensive_sanitize_timer -= delta

	if expensive_cleanup_timer <= 0.0:
		expensive_cleanup_timer = 0.50
		clean_dead_references()

	if expensive_sanitize_timer <= 0.0:
		expensive_sanitize_timer = 1.00
		sanitize_vector3_meta_values()
	update_team_plans(delta)
	update_respawns(delta)
	update_helicopter_strategy(delta)
	update_helicopter_achievement_check()
	update_supply_crates(delta)
	update_units(delta)
	lock_final_boss_position()
	update_manhunt_survival_rewards(delta)
	update_hill_control_rewards(delta)
	update_ctf_mode(delta)
	update_manhunt_mode(delta)
	update_commander_mode(delta)
	update_king_hill_mode(delta)
	update_bullets(delta)
	update_final_boss_mode(delta)
	lock_final_boss_position()
	update_game_timer(delta)
	update_battle_ui_throttled(delta)





# ---------------- SAFE STATUS TEXT ----------------
func set_status_text_safe(text: String) -> void:
	# Works whether the shop/status UI exists or not.
	if has_method("show_shop_status"):
		call("show_shop_status", text)
		return

	if "status_label" in self:
		if status_label != null:
			status_label.text = text
			return

	print(text)




# ---------------- SECRET UNLOCK CODE ----------------
func update_secret_unlock_code_input() -> void:
	var pressed_char: String = get_secret_code_pressed_char()

	if pressed_char == secret_unlock_last_char:
		return

	secret_unlock_last_char = pressed_char

	if pressed_char == "":
		return

	var expected_char: String = SECRET_UNLOCK_CODE.substr(secret_unlock_progress, 1)

	if pressed_char == expected_char:
		secret_unlock_progress += 1

		if secret_unlock_progress >= SECRET_UNLOCK_CODE.length():
			secret_unlock_progress = 0
			activate_secret_unlock_code()
		return

	if pressed_char == SECRET_UNLOCK_CODE.substr(0, 1):
		secret_unlock_progress = 1
	else:
		secret_unlock_progress = 0

func get_secret_code_pressed_char() -> String:
	# Number row, not keypad, so the code is easy and predictable.
	if Input.is_physical_key_pressed(KEY_Q):
		return "q"
	if Input.is_physical_key_pressed(KEY_W):
		return "w"
	if Input.is_physical_key_pressed(KEY_E):
		return "e"
	if Input.is_physical_key_pressed(KEY_R):
		return "r"
	if Input.is_physical_key_pressed(KEY_T):
		return "t"
	if Input.is_physical_key_pressed(KEY_Y):
		return "y"
	if Input.is_physical_key_pressed(KEY_1):
		return "1"
	if Input.is_physical_key_pressed(KEY_2):
		return "2"
	if Input.is_physical_key_pressed(KEY_3):
		return "3"

	return ""


func activate_secret_unlock_code() -> void:
	# Unlock every achievement.
	setup_achievement_defaults()

	for achievement_id in achievement_data.keys():
		achievement_seen[achievement_id] = true
		achievement_unlocked[achievement_id] = true

	# Max every shop upgrade.
	for upgrade_id in upgrade_data.keys():
		var data: Dictionary = upgrade_data[upgrade_id]
		upgrade_levels[upgrade_id] = int(data.get("max_level", int(upgrade_levels.get(upgrade_id, 0))))

	# Make sure boss mode remains unlocked and visible.
	boss_mode_unlocked = true
	achievement_seen["boss_unlocked"] = true
	achievement_unlocked["boss_unlocked"] = true
	achievement_seen["all_geared_up"] = true
	achievement_unlocked["all_geared_up"] = true
	achievement_seen["final_boss"] = true
	achievement_unlocked["final_boss"] = true

	apply_all_upgrades()
	save_shop_data()
	save_achievement_data()
	update_shop_text()
	update_achievement_page()

	if title_mode_button != null:
		title_mode_button.text = get_mode_button_text()

	if title_hint_label != null:
		title_hint_label.text = "SECRET CODE ACCEPTED: everything unlocked."

	show_achievement_notice("SECRET CODE: EVERYTHING UNLOCKED")
	print("SECRET CODE ACCEPTED: qwerty123 unlocked everything.")


# ---------------- EARLY QUIT / RETREAT ----------------
func update_early_quit_input() -> void:
	if not game_started or game_over:
		early_quit_key_was_down = false
		return

	if shop_open:
		return

	var quit_key_down: bool = Input.is_physical_key_pressed(KEY_ESCAPE)

	if quit_key_down and not early_quit_key_was_down:
		save_shop_data()
		show_result_screen("RETREATED", "You quit the match early. Progress was saved.")

	early_quit_key_was_down = quit_key_down


# ---------------- AUTO SAVE ----------------
func update_auto_save_timer(delta: float) -> void:
	auto_save_timer += delta

	if auto_save_timer >= AUTO_SAVE_INTERVAL_SECONDS:
		auto_save_timer = 0.0
		save_shop_data()
		print("Auto saved progress.")


func save_and_quit_game() -> void:
	save_shop_data()
	get_tree().quit()


# ---------------- EXTRA MONEY REWARDS ----------------
func award_money(reason: String, amount: int) -> void:
	if amount <= 0:
		return

	money += amount
	lifetime_money_earned += amount
	save_shop_data()

	if shop_open:
		show_status(reason + ": +$" + str(amount))

	update_shop_text()


func update_manhunt_survival_rewards(delta: float) -> void:
	if selected_game_mode != GAME_MODE_MANHUNT or game_over:
		return

	if manhunt_hunted_target != player:
		return

	if is_player_dead():
		return

	manhunt_survival_reward_timer += delta

	if manhunt_survival_reward_timer >= MANHUNT_REWARD_INTERVAL_SECONDS:
		manhunt_survival_reward_timer = 0.0
		lifetime_manhunt_survival_ticks += 1
		award_money("Manhunt escape time", MONEY_MANHUNT_ESCAPE_TICK)
		unlock_achievement("manhunt_escape_money")

func update_hill_control_rewards(delta: float) -> void:
	if selected_game_mode != GAME_MODE_KING_HILL or game_over:
		return

	if player == null or not is_instance_valid(player) or is_player_dead():
		return

	if player.global_position.distance_to(HILL_POSITION) > HILL_RADIUS:
		return

	unlock_achievement("hill_entered")
	reveal_achievement("hill_holder")
	hill_reward_timer += delta

	if hill_reward_timer >= HILL_REWARD_INTERVAL_SECONDS:
		hill_reward_timer = 0.0
		award_money("Held the hill", MONEY_HILL_CONTROL_TICK)
		match_hill_rewards += 1
		unlock_achievement("hill_holder")

func award_manhunt_survival_bonus_if_needed(result: String) -> void:
	if selected_game_mode != GAME_MODE_MANHUNT:
		return

	if manhunt_hunted_target == player and result.begins_with("VICTORY"):
		award_money("Survived Manhunt", MONEY_MANHUNT_SURVIVE_BONUS)
		unlock_achievement("manhunt_survivor")

func update_ammo_refill_input() -> void:
	if not game_started or game_over:
		ammo_refill_key_was_down = false
		return

	if shop_open:
		return

	var refill_key_down: bool = Input.is_physical_key_pressed(KEY_Q)

	if refill_key_down and not ammo_refill_key_was_down:
		start_player_reload()

	ammo_refill_key_was_down = refill_key_down


func start_player_reload() -> void:
	if player == null or not is_instance_valid(player):
		find_player()

	if player == null or not is_instance_valid(player):
		return

	if player.has_method("refill_ammo_from_battle_manager"):
		player.call("refill_ammo_from_battle_manager")
		return

	# Fallback if the Player script does not have the helper yet.
	if "ammo" in player and "MAX_AMMO" in player:
		player.ammo = player.MAX_AMMO

	if "is_reloading" in player:
		player.is_reloading = false

	if "reload_timer" in player:
		player.reload_timer = 0.0

	if player.has_method("update_ui"):
		player.call("update_ui")


# ---------------- HELICOPTER MATCH RESET ----------------
func reset_all_helicopters_for_new_match() -> void:
	var helicopters: Array[Node] = get_tree().get_nodes_in_group("Helicopter")

	for heli in helicopters:
		if heli == null or not is_instance_valid(heli):
			continue

		if heli.has_method("reset_for_new_match"):
			heli.call("reset_for_new_match")
			continue

		# Fallback for older helicopter scripts.
		if "is_piloted" in heli:
			heli.is_piloted = false
		if "pilot" in heli:
			heli.pilot = null
		if "pilot_is_player" in heli:
			heli.pilot_is_player = false
		if "pilot_team" in heli:
			heli.pilot_team = ""
		if "auto_landing" in heli:
			heli.auto_landing = false
		if "fuel_empty_permanent" in heli:
			heli.fuel_empty_permanent = false
		if "destroyed_permanent" in heli:
			heli.destroyed_permanent = false
		if "helicopter_health" in heli and "HELI_MAX_HEALTH" in heli:
			heli.helicopter_health = heli.HELI_MAX_HEALTH
		if "fuel_remaining" in heli:
			if "upgraded_max_fuel_time" in heli:
				heli.fuel_remaining = heli.upgraded_max_fuel_time
			elif "MAX_FUEL_TIME" in heli:
				heli.fuel_remaining = heli.MAX_FUEL_TIME




# ---------------- MODE TIMER / RESERVE BALANCE ----------------
func get_mode_time_limit() -> float:
	if selected_game_mode == GAME_MODE_ELIMINATION:
		return TEAM_ELIMINATION_TIME_LIMIT

	if selected_game_mode == GAME_MODE_MANHUNT:
		return MANHUNT_TIME_LIMIT

	if selected_game_mode == GAME_MODE_CTF:
		return CTF_TIME_LIMIT

	if selected_game_mode == GAME_MODE_COMMANDER:
		return COMMANDER_TIME_LIMIT

	if selected_game_mode == GAME_MODE_KING_HILL:
		return KING_HILL_TIME_LIMIT

	if selected_game_mode == GAME_MODE_FINAL_BOSS:
		return FINAL_BOSS_TIME_LIMIT

	return MATCH_TIME_LIMIT

func apply_mode_balance_settings() -> void:
	match_time_remaining = get_mode_time_limit()
	red_respawn_timer = 0.0
	blue_respawn_timer = 0.0

func get_mode_summary_text() -> String:
	if selected_game_mode == GAME_MODE_ELIMINATION:
		return "Team Elimination: 15 minutes, 25 reserves per team."

	if selected_game_mode == GAME_MODE_MANHUNT:
		return "Manhunt: survive 4 minutes. Hunted side has no helpers."

	if selected_game_mode == GAME_MODE_CTF:
		return "Capture the Flag: 12 minutes. Score flags before time expires."

	if selected_game_mode == GAME_MODE_COMMANDER:
		return "Commander: 12 minutes. Protect your commander and eliminate theirs."

	if selected_game_mode == GAME_MODE_KING_HILL:
		return "King of the Hill: 10 minutes. Hold the center zone."

	if selected_game_mode == GAME_MODE_FINAL_BOSS:
		return "Final Showdown: no time limit. No respawn."

	return "Standard match."


# ---------------- CPU MATCH RESET ----------------
func reset_all_cpus_for_new_match() -> void:
	# Clear every old CPU and bullet so every match starts clean.
	for unit in all_units:
		if unit != null and is_instance_valid(unit):
			unit.queue_free()

	for bullet in bullets:
		if bullet != null and is_instance_valid(bullet):
			bullet.queue_free()

	red_units.clear()
	blue_units.clear()
	all_units.clear()
	bullets.clear()

	red_spawned_total = 0
	blue_spawned_total = 0
	red_respawn_timer = 0.0
	blue_respawn_timer = 0.0

	red_kills = 0
	blue_kills = 0
	player_kills = 0
	player_headshots = 0
	player_deaths = 0

	red_flag_carrier = null
	blue_flag_carrier = null
	red_commander = null
	blue_commander = null
	manhunt_hunted_target = null
	manhunt_hunted_team = ""
	boss_unit = null
	final_boss_has_spawned = false
	final_boss_spawn_grace_timer = 0.0


func get_red_active_limit_for_mode() -> int:
	if selected_game_mode == GAME_MODE_FINAL_BOSS:
		return 1

	if selected_game_mode == GAME_MODE_MANHUNT:
		if manhunt_hunted_team == "red":
			return 1

		return MANHUNT_HUNTER_ACTIVE_LIMIT

	return RED_ACTIVE_LIMIT

func get_blue_active_limit_for_mode() -> int:
	if selected_game_mode == GAME_MODE_MANHUNT:
		if manhunt_hunted_team == "blue":
			if manhunt_hunted_target == player:
				return 0

			return 1

		return MANHUNT_HUNTER_ACTIVE_LIMIT

	return BLUE_ACTIVE_LIMIT

func get_red_reserve_limit_for_mode() -> int:
	if selected_game_mode == GAME_MODE_FINAL_BOSS:
		return 1

	if selected_game_mode == GAME_MODE_ELIMINATION:
		return TEAM_ELIMINATION_RESERVES

	if selected_game_mode == GAME_MODE_MANHUNT:
		if manhunt_hunted_team == "red":
			return 1

		return MANHUNT_HUNTER_RESERVES

	return RED_TOTAL_RESERVES

func get_blue_reserve_limit_for_mode() -> int:
	if selected_game_mode == GAME_MODE_ELIMINATION:
		return TEAM_ELIMINATION_RESERVES

	if selected_game_mode == GAME_MODE_MANHUNT:
		if manhunt_hunted_team == "blue":
			if manhunt_hunted_target == player:
				return 0

			return 1

		return MANHUNT_HUNTER_RESERVES

	return BLUE_TOTAL_RESERVES

func setup_manhunt_teams_for_match() -> void:
	if selected_game_mode != GAME_MODE_MANHUNT:
		return
	unlock_achievement("manhunt_played")
	reveal_achievement("manhunt_survivor")
	reveal_achievement("red_hunted_survivor")
	var player_hunted: bool = rng.randf() < 0.50
	if player_hunted:
		manhunt_hunted_team = "blue"
		manhunt_hunted_target = player
		for unit in blue_units:
			if unit != null and is_instance_valid(unit): unit.queue_free()
		blue_units.clear()
		var kept_red_units: Array[CharacterBody3D] = []
		for unit in all_units:
			if unit == null or not is_instance_valid(unit): continue
			if str(unit.get_meta("team", "")) == "blue": continue
			kept_red_units.append(unit)
		all_units = kept_red_units
		while red_units.size() < MANHUNT_HUNTER_ACTIVE_LIMIT and red_spawned_total < MANHUNT_HUNTER_RESERVES:
			spawn_one_unit("red")
		print("MANHUNT TARGET: PLAYER / BLUE")
	else:
		manhunt_hunted_team = "red"
		for unit in red_units:
			if unit != null and is_instance_valid(unit): unit.queue_free()
		red_units.clear()
		var kept_blue_units: Array[CharacterBody3D] = []
		for unit in all_units:
			if unit == null or not is_instance_valid(unit): continue
			if str(unit.get_meta("team", "")) == "red": continue
			kept_blue_units.append(unit)
		all_units = kept_blue_units
		red_spawned_total = 0
		spawn_one_unit("red")
		if red_units.size() > 0:
			manhunt_hunted_target = red_units[0]
			manhunt_hunted_target.set_meta("is_manhunt_target", true)
		while blue_units.size() < BLUE_ACTIVE_LIMIT and blue_spawned_total < BLUE_TOTAL_RESERVES:
			spawn_one_unit("blue")
		print("MANHUNT TARGET: RED CPU")

func find_player() -> void:
	player = null

	var grouped_players: Array[Node] = get_tree().get_nodes_in_group("Player")

	for node in grouped_players:
		if node is CharacterBody3D:
			player = node as CharacterBody3D
			confirm_player_is_blue()
			return

	var root: Window = get_tree().root

	if root == null:
		return

	var found: Node = root.find_child(PLAYER_NODE_NAME, true, false)

	if found != null and found is CharacterBody3D:
		player = found as CharacterBody3D
		player.add_to_group("Player")
		confirm_player_is_blue()


func confirm_player_is_blue() -> void:
	if player == null or not is_instance_valid(player):
		return

	player.add_to_group("BlueTeam")
	player.set_meta("team", "blue")
	player.set_meta("is_player", true)


func is_player_dead() -> bool:
	if player == null or not is_instance_valid(player):
		return true

	var player_dead_value: Variant = player.get("player_dead")

	if player_dead_value == null:
		return false

	return bool(player_dead_value)


func get_safe_player_position() -> Vector3:
	if player != null and is_instance_valid(player):
		return player.global_position

	return BLUE_SPAWN_POSITION


# ---------------- UI ----------------
func update_helicopter_achievement_check() -> void:
	if player == null or not is_instance_valid(player): return
	if "active_helicopter" in player:
		var active_heli: Variant = player.get("active_helicopter")
		if active_heli != null:
			unlock_achievement("helicopter_boarded")
			reveal_achievement("helicopter_ace")

func update_battle_ui_throttled(delta: float) -> void:
	battle_ui_update_timer -= delta
	if battle_ui_update_timer > 0.0:
		return
	battle_ui_update_timer = BATTLE_UI_UPDATE_INTERVAL
	update_battle_ui()


func create_battle_ui() -> void:
	battle_ui_layer = CanvasLayer.new()
	battle_ui_layer.name = "BattleUI"
	add_child(battle_ui_layer)

	battle_label = Label.new()
	battle_label.name = "BattleLabel"
	battle_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	battle_label.position = Vector2(0.0, 10.0)
	battle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	battle_label.add_theme_font_size_override("font_size", 26)
	battle_ui_layer.add_child(battle_label)

	result_panel = ColorRect.new()
	result_panel.name = "ResultPanel"
	result_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	result_panel.color = Color(0.0, 0.0, 0.0, 0.0)
	result_panel.visible = false
	result_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	battle_ui_layer.add_child(result_panel)



	result_card_panel = PanelContainer.new()
	result_card_panel.name = "ResultCardPanel"
	result_card_panel.anchor_left = 0.5
	result_card_panel.anchor_right = 0.5
	result_card_panel.anchor_top = 0.5
	result_card_panel.anchor_bottom = 0.5
	result_card_panel.offset_left = -430.0
	result_card_panel.offset_right = 430.0
	result_card_panel.offset_top = -185.0
	result_card_panel.offset_bottom = 180.0
	result_card_panel.visible = false
	result_card_panel.z_index = 5
	result_card_panel.add_theme_stylebox_override("panel", make_panel_style(Color(0.005, 0.012, 0.020, 0.94), Color(0.18, 0.85, 1.0, 0.95), 3))
	battle_ui_layer.add_child(result_card_panel)

	var result_card_box: VBoxContainer = VBoxContainer.new()
	result_card_box.add_theme_constant_override("separation", 14)
	result_card_panel.add_child(result_card_box)

	result_title_label = Label.new()
	result_title_label.name = "ResultTitleLabel"
	result_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result_title_label.add_theme_font_size_override("font_size", 52)
	result_title_label.add_theme_color_override("font_color", Color(0.86, 1.0, 0.95, 1.0))
	result_card_box.add_child(result_title_label)

	result_detail_label = Label.new()
	result_detail_label.name = "ResultDetailLabel"
	result_detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_detail_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_detail_label.add_theme_font_size_override("font_size", 25)
	result_detail_label.add_theme_color_override("font_color", Color(0.78, 0.9, 1.0, 1.0))
	result_card_box.add_child(result_detail_label)

	result_label = Label.new()
	result_label.name = "ResultLabel"
	result_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result_label.add_theme_font_size_override("font_size", 38)
	result_label.visible = false
	result_label.modulate.a = 0.0
	battle_ui_layer.add_child(result_label)

	result_menu_button = Button.new()
	result_menu_button.name = "ResultMainMenuButton"
	result_menu_button.text = "MAIN MENU"
	result_menu_button.anchor_left = 0.5
	result_menu_button.anchor_right = 0.5
	result_menu_button.anchor_top = 0.5
	result_menu_button.anchor_bottom = 0.5
	result_menu_button.offset_left = -150.0
	result_menu_button.offset_right = 150.0
	result_menu_button.offset_top = 210.0
	result_menu_button.offset_bottom = 272.0
	result_menu_button.visible = false
	result_menu_button.z_index = 10
	result_menu_button.modulate.a = 0.0
	result_menu_button.add_theme_font_size_override("font_size", 30)
	result_menu_button.pressed.connect(return_to_main_menu)
	battle_ui_layer.add_child(result_menu_button)

	create_boss_health_ui()

func setup_economy_manager() -> void:
	# Shop and economy are now built directly into BattleManager.
	# No separate EconomyUpgradeManager node or script is needed.
	economy_manager = self
	load_shop_data()
	load_achievement_data()
	build_shop_ui()
	apply_all_upgrades()


func open_shop_from_title() -> void:
	open_shop()


func open_reset_from_title() -> void:
	open_shop()
	request_reset_progress()


func close_shop_if_open() -> void:
	if shop_open:
		close_shop()


func apply_shop_upgrades() -> void:
	apply_all_upgrades()



# ---------------- GENERATED UI SOUND EFFECTS ----------------
func setup_ui_sounds() -> void:
	if not UI_SOUNDS_ENABLED:
		return

	if ui_hover_player == null:
		ui_hover_player = AudioStreamPlayer.new()
		ui_hover_player.name = "UIHoverSound"
		ui_hover_player.volume_db = UI_HOVER_VOLUME_DB
		ui_hover_player.stream = make_beep_stream(880.0, 0.045, 0.28)
		add_child(ui_hover_player)

	if ui_click_player == null:
		ui_click_player = AudioStreamPlayer.new()
		ui_click_player.name = "UIClickSound"
		ui_click_player.volume_db = UI_CLICK_VOLUME_DB
		ui_click_player.stream = make_beep_stream(520.0, 0.070, 0.38)
		add_child(ui_click_player)


func make_beep_stream(frequency: float, duration_seconds: float, amplitude: float) -> AudioStreamWAV:
	var sample_rate: int = 22050
	var sample_count: int = int(float(sample_rate) * duration_seconds)
	var data: PackedByteArray = PackedByteArray()
	data.resize(sample_count * 2)

	for i in range(sample_count):
		var t: float = float(i) / float(sample_rate)
		var fade: float = 1.0 - (float(i) / float(max(sample_count - 1, 1)))
		var sample_value: int = int(sin(TAU * frequency * t) * amplitude * fade * 32767.0)
		data[i * 2] = sample_value & 0xFF
		data[i * 2 + 1] = (sample_value >> 8) & 0xFF

	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream


func play_ui_hover_sound() -> void:
	if not UI_SOUNDS_ENABLED:
		return

	if ui_hover_player == null:
		setup_ui_sounds()

	if ui_hover_player != null and ui_hover_player.stream != null:
		ui_hover_player.stop()
		ui_hover_player.play()


func play_ui_click_sound() -> void:
	if not UI_SOUNDS_ENABLED:
		return

	if ui_click_player == null:
		setup_ui_sounds()

	if ui_click_player != null and ui_click_player.stream != null:
		ui_click_player.stop()
		ui_click_player.play()


func wire_button_sounds(button: Button) -> void:
	if button == null:
		return

	if not button.mouse_entered.is_connected(play_ui_hover_sound):
		button.mouse_entered.connect(play_ui_hover_sound)

	if not button.focus_entered.is_connected(play_ui_hover_sound):
		button.focus_entered.connect(play_ui_hover_sound)

	if not button.pressed.is_connected(play_ui_click_sound):
		button.pressed.connect(play_ui_click_sound)


# ---------------- TITLE SCREEN ----------------

func title_wire_button_sounds(button: Button) -> void:
	# Compatibility alias. Some generated button code calls this name.
	wire_button_sounds(button)


func create_title_screen() -> void:
	if battle_ui_layer == null:
		return

	title_panel = MountainTitlePanel.new()
	title_panel.name = "MountainLaserTagTitlePanel"
	title_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	title_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	title_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	title_panel.z_index = 500
	battle_ui_layer.add_child(title_panel)

	title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.anchor_left = 0.0
	title_label.anchor_right = 1.0
	title_label.anchor_top = 0.0
	title_label.anchor_bottom = 0.0
	title_label.offset_top = 90.0
	title_label.offset_bottom = 180.0
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 68)
	title_label.add_theme_color_override("font_color", Color(0.82, 1.0, 0.95, 1.0))
	title_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.95, 0.35, 0.75))
	title_label.add_theme_constant_override("shadow_offset_x", 3)
	title_label.add_theme_constant_override("shadow_offset_y", 3)
	title_label.text = "MOUNTAIN LASER TAG"
	title_label.z_index = 501
	title_panel.add_child(title_label)

	title_subtitle_label = Label.new()
	title_subtitle_label.name = "TitleSubtitleLabel"
	title_subtitle_label.anchor_left = 0.0
	title_subtitle_label.anchor_right = 1.0
	title_subtitle_label.anchor_top = 0.0
	title_subtitle_label.anchor_bottom = 0.0
	title_subtitle_label.offset_top = 190.0
	title_subtitle_label.offset_bottom = 235.0
	title_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_subtitle_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_subtitle_label.add_theme_font_size_override("font_size", 30)
	title_subtitle_label.add_theme_color_override("font_color", Color(0.72, 0.88, 1.0, 1.0))
	title_subtitle_label.text = "TACTICAL FOG OPS  |  Blue Team vs Red Team"
	title_subtitle_label.z_index = 502
	title_panel.add_child(title_subtitle_label)

	title_hint_label = Label.new()
	title_hint_label.name = "TitleHintLabel"
	title_hint_label.anchor_left = 0.0
	title_hint_label.anchor_right = 1.0
	title_hint_label.anchor_top = 0.0
	title_hint_label.anchor_bottom = 0.0
	title_hint_label.offset_top = 265.0
	title_hint_label.offset_bottom = 310.0
	title_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_hint_label.add_theme_font_size_override("font_size", 24)
	title_hint_label.add_theme_color_override("font_color", Color(0.90, 0.95, 1.0, 1.0))
	title_hint_label.text = "WASD move  |  Mouse aim  |  Left click fire  |  E helicopter  |  Shop from main menu"
	title_hint_label.z_index = 502
	title_panel.add_child(title_hint_label)

	title_start_button = make_title_button("DEPLOY", Vector2(-240.0, -104.0), Vector2(480.0, 48.0))
	title_start_button.pressed.connect(start_game_from_title)
	title_panel.add_child(title_start_button)

	title_shop_button = make_title_button("UPGRADE SHOP", Vector2(-240.0, -48.0), Vector2(480.0, 48.0))
	title_shop_button.pressed.connect(open_shop_from_title)
	title_panel.add_child(title_shop_button)

	title_achievements_button = make_title_button("ACHIEVEMENTS", Vector2(-240.0, 8.0), Vector2(480.0, 48.0))
	title_achievements_button.pressed.connect(open_achievements_from_title)
	title_panel.add_child(title_achievements_button)

	title_reset_progress_button = make_title_button("RESET SAVE", Vector2(-240.0, 64.0), Vector2(480.0, 48.0))
	title_wire_button_sounds(title_reset_progress_button)
	title_reset_progress_button.pressed.connect(open_reset_from_title)
	title_panel.add_child(title_reset_progress_button)

	# Online removed for now. Keep the variable only so older helper functions stay safe.
	online_open_button = null

	title_brief_button = make_title_button("MISSION BRIEF", Vector2(-240.0, 120.0), Vector2(480.0, 48.0))
	title_brief_button.pressed.connect(toggle_title_brief)
	title_panel.add_child(title_brief_button)

	title_mode_button = make_title_button(get_mode_button_text(), Vector2(-240.0, 176.0), Vector2(480.0, 48.0))
	title_mode_button.pressed.connect(cycle_game_mode)
	title_panel.add_child(title_mode_button)

	title_quit_button = make_title_button("QUIT", Vector2(-240.0, 232.0), Vector2(480.0, 48.0))
	title_quit_button.pressed.connect(quit_from_title)
	title_panel.add_child(title_quit_button)

	title_brief_label = Label.new()
	title_brief_label.name = "TitleBriefLabel"
	title_brief_label.anchor_left = 0.5
	title_brief_label.anchor_right = 0.5
	title_brief_label.anchor_top = 0.5
	title_brief_label.anchor_bottom = 0.5
	title_brief_label.offset_left = -430.0
	title_brief_label.offset_right = 430.0
	title_brief_label.offset_top = -92.0
	title_brief_label.offset_bottom = 250.0
	title_brief_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_brief_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_brief_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_brief_label.add_theme_font_size_override("font_size", 22)
	title_brief_label.add_theme_color_override("font_color", Color(0.85, 1.0, 0.90, 1.0))
	title_brief_label.text = get_title_brief_text()
	title_brief_label.visible = false
	title_brief_label.z_index = 503
	title_panel.add_child(title_brief_label)

	# Online menu controls removed for single-player build.
	setup_title_music()


func make_title_button(button_text: String, center_offset: Vector2, button_size: Vector2) -> Button:
	var button: Button = Button.new()
	button.text = button_text
	button.anchor_left = 0.5
	button.anchor_right = 0.5
	button.anchor_top = 0.5
	button.anchor_bottom = 0.5
	button.offset_left = center_offset.x
	button.offset_right = center_offset.x + button_size.x
	button.offset_top = center_offset.y
	button.offset_bottom = center_offset.y + button_size.y
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.process_mode = Node.PROCESS_MODE_ALWAYS
	button.z_index = 504
	button.add_theme_font_size_override("font_size", 26)
	button.add_theme_color_override("font_color", Color(0.86, 0.96, 1.0, 1.0))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.92, 0.45, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(0.25, 1.0, 0.45, 1.0))
	button.add_theme_stylebox_override("normal", make_title_button_style(Color(0.015, 0.04, 0.075, 0.92), Color(0.16, 0.72, 1.0, 0.85)))
	button.add_theme_stylebox_override("hover", make_title_button_style(Color(0.025, 0.075, 0.120, 0.97), Color(1.0, 0.82, 0.25, 1.0)))
	button.add_theme_stylebox_override("pressed", make_title_button_style(Color(0.010, 0.090, 0.055, 0.98), Color(0.30, 1.0, 0.45, 1.0)))
	button.add_theme_stylebox_override("focus", make_title_button_style(Color(0.025, 0.075, 0.120, 0.97), Color(1.0, 0.82, 0.25, 1.0)))
	wire_button_sounds(button)
	return button


func make_title_button_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(2)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.42)
	style.shadow_size = 7
	return style


func create_online_menu_controls() -> void:
	if title_panel == null:
		return

	# PUBLIC-ONLY ONLINE MENU VERSION
	# Simple flow: Solo Game by default, Host Public, Refresh Public, Join Selected Public.
	# No private rooms. No join codes. No server IP entry.
	online_panel = PanelContainer.new()
	online_panel.name = "OnlinePanel"
	online_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	online_panel.offset_left = 0.0
	online_panel.offset_right = 0.0
	online_panel.offset_top = 0.0
	online_panel.offset_bottom = 0.0
	online_panel.z_index = 900
	online_panel.visible = false
	online_panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var overlay_style: StyleBoxFlat = StyleBoxFlat.new()
	overlay_style.bg_color = Color(0.0, 0.0, 0.0, 0.90)
	overlay_style.border_color = Color(0.10, 0.75, 1.0, 0.85)
	overlay_style.set_border_width_all(2)
	online_panel.add_theme_stylebox_override("panel", overlay_style)
	title_panel.add_child(online_panel)

	var outer: MarginContainer = MarginContainer.new()
	outer.name = "OnlineOuterMargin"
	outer.set_anchors_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("margin_left", 70)
	outer.add_theme_constant_override("margin_right", 70)
	outer.add_theme_constant_override("margin_top", 45)
	outer.add_theme_constant_override("margin_bottom", 45)
	online_panel.add_child(outer)

	var online_box: VBoxContainer = VBoxContainer.new()
	online_box.name = "OnlineBox"
	online_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	online_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	online_box.add_theme_constant_override("separation", 14)
	outer.add_child(online_box)

	online_lobby_title_label = Label.new()
	online_lobby_title_label.text = "PUBLIC ONLINE"
	online_lobby_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	online_lobby_title_label.add_theme_font_size_override("font_size", 40)
	online_lobby_title_label.add_theme_color_override("font_color", Color(0.85, 1.0, 0.95, 1.0))
	online_box.add_child(online_lobby_title_label)

	online_lobby_state_label = Label.new()
	online_lobby_state_label.text = "Solo is default. Use public rooms only: host one or join one."
	online_lobby_state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	online_lobby_state_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	online_lobby_state_label.add_theme_font_size_override("font_size", 22)
	online_lobby_state_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	online_box.add_child(online_lobby_state_label)

	online_party_count_label = Label.new()
	online_party_count_label.text = "Party: Solo 1/1"
	online_party_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	online_party_count_label.add_theme_font_size_override("font_size", 28)
	online_party_count_label.add_theme_color_override("font_color", Color(0.30, 0.85, 1.0, 1.0))
	online_box.add_child(online_party_count_label)

	var host_label: Label = Label.new()
	host_label.text = "1. HOST A PUBLIC ROOM"
	host_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	host_label.add_theme_font_size_override("font_size", 24)
	host_label.add_theme_color_override("font_color", Color(0.85, 1.0, 1.0, 1.0))
	online_box.add_child(host_label)

	online_host_public_button = Button.new()
	online_host_public_button.text = "HOST PUBLIC ROOM"
	online_host_public_button.custom_minimum_size = Vector2(620.0, 62.0)
	online_host_public_button.add_theme_font_size_override("font_size", 30)
	online_host_public_button.pressed.connect(online_host_public_pressed)
	online_box.add_child(online_host_public_button)

	var public_label: Label = Label.new()
	public_label.text = "2. JOIN A PUBLIC ROOM"
	public_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	public_label.add_theme_font_size_override("font_size", 24)
	public_label.add_theme_color_override("font_color", Color(0.85, 1.0, 1.0, 1.0))
	online_box.add_child(public_label)

	var public_row: HBoxContainer = HBoxContainer.new()
	public_row.name = "PublicRow"
	public_row.add_theme_constant_override("separation", 14)
	online_box.add_child(public_row)

	online_refresh_public_button = Button.new()
	online_refresh_public_button.text = "REFRESH ROOMS"
	online_refresh_public_button.custom_minimum_size = Vector2(300.0, 58.0)
	online_refresh_public_button.add_theme_font_size_override("font_size", 22)
	online_refresh_public_button.pressed.connect(online_refresh_public_pressed)
	public_row.add_child(online_refresh_public_button)

	online_join_selected_public_button = Button.new()
	online_join_selected_public_button.text = "JOIN SELECTED ROOM"
	online_join_selected_public_button.custom_minimum_size = Vector2(300.0, 58.0)
	online_join_selected_public_button.add_theme_font_size_override("font_size", 22)
	online_join_selected_public_button.pressed.connect(online_join_selected_public_pressed)
	public_row.add_child(online_join_selected_public_button)

	online_public_rooms_item_list = ItemList.new()
	online_public_rooms_item_list.name = "PublicRoomsItemList"
	online_public_rooms_item_list.custom_minimum_size = Vector2(620.0, 170.0)
	online_public_rooms_item_list.add_theme_font_size_override("font_size", 22)
	online_box.add_child(online_public_rooms_item_list)

	online_status_label = Label.new()
	online_status_label.name = "OnlineStatusLabel"
	online_status_label.text = "Status: Solo mode. You are not in an online room."
	online_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	online_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	online_status_label.add_theme_font_size_override("font_size", 21)
	online_status_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	online_box.add_child(online_status_label)

	online_back_button = Button.new()
	online_back_button.text = "BACK TO MAIN MENU"
	online_back_button.custom_minimum_size = Vector2(620.0, 56.0)
	online_back_button.add_theme_font_size_override("font_size", 22)
	online_back_button.pressed.connect(hide_online_menu)
	online_box.add_child(online_back_button)

	online_update_lobby_labels()

func show_online_menu() -> void:
	set_main_menu_controls_visible(false)
	if title_brief_label != null:
		title_brief_label.visible = false
	if online_panel != null:
		online_panel.visible = true
	online_update_lobby_labels()


func hide_online_menu() -> void:
	if online_panel != null:
		online_panel.visible = false
	set_main_menu_controls_visible(true)


func set_main_menu_controls_visible(visible_now: bool) -> void:
	if title_start_button != null:
		title_start_button.visible = visible_now
	if title_shop_button != null:
		title_shop_button.visible = visible_now
	if title_achievements_button != null:
		title_achievements_button.visible = visible_now
	if title_reset_progress_button != null:
		title_reset_progress_button.visible = visible_now
	if online_open_button != null:
		online_open_button.visible = visible_now
	if title_brief_button != null:
		title_brief_button.visible = visible_now
	if title_mode_button != null:
		title_mode_button.visible = visible_now
	if title_quit_button != null:
		title_quit_button.visible = visible_now
	if title_hint_label != null:
		title_hint_label.visible = visible_now


func online_get_party_count() -> int:
	if multiplayer.multiplayer_peer == null:
		return 1
	return max(1, online_current_party_count)


func get_blue_npc_active_limit() -> int:
	# All humans join BlueTeam. Reduce blue NPCs so the blue side adapts as friends join.
	var human_blue_players: int = online_get_party_count()
	return max(0, BLUE_ACTIVE_LIMIT - (human_blue_players - 1))


func online_update_lobby_labels() -> void:
	if online_party_count_label != null:
		if multiplayer.multiplayer_peer == null:
			online_party_count_label.text = "Party: Solo 1/1"
		else:
			online_party_count_label.text = "Party: " + str(online_current_party_count) + "/" + str(online_current_party_max) + "  |  Blue Team"

	if online_private_code_label != null:
		online_private_code_label.visible = false

	if online_lobby_state_label != null:
		if multiplayer.multiplayer_peer == null:
			online_lobby_state_label.text = "SOLO MODE. Press Solo Game on the main menu to play alone."
		elif online_current_room_id.is_empty():
			online_lobby_state_label.text = "CONNECTED. Host a public room or join a public room."
		else:
			online_lobby_state_label.text = "HOSTING PUBLIC ROOM" if online_current_room_host_id == multiplayer.get_unique_id() else "JOINED PUBLIC ROOM"

func online_clear_room_state() -> void:
	online_current_room_id = ""
	online_current_join_code = ""
	online_current_room_private = false
	online_current_room_host_id = 0
	online_current_party_count = 1
	online_current_party_max = ONLINE_MAX_ROOM_PLAYERS
	online_update_lobby_labels()

func online_set_status(message: String) -> void:
	if online_status_label != null:
		online_status_label.text = "Status: " + message
	online_update_lobby_labels()
	print("ONLINE: " + message)


func online_is_connected_to_server() -> bool:
	if multiplayer.multiplayer_peer == null:
		return false

	if multiplayer.is_server():
		return true

	return multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED


func online_ensure_connected_wait() -> bool:
	# Smooth version: players do not type an IP address.
	# The game auto-connects to ONLINE_DEFAULT_SERVER_IP before hosting or joining.
	if online_is_connected_to_server():
		return true

	if multiplayer.multiplayer_peer == null:
		online_set_status("Auto-connecting to online server...")
		online_connect_to_dedicated_server(ONLINE_DEFAULT_SERVER_IP, ONLINE_DEFAULT_PORT)
	else:
		online_set_status("Waiting for online server connection...")

	var waited: float = 0.0
	while waited < ONLINE_CONNECT_TIMEOUT_SECONDS:
		await get_tree().create_timer(0.1).timeout
		waited += 0.1
		if online_is_connected_to_server():
			online_set_status("Connected. Choose host or join.")
			return true

	online_set_status("Could not connect to the online server. Check ONLINE_DEFAULT_SERVER_IP in this script.")
	return false


func online_host_public_pressed() -> void:
	var connected: bool = await online_ensure_connected_wait()
	if not connected:
		return
	if not online_current_room_id.is_empty():
		online_set_status("You are already in a public room.")
		return
	online_set_status("Creating public room...")
	online_create_room(false, selected_game_mode)


func online_host_private_pressed() -> void:
	var connected: bool = await online_ensure_connected_wait()
	if not connected:
		return
	online_set_status("Creating private room and code...")
	online_create_room(true, selected_game_mode)


func online_join_private_pressed() -> void:
	var connected: bool = await online_ensure_connected_wait()
	if not connected:
		return
	if online_join_code_line_edit == null:
		return
	online_join_private_room(online_join_code_line_edit.text)


func online_refresh_public_pressed() -> void:
	var connected: bool = await online_ensure_connected_wait()
	if not connected:
		return
	online_request_public_rooms()


func online_join_selected_public_pressed() -> void:
	var connected: bool = await online_ensure_connected_wait()
	if not connected:
		return
	if online_public_rooms_item_list == null:
		return

	var selected: PackedInt32Array = online_public_rooms_item_list.get_selected_items()
	if selected.is_empty():
		online_set_status("Select a public room first.")
		return

	var index: int = selected[0]
	if index < 0 or index >= online_public_room_ids.size():
		return

	online_join_public_room(online_public_room_ids[index])


func online_start_button_pressed() -> void:
	# Single-player still works exactly like before.
	if multiplayer.multiplayer_peer == null:
		start_game_from_title()
		return

	# Clients ask the dedicated server to start the match.
	if not multiplayer.is_server():
		request_start_game_from_server.rpc_id(1, selected_game_mode)
		return

	# Dedicated server or local host broadcasts the start.
	start_game_from_server.rpc(selected_game_mode)


# ---------------- BUILT-IN ONLINE NETWORK MANAGER ----------------
func online_start_dedicated_server(port: int = ONLINE_DEFAULT_PORT) -> void:
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var error_code: Error = peer.create_server(port, ONLINE_MAX_SERVER_CLIENTS)
	if error_code != OK:
		push_error("Could not start dedicated server. Error: " + str(error_code))
		return

	multiplayer.multiplayer_peer = peer
	if not multiplayer.peer_disconnected.is_connected(online_server_peer_disconnected):
		multiplayer.peer_disconnected.connect(online_server_peer_disconnected)
	print("Dedicated Godot server online on port " + str(port))


func online_connect_to_dedicated_server(server_ip: String, port: int = ONLINE_DEFAULT_PORT) -> void:
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var error_code: Error = peer.create_client(server_ip, port)
	if error_code != OK:
		online_set_status("Could not create client. Error: " + str(error_code))
		return

	multiplayer.multiplayer_peer = peer
	if not multiplayer.connected_to_server.is_connected(online_client_connected):
		multiplayer.connected_to_server.connect(online_client_connected)
	if not multiplayer.connection_failed.is_connected(online_client_connection_failed):
		multiplayer.connection_failed.connect(online_client_connection_failed)
	if not multiplayer.server_disconnected.is_connected(online_client_server_disconnected):
		multiplayer.server_disconnected.connect(online_client_server_disconnected)


func online_create_room(private_room: bool, mode_name: String) -> void:
	if multiplayer.multiplayer_peer == null:
		online_set_status("Not connected to the dedicated server.")
		return

	online_server_create_room.rpc_id(1, private_room, mode_name)


func online_join_private_room(join_code: String) -> void:
	if multiplayer.multiplayer_peer == null:
		online_set_status("Not connected to the dedicated server.")
		return

	online_server_join_private_room.rpc_id(1, join_code.strip_edges().to_upper())


func online_request_public_rooms() -> void:
	if multiplayer.multiplayer_peer == null:
		online_set_status("Not connected to the dedicated server.")
		return

	online_server_request_public_rooms.rpc_id(1)


func online_join_public_room(room_id: String) -> void:
	if multiplayer.multiplayer_peer == null:
		online_set_status("Not connected to the dedicated server.")
		return

	online_server_join_public_room.rpc_id(1, room_id)


@rpc("any_peer", "reliable")
func online_server_create_room(private_room: bool, mode_name: String) -> void:
	if not multiplayer.is_server():
		return

	var host_id: int = multiplayer.get_remote_sender_id()
	var room_id: String = online_make_room_id()
	var join_code: String = online_make_join_code() if private_room else "PUBLIC"

	online_rooms[room_id] = {
		"room_id": room_id,
		"join_code": join_code,
		"private": private_room,
		"mode": mode_name,
		"host_id": host_id,
		"players": [host_id],
		"max_players": ONLINE_MAX_ROOM_PLAYERS
	}
	online_player_room[host_id] = room_id
	online_client_room_created.rpc_id(host_id, room_id, join_code, private_room)
	online_server_broadcast_room_update(room_id)


@rpc("any_peer", "reliable")
func online_server_join_private_room(join_code: String) -> void:
	if not multiplayer.is_server():
		return

	var peer_id: int = multiplayer.get_remote_sender_id()
	for room_id in online_rooms.keys():
		var room: Dictionary = online_rooms[room_id]
		if bool(room["private"]) and str(room["join_code"]) == join_code:
			online_server_add_peer_to_room(peer_id, room_id)
			return

	online_client_lobby_error.rpc_id(peer_id, "No private room found for that code.")


@rpc("any_peer", "reliable")
func online_server_request_public_rooms() -> void:
	if not multiplayer.is_server():
		return

	var peer_id: int = multiplayer.get_remote_sender_id()
	var public_list: Array = []
	for room_id in online_rooms.keys():
		var room: Dictionary = online_rooms[room_id]
		if not bool(room["private"]):
			public_list.append({
				"room_id": room_id,
				"mode": str(room["mode"]),
				"players": (room["players"] as Array).size(),
				"max_players": int(room["max_players"])
			})

	online_client_public_rooms.rpc_id(peer_id, public_list)


@rpc("any_peer", "reliable")
func online_server_join_public_room(room_id: String) -> void:
	if not multiplayer.is_server():
		return

	var peer_id: int = multiplayer.get_remote_sender_id()
	if not online_rooms.has(room_id):
		online_client_lobby_error.rpc_id(peer_id, "That public room no longer exists.")
		return

	var room: Dictionary = online_rooms[room_id]
	if bool(room["private"]):
		online_client_lobby_error.rpc_id(peer_id, "That room is private.")
		return

	online_server_add_peer_to_room(peer_id, room_id)


func online_server_add_peer_to_room(peer_id: int, room_id: String) -> void:
	var room: Dictionary = online_rooms[room_id]
	var players: Array = room["players"] as Array
	if players.size() >= int(room["max_players"]):
		online_client_lobby_error.rpc_id(peer_id, "That room is full.")
		return

	if not players.has(peer_id):
		players.append(peer_id)
	room["players"] = players
	online_rooms[room_id] = room
	online_player_room[peer_id] = room_id
	online_client_room_joined.rpc_id(peer_id, room_id)
	online_server_broadcast_room_update(room_id)



func online_server_broadcast_room_update(room_id: String) -> void:
	if not multiplayer.is_server():
		return
	if not online_rooms.has(room_id):
		return

	var room: Dictionary = online_rooms[room_id]
	var players: Array = room["players"] as Array
	var player_count: int = players.size()
	var max_players: int = int(room["max_players"])
	var join_code: String = str(room["join_code"])
	var private_room: bool = bool(room["private"])
	var mode_name: String = str(room["mode"])
	var host_id: int = int(room["host_id"])

	for player_peer in players:
		online_client_room_update.rpc_id(int(player_peer), room_id, join_code, private_room, mode_name, player_count, max_players, host_id)


@rpc("authority", "reliable")
func online_client_room_update(room_id: String, join_code: String, private_room: bool, mode_name: String, player_count: int, max_players: int, host_id: int) -> void:
	online_current_room_id = room_id
	online_current_join_code = join_code
	online_current_room_private = private_room
	online_current_party_count = player_count
	online_current_party_max = max_players
	online_current_room_host_id = host_id
	selected_game_mode = mode_name
	confirm_player_is_blue()
	online_update_lobby_labels()

@rpc("authority", "reliable")
func online_client_room_created(room_id: String, join_code: String, private_room: bool) -> void:
	online_current_room_id = room_id
	online_current_join_code = "PUBLIC"
	online_current_room_private = false
	online_current_room_host_id = multiplayer.get_unique_id()
	online_current_party_count = 1
	online_current_party_max = ONLINE_MAX_ROOM_PLAYERS
	online_set_status("PUBLIC ROOM READY. Waiting for players.")


@rpc("authority", "reliable")
func online_client_room_joined(room_id: String) -> void:
	online_current_room_id = room_id
	confirm_player_is_blue()
	online_set_status("Joined room as Blue Team. Waiting for host.")


@rpc("authority", "reliable")
func online_client_public_rooms(public_rooms: Array) -> void:
	if online_public_rooms_item_list == null:
		return

	online_public_rooms_item_list.clear()
	online_public_room_ids.clear()
	for room in public_rooms:
		var data: Dictionary = room as Dictionary
		online_public_room_ids.append(str(data["room_id"]))
		online_public_rooms_item_list.add_item("Public Room  |  " + str(data["mode"]).to_upper() + "  |  Party " + str(data["players"]) + "/" + str(data["max_players"]))

	online_set_status("Public rooms updated: " + str(public_rooms.size()))


@rpc("authority", "reliable")
func online_client_lobby_error(message: String) -> void:
	online_set_status(message)


func online_server_peer_disconnected(peer_id: int) -> void:
	if not online_player_room.has(peer_id):
		return

	var room_id: String = str(online_player_room[peer_id])
	online_player_room.erase(peer_id)
	if not online_rooms.has(room_id):
		return

	var room: Dictionary = online_rooms[room_id]
	var players: Array = room["players"] as Array
	players.erase(peer_id)
	if players.is_empty():
		online_rooms.erase(room_id)
	else:
		room["players"] = players
		if int(room["host_id"]) == peer_id:
			room["host_id"] = int(players[0])
		online_rooms[room_id] = room
		online_server_broadcast_room_update(room_id)


func online_client_connected() -> void:
	online_clear_room_state()
	online_set_status("Connected to server. Host or join a room.")


func online_client_connection_failed() -> void:
	online_clear_room_state()
	online_set_status("Connection to server failed.")


func online_client_server_disconnected() -> void:
	online_clear_room_state()
	online_set_status("Server disconnected. Back to solo mode.")


func online_make_room_id() -> String:
	return "room_" + str(Time.get_ticks_msec()) + "_" + str(rng.randi_range(1000, 9999))


func online_make_join_code() -> String:
	var chars: String = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
	var code: String = ""
	for i: int in range(6):
		code += chars[rng.randi_range(0, chars.length() - 1)]
	return code


func setup_title_music() -> void:
	# First try to use an AudioStreamPlayer you already added as a child.
	var found_music: Node = find_child("TitleMusic", true, false)
	if found_music == null:
		found_music = find_child("MenuMusic", true, false)
	if found_music == null:
		found_music = find_child("Music", true, false)

	if found_music != null and found_music is AudioStreamPlayer:
		title_music_player = found_music as AudioStreamPlayer
	else:
		title_music_player = AudioStreamPlayer.new()
		title_music_player.name = "TitleMusic"
		add_child(title_music_player)

		var loaded_stream: AudioStream = get_title_music_stream()
		if loaded_stream != null:
			title_music_player.stream = loaded_stream

	title_music_player.bus = "Master"
	title_music_player.volume_db = TITLE_MUSIC_VOLUME_DB
	title_music_player.autoplay = false


func get_title_music_stream() -> AudioStream:
	var paths: Array[String] = [TITLE_MUSIC_PATH_1, TITLE_MUSIC_PATH_2, TITLE_MUSIC_PATH_3]

	for music_path in paths:
		if ResourceLoader.exists(music_path):
			var resource: Resource = load(music_path)
			if resource != null and resource is AudioStream:
				return resource as AudioStream

	return null


func play_title_music() -> void:
	if title_music_player == null:
		return

	if title_music_player.stream == null:
		# No music file was found. Add res://title_music.ogg, res://title_music.wav,
		# res://music/title_music.ogg, or add a child AudioStreamPlayer named TitleMusic.
		return

	if title_music_tween != null:
		title_music_tween.kill()
		title_music_tween = null

	title_music_player.volume_db = TITLE_MUSIC_VOLUME_DB

	if not title_music_player.playing:
		title_music_player.play()


func fade_out_title_music() -> void:
	if title_music_player == null:
		return

	if not title_music_player.playing:
		return

	if title_music_tween != null:
		title_music_tween.kill()

	title_music_tween = create_tween()
	title_music_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	title_music_tween.tween_property(title_music_player, "volume_db", -60.0, TITLE_MUSIC_FADE_SECONDS)
	title_music_tween.tween_callback(title_music_player.stop)


func set_player_ui_visible(visible_now: bool) -> void:
	# The player owns HP / stamina / ammo / crosshair UI in a separate CanvasLayer.
	# Hide it on the title screen so the menu looks clean.
	var root: Window = get_tree().root
	if root == null:
		return

	var player_ui: Node = root.find_child("PlayerUI", true, false)
	if player_ui != null and player_ui is CanvasLayer:
		(player_ui as CanvasLayer).visible = visible_now



func set_title_brief_button_position(brief_open: bool) -> void:
	if title_brief_button == null:
		return

	var button_size: Vector2 = Vector2(480.0, 48.0)
	var center_offset: Vector2 = Vector2(-240.0, 120.0)

	# Move only the Hide Brief button when the mission brief is open.
	# This keeps the button out of the middle of the mission brief text.
	if brief_open:
		center_offset = Vector2(-240.0, 280.0)

	title_brief_button.offset_left = center_offset.x
	title_brief_button.offset_right = center_offset.x + button_size.x
	title_brief_button.offset_top = center_offset.y
	title_brief_button.offset_bottom = center_offset.y + button_size.y

func show_title_screen() -> void:

	if simple_fireworks_panel != null:
		simple_fireworks_panel.visible = false
		simple_fireworks_panel.enabled_fireworks = false

	if result_art_panel != null:
		result_art_panel.visible = false
	if result_card_panel != null:
		result_card_panel.visible = false
	if result_title_label != null:
		result_title_label.text = ""
	if result_detail_label != null:
		result_detail_label.text = ""
	game_started = false
	title_input_lock_timer = 0.25
	title_brief_visible = false
	set_title_brief_button_position(false)

	if title_panel:
		title_panel.visible = true
	set_main_menu_controls_visible(true)
	set_title_buttons_visible_for_brief(true)
	if online_panel != null:
		online_panel.visible = false

	if title_brief_label:
		title_brief_label.visible = false
		title_brief_label.text = get_title_brief_text()

	if title_mode_button:
		title_mode_button.text = get_mode_button_text()

	if title_subtitle_label:
		title_subtitle_label.text = "Night battle in the Mountains  |  " + get_game_mode_display_name(selected_game_mode)

	if result_panel:
		result_panel.visible = false
	if result_label:
		result_label.visible = false
	if result_menu_button:
		result_menu_button.visible = false

	if battle_label:
		battle_label.visible = false

	if minimap_panel:
		minimap_panel.visible = false

	set_player_ui_visible(false)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	play_title_music()
	get_tree().paused = true


func update_title_screen_input(delta: float) -> void:
	if title_input_lock_timer > 0.0:
		title_input_lock_timer -= delta
		return

	if Input.is_key_pressed(KEY_ENTER) or Input.is_key_pressed(KEY_KP_ENTER) or Input.is_key_pressed(KEY_SPACE):
		start_game_from_title()
	elif Input.is_key_pressed(KEY_B):
		toggle_title_brief()
		title_input_lock_timer = 0.25
	elif Input.is_key_pressed(KEY_M):
		cycle_game_mode()
		title_input_lock_timer = 0.25
	elif Input.is_key_pressed(KEY_ESCAPE):
		quit_from_title()


func toggle_title_brief() -> void:
	title_brief_visible = not title_brief_visible

	if title_brief_label != null:
		title_brief_label.text = get_title_brief_text()
		title_brief_label.visible = title_brief_visible

	set_title_buttons_visible_for_brief(not title_brief_visible)

	if title_brief_button != null:
		title_brief_button.visible = true
		title_brief_button.text = "HIDE BRIEF" if title_brief_visible else "MISSION BRIEF"
		set_title_brief_button_position(title_brief_visible)

func quit_from_title() -> void:
	save_and_quit_game()



func update_title_mode_button_text() -> void:
	if title_mode_button != null:
		title_mode_button.text = get_mode_button_text()

func update_title_brief_for_mode() -> void:
	if title_hint_label != null:
		title_hint_label.text = get_mode_summary_text()


func get_mode_button_text() -> String:
	if selected_game_mode == GAME_MODE_ELIMINATION:
		return "MODE: TEAM ELIMINATION"
	if selected_game_mode == GAME_MODE_CTF:
		return "MODE: CAPTURE THE FLAG"
	if selected_game_mode == GAME_MODE_MANHUNT:
		return "MODE: MANHUNT"
	if selected_game_mode == GAME_MODE_COMMANDER:
		return "MODE: COMMANDER"
	if selected_game_mode == GAME_MODE_KING_HILL:
		return "MODE: KING OF THE HILL"
	if selected_game_mode == GAME_MODE_FINAL_BOSS:
		return "MODE: FINAL SHOWDOWN"
	return "MODE: UNKNOWN"

func get_game_mode_display_name(mode_name: String) -> String:
	if mode_name == GAME_MODE_CTF:
		return "CAPTURE THE FLAG"
	elif mode_name == GAME_MODE_MANHUNT:
		return "MANHUNT"
	elif mode_name == GAME_MODE_COMMANDER:
		return "COMMANDER"
	elif mode_name == GAME_MODE_KING_HILL:
		return "KING OF THE HILL"
	return "TEAM ELIMINATION"


func get_title_brief_text() -> String:
	if selected_game_mode == GAME_MODE_ELIMINATION:
		return "MISSION BRIEF: TEAM ELIMINATION\n\nObjective: Knock out the Red team before they knock out your team.\n\nPersonal eliminations earn money and achievements. CPU eliminations only help the team score.\n\nUse cover, watch the ridges, and take the helicopter only when it is safe."

	if selected_game_mode == GAME_MODE_CTF:
		return "MISSION BRIEF: CAPTURE THE FLAG\n\nObjective: Capture the Red flag and return it to your base.\n\nProtect your flag, push across the map, and escort the flag carrier.\n\nFirst team to the capture goal wins."

	if selected_game_mode == GAME_MODE_MANHUNT:
		return "MISSION BRIEF: MANHUNT\n\nObjective: Survive as the hunted target or quickly find the hunted target.\n\nIf you are hunted, keep moving and escape as long as possible.\n\nIf Red is hunted, find the target fast for a larger reward."

	if selected_game_mode == GAME_MODE_COMMANDER:
		return "MISSION BRIEF: COMMANDER\n\nObjective: Protect your commander and eliminate the Red commander.\n\nMove with your team, avoid reckless pushes, and attack when the enemy commander is exposed.\n\nThe commander objective matters more than random eliminations."

	if selected_game_mode == GAME_MODE_KING_HILL:
		return "MISSION BRIEF: KING OF THE HILL\n\nObjective: Control the mountain relay point.\n\nStand inside the hill zone to score. Clear enemies out of the zone and hold it as long as possible.\n\nFirst team to the score goal wins."

	if selected_game_mode == GAME_MODE_FINAL_BOSS:
		return "MISSION BRIEF: FINAL SHOWDOWN\n\nObjective: Defeat the Final Boss.\n\nThe boss has 500 HP and multiple attacks. Blue CPUs can help weaken him, but only you can finish the last part of the fight.\n\nWin to unlock the final reward mode."

	return "MISSION BRIEF\n\nSelect a mode and complete the objective."

func cycle_game_mode() -> void:
	var available_modes: Array[String] = get_available_game_modes()
	var index: int = available_modes.find(selected_game_mode)

	if index < 0:
		index = 0
	else:
		index = (index + 1) % available_modes.size()

	selected_game_mode = available_modes[index]

	if title_mode_button != null:
		title_mode_button.text = get_mode_button_text()
	update_title_brief_for_mode()

	if title_brief_label != null:
		title_brief_label.text = get_title_brief_text()

func get_available_game_modes() -> Array[String]:
	var modes: Array[String] = [
		GAME_MODE_ELIMINATION,
		GAME_MODE_CTF,
		GAME_MODE_MANHUNT,
		GAME_MODE_COMMANDER,
		GAME_MODE_KING_HILL
	]

	if is_final_boss_unlocked():
		modes.append(GAME_MODE_FINAL_BOSS)

	return modes

func start_game_from_title() -> void:

	if simple_fireworks_panel != null:
		simple_fireworks_panel.visible = false
		simple_fireworks_panel.enabled_fireworks = false

	if result_art_panel != null:
		result_art_panel.visible = false
	if result_card_panel != null:
		result_card_panel.visible = false
	if result_title_label != null:
		result_title_label.text = ""
	if result_detail_label != null:
		result_detail_label.text = ""
	if selected_game_mode == GAME_MODE_FINAL_BOSS and not is_final_boss_unlocked():
		selected_game_mode = GAME_MODE_ELIMINATION
		if title_mode_button != null:
			title_mode_button.text = get_mode_button_text()
		return
	if game_started:
		return

	if selected_game_mode == GAME_MODE_ELIMINATION:
		reveal_achievement("team_elim_win")
	elif selected_game_mode == GAME_MODE_MANHUNT:
		reveal_achievement("manhunt_played")
		reveal_achievement("manhunt_survivor")
		reveal_achievement("red_hunted_survivor")
	elif selected_game_mode == GAME_MODE_COMMANDER:
		unlock_achievement("commander_played")
		reveal_achievement("commander_breaker")
	elif selected_game_mode == GAME_MODE_KING_HILL:
		reveal_achievement("hill_entered")
		reveal_achievement("hill_holder")
	elif selected_game_mode == GAME_MODE_CTF:
		reveal_achievement("flag_pickup")
		reveal_achievement("flag_capture")
		reveal_achievement("two_flags_match")

	close_shop_if_open()
	apply_shop_upgrades()
	game_started = true
	fade_out_title_music()
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	if title_panel:
		title_panel.visible = false

	if result_panel:
		result_panel.visible = false
	if result_label:
		result_label.visible = false
	if result_menu_button:
		result_menu_button.visible = false

	if battle_label:
		battle_label.visible = true

	if minimap_panel:
		minimap_panel.visible = selected_game_mode != GAME_MODE_MANHUNT

	set_player_ui_visible(true)
	reset_all_helicopters_for_new_match()
	reset_all_cpus_for_new_match()
	setup_final_boss_mode_if_needed()
	apply_mode_balance_settings()
	start_match()
	setup_final_boss_mode_if_needed()
	setup_manhunt_teams_for_match()
	apply_mode_balance_settings()
	print("MATCH TIMER SET: ", selected_game_mode, " = ", int(match_time_remaining), " seconds")

func reset_player_for_new_match() -> void:
	if player == null or not is_instance_valid(player):
		find_player()

	if player == null or not is_instance_valid(player):
		return

	# Always deploy from Blue base with full health/stamina/ammo.
	# This prevents starting the next match behind enemy territory or wounded.
	if player.has_method("reset_for_new_match"):
		player.call("reset_for_new_match", BLUE_SPAWN_POSITION)
		return

	player.global_position = BLUE_SPAWN_POSITION
	player.rotation_degrees = Vector3.ZERO
	if object_has_property(player, "velocity"):
		player.set("velocity", Vector3.ZERO)
	if object_has_property(player, "player_dead"):
		player.set("player_dead", false)
	if object_has_property(player, "player_health"):
		var max_health: int = 20
		if object_has_property(player, "current_max_health"):
			max_health = int(player.get("current_max_health"))
		player.set("player_health", max_health)
	if object_has_property(player, "stamina") and object_has_property(player, "current_max_stamina"):
		player.set("stamina", float(player.get("current_max_stamina")))
	if object_has_property(player, "ammo") and object_has_property(player, "MAX_AMMO"):
		player.set("ammo", int(player.get("MAX_AMMO")))
	if player.has_method("update_ui"):
		player.call("update_ui")


func start_match() -> void:
	reset_match_state_for_selected_mode()
	find_player()
	reset_player_for_new_match()
	choose_team_plan("red")
	choose_team_plan("blue")

	var red_spawn_count: int = RED_ACTIVE_LIMIT
	var blue_spawn_count: int = get_blue_npc_active_limit()

	# Manhunt is now a duel mode: player vs one red CPU.
	# No extra blue teammates. No extra red squad.
	if selected_game_mode == GAME_MODE_MANHUNT:
		red_spawn_count = 1
		blue_spawn_count = 0

	for i in range(red_spawn_count):
		spawn_one_unit("red")

	for i in range(blue_spawn_count):
		spawn_one_unit("blue")

	setup_selected_game_mode_objects()


func reset_match_state_for_selected_mode() -> void:
	game_over = false
	game_result = ""
	player_deaths = 0
	player_kills = 0
	player_headshots = 0
	match_eliminations = 0
	match_headshots = 0
	match_helicopter_eliminations = 0
	match_flag_captures = 0
	match_hill_rewards = 0
	red_kills = 0
	blue_kills = 0
	red_spawned_total = 0
	blue_spawned_total = 0
	red_respawn_timer = 0.0
	blue_respawn_timer = 0.0
	match_time_remaining = MATCH_TIME_SECONDS
	manhunt_survival_reward_timer = 0.0
	hill_reward_timer = 0.0
	red_ctf_score = 0
	blue_ctf_score = 0
	red_flag_carrier = null
	blue_flag_carrier = null
	red_flag_at_base = true
	blue_flag_at_base = true
	manhunt_hunted_team = ""
	manhunt_hunted_target = null
	red_commander = null
	blue_commander = null
	blue_hill_score = 0.0
	red_hill_score = 0.0
	clear_objective_nodes()
	clear_no_helicopter_flags()



# ---------------- MINI MAP ----------------
func create_minimap() -> void:
	if battle_ui_layer == null:
		return

	minimap_panel = MiniMapPanel.new()
	minimap_panel.name = "MiniMapPanel"
	minimap_panel.manager = self

	# Top-right corner.
	minimap_panel.anchor_left = 1.0
	minimap_panel.anchor_right = 1.0
	minimap_panel.anchor_top = 0.0
	minimap_panel.anchor_bottom = 0.0

	minimap_panel.offset_left = -(MINIMAP_SIZE + MINIMAP_MARGIN_RIGHT)
	minimap_panel.offset_right = -MINIMAP_MARGIN_RIGHT
	minimap_panel.offset_top = MINIMAP_MARGIN_TOP
	minimap_panel.offset_bottom = MINIMAP_MARGIN_TOP + MINIMAP_SIZE

	minimap_panel.z_index = 100
	battle_ui_layer.add_child(minimap_panel)


func draw_minimap_content(canvas: Control) -> void:
	if selected_game_mode == GAME_MODE_MANHUNT:
		return

	var map_size: Vector2 = canvas.size

	# Background.
	canvas.draw_rect(
		Rect2(Vector2.ZERO, map_size),
		Color(0.0, 0.0, 0.0, 0.55),
		true
	)

	# Border.
	canvas.draw_rect(
		Rect2(Vector2.ZERO, map_size),
		Color(1.0, 1.0, 1.0, 0.85),
		false,
		2.0
	)

	# Center lines.
	canvas.draw_line(
		Vector2(map_size.x * 0.5, 0.0),
		Vector2(map_size.x * 0.5, map_size.y),
		Color(1.0, 1.0, 1.0, 0.18),
		1.0
	)

	canvas.draw_line(
		Vector2(0.0, map_size.y * 0.5),
		Vector2(map_size.x, map_size.y * 0.5),
		Color(1.0, 1.0, 1.0, 0.18),
		1.0
	)

	# Friendly blue team = green dots.
	for unit in blue_units:
		draw_minimap_unit(canvas, unit, Color(0.0, 1.0, 0.15, 1.0), MINIMAP_DOT_SIZE)

	# Enemy red team = red dots.
	for unit in red_units:
		draw_minimap_unit(canvas, unit, Color(1.0, 0.05, 0.03, 1.0), MINIMAP_DOT_SIZE)

	# Final Boss fallback marker if needed.
	draw_final_boss_minimap_fallback(canvas)

	# Player = white direction arrow.
	if player != null and is_instance_valid(player):
		draw_minimap_player_arrow(canvas, player)

	# Flags/objectives = diamonds/rings.
	draw_minimap_flags(canvas)
	draw_minimap_special_objectives(canvas)

	# Helicopters = bigger dots.
	draw_minimap_helicopters(canvas)



func draw_minimap_player_arrow(canvas: Control, player_node: Node3D) -> void:
	if player_node == null or not is_instance_valid(player_node):
		return

	var map_pos: Vector2 = world_to_minimap_position(canvas, player_node.global_position)
	var forward_3d: Vector3 = -player_node.global_transform.basis.z
	var forward_2d: Vector2 = Vector2(forward_3d.x, forward_3d.z)

	if forward_2d.length() < 0.01:
		forward_2d = Vector2(0.0, -1.0)
	else:
		forward_2d = forward_2d.normalized()

	var right_2d: Vector2 = Vector2(-forward_2d.y, forward_2d.x)
	var nose: Vector2 = map_pos + forward_2d * 11.0
	var left: Vector2 = map_pos - forward_2d * 7.0 - right_2d * 6.0
	var right: Vector2 = map_pos - forward_2d * 7.0 + right_2d * 6.0

	var outline: PackedVector2Array = PackedVector2Array([
		nose + forward_2d * 2.0,
		left - right_2d * 1.8,
		right + right_2d * 1.8
	])
	canvas.draw_colored_polygon(outline, Color(0.0, 0.0, 0.0, 0.95))

	var arrow: PackedVector2Array = PackedVector2Array([nose, left, right])
	canvas.draw_colored_polygon(arrow, Color(1.0, 1.0, 1.0, 1.0))

func draw_minimap_unit(canvas: Control, unit: CharacterBody3D, dot_color: Color, dot_size: float) -> void:
	if unit == null or not is_instance_valid(unit):
		return

	var dead_value: Variant = unit.get_meta("dead", false)
	if bool(dead_value):
		return

	if unit.has_meta("is_final_boss"):
		var map_pos: Vector2 = world_to_minimap_position(canvas, unit.global_position)
		canvas.draw_circle(map_pos, dot_size * 7.0 + 4.0, Color(0.0, 0.0, 0.0, 0.98))
		canvas.draw_circle(map_pos, dot_size * 7.0, Color(1.0, 0.0, 0.0, 1.0))
		canvas.draw_circle(map_pos, dot_size * 3.6, Color(0.35, 0.0, 0.0, 1.0))
		canvas.draw_circle(map_pos, dot_size * 1.2, Color(1.0, 0.95, 0.25, 1.0))
		return

	if unit.has_meta("is_final_boss_guard"):
		draw_minimap_position(canvas, unit.global_position, Color(1.0, 0.20, 0.05, 1.0), dot_size * 1.55)
		return

	draw_minimap_position(canvas, unit.global_position, dot_color, dot_size)

func draw_minimap_flags(canvas: Control) -> void:
	if selected_game_mode != GAME_MODE_CTF:
		return

	draw_minimap_flag_position(canvas, get_red_flag_position(), Color(1.0, 0.05, 0.03, 1.0))
	draw_minimap_flag_position(canvas, get_blue_flag_position(), Color(0.0, 0.45, 1.0, 1.0))


func draw_minimap_flag_position(canvas: Control, world_position: Vector3, flag_color: Color) -> void:
	var map_pos: Vector2 = world_to_minimap_position(canvas, world_position)
	var points: PackedVector2Array = PackedVector2Array([
		map_pos + Vector2(0.0, -MINIMAP_FLAG_DOT_SIZE),
		map_pos + Vector2(MINIMAP_FLAG_DOT_SIZE, 0.0),
		map_pos + Vector2(0.0, MINIMAP_FLAG_DOT_SIZE),
		map_pos + Vector2(-MINIMAP_FLAG_DOT_SIZE, 0.0)
	])
	canvas.draw_colored_polygon(points, Color(0.0, 0.0, 0.0, 0.9))
	var inner: PackedVector2Array = PackedVector2Array([
		map_pos + Vector2(0.0, -MINIMAP_FLAG_DOT_SIZE + 2.0),
		map_pos + Vector2(MINIMAP_FLAG_DOT_SIZE - 2.0, 0.0),
		map_pos + Vector2(0.0, MINIMAP_FLAG_DOT_SIZE - 2.0),
		map_pos + Vector2(-MINIMAP_FLAG_DOT_SIZE + 2.0, 0.0)
	])
	canvas.draw_colored_polygon(inner, flag_color)


func draw_minimap_helicopters(canvas: Control) -> void:
	var helicopters: Array[Node] = get_tree().get_nodes_in_group("Helicopter")

	for heli_node in helicopters:
		if heli_node == null or not is_instance_valid(heli_node):
			continue

		if not heli_node is Node3D:
			continue

		if heli_node.has_method("should_show_on_minimap"):
			if not bool(heli_node.call("should_show_on_minimap")):
				continue

		var heli: Node3D = heli_node as Node3D
		var heli_color: Color = Color(1.0, 1.0, 0.0, 1.0)

		if heli_node.has_method("get_pilot_team"):
			var team: String = str(heli_node.call("get_pilot_team"))

			if team == "red":
				heli_color = Color(1.0, 0.05, 0.03, 1.0)
			elif team == "blue":
				heli_color = Color(0.0, 1.0, 0.15, 1.0)

		draw_minimap_position(canvas, heli.global_position, heli_color, MINIMAP_HELI_DOT_SIZE)


func draw_minimap_position(canvas: Control, world_position: Vector3, dot_color: Color, dot_size: float) -> void:
	var map_pos: Vector2 = world_to_minimap_position(canvas, world_position)

	# Dark outline first so the dot shows up on all backgrounds.
	canvas.draw_circle(
		map_pos,
		dot_size + 1.5,
		Color(0.0, 0.0, 0.0, 0.9)
	)

	canvas.draw_circle(
		map_pos,
		dot_size,
		dot_color
	)


func world_to_minimap_position(canvas: Control, world_position: Vector3) -> Vector2:
	var map_size: Vector2 = canvas.size

	var x_ratio: float = inverse_lerp(MIN_BOUND, MAX_BOUND, world_position.x)
	var z_ratio: float = inverse_lerp(MIN_BOUND, MAX_BOUND, world_position.z)

	x_ratio = clamp(x_ratio, 0.0, 1.0)
	z_ratio = clamp(z_ratio, 0.0, 1.0)

	return Vector2(
		x_ratio * map_size.x,
		z_ratio * map_size.y
	)


func update_battle_ui() -> void:
	if battle_label == null:
		return

	battle_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	battle_label.position = Vector2(0.0, 10.0)
	battle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	if selected_game_mode == GAME_MODE_CTF:
		battle_label.text = (
			"CTF  TIME: " + format_match_time(match_time_remaining) +
			"     BLUE: " + str(blue_ctf_score) + "/" + str(CTF_CAPTURE_LIMIT) +
			"     RED: " + str(red_ctf_score) + "/" + str(CTF_CAPTURE_LIMIT) +
			"     " + get_ctf_flag_status_text()
		)
		check_ctf_game_over()
		return
	elif selected_game_mode == GAME_MODE_MANHUNT:
		battle_label.text = "MANHUNT  TIME: " + format_match_time(match_time_remaining) + "     HUNTED: " + get_manhunt_status_text()
		return
	elif selected_game_mode == GAME_MODE_COMMANDER:
		battle_label.text = "COMMANDER  TIME: " + format_match_time(match_time_remaining) + "     " + get_commander_status_text()
		return
	elif selected_game_mode == GAME_MODE_KING_HILL:
		battle_label.text = "KING OF THE HILL  TIME: " + format_match_time(match_time_remaining) + "     BLUE: " + str(int(blue_hill_score)) + "/" + str(int(HILL_SCORE_TO_WIN)) + "     RED: " + str(int(red_hill_score)) + "/" + str(int(HILL_SCORE_TO_WIN))
		return

	var red_total_left: int = get_red_total_left()
	var blue_total_left: int = get_blue_total_left()

	battle_label.text = (
		"TIME: " + format_match_time(match_time_remaining) +
		"     RED LEFT: " + str(red_total_left) +
		"     BLUE LEFT: " + str(blue_total_left)
	)

	check_game_over(red_total_left, blue_total_left)

func get_red_total_left() -> int:
	if selected_game_mode == GAME_MODE_MANHUNT:
		if manhunt_hunted_team == "red":
			return red_units.size()

		var red_left_to_spawn_mh: int = max(get_red_reserve_limit_for_mode() - red_spawned_total, 0)
		return red_units.size() + red_left_to_spawn_mh

	var red_left_to_spawn: int = max(get_red_reserve_limit_for_mode() - red_spawned_total, 0)
	return red_units.size() + red_left_to_spawn

func get_blue_total_left() -> int:
	if selected_game_mode == GAME_MODE_MANHUNT:
		if manhunt_hunted_team == "blue":
			return 0 if is_player_dead() else 1

		var blue_left_to_spawn_mh: int = max(get_blue_reserve_limit_for_mode() - blue_spawned_total, 0)
		return blue_units.size() + blue_left_to_spawn_mh

	var blue_left_to_spawn: int = max(get_blue_reserve_limit_for_mode() - blue_spawned_total - player_deaths, 0)
	return blue_units.size() + blue_left_to_spawn + (0 if is_player_dead() else 1)

func format_match_time(seconds_left: float) -> String:
	var safe_seconds: int = max(int(ceil(seconds_left)), 0)
	var minutes: int = int(safe_seconds / 60)
	var seconds: int = safe_seconds % 60

	if seconds < 10:
		return str(minutes) + ":0" + str(seconds)

	return str(minutes) + ":" + str(seconds)


func show_time_expired_result() -> void:
	if game_over: return
	if selected_game_mode == GAME_MODE_MANHUNT:
		if manhunt_hunted_team == "blue" and manhunt_hunted_target == player:
			if not is_player_dead():
				unlock_achievement("manhunt_survivor")
				show_result_screen("VICTORY", "You survived the 4-minute Manhunt.")
			else:
				show_result_screen("DEFEAT", "You were caught before the Manhunt timer ended.")
			return
		if manhunt_hunted_team == "red":
			if manhunt_hunted_target != null and is_instance_valid(manhunt_hunted_target):
				show_result_screen("DEFEAT", "The Red target survived the Manhunt.")
			else:
				unlock_achievement("red_hunted_survivor")
				show_result_screen("VICTORY", "The Red target was hunted down.")
			return
	if selected_game_mode == GAME_MODE_ELIMINATION:
		var blue_left: int = get_blue_total_left()
		var red_left: int = get_red_total_left()
		if blue_left > red_left: show_result_screen("VICTORY", "Time expired. Blue had more units left.")
		elif red_left > blue_left: show_result_screen("DEFEAT", "Time expired. Red had more units left.")
		else: show_result_screen("DRAW", "Time expired with equal forces remaining.")
		return
	show_result_screen("TIME EXPIRED", "Time ran out.")

func update_game_timer(delta: float) -> void:
	if game_over:
		return

	if selected_game_mode == GAME_MODE_FINAL_BOSS:
		return

	match_time_remaining = max(match_time_remaining - delta, 0.0)

	if match_time_remaining <= 0.0:
		show_time_expired_result()

func end_game_by_timer() -> void:
	if game_over:
		return

	if selected_game_mode == GAME_MODE_MANHUNT:
		if manhunt_hunted_team == "blue":
			show_result_screen("VICTORY - YOU SURVIVED THE HUNT", "Time expired. The hunted side survived.")
		else:
			show_result_screen("DEFEAT - RED TARGET ESCAPED", "Time expired. The hunted target survived.")
		return

	if selected_game_mode == GAME_MODE_KING_HILL:
		if blue_hill_score > red_hill_score:
			show_result_screen("VICTORY - HILL HELD", "Blue controlled the hill longer.")
		elif red_hill_score > blue_hill_score:
			show_result_screen("DEFEAT - RED HELD THE HILL", "Red controlled the hill longer.")
		else:
			show_result_screen("DRAW - HILL CONTESTED", "Both teams tied on hill control.")
		return

	if selected_game_mode == GAME_MODE_CTF:
		if blue_ctf_score > red_ctf_score:
			show_result_screen("VICTORY - TIME UP", "Blue had more flag captures.")
		elif red_ctf_score > blue_ctf_score:
			show_result_screen("DEFEAT - TIME UP", "Red had more flag captures.")
		else:
			show_result_screen("DRAW - TIME UP", "Both teams had the same flag captures.")
		return

	var red_total_left: int = get_red_total_left()
	var blue_total_left: int = get_blue_total_left()
	var timer_result_line: String = (
		"Time expired. Red left: " + str(red_total_left) +
		" | Blue left: " + str(blue_total_left)
	)

	if blue_total_left > red_total_left:
		show_result_screen("VICTORY - TIME UP", timer_result_line)
	elif red_total_left > blue_total_left:
		show_result_screen("DEFEAT - TIME UP", timer_result_line)
	else:
		show_result_screen("DRAW - TIME UP", timer_result_line)


func record_player_kill(headshot: bool, from_helicopter: bool = false) -> void:
	player_kills += 1
	blue_kills += 1
	match_eliminations += 1

	if headshot:
		player_headshots += 1
		match_headshots += 1

	record_elimination(headshot, from_helicopter)

	if from_helicopter:
		match_helicopter_eliminations += 1

	unlock_achievement("first_elim")

	if match_headshots >= 10:
		unlock_achievement("ten_headshots_match")

	if match_helicopter_eliminations >= 5:
		unlock_achievement("helicopter_ace")

	if match_eliminations >= 5:
		unlock_achievement("five_elims_match")
	if match_eliminations >= 10:
		unlock_achievement("ten_elims_match")
	if match_headshots >= 1:
		unlock_achievement("first_headshot")

	update_lifetime_elimination_achievements()

func check_game_over(red_total_left: int, blue_total_left: int) -> void:
	if selected_game_mode != GAME_MODE_ELIMINATION:
		return
	if game_over:
		return

	if red_total_left <= 0:
		show_result_screen("VICTORY")
	elif blue_total_left <= 0:
		show_result_screen("DEFEAT")


func show_result_screen(result: String, extra_line: String = "") -> void:
	if selected_game_mode == GAME_MODE_FINAL_BOSS and result.begins_with("VICTORY") and final_boss_current_hp > 0:
		print("BLOCKED FALSE FINAL BOSS VICTORY. Boss HP left: ", final_boss_current_hp)
		return

	hide_boss_health_ui()
	game_over = true
	game_result = result
	award_manhunt_survival_bonus_if_needed(result)
	unlock_result_achievements(result)
	if selected_game_mode == GAME_MODE_FINAL_BOSS and result.begins_with("VICTORY"):
		unlock_final_boss_completion_rewards()
	else:
		save_shop_data()

	if result_panel != null:
		result_panel.visible = true
		if result.begins_with("VICTORY"):
			result_panel.color = Color(0.0, 0.045, 0.055, 0.90)
		elif result.begins_with("DEFEAT"):
			result_panel.color = Color(0.10, 0.0, 0.0, 0.90)
		else:
			result_panel.color = Color(0.0, 0.0, 0.0, 0.86)

	# Old custom art panel disabled. It looked bad.
	if result_art_panel != null:
		result_art_panel.visible = false

	if simple_fireworks_panel != null:
		simple_fireworks_panel.enabled_fireworks = selected_game_mode == GAME_MODE_FINAL_BOSS and result.begins_with("VICTORY")
		simple_fireworks_panel.visible = simple_fireworks_panel.enabled_fireworks

	if result_card_panel != null:
		result_card_panel.visible = true

	if result_title_label != null:
		result_title_label.text = get_result_title_text(result)

		if selected_game_mode == GAME_MODE_FINAL_BOSS and result.begins_with("VICTORY"):
			result_title_label.text = "FINAL BOSS DEFEATED"
			result_title_label.add_theme_color_override("font_color", Color(0.88, 1.0, 0.55, 1.0))
		elif result.begins_with("VICTORY"):
			result_title_label.add_theme_color_override("font_color", Color(0.72, 1.0, 0.74, 1.0))
		elif result.begins_with("DEFEAT"):
			result_title_label.add_theme_color_override("font_color", Color(1.0, 0.28, 0.22, 1.0))
		else:
			result_title_label.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0, 1.0))

	if result_detail_label != null:
		result_detail_label.text = get_result_detail_text(result, extra_line)

	if result_label != null:
		result_label.visible = false
		result_label.text = ""

	if result_menu_button != null:
		if selected_game_mode == GAME_MODE_FINAL_BOSS and result.begins_with("VICTORY"):
			result_menu_button.text = "MAIN MENU"
		else:
			result_menu_button.text = "MAIN MENU"
		result_menu_button.visible = true

	animate_result_screen()
	set_player_ui_visible(false)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func return_to_main_menu() -> void:
	if is_final_boss_victory_result():
		show_final_boss_ending_credits()
		return

	fade_out_all_audio(0.75)

	game_started = false
	game_over = false
	game_result = ""
	selected_game_mode = selected_game_mode

	clear_match_world()
	hide_boss_health_ui()
	create_title_screen()
	show_title_screen()

func restart_battle() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func get_plan_name(plan: int) -> String:
	if plan == BattlePlan.ASSAULT:
		return "ASSAULT"
	elif plan == BattlePlan.HOLD:
		return "HOLD"
	elif plan == BattlePlan.FLANK_LEFT:
		return "FLANK LEFT"
	elif plan == BattlePlan.FLANK_RIGHT:
		return "FLANK RIGHT"
	elif plan == BattlePlan.FALL_BACK:
		return "FALL BACK"

	return "UNKNOWN"


# ---------------- MULTI-MODE OBJECTIVES ----------------
func setup_selected_game_mode_objects() -> void:
	clear_ctf_flags()
	clear_objective_nodes()
	clear_no_helicopter_flags()

	if selected_game_mode == GAME_MODE_CTF:
		setup_ctf_flags()
	elif selected_game_mode == GAME_MODE_MANHUNT:
		setup_manhunt_mode()
	elif selected_game_mode == GAME_MODE_COMMANDER:
		setup_commander_mode()
	elif selected_game_mode == GAME_MODE_KING_HILL:
		setup_king_hill_mode()


func uses_infinite_respawns() -> bool:
	return selected_game_mode == GAME_MODE_CTF or selected_game_mode == GAME_MODE_KING_HILL


func uses_special_objective_ai_mode() -> bool:
	return selected_game_mode == GAME_MODE_MANHUNT or selected_game_mode == GAME_MODE_COMMANDER or selected_game_mode == GAME_MODE_KING_HILL


func clear_no_helicopter_flags() -> void:
	if player != null and is_instance_valid(player):
		player.set_meta("no_helicopter", false)
	for unit in all_units:
		if unit != null and is_instance_valid(unit):
			unit.set_meta("no_helicopter", false)


func clear_objective_nodes() -> void:
	for node in objective_nodes:
		if node != null and is_instance_valid(node):
			node.queue_free()
	objective_nodes.clear()
	if manhunt_target_marker != null and is_instance_valid(manhunt_target_marker):
		manhunt_target_marker.queue_free()
	manhunt_target_marker = null
	for marker in commander_markers:
		if marker != null and is_instance_valid(marker):
			marker.queue_free()
	commander_markers.clear()
	if hill_node != null and is_instance_valid(hill_node):
		hill_node.queue_free()
	hill_node = null


func create_objective_marker(marker_name: String, position: Vector3, color: Color, label_text: String, radius: float = 1.3) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = marker_name
	root.global_position = snap_position_to_ground(position) + Vector3(0.0, 0.45, 0.0)
	add_child(root)
	objective_nodes.append(root)

	var base: MeshInstance3D = MeshInstance3D.new()
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = 0.25
	base.mesh = mesh
	base.material_override = make_material(color, 2.0)
	root.add_child(base)

	var orb: MeshInstance3D = MeshInstance3D.new()
	var orb_mesh: SphereMesh = SphereMesh.new()
	orb_mesh.radius = radius * 0.38
	orb_mesh.height = radius * 0.76
	orb.mesh = orb_mesh
	orb.position = Vector3(0.0, 1.0, 0.0)
	orb.material_override = make_material(color, 3.0)
	root.add_child(orb)

	var label: Label3D = Label3D.new()
	label.text = label_text
	label.position = Vector3(0.0, 2.2, 0.0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 42
	label.modulate = color
	label.no_depth_test = false
	root.add_child(label)
	return root


func setup_manhunt_mode() -> void:
	# 50% chance the player is hunted, 50% chance Red has a hunted target.
	if rng.randf() > 0.5:
		manhunt_hunted_team = "blue"
		manhunt_hunted_target = player
		if player != null and is_instance_valid(player):
			player.set_meta("no_helicopter", true)
		manhunt_target_marker = create_objective_marker("HuntedPlayerMarker", get_safe_player_position(), Color(0.0, 1.0, 0.25, 1.0), "YOU ARE HUNTED", 1.1)
	else:
		manhunt_hunted_team = "red"
		manhunt_hunted_target = get_best_manhunt_red_target()
		if manhunt_hunted_target != null and is_instance_valid(manhunt_hunted_target):
			manhunt_hunted_target.set_meta("no_helicopter", true)
		manhunt_target_marker = create_objective_marker("RedHuntedMarker", manhunt_hunted_target.global_position if manhunt_hunted_target != null else RED_SPAWN_POSITION, Color(1.0, 0.05, 0.03, 1.0), "HUNTED TARGET", 1.1)


func get_best_manhunt_red_target() -> Node3D:
	if red_units.size() <= 0:
		return null
	return red_units[rng.randi_range(0, red_units.size() - 1)]


func update_manhunt_mode(_delta: float) -> void:
	if selected_game_mode != GAME_MODE_MANHUNT or game_over:
		return

	if manhunt_hunted_target == null or not is_instance_valid(manhunt_hunted_target):
		if manhunt_hunted_team == "red":
			unlock_achievement("red_hunted_survivor")
			award_manhunt_hunter_victory_money()
			show_result_screen("VICTORY", "The Red hunted target was eliminated.")
		else:
			show_result_screen("DEFEAT", "The hunted target was lost.")
		return

	if manhunt_hunted_target is CharacterBody3D:
		var body: CharacterBody3D = manhunt_hunted_target as CharacterBody3D
		if body.has_meta("dead") and bool(body.get_meta("dead")):
			if manhunt_hunted_team == "red":
				unlock_achievement("red_hunted_survivor")
				award_manhunt_hunter_victory_money()
				show_result_screen("VICTORY", "The Red hunted target was eliminated.")
			else:
				show_result_screen("DEFEAT", "You were hunted.")
			return

	if manhunt_hunted_target == player and is_player_dead():
		show_result_screen("DEFEAT", "You were hunted.")
		return

	if manhunt_target_marker != null and is_instance_valid(manhunt_target_marker):
		manhunt_target_marker.global_position = manhunt_hunted_target.global_position + Vector3(0.0, MANHUNT_TARGET_MARKER_HEIGHT, 0.0)

func get_manhunt_status_text() -> String:
	if manhunt_hunted_team == "blue":
		return "YOU"
	elif manhunt_hunted_team == "red":
		return "RED TARGET"
	return "SELECTING"


func setup_commander_mode() -> void:
	blue_commander = player
	red_commander = get_best_red_commander()
	if blue_commander != null and is_instance_valid(blue_commander):
		blue_commander.set_meta("commander", true)
		commander_markers.append(create_objective_marker("BlueCommanderMarker", blue_commander.global_position, Color(0.0, 1.0, 0.25, 1.0), "BLUE COMMANDER", 1.0))
	if red_commander != null and is_instance_valid(red_commander):
		red_commander.set_meta("commander", true)
		commander_markers.append(create_objective_marker("RedCommanderMarker", red_commander.global_position, Color(1.0, 0.05, 0.03, 1.0), "RED COMMANDER", 1.0))


func get_best_red_commander() -> Node3D:
	if red_units.size() <= 0:
		return null
	return red_units[0]


func update_commander_mode(_delta: float) -> void:
	if selected_game_mode != GAME_MODE_COMMANDER or game_over:
		return
	if get_red_total_left() <= 0:
		show_result_screen("VICTORY - RED TEAM ELIMINATED")
		return
	if get_blue_total_left() <= 0:
		show_result_screen("DEFEAT - BLUE TEAM ELIMINATED")
		return
	if blue_commander == null or not is_instance_valid(blue_commander) or is_player_dead():
		show_result_screen("DEFEAT - BLUE COMMANDER DOWN")
		return
	if red_commander == null or not is_instance_valid(red_commander):
		show_result_screen("VICTORY - RED COMMANDER DOWN")
		return
	if red_commander is CharacterBody3D and bool((red_commander as CharacterBody3D).get_meta("dead", false)):
		show_result_screen("VICTORY - RED COMMANDER DOWN")
		return
	for marker in commander_markers:
		if marker == null or not is_instance_valid(marker):
			continue
		if marker.name.begins_with("Blue") and blue_commander != null:
			marker.global_position = blue_commander.global_position + Vector3(0.0, COMMANDER_MARKER_HEIGHT, 0.0)
		elif marker.name.begins_with("Red") and red_commander != null:
			marker.global_position = red_commander.global_position + Vector3(0.0, COMMANDER_MARKER_HEIGHT, 0.0)


func get_commander_status_text() -> String:
	var blue_text: String = "BLUE CMD OK" if blue_commander != null and is_instance_valid(blue_commander) and not is_player_dead() else "BLUE CMD DOWN"
	var red_text: String = "RED CMD OK" if red_commander != null and is_instance_valid(red_commander) else "RED CMD DOWN"
	return blue_text + "     " + red_text


func setup_king_hill_mode() -> void:
	blue_hill_score = 0.0
	red_hill_score = 0.0
	hill_node = create_objective_marker("HillRelayZone", HILL_POSITION, Color(1.0, 0.85, 0.1, 1.0), "RELAY HILL", HILL_RADIUS * 0.08)


func update_king_hill_mode(delta: float) -> void:
	if selected_game_mode != GAME_MODE_KING_HILL or game_over:
		return
	var blue_inside: int = count_team_in_radius("blue", HILL_POSITION, HILL_RADIUS)
	var red_inside: int = count_team_in_radius("red", HILL_POSITION, HILL_RADIUS)
	if blue_inside > red_inside:
		blue_hill_score = min(blue_hill_score + HILL_SCORE_RATE * delta, HILL_SCORE_TO_WIN)
	elif red_inside > blue_inside:
		red_hill_score = min(red_hill_score + HILL_SCORE_RATE * delta, HILL_SCORE_TO_WIN)
	if blue_hill_score >= HILL_SCORE_TO_WIN:
		show_result_screen("VICTORY - BLUE CONTROLS THE HILL")
	elif red_hill_score >= HILL_SCORE_TO_WIN:
		show_result_screen("DEFEAT - RED CONTROLS THE HILL")


func count_team_in_radius(team: String, center: Vector3, radius: float) -> int:
	var count: int = 0
	var pool: Array[CharacterBody3D] = blue_units if team == "blue" else red_units
	for unit in pool:
		if unit != null and is_instance_valid(unit) and not bool(unit.get_meta("dead", false)):
			if unit.global_position.distance_to(center) <= radius:
				count += 1
	if team == "blue" and player != null and is_instance_valid(player) and not is_player_dead():
		if player.global_position.distance_to(center) <= radius:
			count += 1
	return count


func get_special_mode_priority_target(unit: CharacterBody3D) -> Node3D:
	if unit == null or not is_instance_valid(unit):
		return null
	var team: String = str(unit.get_meta("team"))
	if selected_game_mode == GAME_MODE_MANHUNT:
		if manhunt_hunted_target != null and is_instance_valid(manhunt_hunted_target):
			if team != manhunt_hunted_team:
				return manhunt_hunted_target
		return null
	elif selected_game_mode == GAME_MODE_COMMANDER:
		if team == "blue":
			return red_commander if red_commander != null and is_instance_valid(red_commander) else null
		else:
			return blue_commander if blue_commander != null and is_instance_valid(blue_commander) else null
	elif selected_game_mode == GAME_MODE_KING_HILL:
		# Fight enemies who are close to the hill.
		var pool: Array[CharacterBody3D] = blue_units if team == "red" else red_units
		var best: Node3D = null
		var best_distance: float = HILL_CONTEST_RANGE
		for enemy in pool:
			if is_valid_target(enemy) and enemy.global_position.distance_to(HILL_POSITION) <= HILL_CONTEST_RANGE:
				var distance: float = unit.global_position.distance_to(enemy.global_position)
				if distance < best_distance:
					best = enemy
					best_distance = distance
		if team == "red" and player != null and is_instance_valid(player) and not is_player_dead() and player.global_position.distance_to(HILL_POSITION) <= HILL_CONTEST_RANGE:
			return player
		return best
	return null


func get_special_mode_goal_position_for_unit(unit: CharacterBody3D) -> Vector3:
	var team: String = str(unit.get_meta("team"))
	var phase: float = get_meta_float(unit, "phase", 0.0)
	var side: float = get_meta_float(unit, "strafe_side", 1.0)
	if selected_game_mode == GAME_MODE_MANHUNT:
		if manhunt_hunted_target != null and is_instance_valid(manhunt_hunted_target):
			if team != manhunt_hunted_team:
				return manhunt_hunted_target.global_position
			# Same team protects or hides around the hunted target.
			var base: Vector3 = manhunt_hunted_target.global_position
			return base + Vector3(cos(phase) * MANHUNT_ESCORT_RADIUS, 0.0, sin(phase) * MANHUNT_ESCORT_RADIUS)
		return get_enemy_spawn_for_team(team)
	elif selected_game_mode == GAME_MODE_COMMANDER:
		if team == "blue":
			if red_commander != null and is_instance_valid(red_commander) and rng.randf() < COMMANDER_ATTACKER_RATIO:
				return red_commander.global_position
			return get_safe_player_position() + Vector3(cos(phase) * COMMANDER_GUARD_RADIUS, 0.0, sin(phase) * COMMANDER_GUARD_RADIUS)
		else:
			if red_commander != null and is_instance_valid(red_commander) and rng.randf() > COMMANDER_ATTACKER_RATIO:
				return red_commander.global_position + Vector3(cos(phase) * COMMANDER_GUARD_RADIUS, 0.0, sin(phase) * COMMANDER_GUARD_RADIUS)
			return get_safe_player_position()
	elif selected_game_mode == GAME_MODE_KING_HILL:
		var offset: Vector3 = Vector3(cos(phase) * 18.0 * side, 0.0, sin(phase) * 18.0)
		return HILL_POSITION + offset
	return get_enemy_spawn_for_team(team)


func get_special_mode_ai_state(unit: CharacterBody3D, target: Node3D) -> String:
	var team: String = str(unit.get_meta("team"))
	var phase: float = get_meta_float(unit, "phase", 0.0)
	if selected_game_mode == GAME_MODE_MANHUNT:
		if team == manhunt_hunted_team:
			return "hide" if manhunt_hunted_target == unit else "zigzag"
		return "push" if is_valid_target(target) else "flank_search"
	elif selected_game_mode == GAME_MODE_COMMANDER:
		if bool(unit.get_meta("commander", false)):
			return "hold"
		return "push" if is_valid_target(target) else "zigzag"
	elif selected_game_mode == GAME_MODE_KING_HILL:
		return "suppress" if is_valid_target(target) and unit.global_position.distance_to(HILL_POSITION) < HILL_RADIUS else "push"
	return "advance"


func handle_player_objective_death() -> void:
	if selected_game_mode == GAME_MODE_CTF:
		if player != null and is_instance_valid(player):
			var carried_flag: String = str(player.get_meta("carrying_flag", ""))
			if carried_flag != "":
				return_flag_to_base(carried_flag)
	elif selected_game_mode == GAME_MODE_MANHUNT and manhunt_hunted_target == player:
		show_result_screen("DEFEAT - YOU WERE HUNTED")
	elif selected_game_mode == GAME_MODE_COMMANDER and blue_commander == player:
		show_result_screen("DEFEAT - BLUE COMMANDER DOWN")


func handle_unit_objective_death(unit: CharacterBody3D) -> void:
	if unit == null or not is_instance_valid(unit):
		return
	if selected_game_mode == GAME_MODE_CTF:
		var carried_flag: String = str(unit.get_meta("carrying_flag", ""))
		if carried_flag != "":
			return_flag_to_base(carried_flag)
	elif selected_game_mode == GAME_MODE_MANHUNT and manhunt_hunted_target == unit:
		if str(unit.get_meta("team")) == "red":
			award_manhunt_hunter_victory_money()
			show_result_screen("VICTORY - HUNTED TARGET DOWN")
		else:
			show_result_screen("DEFEAT - HUNTED TARGET DOWN")
	elif selected_game_mode == GAME_MODE_COMMANDER and red_commander == unit:
		show_result_screen("VICTORY - RED COMMANDER DOWN")


func draw_minimap_special_objectives(canvas: Control) -> void:
	if selected_game_mode == GAME_MODE_MANHUNT and manhunt_hunted_target != null and is_instance_valid(manhunt_hunted_target):
		draw_minimap_flag_position(canvas, manhunt_hunted_target.global_position, Color(1.0, 1.0, 0.1, 1.0))
	elif selected_game_mode == GAME_MODE_COMMANDER:
		if blue_commander != null and is_instance_valid(blue_commander):
			draw_minimap_flag_position(canvas, blue_commander.global_position, Color(0.0, 1.0, 0.2, 1.0))
		if red_commander != null and is_instance_valid(red_commander):
			draw_minimap_flag_position(canvas, red_commander.global_position, Color(1.0, 0.05, 0.03, 1.0))
	elif selected_game_mode == GAME_MODE_KING_HILL:
		draw_minimap_flag_position(canvas, HILL_POSITION, Color(1.0, 0.85, 0.1, 1.0))

# ---------------- CAPTURE THE FLAG ----------------
func setup_ctf_flags() -> void:
	clear_ctf_flags()
	red_flag_node = create_ctf_flag("red", RED_SPAWN_POSITION)
	blue_flag_node = create_ctf_flag("blue", BLUE_SPAWN_POSITION)
	red_flag_at_base = true
	blue_flag_at_base = true
	red_flag_carrier = null
	blue_flag_carrier = null
	red_ctf_score = 0
	blue_ctf_score = 0


func clear_ctf_flags() -> void:
	if red_flag_node != null and is_instance_valid(red_flag_node):
		red_flag_node.queue_free()
	if blue_flag_node != null and is_instance_valid(blue_flag_node):
		blue_flag_node.queue_free()
	red_flag_node = null
	blue_flag_node = null
	red_flag_carrier = null
	blue_flag_carrier = null
	red_flag_at_base = true
	blue_flag_at_base = true


func create_ctf_flag(team: String, base_position: Vector3) -> Node3D:
	var flag_root: Node3D = Node3D.new()
	flag_root.name = team.capitalize() + "Flag"
	flag_root.add_to_group("CTFFlag")
	flag_root.set_meta("team", team)
	add_child(flag_root)
	flag_root.global_position = snap_position_to_ground(base_position) + Vector3(0.0, CTF_FLAG_RETURN_HEIGHT, 0.0)

	var team_color: Color = Color(1.0, 0.05, 0.03, 1.0) if team == "red" else Color(0.0, 0.45, 1.0, 1.0)
	var glow_color: Color = Color(1.0, 0.2, 0.08, 1.0) if team == "red" else Color(0.0, 1.0, 0.95, 1.0)

	var pole: MeshInstance3D = MeshInstance3D.new()
	pole.name = "FlagPole"
	var pole_mesh: CylinderMesh = CylinderMesh.new()
	pole_mesh.top_radius = 0.08
	pole_mesh.bottom_radius = 0.08
	pole_mesh.height = 4.2
	pole.mesh = pole_mesh
	pole.position = Vector3(0.0, 2.1, 0.0)
	pole.material_override = make_material(Color(0.82, 0.86, 0.90, 1.0), 0.15)
	flag_root.add_child(pole)

	var cloth: MeshInstance3D = MeshInstance3D.new()
	cloth.name = "FlagCloth"
	var cloth_mesh: BoxMesh = BoxMesh.new()
	cloth_mesh.size = Vector3(2.2, 1.25, 0.10)
	cloth.mesh = cloth_mesh
	cloth.position = Vector3(1.1, 3.25, 0.0)
	cloth.material_override = make_material(team_color, 1.2)
	flag_root.add_child(cloth)

	var stripe: MeshInstance3D = MeshInstance3D.new()
	stripe.name = "FlagStripe"
	var stripe_mesh: BoxMesh = BoxMesh.new()
	stripe_mesh.size = Vector3(2.24, 0.18, 0.13)
	stripe.mesh = stripe_mesh
	stripe.position = Vector3(1.1, 3.25, 0.08)
	stripe.material_override = make_material(Color(1.0, 1.0, 1.0, 1.0), 0.9)
	flag_root.add_child(stripe)

	var orb: MeshInstance3D = MeshInstance3D.new()
	orb.name = "FlagGlowOrb"
	var orb_mesh: SphereMesh = SphereMesh.new()
	orb_mesh.radius = 0.28
	orb_mesh.height = 0.56
	orb.mesh = orb_mesh
	orb.position = Vector3(0.0, 4.35, 0.0)
	orb.material_override = make_material(glow_color, 2.5)
	flag_root.add_child(orb)

	var label: Label3D = Label3D.new()
	label.name = "FlagLabel"
	label.text = team.to_upper() + " FLAG"
	label.position = Vector3(0.0, 5.0, 0.0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 48
	label.modulate = team_color
	label.no_depth_test = false
	flag_root.add_child(label)

	return flag_root


func update_ctf_mode(delta: float) -> void:
	if selected_game_mode != GAME_MODE_CTF or game_over:
		return

	ctf_anim_time += delta
	update_ctf_flag_positions()
	check_ctf_pickups_and_captures()


func update_ctf_flag_positions() -> void:
	update_one_ctf_flag_node(red_flag_node, "red", red_flag_carrier, red_flag_at_base)
	update_one_ctf_flag_node(blue_flag_node, "blue", blue_flag_carrier, blue_flag_at_base)


func update_one_ctf_flag_node(flag_node: Node3D, team: String, carrier: Node3D, at_base: bool) -> void:
	if flag_node == null or not is_instance_valid(flag_node):
		return

	var bob: float = sin(ctf_anim_time * CTF_FLAG_BOB_SPEED) * CTF_FLAG_BOB_AMOUNT
	if carrier != null and is_instance_valid(carrier):
		flag_node.global_position = carrier.global_position + Vector3(0.0, CTF_CARRIER_FLAG_HEIGHT + bob, 0.0)
		return

	var base_position: Vector3 = RED_SPAWN_POSITION if team == "red" else BLUE_SPAWN_POSITION
	flag_node.global_position = snap_position_to_ground(base_position) + Vector3(0.0, CTF_FLAG_RETURN_HEIGHT + bob, 0.0)


func check_ctf_pickups_and_captures() -> void:
	# Return flags if the carrier died or disappeared.
	if red_flag_carrier != null and not is_valid_ctf_carrier(red_flag_carrier):
		return_flag_to_base("red")
	if blue_flag_carrier != null and not is_valid_ctf_carrier(blue_flag_carrier):
		return_flag_to_base("blue")

	# Blue side picks up red flag.
	if red_flag_carrier == null and red_flag_at_base:
		var blue_carrier: Node3D = get_nearest_ctf_carrier_candidate("blue", get_red_flag_position())
		if blue_carrier != null:
			red_flag_carrier = blue_carrier
			red_flag_at_base = false
			blue_carrier.set_meta("carrying_flag", "red")
			if blue_carrier == player:
				award_money("Flag pickup", MONEY_FLAG_PICKUP)
				unlock_achievement("flag_pickup")

	# Red side picks up blue flag.
	if blue_flag_carrier == null and blue_flag_at_base:
		var red_carrier: Node3D = get_nearest_ctf_carrier_candidate("red", get_blue_flag_position())
		if red_carrier != null:
			blue_flag_carrier = red_carrier
			blue_flag_at_base = false
			red_carrier.set_meta("carrying_flag", "blue")

	# Blue scores by bringing red flag home.
	if red_flag_carrier != null and is_instance_valid(red_flag_carrier):
		if red_flag_carrier.global_position.distance_to(BLUE_SPAWN_POSITION) <= CTF_FLAG_CAPTURE_DISTANCE:
			var player_captured_flag: bool = red_flag_carrier == player
			blue_ctf_score += 1
			red_flag_carrier.set_meta("carrying_flag", "")
			return_flag_to_base("red")
			if player_captured_flag:
				lifetime_flag_captures += 1
				award_money("Flag capture", MONEY_FLAG_CAPTURE)
				unlock_achievement("flag_capture")
				match_flag_captures += 1
				if match_flag_captures >= 2:
					unlock_achievement("two_flags_match")
			if blue_ctf_score >= CTF_CAPTURE_LIMIT:
				show_result_screen("VICTORY - BLUE CAPTURED " + str(CTF_CAPTURE_LIMIT) + " FLAGS")

	# Red scores by bringing blue flag home.
	if blue_flag_carrier != null and is_instance_valid(blue_flag_carrier):
		if blue_flag_carrier.global_position.distance_to(RED_SPAWN_POSITION) <= CTF_FLAG_CAPTURE_DISTANCE:
			red_ctf_score += 1
			blue_flag_carrier.set_meta("carrying_flag", "")
			return_flag_to_base("blue")
			if red_ctf_score >= CTF_CAPTURE_LIMIT:
				show_result_screen("DEFEAT - RED CAPTURED " + str(CTF_CAPTURE_LIMIT) + " FLAGS")


func get_nearest_ctf_carrier_candidate(team: String, flag_position: Vector3) -> Node3D:
	var best: Node3D = null
	var best_distance: float = CTF_FLAG_PICKUP_DISTANCE

	if team == "blue" and player != null and is_instance_valid(player) and not is_player_dead():
		var player_distance: float = player.global_position.distance_to(flag_position)
		if player_distance <= best_distance:
			best = player
			best_distance = player_distance

	var pool: Array[CharacterBody3D] = blue_units if team == "blue" else red_units
	for unit in pool:
		if not is_valid_ctf_carrier(unit):
			continue
		var distance: float = unit.global_position.distance_to(flag_position)
		if distance <= best_distance:
			best = unit
			best_distance = distance

	return best


func is_valid_ctf_carrier(carrier: Node3D) -> bool:
	if carrier == null or not is_instance_valid(carrier):
		return false
	if carrier is CharacterBody3D:
		var body: CharacterBody3D = carrier as CharacterBody3D
		if body.has_meta("dead") and bool(body.get_meta("dead")):
			return false
	if carrier == player and is_player_dead():
		return false
	return true


func return_flag_to_base(team: String) -> void:
	if team == "red":
		if red_flag_carrier != null and is_instance_valid(red_flag_carrier):
			red_flag_carrier.set_meta("carrying_flag", "")
		red_flag_carrier = null
		red_flag_at_base = true
	else:
		if blue_flag_carrier != null and is_instance_valid(blue_flag_carrier):
			blue_flag_carrier.set_meta("carrying_flag", "")
		blue_flag_carrier = null
		blue_flag_at_base = true


func get_red_flag_position() -> Vector3:
	if red_flag_carrier != null and is_instance_valid(red_flag_carrier):
		return red_flag_carrier.global_position
	if red_flag_node != null and is_instance_valid(red_flag_node):
		return red_flag_node.global_position
	return RED_SPAWN_POSITION


func get_blue_flag_position() -> Vector3:
	if blue_flag_carrier != null and is_instance_valid(blue_flag_carrier):
		return blue_flag_carrier.global_position
	if blue_flag_node != null and is_instance_valid(blue_flag_node):
		return blue_flag_node.global_position
	return BLUE_SPAWN_POSITION


func get_ctf_goal_position_for_unit(unit: CharacterBody3D) -> Vector3:
	var team: String = str(unit.get_meta("team"))
	var carrying: String = str(unit.get_meta("carrying_flag", ""))

	# Carrier's only job is to get home.
	if carrying != "":
		return get_ctf_base_for_team(team)

	var role: String = get_ctf_role(unit)
	var enemy_carrier: Node3D = get_enemy_flag_carrier_for_team(team)
	var friendly_carrier: Node3D = get_friendly_flag_carrier_for_team(team)

	# If the enemy stole our flag, hunters and defenders stop attacking and recover it.
	if enemy_carrier != null:
		if role == CTF_HUNTER_ROLE or role == CTF_DEFENDER_ROLE or role == CTF_MIDFIELD_ROLE:
			return enemy_carrier.global_position

	# If our team has their flag, escorts and midfield help the carrier instead of running past.
	if friendly_carrier != null:
		if role == CTF_ESCORT_ROLE or role == CTF_MIDFIELD_ROLE:
			return friendly_carrier.global_position

	if role == CTF_DEFENDER_ROLE:
		return get_ctf_defend_position(unit)
	elif role == CTF_HUNTER_ROLE:
		return get_ctf_own_flag_position_for_team(team)
	elif role == CTF_MIDFIELD_ROLE:
		return get_ctf_base_for_team(team).lerp(get_ctf_enemy_base_for_team(team), 0.52)

	return get_ctf_enemy_flag_position_for_team(team)


func get_ctf_role_for_unit(index: int) -> String:
	# Small squads spread out instead of all running straight down the middle.
	var slot: int = index % 9

	if slot == 0 or slot == 1 or slot == 2:
		return CTF_ATTACKER_ROLE
	elif slot == 3 or slot == 4:
		return CTF_DEFENDER_ROLE
	elif slot == 5 or slot == 6:
		return CTF_HUNTER_ROLE
	elif slot == 7:
		return CTF_ESCORT_ROLE

	return CTF_MIDFIELD_ROLE


func get_ctf_role(unit: CharacterBody3D) -> String:
	if unit == null or not is_instance_valid(unit):
		return CTF_ATTACKER_ROLE

	var role: String = str(unit.get_meta("ctf_role", ""))
	if role == "":
		role = get_ctf_role_for_unit(int(abs(unit.get_instance_id()) % 9))
		unit.set_meta("ctf_role", role)

	return role


func get_enemy_flag_carrier_for_team(team: String) -> Node3D:
	# Enemy stole our flag. Hunt this carrier.
	if team == "blue":
		if blue_flag_carrier != null and is_instance_valid(blue_flag_carrier):
			return blue_flag_carrier
	else:
		if red_flag_carrier != null and is_instance_valid(red_flag_carrier):
			return red_flag_carrier

	return null


func get_friendly_flag_carrier_for_team(team: String) -> Node3D:
	# Our team stole their flag. Escort this carrier.
	if team == "blue":
		if red_flag_carrier != null and is_instance_valid(red_flag_carrier):
			return red_flag_carrier
	else:
		if blue_flag_carrier != null and is_instance_valid(blue_flag_carrier):
			return blue_flag_carrier

	return null


func get_ctf_base_for_team(team: String) -> Vector3:
	return BLUE_SPAWN_POSITION if team == "blue" else RED_SPAWN_POSITION


func get_ctf_enemy_base_for_team(team: String) -> Vector3:
	return RED_SPAWN_POSITION if team == "blue" else BLUE_SPAWN_POSITION


func get_ctf_own_flag_position_for_team(team: String) -> Vector3:
	return get_blue_flag_position() if team == "blue" else get_red_flag_position()


func get_ctf_enemy_flag_position_for_team(team: String) -> Vector3:
	return get_red_flag_position() if team == "blue" else get_blue_flag_position()


func get_ctf_defend_position(unit: CharacterBody3D) -> Vector3:
	var team: String = str(unit.get_meta("team"))
	var base: Vector3 = get_ctf_base_for_team(team)
	var enemy_base: Vector3 = get_ctf_enemy_base_for_team(team)
	var to_enemy: Vector3 = enemy_base - base
	to_enemy.y = 0.0

	if to_enemy.length() < 0.01:
		to_enemy = Vector3.FORWARD

	to_enemy = to_enemy.normalized()
	var right: Vector3 = Vector3(-to_enemy.z, 0.0, to_enemy.x)
	var side: float = get_meta_float(unit, "strafe_side", 1.0)
	var phase: float = get_meta_float(unit, "phase", 0.0)

	return base + to_enemy * CTF_DEFENDER_RADIUS + right * side * (18.0 + 10.0 * sin(phase))


func add_ctf_route_variation(unit: CharacterBody3D, target: Vector3) -> Vector3:
	var team: String = str(unit.get_meta("team"))
	var role: String = get_ctf_role(unit)
	var base: Vector3 = get_ctf_base_for_team(team)
	var enemy_base: Vector3 = get_ctf_enemy_base_for_team(team)
	var route: Vector3 = enemy_base - base
	route.y = 0.0

	if route.length() < 0.01:
		return target

	route = route.normalized()
	var right: Vector3 = Vector3(-route.z, 0.0, route.x)
	var side: float = get_meta_float(unit, "strafe_side", 1.0)
	var phase: float = get_meta_float(unit, "phase", 0.0)

	if role == CTF_ATTACKER_ROLE:
		return target + right * side * rng.randf_range(35.0, CTF_ATTACK_FLANK_WIDTH)
	elif role == CTF_MIDFIELD_ROLE:
		return base.lerp(enemy_base, 0.50) + right * side * rng.randf_range(70.0, 150.0)
	elif role == CTF_ESCORT_ROLE:
		var carrier: Node3D = get_friendly_flag_carrier_for_team(team)
		if carrier != null:
			return carrier.global_position - route * CTF_ESCORT_DISTANCE + right * side * 10.0
	elif role == CTF_DEFENDER_ROLE:
		return get_ctf_defend_position(unit)
	elif role == CTF_HUNTER_ROLE:
		var enemy_carrier: Node3D = get_enemy_flag_carrier_for_team(team)
		if enemy_carrier != null:
			return enemy_carrier.global_position + right * side * 12.0

	return target + right * side * (20.0 + 10.0 * sin(phase))


func get_ctf_flag_status_text() -> String:
	if red_flag_carrier != null and is_instance_valid(red_flag_carrier):
		return "RED FLAG TAKEN"
	if blue_flag_carrier != null and is_instance_valid(blue_flag_carrier):
		return "BLUE FLAG TAKEN"
	return "FLAGS AT BASE"


func check_ctf_game_over() -> void:
	if game_over:
		return
	if blue_ctf_score >= CTF_CAPTURE_LIMIT:
		show_result_screen("VICTORY - BLUE CAPTURED " + str(CTF_CAPTURE_LIMIT) + " FLAGS")
	elif red_ctf_score >= CTF_CAPTURE_LIMIT:
		show_result_screen("DEFEAT - RED CAPTURED " + str(CTF_CAPTURE_LIMIT) + " FLAGS")


func clear_match_world() -> void:
	for unit in all_units:
		if unit != null and is_instance_valid(unit):
			unit.queue_free()
	all_units.clear()
	red_units.clear()
	blue_units.clear()

	for bullet in bullets:
		if bullet != null and is_instance_valid(bullet):
			bullet.queue_free()
	bullets.clear()

	red_spawned_total = 0
	blue_spawned_total = 0
	red_respawn_timer = 0.0
	blue_respawn_timer = 0.0
	match_time_remaining = MATCH_TIME_SECONDS


# ---------------- TEAM PLANS ----------------
func update_team_plans(delta: float) -> void:
	red_plan_timer -= delta
	blue_plan_timer -= delta

	if red_plan_timer <= 0.0:
		choose_team_plan("red")

	if blue_plan_timer <= 0.0:
		choose_team_plan("blue")


func choose_team_plan(team: String) -> void:
	var friendly_count: int = red_units.size() if team == "red" else blue_units.size()
	var enemy_count: int = blue_units.size() if team == "red" else red_units.size()

	if team == "blue" and player != null and is_instance_valid(player) and not is_player_dead():
		friendly_count += 1

	var plan: int = BattlePlan.ASSAULT

	if friendly_count <= enemy_count - 4:
		plan = BattlePlan.FALL_BACK
	elif friendly_count >= enemy_count + 4:
		plan = BattlePlan.ASSAULT
	else:
		var roll: float = rng.randf()

		if roll < 0.28:
			plan = BattlePlan.HOLD
		elif roll < 0.50:
			plan = BattlePlan.FLANK_LEFT
		elif roll < 0.72:
			plan = BattlePlan.FLANK_RIGHT
		else:
			plan = BattlePlan.ASSAULT

	if team == "red":
		red_plan = plan
		red_plan_timer = rng.randf_range(PLAN_RETHINK_TIME_MIN, PLAN_RETHINK_TIME_MAX)
	else:
		blue_plan = plan
		blue_plan_timer = rng.randf_range(PLAN_RETHINK_TIME_MIN, PLAN_RETHINK_TIME_MAX)


func get_team_plan(team: String) -> int:
	return red_plan if team == "red" else blue_plan


# ---------------- CLEANUP ----------------
func clean_dead_references() -> void:
	for i in range(all_units.size() - 1, -1, -1):
		var unit: CharacterBody3D = all_units[i]
		if unit == null or not is_instance_valid(unit):
			all_units.remove_at(i)

	for i in range(red_units.size() - 1, -1, -1):
		var unit: CharacterBody3D = red_units[i]
		if unit == null or not is_instance_valid(unit):
			red_units.remove_at(i)

	for i in range(blue_units.size() - 1, -1, -1):
		var unit: CharacterBody3D = blue_units[i]
		if unit == null or not is_instance_valid(unit):
			blue_units.remove_at(i)

	for i in range(bullets.size() - 1, -1, -1):
		var bullet: Area3D = bullets[i]
		if bullet == null or not is_instance_valid(bullet):
			bullets.remove_at(i)


# ---------------- SPAWNING ----------------
func update_respawns(delta: float) -> void:
	if selected_game_mode == GAME_MODE_FINAL_BOSS:
		return
	# Manhunt stays one red CPU vs the player. No respawns.
	if selected_game_mode == GAME_MODE_MANHUNT:
		return

	red_respawn_timer -= delta
	blue_respawn_timer -= delta

	if red_units.size() < get_red_active_limit_for_mode() and (uses_infinite_respawns() or red_spawned_total < get_red_reserve_limit_for_mode()) and red_respawn_timer <= 0.0:
		spawn_one_unit("red")
		red_respawn_timer = rng.randf_range(RESPAWN_DELAY_MIN, RESPAWN_DELAY_MAX)

	if blue_units.size() < min(get_blue_npc_active_limit(), get_blue_active_limit_for_mode()) and (uses_infinite_respawns() or blue_spawned_total < get_blue_reserve_limit_for_mode()) and blue_respawn_timer <= 0.0:
		spawn_one_unit("blue")
		blue_respawn_timer = rng.randf_range(RESPAWN_DELAY_MIN, RESPAWN_DELAY_MAX)


func spawn_one_unit(team: String) -> void:
	var index: int = red_spawned_total if team == "red" else blue_spawned_total

	if team == "red":
		if selected_game_mode != GAME_MODE_FINAL_BOSS and not uses_infinite_respawns() and red_spawned_total >= RED_TOTAL_RESERVES:
			return
		red_spawned_total += 1
	else:
		if not uses_infinite_respawns() and blue_spawned_total >= BLUE_TOTAL_RESERVES:
			return
		blue_spawned_total += 1

	var unit: CharacterBody3D = create_unit(team, index)
	if online_is_active():
		unit.set_multiplayer_authority(1)
	var base_position: Vector3 = RED_SPAWN_POSITION if team == "red" else BLUE_SPAWN_POSITION
	unit.global_position = get_spawn_position(index, base_position)

	add_child(unit)

	all_units.append(unit)

	if team == "red":
		red_units.append(unit)
	else:
		blue_units.append(unit)


func get_spawn_position(index: int, base_position: Vector3) -> Vector3:
	var active_index: int = index % (SPAWN_COLUMNS * 3)
	var x_index: int = active_index % SPAWN_COLUMNS
	var z_index: int = int(floor(float(active_index) / float(SPAWN_COLUMNS)))

	var x_offset: float = float(x_index - int(SPAWN_COLUMNS / 2)) * SPAWN_SPACING
	var z_offset: float = float(z_index) * SPAWN_SPACING

	var pos: Vector3 = base_position + Vector3(
		x_offset + rng.randf_range(-1.8, 1.8),
		0.0,
		z_offset + rng.randf_range(-1.8, 1.8)
	)

	pos.x = clamp(pos.x, MIN_BOUND + 5.0, MAX_BOUND - 5.0)
	pos.z = clamp(pos.z, MIN_BOUND + 5.0, MAX_BOUND - 5.0)

	return snap_position_to_ground(pos)


func snap_position_to_ground(position: Vector3) -> Vector3:
	var start_position: Vector3 = Vector3(position.x, position.y + 150.0, position.z)
	var end_position: Vector3 = Vector3(position.x, position.y - 350.0, position.z)

	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(start_position, end_position)
	query.collide_with_bodies = true
	query.collide_with_areas = false

	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)

	if hit.size() > 0:
		var hit_position: Vector3 = as_safe_vector3(hit["position"], Vector3.ZERO)
		return hit_position + Vector3(0.0, 1.25, 0.0)

	return position + Vector3(0.0, 1.25, 0.0)


func get_ai_role_for_unit(index: int) -> String:
	# First few soldiers on each team become ambushers. That keeps the hidden group small.
	var local_index: int = index % 25

	if local_index < 3:
		return "ambusher"
	elif local_index % 9 == 0:
		return "headon"
	elif local_index % 7 == 0:
		return "scout"
	elif local_index % 5 == 0:
		return "flanker"
	elif local_index % 4 == 0:
		return "opportunist"

	return "wander"


func get_enemy_spawn_for_team(team: String) -> Vector3:
	return BLUE_SPAWN_POSITION if team == "red" else RED_SPAWN_POSITION


func get_initial_search_anchor(team: String, index: int) -> Vector3:
	var role: String = get_ai_role_for_unit(index)
	var base: Vector3 = get_enemy_spawn_for_team(team)
	var phase: float = float(index) * 1.37

	if role == "ambusher":
		return get_hide_position(team, index)
	elif role == "headon":
		base = get_enemy_spawn_for_team(team)
	elif role == "scout":
		base = Vector3(0.0, 0.0, 0.0)
	elif role == "flanker":
		base = Vector3(-280.0 if index % 2 == 0 else 280.0, 0.0, 0.0)
	elif role == "opportunist":
		base = Vector3(rng.randf_range(-180.0, 180.0), 0.0, rng.randf_range(-180.0, 180.0))
	else:
		base = Vector3(rng.randf_range(-420.0, 420.0), 0.0, rng.randf_range(-420.0, 420.0))

	base += Vector3(cos(phase) * rng.randf_range(35.0, 110.0), 0.0, sin(phase) * rng.randf_range(35.0, 110.0))
	base.x = clamp(base.x, MIN_BOUND + 12.0, MAX_BOUND - 12.0)
	base.z = clamp(base.z, MIN_BOUND + 12.0, MAX_BOUND - 12.0)
	return snap_position_to_ground(base)


func get_hide_position(team: String, index: int) -> Vector3:
	var own_spawn: Vector3 = RED_SPAWN_POSITION if team == "red" else BLUE_SPAWN_POSITION
	var enemy_spawn: Vector3 = get_enemy_spawn_for_team(team)
	var halfway: Vector3 = own_spawn.lerp(enemy_spawn, 0.38 + float(index % 3) * 0.08)
	var to_enemy: Vector3 = enemy_spawn - own_spawn
	to_enemy.y = 0.0

	if to_enemy.length() < 0.01:
		to_enemy = Vector3.FORWARD

	to_enemy = to_enemy.normalized()
	var right: Vector3 = Vector3(-to_enemy.z, 0.0, to_enemy.x)
	var side: float = -1.0 if index % 2 == 0 else 1.0
	var hide_position: Vector3 = halfway + right * side * rng.randf_range(95.0, 210.0)
	hide_position.x = clamp(hide_position.x, MIN_BOUND + 18.0, MAX_BOUND - 18.0)
	hide_position.z = clamp(hide_position.z, MIN_BOUND + 18.0, MAX_BOUND - 18.0)
	return snap_position_to_ground(hide_position)


func is_team_losing(team: String) -> bool:
	var red_left_to_spawn: int = max(RED_TOTAL_RESERVES - red_spawned_total, 0)
	var blue_left_to_spawn: int = max(BLUE_TOTAL_RESERVES - blue_spawned_total, 0)
	var red_total_left: int = red_units.size() + red_left_to_spawn
	var blue_total_left: int = blue_units.size() + blue_left_to_spawn

	if team == "red":
		return red_total_left < blue_total_left - 2

	return blue_total_left < red_total_left - 2


func choose_new_search_anchor(unit: CharacterBody3D) -> void:
	if unit == null or not is_instance_valid(unit):
		return

	if selected_game_mode == GAME_MODE_CTF:
		var ctf_target: Vector3 = get_ctf_goal_position_for_unit(unit)
		ctf_target = add_ctf_route_variation(unit, ctf_target)
		unit.set_meta("search_anchor", snap_position_to_ground(ctf_target))

		var ctf_role: String = get_ctf_role(unit)
		if ctf_role == CTF_HUNTER_ROLE:
			unit.set_meta("search_repick_timer", rng.randf_range(CTF_HUNTER_REPATH_TIME_MIN, CTF_HUNTER_REPATH_TIME_MAX))
		else:
			unit.set_meta("search_repick_timer", rng.randf_range(CTF_NORMAL_REPATH_TIME_MIN, CTF_NORMAL_REPATH_TIME_MAX))
		return

	var team: String = str(unit.get_meta("team"))
	var role: String = str(unit.get_meta("ai_role"))
	var index_guess: int = int(abs(unit.get_instance_id()) % 25)
	var base: Vector3 = Vector3.ZERO

	if role == "ambusher":
		if is_team_losing(team):
			base = get_meta_vector3(unit, "hide_position", unit.global_position)
		else:
			base = get_initial_search_anchor(team, index_guess)
	elif role == "headon":
		base = get_enemy_spawn_for_team(team)
	elif role == "scout":
		base = Vector3(rng.randf_range(-460.0, 460.0), 0.0, rng.randf_range(-460.0, 460.0))
	elif role == "flanker":
		var enemy_spawn: Vector3 = get_enemy_spawn_for_team(team)
		var side: float = get_meta_float(unit, "strafe_side", 1.0)
		base = enemy_spawn + Vector3(side * rng.randf_range(140.0, 260.0), 0.0, rng.randf_range(-160.0, 160.0))
	elif role == "opportunist":
		base = get_enemy_center_for_team(team) + Vector3(rng.randf_range(-95.0, 95.0), 0.0, rng.randf_range(-95.0, 95.0))
	else:
		base = Vector3(rng.randf_range(-430.0, 430.0), 0.0, rng.randf_range(-430.0, 430.0))

	base.x = clamp(base.x, MIN_BOUND + 12.0, MAX_BOUND - 12.0)
	base.z = clamp(base.z, MIN_BOUND + 12.0, MAX_BOUND - 12.0)
	unit.set_meta("search_anchor", snap_position_to_ground(base))
	unit.set_meta("search_repick_timer", rng.randf_range(NPC_SEARCH_REPICK_TIME_MIN, NPC_SEARCH_REPICK_TIME_MAX))


# ---------------- UNIT CREATION ----------------
func create_unit(team: String, index: int) -> CharacterBody3D:
	var unit: CharacterBody3D = CharacterBody3D.new()
	unit.name = team.capitalize() + "_NPC_" + str(index)

	unit.add_to_group("BattleNPC")
	unit.add_to_group("RedTeam" if team == "red" else "BlueTeam")

	unit.set_meta("team", team)
	unit.set_meta("is_npc", true)
	unit.set_meta("health", NPC_MAX_HEALTH)
	unit.set_meta("max_health", NPC_MAX_HEALTH)
	unit.set_meta("dead", false)
	unit.set_meta("spawn_immune_timer", SPAWN_IMMUNITY_TIME)

	unit.set_meta("speed", rng.randf_range(NPC_SPEED_MIN, NPC_SPEED_MAX))
	unit.set_meta("stop_distance", rng.randf_range(NPC_STOP_DISTANCE_MIN, NPC_STOP_DISTANCE_MAX))
	unit.set_meta("shoot_distance", rng.randf_range(NPC_SHOOT_DISTANCE_MIN, NPC_SHOOT_DISTANCE_MAX))
	var npc_fire_cooldown: float = rng.randf_range(NPC_FIRE_COOLDOWN_MIN, NPC_FIRE_COOLDOWN_MAX)

	if team == "red":
		npc_fire_cooldown = max(npc_fire_cooldown * RED_FIRE_COOLDOWN_MULTIPLIER, RED_FIRE_COOLDOWN_MINIMUM)

	unit.set_meta("fire_cooldown", npc_fire_cooldown)
	unit.set_meta("fire_timer", rng.randf_range(0.0, 0.65))
	unit.set_meta("reload_time", rng.randf_range(NPC_RELOAD_TIME_MIN, NPC_RELOAD_TIME_MAX))
	unit.set_meta("reload_timer", 0.0)
	unit.set_meta("mag_size", rng.randi_range(NPC_MAGAZINE_MIN, NPC_MAGAZINE_MAX))
	unit.set_meta("ammo", unit.get_meta("mag_size"))
	unit.set_meta("state", "advance")
	unit.set_meta("state_timer", rng.randf_range(0.8, 2.4))
	unit.set_meta("target_refresh_timer", rng.randf_range(0.1, 0.5))
	unit.set_meta("target_instance_id", 0)
	unit.set_meta("anim_time", rng.randf_range(0.0, 10.0))
	unit.set_meta("phase", rng.randf_range(0.0, TAU))
	unit.set_meta("strafe_side", -1.0 if index % 2 == 0 else 1.0)
	unit.set_meta("flank_strength", rng.randf_range(0.25, 1.0))
	unit.set_meta("personality", index % 8)
	unit.set_meta("last_position", Vector3.ZERO)
	unit.set_meta("stuck_timer", 0.0)
	unit.set_meta("footstep_timer", rng.randf_range(0.0, 0.35))
	unit.set_meta("repath_timer", 0.0)
	unit.set_meta("repath_position", Vector3.ZERO)
	unit.set_meta("last_state_before_repath", "advance")
	unit.set_meta("ai_role", get_ai_role_for_unit(index))
	unit.set_meta("ctf_role", get_ctf_role_for_unit(index))
	unit.set_meta("search_anchor", get_initial_search_anchor(team, index))
	unit.set_meta("search_repick_timer", rng.randf_range(NPC_SEARCH_REPICK_TIME_MIN, NPC_SEARCH_REPICK_TIME_MAX))
	unit.set_meta("hide_position", get_hide_position(team, index))
	unit.set_meta("last_repath_choice", Vector3.ZERO)
	unit.set_meta("wants_helicopter", false)
	unit.set_meta("helicopter_target_id", 0)
	unit.set_meta("in_helicopter", false)
	unit.set_meta("piloting_helicopter", false)
	unit.set_meta("no_helicopter", false)
	unit.set_meta("commander", false)
	unit.set_meta("carrying_flag", "")

	if str(unit.get_meta("ai_role")) == "ambusher":
		unit.set_meta("shoot_distance", get_meta_float(unit, "shoot_distance", 150.0) + NPC_AMBUSH_SHOOT_DISTANCE_BONUS)
		unit.set_meta("fire_cooldown", max(get_meta_float(unit, "fire_cooldown", 1.0) * 0.72, 0.45))

	unit.collision_layer = 1
	unit.collision_mask = 1
	unit.floor_snap_length = FLOOR_SNAP_LENGTH
	unit.floor_max_angle = deg_to_rad(50.0)

	var collision: CollisionShape3D = CollisionShape3D.new()
	collision.name = "BodyCollision"

	var capsule: CapsuleShape3D = CapsuleShape3D.new()
	capsule.radius = NPC_CAPSULE_RADIUS
	capsule.height = NPC_CAPSULE_HEIGHT

	collision.shape = capsule
	collision.position = Vector3(0.0, NPC_CAPSULE_HEIGHT * 0.5, 0.0)
	unit.add_child(collision)

	create_unit_model(unit, team, index)
	create_head_hitbox(unit)
	create_health_bar(unit)
	create_unit_audio(unit)

	return unit


func create_unit_model(unit: CharacterBody3D, team: String, index: int) -> void:
	var model_root: Node3D = Node3D.new()
	model_root.name = "Model"
	unit.add_child(model_root)

	# This stays laser tag: colored uniforms, glowing hit sensor, goggles, and safe tagger.
	# The model is still procedural, but the proportions are more human than the old blocky soldier.
	var uniform_color: Color = get_uniform_color(team, index)
	var vest_color: Color = Color(0.055, 0.055, 0.052, 1.0)
	var boot_color: Color = Color(0.025, 0.023, 0.020, 1.0)
	var glove_color: Color = Color(0.035, 0.034, 0.032, 1.0)
	var skin_color: Color = Color(rng.randf_range(0.56, 0.86), rng.randf_range(0.39, 0.64), rng.randf_range(0.25, 0.49), 1.0)
	var hair_color: Color = Color(rng.randf_range(0.04, 0.20), rng.randf_range(0.025, 0.14), rng.randf_range(0.012, 0.08), 1.0)
	var gun_color: Color = Color(0.015, 0.015, 0.015, 1.0)

	var uniform_mat: StandardMaterial3D = make_material(uniform_color, 0.0)
	var vest_mat: StandardMaterial3D = make_material(vest_color, 0.0)
	var boot_mat: StandardMaterial3D = make_material(boot_color, 0.0)
	var glove_mat: StandardMaterial3D = make_material(glove_color, 0.0)
	var skin_mat: StandardMaterial3D = make_material(skin_color, 0.0)
	var hair_mat: StandardMaterial3D = make_material(hair_color, 0.0)
	var gun_mat: StandardMaterial3D = make_material(gun_color, 0.0)
	var glass_mat: StandardMaterial3D = make_material(Color(0.02, 0.027, 0.032, 1.0), 0.15)
	var eye_mat: StandardMaterial3D = make_material(Color(0.02, 0.018, 0.015, 1.0), 0.0)
	var mouth_mat: StandardMaterial3D = make_material(Color(0.18, 0.055, 0.045, 1.0), 0.0)

	var chest_plate_color: Color = BLUE_LASER_COLOR if team == "blue" else RED_LASER_COLOR
	var chest_plate_mat: StandardMaterial3D = make_material(chest_plate_color, 1.25)

	# Body core.
	model_root.add_child(create_box_mesh("Pelvis", Vector3(0.46, 0.26, 0.28), Vector3(0.0, 0.86, 0.0), uniform_mat))
	model_root.add_child(create_box_mesh("Waist", Vector3(0.42, 0.18, 0.25), Vector3(0.0, 1.04, 0.0), uniform_mat))
	model_root.add_child(create_box_mesh("LowerTorso", Vector3(0.52, 0.42, 0.30), Vector3(0.0, 1.28, 0.0), uniform_mat))
	model_root.add_child(create_box_mesh("Chest", Vector3(0.68, 0.54, 0.34), Vector3(0.0, 1.62, 0.0), uniform_mat))
	model_root.add_child(create_box_mesh("Shoulders", Vector3(0.88, 0.16, 0.31), Vector3(0.0, 1.91, 0.0), uniform_mat))
	model_root.add_child(create_box_mesh("Vest", Vector3(0.74, 0.66, 0.39), Vector3(0.0, 1.50, -0.018), vest_mat))
	model_root.add_child(create_box_mesh("LaserTagChestPlate", CHEST_PLATE_SCALE, Vector3(0.0, 1.53, -0.225), chest_plate_mat))
	model_root.add_child(create_box_mesh("Backpack", Vector3(0.44, 0.64, 0.16), Vector3(0.0, 1.48, 0.27), vest_mat))

	# Neck and head.
	model_root.add_child(create_box_mesh("Neck", Vector3(0.16, 0.16, 0.16), Vector3(0.0, 2.03, 0.0), skin_mat))
	model_root.add_child(create_sphere_mesh("HeadMesh", Vector3(0.30, 0.36, 0.28), Vector3(0.0, 2.27, 0.0), skin_mat))
	model_root.add_child(create_sphere_mesh("HairCap", Vector3(0.31, 0.16, 0.28), Vector3(0.0, 2.45, 0.025), hair_mat))
	model_root.add_child(create_box_mesh("Goggles", Vector3(0.44, 0.10, 0.055), Vector3(0.0, 2.28, -0.258), glass_mat))
	model_root.add_child(create_sphere_mesh("LeftEye", Vector3(0.035, 0.026, 0.018), Vector3(-0.105, 2.29, -0.286), eye_mat))
	model_root.add_child(create_sphere_mesh("RightEye", Vector3(0.035, 0.026, 0.018), Vector3(0.105, 2.29, -0.286), eye_mat))
	model_root.add_child(create_box_mesh("Nose", Vector3(0.055, 0.080, 0.045), Vector3(0.0, 2.235, -0.292), skin_mat))
	model_root.add_child(create_box_mesh("Mouth", Vector3(0.15, 0.025, 0.018), Vector3(0.0, 2.145, -0.292), mouth_mat))

	# Left leg.
	var left_leg: Node3D = Node3D.new()
	left_leg.name = "LeftLegPivot"
	left_leg.position = Vector3(-0.17, 0.78, 0.0)
	model_root.add_child(left_leg)
	left_leg.add_child(create_box_mesh("LeftThigh", Vector3(0.20, 0.50, 0.22), Vector3(0.0, -0.24, 0.0), uniform_mat))
	left_leg.add_child(create_sphere_mesh("LeftKnee", Vector3(0.12, 0.07, 0.12), Vector3(0.0, -0.50, -0.01), uniform_mat))
	var left_lower_leg: Node3D = Node3D.new()
	left_lower_leg.name = "LeftLowerLegPivot"
	left_lower_leg.position = Vector3(0.0, -0.49, 0.0)
	left_leg.add_child(left_lower_leg)
	left_lower_leg.add_child(create_box_mesh("LeftShin", Vector3(0.18, 0.48, 0.18), Vector3(0.0, -0.22, 0.0), uniform_mat))
	left_lower_leg.add_child(create_box_mesh("LeftBoot", Vector3(0.25, 0.15, 0.40), Vector3(0.0, -0.48, -0.08), boot_mat))

	# Right leg.
	var right_leg: Node3D = Node3D.new()
	right_leg.name = "RightLegPivot"
	right_leg.position = Vector3(0.17, 0.78, 0.0)
	model_root.add_child(right_leg)
	right_leg.add_child(create_box_mesh("RightThigh", Vector3(0.20, 0.50, 0.22), Vector3(0.0, -0.24, 0.0), uniform_mat))
	right_leg.add_child(create_sphere_mesh("RightKnee", Vector3(0.12, 0.07, 0.12), Vector3(0.0, -0.50, -0.01), uniform_mat))
	var right_lower_leg: Node3D = Node3D.new()
	right_lower_leg.name = "RightLowerLegPivot"
	right_lower_leg.position = Vector3(0.0, -0.49, 0.0)
	right_leg.add_child(right_lower_leg)
	right_lower_leg.add_child(create_box_mesh("RightShin", Vector3(0.18, 0.48, 0.18), Vector3(0.0, -0.22, 0.0), uniform_mat))
	right_lower_leg.add_child(create_box_mesh("RightBoot", Vector3(0.25, 0.15, 0.40), Vector3(0.0, -0.48, -0.08), boot_mat))

	# Arms and tagger. Both hands hold the laser tagger so shooting reads clearly.
	var left_arm: Node3D = Node3D.new()
	left_arm.name = "LeftArmPivot"
	left_arm.position = Vector3(-0.50, 1.88, 0.0)
	model_root.add_child(left_arm)

	var right_arm: Node3D = Node3D.new()
	right_arm.name = "RightArmPivot"
	right_arm.position = Vector3(0.50, 1.88, 0.0)
	model_root.add_child(right_arm)

	left_arm.add_child(create_box_mesh("LeftUpperArm", Vector3(0.17, 0.40, 0.17), Vector3(-0.01, -0.20, -0.02), uniform_mat))
	left_arm.add_child(create_sphere_mesh("LeftElbow", Vector3(0.09, 0.06, 0.09), Vector3(-0.02, -0.42, -0.08), uniform_mat))
	left_arm.add_child(create_box_mesh("LeftForearm", Vector3(0.15, 0.38, 0.15), Vector3(-0.04, -0.61, -0.18), uniform_mat))
	left_arm.add_child(create_sphere_mesh("LeftHand", Vector3(0.085, 0.060, 0.085), Vector3(-0.04, -0.83, -0.26), glove_mat))

	right_arm.add_child(create_box_mesh("RightUpperArm", Vector3(0.17, 0.40, 0.17), Vector3(0.01, -0.20, -0.02), uniform_mat))
	right_arm.add_child(create_sphere_mesh("RightElbow", Vector3(0.09, 0.06, 0.09), Vector3(0.02, -0.42, -0.08), uniform_mat))
	right_arm.add_child(create_box_mesh("RightForearm", Vector3(0.15, 0.38, 0.15), Vector3(0.04, -0.61, -0.18), uniform_mat))

	var right_hand: Node3D = Node3D.new()
	right_hand.name = "RightHand"
	right_hand.position = Vector3(0.04, -0.83, -0.26)
	right_arm.add_child(right_hand)
	right_hand.add_child(create_sphere_mesh("RightHandMesh", Vector3(0.085, 0.060, 0.085), Vector3(0.0, 0.0, 0.0), glove_mat))

	var gun_root: Node3D = Node3D.new()
	gun_root.name = "GunRoot"
	gun_root.position = Vector3(0.0, -0.01, -0.23)
	gun_root.rotation_degrees = Vector3(-8.0, 0.0, 0.0)
	right_hand.add_child(gun_root)

	gun_root.add_child(create_box_mesh("RifleBody", Vector3(0.15, 0.15, 0.62), Vector3(0.0, 0.0, -0.20), gun_mat))
	gun_root.add_child(create_box_mesh("RifleBarrel", Vector3(0.055, 0.055, 0.70), Vector3(0.0, 0.02, -0.78), gun_mat))
	gun_root.add_child(create_box_mesh("RifleStock", Vector3(0.16, 0.16, 0.24), Vector3(0.0, -0.02, 0.17), gun_mat))
	gun_root.add_child(create_box_mesh("RifleMagazine", Vector3(0.10, 0.22, 0.12), Vector3(0.0, -0.18, -0.17), gun_mat))
	gun_root.add_child(create_box_mesh("LaserEmitter", Vector3(0.075, 0.075, 0.055), Vector3(0.0, 0.02, -1.16), chest_plate_mat))

func create_head_hitbox(unit: CharacterBody3D) -> void:
	var head_hitbox: Area3D = Area3D.new()
	head_hitbox.name = "HeadHitbox"
	head_hitbox.collision_layer = 2
	head_hitbox.collision_mask = 0
	head_hitbox.monitoring = false
	head_hitbox.monitorable = true
	head_hitbox.set_meta("npc_root", unit)
	head_hitbox.set_meta("hit_zone", "head")

	var head_collision: CollisionShape3D = CollisionShape3D.new()
	var head_sphere: SphereShape3D = SphereShape3D.new()
	head_sphere.radius = 0.36
	head_collision.shape = head_sphere
	head_hitbox.add_child(head_collision)

	head_hitbox.position = Vector3(0.0, 2.27, 0.0)
	unit.add_child(head_hitbox)


func create_health_bar(unit: CharacterBody3D) -> void:
	# Do not create floating NPC word labels.
	# The old Label3D text could appear in the player's first-person view as blurry words.
	return



# ---------------- NPC AUDIO ----------------
func create_unit_audio(unit: CharacterBody3D) -> void:
	var gun_audio: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
	gun_audio.name = "GunshotAudio"
	gun_audio.stream = get_team_gun_stream()
	gun_audio.volume_db = NPC_GUNSHOT_VOLUME_DB
	gun_audio.max_distance = NPC_SOUND_MAX_DISTANCE
	gun_audio.unit_size = NPC_SOUND_UNIT_SIZE
	gun_audio.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	unit.add_child(gun_audio)

	var step_audio: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
	step_audio.name = "FootstepAudio"
	step_audio.stream = create_tone_stream(70.0, 0.055, 0.38)
	step_audio.volume_db = NPC_FOOTSTEP_VOLUME_DB
	step_audio.max_distance = NPC_SOUND_MAX_DISTANCE * 0.55
	step_audio.unit_size = NPC_SOUND_UNIT_SIZE
	step_audio.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	unit.add_child(step_audio)

	var hurt_audio: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
	hurt_audio.name = "HurtAudio"
	hurt_audio.stream = create_tone_stream(180.0, 0.08, 0.45)
	hurt_audio.volume_db = NPC_HURT_VOLUME_DB
	hurt_audio.max_distance = NPC_SOUND_MAX_DISTANCE * 0.65
	hurt_audio.unit_size = NPC_SOUND_UNIT_SIZE
	hurt_audio.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	unit.add_child(hurt_audio)

	var death_audio: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
	death_audio.name = "DeathAudio"
	death_audio.stream = create_tone_stream(95.0, 0.16, 0.60)
	death_audio.volume_db = NPC_DEATH_VOLUME_DB
	death_audio.max_distance = NPC_SOUND_MAX_DISTANCE * 0.80
	death_audio.unit_size = NPC_SOUND_UNIT_SIZE
	death_audio.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	unit.add_child(death_audio)


func get_team_gun_stream() -> AudioStream:
	var gun_node: Node = get_node_or_null("Gun")

	if gun_node != null:
		if gun_node is AudioStreamPlayer:
			var audio: AudioStreamPlayer = gun_node as AudioStreamPlayer
			if audio.stream != null:
				return audio.stream
		elif gun_node is AudioStreamPlayer3D:
			var audio_3d: AudioStreamPlayer3D = gun_node as AudioStreamPlayer3D
			if audio_3d.stream != null:
				return audio_3d.stream
		elif gun_node is AudioStreamPlayer2D:
			var audio_2d: AudioStreamPlayer2D = gun_node as AudioStreamPlayer2D
			if audio_2d.stream != null:
				return audio_2d.stream

	return create_tone_stream(115.0, 0.10, 0.80)


func create_tone_stream(frequency: float, duration: float, volume: float) -> AudioStreamWAV:
	var sample_rate: int = 22050
	var sample_count: int = int(float(sample_rate) * duration)
	var data: PackedByteArray = PackedByteArray()
	data.resize(sample_count)

	for i in range(sample_count):
		var t: float = float(i) / float(sample_rate)
		var fade: float = 1.0 - (float(i) / float(sample_count))
		var noise: float = rng.randf_range(-0.35, 0.35)
		var wave: float = sin(TAU * frequency * t) * 0.65 + noise
		var sample: int = int(clamp(128.0 + wave * 127.0 * volume * fade, 0.0, 255.0))
		data[i] = sample

	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream


func play_unit_sound(unit: CharacterBody3D, sound_name: String) -> void:
	if unit == null or not is_instance_valid(unit):
		return

	var audio: AudioStreamPlayer3D = unit.get_node_or_null(sound_name) as AudioStreamPlayer3D

	if audio == null:
		return

	audio.stop()
	audio.play()


func update_footstep_sound(unit: CharacterBody3D, delta: float) -> void:
	if unit == null or not is_instance_valid(unit):
		return

	var horizontal_speed: float = Vector2(unit.velocity.x, unit.velocity.z).length()
	var timer: float = get_meta_float(unit, "footstep_timer", 0.0)
	timer -= delta

	if horizontal_speed > 0.35 and unit.is_on_floor() and timer <= 0.0:
		play_unit_sound(unit, "FootstepAudio")
		timer = clamp(0.48 - horizontal_speed * 0.035, 0.22, 0.50)

	unit.set_meta("footstep_timer", timer)



# ---------------- HELICOPTER STRATEGY ----------------
func update_helicopter_strategy(delta: float) -> void:
	if not HELICOPTER_STRATEGY_ENABLED:
		return

	# Give the player the first chance to reach the helicopter.
	if helicopter_strategy_delay_timer > 0.0:
		helicopter_strategy_delay_timer -= delta
		return

	helicopter_strategy_timer -= delta
	if helicopter_strategy_timer > 0.0:
		return

	helicopter_strategy_timer = HELICOPTER_STRATEGY_CHECK_TIME

	var helicopters: Array[Node] = get_tree().get_nodes_in_group("Helicopter")
	if helicopters.size() <= 0:
		return

	for helicopter_node in helicopters:
		if helicopter_node == null or not is_instance_valid(helicopter_node):
			continue
		if not helicopter_node is Node3D:
			continue
		var helicopter: Node3D = helicopter_node as Node3D
		if not can_assign_helicopter(helicopter):
			continue

		var candidate: CharacterBody3D = null

		# Player-landed rule: if the player lands with fuel left, send the nearest CPU, not just a normal strategy candidate.
		if helicopter.has_method("should_npc_claim_now") and bool(helicopter.call("should_npc_claim_now")):
			candidate = choose_nearest_cpu_for_abandoned_helicopter(helicopter)
			if candidate != null and helicopter.has_method("clear_npc_claim_request"):
				helicopter.call("clear_npc_claim_request")
		else:
			var red_candidate: CharacterBody3D = choose_helicopter_candidate("red", helicopter)
			var blue_candidate: CharacterBody3D = choose_helicopter_candidate("blue", helicopter)

			if red_candidate != null and blue_candidate != null:
				var red_score: float = red_candidate.global_position.distance_to(helicopter.global_position)
				var blue_score: float = blue_candidate.global_position.distance_to(helicopter.global_position)
				candidate = red_candidate if red_score <= blue_score else blue_candidate
			elif red_candidate != null:
				candidate = red_candidate
			elif blue_candidate != null:
				candidate = blue_candidate

		if candidate != null:
			assign_unit_to_helicopter(candidate, helicopter)


func can_assign_helicopter(helicopter: Node3D) -> bool:
	if helicopter == null or not is_instance_valid(helicopter):
		return false
	if helicopter.has_method("is_destroyed") and bool(helicopter.call("is_destroyed")):
		return false
	if helicopter.has_method("is_out_of_fuel") and bool(helicopter.call("is_out_of_fuel")):
		return false
	# A player-landed helicopter with fuel left should be claimable immediately by the nearest CPU.
	if helicopter.has_method("should_npc_claim_now") and bool(helicopter.call("should_npc_claim_now")):
		return true
	if helicopter.has_method("is_available_for_npc"):
		return bool(helicopter.call("is_available_for_npc"))
	if helicopter.has_method("has_pilot"):
		return not bool(helicopter.call("has_pilot"))
	return true


func choose_nearest_cpu_for_abandoned_helicopter(helicopter: Node3D) -> CharacterBody3D:
	if helicopter == null or not is_instance_valid(helicopter):
		return null

	var best: CharacterBody3D = null
	var best_distance: float = HELICOPTER_ABANDONED_ASSIGN_DISTANCE

	for unit in red_units:
		if unit == null or not is_instance_valid(unit):
			continue
		if bool(unit.get_meta("dead")):
			continue
		if bool(unit.get_meta("in_helicopter")):
			continue
		if bool(unit.get_meta("wants_helicopter")):
			continue
		var red_distance: float = unit.global_position.distance_to(helicopter.global_position)
		if red_distance < best_distance:
			best_distance = red_distance
			best = unit

	for unit in blue_units:
		if unit == null or not is_instance_valid(unit):
			continue
		if bool(unit.get_meta("dead")):
			continue
		if bool(unit.get_meta("in_helicopter")):
			continue
		if bool(unit.get_meta("wants_helicopter")):
			continue
		var blue_distance: float = unit.global_position.distance_to(helicopter.global_position)
		if blue_distance < best_distance:
			best_distance = blue_distance
			best = unit

	return best

func choose_helicopter_candidate(team: String, helicopter: Node3D) -> CharacterBody3D:
	if active_helicopter_pilots_for_team(team) >= HELICOPTER_MAX_ACTIVE_PILOTS_PER_TEAM:
		return null

	var pool: Array[CharacterBody3D] = red_units if team == "red" else blue_units
	if pool.size() < HELICOPTER_MIN_UNIT_COUNT_TO_USE:
		return null

	var best: CharacterBody3D = null
	var best_score: float = 999999.0
	var team_losing: bool = is_team_losing(team)
	var plan: int = get_team_plan(team)

	for unit in pool:
		if unit == null or not is_instance_valid(unit):
			continue
		if bool(unit.get_meta("in_helicopter")):
			continue
		if bool(unit.get_meta("dead")):
			continue
		if bool(unit.get_meta("wants_helicopter")):
			continue

		var distance: float = unit.global_position.distance_to(helicopter.global_position)
		if distance > HELICOPTER_ASSIGN_DISTANCE:
			continue

		var role: String = str(unit.get_meta("ai_role"))
		var score: float = distance

		# Strategy: losing teams and mobile roles value the helicopter more.
		if team_losing:
			score -= 85.0
		if plan == BattlePlan.FLANK_LEFT or plan == BattlePlan.FLANK_RIGHT:
			score -= 35.0
		if role == "scout" or role == "flanker" or role == "opportunist":
			score -= 55.0
		elif role == "ambusher":
			score += 30.0

		if score < best_score:
			best_score = score
			best = unit

	return best


func active_helicopter_pilots_for_team(team: String) -> int:
	var count: int = 0
	var pool: Array[CharacterBody3D] = red_units if team == "red" else blue_units
	for unit in pool:
		if unit != null and is_instance_valid(unit):
			if bool(unit.get_meta("in_helicopter")) and str(unit.get_meta("team")) == team:
				count += 1
	return count


func assign_unit_to_helicopter(unit: CharacterBody3D, helicopter: Node3D) -> void:
	if unit == null or not is_instance_valid(unit):
		return
	if bool(unit.get_meta("no_helicopter", false)):
		return
	if helicopter == null or not is_instance_valid(helicopter):
		return
	unit.set_meta("wants_helicopter", true)
	unit.set_meta("helicopter_target_id", helicopter.get_instance_id())
	unit.set_meta("state", "use_helicopter")
	unit.set_meta("state_timer", 0.25)


func get_assigned_helicopter(unit: CharacterBody3D) -> Node3D:
	if unit == null or not is_instance_valid(unit):
		return null
	if not bool(unit.get_meta("wants_helicopter")):
		return null
	var id_value: int = int(unit.get_meta("helicopter_target_id"))
	if id_value <= 0:
		return null
	var obj: Object = instance_from_id(id_value)
	if obj == null or not is_instance_valid(obj):
		unit.set_meta("wants_helicopter", false)
		unit.set_meta("helicopter_target_id", 0)
		return null
	if obj is Node3D:
		return obj as Node3D
	return null


func update_unit_helicopter_boarding(unit: CharacterBody3D) -> bool:
	var helicopter: Node3D = get_assigned_helicopter(unit)
	if helicopter == null:
		return false

	if not can_assign_helicopter(helicopter):
		unit.set_meta("wants_helicopter", false)
		unit.set_meta("helicopter_target_id", 0)
		return false

	var distance: float = unit.global_position.distance_to(helicopter.global_position)
	if distance <= HELICOPTER_BOARD_DISTANCE:
		if helicopter.has_method("npc_enter_helicopter"):
			var success: bool = bool(helicopter.call("npc_enter_helicopter", unit))
			if success:
				unit.set_meta("wants_helicopter", false)
				unit.set_meta("helicopter_target_id", 0)
				unit.velocity = Vector3.ZERO
				return true

	return false


# ---------------- UNIT UPDATE ----------------
func update_units(delta: float) -> void:
	for i in range(all_units.size() - 1, -1, -1):
		var unit: CharacterBody3D = all_units[i]

		if unit == null or not is_instance_valid(unit):
			all_units.remove_at(i)
			continue

		if bool(unit.get_meta("is_final_boss", false)):
			update_final_boss_unit_state(unit, delta)
			continue

		update_spawn_immunity(unit, delta)

		if bool(unit.get_meta("dead")) or int(unit.get_meta("health")) <= 0:
			handle_unit_objective_death(unit)

			var dead_team: String = str(unit.get_meta("team"))

			remove_unit(unit)
			all_units.remove_at(i)
			red_units.erase(unit)
			blue_units.erase(unit)

			if dead_team == "red" and red_respawn_timer <= 0.0:
				red_respawn_timer = rng.randf_range(RESPAWN_DELAY_MIN, RESPAWN_DELAY_MAX)
			elif dead_team == "blue" and blue_respawn_timer <= 0.0:
				blue_respawn_timer = rng.randf_range(RESPAWN_DELAY_MIN, RESPAWN_DELAY_MAX)

			continue

		update_one_unit(unit, delta)

func update_spawn_immunity(unit: CharacterBody3D, delta: float) -> void:
	var timer: float = get_meta_float(unit, "spawn_immune_timer", 0.0)

	if timer > 0.0:
		timer -= delta
		timer = max(timer, 0.0)
		unit.set_meta("spawn_immune_timer", timer)

	var strength: float = 0.0

	if timer > 0.0:
		strength = timer / SPAWN_IMMUNITY_TIME

	set_model_white_fade(unit, strength)


func set_model_white_fade(unit: CharacterBody3D, strength: float) -> void:
	var model_root: Node3D = unit.get_node_or_null("Model") as Node3D

	if model_root == null:
		return

	var meshes: Array[Node] = model_root.find_children("*", "MeshInstance3D", true, false)

	for node in meshes:
		var mesh_node: MeshInstance3D = node as MeshInstance3D

		if mesh_node == null:
			continue

		var mat: StandardMaterial3D = mesh_node.material_override as StandardMaterial3D

		if mat == null:
			continue

		var base_color: Color = Color(1.0, 1.0, 1.0, 1.0)

		if mesh_node.has_meta("base_color"):
			base_color = mesh_node.get_meta("base_color") as Color
		else:
			base_color = mat.albedo_color
			mesh_node.set_meta("base_color", base_color)

		mat.albedo_color = base_color.lerp(Color(1.0, 1.0, 1.0, 1.0), strength * 0.75)


func update_one_unit(unit: CharacterBody3D, delta: float) -> void:
	if bool(unit.get_meta("in_helicopter")):
		unit.velocity = Vector3.ZERO
		return

	apply_bounds(unit)

	if bool(unit.get_meta("wants_helicopter")):
		if update_unit_helicopter_boarding(unit):
			return

	var target: Node3D = get_current_target(unit, delta)
	var distance_to_target: float = 9999.0
	var direction_to_target: Vector3 = Vector3.ZERO

	var assigned_helicopter: Node3D = get_assigned_helicopter(unit)
	if assigned_helicopter != null:
		var to_helicopter: Vector3 = assigned_helicopter.global_position - unit.global_position
		to_helicopter.y = 0.0
		distance_to_target = to_helicopter.length()
		if distance_to_target > 0.01:
			direction_to_target = to_helicopter.normalized()
			unit.look_at(unit.global_position + direction_to_target, Vector3.UP)
		target = assigned_helicopter

	if is_valid_target(target):
		var to_target: Vector3 = target.global_position - unit.global_position
		to_target.y = 0.0
		distance_to_target = to_target.length()

		if distance_to_target > 0.01:
			direction_to_target = to_target.normalized()
			unit.look_at(unit.global_position + direction_to_target, Vector3.UP)
	else:
		var search_position: Vector3 = get_search_position(unit)
		var to_search: Vector3 = search_position - unit.global_position
		to_search.y = 0.0
		distance_to_target = to_search.length()

		if distance_to_target > 0.01:
			direction_to_target = to_search.normalized()
			unit.look_at(unit.global_position + direction_to_target, Vector3.UP)

	update_ai_state(unit, target, distance_to_target, delta)

	var state: String = str(unit.get_meta("state"))
	var move_direction: Vector3 = get_tactical_move_direction(unit, direction_to_target)

	apply_gravity_and_jump(unit, move_direction, delta)

	var speed: float = get_meta_float(unit, "speed", 4.0)
	var sprinting_now: bool = should_unit_sprint(unit, target, distance_to_target)

	if sprinting_now:
		speed *= NPC_SPRINT_MULTIPLIER

	if state == "hold" or state == "reload" or state == "suppress":
		unit.velocity.x = move_toward(unit.velocity.x, 0.0, speed * delta)
		unit.velocity.z = move_toward(unit.velocity.z, 0.0, speed * delta)
	elif state == "retreat":
		unit.velocity.x = move_direction.x * speed * 1.15
		unit.velocity.z = move_direction.z * speed * 1.15
	elif state == "push":
		unit.velocity.x = move_direction.x * speed * 1.10
		unit.velocity.z = move_direction.z * speed * 1.10
	else:
		unit.velocity.x = move_direction.x * speed
		unit.velocity.z = move_direction.z * speed

	unit.move_and_slide()
	update_footstep_sound(unit, delta)
	apply_bounds(unit)

	handle_stuck_jump(unit, delta)
	animate_unit(unit, delta)
	if not bool(unit.get_meta("wants_helicopter")):
		try_unit_shoot(unit, target, distance_to_target, delta)
	update_health_bar(unit)


func get_enemy_center_for_team(team: String) -> Vector3:
	var enemy_pool: Array[CharacterBody3D] = blue_units if team == "red" else red_units
	var total: Vector3 = Vector3.ZERO
	var count: int = 0

	for enemy in enemy_pool:
		if is_valid_target(enemy):
			total += enemy.global_position
			count += 1

	if team == "red" and player != null and is_instance_valid(player) and not is_player_dead():
		total += player.global_position
		count += 1

	if count > 0:
		return total / float(count)

	if team == "red":
		return BLUE_SPAWN_POSITION

	return RED_SPAWN_POSITION


func get_search_position(unit: CharacterBody3D) -> Vector3:
	if unit == null or not is_instance_valid(unit):
		return Vector3.ZERO

	if selected_game_mode == GAME_MODE_CTF:
		var ctf_anchor: Vector3 = get_meta_vector3(unit, "search_anchor", Vector3.ZERO)
		var ctf_timer: float = get_meta_float(unit, "search_repick_timer", 0.0)

		if ctf_anchor == Vector3.ZERO or unit.global_position.distance_to(ctf_anchor) < NPC_SEARCH_POINT_REACHED_DISTANCE or ctf_timer <= 0.0:
			choose_new_search_anchor(unit)
			ctf_anchor = get_meta_vector3(unit, "search_anchor", get_ctf_goal_position_for_unit(unit))

		var ctf_phase: float = get_meta_float(unit, "phase", 0.0)
		var ctf_anim: float = get_meta_float(unit, "anim_time", 0.0)
		var ctf_role: String = get_ctf_role(unit)
		var ctf_wander: float = 10.0

		if ctf_role == CTF_DEFENDER_ROLE:
			ctf_wander = 18.0
		elif ctf_role == CTF_ESCORT_ROLE:
			ctf_wander = 8.0
		elif ctf_role == CTF_ATTACKER_ROLE:
			ctf_wander = 24.0
		elif ctf_role == CTF_MIDFIELD_ROLE:
			ctf_wander = 35.0

		return ctf_anchor + Vector3(sin(ctf_anim * 0.45 + ctf_phase) * ctf_wander, 0.0, cos(ctf_anim * 0.38 + ctf_phase) * ctf_wander)

	var search_anchor: Vector3 = get_meta_vector3(unit, "search_anchor", Vector3.ZERO)
	var timer: float = get_meta_float(unit, "search_repick_timer", 0.0)
	var role: String = str(unit.get_meta("ai_role"))

	if search_anchor == Vector3.ZERO or unit.global_position.distance_to(search_anchor) < NPC_SEARCH_POINT_REACHED_DISTANCE or timer <= 0.0:
		choose_new_search_anchor(unit)
		search_anchor = get_meta_vector3(unit, "search_anchor", unit.global_position)

	var phase: float = get_meta_float(unit, "phase", 0.0)
	var anim_time: float = get_meta_float(unit, "anim_time", 0.0)
	var wander_radius: float = 18.0

	if role == "scout" or role == "wander":
		wander_radius = 45.0
	elif role == "flanker":
		wander_radius = 32.0
	elif role == "ambusher":
		wander_radius = 10.0

	return search_anchor + Vector3(sin(anim_time * 0.35 + phase) * wander_radius, 0.0, cos(anim_time * 0.28 + phase) * wander_radius)


func is_valid_target(target: Node3D) -> bool:
	if target == null:
		return false

	if not is_instance_valid(target):
		return false

	if target is CharacterBody3D:
		var body: CharacterBody3D = target as CharacterBody3D

		if bool(body.get_meta("is_final_boss", false)):
			return final_boss_current_hp > 0

		if body.has_meta("dead") and bool(body.get_meta("dead")):
			return false

	return true

func apply_bounds(unit: CharacterBody3D) -> void:
	if unit.global_position.y < FALL_RESET_Y:
		var team: String = str(unit.get_meta("team"))
		var base_position: Vector3 = RED_SPAWN_POSITION if team == "red" else BLUE_SPAWN_POSITION
		unit.global_position = snap_position_to_ground(base_position + Vector3(rng.randf_range(-5.0, 5.0), 0.0, rng.randf_range(-5.0, 5.0)))
		unit.velocity = Vector3.ZERO
		return

	unit.global_position.x = clamp(unit.global_position.x, MIN_BOUND, MAX_BOUND)
	unit.global_position.z = clamp(unit.global_position.z, MIN_BOUND, MAX_BOUND)


# ---------------- TARGETING ----------------
func get_current_target(unit: CharacterBody3D, delta: float) -> Node3D:
	var search_timer: float = get_meta_float(unit, "search_repick_timer", 0.0)
	search_timer -= delta
	unit.set_meta("search_repick_timer", search_timer)

	var refresh_timer: float = get_meta_float(unit, "target_refresh_timer", 0.0)
	refresh_timer -= delta

	var stored_target: Node3D = get_target_from_id(int(unit.get_meta("target_instance_id")))

	if refresh_timer > 0.0 and is_valid_target(stored_target) and can_track_target(unit, stored_target):
		unit.set_meta("target_refresh_timer", refresh_timer)
		return stored_target

	refresh_timer = rng.randf_range(0.25, 0.75)
	unit.set_meta("target_refresh_timer", refresh_timer)

	var team: String = str(unit.get_meta("team"))
	var role: String = str(unit.get_meta("ai_role"))
	var best_target: Node3D = null
	var best_score: float = 999999.0
	var detect_distance: float = NPC_DETECT_DISTANCE

	if role == "ambusher":
		detect_distance = NPC_AMBUSH_DETECT_DISTANCE
	elif role == "scout":
		detect_distance = NPC_LOS_DETECT_DISTANCE

	var special_priority: Node3D = get_special_mode_priority_target(unit)
	if special_priority != null and is_valid_target(special_priority):
		unit.set_meta("target_instance_id", special_priority.get_instance_id())
		return special_priority

	if selected_game_mode == GAME_MODE_CTF:
		var ctf_role: String = get_ctf_role(unit)
		var enemy_flag_carrier: Node3D = get_enemy_flag_carrier_for_team(team)
		var friendly_flag_carrier: Node3D = get_friendly_flag_carrier_for_team(team)

		# When the enemy has our flag, hunters/defenders/midfielders prioritize the carrier.
		if enemy_flag_carrier != null and is_valid_target(enemy_flag_carrier):
			if ctf_role == CTF_HUNTER_ROLE or ctf_role == CTF_DEFENDER_ROLE or ctf_role == CTF_MIDFIELD_ROLE:
				unit.set_meta("target_instance_id", enemy_flag_carrier.get_instance_id())
				return enemy_flag_carrier

		# Escorts stay near the friendly carrier and shoot threats around them.
		if friendly_flag_carrier != null and is_valid_target(friendly_flag_carrier) and ctf_role == CTF_ESCORT_ROLE:
			if unit.global_position.distance_to(friendly_flag_carrier.global_position) > CTF_ESCORT_DISTANCE * 1.8:
				unit.set_meta("target_instance_id", 0)
				return null

	var enemy_pool: Array[CharacterBody3D] = blue_units if team == "red" else red_units

	for enemy in enemy_pool:
		if not is_valid_target(enemy):
			continue

		var distance: float = unit.global_position.distance_to(enemy.global_position)
		var has_los: bool = has_combat_line_of_sight(unit, enemy)

		if distance > detect_distance and not (has_los and distance <= NPC_LOS_DETECT_DISTANCE):
			continue

		var score: float = distance + rng.randf_range(-18.0, 18.0)

		if has_los:
			score -= 65.0

		if role == "opportunist" and has_los:
			score -= 35.0

		if is_target_spawn_immune(enemy):
			score += 250.0

		if score < best_score:
			best_score = score
			best_target = enemy

	# Player is a blue-team combatant. Red can only track the player when close enough or visible.
	if team == "red" and player != null and is_instance_valid(player) and not is_player_dead():
		var player_distance: float = unit.global_position.distance_to(player.global_position)
		var player_has_los: bool = has_combat_line_of_sight(unit, player)

		if player_distance <= detect_distance or player_distance <= 95.0 or (player_has_los and player_distance <= NPC_LOS_DETECT_DISTANCE):
			var player_score: float = player_distance - RED_PLAYER_SLIGHT_TARGET_BONUS + rng.randf_range(PLAYER_TARGET_SCORE_RANDOM_MIN, PLAYER_TARGET_SCORE_RANDOM_MAX)

			if player_has_los:
				player_score -= 75.0

			# If the player is close, red should treat the player as a priority target, not only hit by crossfire.
			if player_distance <= 95.0:
				player_score -= 175.0
			elif player_distance <= RED_PLAYER_TARGET_CLOSE_DISTANCE:
				player_score -= RED_PLAYER_TARGET_CLOSE_EXTRA_BONUS

			if player_score < best_score:
				best_score = player_score
				best_target = player


	# A piloted enemy helicopter is a valid tactical target.
	var helicopters: Array[Node] = get_tree().get_nodes_in_group("Helicopter")
	for helicopter_node in helicopters:
		if helicopter_node == null or not is_instance_valid(helicopter_node):
			continue
		if not helicopter_node is Node3D:
			continue
		var helicopter_target: Node3D = helicopter_node as Node3D
		if helicopter_target.has_method("is_destroyed") and bool(helicopter_target.call("is_destroyed")):
			continue
		if helicopter_target.has_method("is_invincible") and bool(helicopter_target.call("is_invincible")):
			continue
		if not helicopter_target.has_method("has_pilot") or not bool(helicopter_target.call("has_pilot")):
			continue
		if helicopter_target.has_method("get_pilot_team") and str(helicopter_target.call("get_pilot_team")) == team:
			continue

		var helicopter_distance: float = unit.global_position.distance_to(helicopter_target.global_position)
		var helicopter_los: bool = has_combat_line_of_sight(unit, helicopter_target)
		if helicopter_distance > NPC_LOS_DETECT_DISTANCE and not helicopter_los:
			continue

		var helicopter_score: float = helicopter_distance - 90.0 + rng.randf_range(-12.0, 12.0)
		if helicopter_los:
			helicopter_score -= 70.0
		if helicopter_score < best_score:
			best_score = helicopter_score
			best_target = helicopter_target

	if best_target != null and is_instance_valid(best_target):
		unit.set_meta("target_instance_id", best_target.get_instance_id())
	else:
		unit.set_meta("target_instance_id", 0)

	return best_target


func can_track_target(unit: CharacterBody3D, target: Node3D) -> bool:
	if not is_valid_target(target):
		return false

	var distance: float = unit.global_position.distance_to(target.global_position)

	if distance <= NPC_LOST_TARGET_DISTANCE:
		return true

	if has_combat_line_of_sight(unit, target) and distance <= NPC_LOS_DETECT_DISTANCE:
		return true

	return false


func get_target_from_id(id_value: int) -> Node3D:
	if id_value <= 0:
		return null

	var obj: Object = instance_from_id(id_value)

	if obj == null:
		return null

	if not is_instance_valid(obj):
		return null

	if obj is Node3D:
		return obj as Node3D

	return null


func is_target_spawn_immune(target: Node3D) -> bool:
	if target == null:
		return false

	if not target.has_meta("spawn_immune_timer"):
		return false

	return float(target.get_meta("spawn_immune_timer")) > 0.0


func update_ai_state(unit: CharacterBody3D, target: Node3D, distance_to_target: float, delta: float) -> void:
	var state_timer: float = get_meta_float(unit, "state_timer", 0.0)
	state_timer -= delta

	var reload_timer: float = get_meta_float(unit, "reload_timer", 0.0)
	reload_timer = max(0.0, reload_timer - delta)
	unit.set_meta("reload_timer", reload_timer)

	var current_state: String = str(unit.get_meta("state"))

	if bool(unit.get_meta("wants_helicopter")):
		unit.set_meta("state", "use_helicopter")
		unit.set_meta("state_timer", 0.30)
		return

	if current_state == "repath" and state_timer > 0.0:
		unit.set_meta("state_timer", state_timer)
		return

	if reload_timer > 0.0:
		unit.set_meta("state", "reload")
		unit.set_meta("state_timer", 0.35)
		return

	if state_timer > 0.0:
		unit.set_meta("state_timer", state_timer)
		return

	var team: String = str(unit.get_meta("team"))
	var role: String = str(unit.get_meta("ai_role"))
	var personality: int = int(unit.get_meta("personality"))
	var local_advantage: int = get_local_advantage(unit, 40.0)
	var outnumbered_badly: bool = local_advantage <= -2
	var has_advantage: bool = local_advantage >= 1

	var shoot_distance: float = get_meta_float(unit, "shoot_distance", 140.0)
	var stop_distance: float = get_meta_float(unit, "stop_distance", 20.0)
	var plan: int = get_team_plan(team)
	var new_state: String = "search"

	if uses_special_objective_ai_mode() and selected_game_mode != GAME_MODE_CTF:
		new_state = get_special_mode_ai_state(unit, target)
		unit.set_meta("state", new_state)
		unit.set_meta("state_timer", rng.randf_range(0.45, 1.15))
		return

	if selected_game_mode == GAME_MODE_CTF:
		var ctf_role: String = get_ctf_role(unit)
		var carrying: String = str(unit.get_meta("carrying_flag", ""))
		var enemy_carrier: Node3D = get_enemy_flag_carrier_for_team(team)
		var friendly_carrier: Node3D = get_friendly_flag_carrier_for_team(team)

		if carrying != "":
			new_state = "zigzag"
		elif enemy_carrier != null and (ctf_role == CTF_HUNTER_ROLE or ctf_role == CTF_DEFENDER_ROLE or ctf_role == CTF_MIDFIELD_ROLE):
			new_state = "push"
		elif friendly_carrier != null and ctf_role == CTF_ESCORT_ROLE:
			new_state = "zigzag"
		elif ctf_role == CTF_DEFENDER_ROLE:
			new_state = "suppress" if is_valid_target(target) else "patrol"
		elif ctf_role == CTF_ATTACKER_ROLE:
			new_state = "flank_left" if get_meta_float(unit, "strafe_side", 1.0) < 0.0 else "flank_right"
		elif ctf_role == CTF_MIDFIELD_ROLE:
			new_state = "zigzag"
		else:
			new_state = "advance"

		unit.set_meta("state", new_state)
		unit.set_meta("state_timer", rng.randf_range(0.50, 1.20))
		return

	if not is_valid_target(target):
		if role == "ambusher" and is_team_losing(team):
			new_state = "hide"
		elif role == "headon":
			new_state = "advance"
		elif role == "scout":
			new_state = "patrol"
		elif role == "flanker":
			new_state = "flank_search"
		else:
			new_state = "search"
	elif role == "ambusher" and distance_to_target > NPC_AMBUSH_DETECT_DISTANCE and not has_combat_line_of_sight(unit, target):
		new_state = "hide"
	elif outnumbered_badly and distance_to_target < shoot_distance:
		new_state = "retreat"
	elif distance_to_target > shoot_distance:
		if role == "flanker":
			new_state = "flank_right" if get_meta_float(unit, "strafe_side", 1.0) > 0.0 else "flank_left"
		else:
			new_state = "advance"
	elif has_advantage and distance_to_target > stop_distance:
		new_state = "push"
	elif distance_to_target < stop_distance * 0.50:
		new_state = "retreat"
	else:
		if role == "ambusher":
			new_state = "suppress"
		elif plan == BattlePlan.FALL_BACK:
			new_state = "retreat"
		elif plan == BattlePlan.HOLD:
			new_state = "suppress"
		elif plan == BattlePlan.FLANK_LEFT:
			new_state = "flank_left"
		elif plan == BattlePlan.FLANK_RIGHT:
			new_state = "flank_right"
		elif role == "opportunist":
			new_state = "suppress" if has_combat_line_of_sight(unit, target) else "zigzag"
		elif personality == 0 or personality == 6:
			new_state = "suppress"
		elif personality == 1:
			new_state = "flank_left"
		elif personality == 2:
			new_state = "flank_right"
		elif personality == 3:
			new_state = "hold"
		elif personality == 4:
			new_state = "zigzag"
		elif personality == 5:
			new_state = "push"
		else:
			new_state = "advance"

	unit.set_meta("state", new_state)
	unit.set_meta("state_timer", rng.randf_range(0.65, 1.8))


func get_local_advantage(unit: CharacterBody3D, radius: float) -> int:
	var team: String = str(unit.get_meta("team"))
	var friendly_count: int = 0
	var enemy_count: int = 0

	for other in all_units:
		if not is_valid_target(other):
			continue

		if other == unit:
			continue

		if unit.global_position.distance_to(other.global_position) > radius:
			continue

		var other_team: String = str(other.get_meta("team"))

		if other_team == team:
			friendly_count += 1
		else:
			enemy_count += 1

	if team == "red" and player != null and is_instance_valid(player) and not is_player_dead():
		if unit.global_position.distance_to(player.global_position) <= radius:
			enemy_count += 1

	return friendly_count - enemy_count


func get_tactical_move_direction(unit: CharacterBody3D, direction_to_target: Vector3) -> Vector3:
	var state: String = str(unit.get_meta("state"))
	var phase: float = get_meta_float(unit, "phase", 0.0)
	var anim_time: float = get_meta_float(unit, "anim_time", 0.0)
	var side: float = get_meta_float(unit, "strafe_side", 1.0)
	var flank_strength: float = get_meta_float(unit, "flank_strength", 0.5)

	if state == "repath":
		var repath_position: Vector3 = get_meta_vector3(unit, "repath_position", unit.global_position)
		var to_repath: Vector3 = repath_position - unit.global_position
		to_repath.y = 0.0

		if to_repath.length() > 0.01:
			return to_repath.normalized()

	if state == "use_helicopter":
		if direction_to_target.length() > 0.01:
			return direction_to_target.normalized()

	if direction_to_target.length() < 0.01:
		var separation_only: Vector3 = get_separation_force(unit)

		if separation_only.length() > 0.01:
			return separation_only.normalized()

		return Vector3.ZERO

	var right_direction: Vector3 = Vector3(-direction_to_target.z, 0.0, direction_to_target.x)
	var desired: Vector3 = direction_to_target

	if state == "retreat":
		desired = -direction_to_target + right_direction * side * 0.70
	elif state == "flank_left":
		desired = direction_to_target * 0.28 - right_direction * flank_strength * 1.20
	elif state == "flank_right":
		desired = direction_to_target * 0.28 + right_direction * flank_strength * 1.20
	elif state == "flank_search":
		desired = direction_to_target * 0.45 + right_direction * side * 1.35
	elif state == "zigzag":
		desired = direction_to_target + right_direction * sin(anim_time * 2.8 + phase) * 1.20
	elif state == "patrol":
		desired = direction_to_target + right_direction * sin(anim_time * 0.85 + phase) * 0.80
	elif state == "search":
		desired = direction_to_target + right_direction * sin(anim_time * 0.55 + phase) * 0.65
	elif state == "hide":
		var hide_position: Vector3 = get_meta_vector3(unit, "hide_position", unit.global_position)
		var to_hide: Vector3 = hide_position - unit.global_position
		to_hide.y = 0.0

		if to_hide.length() < 7.0:
			desired = right_direction * sin(anim_time * 0.8 + phase) * 0.08
		else:
			desired = to_hide.normalized()
	elif state == "hold" or state == "suppress":
		desired = right_direction * sin(anim_time * 1.7 + phase) * 0.30
	elif state == "push":
		desired = direction_to_target + right_direction * side * 0.25
	else:
		desired = direction_to_target + right_direction * side * 0.22

	desired += get_separation_force(unit) * 1.15

	if desired.length() > 0.01:
		desired = desired.normalized()

	return desired


func get_separation_force(unit: CharacterBody3D) -> Vector3:
	var force: Vector3 = Vector3.ZERO

	for other in all_units:
		if not is_valid_target(other):
			continue

		if other == unit:
			continue

		var away: Vector3 = unit.global_position - other.global_position
		away.y = 0.0

		var dist: float = away.length()

		if dist > 0.01 and dist < NPC_SEPARATION_DISTANCE:
			force += away.normalized() * ((NPC_SEPARATION_DISTANCE - dist) / NPC_SEPARATION_DISTANCE)

	return force


# ---------------- MOVEMENT ----------------
func should_unit_sprint(unit: CharacterBody3D, target: Node3D, distance_to_target: float) -> bool:
	if unit == null or not is_instance_valid(unit):
		return false

	var state: String = str(unit.get_meta("state"))

	if state == "use_helicopter":
		return true

	if uses_special_objective_ai_mode() and selected_game_mode != GAME_MODE_CTF:
		return true

	if selected_game_mode == GAME_MODE_CTF:
		var carrying: String = str(unit.get_meta("carrying_flag", ""))
		var ctf_role: String = get_ctf_role(unit)

		if carrying != "":
			return true
		if get_enemy_flag_carrier_for_team(str(unit.get_meta("team"))) != null and (ctf_role == CTF_HUNTER_ROLE or ctf_role == CTF_DEFENDER_ROLE or ctf_role == CTF_MIDFIELD_ROLE):
			return true
		if ctf_role == CTF_DEFENDER_ROLE and get_enemy_flag_carrier_for_team(str(unit.get_meta("team"))) == null:
			return false

	if state == "reload" or state == "hold" or state == "suppress" or state == "hide":
		return false

	if is_valid_target(target):
		return distance_to_target > NPC_SPRINT_DISTANCE

	return distance_to_target > NPC_SPRINT_SEARCH_DISTANCE

func apply_gravity_and_jump(unit: CharacterBody3D, move_direction: Vector3, delta: float) -> void:
	if not unit.is_on_floor():
		unit.velocity.y -= GRAVITY * delta
	else:
		if unit.velocity.y < 0.0:
			unit.velocity.y = 0.0

		var should_jump: bool = false

		if rng.randf() < 0.001:
			should_jump = true

		if move_direction.length() > 0.2 and is_wall_ahead(unit, move_direction) and can_jump_over_obstacle(unit, move_direction):
			should_jump = true

		if should_jump:
			unit.velocity.y = JUMP_FORCE


func is_wall_ahead(unit: CharacterBody3D, move_direction: Vector3) -> bool:
	if move_direction.length() < 0.01:
		return false

	var start: Vector3 = unit.global_position + Vector3(0.0, NPC_WALL_RAY_HEIGHT_LOW, 0.0)
	var end: Vector3 = start + move_direction.normalized() * 1.55

	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(start, end)
	query.exclude = [unit.get_rid()]
	query.collide_with_bodies = true
	query.collide_with_areas = false

	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)

	# If the ray reaches the target point without hitting anything, the line is clear.
	# This is important when the player camera/collision is moved or hidden by helicopter handoff code.
	if hit.size() <= 0:
		return true

	var hit_object: Node = hit["collider"] as Node

	if hit_object != null and hit_object.is_in_group("BattleNPC"):
		return false

	return true


func can_jump_over_obstacle(unit: CharacterBody3D, move_direction: Vector3) -> bool:
	if move_direction.length() < 0.01:
		return false

	# If the high ray also hits, it is probably a wall, not a low step. Do not keep jumping into it.
	var start: Vector3 = unit.global_position + Vector3(0.0, NPC_WALL_RAY_HEIGHT_HIGH, 0.0)
	var end: Vector3 = start + move_direction.normalized() * 1.75
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(start, end)
	query.exclude = [unit.get_rid()]
	query.collide_with_bodies = true
	query.collide_with_areas = false

	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	return hit.size() <= 0


func handle_stuck_jump(unit: CharacterBody3D, delta: float) -> void:
	var last_position: Vector3 = get_meta_vector3(unit, "last_position", unit.global_position)
	var moved: float = unit.global_position.distance_to(last_position)
	var stuck_timer: float = get_meta_float(unit, "stuck_timer", 0.0)
	var horizontal_speed: float = Vector2(unit.velocity.x, unit.velocity.z).length()

	if horizontal_speed > 0.5 and moved < 0.045:
		stuck_timer += delta
	else:
		stuck_timer = max(stuck_timer - delta * 0.7, 0.0)

	if stuck_timer > 0.45 and unit.is_on_floor():
		var move_direction: Vector3 = Vector3(unit.velocity.x, 0.0, unit.velocity.z)

		if move_direction.length() > 0.1 and can_jump_over_obstacle(unit, move_direction):
			unit.velocity.y = JUMP_FORCE

	if stuck_timer > STUCK_REPATH_TIME:
		set_repath_position(unit)
		stuck_timer = 0.0

	unit.set_meta("stuck_timer", stuck_timer)
	unit.set_meta("last_position", unit.global_position)


func set_repath_position(unit: CharacterBody3D) -> void:
	if unit == null or not is_instance_valid(unit):
		return

	var current_state: String = str(unit.get_meta("state"))
	var desired_direction: Vector3 = Vector3(unit.velocity.x, 0.0, unit.velocity.z)

	if desired_direction.length() < 0.1:
		var anchor: Vector3 = get_meta_vector3(unit, "search_anchor", get_search_position(unit))
		desired_direction = anchor - unit.global_position
		desired_direction.y = 0.0

	if desired_direction.length() < 0.1:
		desired_direction = Vector3.FORWARD

	desired_direction = desired_direction.normalized()
	var best_position: Vector3 = find_best_repath_position(unit, desired_direction)

	unit.set_meta("last_state_before_repath", current_state)
	unit.set_meta("repath_position", best_position)
	unit.set_meta("search_anchor", best_position)
	unit.set_meta("state", "repath")
	unit.set_meta("state_timer", NPC_REPATH_TIME)
	unit.set_meta("strafe_side", -get_meta_float(unit, "strafe_side", 1.0))


func find_best_repath_position(unit: CharacterBody3D, desired_direction: Vector3) -> Vector3:
	var angles: Array[float] = [70.0, -70.0, 115.0, -115.0, 35.0, -35.0, 160.0, -160.0]
	var best_position: Vector3 = unit.global_position - desired_direction * 12.0
	var best_score: float = -999999.0

	for angle in angles:
		var candidate_direction: Vector3 = desired_direction.rotated(Vector3.UP, deg_to_rad(angle)).normalized()
		var candidate: Vector3 = unit.global_position + candidate_direction * NPC_REPATH_TEST_DISTANCE
		candidate.x = clamp(candidate.x, MIN_BOUND + 8.0, MAX_BOUND - 8.0)
		candidate.z = clamp(candidate.z, MIN_BOUND + 8.0, MAX_BOUND - 8.0)
		candidate = snap_position_to_ground(candidate)

		if not is_path_segment_clear(unit, candidate):
			continue

		var score: float = candidate.distance_to(unit.global_position)
		score += rng.randf_range(-8.0, 8.0)

		if score > best_score:
			best_score = score
			best_position = candidate

	return best_position


func is_path_segment_clear(unit: CharacterBody3D, destination: Vector3) -> bool:
	var start: Vector3 = unit.global_position + Vector3(0.0, 0.85, 0.0)
	var end: Vector3 = destination + Vector3(0.0, 0.85, 0.0)
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(start, end)
	query.exclude = [unit.get_rid()]
	query.collide_with_bodies = true
	query.collide_with_areas = false

	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)

	if hit.size() <= 0:
		return true

	var hit_object: Node = hit["collider"] as Node

	if hit_object != null and hit_object.is_in_group("BattleNPC"):
		return true

	return false


# ---------------- LASER TAG VISUALS ----------------
func get_team_laser_color(team: String) -> Color:
	if team == "red":
		return RED_LASER_COLOR

	return BLUE_LASER_COLOR


func spawn_laser_ray(start_position: Vector3, end_position: Vector3, team: String) -> void:
	var direction: Vector3 = end_position - start_position

	if direction.length() < 0.01:
		return

	var laser: MeshInstance3D = MeshInstance3D.new()
	laser.name = "LaserRay"

	var cylinder: CylinderMesh = CylinderMesh.new()
	cylinder.top_radius = LASER_WIDTH
	cylinder.bottom_radius = LASER_WIDTH
	cylinder.height = direction.length()
	cylinder.radial_segments = 8
	laser.mesh = cylinder

	var material: StandardMaterial3D = make_material(get_team_laser_color(team), 3.0)
	laser.material_override = material

	get_tree().current_scene.add_child(laser)

	laser.global_position = start_position + direction * 0.5
	laser.look_at(end_position, Vector3.UP)
	laser.rotate_object_local(Vector3.RIGHT, deg_to_rad(90.0))

	await get_tree().create_timer(LASER_LIFETIME).timeout

	if is_instance_valid(laser):
		laser.queue_free()

func get_laser_stop_position(start_position: Vector3, direction: Vector3, max_distance: float, team: String) -> Vector3:
	var end_position: Vector3 = start_position + direction.normalized() * max_distance

	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(start_position, end_position)
	query.exclude = get_laser_visual_exclude_rids(team)
	query.collide_with_bodies = true
	query.collide_with_areas = true

	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)

	if hit.size() > 0:
		return as_safe_vector3(hit.get("position", Vector3.ZERO), Vector3.ZERO)

	return end_position


func get_laser_visual_exclude_rids(team: String) -> Array[RID]:
	var exclude_rids: Array[RID] = []
	var friendly_pool: Array[CharacterBody3D] = red_units if team == "red" else blue_units

	for unit in friendly_pool:
		if unit != null and is_instance_valid(unit):
			exclude_rids.append(unit.get_rid())

	if team == "blue" and player != null and is_instance_valid(player):
		exclude_rids.append(player.get_rid())

	return exclude_rids

# ---------------- SHOOTING ----------------

func is_player_target(target: Node3D) -> bool:
	return player != null and is_instance_valid(player) and target == player


func should_red_force_shoot_player(unit: CharacterBody3D, target: Node3D, distance_to_target: float) -> bool:
	# CPU should not magically force shots on the player.
	# They must use normal line of sight and normal shooting rules.
	return false

func get_effective_shoot_distance(unit: CharacterBody3D, target: Node3D) -> float:
	var base_distance: float = get_meta_float(unit, "shoot_distance", 120.0)

	# Red CPUs cannot hit the player from very far away.
	if str(unit.get_meta("team")) == "red" and is_player_target(target):
		return min(base_distance, NPC_MAX_PLAYER_HIT_RANGE)

	return base_distance

func try_unit_shoot(unit: CharacterBody3D, target: Node3D, distance_to_target: float, delta: float) -> void:
	if not is_valid_target(target):
		return

	var fire_timer: float = get_meta_float(unit, "fire_timer", 0.0)
	fire_timer -= delta

	if fire_timer > 0.0:
		unit.set_meta("fire_timer", fire_timer)
		return

	var reload_timer: float = get_meta_float(unit, "reload_timer", 0.0)

	if reload_timer > 0.0:
		return

	var shoot_distance: float = get_effective_shoot_distance(unit, target)

	if distance_to_target > shoot_distance:
		unit.set_meta("fire_timer", rng.randf_range(0.15, 0.45))
		return

	if not has_combat_line_of_sight(unit, target) and not should_red_force_shoot_player(unit, target, distance_to_target):
		unit.set_meta("fire_timer", rng.randf_range(0.20, 0.55))
		return

	var state: String = str(unit.get_meta("state"))

	if state == "advance" and rng.randf() < 0.12 and not should_red_force_shoot_player(unit, target, distance_to_target):
		unit.set_meta("fire_timer", rng.randf_range(0.25, 0.6))
		return

	shoot_at_target(unit, target)

	var ammo: int = int(unit.get_meta("ammo"))
	ammo -= 1
	unit.set_meta("ammo", ammo)

	if ammo <= 0:
		unit.set_meta("ammo", int(unit.get_meta("mag_size")))
		unit.set_meta("reload_timer", get_meta_float(unit, "reload_time", 1.8))
		unit.set_meta("fire_timer", 0.2)
	else:
		var cooldown: float = get_meta_float(unit, "fire_cooldown", 1.0)

		if state == "suppress":
			cooldown *= 0.55
		if should_red_force_shoot_player(unit, target, distance_to_target):
			cooldown *= 0.45

		unit.set_meta("fire_timer", cooldown)
		
func get_muzzle_position(unit: CharacterBody3D) -> Vector3:
	if unit == null or not is_instance_valid(unit):
		return Vector3.ZERO

	var barrel: Node3D = unit.get_node_or_null("Model/RightArmPivot/RightHand/GunRoot/RifleBarrel") as Node3D

	if barrel != null and is_instance_valid(barrel):
		return barrel.global_position + (-barrel.global_transform.basis.z * 0.45)

	return unit.global_position + Vector3(0.0, 1.45, -0.8)


func shoot_at_target(unit: CharacterBody3D, target: Node3D) -> void:
	if unit == null or not is_instance_valid(unit):
		return

	if not is_valid_target(target):
		return

	var muzzle_position: Vector3 = get_muzzle_position(unit)
	var target_position: Vector3 = target.global_position + Vector3(0.0, 1.0, 0.0)

	var distance: float = muzzle_position.distance_to(target_position)

	# Red CPU player rule:
	# If the player is too far away, the shot becomes visual only.
	if str(unit.get_meta("team")) == "red" and is_player_target(target):
		if distance > NPC_MAX_PLAYER_HIT_RANGE:
			var miss_direction: Vector3 = (target_position - muzzle_position).normalized()
			var visual_end: Vector3 = muzzle_position + miss_direction * NPC_MAX_PLAYER_HIT_RANGE
			spawn_laser_ray(muzzle_position, visual_end, str(unit.get_meta("team")))
			play_unit_sound(unit, "shoot")
			return

		# Only 50% of red CPU shots are allowed to be accurate enough to hit the player.
		if rng.randf() > NPC_CHANCE_TO_HIT_PLAYER:
			target_position += Vector3(
				rng.randf_range(-7.0, 7.0),
				rng.randf_range(-1.5, 2.5),
				rng.randf_range(-7.0, 7.0)
			)

	var aim_error: float = NPC_AIM_ERROR_BASE + distance * NPC_AIM_ERROR_DISTANCE_FACTOR

	# Do not give red CPU extra aim help against the player.
	if str(unit.get_meta("team")) == "red" and is_player_target(target):
		aim_error *= 1.35

	var state: String = str(unit.get_meta("state"))

	if state == "suppress":
		aim_error *= 1.35

	target_position += Vector3(
		rng.randf_range(-aim_error, aim_error),
		rng.randf_range(-aim_error * 0.35, aim_error * 0.35),
		rng.randf_range(-aim_error, aim_error)
	)

	var direction: Vector3 = target_position - muzzle_position

	if direction.length() < 0.01:
		return

	direction = direction.normalized()

	var visual_end_position: Vector3 = get_laser_stop_position(
		muzzle_position,
		direction,
		min(distance, get_effective_shoot_distance(unit, target)),
		str(unit.get_meta("team"))
	)

	spawn_laser_ray(muzzle_position, visual_end_position, str(unit.get_meta("team")))

	var bullet: Area3D = Area3D.new()
	bullet.name = "NPCBullet"
	bullet.collision_layer = 0
	bullet.collision_mask = 1
	bullet.set_meta("direction", direction)
	bullet.set_meta("life", NPC_BULLET_LIFE)
	bullet.set_meta("team", str(unit.get_meta("team")))

	var collision: CollisionShape3D = CollisionShape3D.new()
	var sphere_shape: SphereShape3D = SphereShape3D.new()
	sphere_shape.radius = 0.07
	collision.shape = sphere_shape
	bullet.add_child(collision)

	var bullet_mesh: MeshInstance3D = MeshInstance3D.new()
	var sphere_mesh: SphereMesh = SphereMesh.new()
	sphere_mesh.radius = 0.07
	sphere_mesh.height = 0.14
	bullet_mesh.mesh = sphere_mesh
	bullet_mesh.material_override = make_material(get_team_laser_color(str(unit.get_meta("team"))), 2.5)
	bullet_mesh.visible = false
	bullet.add_child(bullet_mesh)

	get_tree().current_scene.add_child(bullet)
	bullet.global_position = muzzle_position

	if direction.length() > 0.0:
		bullet.look_at(bullet.global_position + direction, Vector3.UP)

	bullets.append(bullet)
	play_unit_sound(unit, "shoot")


func update_bullets(delta: float) -> void:
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state

	for i in range(bullets.size() - 1, -1, -1):
		var bullet: Area3D = bullets[i]

		if bullet == null or not is_instance_valid(bullet):
			bullets.remove_at(i)
			continue

		var direction: Vector3 = as_safe_vector3(get_node_vector3_meta(bullet, "direction", bullet.global_position), Vector3.ZERO)
		var life: float = float(bullet.get_meta("life"))
		var bullet_team: String = str(bullet.get_meta("team"))

		var old_position: Vector3 = bullet.global_position
		var new_position: Vector3 = old_position + direction * NPC_BULLET_SPEED * delta

		var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(old_position, new_position)
		query.exclude = get_friendly_fire_exclude_rids(bullet, bullet_team)
		query.collide_with_bodies = true
		query.collide_with_areas = true

		var hit: Dictionary = space_state.intersect_ray(query)

		if hit.size() > 0:
			var hit_object: Node = hit["collider"] as Node
			var hit_position: Vector3 = as_safe_vector3(hit["position"], Vector3.ZERO)
			var hit_normal: Vector3 = Vector3.UP

			if hit.has("normal"):
				hit_normal = as_safe_vector3(hit.get("normal", Vector3.UP), Vector3.UP)

			handle_bullet_hit(bullet_team, hit_object, hit_position, hit_normal, int(bullet.get_meta("damage", NPC_BULLET_DAMAGE)), bool(bullet.get_meta("is_final_boss_bullet", false)) or bool(bullet.get_meta("is_final_boss_laser", false)))

			bullets.remove_at(i)
			bullet.queue_free()
			continue

		# Backup hit check for the player.
		# Some player/camera setups do not give the player a reliable collider hit,
		# so red shots can visually pass through the player without damage.
		if bullet_segment_hits_player(old_position, new_position, bullet_team, float(bullet.get_meta("hit_radius", PLAYER_BULLET_HIT_RADIUS))):
			apply_red_bullet_damage_to_player(new_position, int(bullet.get_meta("damage", NPC_BULLET_DAMAGE)), bool(bullet.get_meta("is_final_boss_bullet", false)) or bool(bullet.get_meta("is_final_boss_laser", false)))
			bullets.remove_at(i)
			bullet.queue_free()
			continue

		bullet.global_position = new_position

		life -= delta
		bullet.set_meta("life", life)

		if life <= 0.0:
			bullets.remove_at(i)
			bullet.queue_free()


func get_friendly_fire_exclude_rids(bullet: Area3D, bullet_team: String) -> Array[RID]:
	var exclude_rids: Array[RID] = []

	if bullet != null and is_instance_valid(bullet):
		exclude_rids.append(bullet.get_rid())

	var friendly_pool: Array[CharacterBody3D] = red_units if bullet_team == "red" else blue_units

	for unit in friendly_pool:
		if unit != null and is_instance_valid(unit):
			exclude_rids.append(unit.get_rid())

	if bullet_team == "blue" and player != null and is_instance_valid(player):
		exclude_rids.append(player.get_rid())

	return exclude_rids


func bullet_segment_hits_player(old_position: Vector3, new_position: Vector3, bullet_team: String, hit_radius: float = PLAYER_BULLET_HIT_RADIUS) -> bool:
	if bullet_team != "red":
		return false

	if player == null or not is_instance_valid(player) or is_player_dead():
		return false

	var player_center: Vector3 = player.global_position + Vector3(0.0, 0.9, 0.0)
	var closest_point: Vector3 = closest_point_on_segment(player_center, old_position, new_position)
	var distance_to_player: float = closest_point.distance_to(player_center)

	return distance_to_player <= hit_radius

func closest_point_on_segment(point: Vector3, segment_a: Vector3, segment_b: Vector3) -> Vector3:
	var segment: Vector3 = segment_b - segment_a
	var length_squared: float = segment.length_squared()

	if length_squared <= 0.0001:
		return segment_a

	var t: float = (point - segment_a).dot(segment) / length_squared
	t = clamp(t, 0.0, 1.0)

	return segment_a + segment * t


func apply_red_bullet_damage_to_player(hit_position: Vector3, damage: int = NPC_BULLET_DAMAGE, is_boss_bullet: bool = false) -> void:
	if player == null or not is_instance_valid(player) or is_player_dead():
		return

	if is_boss_bullet:
		if not can_final_boss_damage_player():
			return

		start_final_boss_player_damage_cooldown()

	var was_dead: bool = is_player_dead()

	if player.has_method("take_damage"):
		player.call("take_damage", damage)

	if not was_dead and is_player_dead():
		player_deaths += 1
		red_kills += 1
		handle_player_objective_death()

	spawn_hit_particles(hit_position, Vector3.UP, true)

func handle_bullet_hit(bullet_team: String, hit_object: Node, hit_position: Vector3, hit_normal: Vector3, bullet_damage: int = NPC_BULLET_DAMAGE, is_boss_bullet: bool = false) -> void:
	var hit_npc: CharacterBody3D = find_npc_from_hit_object(hit_object)
	var hit_helicopter: Node = find_helicopter_from_hit_object(hit_object)
	var hit_player: CharacterBody3D = find_player_from_hit_object(hit_object)
	var hit_zone: String = get_hit_zone(hit_object)

	if hit_helicopter != null:
		if hit_helicopter.has_method("get_pilot_team") and str(hit_helicopter.call("get_pilot_team")) == bullet_team:
			return
		if hit_helicopter.has_method("is_invincible") and bool(hit_helicopter.call("is_invincible")):
			return
		if hit_helicopter.has_method("take_damage"):
			hit_helicopter.call("take_damage", NPC_BODY_DAMAGE, bullet_team)
		spawn_hit_particles(hit_position, hit_normal, true)
		return

	if hit_npc != null:
		var npc_team: String = str(hit_npc.get_meta("team"))

		if npc_team == bullet_team:
			return

		if is_target_spawn_immune(hit_npc):
			spawn_hit_particles(hit_position, hit_normal, false)
			return

		var damage: int = NPC_HEADSHOT_DAMAGE if hit_zone == "head" else NPC_BODY_DAMAGE
		var headshot: bool = hit_zone == "head"

		if bool(hit_npc.get_meta("is_final_boss", false)) and bullet_team == "blue":
			damage_final_boss_from_blue_cpu(headshot)
		else:
			damage_npc(hit_npc, damage, headshot)

		spawn_hit_particles(hit_position, hit_normal, true)
		return

	if hit_player != null:
		if bullet_team == "red":
			if is_boss_bullet:
				if not can_final_boss_damage_player():
					return

				start_final_boss_player_damage_cooldown()

			var was_dead: bool = is_player_dead()

			if hit_player.has_method("take_damage"):
				hit_player.call("take_damage", bullet_damage)

			if not was_dead and is_player_dead():
				player_deaths += 1
				red_kills += 1

			spawn_hit_particles(hit_position, hit_normal, true)

		return

	spawn_hit_particles(hit_position, hit_normal, false)

func damage_npc(unit: CharacterBody3D, amount: int, headshot: bool) -> void:
	if not is_valid_target(unit):
		return

	if is_target_spawn_immune(unit):
		return

	var is_boss: bool = bool(unit.get_meta("is_final_boss", false))

	if is_boss:
		var boss_damage: int = FINAL_BOSS_BODY_HIT_DAMAGE

		if headshot:
			boss_damage = FINAL_BOSS_BODY_HIT_DAMAGE * FINAL_BOSS_HEADSHOT_MULTIPLIER

		boss_damage = clamp(boss_damage, 1, FINAL_BOSS_MAX_DAMAGE_PER_PLAYER_HIT)

		final_boss_current_hp = max(final_boss_current_hp - boss_damage, 0)
		unit.set_meta("health", final_boss_current_hp)
		unit.set_meta("max_health", FINAL_BOSS_HEALTH)

		if final_boss_current_hp <= 0:
			unit.set_meta("dead", true)
			blue_kills += 1
			player_kills += 1
			match_eliminations += 1

			if headshot:
				player_headshots += 1
				match_headshots += 1

			record_elimination(headshot, false)
			play_unit_sound(unit, "DeathAudio")
		else:
			unit.set_meta("dead", false)
			play_unit_sound(unit, "HurtAudio")

		update_boss_health_ui()
		print("BOSS HIT: -", boss_damage, " HP. Boss HP left: ", final_boss_current_hp)
		return

	var health: int = int(unit.get_meta("health"))
	health -= amount
	unit.set_meta("health", health)

	if health <= 0:
		var dead_team: String = str(unit.get_meta("team"))

		if dead_team == "red":
			# Blue CPUs killed a red CPU. This is NOT a player kill.
			blue_kills += 1
		elif dead_team == "blue":
			red_kills += 1

		play_unit_sound(unit, "DeathAudio")
		handle_unit_objective_death(unit)
		unit.set_meta("dead", true)
	else:
		play_unit_sound(unit, "HurtAudio")

func has_combat_line_of_sight(unit: CharacterBody3D, target: Node3D) -> bool:
	if unit == null or target == null:
		return false

	if not is_instance_valid(unit) or not is_instance_valid(target):
		return false

	var start_position: Vector3 = unit.global_position + Vector3(0.0, 1.55, 0.0)
	var target_position: Vector3 = target.global_position + Vector3(0.0, 1.0, 0.0)

	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(start_position, target_position)
	query.exclude = get_line_of_sight_exclude_rids(unit)
	query.collide_with_bodies = true
	query.collide_with_areas = false

	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)

	# If the ray reaches the target point without hitting anything, the shot line is clear.
	# This matters for the player because the camera/vehicle handoff can make the exact collider hard to hit.
	if hit.size() <= 0:
		return true

	var hit_object: Node = hit["collider"] as Node

	if hit_object == target:
		return true

	var hit_npc: CharacterBody3D = find_npc_from_hit_object(hit_object)

	if hit_npc == target:
		return true

	var hit_player: CharacterBody3D = find_player_from_hit_object(hit_object)

	if hit_player == target:
		return true

	var hit_helicopter: Node = find_helicopter_from_hit_object(hit_object)
	if hit_helicopter == target:
		return true

	return false


func get_line_of_sight_exclude_rids(unit: CharacterBody3D) -> Array[RID]:
	var exclude_rids: Array[RID] = []

	if unit != null and is_instance_valid(unit):
		exclude_rids.append(unit.get_rid())

	var team: String = str(unit.get_meta("team"))
	var friendly_pool: Array[CharacterBody3D] = red_units if team == "red" else blue_units

	for friendly in friendly_pool:
		if friendly != null and is_instance_valid(friendly):
			exclude_rids.append(friendly.get_rid())

	if team == "blue" and player != null and is_instance_valid(player):
		exclude_rids.append(player.get_rid())

	return exclude_rids


# ---------------- HIT HELPERS ----------------
func find_npc_from_hit_object(hit_object: Node) -> CharacterBody3D:
	if hit_object == null:
		return null

	var node: Node = hit_object

	while node != null:
		if node is CharacterBody3D and node.is_in_group("BattleNPC"):
			return node as CharacterBody3D

		if node.has_meta("npc_root"):
			var root: Node = node.get_meta("npc_root") as Node
			if root != null and root is CharacterBody3D and is_instance_valid(root):
				return root as CharacterBody3D

		node = node.get_parent()

	return null


func find_helicopter_from_hit_object(hit_object: Node) -> Node:
	if hit_object == null:
		return null

	var node: Node = hit_object
	while node != null:
		if node.is_in_group("Helicopter"):
			return node
		node = node.get_parent()

	return null


func find_player_from_hit_object(hit_object: Node) -> CharacterBody3D:
	if hit_object == null:
		return null

	var node: Node = hit_object

	while node != null:
		if player != null and is_instance_valid(player):
			if node == player and node is CharacterBody3D:
				return node as CharacterBody3D

		if node.is_in_group("Player") and node is CharacterBody3D:
			return node as CharacterBody3D

		node = node.get_parent()

	return null


func get_hit_zone(hit_object: Node) -> String:
	if hit_object == null:
		return "body"

	var node: Node = hit_object

	while node != null:
		if node.has_meta("hit_zone"):
			return str(node.get_meta("hit_zone"))

		node = node.get_parent()

	return "body"


# ---------------- ANIMATION ----------------
func animate_unit(unit: CharacterBody3D, delta: float) -> void:
	var model_root: Node3D = unit.get_node_or_null("Model") as Node3D

	if model_root == null:
		return

	var anim_time: float = get_meta_float(unit, "anim_time", 0.0)
	anim_time += delta
	unit.set_meta("anim_time", anim_time)

	var shoot_timer: float = get_meta_float(unit, "shoot_anim_timer", 0.0)
	shoot_timer = max(shoot_timer - delta, 0.0)
	unit.set_meta("shoot_anim_timer", shoot_timer)

	var speed_2d: float = Vector2(unit.velocity.x, unit.velocity.z).length()
	var moving: bool = speed_2d > 0.20
	var running: bool = speed_2d > NPC_SPEED_MAX * 1.10
	var jumping: bool = not unit.is_on_floor()
	var state: String = str(unit.get_meta("state"))

	var left_leg: Node3D = model_root.get_node_or_null("LeftLegPivot") as Node3D
	var right_leg: Node3D = model_root.get_node_or_null("RightLegPivot") as Node3D
	var left_lower_leg: Node3D = model_root.get_node_or_null("LeftLegPivot/LeftLowerLegPivot") as Node3D
	var right_lower_leg: Node3D = model_root.get_node_or_null("RightLegPivot/RightLowerLegPivot") as Node3D
	var left_arm: Node3D = model_root.get_node_or_null("LeftArmPivot") as Node3D
	var right_arm: Node3D = model_root.get_node_or_null("RightArmPivot") as Node3D
	var chest: Node3D = model_root.get_node_or_null("Chest") as Node3D
	var lower_torso: Node3D = model_root.get_node_or_null("LowerTorso") as Node3D
	var pelvis: Node3D = model_root.get_node_or_null("Pelvis") as Node3D
	var head_mesh: Node3D = model_root.get_node_or_null("HeadMesh") as Node3D
	var hair_cap: Node3D = model_root.get_node_or_null("HairCap") as Node3D
	var goggles: Node3D = model_root.get_node_or_null("Goggles") as Node3D
	var gun_root: Node3D = model_root.get_node_or_null("RightArmPivot/RightHand/GunRoot") as Node3D
	var emitter: Node3D = model_root.get_node_or_null("RightArmPivot/RightHand/GunRoot/LaserEmitter") as Node3D

	var cycle_speed: float = 11.5 if running else 7.3
	var stride: float = 39.0 if running else 24.0
	var knee_bend: float = 32.0 if running else 18.0
	var bob_strength: float = 0.055 if running else 0.030
	var walk_a: float = sin(anim_time * cycle_speed)
	var walk_b: float = sin(anim_time * cycle_speed + PI)
	var idle_breath: float = sin(anim_time * 2.0) * 0.014
	var bob: float = abs(sin(anim_time * cycle_speed)) * bob_strength if moving else idle_breath
	var shoot_kick: float = shoot_timer / 0.18 if shoot_timer > 0.0 else 0.0

	# Jump pose overrides walking/running: legs tuck, arms brace, tagger stays forward.
	if jumping:
		if left_leg:
			left_leg.rotation_degrees.x = -18.0
			left_leg.rotation_degrees.z = -4.0
		if right_leg:
			right_leg.rotation_degrees.x = 20.0
			right_leg.rotation_degrees.z = 4.0
		if left_lower_leg:
			left_lower_leg.rotation_degrees.x = 28.0
		if right_lower_leg:
			right_lower_leg.rotation_degrees.x = 18.0
	else:
		if left_leg:
			left_leg.rotation_degrees.x = walk_a * stride if moving else 0.0
			left_leg.rotation_degrees.z = -2.0 if running else 0.0
		if right_leg:
			right_leg.rotation_degrees.x = walk_b * stride if moving else 0.0
			right_leg.rotation_degrees.z = 2.0 if running else 0.0
		if left_lower_leg:
			left_lower_leg.rotation_degrees.x = max(0.0, -walk_a) * knee_bend if moving else 0.0
		if right_lower_leg:
			right_lower_leg.rotation_degrees.x = max(0.0, -walk_b) * knee_bend if moving else 0.0

	# Arms: walking swings, running pumps, shooting snaps both arms forward.
	if left_arm:
		if shoot_timer > 0.0 or state == "suppress":
			left_arm.rotation_degrees.x = -54.0 - shoot_kick * 7.0
			left_arm.rotation_degrees.y = -10.0
			left_arm.rotation_degrees.z = -16.0
		elif jumping:
			left_arm.rotation_degrees.x = -26.0
			left_arm.rotation_degrees.y = 0.0
			left_arm.rotation_degrees.z = -18.0
		else:
			left_arm.rotation_degrees.x = -28.0 + (walk_b * (16.0 if running else 7.0) if moving else sin(anim_time * 1.4) * 2.0)
			left_arm.rotation_degrees.y = 0.0
			left_arm.rotation_degrees.z = -10.0

	if right_arm:
		if shoot_timer > 0.0 or state == "suppress":
			right_arm.rotation_degrees.x = -58.0 - shoot_kick * 10.0
			right_arm.rotation_degrees.y = 8.0
			right_arm.rotation_degrees.z = 12.0
		elif jumping:
			right_arm.rotation_degrees.x = -32.0
			right_arm.rotation_degrees.y = 0.0
			right_arm.rotation_degrees.z = 14.0
		else:
			right_arm.rotation_degrees.x = -30.0 + (walk_a * (13.0 if running else 5.0) if moving else sin(anim_time * 1.6) * 2.0)
			right_arm.rotation_degrees.y = 0.0
			right_arm.rotation_degrees.z = 9.0

	if chest:
		chest.position.y = 1.62 + bob
		chest.rotation_degrees.z = sin(anim_time * cycle_speed) * (3.2 if running else 1.7) if moving and not jumping else 0.0
		chest.rotation_degrees.x = -4.0 if running else 0.0
	if lower_torso:
		lower_torso.position.y = 1.28 + bob * 0.65
	if pelvis:
		pelvis.position.y = 0.86 + bob * 0.45
		pelvis.rotation_degrees.z = -sin(anim_time * cycle_speed) * 2.0 if moving and not jumping else 0.0

	if head_mesh:
		head_mesh.rotation_degrees.y = sin(anim_time * 1.35) * 4.0
		head_mesh.rotation_degrees.x = -3.0 if running else 0.0
	if hair_cap:
		hair_cap.rotation_degrees = head_mesh.rotation_degrees if head_mesh else Vector3.ZERO
	if goggles:
		goggles.rotation_degrees = head_mesh.rotation_degrees if head_mesh else Vector3.ZERO

	if gun_root:
		if state == "reload":
			gun_root.rotation_degrees.x = 38.0
			gun_root.rotation_degrees.z = sin(anim_time * 18.0) * 5.0
		elif shoot_timer > 0.0:
			gun_root.rotation_degrees.x = -13.0 + shoot_kick * 7.0
			gun_root.rotation_degrees.z = sin(anim_time * 30.0) * 1.2
		elif state == "suppress":
			gun_root.rotation_degrees.x = -10.0 + sin(anim_time * 5.0) * 1.2
			gun_root.rotation_degrees.z = sin(anim_time * 3.0) * 1.0
		else:
			gun_root.rotation_degrees.x = -8.0 + sin(anim_time * 2.0) * 1.0
			gun_root.rotation_degrees.z = 0.0

	if emitter:
		emitter.scale = Vector3.ONE * (1.35 if shoot_timer > 0.0 else 1.0)

func update_health_bar(unit: CharacterBody3D) -> void:
	# NPC floating labels are intentionally disabled.
	# Keep this function so the rest of the enemy manager can still call it safely.
	var label: Label3D = unit.get_node_or_null("HealthBar") as Label3D
	if label != null:
		label.visible = false
		label.text = ""
	return


func remove_unit(unit: CharacterBody3D) -> void:
	if unit == null or not is_instance_valid(unit):
		return

	spawn_death_particles(unit.global_position + Vector3(0.0, 1.2, 0.0))

	unit.visible = false
	unit.collision_layer = 0
	unit.collision_mask = 0

	for child in unit.get_children():
		if child is CollisionShape3D:
			var shape: CollisionShape3D = child as CollisionShape3D
			shape.disabled = true
		elif child is Area3D:
			var area: Area3D = child as Area3D
			area.collision_layer = 0
			area.collision_mask = 0

	unit.call_deferred("queue_free")


# ---------------- PARTICLES ----------------
func spawn_muzzle_flash(position: Vector3, direction: Vector3) -> void:
	if LASER_TAG_MODE:
		return

	var particles: GPUParticles3D = GPUParticles3D.new()
	particles.name = "MuzzleFlash"
	particles.amount = 8
	particles.lifetime = 0.08
	particles.one_shot = true
	particles.emitting = true
	particles.local_coords = false

	var material: ParticleProcessMaterial = ParticleProcessMaterial.new()
	material.direction = direction.normalized()
	material.spread = 25.0
	material.initial_velocity_min = 2.0
	material.initial_velocity_max = 5.0
	material.gravity = Vector3.ZERO
	material.scale_min = 0.04
	material.scale_max = 0.1
	material.color = Color(1.0, 0.42, 0.08, 1.0)
	particles.process_material = material

	var mesh: SphereMesh = SphereMesh.new()
	mesh.radius = 0.045
	mesh.height = 0.09
	particles.draw_pass_1 = mesh

	get_tree().current_scene.add_child(particles)
	particles.global_position = position

	await get_tree().create_timer(0.2).timeout

	if is_instance_valid(particles):
		particles.queue_free()


func spawn_hit_particles(position: Vector3, normal: Vector3, flesh_hit: bool) -> void:
	if LASER_TAG_MODE:
		return

	var particles: GPUParticles3D = GPUParticles3D.new()
	particles.name = "HitParticles"
	particles.amount = 32
	particles.lifetime = 0.3
	particles.one_shot = true
	particles.emitting = true
	particles.local_coords = false

	var material: ParticleProcessMaterial = ParticleProcessMaterial.new()
	material.direction = normal.normalized()
	material.spread = 70.0
	material.initial_velocity_min = 2.0
	material.initial_velocity_max = 8.0
	material.gravity = Vector3(0.0, -7.5, 0.0)
	material.scale_min = 0.035
	material.scale_max = 0.085
	material.color = Color(0.65, 0.02, 0.02, 1.0) if flesh_hit else Color(0.62, 0.55, 0.42, 1.0)
	particles.process_material = material

	var mesh: SphereMesh = SphereMesh.new()
	mesh.radius = 0.04
	mesh.height = 0.08
	particles.draw_pass_1 = mesh

	get_tree().current_scene.add_child(particles)
	particles.global_position = position

	await get_tree().create_timer(0.6).timeout

	if is_instance_valid(particles):
		particles.queue_free()


func spawn_death_particles(position: Vector3) -> void:
	if LASER_TAG_MODE:
		return

	var particles: GPUParticles3D = GPUParticles3D.new()
	particles.name = "DeathDust"
	particles.amount = 28
	particles.lifetime = 0.45
	particles.one_shot = true
	particles.emitting = true
	particles.local_coords = false

	var material: ParticleProcessMaterial = ParticleProcessMaterial.new()
	material.direction = Vector3.UP
	material.spread = 160.0
	material.initial_velocity_min = 2.0
	material.initial_velocity_max = 5.0
	material.gravity = Vector3(0.0, -8.0, 0.0)
	material.scale_min = 0.045
	material.scale_max = 0.11
	material.color = Color(0.35, 0.28, 0.22, 1.0)
	particles.process_material = material

	var mesh: SphereMesh = SphereMesh.new()
	mesh.radius = 0.05
	mesh.height = 0.1
	particles.draw_pass_1 = mesh

	get_tree().current_scene.add_child(particles)
	particles.global_position = position

	await get_tree().create_timer(0.8).timeout

	if is_instance_valid(particles):
		particles.queue_free()


# ---------------- MATERIAL / MESH HELPERS ----------------
func get_uniform_color(team: String, index: int) -> Color:
	if team == "blue":
		if index % 3 == 0:
			return Color(0.05, 0.16, 0.45, 1.0)
		elif index % 3 == 1:
			return Color(0.08, 0.22, 0.55, 1.0)
		return Color(0.04, 0.12, 0.32, 1.0)

	if index % 3 == 0:
		return Color(0.45, 0.05, 0.04, 1.0)
	elif index % 3 == 1:
		return Color(0.55, 0.08, 0.06, 1.0)

	return Color(0.32, 0.04, 0.04, 1.0)



func create_sphere_mesh(mesh_name: String, scale_value: Vector3, position: Vector3, material: Material) -> MeshInstance3D:
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	mesh_instance.name = mesh_name

	var sphere: SphereMesh = SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0

	mesh_instance.mesh = sphere
	mesh_instance.scale = scale_value
	mesh_instance.position = position
	mesh_instance.material_override = material

	if material is StandardMaterial3D:
		var std_material: StandardMaterial3D = material as StandardMaterial3D
		mesh_instance.set_meta("base_color", std_material.albedo_color)

	return mesh_instance

func make_material(color: Color, emission_amount: float) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.85
	material.metallic = 0.0

	if emission_amount > 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = emission_amount

	return material


func create_box_mesh(mesh_name: String, size: Vector3, position: Vector3, material: Material) -> MeshInstance3D:
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	mesh_instance.name = mesh_name

	var box: BoxMesh = BoxMesh.new()
	box.size = size

	mesh_instance.mesh = box
	mesh_instance.position = position
	mesh_instance.material_override = material

	if material is StandardMaterial3D:
		var std_material: StandardMaterial3D = material as StandardMaterial3D
		mesh_instance.set_meta("base_color", std_material.albedo_color)

	return mesh_instance


# ---------------- META HELPERS ----------------
func get_meta_float(unit: CharacterBody3D, key: String, fallback: float) -> float:
	if unit == null:
		return fallback

	if not unit.has_meta(key):
		return fallback

	return float(unit.get_meta(key))


func get_meta_vector3(node: Node, key: String, fallback: Vector3 = Vector3.ZERO) -> Vector3:
	if node == null:
		return fallback

	if not node.has_meta(key):
		return fallback

	var value: Variant = node.get_meta(key)

	if value is Vector3:
		return value

	if value is Vector2:
		var v2: Vector2 = value
		return Vector3(v2.x, fallback.y, v2.y)

	if value is Array:
		var arr: Array = value
		if arr.size() >= 3:
			return Vector3(float(arr[0]), float(arr[1]), float(arr[2]))

	if value is Dictionary:
		var dict: Dictionary = value
		if dict.has("x") and dict.has("y") and dict.has("z"):
			return Vector3(float(dict["x"]), float(dict["y"]), float(dict["z"]))

	node.set_meta(key, fallback)
	return fallback

func update_shop_input(_delta: float) -> void:
	var key_down: bool = Input.is_physical_key_pressed(SHOP_TOGGLE_KEY)

	if key_down and not key_was_down:
		if can_open_shop():
			toggle_shop()
		else:
			show_status("Shop opens from the main menu after a match.")

	key_was_down = key_down

	if shop_open and confirm_panel != null and confirm_panel.visible:
		if Input.is_physical_key_pressed(CONFIRM_YES_KEY):
			confirm_purchase_yes()
		elif Input.is_physical_key_pressed(CONFIRM_NO_KEY):
			confirm_purchase_no()

	if shop_open:
		update_shop_text()
# ---------------- PUBLIC API ----------------
func record_elimination(headshot: bool, from_helicopter: bool = false) -> void:
	var reward: int = get_player_elimination_money_reward(headshot, from_helicopter)

	lifetime_eliminations += 1

	if headshot:
		lifetime_headshots += 1

	if selected_game_mode == GAME_MODE_ELIMINATION:
		lifetime_team_elimination_eliminations += 1
	elif selected_game_mode == GAME_MODE_CTF:
		lifetime_ctf_eliminations += 1
	elif selected_game_mode == GAME_MODE_COMMANDER:
		lifetime_commander_eliminations += 1
	elif selected_game_mode == GAME_MODE_KING_HILL:
		lifetime_hill_eliminations += 1

	update_lifetime_elimination_achievements()

	if reward > 0:
		money += reward
		lifetime_money_earned += reward
		save_shop_data()
		show_status("Earned $" + str(reward) + " from " + get_game_mode_display_name(selected_game_mode) + ".")
		update_shop_text()
	else:
		save_shop_data_only()

func open_shop() -> void:
	reveal_shop_achievements()
	check_shop_achievements()
	if not can_open_shop():
		show_status("Shop opens from the main menu after a match.")
		return

	shop_open = true
	if shop_root != null:
		shop_root.visible = true

	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	update_shop_text()


func close_shop() -> void:
	shop_open = false
	pending_upgrade_id = ""

	if confirm_panel != null:
		confirm_panel.visible = false

	if shop_root != null:
		shop_root.visible = false

	


func toggle_shop() -> void:
	if shop_open:
		close_shop()
	else:
		open_shop()


func can_open_shop() -> bool:
	if game_started:
		return false

	if game_over:
		return true

	return shop_allowed_from_main_menu


func apply_all_upgrades() -> void:
	apply_player_upgrades()
	apply_helicopter_upgrades()
	apply_battle_manager_upgrades()


func get_upgrade_level(upgrade_id: String) -> int:
	if not upgrade_levels.has(upgrade_id):
		return 0

	return int(upgrade_levels[upgrade_id])


func get_upgrade_cost(upgrade_id: String) -> int:
	if not upgrade_data.has(upgrade_id):
		return 999999

	var level: int = get_upgrade_level(upgrade_id)
	var max_level: int = int(upgrade_data[upgrade_id]["max_level"])

	if level >= max_level:
		return -1

	var base_cost: int = int(upgrade_data[upgrade_id]["base_cost"])
	var cost_step: int = int(upgrade_data[upgrade_id]["cost_step"])
	return base_cost + level * cost_step


# ---------------- UI BUILD ----------------
func build_shop_ui() -> void:
	if shop_ui_layer == null:
		shop_ui_layer = CanvasLayer.new()
		shop_ui_layer.name = "IntegratedShopLayer"
		shop_ui_layer.layer = 950
		add_child(shop_ui_layer)

	shop_root = Control.new()
	shop_root.name = "OfficialShopRoot"
	shop_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	shop_root.visible = false
	shop_root.mouse_filter = Control.MOUSE_FILTER_STOP
	shop_ui_layer.add_child(shop_root)

	dim_background = ColorRect.new()
	dim_background.name = "ShopDimBackground"
	dim_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim_background.color = Color(0.0, 0.0, 0.0, 0.72)
	shop_root.add_child(dim_background)

	main_panel = PanelContainer.new()
	main_panel.name = "ShopMainPanel"
	main_panel.anchor_left = 0.18
	main_panel.anchor_right = 0.82
	main_panel.anchor_top = 0.08
	main_panel.anchor_bottom = 0.92
	main_panel.offset_left = 0.0
	main_panel.offset_right = 0.0
	main_panel.offset_top = 0.0
	main_panel.offset_bottom = 0.0
	main_panel.add_theme_stylebox_override("panel", make_panel_style(Color(0.018, 0.026, 0.045, 0.96), Color(0.20, 0.72, 1.0, 0.95), 3))
	shop_root.add_child(main_panel)

	var outer_margin: MarginContainer = MarginContainer.new()
	outer_margin.add_theme_constant_override("margin_left", 24)
	outer_margin.add_theme_constant_override("margin_right", 24)
	outer_margin.add_theme_constant_override("margin_top", 20)
	outer_margin.add_theme_constant_override("margin_bottom", 20)
	main_panel.add_child(outer_margin)

	var outer_box: VBoxContainer = VBoxContainer.new()
	outer_box.add_theme_constant_override("separation", 8)
	outer_margin.add_child(outer_box)

	var title: Label = Label.new()
	title.text = "TACTICAL UPGRADE SHOP"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color(0.85, 0.96, 1.0, 1.0))
	outer_box.add_child(title)

	var subtitle: Label = Label.new()
	subtitle.text = "Earn money during matches. Buy upgrades from the main menu."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", Color(0.70, 0.86, 0.95, 1.0))
	outer_box.add_child(subtitle)

	money_label = Label.new()
	money_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	money_label.add_theme_font_size_override("font_size", 28)
	money_label.add_theme_color_override("font_color", Color(0.25, 1.0, 0.45, 1.0))
	outer_box.add_child(money_label)

	var content_row: HBoxContainer = HBoxContainer.new()
	content_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_row.add_theme_constant_override("separation", 16)
	outer_box.add_child(content_row)

	var left_panel: PanelContainer = PanelContainer.new()
	left_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_panel.add_theme_stylebox_override("panel", make_panel_style(Color(0.02, 0.04, 0.07, 0.88), Color(0.10, 0.35, 0.55, 0.80), 2))
	content_row.add_child(left_panel)

	var left_margin: MarginContainer = MarginContainer.new()
	left_margin.add_theme_constant_override("margin_left", 12)
	left_margin.add_theme_constant_override("margin_right", 12)
	left_margin.add_theme_constant_override("margin_top", 12)
	left_margin.add_theme_constant_override("margin_bottom", 12)
	left_panel.add_child(left_margin)

	var button_box: VBoxContainer = VBoxContainer.new()
	button_box.add_theme_constant_override("separation", 8)
	left_margin.add_child(button_box)

	add_upgrade_button(button_box, "sprint")
	add_upgrade_button(button_box, "stamina")
	add_upgrade_button(button_box, "stamina_regen")
	add_upgrade_button(button_box, "health")
	add_upgrade_button(button_box, "hcop_fuel")
	add_upgrade_button(button_box, "fire_rate")
	add_upgrade_button(button_box, "reload_speed")
	add_upgrade_button(button_box, "ammo_capacity")

	var right_panel: PanelContainer = PanelContainer.new()
	right_panel.custom_minimum_size = Vector2(300.0, 0.0)
	right_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_panel.add_theme_stylebox_override("panel", make_panel_style(Color(0.015, 0.023, 0.040, 0.90), Color(0.18, 0.55, 0.85, 0.75), 2))
	content_row.add_child(right_panel)

	var right_margin: MarginContainer = MarginContainer.new()
	right_margin.add_theme_constant_override("margin_left", 14)
	right_margin.add_theme_constant_override("margin_right", 14)
	right_margin.add_theme_constant_override("margin_top", 14)
	right_margin.add_theme_constant_override("margin_bottom", 14)
	right_panel.add_child(right_margin)

	detail_label = Label.new()
	detail_label.text = "Select an upgrade to inspect it."
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	detail_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_label.add_theme_font_size_override("font_size", 18)
	detail_label.add_theme_color_override("font_color", Color(0.90, 0.95, 1.0, 1.0))
	right_margin.add_child(detail_label)

	status_label = Label.new()
	status_label.text = ""
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 16)
	status_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.35, 1.0))
	outer_box.add_child(status_label)

	var bottom_row: HBoxContainer = HBoxContainer.new()
	bottom_row.add_theme_constant_override("separation", 10)
	outer_box.add_child(bottom_row)

	save_button = Button.new()
	save_button.text = "SAVE PROGRESS"
	save_button.custom_minimum_size = Vector2(0.0, 34.0)
	save_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save_button.add_theme_font_size_override("font_size", 18)
	wire_button_sounds(save_button)
	save_button.pressed.connect(save_progress_from_shop)
	bottom_row.add_child(save_button)

	reset_progress_button = Button.new()
	reset_progress_button.text = "RESET PROGRESS"
	reset_progress_button.custom_minimum_size = Vector2(0.0, 34.0)
	reset_progress_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reset_progress_button.add_theme_font_size_override("font_size", 18)
	wire_button_sounds(reset_progress_button)
	reset_progress_button.pressed.connect(request_reset_progress)
	bottom_row.add_child(reset_progress_button)

	close_button = Button.new()
	close_button.text = "CLOSE SHOP"
	close_button.custom_minimum_size = Vector2(0.0, 34.0)
	close_button.add_theme_font_size_override("font_size", 17)
	wire_button_sounds(close_button)
	close_button.pressed.connect(close_shop)
	outer_box.add_child(close_button)

	build_confirm_panel()
	update_shop_text()


func add_upgrade_button(parent: VBoxContainer, upgrade_id: String) -> void:
	var button: Button = Button.new()
	button.custom_minimum_size = Vector2(0.0, 48.0)
	button.add_theme_font_size_override("font_size", 18)
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_entered.connect(func() -> void: show_upgrade_details(upgrade_id))
	button.focus_entered.connect(func() -> void: show_upgrade_details(upgrade_id))
	button.pressed.connect(func() -> void: request_purchase(upgrade_id))
	wire_button_sounds(button)
	parent.add_child(button)
	upgrade_buttons[upgrade_id] = button


func build_confirm_panel() -> void:
	confirm_panel = PanelContainer.new()
	confirm_panel.name = "ConfirmPurchasePanel"
	confirm_panel.anchor_left = 0.5
	confirm_panel.anchor_right = 0.5
	confirm_panel.anchor_top = 0.5
	confirm_panel.anchor_bottom = 0.5
	confirm_panel.offset_left = -250.0
	confirm_panel.offset_right = 250.0
	confirm_panel.offset_top = -140.0
	confirm_panel.offset_bottom = 140.0
	confirm_panel.visible = false
	confirm_panel.z_index = 50
	confirm_panel.add_theme_stylebox_override("panel", make_panel_style(Color(0.03, 0.035, 0.055, 0.98), Color(1.0, 0.78, 0.25, 1.0), 3))
	shop_root.add_child(confirm_panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	confirm_panel.add_child(margin)

	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)

	confirm_title_label = Label.new()
	confirm_title_label.text = "CONFIRM PURCHASE"
	confirm_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	confirm_title_label.add_theme_font_size_override("font_size", 26)
	confirm_title_label.add_theme_color_override("font_color", Color(1.0, 0.90, 0.45, 1.0))
	box.add_child(confirm_title_label)

	confirm_body_label = Label.new()
	confirm_body_label.text = ""
	confirm_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	confirm_body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	confirm_body_label.add_theme_font_size_override("font_size", 17)
	confirm_body_label.add_theme_color_override("font_color", Color(0.95, 0.98, 1.0, 1.0))
	box.add_child(confirm_body_label)

	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)

	confirm_yes_button = Button.new()
	confirm_yes_button.text = "CONFIRM"
	confirm_yes_button.custom_minimum_size = Vector2(210.0, 48.0)
	confirm_yes_button.add_theme_font_size_override("font_size", 18)
	wire_button_sounds(confirm_yes_button)
	confirm_yes_button.pressed.connect(confirm_purchase_yes)
	row.add_child(confirm_yes_button)

	confirm_no_button = Button.new()
	confirm_no_button.text = "CANCEL"
	confirm_no_button.custom_minimum_size = Vector2(210.0, 48.0)
	confirm_no_button.add_theme_font_size_override("font_size", 18)
	wire_button_sounds(confirm_no_button)
	confirm_no_button.pressed.connect(confirm_purchase_no)
	row.add_child(confirm_no_button)


func make_panel_style(bg: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	style.shadow_size = 10
	return style


# ---------------- SAVE / RESET SHOP BUTTONS ----------------
func save_progress_from_shop() -> void:
	save_shop_data()
	show_status("Progress saved.")


func request_reset_progress() -> void:
	pending_upgrade_id = "__RESET_PROGRESS__"
	if confirm_title_label != null:
		confirm_title_label.text = "RESET ALL PROGRESS?"
	if confirm_body_label != null:
		confirm_body_label.text = "This will erase all money, upgrades, eliminations, and headshots. This cannot be undone.\n\nPress ENTER or click CONFIRM to reset."
	if confirm_panel != null:
		confirm_panel.visible = true


func reset_progress_confirmed() -> void:
	money = 0
	lifetime_money_earned = 0
	lifetime_eliminations = 0
	lifetime_headshots = 0
	lifetime_flag_captures = 0
	lifetime_manhunt_survival_ticks = 0
	lifetime_team_elimination_eliminations = 0
	lifetime_ctf_eliminations = 0
	lifetime_commander_eliminations = 0
	lifetime_hill_eliminations = 0
	lifetime_manhunt_hunts_won = 0
	final_boss_reward_power_unlocked = false
	final_boss_finale_quit_started = false

	for key in upgrade_levels.keys():
		upgrade_levels[key] = 0

	pending_upgrade_id = ""
	if confirm_panel != null:
		confirm_panel.visible = false

	for achievement_id in achievement_unlocked.keys():
		achievement_unlocked[achievement_id] = false
		achievement_seen[achievement_id] = false

	boss_mode_unlocked = false

	if player != null and is_instance_valid(player) and player.has_method("disable_final_boss_reward_power_mode"):
		player.call("disable_final_boss_reward_power_mode")

	save_achievement_data()
	save_shop_data()
	apply_all_upgrades()
	update_shop_text()
	show_status("Progress reset. Money, upgrades, achievements, and final boss reward mode are now cleared.")

func setup_achievement_defaults() -> void:
	for achievement_id in achievement_data.keys():
		if not achievement_unlocked.has(achievement_id):
			achievement_unlocked[achievement_id] = false
		if not achievement_seen.has(achievement_id):
			achievement_seen[achievement_id] = false

func reveal_achievement(achievement_id: String) -> void:
	if not achievement_data.has(achievement_id):
		return

	setup_achievement_defaults()

	if bool(achievement_unlocked.get(achievement_id, false)):
		return

	if bool(achievement_seen.get(achievement_id, false)):
		return

	achievement_seen[achievement_id] = true
	save_achievement_data()
	save_shop_data_only()
	update_achievement_page()

func unlock_achievement(achievement_id: String) -> void:
	if not achievement_data.has(achievement_id):
		return

	setup_achievement_defaults()

	achievement_seen[achievement_id] = true

	if bool(achievement_unlocked.get(achievement_id, false)):
		save_achievement_data()
		save_shop_data_only()
		return

	achievement_unlocked[achievement_id] = true
	save_achievement_data()
	save_shop_data_only()
	update_achievement_unlocks()
	show_achievement_notice(str(achievement_data[achievement_id]["title"]))

func update_achievement_unlocks() -> void:
	setup_achievement_defaults()

	if are_all_normal_achievements_unlocked():
		boss_mode_unlocked = true
		achievement_seen["boss_unlocked"] = true
		achievement_unlocked["boss_unlocked"] = true

	update_achievement_page()

func are_all_normal_achievements_unlocked() -> bool:
	for achievement_id in achievement_data.keys():
		if achievement_id == "final_boss" or achievement_id == "boss_unlocked":
			continue

		if not bool(achievement_unlocked.get(achievement_id, false)):
			return false

	return true

func is_final_boss_unlocked() -> bool:
	return boss_mode_unlocked or bool(achievement_unlocked.get("boss_unlocked", false))

func show_achievement_notice(title_text: String) -> void:
	if achievement_notice_label == null:
		create_achievement_notice_label()

	if achievement_notice_label == null:
		print("ACHIEVEMENT UNLOCKED: " + title_text)
		return

	achievement_notice_label.text = "ACHIEVEMENT UNLOCKED\n" + title_text
	achievement_notice_label.visible = true
	achievement_notice_timer = 4.0


func create_achievement_notice_label() -> void:
	if battle_ui_layer == null:
		return

	achievement_notice_label = Label.new()
	achievement_notice_label.name = "AchievementNotice"
	achievement_notice_label.anchor_left = 0.0
	achievement_notice_label.anchor_right = 1.0
	achievement_notice_label.anchor_top = 0.0
	achievement_notice_label.anchor_bottom = 0.0
	achievement_notice_label.offset_top = 82.0
	achievement_notice_label.offset_bottom = 150.0
	achievement_notice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	achievement_notice_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	achievement_notice_label.add_theme_font_size_override("font_size", 24)
	achievement_notice_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.25, 1.0))
	achievement_notice_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	achievement_notice_label.add_theme_constant_override("shadow_offset_x", 3)
	achievement_notice_label.add_theme_constant_override("shadow_offset_y", 3)
	achievement_notice_label.visible = false
	battle_ui_layer.add_child(achievement_notice_label)


func update_achievement_notice(delta: float) -> void:
	if achievement_notice_timer <= 0.0:
		return

	achievement_notice_timer = max(achievement_notice_timer - delta, 0.0)

	if achievement_notice_timer <= 0.0 and achievement_notice_label != null:
		achievement_notice_label.visible = false


func open_achievements_from_title() -> void:
	set_player_ui_visible(false)
	open_achievements_page()


func open_achievements_page() -> void:
	if achievement_panel == null:
		build_achievement_ui()

	if achievement_panel == null:
		return

	update_achievement_page()
	achievement_panel.visible = true
	set_main_menu_controls_visible(false)


func close_achievements_page() -> void:
	if achievement_panel != null:
		achievement_panel.visible = false

	if not game_started:
		set_main_menu_controls_visible(true)


func build_achievement_ui() -> void:
	if title_panel == null:
		return

	achievement_panel = PanelContainer.new()
	achievement_panel.name = "AchievementPanel"
	achievement_panel.anchor_left = 0.12
	achievement_panel.anchor_right = 0.88
	achievement_panel.anchor_top = 0.10
	achievement_panel.anchor_bottom = 0.90
	achievement_panel.offset_left = 0.0
	achievement_panel.offset_right = 0.0
	achievement_panel.offset_top = 0.0
	achievement_panel.offset_bottom = 0.0
	achievement_panel.visible = false
	achievement_panel.z_index = 930
	achievement_panel.add_theme_stylebox_override("panel", make_panel_style(Color(0.010, 0.014, 0.022, 0.98), Color(0.80, 0.68, 0.24, 0.95), 3))
	title_panel.add_child(achievement_panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 22)
	achievement_panel.add_child(margin)

	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	margin.add_child(box)

	var title: Label = Label.new()
	title.text = "ACHIEVEMENTS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35, 1.0))
	box.add_child(title)

	achievement_list_label = Label.new()
	achievement_list_label.text = "Locked achievements hide their mission until you complete them."
	achievement_list_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	achievement_list_label.add_theme_font_size_override("font_size", 18)
	achievement_list_label.add_theme_color_override("font_color", Color(0.80, 0.86, 0.92, 1.0))
	box.add_child(achievement_list_label)

	achievement_scroll = ScrollContainer.new()
	achievement_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	achievement_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(achievement_scroll)

	achievement_grid = GridContainer.new()
	achievement_grid.columns = 2
	achievement_grid.add_theme_constant_override("h_separation", 14)
	achievement_grid.add_theme_constant_override("v_separation", 14)
	achievement_scroll.add_child(achievement_grid)

	achievement_cards.clear()
	setup_achievement_defaults()

	for achievement_id in achievement_data.keys():
		var card: PanelContainer = make_achievement_card(achievement_id)
		achievement_grid.add_child(card)
		achievement_cards[achievement_id] = card

	achievement_close_button = Button.new()
	achievement_close_button.text = "BACK"
	achievement_close_button.custom_minimum_size = Vector2(0.0, 48.0)
	achievement_close_button.add_theme_font_size_override("font_size", 22)
	wire_button_sounds(achievement_close_button)
	achievement_close_button.pressed.connect(close_achievements_page)
	box.add_child(achievement_close_button)


func make_achievement_card(achievement_id: String) -> PanelContainer:
	var card: PanelContainer = PanelContainer.new()
	card.name = "AchievementCard_" + achievement_id
	card.custom_minimum_size = Vector2(620.0, 116.0)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", make_panel_style(Color(0.018, 0.024, 0.035, 0.94), Color(0.20, 0.30, 0.42, 0.75), 2))

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	card.add_child(margin)

	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	margin.add_child(row)

	var icon_panel: PanelContainer = PanelContainer.new()
	icon_panel.name = "IconPanel"
	icon_panel.custom_minimum_size = Vector2(78.0, 78.0)
	icon_panel.add_theme_stylebox_override("panel", make_panel_style(Color(0.04, 0.05, 0.07, 1.0), Color(0.60, 0.60, 0.60, 0.8), 2))
	row.add_child(icon_panel)

	var icon_label: Label = Label.new()
	icon_label.name = "IconLabel"
	icon_label.text = "?"
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_label.add_theme_font_size_override("font_size", 42)
	icon_label.add_theme_color_override("font_color", Color(0.68, 0.72, 0.78, 1.0))
	icon_panel.add_child(icon_label)

	var text_box: VBoxContainer = VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.add_theme_constant_override("separation", 4)
	row.add_child(text_box)

	var title_label: Label = Label.new()
	title_label.name = "TitleLabel"
	title_label.text = "???"
	title_label.add_theme_font_size_override("font_size", 21)
	title_label.add_theme_color_override("font_color", Color(0.92, 0.95, 1.0, 1.0))
	text_box.add_child(title_label)

	var desc_label: Label = Label.new()
	desc_label.name = "DescLabel"
	desc_label.text = "Hidden achievement"
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", 16)
	desc_label.add_theme_color_override("font_color", Color(0.72, 0.78, 0.86, 1.0))
	text_box.add_child(desc_label)

	return card


func get_achievement_icon_text(achievement_id: String) -> String:
	if not achievement_data.has(achievement_id):
		return "?"
	var data: Dictionary = achievement_data[achievement_id]
	return str(data.get("icon", "?"))

func set_achievement_card_state(achievement_id: String, unlocked: bool) -> void:
	if not achievement_cards.has(achievement_id):
		return
	var card: PanelContainer = achievement_cards[achievement_id]
	if card == null:
		return
	var data: Dictionary = achievement_data[achievement_id]
	var seen: bool = bool(achievement_seen.get(achievement_id, false))
	var icon_label: Label = card.find_child("IconLabel", true, false) as Label
	var title_label: Label = card.find_child("TitleLabel", true, false) as Label
	var desc_label: Label = card.find_child("DescLabel", true, false) as Label
	var icon_panel: PanelContainer = card.find_child("IconPanel", true, false) as PanelContainer
	if unlocked:
		card.add_theme_stylebox_override("panel", make_panel_style(Color(0.035,0.030,0.010,0.96), Color(1.0,0.78,0.25,1.0), 2))
		if icon_panel != null: icon_panel.add_theme_stylebox_override("panel", make_panel_style(Color(0.10,0.075,0.015,1.0), Color(1.0,0.86,0.28,1.0), 2))
		if icon_label != null:
			icon_label.text = get_achievement_icon_text(achievement_id)
			icon_label.add_theme_color_override("font_color", Color(1.0,0.88,0.35,1.0))
		if title_label != null:
			title_label.text = str(data["title"])
			title_label.add_theme_color_override("font_color", Color(1.0,0.90,0.38,1.0))
		if desc_label != null:
			desc_label.text = str(data["desc"])
			desc_label.add_theme_color_override("font_color", Color(0.90,0.92,0.82,1.0))
		return
	if seen:
		card.add_theme_stylebox_override("panel", make_panel_style(Color(0.015,0.015,0.018,0.96), Color(0.88,0.88,0.88,0.92), 2))
		if icon_panel != null: icon_panel.add_theme_stylebox_override("panel", make_panel_style(Color(0.0,0.0,0.0,1.0), Color(0.92,0.92,0.92,1.0), 2))
		if icon_label != null:
			icon_label.text = get_achievement_icon_text(achievement_id)
			icon_label.add_theme_color_override("font_color", Color(0.96,0.96,0.96,1.0))
		if title_label != null:
			title_label.text = str(data["title"])
			title_label.add_theme_color_override("font_color", Color(0.96,0.96,0.96,1.0))
		if desc_label != null:
			desc_label.text = str(data["desc"])
			desc_label.add_theme_color_override("font_color", Color(0.78,0.78,0.78,1.0))
		return
	card.add_theme_stylebox_override("panel", make_panel_style(Color(0.018,0.024,0.035,0.94), Color(0.20,0.30,0.42,0.75), 2))
	if icon_panel != null: icon_panel.add_theme_stylebox_override("panel", make_panel_style(Color(0.04,0.05,0.07,1.0), Color(0.42,0.48,0.56,0.8), 2))
	if icon_label != null:
		icon_label.text = "?"
		icon_label.add_theme_color_override("font_color", Color(0.65,0.70,0.78,1.0))
	if bool(data.get("hidden", false)):
		if title_label != null: title_label.text = "???"
		if desc_label != null: desc_label.text = "Hidden achievement"
	else:
		if title_label != null: title_label.text = str(data["title"])
		if desc_label != null: desc_label.text = str(data["desc"])

func update_achievement_page() -> void:
	setup_achievement_defaults()
	var unlocked_count: int = 0
	var total_count: int = achievement_data.size()
	for achievement_id in achievement_data.keys():
		var data: Dictionary = achievement_data[achievement_id]
		var unlocked: bool = bool(achievement_unlocked.get(achievement_id, false))
		var super_hidden: bool = bool(data.get("super_hidden", false))
		if unlocked: unlocked_count += 1
		if super_hidden and not is_final_boss_unlocked() and not unlocked:
			if achievement_cards.has(achievement_id):
				var hidden_card: Control = achievement_cards[achievement_id]
				if hidden_card != null: hidden_card.visible = false
			continue
		if achievement_cards.has(achievement_id):
			var card: Control = achievement_cards[achievement_id]
			if card != null: card.visible = true
		set_achievement_card_state(achievement_id, unlocked)
	if achievement_list_label != null:
		var boss_text: String = ""
		if is_final_boss_unlocked() and not bool(achievement_unlocked.get("final_boss", false)):
			boss_text = "  |  FINAL SHOWDOWN UNLOCKED"
		achievement_list_label.text = "Unlocked: " + str(unlocked_count) + "/" + str(total_count) + boss_text

func save_achievement_data() -> void:
	setup_achievement_defaults()

	var data: Dictionary = {
		"achievement_unlocked": achievement_unlocked,
		"achievement_seen": achievement_seen,
		"boss_mode_unlocked": boss_mode_unlocked
	}

	var file: FileAccess = FileAccess.open(ACHIEVEMENT_SAVE_PATH, FileAccess.WRITE)

	if file == null:
		print("Could not save achievement data.")
		return

	file.store_string(JSON.stringify(data))
	file.close()

func load_achievement_data() -> void:
	setup_achievement_defaults()
	if not FileAccess.file_exists(ACHIEVEMENT_SAVE_PATH):
		update_achievement_unlocks()
		return
	var file: FileAccess = FileAccess.open(ACHIEVEMENT_SAVE_PATH, FileAccess.READ)
	if file == null:
		update_achievement_unlocks()
		return
	var text: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if parsed == null or not parsed is Dictionary:
		update_achievement_unlocks()
		return
	var data: Dictionary = parsed as Dictionary
	if data.has("achievement_unlocked") and data["achievement_unlocked"] is Dictionary:
		var loaded: Dictionary = data["achievement_unlocked"]
		for achievement_id in achievement_data.keys():
			if loaded.has(achievement_id):
				achievement_unlocked[achievement_id] = bool(loaded[achievement_id])
	if data.has("achievement_seen") and data["achievement_seen"] is Dictionary:
		var loaded_seen: Dictionary = data["achievement_seen"]
		for achievement_id in achievement_data.keys():
			if loaded_seen.has(achievement_id):
				achievement_seen[achievement_id] = bool(loaded_seen[achievement_id])
	if data.has("boss_mode_unlocked"):
		boss_mode_unlocked = bool(data["boss_mode_unlocked"])
	update_achievement_unlocks()

	save_shop_data_only()

func request_purchase(upgrade_id: String) -> void:
	if not upgrade_data.has(upgrade_id):
		return

	show_upgrade_details(upgrade_id)

	var level: int = get_upgrade_level(upgrade_id)
	var max_level: int = int(upgrade_data[upgrade_id]["max_level"])
	var cost: int = get_upgrade_cost(upgrade_id)

	if level >= max_level:
		show_status(str(upgrade_data[upgrade_id]["title"]) + " is already max level.")
		return

	if money < cost:
		show_status("Not enough money. Need $" + str(cost) + ".")
		return

	pending_upgrade_id = upgrade_id

	confirm_title_label.text = "CONFIRM PURCHASE"
	confirm_body_label.text = (
		"Buy " + str(upgrade_data[upgrade_id]["title"]) +
		"\nLevel " + str(level) + " -> " + str(level + 1) +
		"\nCost: $" + str(cost) +
		"\n\nPress ENTER or click CONFIRM."
	)
	confirm_panel.visible = true


func confirm_purchase_yes() -> void:
	if pending_upgrade_id == "":
		return

	if pending_upgrade_id == "__RESET_PROGRESS__":
		reset_progress_confirmed()
		return

	var upgrade_id: String = pending_upgrade_id
	var cost: int = get_upgrade_cost(upgrade_id)

	if cost < 0:
		confirm_purchase_no()
		return

	if money < cost:
		show_status("Not enough money.")
		confirm_purchase_no()
		return

	money -= cost
	upgrade_levels[upgrade_id] = get_upgrade_level(upgrade_id) + 1

	save_shop_data()
	apply_all_upgrades()
	show_status("Purchased " + str(upgrade_data[upgrade_id]["title"]) + " level " + str(get_upgrade_level(upgrade_id)) + ".")

	pending_upgrade_id = ""
	confirm_panel.visible = false
	update_shop_text()


func confirm_purchase_no() -> void:
	pending_upgrade_id = ""

	if confirm_panel != null:
		confirm_panel.visible = false


func show_upgrade_details(upgrade_id: String) -> void:
	if not upgrade_data.has(upgrade_id):
		return

	var level: int = get_upgrade_level(upgrade_id)
	var max_level: int = int(upgrade_data[upgrade_id]["max_level"])
	var cost: int = get_upgrade_cost(upgrade_id)

	var cost_text: String = "MAXED"
	if cost >= 0:
		cost_text = "$" + str(cost)

	detail_label.text = (
		str(upgrade_data[upgrade_id]["title"]) +
		"\n\n" + str(upgrade_data[upgrade_id]["short"]) +
		"\n\nEffect:\n" + str(upgrade_data[upgrade_id]["effect"]) +
		"\n\nCurrent Level: " + str(level) + "/" + str(max_level) +
		"\nNext Cost: " + cost_text +
		"\n\nMoney: $" + str(money)
	)


func update_shop_text() -> void:
	if money_label != null:
		money_label.text = "AVAILABLE FUNDS: $" + str(money)

	for upgrade_id in upgrade_buttons.keys():
		var button: Button = upgrade_buttons[upgrade_id]
		var level: int = get_upgrade_level(upgrade_id)
		var max_level: int = int(upgrade_data[upgrade_id]["max_level"])
		var cost: int = get_upgrade_cost(upgrade_id)

		var cost_text: String = "MAX"
		if cost >= 0:
			cost_text = "$" + str(cost)

		button.text = (
			str(upgrade_data[upgrade_id]["title"]) +
			"  |  LVL " + str(level) + "/" + str(max_level) +
			"  |  " + cost_text
		)

		button.disabled = level >= max_level


func show_status(text: String) -> void:
	if status_label != null:
		status_label.text = text
	else:
		print(text)


# ---------------- APPLY UPGRADES ----------------
func apply_player_upgrades() -> void:
	if player == null or not is_instance_valid(player):
		find_player()

	if player == null:
		return

	if player.has_method("apply_economy_upgrades"):
		player.call(
			"apply_economy_upgrades",
			get_upgrade_level("sprint"),
			get_upgrade_level("stamina"),
			get_upgrade_level("stamina_regen"),
			get_upgrade_level("health"),
			get_upgrade_level("fire_rate"),
			SPRINT_BONUS_PER_LEVEL,
			STAMINA_BONUS_PER_LEVEL,
			STAMINA_REGEN_BONUS_PER_LEVEL,
			HEALTH_BONUS_PER_LEVEL,
			PLAYER_FIRE_COOLDOWN_BASE,
			PLAYER_FIRE_COOLDOWN_REDUCTION_PER_LEVEL,
			PLAYER_FIRE_COOLDOWN_MIN
		)

	if player.has_method("set_reload_upgrade"):
		player.call(
			"set_reload_upgrade",
			get_upgrade_level("reload_speed"),
			PLAYER_RELOAD_TIME_BASE,
			PLAYER_RELOAD_TIME_REDUCTION_PER_LEVEL,
			PLAYER_RELOAD_TIME_MIN
		)

	if player.has_method("set_ammo_upgrade"):
		player.call(
			"set_ammo_upgrade",
			get_upgrade_level("ammo_capacity"),
			PLAYER_AMMO_BASE,
			PLAYER_AMMO_PER_LEVEL
		)


	if final_boss_reward_power_unlocked and player != null and is_instance_valid(player) and player.has_method("enable_final_boss_reward_power_mode"):
		player.call("enable_final_boss_reward_power_mode")

func apply_helicopter_upgrades() -> void:
	var helicopters: Array[Node] = get_tree().get_nodes_in_group("Helicopter")

	for heli in helicopters:
		if heli != null and heli.has_method("apply_economy_upgrades"):
			heli.call(
				"apply_economy_upgrades",
				get_upgrade_level("hcop_fuel"),
				HCOP_FUEL_BONUS_SECONDS_PER_LEVEL
			)


func apply_battle_manager_upgrades() -> void:
	# Recon boost was removed. Keep this function so old calls stay safe.
	pass



func object_has_property(obj: Object, property_name: String) -> bool:
	if obj == null:
		return false

	for property_info in obj.get_property_list():
		if property_info.has("name") and property_info["name"] == property_name:
			return true

	return false


# ---------------- SAVE / LOAD ----------------
func save_shop_data() -> void:
	save_shop_data_only()
	save_achievement_data()

func load_shop_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)

	if file == null:
		return

	var text: String = file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(text)

	if parsed == null or not parsed is Dictionary:
		return

	var data: Dictionary = parsed as Dictionary

	if data.has("money"):
		money = int(data["money"])

	if data.has("lifetime_money_earned"):
		lifetime_money_earned = int(data["lifetime_money_earned"])

	if data.has("lifetime_eliminations"):
		lifetime_eliminations = int(data["lifetime_eliminations"])

	if data.has("lifetime_headshots"):
		lifetime_headshots = int(data["lifetime_headshots"])

	if data.has("lifetime_flag_captures"):
		lifetime_flag_captures = int(data["lifetime_flag_captures"])

	if data.has("lifetime_manhunt_survival_ticks"):
		lifetime_manhunt_survival_ticks = int(data["lifetime_manhunt_survival_ticks"])

	if data.has("lifetime_team_elimination_eliminations"):
		lifetime_team_elimination_eliminations = int(data["lifetime_team_elimination_eliminations"])

	if data.has("lifetime_ctf_eliminations"):
		lifetime_ctf_eliminations = int(data["lifetime_ctf_eliminations"])

	if data.has("lifetime_commander_eliminations"):
		lifetime_commander_eliminations = int(data["lifetime_commander_eliminations"])

	if data.has("lifetime_hill_eliminations"):
		lifetime_hill_eliminations = int(data["lifetime_hill_eliminations"])

	if data.has("lifetime_manhunt_hunts_won"):
		lifetime_manhunt_hunts_won = int(data["lifetime_manhunt_hunts_won"])

	if data.has("upgrade_levels") and data["upgrade_levels"] is Dictionary:
		var loaded_levels: Dictionary = data["upgrade_levels"]
		for key in upgrade_levels.keys():
			if loaded_levels.has(key):
				upgrade_levels[key] = int(loaded_levels[key])


	if data.has("final_boss_reward_power_unlocked"):
		final_boss_reward_power_unlocked = bool(data["final_boss_reward_power_unlocked"])

	if data.has(FINAL_BOSS_COMPLETION_SAVE_KEY):
		final_boss_reward_power_unlocked = bool(data[FINAL_BOSS_COMPLETION_SAVE_KEY])

	setup_achievement_defaults()

	if data.has("achievement_unlocked") and data["achievement_unlocked"] is Dictionary:
		var loaded_unlocked: Dictionary = data["achievement_unlocked"]
		for achievement_id in achievement_data.keys():
			if loaded_unlocked.has(achievement_id):
				achievement_unlocked[achievement_id] = bool(loaded_unlocked[achievement_id])

	if data.has("achievement_seen") and data["achievement_seen"] is Dictionary:
		var loaded_seen: Dictionary = data["achievement_seen"]
		for achievement_id in achievement_data.keys():
			if loaded_seen.has(achievement_id):
				achievement_seen[achievement_id] = bool(loaded_seen[achievement_id])

	if data.has("boss_mode_unlocked"):
		boss_mode_unlocked = bool(data["boss_mode_unlocked"])

func update_supply_crates(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return

	var crates: Array[Node] = get_tree().get_nodes_in_group("SupplyCrate")

	for crate in crates:
		if crate == null or not is_instance_valid(crate):
			continue
		if not crate is Node3D:
			continue

		var crate_node: Node3D = crate as Node3D
		var crate_id: String = str(crate_node.get_instance_id())

		if supply_crate_respawn_timers.has(crate_id):
			var remaining: float = float(supply_crate_respawn_timers[crate_id]) - delta
			if remaining <= 0.0:
				supply_crate_respawn_timers.erase(crate_id)
				set_supply_crate_visible(crate_node, true)
			else:
				supply_crate_respawn_timers[crate_id] = remaining
			continue

		if not crate_node.visible:
			continue

		var distance_to_player: float = crate_node.global_position.distance_to(player.global_position)
		if distance_to_player <= SUPPLY_CRATE_PICKUP_DISTANCE:
			pickup_supply_crate(crate_node)


func pickup_supply_crate(crate_node: Node3D) -> void:
	var crate_type: String = "health"

	if crate_node.has_meta("crate_type"):
		crate_type = str(crate_node.get_meta("crate_type"))
	elif crate_node.has_meta("type"):
		crate_type = str(crate_node.get_meta("type"))

	match crate_type:
		"health":
			give_supply_health()
		"ammo":
			give_supply_ammo()
		"stamina":
			give_supply_stamina()
		"fuel":
			give_supply_fuel(crate_node.global_position)
		"radar":
			# Recon has been removed. Old radar crates now give money instead of map ping.
			money += 100
			save_shop_data()
			show_status("Supply crate: +$100")
		"money":
			money += 150
			save_shop_data()
			show_status("Supply crate: +$150")
		_:
			give_supply_health()

	set_supply_crate_visible(crate_node, false)
	supply_crate_respawn_timers[str(crate_node.get_instance_id())] = SUPPLY_CRATE_RESPAWN_SECONDS


func set_supply_crate_visible(crate_node: Node3D, value: bool) -> void:
	crate_node.visible = value
	crate_node.set_process(value)
	crate_node.set_physics_process(value)

	for child in crate_node.get_children():
		if child is CollisionObject3D:
			var collision_object: CollisionObject3D = child as CollisionObject3D
			collision_object.set_deferred("disabled", not value)
		elif child is CollisionShape3D:
			var collision_shape: CollisionShape3D = child as CollisionShape3D
			collision_shape.set_deferred("disabled", not value)


func give_supply_health() -> void:
	if player == null or not is_instance_valid(player):
		return

	if object_has_property(player, "player_health"):
		var max_health: int = 20
		if object_has_property(player, "current_max_health"):
			max_health = int(player.get("current_max_health"))
		elif object_has_property(player, "PLAYER_MAX_HEALTH"):
			max_health = int(player.get("PLAYER_MAX_HEALTH"))

		player.set("player_health", min(int(player.get("player_health")) + 10, max_health))
		if player.has_method("update_ui"):
			player.call("update_ui")
		show_status("Supply crate: health restored")


func give_supply_ammo() -> void:
	if player == null or not is_instance_valid(player):
		return

	if object_has_property(player, "ammo"):
		var max_ammo: int = 25
		if object_has_property(player, "MAX_AMMO"):
			max_ammo = int(player.get("MAX_AMMO"))
		player.set("ammo", max_ammo)

	if object_has_property(player, "is_reloading"):
		player.set("is_reloading", false)

	if player.has_method("update_ui"):
		player.call("update_ui")

	show_status("Supply crate: ammo refilled")


func give_supply_stamina() -> void:
	if player == null or not is_instance_valid(player):
		return

	if object_has_property(player, "stamina"):
		var max_stamina: float = 500.0
		if object_has_property(player, "current_max_stamina"):
			max_stamina = float(player.get("current_max_stamina"))
		elif object_has_property(player, "MAX_STAMINA"):
			max_stamina = float(player.get("MAX_STAMINA"))
		player.set("stamina", max_stamina)

	if player.has_method("update_ui"):
		player.call("update_ui")

	show_status("Supply crate: stamina refilled")


func give_supply_fuel(crate_position: Vector3) -> void:
	var helicopters: Array[Node] = get_tree().get_nodes_in_group("Helicopter")
	var nearest_heli: Node = null
	var nearest_distance: float = 999999.0

	for heli in helicopters:
		if heli == null or not heli is Node3D:
			continue

		var heli_node: Node3D = heli as Node3D
		var distance_to_heli: float = crate_position.distance_to(heli_node.global_position)
		if distance_to_heli < nearest_distance:
			nearest_distance = distance_to_heli
			nearest_heli = heli

	if nearest_heli == null:
		return

	if nearest_heli.has_method("refuel_from_crate"):
		nearest_heli.call("refuel_from_crate", 75.0)
		show_status("Supply crate: helicopter fuel added")
		return

	if object_has_property(nearest_heli, "fuel_remaining"):
		var max_fuel: float = 180.0
		if object_has_property(nearest_heli, "upgraded_max_fuel_time"):
			max_fuel = float(nearest_heli.get("upgraded_max_fuel_time"))
		elif object_has_property(nearest_heli, "MAX_FUEL_TIME"):
			max_fuel = float(nearest_heli.get("MAX_FUEL_TIME"))

		nearest_heli.set("fuel_remaining", min(float(nearest_heli.get("fuel_remaining")) + 75.0, max_fuel))

	if object_has_property(nearest_heli, "fuel_empty_permanent"):
		nearest_heli.set("fuel_empty_permanent", false)

	show_status("Supply crate: helicopter fuel added")


# ---------------- FINAL BOSS / RESULT PATCH FUNCTIONS ----------------
func unlock_result_achievements(result: String) -> void:
	if not result.begins_with("VICTORY"):
		return
	if selected_game_mode == GAME_MODE_ELIMINATION:
		unlock_achievement("team_elim_win")
	elif selected_game_mode == GAME_MODE_CTF:
		unlock_achievement("ctf_specialist")
	elif selected_game_mode == GAME_MODE_KING_HILL:
		unlock_achievement("king_hill_win")
	elif selected_game_mode == GAME_MODE_COMMANDER:
		unlock_achievement("commander_breaker")
	elif selected_game_mode == GAME_MODE_MANHUNT:
		if manhunt_hunted_team == "blue" and manhunt_hunted_target == player:
			unlock_achievement("manhunt_survivor")
		elif manhunt_hunted_team == "red":
			unlock_achievement("red_hunted_survivor")
	elif selected_game_mode == GAME_MODE_FINAL_BOSS:
		if final_boss_current_hp <= 0:
			unlock_achievement("final_boss")
			award_money("Final boss defeated", FINAL_BOSS_REWARD_MONEY)

func setup_final_boss_mode_if_needed() -> void:
	if selected_game_mode != GAME_MODE_FINAL_BOSS:
		hide_boss_health_ui()
		return

	match_time_remaining = FINAL_BOSS_TIME_LIMIT
	player_deaths = 0

	boss_unit = null
	final_boss_has_spawned = false
	final_boss_spawn_grace_timer = 2.0
	final_boss_match_timer = 0.0
	final_boss_current_hp = FINAL_BOSS_HEALTH
	final_boss_shotgun_timer = 1.2
	final_boss_ring_timer = 3.0
	final_boss_charge_timer = 4.5
	final_boss_summon_timer = 999999.0
	final_boss_is_charging = false
	final_boss_charge_time_left = 0.0
	final_boss_charge_direction = Vector3.ZERO
	final_boss_offense_update_timer = 0.0

	# Clear all old Red units. Final Boss mode has exactly one Red: the boss.
	for unit in red_units:
		if unit != null and is_instance_valid(unit):
			unit.queue_free()

	red_units.clear()

	var kept_blue_units: Array[CharacterBody3D] = []
	for unit in all_units:
		if unit == null or not is_instance_valid(unit):
			continue

		var team_value: String = str(unit.get_meta("team", ""))
		if team_value == "red":
			continue

		kept_blue_units.append(unit)

	all_units = kept_blue_units
	red_spawned_total = 0
	red_respawn_timer = 999999.0

	red_plan = BattlePlan.ASSAULT
	blue_plan = BattlePlan.ASSAULT

	spawn_final_boss()
	show_boss_health_ui()

func spawn_final_boss_guards() -> void:
	# Final Boss guards removed. Final Showdown is boss-only.
	return

func spawn_final_boss() -> void:
	if selected_game_mode != GAME_MODE_FINAL_BOSS:
		return

	if boss_unit != null and is_instance_valid(boss_unit):
		return

	final_boss_current_hp = FINAL_BOSS_HEALTH
	final_boss_locked_position = get_final_boss_spawn_position()
	final_boss_move_direction = Vector3.ZERO
	final_boss_target_update_timer = 0.0
	final_boss_path_update_timer = 0.0
	final_boss_los_update_timer = 0.0
	final_boss_single_shot_timer = 1.25
	final_boss_dash_timer = 0.0
	final_boss_dash_cooldown_timer = 1.4
	final_boss_dash_direction = Vector3.ZERO
	final_boss_last_attack_name = ""
	final_boss_player_damage_cooldown_timer = 0.0
	final_boss_has_line_of_sight = false

	spawn_one_unit("red")

	if red_units.is_empty():
		final_boss_spawn_grace_timer = max(final_boss_spawn_grace_timer, 0.35)
		return

	boss_unit = red_units[0]

	if boss_unit == null or not is_instance_valid(boss_unit):
		final_boss_spawn_grace_timer = max(final_boss_spawn_grace_timer, 0.35)
		return

	final_boss_has_spawned = true
	final_boss_spawn_grace_timer = 0.0

	boss_unit.name = "FinalBoss"
	boss_unit.add_to_group("BattleNPC")
	boss_unit.add_to_group("RedTeam")
	boss_unit.global_position = final_boss_locked_position
	boss_unit.scale = FINAL_BOSS_SIZE_SCALE
	boss_unit.velocity = Vector3.ZERO

	boss_unit.set_meta("is_final_boss", true)
	boss_unit.set_meta("team", "red")
	boss_unit.set_meta("dead", false)
	boss_unit.set_meta("health", FINAL_BOSS_HEALTH)
	boss_unit.set_meta("max_health", FINAL_BOSS_HEALTH)
	boss_unit.set_meta("spawn_immune_timer", 0.0)
	boss_unit.set_meta("damage_multiplier", FINAL_BOSS_DAMAGE_MULTIPLIER)
	boss_unit.set_meta("boss_fire_multiplier", FINAL_BOSS_FIRE_COOLDOWN_MULTIPLIER_STRONG)
	boss_unit.set_meta("boss_miss_chance", FINAL_BOSS_MISS_CHANCE)
	boss_unit.set_meta("shoot_distance", NPC_SHOOT_DISTANCE_MAX * 1.9)
	boss_unit.set_meta("stop_distance", FINAL_BOSS_ATTACK_DISTANCE)
	boss_unit.set_meta("speed", FINAL_BOSS_MAX_MOVE_SPEED)
	boss_unit.set_meta("state", "boss_hunt")
	boss_unit.set_meta("ai_role", "boss_hunter")
	boss_unit.set_meta("search_repick_timer", 0.0)
	boss_unit.set_meta("target_refresh_timer", 0.0)

	create_final_boss_hitboxes()
	show_boss_health_ui()
	print("FINAL BOSS SPAWNED: center spawn, scaled red CPU, 500 HP, active boss AI")

func is_final_boss_dead() -> bool:
	if selected_game_mode != GAME_MODE_FINAL_BOSS:
		return false

	if not final_boss_has_spawned:
		return false

	if final_boss_match_timer < FINAL_BOSS_MIN_WIN_TIME:
		return false

	return final_boss_current_hp <= 0

func as_safe_vector3(value: Variant, fallback: Vector3 = Vector3.ZERO) -> Vector3:
	if value is Vector3:
		return value

	if value is Vector2:
		var v2: Vector2 = value
		return Vector3(v2.x, fallback.y, v2.y)

	if value is Array:
		var arr: Array = value
		if arr.size() >= 3:
			return Vector3(float(arr[0]), float(arr[1]), float(arr[2]))

	if value is Dictionary:
		var dict: Dictionary = value
		if dict.has("x") and dict.has("y") and dict.has("z"):
			return Vector3(float(dict["x"]), float(dict["y"]), float(dict["z"]))

	return fallback


func get_node_vector3_meta(node: Node, key: String, fallback: Vector3 = Vector3.ZERO) -> Vector3:
	if node == null:
		return fallback

	var value: Variant = node.get_meta(key, fallback)
	return as_safe_vector3(value, fallback)


func update_final_boss_special_attacks(delta: float) -> void:
	# Boss attacks are handled inside update_final_boss_unit_state().
	# This function remains to satisfy existing calls without double-firing.
	return

func final_boss_shotgun_attack() -> void:
	if boss_unit == null or not is_instance_valid(boss_unit):
		return

	var origin: Vector3 = boss_unit.global_position + Vector3(0.0, 7.0, 0.0)
	var to_player: Vector3 = (get_safe_player_position() + Vector3(0.0, 1.3, 0.0) - origin).normalized()

	for i in range(FINAL_BOSS_SHOTGUN_PELLETS):
		var spread_x: float = float(i - FINAL_BOSS_SHOTGUN_PELLETS / 2) * 0.055
		var spread_z: float = sin(float(i) * 1.7) * 0.035
		var dir: Vector3 = (to_player + Vector3(spread_x, 0.0, spread_z)).normalized()
		spawn_final_boss_laser(origin, apply_final_boss_miss_chance(dir), FINAL_BOSS_SPECIAL_DAMAGE, Color(1.0, 0.08, 0.0, 1.0))


func final_boss_ring_attack() -> void:
	if boss_unit == null or not is_instance_valid(boss_unit):
		return

	var origin: Vector3 = boss_unit.global_position + Vector3(0.0, 5.5, 0.0)

	for i in range(FINAL_BOSS_RING_BULLETS):
		var angle: float = TAU * float(i) / float(FINAL_BOSS_RING_BULLETS)
		var dir: Vector3 = Vector3(cos(angle), 0.03, sin(angle)).normalized()
		spawn_final_boss_laser(origin, apply_final_boss_miss_chance(dir), FINAL_BOSS_SPECIAL_DAMAGE, Color(1.0, 0.35, 0.0, 1.0))


func start_final_boss_charge() -> void:
	final_boss_is_charging = false
	final_boss_charge_time_left = 0.0
	final_boss_charge_direction = Vector3.ZERO
	lock_final_boss_position()

func update_final_boss_charge(delta: float) -> void:
	final_boss_is_charging = false
	final_boss_charge_time_left = 0.0
	final_boss_charge_direction = Vector3.ZERO
	lock_final_boss_position()

func final_boss_summon_guard() -> void:
	# Final Boss guards removed. No summons.
	return

func spawn_final_boss_laser(origin: Vector3, direction: Vector3, damage: int, laser_color: Color) -> void:
	if direction.length() < 0.01:
		return

	var clean_direction: Vector3 = direction.normalized()

	var bullet: Area3D = Area3D.new()
	bullet.name = "FinalBossSpecialLaser"
	bullet.global_position = origin
	bullet.set_meta("direction", clean_direction)
	bullet.set_meta("velocity", clean_direction * NPC_BULLET_SPEED * 1.20)
	bullet.set_meta("life", NPC_BULLET_LIFE)
	bullet.set_meta("team", "red")
	bullet.set_meta("damage", damage)
	bullet.set_meta("hit_radius", FINAL_BOSS_BULLET_HIT_RADIUS)
	bullet.set_meta("is_final_boss_laser", true)

	var collision: CollisionShape3D = CollisionShape3D.new()
	var shape: SphereShape3D = SphereShape3D.new()
	shape.radius = 0.42
	collision.shape = shape
	bullet.add_child(collision)

	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	var mesh: SphereMesh = SphereMesh.new()
	mesh.radius = 0.34
	mesh.height = 0.68
	mesh_instance.mesh = mesh

	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = laser_color
	mat.emission_enabled = true
	mat.emission = laser_color
	mat.emission_energy_multiplier = 4.2
	mesh_instance.material_override = mat
	bullet.add_child(mesh_instance)

	add_child(bullet)
	bullets.append(bullet)

func update_final_boss_mode(delta: float) -> void:
	if selected_game_mode != GAME_MODE_FINAL_BOSS or game_over:
		hide_boss_health_ui()
		return

	final_boss_match_timer += delta
	final_boss_player_damage_cooldown_timer = max(final_boss_player_damage_cooldown_timer - delta, 0.0)
	sync_final_boss_hp_from_unit()
	show_boss_health_ui()
	final_boss_ui_timer -= delta
	if final_boss_ui_timer <= 0.0:
		final_boss_ui_timer = 0.10
		update_boss_health_ui()

	if is_player_dead():
		show_result_screen("DEFEAT", "You fell in the final showdown. No respawn. Restart the battle.")
		return

	if not final_boss_has_spawned:
		final_boss_spawn_grace_timer = max(final_boss_spawn_grace_timer - delta, 0.0)

		if boss_unit == null or not is_instance_valid(boss_unit):
			spawn_final_boss()

		return

	if boss_unit == null or not is_instance_valid(boss_unit):
		if final_boss_current_hp > 0:
			spawn_final_boss()
		return

	lock_final_boss_position()

	if is_final_boss_dead():
		update_boss_health_ui()
		unlock_achievement("final_boss")
		show_result_screen("VICTORY", "Final boss defeated.")
		return

func reveal_shop_achievements() -> void:
	reveal_achievement("first_upgrade")
	reveal_achievement("sprint_maxed")
	reveal_achievement("stamina_maxed")
	reveal_achievement("stamina_regen_maxed")
	reveal_achievement("health_maxed")
	reveal_achievement("hcop_fuel_maxed")
	reveal_achievement("fire_rate_maxed")
	reveal_achievement("reload_speed_maxed")
	reveal_achievement("ammo_capacity_maxed")
	reveal_achievement("all_geared_up")


func check_shop_achievements() -> void:
	if upgrade_levels.is_empty():
		return

	var bought_any_upgrade: bool = false
	for upgrade_id in upgrade_levels.keys():
		if int(upgrade_levels.get(upgrade_id, 0)) > 0:
			bought_any_upgrade = true
			break

	if bought_any_upgrade:
		unlock_achievement("first_upgrade")
		reveal_shop_achievements()

	check_single_upgrade_maxed("sprint", "sprint_maxed")
	check_single_upgrade_maxed("stamina", "stamina_maxed")
	check_single_upgrade_maxed("stamina_regen", "stamina_regen_maxed")
	check_single_upgrade_maxed("health", "health_maxed")
	check_single_upgrade_maxed("hcop_fuel", "hcop_fuel_maxed")
	check_single_upgrade_maxed("fire_rate", "fire_rate_maxed")
	check_single_upgrade_maxed("reload_speed", "reload_speed_maxed")
	check_single_upgrade_maxed("ammo_capacity", "ammo_capacity_maxed")

	if are_all_shop_upgrades_maxed():
		unlock_achievement("all_geared_up")


func check_single_upgrade_maxed(upgrade_id: String, achievement_id: String) -> void:
	if not upgrade_data.has(upgrade_id):
		return

	var data: Dictionary = upgrade_data[upgrade_id]
	var max_level: int = int(data.get("max_level", 0))
	var current_level: int = int(upgrade_levels.get(upgrade_id, 0))

	if max_level > 0 and current_level >= max_level:
		unlock_achievement(achievement_id)
	elif current_level > 0:
		reveal_achievement(achievement_id)


func are_all_shop_upgrades_maxed() -> bool:
	for upgrade_id in upgrade_data.keys():
		var data: Dictionary = upgrade_data[upgrade_id]
		var max_level: int = int(data.get("max_level", 0))
		var current_level: int = int(upgrade_levels.get(upgrade_id, 0))

		if max_level <= 0:
			continue

		if current_level < max_level:
			return false

	return true



func save_shop_data_only() -> void:
	setup_achievement_defaults()

	var data: Dictionary = {
		"money": money,
		"lifetime_money_earned": lifetime_money_earned,
		"lifetime_eliminations": lifetime_eliminations,
		"lifetime_headshots": lifetime_headshots,
		"lifetime_flag_captures": lifetime_flag_captures,
		"lifetime_manhunt_survival_ticks": lifetime_manhunt_survival_ticks,
		"lifetime_team_elimination_eliminations": lifetime_team_elimination_eliminations,
		"lifetime_ctf_eliminations": lifetime_ctf_eliminations,
		"lifetime_commander_eliminations": lifetime_commander_eliminations,
		"lifetime_hill_eliminations": lifetime_hill_eliminations,
		"lifetime_manhunt_hunts_won": lifetime_manhunt_hunts_won,
		"upgrade_levels": upgrade_levels,
		"achievement_unlocked": achievement_unlocked,
		"achievement_seen": achievement_seen,
		"boss_mode_unlocked": boss_mode_unlocked,
		"final_boss_reward_power_unlocked": final_boss_reward_power_unlocked
	}

	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)

	if file == null:
		print("Could not save shop data.")
		return

	file.store_string(JSON.stringify(data))
	file.close()




func apply_final_boss_miss_chance(direction: Vector3) -> Vector3:
	var safe_dir: Vector3 = direction
	if safe_dir.length() < 0.01:
		safe_dir = Vector3.FORWARD

	# Boss misses only 10% of the time.
	if rng.randf() >= FINAL_BOSS_MISS_CHANCE:
		return safe_dir.normalized()

	var miss_spread: Vector3 = Vector3(
		rng.randf_range(-0.70, 0.70),
		rng.randf_range(-0.18, 0.18),
		rng.randf_range(-0.70, 0.70)
	)

	return (safe_dir.normalized() + miss_spread).normalized()


func create_final_boss_hitboxes() -> void:
	if boss_unit == null or not is_instance_valid(boss_unit):
		return

	var old_body: Node = boss_unit.get_node_or_null("FinalBossBodyHitbox")
	if old_body != null:
		old_body.queue_free()

	var old_head: Node = boss_unit.get_node_or_null("FinalBossHeadHitbox")
	if old_head != null:
		old_head.queue_free()

	var body_hitbox: Area3D = Area3D.new()
	body_hitbox.name = "FinalBossBodyHitbox"
	body_hitbox.collision_layer = 2
	body_hitbox.collision_mask = 0
	body_hitbox.monitoring = false
	body_hitbox.monitorable = true
	body_hitbox.set_meta("npc_root", boss_unit)
	body_hitbox.set_meta("hit_zone", "body")

	var body_collision: CollisionShape3D = CollisionShape3D.new()
	var body_shape: CapsuleShape3D = CapsuleShape3D.new()
	body_shape.radius = FINAL_BOSS_BODY_HITBOX_RADIUS
	body_shape.height = FINAL_BOSS_BODY_HITBOX_HEIGHT
	body_collision.shape = body_shape
	body_collision.position = Vector3(0.0, FINAL_BOSS_BODY_HITBOX_HEIGHT * 0.5, 0.0)
	body_hitbox.add_child(body_collision)
	boss_unit.add_child(body_hitbox)

	var head_hitbox: Area3D = Area3D.new()
	head_hitbox.name = "FinalBossHeadHitbox"
	head_hitbox.collision_layer = 2
	head_hitbox.collision_mask = 0
	head_hitbox.monitoring = false
	head_hitbox.monitorable = true
	head_hitbox.set_meta("npc_root", boss_unit)
	head_hitbox.set_meta("hit_zone", "head")

	var head_collision: CollisionShape3D = CollisionShape3D.new()
	var head_shape: SphereShape3D = SphereShape3D.new()
	head_shape.radius = FINAL_BOSS_HEAD_HITBOX_RADIUS
	head_collision.shape = head_shape
	head_collision.position = Vector3(0.0, FINAL_BOSS_BODY_HITBOX_HEIGHT + 0.65, 0.0)
	head_hitbox.add_child(head_collision)
	boss_unit.add_child(head_hitbox)

	print("FINAL BOSS HITBOXES READY")

func update_final_boss_offense(delta: float) -> void:
	if boss_unit == null or not is_instance_valid(boss_unit):
		return

	final_boss_offense_update_timer -= delta

	if final_boss_offense_update_timer > 0.0:
		return

	final_boss_offense_update_timer = 0.75
	lock_final_boss_position()

	if player == null or not is_instance_valid(player):
		find_player()

	if player == null or not is_instance_valid(player):
		return

	var to_player: Vector3 = player.global_position - boss_unit.global_position
	to_player.y = 0.0

	if to_player.length() > 0.1:
		boss_unit.look_at(boss_unit.global_position + to_player.normalized(), Vector3.UP)

func get_result_title_text(result: String) -> String:
	if selected_game_mode == GAME_MODE_FINAL_BOSS and result.begins_with("VICTORY"):
		return "FINAL BOSS DEFEATED"

	if selected_game_mode == GAME_MODE_CTF:
		if result.begins_with("VICTORY"):
			return "FLAG CAPTURED"
		if result.begins_with("DEFEAT"):
			return "FLAG LOST"

	if selected_game_mode == GAME_MODE_MANHUNT:
		if result.begins_with("VICTORY"):
			return "HUNT SURVIVED"
		if result.begins_with("DEFEAT"):
			return "HUNTED DOWN"

	if selected_game_mode == GAME_MODE_KING_HILL:
		if result.begins_with("VICTORY"):
			return "HILL SECURED"
		if result.begins_with("DEFEAT"):
			return "HILL LOST"

	if selected_game_mode == GAME_MODE_COMMANDER:
		if result.begins_with("VICTORY"):
			return "COMMAND BROKEN"
		if result.begins_with("DEFEAT"):
			return "COMMAND LOST"

	if result.begins_with("VICTORY"):
		return "VICTORY"

	if result.begins_with("DEFEAT"):
		return "DEFEAT"

	return result

func get_result_detail_text(result: String, extra_line: String = "") -> String:
	var lines: Array[String] = []

	if selected_game_mode == GAME_MODE_FINAL_BOSS and result.begins_with("VICTORY"):
		lines.append("Final Boss defeated.")
		lines.append("Boss HP: 0 / " + str(FINAL_BOSS_HEALTH))
		lines.append("")
		lines.append("You finished the final fight.")
		lines.append("Press MAIN MENU to continue to the ending.")
		return "\n".join(lines)

	lines.append("Mode: " + get_game_mode_display_name(selected_game_mode))

	if extra_line != "":
		lines.append(extra_line)

	if selected_game_mode == GAME_MODE_FINAL_BOSS:
		lines.append("Boss HP: " + str(max(final_boss_current_hp, 0)) + " / " + str(FINAL_BOSS_HEALTH))
		lines.append("Player Knock Outs: " + str(player_kills) + " | Headshots: " + str(player_headshots))
	elif selected_game_mode == GAME_MODE_CTF:
		lines.append("Blue Captures: " + str(blue_ctf_score) + " | Red Captures: " + str(red_ctf_score))
	elif selected_game_mode == GAME_MODE_KING_HILL:
		lines.append("Blue Hill Score: " + str(int(blue_hill_score)) + " | Red Hill Score: " + str(int(red_hill_score)))
	elif selected_game_mode == GAME_MODE_MANHUNT:
		lines.append("Hunted Team: " + manhunt_hunted_team.capitalize())
	elif selected_game_mode == GAME_MODE_COMMANDER:
		lines.append(get_commander_status_text())
	else:
		lines.append("Player Knock Outs: " + str(player_kills))
		lines.append("Headshots: " + str(player_headshots))
		lines.append("Times Knocked Out: " + str(player_deaths))

	return "\n".join(lines)

func animate_result_screen() -> void:
	var tween: Tween = create_tween()
	tween.set_parallel(true)

	if result_panel != null:
		result_panel.modulate.a = 0.0
		tween.tween_property(result_panel, "modulate:a", 1.0, 0.70)

	if simple_fireworks_panel != null and simple_fireworks_panel.visible:
		simple_fireworks_panel.modulate.a = 0.0
		tween.tween_property(simple_fireworks_panel, "modulate:a", 1.0, 0.90)

	if result_card_panel != null:
		result_card_panel.modulate.a = 0.0
		result_card_panel.scale = Vector2(0.88, 0.88)
		tween.tween_property(result_card_panel, "modulate:a", 1.0, 0.70)
		tween.tween_property(result_card_panel, "scale", Vector2.ONE, 0.70).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	if result_menu_button != null:
		result_menu_button.modulate.a = 0.0
		tween.tween_property(result_menu_button, "modulate:a", 1.0, 1.20)

func lock_final_boss_position() -> void:
	if selected_game_mode != GAME_MODE_FINAL_BOSS:
		return

	if boss_unit == null or not is_instance_valid(boss_unit):
		return

	if final_boss_current_hp <= 0:
		return

	boss_unit.set_meta("is_final_boss", true)
	boss_unit.set_meta("team", "red")
	boss_unit.set_meta("dead", false)
	boss_unit.set_meta("max_health", FINAL_BOSS_HEALTH)
	boss_unit.set_meta("speed", FINAL_BOSS_MAX_MOVE_SPEED)
	boss_unit.set_meta("state", "boss_hunt")
	boss_unit.set_meta("ai_role", "boss_hunter")

func remove_final_boss_from_cpu_loops() -> void:
	# Intentionally no-op.
	# Keep boss in red_units/all_units so minimap and counters remain correct.
	# Performance is handled by update_units() routing the boss to dedicated boss AI.
	return

func final_boss_single_laser_attack() -> void:
	var target: Node3D = get_final_boss_target()

	if target == null or not is_instance_valid(target):
		return

	final_boss_rifle_burst_attack(target)

func sync_final_boss_hp_from_unit() -> void:
	if selected_game_mode != GAME_MODE_FINAL_BOSS:
		return

	if boss_unit == null or not is_instance_valid(boss_unit):
		return

	if not boss_unit.has_meta("health"):
		boss_unit.set_meta("health", final_boss_current_hp)
		return

	var unit_hp: int = int(boss_unit.get_meta("health"))

	if unit_hp < final_boss_current_hp:
		var raw_delta: int = final_boss_current_hp - unit_hp
		var capped_delta: int = clamp(raw_delta, 1, FINAL_BOSS_MAX_DAMAGE_PER_PLAYER_HIT)

		final_boss_current_hp = max(final_boss_current_hp - capped_delta, 0)

		# Put the capped HP back onto the boss so old Player direct damage cannot keep draining it.
		boss_unit.set_meta("health", final_boss_current_hp)
		print("FINAL BOSS DAMAGE SYNC CAPPED: raw=", raw_delta, " applied=", capped_delta, " hp=", final_boss_current_hp)
	elif unit_hp > final_boss_current_hp:
		boss_unit.set_meta("health", final_boss_current_hp)

	if final_boss_current_hp <= 0:
		boss_unit.set_meta("dead", true)
	else:
		boss_unit.set_meta("dead", false)

func update_final_boss_unit_state(unit: CharacterBody3D, delta: float) -> void:
	if selected_game_mode != GAME_MODE_FINAL_BOSS:
		return

	if unit == null or not is_instance_valid(unit):
		return

	if boss_unit == null or not is_instance_valid(boss_unit):
		boss_unit = unit

	sync_final_boss_hp_from_unit()

	if final_boss_current_hp <= 0:
		unit.set_meta("health", 0)
		unit.set_meta("dead", true)
		return

	final_boss_dash_cooldown_timer = max(final_boss_dash_cooldown_timer - delta, 0.0)

	unit.set_meta("is_final_boss", true)
	unit.set_meta("team", "red")
	unit.set_meta("dead", false)
	unit.set_meta("max_health", FINAL_BOSS_HEALTH)
	unit.set_meta("spawn_immune_timer", 0.0)
	unit.set_meta("speed", FINAL_BOSS_MAX_MOVE_SPEED)
	unit.set_meta("state", "boss_hunt")
	unit.set_meta("ai_role", "boss_hunter")

	var target: Node3D = get_final_boss_target()
	var move_direction: Vector3 = Vector3.ZERO
	var distance_to_target: float = 999999.0

	if target != null and is_instance_valid(target):
		var to_target: Vector3 = target.global_position - unit.global_position
		to_target.y = 0.0
		distance_to_target = to_target.length()

		if distance_to_target > 0.1:
			unit.look_at(unit.global_position + to_target.normalized(), Vector3.UP)

		if final_boss_dash_timer > 0.0:
			final_boss_dash_timer -= delta
			move_direction = final_boss_dash_direction
		else:
			move_direction = get_final_boss_move_direction(unit, target, delta)
			final_boss_try_attack(unit, target, distance_to_target, delta)

	apply_gravity_and_jump(unit, move_direction, delta)

	var speed: float = FINAL_BOSS_MAX_MOVE_SPEED

	if final_boss_current_hp <= FINAL_BOSS_PHASE_TWO_HEALTH:
		speed *= 1.25

	if final_boss_dash_timer > 0.0:
		speed = FINAL_BOSS_DASH_SPEED

	if distance_to_target <= FINAL_BOSS_ATTACK_DISTANCE and distance_to_target >= FINAL_BOSS_RETREAT_DISTANCE and final_boss_dash_timer <= 0.0:
		speed *= 0.65

	if move_direction.length() > 0.01:
		unit.velocity.x = move_direction.x * speed
		unit.velocity.z = move_direction.z * speed
	else:
		unit.velocity.x = move_toward(unit.velocity.x, 0.0, speed * delta)
		unit.velocity.z = move_toward(unit.velocity.z, 0.0, speed * delta)

	unit.move_and_slide()
	apply_bounds(unit)
	handle_stuck_jump(unit, delta)
	animate_unit(unit, delta)
	update_health_bar(unit)

func get_final_boss_spawn_position() -> Vector3:
	var spawn_node: Node3D = find_final_boss_spawn_node()

	if spawn_node != null:
		return snap_position_to_ground(spawn_node.global_position)

	return snap_position_to_ground(FINAL_BOSS_CENTER)

func draw_final_boss_minimap_fallback(canvas: Control) -> void:
	if selected_game_mode != GAME_MODE_FINAL_BOSS:
		return

	if boss_unit == null or not is_instance_valid(boss_unit):
		return

	if final_boss_current_hp <= 0:
		return

	if red_units.has(boss_unit):
		return

	draw_minimap_unit(canvas, boss_unit, Color(1.0, 0.05, 0.03, 1.0), MINIMAP_DOT_SIZE)

func find_final_boss_spawn_node() -> Node3D:
	var grouped_nodes: Array[Node] = get_tree().get_nodes_in_group(FINAL_BOSS_SPAWN_NODE_NAME)

	for node in grouped_nodes:
		if node != null and is_instance_valid(node) and node is Node3D:
			return node as Node3D

	var named_node: Node = get_tree().root.find_child(FINAL_BOSS_SPAWN_NODE_NAME, true, false)

	if named_node != null and is_instance_valid(named_node) and named_node is Node3D:
		return named_node as Node3D

	return null



func get_final_boss_target() -> Node3D:
	if player != null and is_instance_valid(player) and not is_player_dead():
		return player

	var best_target: Node3D = null
	var best_distance: float = 999999.0

	for unit in blue_units:
		if not is_valid_target(unit):
			continue

		var distance: float = boss_unit.global_position.distance_to(unit.global_position) if boss_unit != null and is_instance_valid(boss_unit) else 999999.0

		if distance < best_distance:
			best_distance = distance
			best_target = unit

	return best_target



func final_boss_has_clear_path(unit: CharacterBody3D, direction: Vector3, distance: float = 3.0) -> bool:
	if unit == null or not is_instance_valid(unit):
		return false

	if direction.length() < 0.01:
		return true

	var start: Vector3 = unit.global_position + Vector3(0.0, 1.2, 0.0)
	var end: Vector3 = start + direction.normalized() * distance
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(start, end)
	query.exclude = [unit.get_rid()]
	query.collide_with_bodies = true
	query.collide_with_areas = false

	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)

	if hit.size() <= 0:
		return true

	var collider: Object = hit.get("collider", null)

	if collider != null and collider is Node:
		var node: Node = collider as Node
		if node.is_in_group("BattleNPC"):
			return true

	return false



func get_final_boss_move_direction(unit: CharacterBody3D, target: Node3D, delta: float) -> Vector3:
	if unit == null or not is_instance_valid(unit):
		return Vector3.ZERO

	if target == null or not is_instance_valid(target):
		return Vector3.ZERO

	final_boss_path_update_timer -= delta

	if final_boss_path_update_timer > 0.0 and final_boss_move_direction.length() > 0.01:
		return final_boss_move_direction

	final_boss_path_update_timer = FINAL_BOSS_PATH_RECALC_INTERVAL

	var to_target: Vector3 = target.global_position - unit.global_position
	to_target.y = 0.0

	if to_target.length() < 0.1:
		final_boss_move_direction = Vector3.ZERO
		return final_boss_move_direction

	var distance: float = to_target.length()
	var forward: Vector3 = to_target.normalized()
	var right: Vector3 = Vector3(-forward.z, 0.0, forward.x)
	var phase_two: bool = final_boss_current_hp <= FINAL_BOSS_PHASE_TWO_HEALTH
	var desired: Vector3 = forward

	if distance > FINAL_BOSS_CHASE_DISTANCE:
		desired = forward
	elif distance < FINAL_BOSS_RETREAT_DISTANCE:
		desired = -forward + right * sin(final_boss_match_timer * 2.0) * 0.55
	elif distance < FINAL_BOSS_STRAFE_DISTANCE:
		desired = right * sign(sin(final_boss_match_timer * 1.35))
	else:
		desired = forward * 0.55 + right * sin(final_boss_match_timer * 1.7) * (0.80 if phase_two else 0.55)

	if desired.length() < 0.01:
		desired = forward

	desired = desired.normalized()

	if not final_boss_has_clear_path(unit, desired, 4.2):
		var left: Vector3 = desired.rotated(Vector3.UP, deg_to_rad(58.0)).normalized()
		var right_dir: Vector3 = desired.rotated(Vector3.UP, deg_to_rad(-58.0)).normalized()

		if final_boss_has_clear_path(unit, left, 4.2):
			desired = left
		elif final_boss_has_clear_path(unit, right_dir, 4.2):
			desired = right_dir
		else:
			desired = -desired

	final_boss_move_direction = desired
	return final_boss_move_direction



func final_boss_update_los(unit: CharacterBody3D, target: Node3D, delta: float) -> bool:
	final_boss_los_update_timer -= delta

	if final_boss_los_update_timer > 0.0:
		return final_boss_has_line_of_sight

	final_boss_los_update_timer = FINAL_BOSS_ATTACK_LOS_INTERVAL
	final_boss_has_line_of_sight = has_combat_line_of_sight(unit, target)
	return final_boss_has_line_of_sight



func final_boss_try_attack(unit: CharacterBody3D, target: Node3D, distance: float, delta: float) -> void:
	if unit == null or target == null:
		return

	if not is_instance_valid(unit) or not is_instance_valid(target):
		return

	final_boss_single_shot_timer -= delta
	final_boss_close_blast_timer -= delta

	if final_boss_single_shot_timer > 0.0:
		return

	var attack_target: Node3D = get_final_boss_attack_target(target, distance)
	var attack_distance: float = boss_unit.global_position.distance_to(attack_target.global_position) if attack_target != null and is_instance_valid(attack_target) and boss_unit != null and is_instance_valid(boss_unit) else distance
	var attack_name: String = final_boss_pick_attack(attack_distance)

	if attack_name == "hunt_advance":
		final_boss_single_shot_timer = 0.35
		final_boss_last_attack_name = attack_name
		return

	if attack_name == "dash_rush":
		final_boss_dash_attack(attack_target)
		final_boss_single_shot_timer = final_boss_get_attack_cooldown()
		final_boss_last_attack_name = attack_name
		return

	if attack_name == "radial_blast":
		if final_boss_close_blast_timer <= 0.0:
			final_boss_radial_blast_attack()
			final_boss_close_blast_timer = FINAL_BOSS_CLOSE_BLAST_COOLDOWN
			final_boss_single_shot_timer = final_boss_get_attack_cooldown()
			final_boss_last_attack_name = attack_name
		else:
			final_boss_single_shot_timer = 0.25
		return

	if attack_name == "rifle_burst":
		# Main boss gun attack. Allowed only inside fair gun range.
		if attack_distance <= FINAL_BOSS_MAX_GUN_RANGE:
			final_boss_rifle_burst_attack(attack_target)
			final_boss_single_shot_timer = final_boss_get_attack_cooldown()
			final_boss_last_attack_name = attack_name
		else:
			final_boss_single_shot_timer = 0.35
		return

	if attack_name == "sweep_fire":
		if attack_distance <= FINAL_BOSS_MAX_GUN_RANGE:
			final_boss_sweep_fire_attack(attack_target)
			final_boss_single_shot_timer = final_boss_get_attack_cooldown()
			final_boss_last_attack_name = attack_name
		else:
			final_boss_single_shot_timer = 0.35
		return

	if attack_name == "suppression_fire":
		# Suppression is allowed at the far edge, but not true across-map.
		if attack_distance < FINAL_BOSS_NO_GUN_RANGE:
			final_boss_suppression_fire_attack(attack_target)
			final_boss_single_shot_timer = final_boss_get_attack_cooldown()
			final_boss_last_attack_name = attack_name
		else:
			final_boss_single_shot_timer = 0.35
		return

	final_boss_single_shot_timer = 0.35

func final_boss_burst_attack(target: Node3D) -> void:
	final_boss_rifle_burst_attack(target)

func final_boss_radial_blast_attack() -> void:
	if boss_unit == null or not is_instance_valid(boss_unit):
		return

	var origin: Vector3 = boss_unit.global_position + Vector3(0.0, 3.6, 0.0)

	for i in range(FINAL_BOSS_CLOSE_BLAST_SHOTS):
		var angle: float = TAU * float(i) / float(FINAL_BOSS_CLOSE_BLAST_SHOTS)
		var dir: Vector3 = Vector3(cos(angle), 0.02, sin(angle)).normalized()
		spawn_final_boss_laser(origin, dir, FINAL_BOSS_BULLET_DAMAGE, Color(1.0, 0.38, 0.0, 1.0))

	print("FINAL BOSS ATTACK: Radial Blast")

func final_boss_pick_attack(distance: float) -> String:
	var attacks: Array[String] = []

	# Across-map behavior: no gun. The boss closes distance first.
	if distance >= FINAL_BOSS_NO_GUN_RANGE:
		if final_boss_dash_cooldown_timer <= 0.0:
			return "dash_rush"
		return "hunt_advance"

	# Close range: blast, sweep, or gun at short range.
	if distance <= FINAL_BOSS_CLOSE_BLAST_DISTANCE:
		attacks.append("radial_blast")
		attacks.append("sweep_fire")
		attacks.append("rifle_burst")

		if final_boss_dash_cooldown_timer <= 0.0 and distance >= FINAL_BOSS_DASH_MIN_RANGE:
			attacks.append("dash_rush")

	# Medium range: boss mainly uses the gun, then mixes in special attacks.
	if distance > FINAL_BOSS_CLOSE_BLAST_DISTANCE and distance <= FINAL_BOSS_MAX_GUN_RANGE:
		# Rifle burst appears twice so the boss uses his gun more often.
		attacks.append("rifle_burst")
		attacks.append("rifle_burst")
		attacks.append("sweep_fire")
		attacks.append("suppression_fire")

		if final_boss_dash_cooldown_timer <= 0.0 and distance >= FINAL_BOSS_DASH_MIN_RANGE:
			attacks.append("dash_rush")

	# Long-but-not-across-map range: suppress or close distance.
	if distance > FINAL_BOSS_MAX_GUN_RANGE and distance < FINAL_BOSS_NO_GUN_RANGE:
		attacks.append("suppression_fire")
		if final_boss_dash_cooldown_timer <= 0.0:
			attacks.append("dash_rush")

	if attacks.is_empty():
		return "hunt_advance"

	# Avoid repeating unless rifle_burst is the only practical option.
	if attacks.size() > 1 and attacks.has(final_boss_last_attack_name) and final_boss_last_attack_name != "rifle_burst":
		attacks.erase(final_boss_last_attack_name)

	var picked_index: int = rng.randi_range(0, attacks.size() - 1)
	return attacks[picked_index]

func final_boss_get_attack_cooldown() -> float:
	var cooldown: float = rng.randf_range(FINAL_BOSS_ATTACK_DECISION_COOLDOWN_MIN, FINAL_BOSS_ATTACK_DECISION_COOLDOWN_MAX)

	if final_boss_current_hp <= FINAL_BOSS_PHASE_TWO_HEALTH:
		cooldown *= FINAL_BOSS_PHASE_TWO_ATTACK_COOLDOWN_MULTIPLIER

	return cooldown



func final_boss_get_fair_aim_direction(origin: Vector3, target: Node3D, error_radius: float) -> Vector3:
	if target == null or not is_instance_valid(target):
		return Vector3.ZERO

	var effective_error: float = error_radius

	if final_boss_current_hp <= FINAL_BOSS_PHASE_TWO_HEALTH:
		effective_error *= 0.75

	# The boss aims near the player, not perfectly at the exact center every shot.
	var aim_point: Vector3 = target.global_position + Vector3(0.0, 1.2, 0.0)
	aim_point += Vector3(
		rng.randf_range(-effective_error, effective_error),
		rng.randf_range(-effective_error * 0.20, effective_error * 0.20),
		rng.randf_range(-effective_error, effective_error)
	)

	var direction: Vector3 = aim_point - origin

	if direction.length() < 0.1:
		return Vector3.ZERO

	return direction.normalized()



func final_boss_sweep_fire_attack(target: Node3D) -> void:
	if boss_unit == null or not is_instance_valid(boss_unit):
		return

	if target == null or not is_instance_valid(target):
		return

	var origin: Vector3 = get_muzzle_position(boss_unit)
	var base_direction: Vector3 = final_boss_get_fair_aim_direction(origin, target, FINAL_BOSS_FAIR_AIM_ERROR_NEAR)

	if base_direction.length() < 0.1:
		return

	var center_index: float = float(FINAL_BOSS_SWEEP_SHOTS - 1) * 0.5

	for i in range(FINAL_BOSS_SWEEP_SHOTS):
		var offset: float = float(i) - center_index
		var yaw: float = deg_to_rad((offset / max(center_index, 1.0)) * FINAL_BOSS_SWEEP_ARC_DEGREES)
		var direction: Vector3 = base_direction.rotated(Vector3.UP, yaw).normalized()
		spawn_final_boss_laser(origin, direction, FINAL_BOSS_BULLET_DAMAGE, Color(1.0, 0.18, 0.04, 1.0))

	play_unit_sound(boss_unit, "shoot")
	print("FINAL BOSS ATTACK: Sweep Fire")

func final_boss_suppression_fire_attack(target: Node3D) -> void:
	if boss_unit == null or not is_instance_valid(boss_unit):
		return

	if target == null or not is_instance_valid(target):
		return

	var origin: Vector3 = get_muzzle_position(boss_unit)
	var base_direction: Vector3 = final_boss_get_fair_aim_direction(origin, target, FINAL_BOSS_FAIR_AIM_ERROR_LONG)

	if base_direction.length() < 0.1:
		return

	for i in range(FINAL_BOSS_SUPPRESSION_SHOTS):
		var yaw: float = deg_to_rad(rng.randf_range(-FINAL_BOSS_SUPPRESSION_SPREAD_DEGREES, FINAL_BOSS_SUPPRESSION_SPREAD_DEGREES))
		var direction: Vector3 = base_direction.rotated(Vector3.UP, yaw).normalized()
		spawn_final_boss_laser(origin, direction, FINAL_BOSS_BULLET_DAMAGE, Color(1.0, 0.42, 0.04, 1.0))

	play_unit_sound(boss_unit, "shoot")
	print("FINAL BOSS ATTACK: Suppression Fire")

func final_boss_dash_attack(target: Node3D) -> void:
	if boss_unit == null or not is_instance_valid(boss_unit):
		return

	if target == null or not is_instance_valid(target):
		return

	if final_boss_dash_cooldown_timer > 0.0:
		return

	var direction: Vector3 = target.global_position - boss_unit.global_position
	direction.y = 0.0

	if direction.length() < 0.1:
		return

	final_boss_dash_direction = direction.normalized()
	final_boss_dash_timer = FINAL_BOSS_DASH_DURATION
	final_boss_dash_cooldown_timer = FINAL_BOSS_DASH_COOLDOWN

	print("FINAL BOSS ATTACK: Dash Rush")



func spawn_final_boss_gun_bullet(target: Node3D, aim_error: float) -> void:
	if boss_unit == null or not is_instance_valid(boss_unit):
		return

	if target == null or not is_instance_valid(target):
		return

	var muzzle_position: Vector3 = get_muzzle_position(boss_unit)
	var direction: Vector3 = final_boss_get_fair_aim_direction(muzzle_position, target, aim_error)

	if direction.length() < 0.01:
		return

	var distance_to_target: float = muzzle_position.distance_to(target.global_position + Vector3(0.0, 1.0, 0.0))
	var visual_end_position: Vector3 = get_laser_stop_position(
		muzzle_position,
		direction,
		min(distance_to_target, FINAL_BOSS_MAX_GUN_RANGE),
		"red"
	)

	spawn_laser_ray(muzzle_position, visual_end_position, "red")
	play_unit_sound(boss_unit, "shoot")

	var bullet: Area3D = Area3D.new()
	bullet.name = "FinalBossGunBullet"
	bullet.collision_layer = 0
	bullet.collision_mask = 1
	bullet.set_meta("direction", direction.normalized())
	bullet.set_meta("life", NPC_BULLET_LIFE)
	bullet.set_meta("team", "red")
	bullet.set_meta("damage", FINAL_BOSS_BULLET_DAMAGE)
	bullet.set_meta("hit_radius", FINAL_BOSS_BULLET_HIT_RADIUS)
	bullet.set_meta("is_final_boss_bullet", true)

	var collision: CollisionShape3D = CollisionShape3D.new()
	var sphere_shape: SphereShape3D = SphereShape3D.new()
	sphere_shape.radius = 0.12
	collision.shape = sphere_shape
	bullet.add_child(collision)

	var bullet_mesh: MeshInstance3D = MeshInstance3D.new()
	var sphere_mesh: SphereMesh = SphereMesh.new()
	sphere_mesh.radius = 0.10
	sphere_mesh.height = 0.20
	bullet_mesh.mesh = sphere_mesh
	bullet_mesh.material_override = make_material(Color(1.0, 0.12, 0.04, 1.0), 3.0)
	bullet_mesh.visible = false
	bullet.add_child(bullet_mesh)

	get_tree().current_scene.add_child(bullet)
	bullet.global_position = muzzle_position

	if direction.length() > 0.0:
		bullet.look_at(bullet.global_position + direction, Vector3.UP)

	bullets.append(bullet)



func final_boss_rifle_burst_attack(target: Node3D) -> void:
	if boss_unit == null or not is_instance_valid(boss_unit):
		return

	if target == null or not is_instance_valid(target):
		return

	var shot_count: int = FINAL_BOSS_RIFLE_BURST_SHOTS

	if final_boss_current_hp <= FINAL_BOSS_PHASE_TWO_HEALTH:
		shot_count = FINAL_BOSS_PHASE_TWO_RIFLE_BURST_SHOTS

	var distance: float = boss_unit.global_position.distance_to(target.global_position)
	var aim_error: float = FINAL_BOSS_FAIR_AIM_ERROR_NEAR

	if distance > 110.0:
		aim_error = FINAL_BOSS_FAIR_AIM_ERROR_MID

	for i in range(shot_count):
		spawn_final_boss_gun_bullet(target, aim_error)

	print("FINAL BOSS ATTACK: Rifle Burst")



func can_final_boss_damage_player() -> bool:
	if selected_game_mode != GAME_MODE_FINAL_BOSS:
		return true

	return final_boss_player_damage_cooldown_timer <= 0.0



func start_final_boss_player_damage_cooldown() -> void:
	final_boss_player_damage_cooldown_timer = FINAL_BOSS_PLAYER_DAMAGE_COOLDOWN



func get_final_boss_attack_target(default_target: Node3D, distance_to_default: float) -> Node3D:
	var candidates: Array[Node3D] = []
	var player_candidate: Node3D = null

	if player != null and is_instance_valid(player) and not is_player_dead():
		var player_distance: float = boss_unit.global_position.distance_to(player.global_position) if boss_unit != null and is_instance_valid(boss_unit) else 999999.0

		if player_distance <= FINAL_BOSS_MAX_GUN_RANGE:
			player_candidate = player

	for unit in blue_units:
		if not is_valid_target(unit):
			continue

		var blue_distance: float = boss_unit.global_position.distance_to(unit.global_position) if boss_unit != null and is_instance_valid(boss_unit) else 999999.0

		if blue_distance <= FINAL_BOSS_MAX_GUN_RANGE:
			for i in range(FINAL_BOSS_ATTACK_BLUE_WEIGHT):
				candidates.append(unit)

	if player_candidate != null:
		for i in range(FINAL_BOSS_ATTACK_PLAYER_WEIGHT):
			candidates.append(player_candidate)

	if candidates.is_empty():
		return default_target

	var picked_index: int = rng.randi_range(0, candidates.size() - 1)
	return candidates[picked_index]



func damage_final_boss_from_blue_cpu(headshot: bool = false) -> void:
	if selected_game_mode != GAME_MODE_FINAL_BOSS:
		return

	if boss_unit == null or not is_instance_valid(boss_unit):
		return

	if final_boss_current_hp <= FINAL_BOSS_PLAYER_FINISH_HP:
		print("BLUE CPU HIT BOSS: blocked at final player-only HP gate.")
		return

	var cpu_damage: int = FINAL_BOSS_BLUE_HELP_DAMAGE

	if headshot:
		cpu_damage = min(FINAL_BOSS_BLUE_HELP_DAMAGE * 2, FINAL_BOSS_MAX_DAMAGE_PER_PLAYER_HIT)

	var new_hp: int = max(final_boss_current_hp - cpu_damage, FINAL_BOSS_PLAYER_FINISH_HP)
	final_boss_current_hp = new_hp
	boss_unit.set_meta("health", final_boss_current_hp)
	boss_unit.set_meta("dead", false)
	update_boss_health_ui()
	play_unit_sound(boss_unit, "HurtAudio")
	print("BLUE CPU HIT BOSS: -", cpu_damage, " HP. Boss HP left: ", final_boss_current_hp)



func unlock_final_boss_completion_rewards() -> void:
	final_boss_reward_power_unlocked = true
	boss_mode_unlocked = true
	money = max(money, 999999)

	for upgrade_id in upgrade_data.keys():
		var upgrade_info: Dictionary = upgrade_data[upgrade_id]
		upgrade_levels[upgrade_id] = int(upgrade_info.get("max_level", int(upgrade_levels.get(upgrade_id, 0))))

	achievement_seen["final_boss"] = true
	achievement_unlocked["final_boss"] = true
	apply_all_upgrades()

	if player != null and is_instance_valid(player) and player.has_method("enable_final_boss_reward_power_mode"):
		player.call("enable_final_boss_reward_power_mode")

	save_shop_data()
	print("FINAL BOSS COMPLETION REWARDS SAVED.")



func is_final_boss_victory_result() -> bool:
	return selected_game_mode == GAME_MODE_FINAL_BOSS and game_result.begins_with("VICTORY")



func fade_out_all_audio(seconds: float = FINAL_BOSS_END_FADE_SECONDS) -> void:
	var audio_nodes: Array[Node] = []
	collect_audio_nodes_recursive(get_tree().root, audio_nodes)

	for node in audio_nodes:
		if node is AudioStreamPlayer:
			var p: AudioStreamPlayer = node as AudioStreamPlayer
			var tween: Tween = create_tween()
			tween.tween_property(p, "volume_db", -80.0, seconds)
		elif node is AudioStreamPlayer2D:
			var p2: AudioStreamPlayer2D = node as AudioStreamPlayer2D
			var tween2: Tween = create_tween()
			tween2.tween_property(p2, "volume_db", -80.0, seconds)
		elif node is AudioStreamPlayer3D:
			var p3: AudioStreamPlayer3D = node as AudioStreamPlayer3D
			var tween3: Tween = create_tween()
			tween3.tween_property(p3, "volume_db", -80.0, seconds)



func collect_audio_nodes_recursive(root: Node, output: Array[Node]) -> void:
	if root == null:
		return

	if root is AudioStreamPlayer or root is AudioStreamPlayer2D or root is AudioStreamPlayer3D:
		output.append(root)

	for child in root.get_children():
		collect_audio_nodes_recursive(child, output)



func save_and_close_after_finale() -> void:
	if final_boss_finale_quit_started:
		return

	final_boss_finale_quit_started = true
	unlock_final_boss_completion_rewards()
	save_shop_data()
	fade_out_all_audio(1.50)
	show_final_completion_blackout()

func get_final_boss_credits_text() -> String:
	var lines: Array[String] = []

	lines.append("You reached the end of Mountain Laser Tag.")
	lines.append("")
	lines.append("The final boss is defeated. The mountain is quiet. The last laser fades into the dark, and the fight that started as a simple match has become the end of the game.")
	lines.append("")
	lines.append("This was not just another round. You fought through the teams, the modes, the upgrades, the chaos, and the final battle. You made it to the last part of the game and finished it.")
	lines.append("")
	lines.append("Thank you for playing all the way to the end.")
	lines.append("")
	lines.append("CREDITS")
	lines.append("Created by Lol123rl")
	lines.append("Game concept, battles, upgrades, boss fight, and final showdown by Lol123rl")
	lines.append("")
	lines.append("COMPLETION REWARD")
	lines.append("Your completion reward has been saved.")
	lines.append("When you reopen the game, you will have overpowered mode:")
	lines.append("• Near-infinite ammo")
	lines.append("• Very fast firing")
	lines.append("• Huge stamina")
	lines.append("• Fast reload")
	lines.append("• Maxed upgrades")
	lines.append("")
	lines.append("This save marks that you beat the final part of the game.")
	lines.append("")
	lines.append("Press SAVE & FINISH to save your completion and fade to the final black screen.")

	return "\n".join(lines)



func show_final_boss_ending_credits() -> void:
	if final_boss_credits_active:
		return

	final_boss_credits_active = true
	final_boss_finale_quit_started = false

	unlock_final_boss_completion_rewards()
	fade_out_all_audio(FINAL_BOSS_END_FADE_SECONDS)

	if result_panel != null:
		result_panel.visible = false

	if result_art_panel != null:
		result_art_panel.visible = false

	if simple_fireworks_panel != null:
		simple_fireworks_panel.visible = false

	if final_boss_credits_layer != null and is_instance_valid(final_boss_credits_layer):
		final_boss_credits_layer.queue_free()

	final_boss_credits_layer = CanvasLayer.new()
	final_boss_credits_layer.name = "FinalBossCreditsLayer"
	final_boss_credits_layer.layer = 260
	add_child(final_boss_credits_layer)

	final_boss_credits_root = Control.new()
	final_boss_credits_root.name = "FinalBossCreditsRoot"
	final_boss_credits_root.anchor_left = 0.0
	final_boss_credits_root.anchor_top = 0.0
	final_boss_credits_root.anchor_right = 1.0
	final_boss_credits_root.anchor_bottom = 1.0
	final_boss_credits_root.mouse_filter = Control.MOUSE_FILTER_STOP
	final_boss_credits_layer.add_child(final_boss_credits_root)

	var background: ColorRect = ColorRect.new()
	background.anchor_left = 0.0
	background.anchor_top = 0.0
	background.anchor_right = 1.0
	background.anchor_bottom = 1.0
	background.color = Color(0.005, 0.006, 0.014, 1.0)
	final_boss_credits_root.add_child(background)

	var panel: PanelContainer = PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -560.0
	panel.offset_right = 560.0
	panel.offset_top = -330.0
	panel.offset_bottom = 330.0
	panel.add_theme_stylebox_override("panel", make_panel_style(Color(0.02, 0.025, 0.04, 0.96), Color(0.30, 0.75, 1.0, 0.95), 3))
	final_boss_credits_root.add_child(panel)

	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	panel.add_child(box)

	var title: Label = Label.new()
	title.text = FINAL_BOSS_CREDITS_TITLE
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color(0.85, 0.95, 1.0, 1.0))
	box.add_child(title)

	var body: Label = Label.new()
	body.text = get_final_boss_credits_text()
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 19)
	body.add_theme_color_override("font_color", Color(0.86, 0.91, 0.96, 1.0))
	body.custom_minimum_size = Vector2(1040.0, 460.0)
	box.add_child(body)

	final_boss_credits_button = Button.new()
	final_boss_credits_button.text = "SAVE & FINISH"
	final_boss_credits_button.custom_minimum_size = Vector2(280.0, 54.0)
	final_boss_credits_button.pressed.connect(save_and_close_after_finale)
	box.add_child(final_boss_credits_button)

	print("FINAL BOSS ENDING CREDITS OPENED.")



func get_player_elimination_money_reward(headshot: bool, from_helicopter: bool = false) -> int:
	var reward: int = 0

	if selected_game_mode == GAME_MODE_ELIMINATION:
		reward = MONEY_TEAM_ELIMINATION_ELIMINATION
		if headshot:
			reward += MONEY_TEAM_ELIMINATION_HEADSHOT_BONUS
	elif selected_game_mode == GAME_MODE_CTF:
		reward = MONEY_CTF_DEFENSE_ELIMINATION
	elif selected_game_mode == GAME_MODE_COMMANDER:
		reward = MONEY_COMMANDER_ELIMINATION
	elif selected_game_mode == GAME_MODE_KING_HILL:
		reward = MONEY_HILL_ELIMINATION
	elif selected_game_mode == GAME_MODE_FINAL_BOSS:
		reward = 0
	elif selected_game_mode == GAME_MODE_MANHUNT:
		# Manhunt should reward escaping or finding the hunted target, not farming eliminations.
		reward = 0

	if from_helicopter and reward > 0:
		reward += MONEY_HELICOPTER_BONUS

	return reward



func update_lifetime_elimination_achievements() -> void:
	if lifetime_eliminations >= 100:
		unlock_achievement("hundred_elims")

	if lifetime_eliminations >= 500:
		unlock_achievement("five_hundred_elims")

	if lifetime_team_elimination_eliminations >= 25:
		unlock_achievement("team_elim_25_elims")



func award_manhunt_hunter_victory_money() -> void:
	if selected_game_mode != GAME_MODE_MANHUNT:
		return

	if manhunt_hunted_team != "red":
		return

	var time_used: float = MANHUNT_TIME_LIMIT - match_time_remaining
	var time_ratio_left: float = clamp(match_time_remaining / MANHUNT_TIME_LIMIT, 0.0, 1.0)
	var bonus: int = int(float(MONEY_MANHUNT_FAST_HUNT_TIME_BONUS_MAX) * time_ratio_left)
	var total_reward: int = MONEY_MANHUNT_FAST_HUNT_BASE + bonus

	lifetime_manhunt_hunts_won += 1
	award_money("Fast Manhunt win", total_reward)

	if time_used <= 90.0:
		unlock_achievement("fast_hunter")



func show_final_completion_blackout() -> void:
	final_completion_blackout_active = true

	if final_completion_blackout_layer != null and is_instance_valid(final_completion_blackout_layer):
		final_completion_blackout_layer.queue_free()

	final_completion_blackout_layer = CanvasLayer.new()
	final_completion_blackout_layer.name = "FinalCompletionBlackoutLayer"
	final_completion_blackout_layer.layer = 400
	add_child(final_completion_blackout_layer)

	var root: Control = Control.new()
	root.anchor_left = 0.0
	root.anchor_top = 0.0
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	root.modulate.a = 0.0
	final_completion_blackout_layer.add_child(root)

	var background: ColorRect = ColorRect.new()
	background.anchor_left = 0.0
	background.anchor_top = 0.0
	background.anchor_right = 1.0
	background.anchor_bottom = 1.0
	background.color = Color(0.0, 0.0, 0.0, 1.0)
	root.add_child(background)

	final_completion_blackout_label = Label.new()
	final_completion_blackout_label.anchor_left = 0.5
	final_completion_blackout_label.anchor_right = 0.5
	final_completion_blackout_label.anchor_top = 0.5
	final_completion_blackout_label.anchor_bottom = 0.5
	final_completion_blackout_label.offset_left = -420.0
	final_completion_blackout_label.offset_right = 420.0
	final_completion_blackout_label.offset_top = -80.0
	final_completion_blackout_label.offset_bottom = 80.0
	final_completion_blackout_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	final_completion_blackout_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	final_completion_blackout_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	final_completion_blackout_label.add_theme_font_size_override("font_size", 28)
	final_completion_blackout_label.add_theme_color_override("font_color", Color(0.90, 0.94, 1.0, 1.0))
	final_completion_blackout_label.text = "Game saved.\nThank you for playing Mountain Laser Tag.\nYou may now close this tab."
	root.add_child(final_completion_blackout_label)

	var tween: Tween = create_tween()
	tween.tween_property(root, "modulate:a", 1.0, 1.25)



func set_title_buttons_visible_for_brief(show_buttons: bool) -> void:
	if title_start_button != null:
		title_start_button.visible = show_buttons
	if title_shop_button != null:
		title_shop_button.visible = show_buttons
	if title_achievements_button != null:
		title_achievements_button.visible = show_buttons
	if title_reset_progress_button != null:
		title_reset_progress_button.visible = show_buttons
	if title_mode_button != null:
		title_mode_button.visible = show_buttons
	if title_quit_button != null:
		title_quit_button.visible = show_buttons
