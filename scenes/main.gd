extends Node3D

@export var rotate_sensitivity: float = 0.005
@export var zoom_speed: float = 0.005
@export var min_pitch: float = -80.0
@export var max_pitch: float = 80.0

signal tile_placed(player: bool)

@onready var queen = get_parent().get_node_or_null("TileSelectorUI/Queen")
@onready var voice = get_parent().get_node_or_null("Audio/QueenVoice")

@export var on_screen_pos: Vector2 = Vector2(600, 300)
@export var off_screen_pos: Vector2 = Vector2(1800, 300)

# --- Soldier popup assets ---
@onready var ui_layer = get_tree().root.get_node("Main/TileSelectorUI")
var soldier_texture: Texture2D = preload("res://assets/ui/soldier.png")
var soldier_voice_player: AudioStreamPlayer = AudioStreamPlayer.new()
var soldier_bgm: AudioStreamPlayer = AudioStreamPlayer.new()

var soldier_popup : TextureRect = null

var yaw: float = -90.0 # Face from length side
var pitch: float = -70.0 # More top-down view
# Center of board: GRID_ORIGIN (50, 0, -130) + Half Grid Size (315, 0, 495) = (365, 0, 365)
var orbit_center: Vector3 = Vector3(365, 0, 365) 
var orbit_radius: float = 1200.0 # Zoomed out even more (2x)
var min_zoom: float = 20.0
var max_zoom: float = 2000.0
var default_orbit_center: Vector3
var default_orbit_radius: float
var default_pitch: float
var default_yaw: float
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
@onready var map_button: Control = get_parent().get_node_or_null("TileSelectorUI/MapButton")
@onready var map_popup: Control = get_parent().get_node_or_null("TileSelectorUI/MapPopup")
@onready var close_button: Control = get_parent().get_node_or_null("TileSelectorUI/MapPopup/CloseButton")
@onready var difficulty_popup: Control = get_parent().get_node_or_null("TileSelectorUI/DifficultyPopup")
@onready var difficulty_bg: Control = difficulty_popup.get_node_or_null("Background") if difficulty_popup else null
@onready var difficulty_title: Label = difficulty_popup.get_node_or_null("TitleLabel") if difficulty_popup else null
@onready var difficulty_slider: HSlider = difficulty_popup.get_node_or_null("DifficultySlider") if difficulty_popup else null
@onready var difficulty_label: Label = difficulty_popup.get_node_or_null("ValueLabel") if difficulty_popup else null
@onready var start_button: Button = difficulty_popup.get_node_or_null("StartButton") if difficulty_popup else null

var selected_difficulty: int = 3

var selected_scene: PackedScene = null
var occupied_cells: Dictionary = {}
var placed_scenes := []
var completed_cities_global: Dictionary = {}
@export var total_tiles: int = 0

# Preview tile system
var preview_tile: Node3D = null
var preview_tile_path: String = ""
var preview_row: int = -1
var preview_col: int = -1
var confirm_button: Button = null
var turn_indicator: Label = null

# If true, two human players alternate turns instead of AI playing as player 2
@export var pvp_mode: bool = true

# ... (existing code) ...

func _setup_turn_indicator() -> void:
	if turn_indicator: return
	
	turn_indicator = Label.new()
	turn_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	turn_indicator.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Style
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	style.corner_radius_bottom_left = 15
	style.corner_radius_bottom_right = 15
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	turn_indicator.add_theme_stylebox_override("normal", style)
	turn_indicator.add_theme_font_size_override("font_size", 24)
	turn_indicator.add_theme_color_override("font_outline_color", Color.BLACK)
	turn_indicator.add_theme_constant_override("outline_size", 4)
	
	# Position at top center
	turn_indicator.anchor_left = 0.5
	turn_indicator.anchor_top = 0.0
	turn_indicator.anchor_right = 0.5
	turn_indicator.anchor_bottom = 0.0
	turn_indicator.grow_horizontal = Control.GROW_DIRECTION_BOTH
	turn_indicator.position = Vector2(get_viewport().get_visible_rect().size.x / 2 - 100, 0)
	
	if ui_layer:
		ui_layer.add_child(turn_indicator)
	else:
		add_child(turn_indicator)
	
	_update_turn_indicator()

func _update_turn_indicator() -> void:
	if not turn_indicator: return
	
	if pvp_mode:
		if is_player_turn:
			turn_indicator.text = "PLAYER 1'S TURN"
			turn_indicator.add_theme_color_override("font_color", Color(0.2, 0.6, 1.0)) # Blue
		else:
			turn_indicator.text = "PLAYER 2'S TURN"
			turn_indicator.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4)) # Red
	else:
		if is_player_turn:
			turn_indicator.text = "YOUR TURN"
			turn_indicator.add_theme_color_override("font_color", Color(0.2, 1.0, 0.2)) # Green
		else:
			turn_indicator.text = "AI IS THINKING..."
			turn_indicator.add_theme_color_override("font_color", Color(1.0, 0.6, 0.2)) # Orange

# true => it's the (first) player's turn; false => it's the second player's turn
var is_player_turn: bool = true

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

var cities = {
	"C1": [[10,0],[10,1],[9,0],[9,1]],
	"C2": [[10,2],[10,3],[10,4],[10,5],[9,2],[9,3],[9,4],[9,5]],
	"C3": [[10,6],[9,6],[8,6],[7,6],[7,5],[6,5],[6,6]],
	"C4": [[6,4],[6,5],[6,6],[5,5],[5,6]],
	"C5": [[9,0],[8,0],[8,1]],
	"C6": [[4,1],[3,1],[3,2]],
	"C7": [[4,2],[3,2],[4,3],[3,3],[3,4],[2,3]],
	"C8": [[3,2],[3,3],[2,2],[2,3]],
	"C9": [[2,2],[2,3],[1,2],[1,3]],
	"C10": [[3,0],[3,1],[2,0],[2,1],[2,2],[1,1],[1,2],[0,0],[0,1],[0,2],[0,3]],
	"C11": [[3,5],[3,6],[2,5],[2,6]],
	"C12": [[2,4],[2,5],[2,6],[1,3],[1,4],[1,5],[1,6],[0,4],[0,5],[0,6],[0,3]],
	"P1": [[6,1],[6,2],[6,3],[7,1],[7,2],[7,3],[5,1],[5,2],[5,3]],
	"P2": [[5,4],[5,3],[5,5],[4,4],[4,3],[4,5],[6,4],[6,3],[6,5]],
	"P3": [[2,4],[2,3],[2,5],[1,4],[1,3],[1,5],[3,4],[3,3],[3,5]]
}

var MAX_DEPTH = 3

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
			_show_win_popup("PLAYER 1 WINS!" if pvp_mode else "VICTORY!")
		elif ai_score > player_score:
			if pvp_mode:
				sfx_victory.play()
				_show_win_popup("PLAYER 2 WINS!")
			else:
				sfx_defeat.play()
				_show_lose_popup()
		else:
			# It's a tie
			sfx_victory.play()
			_show_win_popup("IT'S A TIE!")

func _show_win_popup(title_text: String = "") -> void:
	if winpopup:
		winpopup.visible = true
		winrestart.connect("pressed", Callable(self, "_on_restart_pressed"))
		winmainmenu.connect("pressed", Callable(self, "_on_main_menu_pressed"))
		
		if title_text != "":
			var title = winpopup.get_node_or_null("TitleLabel")
			if title: title.text = title_text

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

func show_soldier_report(is_ai: bool):
	# Skip soldier report in PvP mode
	if pvp_mode:
		return

	# If already showing, skip
	if soldier_popup:
		return
	
	# Create container for soldier image
	soldier_popup = TextureRect.new()
	soldier_popup.texture = soldier_texture
	soldier_popup.position = Vector2(-400, 400)  # start off-screen left
	soldier_popup.scale = Vector2(2, 2)
	soldier_popup.modulate = Color(1, 1, 1, 0.0)  # start transparent
	soldier_popup.size = Vector2(500, 500)
	ui_layer.add_child(soldier_popup)

	# Set dialogue & sound based on who completed
	var dialogue_text = ""
	if is_ai:
		dialogue_text = "Reporting... success, my King — the stronghold is secured."
		soldier_voice_player.stream = preload("res://assets/ui/losevoice.mp3")
	else:
		dialogue_text = "Victory, my King! The city is ours!"
		soldier_voice_player.stream = preload("res://assets/ui/soldiersuccess.mp3")

	# Optional background music (battle atmosphere)
	soldier_bgm.stream = preload("res://assets/ui/losevoice.mp3")

	# --- Tween soldier in ---
	var tween = create_tween()
	tween.tween_property(soldier_popup, "position", Vector2(200, 400), 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(soldier_popup, "modulate:a", 1.0, 0.5)

	# Play voice line slightly after animation starts
	await get_tree().create_timer(0.6).timeout
	add_child(soldier_voice_player)
	soldier_voice_player.volume_db = 10
	soldier_bgm.volume_db = 10
	soldier_bgm.play()
	soldier_voice_player.play()
	add_child(soldier_bgm)

	# Wait for voice to finish (or 3s default)
	await get_tree().create_timer(soldier_voice_player.stream.get_length() if soldier_voice_player.stream else 3.0).timeout

	# --- Tween soldier out ---
	var tween_out = create_tween()
	tween_out.tween_property(soldier_popup, "position", Vector2(-400, 400), 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween_out.parallel().tween_property(soldier_popup, "modulate:a", 0.0, 0.5)

	await get_tree().create_timer(1.0).timeout

	# Cleanup
	soldier_popup.queue_free()
	soldier_popup = null
	soldier_bgm.stop()

func _on_map_button_pressed():
	map_popup.visible = true  # Show the map

func _on_close_button_pressed():
	map_popup.visible = false  # Hide the map again

func on_city_completed(city_position: Vector2):
	# 1. Quick particle-like effect
	for i in range(20):
		var dot = ColorRect.new()
		dot.color = Color(randf(), randf(), randf())
		dot.size = Vector2(6,6)
		dot.position = city_position + Vector2(randf_range(-20,20), randf_range(-20,20))
		add_child(dot)

		# Fade out with Tween
		var tween = create_tween()
		tween.tween_property(dot, "modulate:a", 0.0, 0.7)
		await get_tree().create_timer(0.7).timeout
		dot.queue_free()
	
	# 2. "City Completed!" label
	var label = Label.new()
	label.text = "City Completed!"
	label.position = city_position + Vector2(-50, -40)
	label.scale = Vector2.ZERO
	add_child(label)

	var tween_label = create_tween()
	tween_label.tween_property(label, "scale", Vector2(1.2,1.2), 0.5)
	await get_tree().create_timer(1.5).timeout
	label.queue_free()

func _style_slider():
	if not difficulty_slider:
		return
	
	# Create custom theme for epic war-style slider
	var slider_theme = Theme.new()
	
	# Stylebox for the grabber (the knob you drag)
	var grabber_style = StyleBoxFlat.new()
	grabber_style.bg_color = Color(0.8, 0.2, 0.1, 1.0)  # Deep red
	grabber_style.corner_radius_top_left = 12
	grabber_style.corner_radius_top_right = 12
	grabber_style.corner_radius_bottom_left = 12
	grabber_style.corner_radius_bottom_right = 12
	grabber_style.border_width_left = 3
	grabber_style.border_width_right = 3
	grabber_style.border_width_top = 3
	grabber_style.border_width_bottom = 3
	grabber_style.border_color = Color(1.0, 0.8, 0.2, 1.0)  # Gold border
	grabber_style.shadow_color = Color(0, 0, 0, 0.5)
	grabber_style.shadow_size = 4
	
	# Stylebox for the slider bar background
	var slider_bg = StyleBoxFlat.new()
	slider_bg.bg_color = Color(0.15, 0.15, 0.2, 0.9)  # Dark gray-blue
	slider_bg.corner_radius_top_left = 6
	slider_bg.corner_radius_top_right = 6
	slider_bg.corner_radius_bottom_left = 6
	slider_bg.corner_radius_bottom_right = 6
	slider_bg.border_width_left = 2
	slider_bg.border_width_right = 2
	slider_bg.border_width_top = 2
	slider_bg.border_width_bottom = 2
	slider_bg.border_color = Color(0.4, 0.3, 0.2, 1.0)  # Brown border
	
	# Stylebox for the filled part of the slider
	var grabber_area = StyleBoxFlat.new()
	grabber_area.bg_color = Color(0.6, 0.15, 0.1, 0.8)  # Dark red gradient
	grabber_area.corner_radius_top_left = 6
	grabber_area.corner_radius_bottom_left = 6
	
	slider_theme.set_stylebox("slider", "HSlider", slider_bg)
	slider_theme.set_stylebox("grabber_area", "HSlider", grabber_area)
	slider_theme.set_stylebox("grabber_highlight", "HSlider", grabber_style)
	
	difficulty_slider.theme = slider_theme
	difficulty_slider.custom_minimum_size = Vector2(400, 40)
	
	# Add glow effect with Panel behind slider
	var glow_panel = Panel.new()
	var glow_style = StyleBoxFlat.new()
	glow_style.bg_color = Color(0.8, 0.2, 0.1, 0.3)
	glow_style.border_width_left = 0
	glow_style.shadow_color = Color(1.0, 0.3, 0.1, 0.6)
	glow_style.shadow_size = 15
	glow_panel.add_theme_stylebox_override("panel", glow_style)
	
	difficulty_slider.get_parent().add_child(glow_panel)
	difficulty_slider.get_parent().move_child(glow_panel, difficulty_slider.get_index())
	glow_panel.position = difficulty_slider.position - Vector2(10, 10)
	glow_panel.size = difficulty_slider.size + Vector2(20, 20)

func _on_difficulty_changed(value: float) -> void:
	selected_difficulty = int(value)
	var difficulty_names = {
		1: "⚔️ RECRUIT ⚔️",
		2: "🛡️ SOLDIER 🛡️", 
		3: "👑 CAPTAIN 👑",
		4: "⚡ GENERAL ⚡",
		5: "🔥 WARLORD 🔥"
	}
	var name = difficulty_names.get(selected_difficulty, "UNKNOWN")
	difficulty_label.text = name
	difficulty_label.add_theme_font_size_override("font_size", 28)

	
	# Add visual feedback - pulse effect
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(difficulty_label, "scale", Vector2(1.1, 1.1), 0.1)
	tween.tween_property(difficulty_label, "scale", Vector2(1.0, 1.0), 0.1)

func _on_difficulty_selected() -> void:
	if not difficulty_popup:
		return
	
	print("🎮 Difficulty selected, starting transition...")
	
	# Epic slide-out like a battle banner being raised
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var target_pos = Vector2(difficulty_popup.position.x, -difficulty_popup.size.y - 100)
	tween.tween_property(difficulty_popup, "position", target_pos, 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	await tween.finished
	
	difficulty_popup.visible = false
	
	# Apply difficulty level
	match selected_difficulty:
		1: MAX_DEPTH = 1
		2: MAX_DEPTH = 2
		3: MAX_DEPTH = 3
		4: MAX_DEPTH = 4
		5: MAX_DEPTH = 5

	print("⚔️ Battle difficulty set to level %d - Depth %d" % [selected_difficulty, MAX_DEPTH])
	
	# Resume game BEFORE playing queen intro
	get_tree().paused = false
	
	# Small delay to ensure unpause completes
	await get_tree().create_timer(0.1).timeout
	
	print("👑 Starting queen intro...")
	play_queen_intro()

func play_queen_intro():
	if not queen or not voice:
		print("⚠️ Queen or voice not found!")
		return
		
	print("🎬 Queen intro animation starting...")
	var tween = create_tween()
	voice.volume_db = 10
	tween.tween_property(queen, "position", on_screen_pos, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func(): 
		print("🎤 Playing queen voice...")
		voice.play()
	)
	tween.tween_interval(voice.stream.get_length() if voice.stream else 3.0)
	tween.tween_property(queen, "position", off_screen_pos, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func _ready():
	map_button.pressed.connect(_on_map_button_pressed)
	close_button.pressed.connect(_on_close_button_pressed)
	map_popup.visible = false
	winpopup.visible = false
	losepopup.visible = false
	if difficulty_popup:
		difficulty_popup.visible = false
	queen.position = off_screen_pos
	
	# Configure slider range
	if difficulty_slider:
		difficulty_slider.min_value = 1
		difficulty_slider.max_value = 5
		difficulty_slider.step = 1
		difficulty_slider.value = 3
	
	if difficulty_bg and difficulty_bg is ColorRect:
		var texture_rect = TextureRect.new()
		texture_rect.texture = preload("res://assets/ui/difficultyPopup.png")
		texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
		texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH
		texture_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		texture_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
		texture_rect.modulate = Color(1, 1, 1, 0.95)
		
		difficulty_bg.add_child(texture_rect)
		difficulty_bg.color = Color(1, 1, 1, 0)

	# Setup difficulty popup
	# Setup difficulty popup
	# We will show this ONLY if PvAI is selected
	
	if tile_ui and "tile_scenes" in tile_ui:
		scenes = tile_ui.tile_scenes.duplicate()
		total_tiles = scenes.size()
		tile_ui.connect("tile_selected", Callable(self, "_on_tile_selected"))
	else:
		print("⚠️ TileSelectorUI not found or missing tile_scenes")

	default_orbit_center = orbit_center
	default_orbit_radius = orbit_radius
	default_pitch = pitch
	default_yaw = yaw
	_update_camera_transform()

	if sfx_background and sfx_background.stream:
		sfx_background.stream.loop = true
		sfx_background.play()

	if sfx_start:
		sfx_start.volume_db = -2
		sfx_start.play()
	
	_setup_confirm_button()
	_setup_turn_indicator()
	_setup_environment()
	_setup_ambient_particles()
	_setup_sun()
	
	# Start with Game Mode selection
	_setup_gamemode_popup()

func _setup_gamemode_popup() -> void:
	var popup = Panel.new()
	popup.name = "GameModePopup"
	popup.size = Vector2(600, 400)
	popup.position = get_viewport().get_visible_rect().size / 2 - popup.size / 2
	popup.process_mode = Node.PROCESS_MODE_ALWAYS  # CRITICAL: Must process while paused
	
	# Style
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	style.border_width_left = 4
	style.border_width_right = 4
	style.border_width_top = 4
	style.border_width_bottom = 4
	style.border_color = Color(0.8, 0.6, 0.2, 1.0) # Gold
	style.corner_radius_top_left = 20
	style.corner_radius_top_right = 20
	style.corner_radius_bottom_left = 20
	style.corner_radius_bottom_right = 20
	popup.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 30)
	popup.add_child(vbox)
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 40
	vbox.offset_right = -40
	vbox.offset_top = 40
	vbox.offset_bottom = -40
	
	var title = Label.new()
	title.text = "SELECT GAME MODE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	vbox.add_child(title)
	
	# PvAI Button
	var btn_pvai = Button.new()
	btn_pvai.text = "⚔️ PLAYER vs AI 🤖"
	btn_pvai.custom_minimum_size = Vector2(0, 80)
	btn_pvai.add_theme_font_size_override("font_size", 24)
	btn_pvai.process_mode = Node.PROCESS_MODE_ALWAYS # Ensure button works
	btn_pvai.pressed.connect(func(): _on_gamemode_selected(false, popup))
	vbox.add_child(btn_pvai)
	
	# PvP Button
	var btn_pvp = Button.new()
	btn_pvp.text = "⚔️ PLAYER vs PLAYER ⚔️"
	btn_pvp.custom_minimum_size = Vector2(0, 80)
	btn_pvp.add_theme_font_size_override("font_size", 24)
	btn_pvp.process_mode = Node.PROCESS_MODE_ALWAYS # Ensure button works
	btn_pvp.pressed.connect(func(): _on_gamemode_selected(true, popup))
	vbox.add_child(btn_pvp)
	
	ui_layer.add_child(popup)
	
	# Pause game while selecting
	get_tree().paused = true

func _on_gamemode_selected(is_pvp: bool, popup: Control) -> void:
	pvp_mode = is_pvp
	popup.queue_free()
	
	if pvp_mode:
		print("⚔️ PvP Mode Selected")
		# Change AI score icon to Enemy icon
		var enemy_icon = load("res://assets/ui/score_enemy.png")
		if enemy_icon:
			# Try finding Icon child first
			var score_ai_icon = get_parent().get_node_or_null("TileSelectorUI/ScoreAI/Icon")
			if score_ai_icon and score_ai_icon is TextureRect:
				score_ai_icon.texture = enemy_icon
			else:
				# Try the ScoreAI container itself (if it's the texture)
				var score_ai_container = get_parent().get_node_or_null("TileSelectorUI/ScoreAI")
				if score_ai_container and score_ai_container is TextureRect:
					score_ai_container.texture = enemy_icon
		
		# Start game immediately (no queen intro)
		get_tree().paused = false
	else:
		print("🤖 PvAI Mode Selected")
		_show_difficulty_popup()
	
	_update_turn_indicator()

func _show_difficulty_popup() -> void:
	if difficulty_popup:
		# Setup slider + label
		difficulty_slider.value = selected_difficulty
		if not difficulty_slider.is_connected("value_changed", Callable(self, "_on_difficulty_changed")):
			difficulty_slider.connect("value_changed", Callable(self, "_on_difficulty_changed"))
		if not start_button.is_connected("pressed", Callable(self, "_on_difficulty_selected")):
			start_button.connect("pressed", Callable(self, "_on_difficulty_selected"))
		
		# Style the slider to look epic
		_style_slider()
		
		# Update initial label
		_on_difficulty_changed(selected_difficulty)
		
		# Update title for war theme
		if difficulty_title:
			difficulty_title.text = "⚔️ SELECT YOUR CHALLENGE ⚔️"
			difficulty_title.add_theme_font_size_override("font_size", 32)
		
		# Make UI elements process even when paused
		difficulty_popup.process_mode = Node.PROCESS_MODE_ALWAYS
		difficulty_slider.process_mode = Node.PROCESS_MODE_ALWAYS
		start_button.process_mode = Node.PROCESS_MODE_ALWAYS
		if difficulty_label:
			difficulty_label.process_mode = Node.PROCESS_MODE_ALWAYS
		
		# Start off-screen (slide from top like a battle banner)
		difficulty_popup.visible = true
		difficulty_popup.modulate.a = 1.0
		var original_pos = difficulty_popup.position
		difficulty_popup.position = Vector2(original_pos.x, -difficulty_popup.size.y - 100)

		# Epic slide-in animation
		var tween = create_tween()
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.tween_property(difficulty_popup, "position", original_pos, 1.0).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
		# Pause AFTER starting the tween
		get_tree().paused = true
	else:
		print("⚠️ Difficulty popup not found!")
		play_queen_intro()

	if tile_ui and "tile_scenes" in tile_ui:
		scenes = tile_ui.tile_scenes.duplicate()
		total_tiles = scenes.size()
		tile_ui.connect("tile_selected", Callable(self, "_on_tile_selected"))
	else:
		print("⚠️ TileSelectorUI not found or missing tile_scenes")

	default_cam_transform = cam.global_transform

	if sfx_background and sfx_background.stream:
		sfx_background.stream.loop = true
		sfx_background.play()

	if sfx_start:
		sfx_start.volume_db = -2
		sfx_start.play()
	
	_setup_confirm_button()

func _get_snapped_position(row: int, col: int) -> Vector3:
	var grid_x = col - 1
	var grid_z = row - 1
	return Vector3(grid_x * GRID_SIZE_X + GRID_ORIGIN.x, 0, grid_z * GRID_SIZE_Z + GRID_ORIGIN.z)
	
func _get_cell_key(row: int, col: int) -> String:
	# Cities use 0-indexed coords, so convert row/col (1-indexed) to 0-indexed
	var grid_z = row - 1  # row 1 -> 0, row 2 -> 1, etc.
	var grid_x = col - 1  # col 1 -> 0, col 2 -> 1, etc.
	return "%d,%d" % [grid_z, grid_x]  # Format: "row,col" in 0-indexed
	
func _remove_tile_button(scene_path: String) -> void:
	if tile_ui and tile_ui.has_method("remove_tile_button"):
		tile_ui.remove_tile_button(scene_path)
		
func focus_camera_on_tile(tile: Node3D, duration: float = 0.5, hold_time: float = 1.5):
	if not is_instance_valid(tile):
		return
	var target_pos = tile.global_transform.origin
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "orbit_center", target_pos, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "orbit_radius", 100.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
func _return_camera_to_default():
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "orbit_center", default_orbit_center, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "orbit_radius", default_orbit_radius, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "pitch", default_pitch, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "yaw", default_yaw, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _show_preview_tile(tile_path: String, row: int, col: int) -> void:
	# Remove existing preview if any
	_remove_preview_tile()
	
	var cell_key = _get_cell_key(row, col)
	if occupied_cells.has(cell_key):
		print("🚫 Cell already occupied, cannot show preview")
		return
	
	if not ResourceLoader.exists(tile_path):
		print("⚠️ Scene missing for preview:", tile_path)
		return
	
	var scene = load(tile_path)
	preview_tile = scene.instantiate()
	get_tree().current_scene.add_child(preview_tile)
	
	var snapped_pos = _get_snapped_position(row, col)
	# Raise slightly to avoid z-fighting with ground
	preview_tile.global_transform.origin = snapped_pos + Vector3(0, 0.1, 0)
	
	# Make it semi-transparent to indicate it's a preview
	_set_tile_transparency(preview_tile, 0.7)
	
	# Store preview info
	preview_tile_path = tile_path
	preview_row = row
	preview_col = col
	
	# Show confirm button
	if confirm_button:
		confirm_button.visible = true
		# Pop-in animation
		confirm_button.scale = Vector2.ZERO
		var tween = create_tween()
		tween.tween_property(confirm_button, "scale", Vector2(1, 1), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	print("👁️ Preview tile shown at row:", row, "col:", col)

func _remove_preview_tile() -> void:
	if preview_tile and is_instance_valid(preview_tile):
		preview_tile.queue_free()
		preview_tile = null
		preview_tile_path = ""
		preview_row = -1
		preview_col = -1
	
	if confirm_button:
		confirm_button.visible = false

func _setup_confirm_button() -> void:
	if confirm_button: return
	
	confirm_button = Button.new()
	confirm_button.text = "CONFIRM PLACEMENT"
	confirm_button.visible = false
	
	# Styling
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.2, 0.6, 0.2, 1.0) # Green
	style_normal.corner_radius_top_left = 10
	style_normal.corner_radius_top_right = 10
	style_normal.corner_radius_bottom_left = 10
	style_normal.corner_radius_bottom_right = 10
	style_normal.border_width_bottom = 4
	style_normal.border_color = Color(0.1, 0.4, 0.1, 1.0)
	style_normal.content_margin_left = 20
	style_normal.content_margin_right = 20
	style_normal.content_margin_top = 10
	style_normal.content_margin_bottom = 10
	
	var style_hover = style_normal.duplicate()
	style_hover.bg_color = Color(0.3, 0.7, 0.3, 1.0)
	
	var style_pressed = style_normal.duplicate()
	style_pressed.bg_color = Color(0.15, 0.5, 0.15, 1.0)
	style_pressed.border_width_bottom = 0
	style_pressed.content_margin_top = 14 # Shift text down
	
	confirm_button.add_theme_stylebox_override("normal", style_normal)
	confirm_button.add_theme_stylebox_override("hover", style_hover)
	confirm_button.add_theme_stylebox_override("pressed", style_pressed)
	confirm_button.add_theme_font_size_override("font_size", 24)
	confirm_button.add_theme_color_override("font_color", Color.WHITE)
	confirm_button.add_theme_constant_override("outline_size", 4)
	confirm_button.add_theme_color_override("font_outline_color", Color.BLACK)
	
	# Positioning (Bottom Center, above tile list)
	confirm_button.anchor_left = 0.5
	confirm_button.anchor_top = 0.85
	confirm_button.anchor_right = 0.5
	confirm_button.anchor_bottom = 0.85
	confirm_button.grow_horizontal = Control.GROW_DIRECTION_BOTH
	confirm_button.grow_vertical = Control.GROW_DIRECTION_BOTH
	# Offset to center
	confirm_button.position = Vector2(get_viewport().get_visible_rect().size.x / 2 - 100, get_viewport().get_visible_rect().size.y - 150)
	
	confirm_button.connect("pressed", Callable(self, "_confirm_tile_placement"))
	
	# Add to UI layer
	if ui_layer:
		ui_layer.add_child(confirm_button)
	else:
		add_child(confirm_button)

func _set_tile_transparency(tile: Node3D, alpha: float) -> void:
	# Recursively set transparency for all MeshInstance3D children
	for child in tile.get_children():
		if child is MeshInstance3D:
			# Disable shadows for preview
			child.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			
			# Get the number of surfaces
			var surface_count = child.mesh.get_surface_count() if child.mesh else 0
			
			for i in range(surface_count):
				var material = child.get_surface_override_material(i)
				if material == null:
					material = child.mesh.surface_get_material(i)
				
				if material:
					# Duplicate the material to avoid affecting other instances
					material = material.duplicate()
					
					# Handle StandardMaterial3D
					if material is StandardMaterial3D:
						material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
						material.albedo_color.a = alpha
					# Handle other material types
					elif "albedo_color" in material:
						var color = material.albedo_color
						color.a = alpha
						material.albedo_color = color
					
					child.set_surface_override_material(i, material)
					print("🎨 Set transparency to ", alpha, " for surface ", i)
		
		# Recursively process children
		if child.get_child_count() > 0:
			_set_tile_transparency(child, alpha)


func _on_tile_selected(tile_path: String) -> void:
	if not ResourceLoader.exists(tile_path):
		print("⚠️ Scene missing:", tile_path)
		return

	print("🎯 Player selected:", tile_path)

	var row_col = _get_row_col_from_scene(tile_path)
	if row_col.size() == 0:
		print("⚠️ Failed to parse row/col from:", tile_path)
		return

	var row = int(row_col["row"])
	var col = int(row_col["col"])
	
	# Show preview tile at this position
	_show_preview_tile(tile_path, row, col)
	
	# Store the selected scene for later placement
	selected_scene = load(tile_path)

func _confirm_tile_placement() -> void:
	if preview_tile == null or preview_tile_path == "":
		print("⚠️ No preview tile to confirm")
		return
	
	var tile_path = preview_tile_path
	var row = preview_row
	var col = preview_col
	var cell_key = _get_cell_key(row, col)

	if occupied_cells.has(cell_key):
		print("🚫 Cell already occupied:", cell_key)
		_remove_preview_tile()
		return

	# Remove the preview tile
	_remove_preview_tile()

	var snapped_pos = _get_snapped_position(row, col)
	var tile = selected_scene.instantiate()
	get_tree().current_scene.add_child(tile)
	tile.global_transform.origin = snapped_pos
	
	_add_collision_to_tile(tile)
	_add_torch_to_tile(tile)

	occupied_cells[cell_key] = tile
	placed_scenes.append(tile_path)
	
	print("✅ Player placed tile at row:", row, "col:", col, "key:", cell_key)
	
	# --- Check for city completion and trigger effect ---
	var completed = _check_city_completion_for_real(row - 1, col - 1)  # 0-indexed
	# Determine which human is placing: in PvP mode use is_player_turn, otherwise default to player
	var placing_is_player: bool = true
	if pvp_mode:
		placing_is_player = is_player_turn
	
	for city_name in completed:
		var score_gained = cities[city_name].size() * 5
		if placing_is_player:
			player_score += score_gained
			print("✅ Player completed city:", city_name, "Score +", score_gained)
		else:
			ai_score += score_gained
			print("✅ Player 2 completed city:", city_name, "Score +", score_gained)
		
		show_soldier_report(not placing_is_player)
		# Spawn visual effect at the tile's position
		on_city_completed(cam.unproject_position(tile.global_transform.origin))
		
		# Highlight all tiles in the completed city
		_highlight_city_tiles(city_name, placing_is_player)

	_update_score_labels()

	# Play placement sound & focus camera
	sfx_tile_placement.play()
	focus_camera_on_tile(tile)

	# Reset camera after delay
	var cam_reset_timer = Timer.new()
	cam_reset_timer.one_shot = true
	cam_reset_timer.wait_time = 1.0
	cam_reset_timer.connect("timeout", Callable(self, "_return_camera_to_default"))
	add_child(cam_reset_timer)
	cam_reset_timer.start()

	# Remove tile from selector UI (if present)
	call_deferred("_remove_tile_button", tile_path)

	# Emit placement signal (true indicates human player / first player)
	emit_signal("tile_placed", placing_is_player)

	# If PvP mode is enabled, toggle the human turn and do NOT schedule the AI
	if pvp_mode:
		is_player_turn = not is_player_turn
		print("🔁 PvP mode: switched turn. Now is_player_turn =", is_player_turn)
		_update_turn_indicator()
	else:
		# Schedule AI tile placement
		is_player_turn = false # AI turn starts
		_update_turn_indicator()
		
		var timer = Timer.new()
		timer.one_shot = true
		timer.wait_time = 0.5  # Faster gameplay
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

# Check city completion for actual game (uses real occupied_cells)
func _check_city_completion_for_real(row: int, col: int) -> Array:
	var completed = []
	
	for city_name in cities.keys():
		# Skip if city was already completed
		if completed_cities_global.has(city_name):
			continue
			
		var tiles = cities[city_name]
		var all_placed = true
		for tile_coord in tiles:
			var r = tile_coord[0]  # 0-indexed row
			var c = tile_coord[1]  # 0-indexed col
			var key = "%d,%d" % [r, c]  # Use 0-indexed coords directly
			if not occupied_cells.has(key):
				all_placed = false
				break
		
		if all_placed:
			completed.append(city_name)
			completed_cities_global[city_name] = true  # Mark as completed globally
			print("🏙️ City completed:", city_name, "Tiles:", tiles.size())
	
	return completed

# Check which cities would be completed by placing a tile at (row, col) in simulation
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

# Get all available moves (free cells) with heuristic ordering
func _get_available_moves(state: Dictionary) -> Array:
	var moves = []
	for row in range(GRID_DIM_Z):
		for col in range(GRID_DIM_X):
			var key = "%d,%d" % [row, col]
			if not state["occupied"].has(key):
				# Add heuristic score for move ordering (better pruning)
				var heuristic = _evaluate_move_heuristic(state, row, col)
				moves.append({"row": row, "col": col, "heuristic": heuristic})
	
	# Sort moves by heuristic (best first) for better alpha-beta pruning
	moves.sort_custom(func(a, b): return a["heuristic"] > b["heuristic"])
	return moves

# Quick heuristic to prioritize moves that might complete cities
func _evaluate_move_heuristic(state: Dictionary, row: int, col: int) -> float:
	var score = 0.0
	for city_name in cities.keys():
		if state["completed_cities"].has(city_name):
			continue
		var tiles = cities[city_name]
		var remaining = 0
		for tile_coord in tiles:
			var r = tile_coord[0]
			var c = tile_coord[1]
			var key = "%d,%d" % [r, c]
			if not state["occupied"].has(key) and not (r == row and c == col):
				remaining += 1
		# Prioritize moves that nearly complete cities
		if remaining == 0:
			score += cities[city_name].size() * 10  # Would complete city!
		elif remaining <= 2:
			score += cities[city_name].size() * 2  # Close to completion
	return score

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
# AI tile placement using minimax
func _place_ai_tile():
	print("🤖 AI thinking...")
	sfx_tile_placement.play()
	
	# Build current game state
	var current_state = {
		"occupied": occupied_cells.duplicate(),
		"completed_cities": completed_cities_global.duplicate(),
		"ai_score": ai_score,
		"player_score": player_score
	}
	
	# Get available moves
	var available_moves = _get_available_moves(current_state)
	if available_moves.size() == 0:
		print("No available moves for AI!")
		return
		
	# If too many moves, use heuristic (fallback for performance)
	var best_move = null
	if available_moves.size() > 40:
		print("🤖 Too many moves, using heuristic only")
		best_move = available_moves[0]  # already sorted by heuristic
	else:
		var result = _minimax(current_state, MAX_DEPTH, -INF, INF, true)
		best_move = result["move"]
	
	if not best_move:
		print("No valid move found for AI!")
		return
	
	var row = best_move["row"]
	var col = best_move["col"]
	var cell_key = "%d,%d" % [row, col]
	
	print("🤖 AI chose row:", row, "col:", col)
	
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
	
	_add_collision_to_tile(ai_tile)
	_add_torch_to_tile(ai_tile)
	
	occupied_cells[cell_key] = ai_tile
	placed_scenes.append(scene_path)
	
	print("🤖 AI placed tile at row:", row, "col:", col, "key:", cell_key)
	
	# Check for city completion and update score
	var completed = _check_city_completion_for_real(row, col)
	for city_name in completed:
		var score_gained = cities[city_name].size() * 5
		ai_score += score_gained
		print("🤖 AI completed city:", city_name, "Score +", score_gained)
		
		show_soldier_report(true)

		# 🔥 Show completion effect at tile’s position
		on_city_completed(cam.unproject_position(ai_tile.global_transform.origin))
		
		_highlight_city_tiles(city_name, false)

	_update_score_labels()
	call_deferred("_remove_tile_button", scene_path)
	
	emit_signal("tile_placed", false)
	focus_camera_on_tile(ai_tile)
	
	# Reset camera after delay
	var cam_reset_timer = Timer.new()
	cam_reset_timer.one_shot = true
	cam_reset_timer.wait_time = 1.0
	cam_reset_timer.connect("timeout", Callable(self, "_return_camera_to_default"))
	add_child(cam_reset_timer)
	cam_reset_timer.start()
	
	_check_game_end()
	
	# AI turn finished, back to player
	is_player_turn = true
	_update_turn_indicator()
	
var last_tap_time: float = 0.0
var double_tap_max_interval: float = 0.3
var tile_info_popup: Control = null
var selected_tile: Node3D = null

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			var current_time = Time.get_ticks_usec() / 1_000_000.0

			if current_time - last_tap_time <= double_tap_max_interval:
				_handle_double_tap(event.position)
			else:
				_handle_tile_touch(event.position)
			last_tap_time = current_time
			touches[event.index] = event.position
		else:
			touches.erase(event.index)
			last_pinch_dist = 0.0

	elif event is InputEventScreenDrag:
		touches[event.index] = event.position
		if touches.size() == 1:
			_rotate_camera(event.relative.x * rotate_sensitivity * 20, event.relative.y * rotate_sensitivity * 20)
		elif touches.size() == 2:
			var points = touches.values()
			var dist = points[0].distance_to(points[1])
			if last_pinch_dist > 0:
				var delta = dist - last_pinch_dist
				_zoom_camera(-delta * zoom_speed * 50)
			last_pinch_dist = dist

			var center_prev = (points[0] + points[1] - event.relative) / 2
			var center_now = (points[0] + points[1]) / 2
			var pan_delta = center_now - center_prev
			_pan_camera(pan_delta * 0.5)

	elif event is InputEventMouseMotion:
		if event.button_mask & MOUSE_BUTTON_MASK_LEFT or event.button_mask & MOUSE_BUTTON_MASK_RIGHT:
			_rotate_camera(event.relative.x * rotate_sensitivity * 20, event.relative.y * rotate_sensitivity * 20)
		elif event.button_mask & MOUSE_BUTTON_MASK_MIDDLE:
			_pan_camera(event.relative)

	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_camera(-zoom_speed * 50)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_camera(zoom_speed * 50)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.double_click:
				_handle_double_tap(event.position)
			else:
				_handle_tile_touch(event.position)

func _process(delta: float) -> void:
	_update_camera_transform()

func _handle_double_tap(screen_pos: Vector2) -> void:
	# If there's a preview tile, confirm its placement
	if preview_tile != null:
		_confirm_tile_placement()
		return
	
	# Otherwise, focus on an existing tile
	var from = cam.project_ray_origin(screen_pos)
	var to   = from + cam.project_ray_normal(screen_pos) * 15000 #Increased ray length

	var params = PhysicsRayQueryParameters3D.new()
	params.from = from
	params.to = to
	params.collision_mask = 1
	params.exclude = []

	var space_state = get_world_3d().direct_space_state
	var result = space_state.intersect_ray(params)

	if result and result.has("collider"):
		var collider = result["collider"]
		var tile = collider.get_parent()
		if tile in occupied_cells.values():
			# The collider is the StaticBody3D child of the tile
			focus_camera_on_tile(tile)
			_show_tile_info(tile)
	else:
		# Clicked background
		_return_camera_to_default()
		_hide_tile_info()

func _handle_tile_touch(screen_pos: Vector2) -> void:
	var from = cam.project_ray_origin(screen_pos)
	var to   = from + cam.project_ray_normal(screen_pos) * 5000 # Increased ray length

	var params = PhysicsRayQueryParameters3D.new()
	params.from = from
	params.to = to
	params.collision_mask = 1
	params.exclude = []

	var space_state = get_world_3d().direct_space_state
	var result = space_state.intersect_ray(params)

	if result and result.has("collider"):
		var collider = result["collider"]
		var tile = collider.get_parent()
		print("🖱️ Raycast hit:", collider.name, " Parent:", tile.name)
		
		if tile in occupied_cells.values():
			print("✅ Tile found in occupied_cells!")
			selected_tile = tile
			_show_tile_info(tile)
			focus_camera_on_tile(tile) # Focus and set as orbit origin
			return
		else:
			print("❌ Tile NOT in occupied_cells")

	# If touched outside any tile, hide popup and reset camera to board origin
	print("🌐 Clicked outside/background - Resetting camera")
	_hide_tile_info()
	_return_camera_to_default()

func _show_tile_info(tile: Node3D) -> void:
	if tile_info_popup:
		return

	tile_info_popup = ColorRect.new()
	tile_info_popup.color = Color(0,0,0,0.7)
	tile_info_popup.size = Vector2(200,100)
	tile_info_popup.position = get_viewport().get_visible_rect().size / 2 - tile_info_popup.size / 2
	add_child(tile_info_popup)

	var label = Label.new()
	label.text = "Tile Info"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tile_info_popup.add_child(label)

func _add_collision_to_tile(tile: Node3D) -> void:
	# Only add if no collision exists
	if tile.get_node_or_null("TileBody") != null:
		return

	# Create a StaticBody3D to hold the collision
	var body = StaticBody3D.new()
	body.name = "TileBody"
	tile.add_child(body)

	var collision = CollisionShape3D.new()
	collision.name = "DynamicCollision"

	# Find the first MeshInstance3D in the tile to get its bounding box
	var mesh_instance = _find_mesh_instance(tile)
	
	if mesh_instance:
		var aabb = mesh_instance.get_aabb()
		var box = BoxShape3D.new()
		box.size = aabb.size
		collision.shape = box
		collision.position = aabb.position + aabb.size / 2
	else:
		# Fallback: use a default box if no mesh found
		var box = BoxShape3D.new()
		box.size = Vector3(GRID_SIZE_X, 1.0, GRID_SIZE_Z)
		collision.shape = box
		collision.position = Vector3(0, 0, 0)
		print("⚠️ No mesh found in tile, using default collision box")

	# Add to body
	body.add_child(collision)

func _find_mesh_instance(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node
	
	for child in node.get_children():
		var result = _find_mesh_instance(child)
		if result:
			return result
	
	return null
	
func _hide_tile_info() -> void:
	if tile_info_popup:
		tile_info_popup.queue_free()
		tile_info_popup = null
		selected_tile = null

func _update_camera_transform() -> void:
	var rot = Basis.from_euler(Vector3(deg_to_rad(pitch), deg_to_rad(yaw), 0))
	var offset = Vector3(0, 0, orbit_radius)
	cam.global_transform.origin = orbit_center + (rot * offset)
	cam.look_at(orbit_center)

func _rotate_camera(delta_yaw: float, delta_pitch: float) -> void:
	yaw -= delta_yaw
	pitch -= delta_pitch
	pitch = clamp(pitch, min_pitch, max_pitch)
	_update_camera_transform()

func _zoom_camera(delta: float) -> void:
	orbit_radius -= delta
	orbit_radius = clamp(orbit_radius, min_zoom, max_zoom)
	_update_camera_transform()

func _pan_camera(delta: Vector2) -> void:
	var right = cam.transform.basis.x.normalized()
	# Project up vector to ground plane for flatter panning if desired, or keep camera-relative
	# For top-down strategy, panning on XZ plane is often better.
	# But let's stick to camera-relative for now as it's intuitive.
	var up = cam.transform.basis.y.normalized()
	
	orbit_center -= right * delta.x * 0.5
	orbit_center += up * delta.y * 0.5
	_update_camera_transform()

func _highlight_city_tiles(city_name: String, is_player: bool) -> void:
	if not cities.has(city_name):
		return
	
	var tiles_coords = cities[city_name]
	var tiles_to_animate = []
	var centroid = Vector3.ZERO
	
	for coord in tiles_coords:
		var r = coord[0]
		var c = coord[1]
		var key = "%d,%d" % [r, c]
		
		if occupied_cells.has(key):
			var tile = occupied_cells[key]
			tiles_to_animate.append(tile)
			centroid += tile.global_transform.origin
	
	if tiles_to_animate.size() > 0:
		centroid /= tiles_to_animate.size()
		_animate_city_celebration(tiles_to_animate, centroid)

func _animate_city_celebration(tiles: Array, centroid: Vector3) -> void:
	# 0. Reset camera to default view to ensure consistent framing
	_return_camera_to_default()

	# 1. Create Pivot
	var pivot = Node3D.new()
	pivot.name = "CelebrationPivot"
	get_tree().current_scene.add_child(pivot)
	pivot.global_transform.origin = centroid
	
	# 2. Reparent tiles to pivot
	var original_parent = tiles[0].get_parent()
	for tile in tiles:
		if is_instance_valid(tile):
			tile.reparent(pivot, true)
		
	# 3. Animate Pivot
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Calculate DEFAULT camera position and forward vector
	var rot = Basis.from_euler(Vector3(deg_to_rad(default_pitch), deg_to_rad(default_yaw), 0))
	var offset = Vector3(0, 0, default_orbit_radius)
	var def_cam_pos = default_orbit_center + (rot * offset)
	var def_cam_forward = (default_orbit_center - def_cam_pos).normalized()
	
	# Target: In front of the DEFAULT camera position
	var dist_from_cam = 400.0 # Distance from camera lens
	var target_pos = def_cam_pos + def_cam_forward * dist_from_cam
	
	tween.tween_property(pivot, "global_transform:origin", target_pos, 1.0).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(pivot, "scale", Vector3(0.5, 0.5, 0.5), 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(pivot, "rotation:y", TAU, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Hold
	tween.chain().tween_interval(0.3)
	
	# Return
	tween.chain().set_parallel(true)
	tween.tween_property(pivot, "global_transform:origin", centroid, 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(pivot, "scale", Vector3(1, 1, 1), 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# Continue rotating to 2 turns to keep flow, or reset? 
	# Going to 2*TAU ensures continuous direction.
	tween.tween_property(pivot, "rotation:y", TAU * 2, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Cleanup
	tween.chain().tween_callback(func():
		for tile in tiles:
			if is_instance_valid(tile):
				tile.reparent(original_parent, true)
		pivot.queue_free()
	)

func _setup_environment() -> void:
	# Check if one already exists to avoid duplication
	if get_node_or_null("WorldEnvironment"):
		return

	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.05, 0.05, 0.08) # Deep dark background
	
	# Tone Mapping (Cinematic look)
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.0
	
	# SSAO (Ambient Occlusion) - Critical for 3D tiles
	env.ssao_enabled = true
	env.ssao_radius = 2.0
	env.ssao_intensity = 3.0
	env.ssao_power = 1.5
	
	# Glow (Bloom)
	env.glow_enabled = true
	env.glow_intensity = 0.6
	env.glow_strength = 0.95
	env.glow_bloom = 0.1
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	
	# Adjustments (Vibrance)
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.3 # Make colors pop
	env.adjustment_contrast = 1.15
	
	# Fog (Depth)
	env.fog_enabled = true
	env.fog_light_color = Color(0.05, 0.05, 0.08)
	env.fog_density = 0.0005 # Subtle distance fade
	env.fog_aerial_perspective = 0.5
	
	var world_env = WorldEnvironment.new()
	world_env.environment = env
	world_env.name = "WorldEnvironment"
	add_child(world_env)
	print("✨ Premium Environment Setup Complete")

func _setup_ambient_particles() -> void:
	if get_node_or_null("AmbientStars"):
		return
		
	var particles = GPUParticles3D.new()
	particles.name = "AmbientStars"
	particles.amount = 200
	particles.lifetime = 10.0
	particles.preprocess = 5.0 # Start fully populated
	particles.explosiveness = 0.0
	particles.randomness = 0.5
	
	# Process Material (Physics)
	var proc_mat = ParticleProcessMaterial.new()
	proc_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	proc_mat.emission_box_extents = Vector3(500, 100, 500) # Large area around board
	proc_mat.gravity = Vector3(0, 5, 0) # Slow rise
	proc_mat.turbulence_enabled = true
	proc_mat.turbulence_noise_strength = 5.0
	proc_mat.scale_min = 0.5
	proc_mat.scale_max = 2.0
	
	particles.process_material = proc_mat
	
	# Draw Pass (Visuals)
	var mesh = SphereMesh.new()
	mesh.radius = 2.0
	mesh.height = 4.0
	mesh.radial_segments = 8
	mesh.rings = 4
	
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 1.0, 1.0) # Pure White
	mat.emission_enabled = true
	mat.emission = Color(1.0, 1.0, 1.0)
	mat.emission_energy_multiplier = 16.0 # Intense star glow
	
	mesh.material = mat
	particles.draw_pass_1 = mesh
	
	add_child(particles)
	particles.global_position = orbit_center # Center on board

func _setup_sun() -> void:
	if get_node_or_null("TheSun"):
		return
		
	var sun = MeshInstance3D.new()
	sun.name = "TheSun"
	
	var mesh = SphereMesh.new()
	mesh.radius = 60.0
	mesh.height = 120.0
	sun.mesh = mesh
	
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.9, 0.6) # Bright Yellow-White
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.8, 0.4) # Warm Sun
	mat.emission_energy_multiplier = 10.0 # Blindingly bright
	sun.material_override = mat
	
	add_child(sun)
	
	# Position it far away in the sky
	sun.global_position = orbit_center + Vector3(1000, 800, -1000)
	
	# Add strong sunlight
	var light = DirectionalLight3D.new()
	light.name = "SunLight"
	light.light_color = Color(1.0, 0.95, 0.8) # Warm sunlight
	light.light_energy = 2.0
	light.shadow_enabled = true
	sun.add_child(light)
	light.look_at(orbit_center, Vector3.UP)

func _add_torch_to_tile(tile: Node3D) -> void:
	# Add 2 to 3 torches per tile for a campfire vibe
	var count = randi_range(2, 3)
	for i in range(count):
		_create_single_torch(tile)

func _create_single_torch(tile: Node3D) -> void:
	# Create Stick
	var stick = MeshInstance3D.new()
	stick.mesh = CylinderMesh.new()
	stick.mesh.top_radius = 0.15
	stick.mesh.bottom_radius = 0.15
	stick.mesh.height = 1.0 # Short
	
	var stick_mat = StandardMaterial3D.new()
	stick_mat.albedo_color = Color(0.4, 0.2, 0.1) # Wood brown
	stick.material_override = stick_mat
	
	# Calculate visual center from AABB
	var center_pos = Vector3.ZERO
	var mesh_instance = _find_mesh_instance(tile)
	if mesh_instance:
		var aabb = mesh_instance.get_aabb()
		center_pos = aabb.position + aabb.size / 2
	
	# Position: Visual Center + Spread +/- 10
	var offset_x = randf_range(-2, 2)
	var offset_z = randf_range(-2, 2)
	stick.position = Vector3(center_pos.x + offset_x, 0.5, center_pos.z + offset_z)
	
	tile.add_child(stick)
	
	# Create Fire Particles
	var fire = GPUParticles3D.new()
	fire.amount = 16
	fire.lifetime = 0.6
	
	var proc_mat = ParticleProcessMaterial.new()
	proc_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	proc_mat.emission_sphere_radius = 0.1
	proc_mat.gravity = Vector3(0, 5, 0)
	proc_mat.scale_min = 0.2
	proc_mat.scale_max = 0.5
	fire.process_material = proc_mat
	
	var mesh = QuadMesh.new()
	mesh.size = Vector2(0.5, 0.5)
	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.albedo_color = Color(1.0, 0.6, 0.1)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.4, 0.0)
	mat.emission_energy_multiplier = 10.0 # SUPER BRIGHT
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mesh.material = mat
	fire.draw_pass_1 = mesh
	
	fire.position = Vector3(0, 0.5, 0) # Top of stick (height/2)
	stick.add_child(fire)
	
	# Create Light
	var light = OmniLight3D.new()
	light.light_color = Color(1.0, 0.6, 0.2) # Orange
	light.light_energy = 4.0 # Much brighter
	light.omni_range = 150.0 # Wider range
	light.position = Vector3(0, 2.0, 0) # Raised slightly
	stick.add_child(light)
	
	# Flicker animation
	var tween = create_tween().set_loops()
	tween.tween_property(light, "light_energy", 3.0, 0.1)
	tween.tween_property(light, "light_energy", 5.0, 0.1)
