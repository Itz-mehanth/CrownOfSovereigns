extends TextureButton

@onready var camera: Camera3D = get_viewport().get_camera_3d()
@onready var index_label: Label = $Label  # assuming you added a Label child

var scene_to_place: PackedScene
var is_selected: bool = false

static var occupied_cells: Dictionary = {}
static var selected_button: TextureButton = null
static var shared_grid_visual: Node3D = null
static var tiles_placed_count = 0
var tiles_placed = []

var next_scene_index: int = 0

var scenes = [
	"res://scenes/r1/11.tscn",
	"res://scenes/r1/12.tscn",
	"res://scenes/r1/13.tscn",
	"res://scenes/r1/14.tscn",
	"res://scenes/r1/15.tscn",
	"res://scenes/r1/16.tscn",
	"res://scenes/r1/17.tscn",
	"res://scenes/r2/21.tscn",
	"res://scenes/r2/22.tscn",
	"res://scenes/r2/23.tscn",
	"res://scenes/r2/24.tscn",
	"res://scenes/r2/25.tscn",
	"res://scenes/r2/26.tscn",
	"res://scenes/r2/27.tscn",
	"res://scenes/r3/31.tscn",
	"res://scenes/r3/32.tscn",
	"res://scenes/r3/33.tscn",
	"res://scenes/r3/34.tscn",
	"res://scenes/r3/35.tscn",
	"res://scenes/r3/36.tscn",
	"res://scenes/r3/37.tscn",
	"res://scenes/r4/41.tscn",
	"res://scenes/r4/42.tscn",
	"res://scenes/r4/43.tscn",
	"res://scenes/r4/44.tscn",
	"res://scenes/r4/45.tscn",
	"res://scenes/r4/46.tscn",
	"res://scenes/r4/47.tscn",
	"res://scenes/r5/51.tscn",
	"res://scenes/r5/52.tscn",
	"res://scenes/r5/53.tscn",
	"res://scenes/r5/54.tscn",
	"res://scenes/r5/55.tscn",
	"res://scenes/r5/56.tscn",
	"res://scenes/r5/57.tscn",
	"res://scenes/r6/61.tscn",
	"res://scenes/r6/62.tscn",
	"res://scenes/r6/63.tscn",
	"res://scenes/r6/64.tscn",
	"res://scenes/r6/65.tscn",
	"res://scenes/r6/66.tscn",
	"res://scenes/r6/67.tscn",
	"res://scenes/r7/71.tscn",
	"res://scenes/r7/72.tscn",
	"res://scenes/r7/73.tscn",
	"res://scenes/r7/74.tscn",
	"res://scenes/r7/75.tscn",
	"res://scenes/r7/76.tscn",
	"res://scenes/r7/77.tscn",
	"res://scenes/r8/81.tscn",
	"res://scenes/r8/82.tscn",
	"res://scenes/r8/83.tscn",
	"res://scenes/r8/84.tscn",
	"res://scenes/r8/85.tscn",
	"res://scenes/r8/86.tscn",
	"res://scenes/r8/87.tscn",
	"res://scenes/r9/91.tscn",
	"res://scenes/r9/92.tscn",
	"res://scenes/r9/93.tscn",
	"res://scenes/r9/94.tscn",
	"res://scenes/r9/95.tscn",
	"res://scenes/r9/96.tscn",
	"res://scenes/r9/97.tscn",
	"res://scenes/r10/101.tscn",
	"res://scenes/r10/102.tscn",
	"res://scenes/r10/103.tscn",
	"res://scenes/r10/104.tscn",
	"res://scenes/r10/105.tscn",
	"res://scenes/r10/106.tscn",
	"res://scenes/r10/107.tscn",
	"res://scenes/r11/111.tscn",
	"res://scenes/r11/112.tscn",
	"res://scenes/r11/113.tscn",
	"res://scenes/r11/114.tscn",
	"res://scenes/r11/115.tscn",
	"res://scenes/r11/116.tscn",
	"res://scenes/r11/117.tscn",
]

func _ready():
	pressed.connect(_on_pressed)
	_set_next_scene()

func _set_next_scene():
	if scenes.is_empty():
		push_warning("⚠️ No scenes in list")
		return

	next_scene_index = randi() % scenes.size()
	var scene_path = scenes[next_scene_index]

	if ResourceLoader.exists(scene_path):
		scene_to_place = load(scene_path)
		print("🎲 Random scene selected:", scene_path)
	else:
		push_warning("⚠️ Missing scene: " + scene_path)

	# Update label to show current index
	index_label.text = str(next_scene_index)

func _on_pressed():
	var main_node = get_tree().get_current_scene().get_node("camera")
	if not main_node or not main_node.has_method("set_selected_scene"):
		push_warning("Main node missing or has no set_selected_scene method")
		return

	if scene_to_place == null:
		print("⚠️ No scene_to_place for", name)
		return

	main_node.set_selected_scene(scene_to_place)
	print("✅", name, "selected:", scene_to_place.resource_path)

	# 🔁 Pick a new random tile for next press
	_set_next_scene()
