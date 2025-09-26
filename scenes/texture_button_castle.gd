extends TextureButton

@onready var camera: Camera3D = get_viewport().get_camera_3d()
var scene_to_place: PackedScene
var is_selected: bool = false

static var occupied_cells: Dictionary = {}

# 🔧 SINGLETON: Track which button is currently selected
static var selected_button: TextureButton = null
static var shared_grid_visual: Node3D = null

# Scene mapping based on button names
var scene_map: Dictionary = {
	#"CastleButton": "res://scenes/tile_castle.tscn",
	#"ForestButton": "res://scenes/tile_forest.tscn",
	#"YellowButton": "res://scenes/tile_yellow.tscn",
	#"GreenButton": "res://scenes/tile_green.tscn",
	#"GrassButton": "res://scenes/tile_grass.tscn",
	#"RedMonasteryButton": "res://scenes/r1/11.tscn",
	#"BlueMonasteryButton": "res://scenes/tile_monastery_blue.tscn",
	"CastleButton": "res://scenes/r1/11.tscn",
	"ForestButton": "res://scenes/r1/12.tscn",
	"YellowButton": "res://scenes/r1/13.tscn",
	"GreenButton": "res://scenes/r1/14.tscn",
	"GrassButton": "res://scenes/r1/15.tscn",
	"RedMonasteryButton": "res://scenes/r1/16.tscn",
	"BlueMonasteryButton": "res://scenes/r1/17.tscn",
}

# --- Grid settings ---
const GRID_SIZE: float = 10.0
const GRID_DIM: int = 9
const GROUND_Y: float = 0
@export var GRID_ORIGIN: Vector3 = Vector3(0, 0, 0)

# 🔧 DEBUG: Visual feedback
@onready var debug_sphere: MeshInstance3D

func _ready():
	pressed.connect(_on_pressed)
	create_debug_sphere()
	
	# Only create grid once (shared between all buttons)
	if shared_grid_visual == null:
		create_shared_grid_visual()
	
	load_scene_for_button()

func load_scene_for_button():
	"""Load the appropriate scene based on button name"""
	var button_name = self.name
	print("🎯 Button name:", button_name)
	
	if scene_map.has(button_name):
		var scene_path = scene_map[button_name]
		print("🎯 Loading scene:", scene_path)
		
		# Check if file exists before loading
		if ResourceLoader.exists(scene_path):
			scene_to_place = load(scene_path)
			print("✅ Scene loaded successfully:", scene_path)
		else:
			print("❌ Scene file not found:", scene_path)
			print("   - Using default castle scene as fallback")
			scene_to_place = load("res://scenes/tile_castle.tscn")
	else:
		print("❌ Unknown button name:", button_name)
		print("   - Available button names:", scene_map.keys())
		print("   - Using default castle scene as fallback")
		scene_to_place = load("res://scenes/tile_castle.tscn")

func create_debug_sphere():
	# Create a small sphere to show exact hit position
	debug_sphere = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.2
	sphere_mesh.height = 0.4
	debug_sphere.mesh = sphere_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.RED
	debug_sphere.material_override = material
	
	get_tree().current_scene.add_child(debug_sphere)
	debug_sphere.visible = false

func create_shared_grid_visual():
	"""Create a single shared grid for all buttons"""
	shared_grid_visual = Node3D.new()
	shared_grid_visual.name = "SharedGridVisual"
	get_tree().current_scene.add_child(shared_grid_visual)
	
	print("🔧 Creating shared grid at GROUND_Y:", GROUND_Y, " GRID_ORIGIN:", GRID_ORIGIN)
	
	var half_range = (GRID_DIM - 1) / 2.0  # 4.5 for 10x10
	
	# Create a very visible material
	var bright_material = StandardMaterial3D.new()
	bright_material.flags_unshaded = true
	bright_material.albedo_color = Color.CYAN  # Bright cyan
	bright_material.emission = Color.CYAN * 0.3
	
	# Create cell material
	var cell_material = StandardMaterial3D.new()
	cell_material.flags_unshaded = true  
	cell_material.flags_transparent = true
	cell_material.albedo_color = Color(1, 1, 0, 0.3)  # Yellow with transparency
	
	# Create simple cubes at each grid intersection
	for i in range(GRID_DIM + 1):
		for j in range(GRID_DIM + 1):
			var x_pos = (i - half_range - 0.5) * GRID_SIZE + GRID_ORIGIN.x
			var z_pos = (j - half_range - 0.5) * GRID_SIZE + GRID_ORIGIN.z
			
			var marker = MeshInstance3D.new()
			var box_mesh = BoxMesh.new()
			box_mesh.size = Vector3(0.15, 0.8, 0.15)  # Thin tall markers
			marker.mesh = box_mesh
			marker.material_override = bright_material
			marker.position = Vector3(x_pos, GROUND_Y + 0.4, z_pos)
			shared_grid_visual.add_child(marker)
	
	# Create cell highlights
	for x in range(-int(half_range), int(half_range) + 1):
		for z in range(-int(half_range), int(half_range) + 1):
			var cell_center = Vector3(
				x * GRID_SIZE + GRID_ORIGIN.x,
				GROUND_Y + 0.05,
				z * GRID_SIZE + GRID_ORIGIN.z
			)
			
			var cell = MeshInstance3D.new()
			var plane = PlaneMesh.new()
			plane.size = Vector2(GRID_SIZE * 0.8, GRID_SIZE * 0.8)
			cell.mesh = plane
			cell.material_override = cell_material
			cell.position = cell_center
			cell.rotation_degrees = Vector3(-90, 0, 0)
			shared_grid_visual.add_child(cell)
			
			# Add a small cube at center for extra visibility
			var center_marker = MeshInstance3D.new()
			var small_box = BoxMesh.new()
			small_box.size = Vector3(0.3, 0.1, 0.3)
			center_marker.mesh = small_box
			center_marker.material_override = bright_material
			center_marker.position = Vector3(cell_center.x, cell_center.y + 0.05, cell_center.z)
			shared_grid_visual.add_child(center_marker)
	
	# Add origin marker
	var origin_marker = MeshInstance3D.new()
	var origin_sphere = SphereMesh.new()
	origin_sphere.radius = 0.3
	var origin_material = StandardMaterial3D.new()
	origin_material.albedo_color = Color.RED
	origin_material.emission = Color.RED * 0.3
	origin_marker.mesh = origin_sphere
	origin_marker.material_override = origin_material
	origin_marker.position = Vector3(GRID_ORIGIN.x, GROUND_Y + 0.8, GRID_ORIGIN.z)
	shared_grid_visual.add_child(origin_marker)
	
	shared_grid_visual.visible = false  # Start hidden
	print("📐 Shared grid visual created")

func _on_pressed():
	# Deselect the previously selected button
	if selected_button != null and selected_button != self:
		selected_button.deselect()
	
	# Toggle this button's selection
	if selected_button == self:
		# Clicking the same button again deselects it
		deselect()
		selected_button = null
		shared_grid_visual.visible = false
		print("❌ All buttons deselected")
	else:
		# Select this button
		select()
		selected_button = self
		shared_grid_visual.visible = true
		print("✅", self.name, "selected → ready to place", scene_to_place.resource_path if scene_to_place else "no scene")

func select():
	"""Select this button"""
	is_selected = true
	modulate = Color(0.5, 1, 0.5)  # Green highlight

func deselect():
	"""Deselect this button"""
	is_selected = false
	modulate = Color(1, 1, 1)  # Normal color

func _unhandled_input(event: InputEvent) -> void:
	# Only the selected button should handle input
	if selected_button != self:
		return
		
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# 🔧 FIX 1: Account for UI offset
		var mouse_pos: Vector2 = event.position
		
		# 🔧 FIX 2: Check if we have a valid camera
		if not camera:
			camera = get_viewport().get_camera_3d()
			if not camera:
				print("❌ No camera found!")
				return
		
		print("🖱️ Raw mouse position:", mouse_pos)
		print("📷 Camera position:", camera.global_position)
		print("📷 Camera rotation:", camera.global_rotation_degrees)
		
		# 🔧 FIX 3: More robust ray calculation
		var from: Vector3 = camera.project_ray_origin(mouse_pos)
		var direction: Vector3 = camera.project_ray_normal(mouse_pos)
		var to: Vector3 = from + direction * 1000.0
		
		print("🔍 Ray from:", from)
		print("🔍 Ray direction:", direction)
		
		var space_state: PhysicsDirectSpaceState3D = get_viewport().get_world_3d().direct_space_state
		var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, to)
		
		# 🔧 FIX 4: Ensure we're only hitting the ground
		query.collide_with_areas = false
		query.collide_with_bodies = true
		# Optionally set collision mask if you have layers
		# query.collision_mask = 1  # Only layer 1
		
		var result: Dictionary = space_state.intersect_ray(query)
		
		if result.has("position") and scene_to_place != null:
			var hit_pos: Vector3 = result["position"]
			var hit_object = result.get("collider")
			var hit_normal: Vector3 = result.get("normal", Vector3.UP)
			
			print("🎯 Hit object:", hit_object.name if hit_object else "Unknown")
			print("🎯 Hit position:", hit_pos)
			print("🎯 Hit normal:", hit_normal)
			
			# 🔧 Show debug sphere at exact hit position
			debug_sphere.global_position = hit_pos
			debug_sphere.visible = true
			
			# Convert world position to grid indices
			var local_x = (hit_pos.x - GRID_ORIGIN.x) / GRID_SIZE
			var local_z = (hit_pos.z - GRID_ORIGIN.z) / GRID_SIZE
			var grid_x = round(local_x)
			var grid_z = round(local_z)
			
			print("🧮 Local coords: (", local_x, ",", local_z, ")")
			print("🧮 Grid indices: (", grid_x, ",", grid_z, ")")
			
			# Proper 10x10 bounds
			var half_range = (GRID_DIM - 1) / 2.0  # 4.5 for 10x10
			
			if abs(grid_x) <= half_range and abs(grid_z) <= half_range:
				var snapped_x = grid_x * GRID_SIZE + GRID_ORIGIN.x
				var snapped_z = grid_z * GRID_SIZE + GRID_ORIGIN.z
				
				# 🔧 FIX 5: Use hit Y position or add small offset above ground
				var snapped_pos = Vector3(snapped_x, hit_pos.y + 0.1, snapped_z)
				
				print("📍 Snapped position:", snapped_pos)
				print("📏 Distance from hit to snap:", hit_pos.distance_to(snapped_pos))
				
				var tile: Node3D = scene_to_place.instantiate()
				get_tree().current_scene.add_child(tile)
				tile.global_transform.origin = snapped_pos
				
				print("✅ Tile placed successfully!")
				
				# Hide debug sphere after a moment
				await get_tree().create_timer(2.0).timeout
				debug_sphere.visible = false
				
			else:
				print("⚠️ Outside grid bounds (", grid_x, ",", grid_z, ") - allowed: ±", half_range)

			var cell_key = str(grid_x) + "," + str(grid_z)

			if occupied_cells.has(cell_key):
				print("🚫 Cell already occupied:", cell_key)
				_show_popup("Cell already occupied!")
				return
			else:
				# Place the tile
				var snapped_x = grid_x * GRID_SIZE + GRID_ORIGIN.x
				var snapped_z = grid_z * GRID_SIZE + GRID_ORIGIN.z
				var snapped_pos = Vector3(snapped_x, hit_pos.y + 0.1, snapped_z)

				var tile: Node3D = scene_to_place.instantiate()
				get_tree().current_scene.add_child(tile)
				tile.global_transform.origin = snapped_pos

				# Mark cell as occupied
				occupied_cells[cell_key] = tile
				print("✅ Tile placed at cell:", cell_key)
		else:
			print("⚠️ No collision detected")
			if not result.has("position"):
				print("   - Raycast missed everything")
			if not scene_to_place:
				print("   - No scene to place")
				
			

func _show_popup(message: String):
	var popup = get_tree().current_scene.get_node("Popup")
	popup.get_node("Label").text = message
	popup.popup_centered()
	
# 🔧 ALTERNATIVE: Manual ground plane intersection
func intersect_ground_plane(ray_origin: Vector3, ray_direction: Vector3, ground_y: float = GROUND_Y) -> Vector3:
	"""Calculate intersection with a horizontal plane at ground_y"""
	if abs(ray_direction.y) < 0.001:  # Ray is nearly horizontal
		return Vector3.ZERO
	
	var t = (ground_y - ray_origin.y) / ray_direction.y
	if t < 0:  # Intersection is behind camera
		return Vector3.ZERO
	
	var intersection = ray_origin + ray_direction * t
	print("🎯 Manual ground intersection:", intersection)
	return intersection
