# ReturnState.gd
extends State

func enter(prev_state:String) -> void:
	owner.play_animation("run")  # 返回时也可以用跑步动画

func physics_update(delta: float) -> void:
	# 返回到最近的巡逻点或 idle 点
	var return_target = owner.patrol_points[owner.patrol_index]
	var dir = (return_target - owner.global_position).normalized()
	owner.velocity = dir * owner.speed
	owner.move_and_slide()

	# 距离足够近后，回到巡逻状态
	if owner.global_position.distance_to(return_target) < 8.0:
		owner.change_state(owner.States.PATROL)

func process(delta: float) -> void:
	pass
