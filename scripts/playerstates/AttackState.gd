# res://scripts/playerstates/AttackState.gd
extends PlayerState
class_name PlayerAttackState

# 标记是否本次为重击
var is_heavy := false    

# 用于延迟关闭 HitBox（0.2 秒后关闭，这里可根据动画时机自行调整）
var attack_timer := 0.0  

# 确保“只打开一次 HitBox”或“只算一次伤害”
var has_hit := false     

func _init(_owner) -> void:
	owner = _owner
func enter(prev_state: String) -> void:
	# 进入攻击：设置标记、播放动画、打开 HitBox 并绑定动画结束信号
	owner.attack_ip = true
	owner.velocity = Vector2.ZERO
	has_hit = false
	attack_timer = 0.0

	# —— 1) 播动画 —— 
	var base_dir = owner.current_dir if owner.current_dir in ["up", "down"] else "side"
	if is_heavy:
		# 重击动画: thump_attack_down / thump_attack_side / thump_attack_up
		var anim_name = "thump_attack_%s" % base_dir
		owner.PlayAnim(anim_name, true)
	else:
		# 普通连击：第 1 段 or 第 2 段
		owner.attack_index = (owner.attack_index + 1) % 2
		var suffix = "first" if owner.attack_index == 0  else "second"
		var anim_name = "attack_%s_%s" % [base_dir, suffix]
		owner.PlayAnim(anim_name, true)


	# —— 2) 刚一进攻，就把 HitBox 移到当前朝向并打开监测 —— 
	owner._update_hitbox_offset()
	owner.hitbox_area.monitoring = true

	# —— 3) 连接动画结束信号，以便动画播完后切 Idle —— 
	if owner.anim_player and not owner.anim_player.is_connected("animation_finished", Callable(self, "_on_animation_finished")):
		owner.anim_player.connect("animation_finished", Callable(self, "_on_animation_finished"))

func physics_update(delta: float) -> void:
	# —— A) 允许“攻击中也能切换朝向” —— 
	# 如果玩家在这阶段按了上下左右，就随时更新 current_dir，并让 HitBox 立即跟上
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
		var new_dir = owner.current_dir
		dir_vec = dir_vec.normalized()
		if abs(dir_vec.x) > abs(dir_vec.y):
			new_dir = "right" if dir_vec.x > 0  else "left"
		else:
			new_dir = "down" if dir_vec.y > 0  else "up"
	
		if new_dir != owner.current_dir:
			owner.current_dir = new_dir
			owner._update_hitbox_offset()
			# （可选）如果想让攻击动画同时切换朝向，可以在这里再调用一次播放相应“面向+攻击”动画，
			# 但多数情况下只是更新 HitBox 即可，不用切新动画帧。


	# —— B) 累加计时器，到达某个时刻关闭 HitBox —— 
	if not has_hit:
		attack_timer += delta
		# 这里假定我们在动画开始约 0.2 秒后关闭 HitBox，避免“命中判定一直开着”
		if attack_timer >= 0.2:
			has_hit = true
			owner.hitbox_area.monitoring = false
		
	

	# —— C) 如果玩家血量归零，立刻切 Dead —— 
	if global.player_health <= 0:
		owner.change_state(owner.States.DEAD)
		return
	

	# —— D) 攻击过程中不允许移动 —— 
	owner.velocity = Vector2.ZERO


func process(delta: float) -> void:
	# 攻击状态里不在这里做切换，由动画结束信号来切回 Idle
	pass


func exit(next_state: String) -> void:
	owner.attack_ip = false

	# —— 1) 断开 animation_finished 信号 —— 
	if owner.anim_player and owner.anim_player.is_connected("animation_finished", Callable(self, "_on_animation_finished")):
		owner.anim_player.disconnect("animation_finished", Callable(self, "_on_animation_finished"))
	

	# —— 2) 确保离开状态时 HitBox 关闭监测 —— 
	if owner.has_node("HitBox"):
		owner.hitbox_area.monitoring = false
	


# 当动画真正播完（普通或重击任意一段）时，切回 Idle
func _on_animation_finished(anim_name: String) -> void:
	var valid_names := []
	if is_heavy:
		valid_names = ["thump_attack_down", "thump_attack_side", "thump_attack_up"]
	else:
		valid_names = [
			"attack_down_first",  "attack_down_second",
			"attack_side_first",  "attack_side_second",
			"attack_up_first",    "attack_up_second"
		]


	if anim_name in valid_names:
		owner.change_state(owner.States.IDLE)
