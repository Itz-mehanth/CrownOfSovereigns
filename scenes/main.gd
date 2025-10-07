extends Node3D


@export var rotate_sensitivity: float = 0.005
@export var zoom_speed: float = 0.001
@export var min_pitch: float = -80.0
@export var max_pitch: float = 80.0


var yaw: float = 0.0
var pitch: float = 0.0
var touches := {}
var last_pinch_dist: float = 0.0


@onready var cam: Camera3D = $Camera3D
@onready var tile_ui: Control = get_parent().get_node("TileSelectorUI")


var selected_scene: PackedScene = null
var occupied_cells: Dictionary = {}
var placed_scenes := []


const GRID_SIZE_X = 90.0
const GRID_SIZE_Z = 90.0
const GRID_DIM_X = 7
const GRID_DIM_Z = 11
const GRID_ORIGIN = Vector3(50, 0, -130)


@export var SHOW_GRID: bool = true
@export var GRID_COLOR: Color = Color(0.2, 0.8, 1.0, 0.15)


var grid_parent: Node3D

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

func _ready():
	tile_ui.tile_scenes = scenes
	tile_ui.connect("tile_selected", Callable(self, "_on_tile_selected"))

func _on_tile_selected(tile_path: String):
	if ResourceLoader.exists(tile_path):
		selected_scene = load(tile_path)
		print("🎯 Scene selected manually:", tile_path)
	else:
		print("⚠️ Scene missing:", tile_path)

func _unhandled_input(event: InputEvent) -> void:
			
	if selected_scene == null:
		print("⚠️ No scene selected yet!")
		return

	var from = cam.project_ray_origin(event.position)
	var to = from + cam.project_ray_normal(event.position) * 1000.0
	var result = get_world_3d().direct_space_state.intersect_ray(
	PhysicsRayQueryParameters3D.create(from, to)
	)
	
	if not result.has("position"):
		print("⚠️ No collision detected")
		return


	var hit_pos: Vector3 = result["position"]
	var grid_x = round((hit_pos.x - GRID_ORIGIN.x) / GRID_SIZE_X)
	var grid_z = round((hit_pos.z - GRID_ORIGIN.z) / GRID_SIZE_Z)
	var cell_key = "%d,%d" % [grid_x, grid_z]


	if abs(grid_x) > (GRID_DIM_X - 1) / 2 or abs(grid_z) > (GRID_DIM_Z - 1) / 2:
		print("🚫 Out of grid bounds")
		return


	if occupied_cells.has(cell_key):
		print("🚫 Cell occupied:", cell_key)
		return


	# Place selected scene
	var snapped_pos = Vector3(
	grid_x * GRID_SIZE_X + GRID_ORIGIN.x,
	hit_pos.y - 0.1,
	grid_z * GRID_SIZE_Z + GRID_ORIGIN.z
	)
	var tile = selected_scene.instantiate()
	get_tree().current_scene.add_child(tile)
	tile.global_transform.origin = snapped_pos


	occupied_cells[cell_key] = tile
	placed_scenes.append(selected_scene.resource_path)
	print("✅ Placed tile at:", snapped_pos)

	print("✅ Placed tile at:", snapped_pos)

	# AI places a tile
	_place_ai_tile()

func set_selected_scene(scene: PackedScene) -> void:
	selected_scene = scene
	print("🎯 Scene selected:", scene.resource_path)

func _place_ai_tile():
	# Find free cells
	const AI_GRID_SIZE_X = 9  # smaller spacing for AI tiles
	const AI_GRID_SIZE_Z = 9
	const AI_GRID_ORIGIN = Vector3(5,0,-13)

	var free_cells = []
	for x in range(-int((GRID_DIM_X - 1)/2), int((GRID_DIM_X - 1)/2)+1):
		for z in range(-int((GRID_DIM_Z - 1)/2), int((GRID_DIM_Z - 1)/2)+1):
			var key = "%d,%d" % [x, z]
			if not occupied_cells.has(key):
				free_cells.append(key)

	if free_cells.size() == 0:
		return  # No free cells

	# Pick a random free cell
	var rand_cell = free_cells[randi() % free_cells.size()]
	var coords = rand_cell.split(",")
	var grid_x = int(coords[0])
	var grid_z = int(coords[1])

	# Pick a scene that hasn't been placed yet
	var available_scenes = []
	for s in scenes:
		if s not in placed_scenes:
			available_scenes.append(s)

	if available_scenes.size() == 0:
		return  # All scenes placed

	var rand_index = randi() % available_scenes.size()
	var scene_path = available_scenes[rand_index]
	var ai_tile_scene = load(scene_path)
	if ai_tile_scene == null:
		print("⚠️ Missing AI scene:", scene_path)
		return

	var ai_tile = ai_tile_scene.instantiate()

	# Snap tile to grid
	var snapped_pos = Vector3(
		AI_GRID_ORIGIN.x + grid_x * AI_GRID_SIZE_X,
		-17.5,  # Adjust Y if needed
		AI_GRID_ORIGIN.z + grid_z * AI_GRID_SIZE_Z
	)
	ai_tile.global_transform.origin = snapped_pos
	get_tree().current_scene.add_child(ai_tile)

	# Mark cell and scene as used
	occupied_cells[rand_cell] = ai_tile
	placed_scenes.append(scene_path)

	print("🤖 AI placed tile at:", snapped_pos, "Scene:", scene_path)

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
			# One finger → rotate
			var drag = event.relative
			yaw   -= drag.x * rotate_sensitivity
			pitch -= drag.y * rotate_sensitivity
			pitch = clamp(pitch, min_pitch, max_pitch)
			rotation_degrees = Vector3(pitch, yaw, 0)
