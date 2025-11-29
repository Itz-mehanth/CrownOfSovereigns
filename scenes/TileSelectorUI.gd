extends Control

@export var tile_scenes: Array = [
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

var tile_images: Array = [
	"res://assets/TileImages/r11/117.jpg", "res://assets/TileImages/r11/116.jpg", "res://assets/TileImages/r11/115.jpg",
	"res://assets/TileImages/r11/114.jpg", "res://assets/TileImages/r11/113.jpg", "res://assets/TileImages/r11/112.jpg",
	"res://assets/TileImages/r11/111.jpg", "res://assets/TileImages/r10/107.jpg", "res://assets/TileImages/r10/106.jpg",
	"res://assets/TileImages/r10/105.jpg", "res://assets/TileImages/r10/104.jpg", "res://assets/TileImages/r10/103.jpg",
	"res://assets/TileImages/r10/102.jpg", "res://assets/TileImages/r10/101.jpg", "res://assets/TileImages/r9/97.jpg",
	"res://assets/TileImages/r9/96.jpg", "res://assets/TileImages/r9/95.jpg", "res://assets/TileImages/r9/94.jpg",
	"res://assets/TileImages/r9/93.jpg", "res://assets/TileImages/r9/92.jpg", "res://assets/TileImages/r9/91.jpg",
	"res://assets/TileImages/r8/87.jpg", "res://assets/TileImages/r8/86.jpg", "res://assets/TileImages/r8/85.jpg",
	"res://assets/TileImages/r8/84.jpg", "res://assets/TileImages/r8/83.jpg", "res://assets/TileImages/r8/82.jpg",
	"res://assets/TileImages/r8/81.jpg", "res://assets/TileImages/r7/77.jpg", "res://assets/TileImages/r7/76.jpg",
	"res://assets/TileImages/r7/75.jpg", "res://assets/TileImages/r7/74.jpg", "res://assets/TileImages/r7/73.jpg",
	"res://assets/TileImages/r7/72.jpg", "res://assets/TileImages/r7/71.jpg", "res://assets/TileImages/r6/67.jpg",
	"res://assets/TileImages/r6/66.jpg", "res://assets/TileImages/r6/65.jpg", "res://assets/TileImages/r6/64.jpg",
	"res://assets/TileImages/r6/63.jpg", "res://assets/TileImages/r6/62.jpg", "res://assets/TileImages/r6/61.jpg",
	"res://assets/TileImages/r5/57.jpg", "res://assets/TileImages/r5/56.jpg", "res://assets/TileImages/r5/55.jpg",
	"res://assets/TileImages/r5/54.jpg", "res://assets/TileImages/r5/53.jpg", "res://assets/TileImages/r5/52.jpg",
	"res://assets/TileImages/r5/51.jpg", "res://assets/TileImages/r4/47.jpg", "res://assets/TileImages/r4/46.jpg",
	"res://assets/TileImages/r4/45.jpg", "res://assets/TileImages/r4/44.jpg", "res://assets/TileImages/r4/43.jpg",
	"res://assets/TileImages/r4/42.jpg", "res://assets/TileImages/r4/41.jpg", "res://assets/TileImages/r3/37.jpg",
	"res://assets/TileImages/r3/36.jpg", "res://assets/TileImages/r3/35.jpg", "res://assets/TileImages/r3/34.jpg",
	"res://assets/TileImages/r3/33.jpg", "res://assets/TileImages/r3/32.jpg", "res://assets/TileImages/r3/31.jpg",
	"res://assets/TileImages/r2/27.jpg", "res://assets/TileImages/r2/26.jpg", "res://assets/TileImages/r2/25.jpg",
	"res://assets/TileImages/r2/24.jpg", "res://assets/TileImages/r2/23.jpg", "res://assets/TileImages/r2/22.jpg",
	"res://assets/TileImages/r2/21.jpg", "res://assets/TileImages/r1/17.jpg", "res://assets/TileImages/r1/16.jpg",
	"res://assets/TileImages/r1/15.jpg", "res://assets/TileImages/r1/14.jpg", "res://assets/TileImages/r1/13.jpg",
	"res://assets/TileImages/r1/12.jpg", "res://assets/TileImages/r1/11.jpg"
]

@export var fallback_image: String = "res://assets/ui/forest.png"
@export var tile_size: Vector2 = Vector2(250, 250)
@export var tile_spacing: int = 8
@export var double_click_ms: int = 300

@onready var vbox: VBoxContainer = $ScrollContainer/VBoxContainer

signal tile_selected(tile_path: String)

var selected_button: Button = null
var last_click_times: Dictionary = {}  # per-button last click time in ms

func _ready():
	$ScrollContainer.mouse_filter = Control.MOUSE_FILTER_STOP
	_populate_tiles()

func _populate_tiles():
	# Clear previous tiles
	for child in vbox.get_children():
		child.queue_free()

	for i in range(tile_scenes.size()):
		var scene_path = tile_scenes[i]
		
		var wrapper = VBoxContainer.new()
		wrapper.custom_minimum_size = tile_size
		wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var btn = Button.new()
		btn.set_meta("scene_path", scene_path)
		btn.name = scene_path.get_file()
		btn.custom_minimum_size = tile_size
		btn.focus_mode = Control.FOCUS_NONE
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.size_flags_vertical = Control.SIZE_EXPAND_FILL

		var tex_rect = TextureRect.new()
		if i < tile_images.size() and ResourceLoader.exists(tile_images[i]):
			tex_rect.texture = load(tile_images[i])
		elif ResourceLoader.exists(fallback_image):
			tex_rect.texture = load(fallback_image)
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tex_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
		tex_rect.custom_minimum_size = tile_size
		tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(tex_rect)

		btn.connect("gui_input", Callable(self, "_on_button_gui_input").bind(btn, scene_path))
		wrapper.add_child(btn)
		vbox.add_child(wrapper)

	vbox.custom_minimum_size = Vector2(0, tile_scenes.size() * (tile_size.y + tile_spacing))
	vbox.add_theme_constant_override("separation", tile_spacing)

func _on_button_gui_input(event: InputEvent, btn: Button, scene_path: String) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_select_tile(btn, scene_path)

func _select_tile(btn: Button, scene_path: String) -> void:
	# Highlight selected button
	if selected_button and is_instance_valid(selected_button):
		var default_style = StyleBoxFlat.new()
		default_style.bg_color = Color(1,1,1,0)
		selected_button.add_theme_stylebox_override("normal", default_style)

	selected_button = btn
	var style = StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.55, 0.1, 0.25)
	btn.add_theme_stylebox_override("normal", style)

	# Notify main.gd
	emit_signal("tile_selected", scene_path)
	print("Selected tile:", scene_path)

func remove_tile_button(scene_path: String) -> void:
	call_deferred("_remove_tile_button_deferred", scene_path)

func _remove_tile_button_deferred(scene_path: String) -> void:
	for wrapper in vbox.get_children():
		if wrapper.get_child_count() > 0:
			var btn = wrapper.get_child(0)
			if btn is Button and btn.get_meta("scene_path") == scene_path:
				wrapper.queue_free()
				call_deferred("_update_vbox_size")
				break

func _update_vbox_size():
	var count = vbox.get_child_count()
	vbox.custom_minimum_size = Vector2(0, count * (tile_size.y + tile_spacing))
