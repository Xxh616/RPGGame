# res://scripts/states/AttackState.gd
extends State
class_name PlayerAttackState

var attack_cooldown := 1.0  # 动画 + 冷却 总时长
var timer := 0.0            # 累计时间

func _init(_owner) -> void:
	owner = _owner

func enter(prev_state: String) -> void:
	timer = 0.0
	# —— 2) 更新并打开攻击区 —— 
	owner.update_attack_area()
	owner.attack_area.monitoring  = true
	owner.attack_area.monitorable = true
	var to_player = owner.player.global_position - owner.global_position
	if abs(to_player.x) > abs(to_player.y):
		owner.last_facing_dir ="right" if to_player.x > 0  else "left"
	else:
		owner.last_facing_dir = "down" if to_player.y > 0 else "up"

	# —— 3) 播攻击动画 —— 
	owner.play_animation("attack")


func physics_update(delta: float) -> void:
	# 攻击期间禁止移动
	owner.velocity = Vector2.ZERO

	timer += delta

	# —— 在 0.5 秒时尝试命中一次 —— 
	if timer >= 0.5 and timer - delta < 0.5:
		if owner.attack_valid:
			var factor=(100+owner.config.attack)/100.0
			owner.player.take_damage(20*factor)
		# 不管是否命中，这次触发后就不再重复
		owner.attack_valid = false

	# —— 当前攻击周期结束（动画+冷却） —— 
	if timer >= attack_cooldown:
		timer = 0.0

		# 先关闭本轮的攻击区检测
		owner.attack_area.monitoring  = false
		owner.attack_area.monitorable = false

		# 决定下一步：如果玩家仍在判定区，就连击；否则回 Chase
		if owner.attack_valid:
			# 连击下一轮：再对齐攻击区、重新打开检测、播放动画
			owner.update_attack_area()
			owner.attack_area.monitoring  = true
			owner.attack_area.monitorable = true
			owner.attack_valid = false
			owner.play_animation("attack")
		else:
			owner.change_state(owner.States.CHASE)

func process(delta: float) -> void:
	# 攻击状态无需在 process 里做额外逻辑
	pass

func exit(next_state: String) -> void:
	# 离开攻击状态时，一定关闭攻击区
	owner.attack_area.call_deferred("set_monitoring", false)
	owner.attack_area.call_deferred("set_monitorable", false)
	
