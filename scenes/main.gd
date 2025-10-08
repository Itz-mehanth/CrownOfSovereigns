extends Node3D


@export var rotate_sensitivity: float = 0.005
@export var zoom_speed: float = 0.001
@export var min_pitch: float = -80.0
@export var max_pitch: float = 80.0

signal tile_placed(player: bool)

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
@export var total_tiles: int = 0  # will be set from the scene

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

func _on_tile_placed(player: bool) -> void:
	if player:
		player_score += 1
	else:
		ai_score += 1
	_update_score_labels()
	_check_game_end()

func _update_score_labels() -> void:
	scoreyou.text = str(player_score)
	scoreai.text = str(ai_score)

func _check_game_end() -> void:
	if player_score + ai_score >= total_tiles:
		if player_score > ai_score:
			sfx_victory.play()
			_show_win_popup()
		else:
			sfx_defeat.play()
			_show_lose_popup()

# Show Win popup
func _show_win_popup() -> void:
	if winpopup:
		winpopup.visible = true
		# Connect buttons
		winrestart.connect("pressed", Callable(self, "_on_restart_pressed"))
		winmainmenu.connect("pressed", Callable(self, "_on_main_menu_pressed"))

# Show Lose popup
func _show_lose_popup() -> void:
	if losepopup:
		losepopup.visible = true
		# Connect buttons
		loserestart.connect("pressed", Callable(self, "_on_restart_pressed"))
		losemainmenu.connect("pressed", Callable(self, "_on_main_menu_pressed"))

func _on_restart_pressed():
	get_tree().reload_current_scene()

func _on_main_menu_pressed():
	get_tree().change_scene_to_file("res://scenes/Home.tscn")

func set_total_tiles(count: int) -> void:
	total_tiles = count

func _ready():
	winpopup.visible = false
	losepopup.visible = false
	# Initialize scene list from UI
	if tile_ui and "tile_scenes" in tile_ui:
		scenes = tile_ui.tile_scenes.duplicate()
		total_tiles = scenes.size()
		tile_ui.connect("tile_selected", Callable(self, "_on_tile_selected"))
	else:
		print("⚠️ TileSelectorUI not found or missing tile_scenes")

	default_cam_transform = cam.global_transform

	# Play music if nodes exist
	if sfx_background:
		sfx_background.volume_db = -5
		sfx_background.play()
	if sfx_start:
		sfx_start.volume_db = -2
		sfx_start.play()


func _get_snapped_position(row: int, col: int) -> Vector3:
	var grid_x = col - 1
	var grid_z = row - 1
	return Vector3(
		grid_x * GRID_SIZE_X + GRID_ORIGIN.x,
		0,
		grid_z * GRID_SIZE_Z + GRID_ORIGIN.z
	)
	
# Unified key for occupied cells
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
	var offset = Vector3(-50, 200, 0)  # adjust camera height/distance
	var tween = create_tween()
	
	# Move camera to tile
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

	# Place player tile
	var snapped_pos = _get_snapped_position(row, col)
	var tile = selected_scene.instantiate()
	get_tree().current_scene.add_child(tile)
	tile.global_transform.origin = snapped_pos

	# Track placement
	occupied_cells[cell_key] = tile
	placed_scenes.append(tile_path)
	player_score += 1
	_update_score_labels()

	print("✅ Player placed tile at:", snapped_pos)
	sfx_tile_placement.play()

	# Focus camera
	focus_camera_on_tile(tile)

	# Schedule AI tile placement
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
	
# --- Inside _place_ai_tile (AI tile placement) ---
func _place_ai_tile():
	sfx_tile_placement.play()
	
	# Build list of free cells
	var free_cells := []
	for row in range(1, GRID_DIM_Z + 1):
		for col in range(1, GRID_DIM_X + 1):
			var key = _get_cell_key(row, col)
			if not occupied_cells.has(key):
				free_cells.append({"row": row, "col": col, "key": key})

	if free_cells.size() == 0:
		print("No free cells for AI!")
		return

	var cell = free_cells[randi() % free_cells.size()]
	var row = int(cell["row"])
	var col = int(cell["col"])
	var cell_key = _get_cell_key(row, col)

	# Pick tile for AI
	var tile_num = (row) * 10 + (col)
	var scene_path = "res://scenes/r%d/%d.tscn" % [row, tile_num]
	if scene_path in placed_scenes:
		var available_scenes := []
		for s in scenes:
			if s not in placed_scenes:
				available_scenes.append(s)
		if available_scenes.size() == 0:
			print("No unplaced scenes left for AI!")
			return
		scene_path = available_scenes[randi() % available_scenes.size()]

	var ai_tile_scene = load(scene_path)
	if not ai_tile_scene:
		print("⚠️ Missing AI scene:", scene_path)
		return

	var ai_tile = ai_tile_scene.instantiate()
	get_tree().current_scene.add_child(ai_tile)
	ai_tile.global_transform.origin = _get_snapped_position(row, col)

	occupied_cells[cell_key] = ai_tile
	placed_scenes.append(scene_path)

	call_deferred("_remove_tile_button", scene_path)
	print("🤖 AI placed tile at:", ai_tile.global_transform.origin, "Scene:", scene_path)

	# Update AI score & emit signal
	ai_score += 1
	_update_score_labels()
	emit_signal("tile_placed", false)
	
	focus_camera_on_tile(ai_tile)


	_check_game_end()

func _input(event: InputEvent) -> void:
	# --- TOUCH INPUT ---
	if event is InputEventScreenTouch:
		if event.pressed:
			touches[event.index] = event.position
		else:
			touches.erase(event.index)
			last_pinch_dist = 0.0

	elif event is InputEventScreenDrag:
		touches[event.index] = event.position

		if touches.size() == 1:
			# One finger → rotate camera
			var drag = event.relative
			yaw   -= drag.x * rotate_sensitivity
			pitch -= drag.y * rotate_sensitivity
			pitch = clamp(pitch, min_pitch, max_pitch)
			rotation_degrees = Vector3(pitch, yaw, 0)

		elif touches.size() == 2:
			# Two fingers → pinch zoom
			var points = touches.values()
			var dist = points[0].distance_to(points[1])
			if last_pinch_dist > 0:
				var delta = dist - last_pinch_dist
				cam.translate_local(Vector3(0, 0, -delta * zoom_speed))
			last_pinch_dist = dist

	# --- MOUSE INPUT (optional for desktop) ---
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		yaw   -= event.relative.x * rotate_sensitivity * 0.5
		pitch -= event.relative.y * rotate_sensitivity * 0.5
		pitch = clamp(pitch, min_pitch, max_pitch)
		rotation_degrees = Vector3(pitch, yaw, 0)

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
		cam.translate_local(Vector3(0, 0, -zoom_speed * 100))
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
		cam.translate_local(Vector3(0, 0, zoom_speed * 100))
