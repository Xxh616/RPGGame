# res://scripts/playerstates/MoveState.gd
extends PlayerState
class_name PlayerMoveState

func _init(_owner) -> void:
	owner = _owner


func enter(prev_state: String) -> void:
	print("**ENTER MoveState**")
	# 默认先播放一个动画占位，后面 physics_update 会根据方向切动画
	owner.PlayAnim("run_side", true)
	owner.moving = true


func physics_update(delta: float) -> void:
	# 1) 如果正在攻击/蓄力，就立刻回 Idle
	if owner.attack_ip or owner.is_charging:
		owner.velocity = Vector2.ZERO
		owner.moving = false
		owner.change_state(owner.States.IDLE)
		return
	

	# 2) 读取输入，决定 dir_vec
	var dir_vec := Vector2.ZERO
	if Input.is_action_pressed("ui_right"):
		dir_vec.x += 1
	
	if Input.is_action_pressed("ui_left"):
		dir_vec.x -= 1
	
	if Input.is_action_pressed("ui_down"):
		dir_vec.y += 1
	
	if Input.is_action_pressed("ui_up"):
		dir_vec.y -= 1
	

	# 3) 如果没有任何方向输入，回到 Idle
	if dir_vec == Vector2.ZERO:
		owner.velocity = Vector2.ZERO
		owner.moving = false
		owner.change_state(owner.States.IDLE)
		return
	

	# 4) 有方向输入，先把方向归一化并赋速度
	dir_vec = dir_vec.normalized()
	owner.velocity = dir_vec * owner.speed

	# 5) 根据 dir_vec 计算新方向，并立即更新 current_dir、HitBox，再播放相应动画
	var new_dir: String = owner.current_dir
	if abs(dir_vec.x) > abs(dir_vec.y):
		# 左/右方向占优
		if dir_vec.x > 0:
			new_dir = "right"
			if new_dir != owner.current_dir:
				owner.current_dir = new_dir
				owner._update_hitbox_offset()      # ← 立即更新 HitBox 位置
			
			owner.PlayAnim("run_side", true)
		else:
			new_dir = "left"
			if new_dir != owner.current_dir:
				owner.current_dir = new_dir
				owner._update_hitbox_offset()      # ← 立即更新 HitBox 位置
			
			owner.PlayAnim("run_side", true)
		
	else:
		# 上/下方向占优
		if dir_vec.y > 0:
			new_dir = "down"
			if new_dir != owner.current_dir:
				owner.current_dir = new_dir
				owner._update_hitbox_offset()      # ← 立即更新 HitBox 位置
			
			owner.PlayAnim("run_down", true)
		else:
			new_dir = "up"
			if new_dir != owner.current_dir:
				owner.current_dir = new_dir
				owner._update_hitbox_offset()      # ← 立即更新 HitBox 位置
			
			owner.PlayAnim("run_up", true)
		
	

	# 6) 如果按了“攻击”键，就切 Charge
	if Input.is_action_just_pressed("attack"):
		owner.change_state(owner.States.CHARGE)
		return
	

	# 7) 检测血量，若为 0 则切 DEAD
	if global.player_health <= 0:
		owner.change_state(owner.States.DEAD)
		return
	

	# （不要在这里调用 move_and_slide()，统一由 Player.gd 处理）


func process(delta: float) -> void:
	owner._refresh_drop_labels()


func exit(next_state: String) -> void:
	owner.velocity = Vector2.ZERO
	owner.moving = false
