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
	"res://assets/ui/forest.png"  # Use one image for now
]

@export var fallback_image: String = "res://assets/ui/forest.png"  # used when a preview is missing
@export var tile_size: Vector2 = Vector2(250, 250)                 # button width/height
@export var tile_spacing: int = 8                                 # spacing between tiles (px)
@export var double_click_ms: int = 300                            # double-click time window (ms)

@onready var vbox: VBoxContainer = $ScrollContainer/VBoxContainer

signal tile_selected(tile_path: String)

var selected_button: Button = null
var last_click_times: Dictionary = {}  # per-button last click time in ms

func _ready():
	$ScrollContainer.mouse_filter = Control.MOUSE_FILTER_STOP
	_populate_tiles()

func _populate_tiles():
	# Clear previous
	for child in vbox.get_children():
		child.queue_free()

	for i in range(tile_scenes.size()):
		var scene_path: String = tile_scenes[i]
		var image_path: String = tile_images[0]

		# Outer wrapper for spacing
		var wrapper := VBoxContainer.new()
		wrapper.custom_minimum_size = tile_size
		wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.add_child(wrapper)

		# Button
		var btn := Button.new()
		btn.name = scene_path.get_file()
		btn.custom_minimum_size = tile_size
		btn.focus_mode = Control.FOCUS_NONE
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.size_flags_vertical = Control.SIZE_EXPAND_FILL

		# Texture container
		var tex_rect := TextureRect.new()
		if ResourceLoader.exists(image_path):
			tex_rect.texture = load(image_path)
		elif ResourceLoader.exists(fallback_image):
			tex_rect.texture = load(fallback_image)

		# ✅ ensure texture shows fully
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE  # ensures fill
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tex_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
		tex_rect.custom_minimum_size = tile_size
		tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(tex_rect)

		# Fallback label if texture missing
		if tex_rect.texture == null:
			var lbl := Label.new()
			lbl.text = scene_path.get_file()
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
			btn.add_child(lbl)

		# Double-click connection
		btn.connect("gui_input", Callable(self, "_on_button_gui_input").bind(btn, scene_path))
		wrapper.add_child(btn)

	# Adjust scrollable height
	var total_height = tile_scenes.size() * (tile_size.y + tile_spacing)
	vbox.custom_minimum_size = Vector2(0, total_height)
	vbox.add_theme_constant_override("separation", tile_spacing)

func _on_button_gui_input(event: InputEvent, btn: Button, scene_path: String) -> void:
	# Only consider left-button presses
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var now_ms = Time.get_ticks_msec()
		var last_ms = 0
		if last_click_times.has(btn):
			last_ms = last_click_times[btn]
		# Double-click if within configured ms window
		if now_ms - last_ms <= double_click_ms:
			_select_tile(btn, scene_path)
		# update last click time
		last_click_times[btn] = now_ms

func _select_tile(btn: Button, scene_path: String) -> void:
	# Remove highlight from previous
	if selected_button and is_instance_valid(selected_button):
		# Reset normal state
		var default_style := StyleBoxFlat.new()
		default_style.bg_color = Color(1,1,1,0) # transparent or whatever your default
		selected_button.add_theme_stylebox_override("normal", default_style)

	# Apply highlight (only background color, safe properties)
	selected_button = btn
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.55, 0.1, 0.25)  # subtle orange tint
	btn.add_theme_stylebox_override("normal", style)

	emit_signal("tile_selected", scene_path)
	print("Selected tile:", scene_path)
