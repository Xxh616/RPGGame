extends BossState
class_name BossChaseState



func _init(_owner: Boss) -> void:
	owner = _owner

func enter(prev_state: String) -> void:
	owner.velocity = Vector2.ZERO
	# 每次进入时设置目标，自动重算路径
	owner.agent.target_position = owner.player_node.global_position

func physics_update(delta: float) -> void:
	if owner.player_in_safe_zone:
		owner.change_state(owner.States.RETURN)
		return
	var target_pos = owner.player_node.global_position

	# 到攻击距离且冷却结束，切攻击
	if owner.global_position.distance_to(target_pos) <= owner.stopping_distance \
	   and owner.time_since_last_attack >= owner.attack_cooldown:
		owner.change_state(owner.States.ATTACK)
		return

	# 不在追击范围，先回 Idle
	if not owner.is_player_in_chase_range():
		owner.change_state(owner.States.IDLE)
		return

	# 更新目标并移动
	owner.agent.target_position = target_pos
	if owner.agent.is_navigation_finished():
		return

	var next_point = owner.agent.get_next_path_position()
	var dir = (next_point - owner.global_position).normalized()
	owner.velocity = dir * owner.chase_speed

	# 播放对应方向行走动画
	if abs(dir.x) > abs(dir.y):
		owner.anim_sprite.play("walk_right")
		owner.anim_sprite.flip_h = dir.x < 0
		owner.last_facing_dir = "left" if dir.x < 0   else "right"
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
