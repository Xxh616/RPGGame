extends Node2D

func _process(delta):
	change_sence()


func change_sence():
	
	if global.transition_scene:
		if global.current_scene=="cliffside":
			get_tree().change_scene_to_file("res://scenes/world.tscn")
			global.current_scene="world"
			global.transition_scene=false

func _on_cliffside_transitionpoint_body_entered(body):
	if body.has_method("player"):
		global.transition_scene=true
		


func _on_cliffside_transitionpoint_body_exited(body):
	if body.has_method("player"):
		global.transition_scene=false
