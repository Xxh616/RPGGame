# res://scripts/states/ReturnState.gd
extends State

func enter(prev_state:String) -> void:
	owner.play_animation("walk")

func physics_update(delta: float) -> void:
	# 这里假设你把回家的目标存到 owner.return_point
	var dir = (owner.return_point - owner.global_position).normalized()
	owner.velocity = dir * owner.config.speed
	owner.move_and_slide()

	# 到家后切 IDLE 或 PATROL
	if owner.global_position.distance_to(owner.return_point) < 5.0:
		owner.change_state(owner.States.IDLE)
		return

	# —— 保证每帧都调用：让 play_animation() 根据 velocity.x<0 翻转 —— 
	owner.play_animation("walk")
