extends VideoStreamPlayer


func on_VideoPlayer_finished():
	print("Intro video finished!")
	get_tree().change_scene("res://scenes/main.tscn")
