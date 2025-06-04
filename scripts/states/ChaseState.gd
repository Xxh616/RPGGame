# ChaseState.gd
extends RefCounted    # (Godot 4 用 RefCounted；Godot 3 用 Reference)
class_name ChaseState

var owner

func _init(_owner):
	owner = _owner

func enter(prev_state: String) -> void:
	# 进入追击时改播放 walk，虽然速度用 run_speed，但动画仍是 walk
	owner.play_animation("walk")

func physics_update(delta: float) -> void:
	
	if owner.is_player_in_attack_range():
		owner.change_state(owner.States.ATTACK)
		return
	if owner.is_player_lost_sight():
		owner.change_state(owner.States.RETURN)
		return

	var dir_vec: Vector2 = (owner.player.global_position - owner.global_position).normalized()
	owner.velocity = dir_vec * owner.config.run_speed   # 速度用 run_speed
	owner.move_and_slide()
	owner.play_animation("walk")  # 始终播放“走”动画，只是角色跑得更快

func exit(next_state: String) -> void:
	owner.velocity = Vector2.ZERO

func process(delta: float) -> void:
	pass
