extends Node3D

@export var rotate_sensitivity: float = 0.005
@export var zoom_speed: float = 0.001
@export var min_pitch: float = -80.0
@export var max_pitch: float = 80.0

signal tile_placed(player: bool)

@onready var queen = get_parent().get_node_or_null("TileSelectorUI/Queen")
@onready var voice = get_parent().get_node_or_null("Audio/QueenVoice")

@export var on_screen_pos: Vector2 = Vector2(600, 300)
@export var off_screen_pos: Vector2 = Vector2(1800, 300)

var yaw: float = 0.0
var pitch: float = 0.0
var touches := {}
var last_pinch_dist: float = 0.0

@onready var cam: Camera3D = $Camera3D
@onready var tile_ui: Control = get_parent().get_node_or_null("TileSelectorUI")
@onready var losepopup: Control = get_parent().get_node_or_null("TileSelectorUI/LosePopup")
@onready var winpopup: Control = get_parent().get_node_or_null("TileSelectorUI/WinPopup")
@onready var losemainmenu: Control = get_parent().get_node_or_null("TileSelectorUI/LosePopup/MainMenuButton")
@onready var loserestart: Control = get_parent().get_node_or_null("TileSelectorUI/LosePopup/RestartButton")
@onready var winmainmenu: Control = get_parent().get_node_or_null("TileSelectorUI/WinPopup/MainMenuButton")
@onready var winrestart: Control = get_parent().get_node_or_null("TileSelectorUI/WinPopup/RestartButton")
@onready var scoreai: Control = get_parent().get_node_or_null("TileSelectorUI/ScoreAI/Score")
@onready var scoreyou: Control = get_parent().get_node_or_null("TileSelectorUI/ScoreYou/Score")

var selected_scene: PackedScene = null
var occupied_cells: Dictionary = {}
var placed_scenes := []
@export var total_tiles: int = 0

const GRID_SIZE_X = 90.0
const GRID_SIZE_Z = 90.0
const GRID_DIM_X = 7
const GRID_DIM_Z = 11
const GRID_ORIGIN = Vector3(50, 0, -130)

var player_score: int = 0
var ai_score: int = 0
var default_cam_transform: Transform3D

@onready var sfx_tile_placement: AudioStreamPlayer2D = get_tree().current_scene.get_node("Audio/PlaceTileSound")
@onready var sfx_button_click: AudioStreamPlayer2D = get_tree().current_scene.get_node("Audio/ClickSound")
@onready var sfx_victory: AudioStreamPlayer2D = get_tree().current_scene.get_node("Audio/VictorySound")
@onready var sfx_defeat: AudioStreamPlayer2D = get_tree().current_scene.get_node("Audio/DefeatSound")
@onready var sfx_background: AudioStreamPlayer2D = get_tree().current_scene.get_node("Audio/BattleMusicPlayer")
@onready var sfx_start: AudioStreamPlayer2D = get_tree().current_scene.get_node("Audio/BattleStartMusic")

var scenes = [
	"res://scenes/r1/11.tscn", "res://scenes/r1/12.tscn", "res://scenes/r1/13.tscn",
	"res://scenes/r1/14.tscn", "res://scenes/r1/15.tscn", "res://scenes/r1/16.tscn",
	"res://scenes/r1/17.tscn", "res://scenes/r2/21.tscn", "res://scenes/r2/22.tscn",
	"res://scenes/r2/23.tscn", "res://scenes/r2/24.tscn", "res://scenes/r2/25.tscn",
	"res://scenes/r2/26.tscn", "res://scenes/r2/27.tscn", "res://scenes/r3/31.tscn",
	"res://scenes/r3/32.tscn", "res://scenes/r3/33.tscn", "res://scenes/r3/34.tscn",
	"res://scenes/r3/35.tscn", "res://scenes/r3/36.tscn", "res://scenes/r3/37.tscn",
	"res://scenes/r4/41.tscn", "res://scenes/r4/42.tscn", "res://scenes/r4/43.tscn",
	"res://scenes/r4/44.tscn", "res://scenes/r4/45.tscn", "res://scenes/r4/46.tscn",
	"res://scenes/r4/47.tscn", "res://scenes/r5/51.tscn", "res://scenes/r5/52.tscn",
	"res://scenes/r5/53.tscn", "res://scenes/r5/54.tscn", "res://scenes/r5/55.tscn",
	"res://scenes/r5/56.tscn", "res://scenes/r5/57.tscn", "res://scenes/r6/61.tscn",
	"res://scenes/r6/62.tscn", "res://scenes/r6/63.tscn", "res://scenes/r6/64.tscn",
	"res://scenes/r6/65.tscn", "res://scenes/r6/66.tscn", "res://scenes/r6/67.tscn",
	"res://scenes/r7/71.tscn", "res://scenes/r7/72.tscn", "res://scenes/r7/73.tscn",
	"res://scenes/r7/74.tscn", "res://scenes/r7/75.tscn", "res://scenes/r7/76.tscn",
	"res://scenes/r7/77.tscn", "res://scenes/r8/81.tscn", "res://scenes/r8/82.tscn",
	"res://scenes/r8/83.tscn", "res://scenes/r8/84.tscn", "res://scenes/r8/85.tscn",
	"res://scenes/r8/86.tscn", "res://scenes/r8/87.tscn", "res://scenes/r9/91.tscn",
	"res://scenes/r9/92.tscn", "res://scenes/r9/93.tscn", "res://scenes/r9/94.tscn",
	"res://scenes/r9/95.tscn", "res://scenes/r9/96.tscn", "res://scenes/r9/97.tscn",
	"res://scenes/r10/101.tscn", "res://scenes/r10/102.tscn", "res://scenes/r10/103.tscn",
	"res://scenes/r10/104.tscn", "res://scenes/r10/105.tscn", "res://scenes/r10/106.tscn",
	"res://scenes/r10/107.tscn", "res://scenes/r11/111.tscn", "res://scenes/r11/112.tscn",
	"res://scenes/r11/113.tscn", "res://scenes/r11/114.tscn", "res://scenes/r11/115.tscn",
	"res://scenes/r11/116.tscn", "res://scenes/r11/117.tscn"
]

# City definitions: each city maps to tile coordinates
var cities = {
	"C1": [[0,0],[0,1],[1,0],[1,1]],
	"C2": [[0,2],[0,3],[0,4],[0,5],[1,2],[1,3],[1,4],[1,5]],
	"C3": [[0,6],[1,6],[2,6],[3,6],[3,5],[4,5],[4,6]],
	"C4": [[4,4],[4,5],[4,6],[5,5],[5,6]],
	"C5": [[1,0],[2,0],[2,1]],
	"C6": [[6,1],[7,1],[7,2]],
	"C7": [[6,2],[7,2],[6,3],[7,3],[7,4],[8,3]],
	"C8": [[7,2],[7,3],[8,2],[8,3]],
	"C9": [[8,2],[8,3],[9,2],[9,3]],
	"C10": [[7,0],[7,1],[8,0],[8,1],[8,2],[9,1],[9,2],[10,0],[10,1],[10,2],[10,3]],
	"C11": [[7,5],[7,6],[8,5],[8,6]],
	"C12": [[8,4],[8,5],[8,6],[9,3],[9,4],[9,5],[9,6],[10,4],[10,5],[10,6],[10,3]]
}

const MAX_DEPTH = 4  # Adjust for difficulty (higher = smarter but slower)

func _on_tile_placed(player: bool) -> void:
	# Score is only updated when cities are completed, not on every tile
	_check_game_end()

func _update_score_labels() -> void:
	scoreyou.text = str(player_score)
	scoreai.text = str(ai_score)

func _check_game_end() -> void:
	# Count total tiles placed
	var tiles_placed = occupied_cells.size()
	
	# Game ends only when all tiles are placed
	if tiles_placed >= GRID_DIM_X * GRID_DIM_Z:
		if player_score > ai_score:
			sfx_victory.play()
			_show_win_popup()
		elif ai_score > player_score:
			sfx_defeat.play()
			_show_lose_popup()
		else:
			# It's a tie - you can decide how to handle this
			sfx_victory.play()
			_show_win_popup()

func _show_win_popup() -> void:
	if winpopup:
		winpopup.visible = true
		winrestart.connect("pressed", Callable(self, "_on_restart_pressed"))
		winmainmenu.connect("pressed", Callable(self, "_on_main_menu_pressed"))

func _show_lose_popup() -> void:
	if losepopup:
		losepopup.visible = true
		loserestart.connect("pressed", Callable(self, "_on_restart_pressed"))
		losemainmenu.connect("pressed", Callable(self, "_on_main_menu_pressed"))

func _on_restart_pressed():
	get_tree().reload_current_scene()

func _on_main_menu_pressed():
	get_tree().change_scene_to_file("res://scenes/Home.tscn")

func set_total_tiles(count: int) -> void:
	total_tiles = count

func play_queen_intro():
	var tween = create_tween()
	voice.volume_db = 10
	tween.tween_property(queen, "position", on_screen_pos, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func (): voice.play())
	tween.tween_interval(voice.stream.get_length())
	tween.tween_property(queen, "position", off_screen_pos, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
func _ready():
	winpopup.visible = false
	losepopup.visible = false
	queen.position = off_screen_pos
	play_queen_intro()
	
	if tile_ui and "tile_scenes" in tile_ui:
		scenes = tile_ui.tile_scenes.duplicate()
		total_tiles = scenes.size()
		tile_ui.connect("tile_selected", Callable(self, "_on_tile_selected"))
	else:
		print("⚠️ TileSelectorUI not found or missing tile_scenes")

	default_cam_transform = cam.global_transform

	if sfx_background:
		sfx_background.volume_db = -5
		sfx_background.play()
	if sfx_start:
		sfx_start.volume_db = -2
		sfx_start.play()

func _get_snapped_position(row: int, col: int) -> Vector3:
	var grid_x = col - 1
	var grid_z = row - 1
	return Vector3(grid_x * GRID_SIZE_X + GRID_ORIGIN.x, 0, grid_z * GRID_SIZE_Z + GRID_ORIGIN.z)
	
func _get_cell_key(row: int, col: int) -> String:
	var grid_x = col - 1
	var grid_z = row - 1
	return "%d,%d" % [grid_x, grid_z]
	
func _remove_tile_button(scene_path: String) -> void:
	if tile_ui and tile_ui.has_method("remove_tile_button"):
		tile_ui.remove_tile_button(scene_path)
		
func focus_camera_on_tile(tile: Node3D, duration: float = 0.5, hold_time: float = 1.5):
	if not is_instance_valid(tile):
		return
	var target_pos = tile.global_transform.origin
	var offset = Vector3(-50, 200, 0)
	var tween = create_tween()
	tween.tween_property(cam, "global_transform:origin", target_pos + offset, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
func _return_camera_to_default():
	var tween = create_tween()
	tween.tween_property(cam, "global_transform:origin", default_cam_transform.origin, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_tile_selected(tile_path: String) -> void:
	if not ResourceLoader.exists(tile_path):
		print("⚠️ Scene missing:", tile_path)
		return

	selected_scene = load(tile_path)
	print("🎯 Player selected:", tile_path)

	var row_col = _get_row_col_from_scene(tile_path)
	if row_col.size() == 0:
		print("⚠️ Failed to parse row/col from:", tile_path)
		return

	var row = int(row_col["row"])
	var col = int(row_col["col"])
	var cell_key = _get_cell_key(row, col)

	if occupied_cells.has(cell_key):
		print("🚫 Cell already occupied:", cell_key)
		return

	var snapped_pos = _get_snapped_position(row, col)
	var tile = selected_scene.instantiate()
	get_tree().current_scene.add_child(tile)
	tile.global_transform.origin = snapped_pos

	occupied_cells[cell_key] = tile
	placed_scenes.append(tile_path)
	player_score += 1
	_update_score_labels()

	print("✅ Player placed tile at:", snapped_pos)
	sfx_tile_placement.play()
	focus_camera_on_tile(tile)

	var timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = 1.0
	timer.connect("timeout", Callable(self, "_place_ai_tile"))
	add_child(timer)
	timer.start()

	_check_game_end()

func _get_row_col_from_scene(scene_path: String) -> Dictionary:
	var regex = RegEx.new()
	regex.compile("r(\\d+)/([0-9]+)\\.tscn")
	var match = regex.search(scene_path)
	if not match:
		return {}
	var row = int(match.get_string(1))
	var col = int(match.get_string(2)) % 10
	return {"row": row, "col": col}

# === MINIMAX WITH ALPHA-BETA PRUNING ===

# Check which cities would be completed by placing a tile at (row, col)
func _check_city_completion(state: Dictionary, row: int, col: int) -> Array:
	var completed = []
	for city_name in cities.keys():
		var tiles = cities[city_name]
		var all_placed = true
		for tile_coord in tiles:
			var r = tile_coord[0]
			var c = tile_coord[1]
			var key = "%d,%d" % [r, c]
			if not state["occupied"].has(key) and not (r == row and c == col):
				all_placed = false
				break
		if all_placed:
			if not state["completed_cities"].has(city_name):
				completed.append(city_name)
	return completed

# Evaluate board state for AI
func _evaluate_state(state: Dictionary) -> int:
	return state["ai_score"] - state["player_score"]

# Get all available moves (free cells)
func _get_available_moves(state: Dictionary) -> Array:
	var moves = []
	for row in range(GRID_DIM_Z):
		for col in range(GRID_DIM_X):
			var key = "%d,%d" % [row, col]
			if not state["occupied"].has(key):
				moves.append({"row": row, "col": col})
	return moves

# Minimax with alpha-beta pruning
func _minimax(state: Dictionary, depth: int, alpha: float, beta: float, is_maximizing: bool) -> Dictionary:
	var moves = _get_available_moves(state)
	
	# Terminal conditions
	if depth == 0 or moves.size() == 0:
		return {"score": _evaluate_state(state), "move": null}
	
	if is_maximizing:
		var max_eval = -INF
		var best_move = null
		
		for move in moves:
			var new_state = _simulate_move(state, move["row"], move["col"], true)
			var eval_result = _minimax(new_state, depth - 1, alpha, beta, false)
			
			if eval_result["score"] > max_eval:
				max_eval = eval_result["score"]
				best_move = move
			
			alpha = max(alpha, eval_result["score"])
			if beta <= alpha:
				break  # Beta cutoff
		
		return {"score": max_eval, "move": best_move}
	else:
		var min_eval = INF
		var best_move = null
		
		for move in moves:
			var new_state = _simulate_move(state, move["row"], move["col"], false)
			var eval_result = _minimax(new_state, depth - 1, alpha, beta, true)
			
			if eval_result["score"] < min_eval:
				min_eval = eval_result["score"]
				best_move = move
			
			beta = min(beta, eval_result["score"])
			if beta <= alpha:
				break  # Alpha cutoff
		
		return {"score": min_eval, "move": best_move}

# Simulate placing a tile and return new state
func _simulate_move(state: Dictionary, row: int, col: int, is_ai: bool) -> Dictionary:
	var new_state = {
		"occupied": state["occupied"].duplicate(),
		"completed_cities": state["completed_cities"].duplicate(),
		"ai_score": state["ai_score"],
		"player_score": state["player_score"]
	}
	
	var key = "%d,%d" % [row, col]
	new_state["occupied"][key] = true
	
	var completed = _check_city_completion(new_state, row, col)
	for city_name in completed:
		var city_size = cities[city_name].size()
		var score_gained = city_size * 5  # 5x multiplier
		if is_ai:
			new_state["ai_score"] += score_gained
		else:
			new_state["player_score"] += score_gained
		new_state["completed_cities"][city_name] = true
	
	return new_state

# AI tile placement using minimax
func _place_ai_tile():
	sfx_tile_placement.play()
	
	# Build current game state
	var current_state = {
		"occupied": occupied_cells.duplicate(),
		"completed_cities": {},
		"ai_score": ai_score,
		"player_score": player_score
	}
	
	# Find best move using minimax
	var result = _minimax(current_state, MAX_DEPTH, -INF, INF, true)
	var best_move = result["move"]
	
	if not best_move:
		print("No available moves for AI!")
		return
	
	var row = best_move["row"]
	var col = best_move["col"]
	var cell_key = "%d,%d" % [row, col]
	
	# Convert grid coords to scene path
	var tile_num = (row + 1) * 10 + (col + 1)
	var scene_path = "res://scenes/r%d/%d.tscn" % [row + 1, tile_num]
	
	if scene_path in placed_scenes or not ResourceLoader.exists(scene_path):
		var available = []
		for s in scenes:
			if s not in placed_scenes:
				available.append(s)
		if available.size() == 0:
			print("No unplaced scenes left for AI!")
			return
		scene_path = available[randi() % available.size()]
	
	var ai_tile_scene = load(scene_path)
	if not ai_tile_scene:
		print("⚠️ Missing AI scene:", scene_path)
		return
	
	var ai_tile = ai_tile_scene.instantiate()
	get_tree().current_scene.add_child(ai_tile)
	ai_tile.global_transform.origin = _get_snapped_position(row + 1, col + 1)
	
	occupied_cells[cell_key] = ai_tile
	placed_scenes.append(scene_path)
	
	# Check for city completion and update score
	var completed = _check_city_completion(current_state, row, col)
	for city_name in completed:
		var score_gained = cities[city_name].size() * 5  # 5x multiplier
		ai_score += score_gained
	
	_update_score_labels()
	call_deferred("_remove_tile_button", scene_path)
	
	print("🤖 AI placed tile at:", ai_tile.global_transform.origin, "Cities completed:", completed.size())
	
	emit_signal("tile_placed", false)
	focus_camera_on_tile(ai_tile)
	
	var cam_reset_timer = Timer.new()
	cam_reset_timer.one_shot = true
	cam_reset_timer.wait_time = 1.0
	cam_reset_timer.connect("timeout", Callable(self, "_return_camera_to_default"))
	add_child(cam_reset_timer)
	cam_reset_timer.start()
	
	_check_game_end()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			touches[event.index] = event.position
		else:
			touches.erase(event.index)
			last_pinch_dist = 0.0

	elif event is InputEventScreenDrag:
		touches[event.index] = event.position

		if touches.size() == 1:
			var drag = event.relative
			yaw   -= drag.x * rotate_sensitivity
			pitch -= drag.y * rotate_sensitivity
			pitch = clamp(pitch, min_pitch, max_pitch)
			rotation_degrees = Vector3(pitch, yaw, 0)

		elif touches.size() == 2:
			var points = touches.values()
			var dist = points[0].distance_to(points[1])
			if last_pinch_dist > 0:
				var delta = dist - last_pinch_dist
				cam.translate_local(Vector3(0, 0, -delta * zoom_speed))
			last_pinch_dist = dist

	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		yaw   -= event.relative.x * rotate_sensitivity * 0.5
		pitch -= event.relative.y * rotate_sensitivity * 0.5
		pitch = clamp(pitch, min_pitch, max_pitch)
		rotation_degrees = Vector3(pitch, yaw, 0)

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
		cam.translate_local(Vector3(0, 0, -zoom_speed * 100))
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
		cam.translate_local(Vector3(0, 0, zoom_speed * 100))
