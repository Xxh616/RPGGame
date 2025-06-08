# res://scripts/states/PatrolState.gd
extends State

var point_reach_tolerance := 8.0

func enter(prev_state:String) -> void:
	# 一进入 Patrol，就让动画开始播放
	owner.play_animation("walk")

func physics_update(delta: float) -> void:
	# —— 1) 优先切 Chase —— 
	if owner.is_player_in_chase_range():
		owner.change_state(owner.States.CHASE)
		return

	# —— 2) 计算朝当前巡逻目标的移动向量并移动 —— 
	var target_pos = owner.patrol_points[owner.patrol_index]
	var dir = (target_pos - owner.global_position).normalized()
	owner.velocity = dir * owner.config.speed
	owner.move_and_slide()

	# —— 3) 到达当前点后换下一个 —— 
	if owner.global_position.distance_to(target_pos) <= point_reach_tolerance:
		owner.patrol_index = (owner.patrol_index + 1) % owner.patrol_points.size()

	# —— 4) **保证每帧都根据 velocity 重新播放“walk”动画** —— 
	#      这样能让 play_animation() 里的“flip_h”逻辑生效
	owner.play_animation("walk")
