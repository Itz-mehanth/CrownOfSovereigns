extends Node2D

# Path to the main scene to load after intro
@export var main_scene_path: String = "res://scenes/main.tscn"
@onready var video_player: VideoStreamPlayer = $VideoStreamPlayer

# Fallback timer in case finished signal doesn't fire
@export var fallback_time: float = 7.0  # adjust based on your video length

func _ready():
	print("🎬 Intro scene started")
	
	# Make video fullscreen
	if video_player:
	
		if video_player.stream != null:
			video_player.play()
			print("▶️ Playing intro video")
			if video_player.stream.has_method("get_length"):
				print("⏱️ Video duration:", video_player.stream.get_length())
		else:
			push_warning("⚠️ VideoStreamPlayer has no video assigned!")
			go_to_main_scene()
		
		# Connect finished signal
		video_player.finished.connect(_on_video_finished)
		print("🔌 Connected finished signal")
	else:
		push_error("❌ VideoStreamPlayer node not found")
		go_to_main_scene()
	
	# Fallback timer
	create_fallback_timer()

func create_fallback_timer():
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = fallback_time
	timer.one_shot = true
	timer.timeout.connect(_on_fallback_timeout)
	timer.start()

func _on_fallback_timeout():
	print("⏰ Fallback timer triggered - going to main scene")
	go_to_main_scene()

func _on_video_finished():
	print("✅ Intro video finished")
	go_to_main_scene()

func go_to_main_scene():
	print("🚀 Transitioning to main scene...")
	
	if ResourceLoader.exists(main_scene_path):
		print("✅ Main scene file exists:", main_scene_path)
		var err = get_tree().change_scene_to_file(main_scene_path)
		if err != OK:
			push_error("❌ Failed to load main scene. Error code: " + str(err))
		else:
			print("✅ Scene change initiated successfully")
	else:
		push_error("❌ Main scene not found at path: " + main_scene_path)
		list_files_in_directory("res://scenes/")

func list_files_in_directory(path: String):
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			print("  - " + file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		print("❌ Could not open directory:", path)

func _input(event):
	# Skip intro on any key press or mouse click
	if event.is_pressed():
		print("⏭️ User input detected - skipping intro")
		go_to_main_scene()
