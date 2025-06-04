# res://scripts/playerstates/ChargeState.gd
extends PlayerState
class_name PlayerChargeState

func _init(_owner) -> void:
	owner = _owner

func enter(prev_state: String) -> void:
	# 进入蓄力：打开蓄力条、初始化数据、播放“idle”静止
	owner.is_charging = true
	owner.charge_time = 0.0
	owner.get_node("charge_bar").visible = true
	owner.get_node("charge_bar").value = 0

	var base_dir = owner.current_dir if owner.current_dir in ["up", "down"] else "side"
	var charge_anim = "idle_%s" % base_dir
	owner.PlayAnim(charge_anim, true)

	# 先当作静止
	owner.moving = false
	owner.velocity = Vector2.ZERO

func physics_update(delta: float) -> void:
	# —— 1) 只要 “attack” 还按着，就继续蓄力计算 —— 
	if Input.is_action_pressed("attack"):
		owner.charge_time += delta

		# 更新进度条
		var ratio = owner.charge_time / owner.max_charge_time
		owner.get_node("charge_bar").value = min(ratio * 100, 100)
		if ratio >= 1.0:
			owner.get_node("charge_bar").modulate = Color(1, 0, 0)
		else:
			owner.get_node("charge_bar").modulate = Color(1, 1, 1)

		# —— （A）允许踩方向键小步走 —— 
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
			# 蓄力时可走的速度 (比正常跑慢一点)
			owner.velocity = dir_vec * owner.charge_move_speed
			owner.move_and_slide()

			# —— 更新玩家朝向并播放“run”动画 —— 
			var new_dir: String
			# 水平优先
			if abs(dir_vec.x) > abs(dir_vec.y):
				if dir_vec.x > 0:
					new_dir = "right"
				else:
					new_dir = "left"
				owner.current_dir = new_dir
				owner.PlayAnim("run_side", true)   # 每帧都强制刷新 run_side

			else:
				if dir_vec.y > 0:
					new_dir = "down"
					owner.current_dir = "down"
					owner.PlayAnim("run_down", true)    # 每帧都强制刷新 run_down
				else:
					new_dir = "up"
					owner.current_dir = "up"
					owner.PlayAnim("run_up", true)      # 每帧都强制刷新 run_up

			# HitBox 位置随时保持正确朝向
			owner._update_hitbox_offset()
			owner.moving = true

		else:
			# —— （B）踩键归零：保持“站桩蓄力” —— 
			owner.velocity = Vector2.ZERO
			owner.moving = false

			var base_dir2 = owner.current_dir if owner.current_dir in ["up", "down"] else "side"
			var charge_idle = "idle_%s" % base_dir2
			owner.PlayAnim(charge_idle, true)   # 强制刷新 “idle” 蓄力姿势

		return  # 只要还在按“attack”，就不往后走分支

	# —— 2) 蓄力键松手：切到普通或重击 —— 
	owner.is_charging = false
	owner.get_node("charge_bar").visible = false
	owner.get_node("charge_bar").value = 0
	owner.get_node("charge_bar").modulate = Color(1,1,1)

	if owner.charge_time >= owner.max_charge_time:
		owner.change_state(owner.States.HEAVY_ATTACK)
	else:
		owner.change_state(owner.States.ATTACK)

	return

func process(delta: float) -> void:
	pass

func exit(next_state: String) -> void:
	owner.velocity = Vector2.ZERO
	owner.moving = false
