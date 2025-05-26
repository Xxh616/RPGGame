extends Node2D
func _ready():
	if global.game_first_load:
		$player.position.x=global.player_start_posx
		$player.position.y=global.player_start_posy
	else:
		$player.position.x=global.player_exited_cliffside_posx
		$player.position.y=global.player_exited_cliffside_posy
func _process(delta):
	change_sence()
func _on_transition_point_body_entered(body):
	if body.has_method("player"):
		global.transition_scene=true


func _on_transition_point_body_exited(body) :
	if body.has_method("player"):
		global.transition_scene=false
func change_sence():
	if global.transition_scene:
		if global.current_scene=="world":
			get_tree().change_scene_to_file("res://scenes/cliffside.tscn")
			global.game_first_load=false
			global.current_scene="cliffside"
			global.transition_scene=false
			
