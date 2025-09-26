extends VideoStreamPlayer


func _on_finished() -> void:
	get_tree().change_scene("res://main.tscn")
