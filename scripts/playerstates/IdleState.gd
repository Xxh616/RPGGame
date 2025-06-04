# res://scripts/playerstates/IdleState.gd
extends PlayerState
class_name PlayerIdleState

func _init(_owner) -> void:
	owner = _owner

func enter(prev_state: String) -> void:
	print("**ENTER IdleState**, current_dir=", owner.current_dir)
	# 切入 Idle 时，播放正确方向的待机动画
	var base_dir = owner.current_dir if owner.current_dir in ["up", "down"] else "side"
	var anim_name = "idle_%s" % base_dir
	owner.PlayAnim(anim_name, true)

	# 确保 velocity 为零，不会被别的状态残余速度干扰
	owner.velocity = Vector2.ZERO

func physics_update(delta: float) -> void:
	var x_input := Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	var y_input := Input.get_action_strength("ui_down")  - Input.get_action_strength("ui_up")

	# 如果你希望“Idle 时按方向键只切换朝向，但不立刻进入 Move”，可以这样写：
	if x_input != 0 or y_input != 0:
		# 先计算 new_dir
		var new_dir = owner.current_dir
		if abs(x_input) > abs(y_input):
			new_dir = "right" if x_input > 0 else "left"
		else:
			new_dir = "down" if y_input > 0  else "up"


		if new_dir != owner.current_dir:
			owner.current_dir = new_dir
			owner._update_hitbox_offset()    # ← 立刻更新 HitBox 到新朝向
		

		# 如果你仍希望一按方向就进 Move，则保留下面的切换
		owner.change_state(owner.States.MOVE)
		return
	

	# 如果你想完全不让 Idle 时切换到 Move，只想切换朝向，那么把上面 owner.change_state(...) 注释掉即可，
	# 这样只会执行 _update_hitbox_offset() 而不会离开 Idle。
	
	# —— 2. 检测攻击键按下 —— 
	if Input.is_action_just_pressed("attack") and not owner.attack_ip:
		owner.change_state(owner.States.CHARGE)
		return
	

	# —— 3. 检测拾取键 —— 
	if Input.is_action_just_pressed("pickup_item"):
		owner._refresh_drop_labels()
		if owner.itemselect != null:
			owner.itemselect.pickup()
			owner.nearby_drops.erase(owner.itemselect)
			owner.itemselect.show_label(false)
			owner.itemselect = null
		
	

	# —— 4. 始终把 velocity 设为零 —— 
	owner.velocity = Vector2.ZERO


func process(delta: float) -> void:
	# Idle 状态里可以做一些非物理逻辑，例如：刷新掉落提示、处理鼠标悬停等
	pass

func exit(next_state: String) -> void:
	# 离开 Idle 时，如果需要清理某些东西可以写在这里
	pass
