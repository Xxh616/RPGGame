# res://scripts/states/ReturnState.gd
extends State

func enter(prev_state: String) -> void:
	# Play the walking animation when entering the return state
	owner.play_animation("walk")

func physics_update(delta: float) -> void:
	# Calculate direction toward the return point and move there
	var dir = (owner.return_point - owner.global_position).normalized()
	owner.velocity = dir * owner.config.speed
	owner.move_and_slide()

	# Once close enough to the return point, switch to IDLE state
	if owner.global_position.distance_to(owner.return_point) < 5.0:
		owner.change_state(owner.States.IDLE)
		return

	# Always replay the walk animation each frame to apply flip_h based on velocity
	owner.play_animation("walk")
