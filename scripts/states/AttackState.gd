# AttackState.gd
extends State

# 攻击间隔与定时器（可用来控制连续攻击的节奏）
var can_attack := true
var attack_cooldown := 1.0  # 攻击动画时长 + 冷却
var timer := 0.0

func enter(prev_state:String) -> void:
	timer = 0.0
	can_attack = true
	owner.play_animation("attack")  # 播放攻击动画

func physics_update(delta: float) -> void:
	# 如果玩家跑出攻击范围，返回 chase
	if not owner.is_player_in_attack_range():
		owner.change_state(owner.States.CHASE)
		return

	# 如果正在攻击动画中，就不移动；利用 timer 来判定何时击中玩家
	timer += delta
	if timer >= 0.5 and can_attack:
		# 假设动画播放到 0.5s 时，判定为击中
		owner.player.take_damage(10)  # 示例：给玩家减血 10 点
		can_attack = false

	# 当整段攻击动画结束（或冷却结束），准备下一次攻击/切回追击
	if timer >= attack_cooldown:
		timer = 0.0
		can_attack = true
		# 动画可以自动循环或重播
		owner.play_animation("attack")

func process(delta: float) -> void:
	pass
