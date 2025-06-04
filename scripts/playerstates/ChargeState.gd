# res://scripts/playerstates/ChargeState.gd
extends PlayerState
class_name PlayerChargeState

func _init(_owner) -> void:
	owner = _owner

func enter(prev_state: String) -> void:
	# 进入蓄力：打开进度条，重置 charge_time
	owner.is_charging = true
	owner.charge_time = 0.0

	# 假设你在 Player.gd 里用 @onready var charge_bar = $ChargeBar 缓存了引用
	owner.charge_bar.visible = true
	owner.charge_bar.value = 0

	# 播放蓄力时的初始动画。示例：蓄力时一律播放 “down_charge”、“up_charge”或“side_charge”
	var base_dir = owner.current_dir if owner.current_dir in ["up", "down"] else "side"
	owner.PlayAnim("%s_walk" % base_dir, true)

	# 一进入状态，velocity 也先归零
	owner.velocity = Vector2.ZERO

func physics_update(delta: float) -> void:
	# —— 1) 如果仍在按住“attack”，继续累加 charge_time 并刷新进度条 —— 
	if Input.is_action_pressed("attack"):
		owner.charge_time += delta
		var ratio = owner.charge_time / owner.max_charge_time
		owner.charge_bar.value = min(ratio * 100, 100)

		# 超过最大值时让它变红或闪烁
		if ratio >= 1.0:
			owner.charge_bar.modulate = Color(1, 0, 0)
		else:
			owner.charge_bar.modulate = Color(1, 1, 1)

		# 同时允许玩家在蓄力时踩方向键“缓慢滑动”
		var dir_vec := Vector2.ZERO
		if Input.is_action_pressed("ui_right"):
			dir_vec.x += 1
		if Input.is_action_pressed("ui_left"):
			dir_vec.x -= 1
		if Input.is_action_pressed("ui_down"):
			dir_vec.y += 1
		if Input.is_action_pressed("ui_up"):
			dir_vec.y -= 1

		if dir_vec != Vector2.ZERO:
			dir_vec = dir_vec.normalized()
			owner.velocity = dir_vec * owner.charge_move_speed
			# **不要在这里调用 move_and_slide()**，由 Player.gd 最后一行统一执行
			# owner.move_and_slide()

			# 播放对应方向的“蓄力中慢跑”动画
			var new_dir = owner.current_dir
			if abs(dir_vec.x) > abs(dir_vec.y):
				new_dir = "right" if dir_vec.x > 0 else "left"
				owner.PlayAnim("run_side", owner.current_dir != new_dir)
			else:
				new_dir = "down" if dir_vec.y > 0 else "up"
				owner.PlayAnim("%s_run" % new_dir, owner.current_dir != new_dir)
			owner.current_dir = new_dir

		# 如果血量见底，切到 Dead
		if global.player_health <= 0:
			owner.change_state(owner.States.DEAD)
			return

		# 早返回，后续“松开键”逻辑留到下面
		return
	# —— 2) 松开“attack”键 —— 
	owner.is_charging = false
	owner.charge_bar.visible = false
	owner.charge_bar.value = 0

	if owner.charge_time >= owner.max_charge_time:
		# 切到重击
		owner.change_state(owner.States.HEAVY_ATTACK)
		return    # 一定要 return，避免执行后面“踩键移动”块
	else:
		# 切到普通连击
		owner.change_state(owner.States.ATTACK)
		return    # 一定要 return

	# （下方不再写“踩键移动”或其他逻辑，因为上面两条 return 已经把流程拦住了）

func process(delta: float) -> void:
	# 蓄力状态一般不需要做其它处理，但你也可以在这里刷新选中掉落物
	owner._refresh_drop_labels()

func exit(next_state: String) -> void:
	# 离开蓄力状态时，确保 velocity 清零，不让角色继续滑动
	owner.velocity = Vector2.ZERO
