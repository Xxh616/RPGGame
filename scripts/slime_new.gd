extends "res://scripts/enemy_base.gd"

@export var attack_anim_time: float = 0.5
@export var attack_cooldown_time: float = 1.0
@export var attack_landing_frame: int = 5

@export var attack_hit_range: float = 40.0

var has_landed := false
var attack_target_position: Vector2

	
func init_timers():
	$attack_timer.wait_time = attack_anim_time
	$attack_cooldown_timer.wait_time = attack_cooldown_time

func perform_attack():
	if not player:
		return

	print("🟢 [Slime] 执行攻击")
	attacking = true
	attack_cooldown = true
	has_landed = false

	attack_target_position = player.position
	velocity = (attack_target_position - position).normalized() * 80
	print("🟢 [Slime] 朝玩家原位置跳跃，方向：", velocity)

	play_attack_animation()
	$attack_timer.start()

func play_idle_animation():
	$AnimatedSprite2D.play("idle")

func play_walk_animation():
	$AnimatedSprite2D.play("walk")

func play_death_animation():
	$AnimatedSprite2D.play("death")

func play_attack_animation():
	$AnimatedSprite2D.play("attack")

func _on_attack_land():
	has_landed = true
	var dist = attack_target_position.distance_to(player.position)
	#print("🟡 [Slime] 玩家与目标点距离：", dist)

	if dist <= attack_hit_range and player.has_method("take_damage"):
		player.take_damage(10)
		#print("🔥 [Slime] 命中玩家！当前血量：", global.player_health)
	else:
		pass
		#print("❌ [Slime] 攻击落空")

func _on_attack_timer_timeout():
	$attack_timer.stop()
	velocity = Vector2.ZERO
	attacking = false
	play_idle_animation()
	#print("🔁 [Slime] 攻击结束，进入冷却")
	$attack_cooldown_timer.start()

func _on_attack_cooldown_timer_timeout():
	attack_cooldown = false
	#print("✅ [Slime] 冷却结束，可再次攻击")

func _on_enemy_damage_timer_timeout():
	can_take_damage = true

func _on_death_timer_timeout():
	queue_free()

func _on_detection_area_body_entered(body):
	if body.has_method("player"):
		player = body
		player_chase = true
		#print("🎯 [Slime] 玩家进入追踪范围")

func _on_detection_area_body_exited(body):
	player_chase = false
	#print("🚫 [Slime] 玩家离开追踪范围")

func _on_enemy_hit_box_body_entered(body):
	pass

func _on_enemy_hit_box_body_exited(body):
	player_in_attack_zone = false
func take_damage(amount: int):
	health -= amount
	print("💢 敌人受击，当前血量：", health)

	if health <= 0:
		die()
	else:
		can_take_damage = false
		$enemy_damage_timer.start()
func _on_animated_frame_changed():
	
	if attacking and not has_landed and $AnimatedSprite2D.animation == "attack":
		if $AnimatedSprite2D.frame == attack_landing_frame:
			#print("🔵 [Slime] 到达攻击落地帧")
			_on_attack_land()
