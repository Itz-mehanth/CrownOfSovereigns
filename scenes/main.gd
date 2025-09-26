extends Node3D

@export var rotate_sensitivity: float = 0.001
@export var pan_speed: float = 0.01
@export var zoom_speed: float = 0.01
@export var min_pitch: float = -80.0
@export var max_pitch: float = 80.0

var yaw: float = 0.0
var pitch: float = 0.0

var touches := {}   # stores active touches: { index: position }
var last_pinch_dist: float = 0.0

@onready var cam: Camera3D = $Camera3D
@export var tile_scene: PackedScene   # assign your GLTF/GLB tile scene in the Inspector

func place_tile_at_screen_pos(screen_pos: Vector2) -> void:
	# Cast ray from camera into 3D world (Godot 4 style)
	var from: Vector3 = cam.project_ray_origin(screen_pos)
	var to: Vector3 = from + cam.project_ray_normal(screen_pos) * 1000.0

	var space_state = get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, to)
	# optional: tune the query
	query.collide_with_areas = false
	query.collide_with_bodies = true
	# query.exclude = [self.get_rid()]  # if you need to exclude nodes
	# query.collision_mask = 0xFFFFFFFF  # adjust if you use masks

	var result = space_state.intersect_ray(query)  # <-- Godot 4 correct call

	if result and result.has("position"):
		if tile_scene == null:
			push_warning("tile_scene not assigned in Inspector!")
			return
		var tile: Node3D = tile_scene.instantiate()
		tile.global_transform.origin = result["position"]
		add_child(tile)
		print("✅ Placed tile at: ", result["position"])
	else:
		print("⚠️ No collision under screen pos: ", screen_pos)


func _input(event: InputEvent) -> void:
	# keep camera variable local to avoid repeated node lookups
	var cam: Camera3D = $Camera3D

	# --- Track touches ---
	if event is InputEventScreenTouch:
		if event.pressed:
			touches[event.index] = event.position
		else:
			touches.erase(event.index)
			last_pinch_dist = 0.0  # reset pinch when a finger lifts

	elif event is InputEventScreenDrag:
		touches[event.index] = event.position

		if touches.size() == 1:
			# --- One finger drag → Orbit ---
			yaw -= event.relative.x * rotate_sensitivity
			pitch -= event.relative.y * rotate_sensitivity
			pitch = clamp(pitch, min_pitch, max_pitch)
			rotation_degrees = Vector3(pitch, yaw, 0)

		elif touches.size() == 2:
			var points = touches.values()
			var pos1: Vector2 = points[0]
			var pos2: Vector2 = points[1]

			# --- Two finger drag → Pan ---
			var pan: Vector3 = (-cam.global_transform.basis.x * event.relative.x +
								cam.global_transform.basis.y * event.relative.y) * pan_speed
			translate(pan)

			# --- Pinch → Zoom ---
			var dist: float = pos1.distance_to(pos2)
			if last_pinch_dist != 0.0:
				var zoom_amount: float = (last_pinch_dist - dist) * zoom_speed
				cam.translate_object_local(Vector3(0, 0, zoom_amount))
			last_pinch_dist = dist
