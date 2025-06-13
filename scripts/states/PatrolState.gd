extends State

var point_reach_tolerance := 8.0  # Distance tolerance to consider a patrol point reached

func enter(prev_state:String) -> void:
	# When entering the Patrol state, start playing the walk animation
	owner.play_animation("walk")

func physics_update(delta: float) -> void:
	# 1) If the player enters chase range, switch to CHASE state immediately
	if owner.is_player_in_chase_range():
		owner.change_state(owner.States.CHASE)
		return

	# 2) Compute movement vector toward the current patrol target and move
	var target_pos = owner.patrol_points[owner.patrol_index]
	var dir = (target_pos - owner.global_position).normalized()
	owner.velocity = dir * owner.config.speed
	owner.move_and_slide()

	# 3) If within tolerance of the patrol point, advance to the next one
	if owner.global_position.distance_to(target_pos) <= point_reach_tolerance:
		owner.patrol_index = (owner.patrol_index + 1) % owner.patrol_points.size()

	# 4) Always replay the walk animation each frame based on velocity
	#    This ensures the flip_h logic inside play_animation() is applied
	owner.play_animation("walk")
