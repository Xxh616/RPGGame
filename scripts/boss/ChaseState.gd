extends BossState
class_name BossChaseState

func _init(_owner: Boss) -> void:
	owner = _owner

func enter(prev_state: String) -> void:
	owner.velocity = Vector2.ZERO
	# Set the target each time we enter and automatically recalculate the path
	owner.agent.target_position = owner.player_node.global_position

func physics_update(delta: float) -> void:
	if owner.player_in_safe_zone:
		owner.change_state(owner.States.RETURN)
		return

	var target_pos = owner.player_node.global_position

	# If within attack range and cooldown is complete, switch to ATTACK
	if owner.global_position.distance_to(target_pos) <= owner.stopping_distance \
	   and owner.time_since_last_attack >= owner.attack_cooldown:
		owner.change_state(owner.States.ATTACK)
		return

	# If no longer in chase range, switch back to IDLE
	if not owner.is_player_in_chase_range():
		owner.change_state(owner.States.IDLE)
		return

	# Update the target and move toward it
	owner.agent.target_position = target_pos
	if owner.agent.is_navigation_finished():
		return

	var next_point = owner.agent.get_next_path_position()
	var dir = (next_point - owner.global_position).normalized()
	owner.velocity = dir * owner.chase_speed

	# Play the walk animation based on movement direction
	if abs(dir.x) > abs(dir.y):
		owner.anim_sprite.play("walk_right")
		owner.anim_sprite.flip_h = dir.x < 0
		owner.last_facing_dir = "left" if dir.x < 0 else "right"
	else:
		if dir.y < 0:
			owner.anim_sprite.play("walk_up")
			owner.last_facing_dir = "up"
		else:
			owner.anim_sprite.play("walk_down")
			owner.last_facing_dir = "down"

	owner.move_and_slide()

func process(delta: float) -> void:
	pass

func exit(next_state: String) -> void:
	pass
