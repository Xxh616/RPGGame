# res://scripts/states/BossReturnState.gd
extends BossState
class_name BossReturnState

func _init(_owner: Boss) -> void:
	owner = _owner

func enter(prev_state: String) -> void:
	# Upon entering RETURN state, set the navigation target to home_position
	owner.agent.target_position = owner.home_position
	owner.velocity = Vector2.ZERO

func physics_update(delta: float) -> void:
	# If not yet at home, follow the path and play walking animation
	if not owner.agent.is_navigation_finished():
		var next_point: Vector2 = owner.agent.get_next_path_position()
		var dir: Vector2 = (next_point - owner.global_position).normalized()
		owner.velocity = dir * owner.chase_speed
		owner.move_and_slide()

		# Choose and play walking animation based on direction
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
	else:
		owner.health = owner.max_health
		# Once home is reached, switch back to Idle
		owner.change_state(owner.States.IDLE)

func process(delta: float) -> void:
	pass

func exit(next_state: String) -> void:
	owner.anim_sprite.play("idle_" + owner.last_facing_dir)
