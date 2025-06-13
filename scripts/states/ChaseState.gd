extends RefCounted
class_name ChaseState

var owner

func _init(_owner):
	owner = _owner

func enter(prev_state: String) -> void:
	# Upon entering chase, play the walk animation.
	# Movement speed uses run_speed, but the animation remains "walk".
	owner.play_animation("walk")

func physics_update(delta: float) -> void:
	# If the player is within attack range, switch to ATTACK state
	if owner.is_player_in_attack_range():
		owner.change_state(owner.States.ATTACK)
		return
	# If the player is lost from sight, switch to RETURN state
	if owner.is_player_lost_sight():
		owner.change_state(owner.States.RETURN)
		return

	# Calculate direction toward the player, move using run_speed, and slide
	var dir_vec: Vector2 = (owner.player.global_position - owner.global_position).normalized()
	owner.velocity = dir_vec * owner.config.run_speed
	owner.move_and_slide()
	# Always play the "walk" animation, even though the character runs faster
	owner.play_animation("walk")

func exit(next_state: String) -> void:
	# Stop movement when exiting the chase state
	owner.velocity = Vector2.ZERO

func process(delta: float) -> void:
	# No additional non-physics logic needed in chase
	pass
