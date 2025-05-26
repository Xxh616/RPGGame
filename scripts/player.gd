extends CharacterBody2D

@export var speed := 100
@export var attack_radius := 60                # 攻击距离
@export var attack_angle_degrees := 90         # 攻击夹角（扇形）
var current_dir := "down"
var moving := false
var attack_ip := false

func _ready():
	$regen_timer.wait_time = global.player_regen_interval
	$regen_timer.start()
	update_health_bar()
	$AnimatedSprite2D.play("front_idle")

func _physics_process(delta):
	handle_movement()
	move_and_slide()
	handle_attack()
	update_health_bar()
	current_camera()

	if global.player_health <= 0:
		global.player_alive = false
		global.player_health = 0
		print("💀 玩家死亡")
		queue_free()
func player():
	pass

func handle_movement():
	if attack_ip:
		velocity = Vector2.ZERO
		moving = false
		return

	moving = false
	velocity = Vector2.ZERO

	if Input.is_action_pressed("ui_right"):
		current_dir = "right"
		velocity.x = speed
		moving = true
	elif Input.is_action_pressed("ui_left"):
		current_dir = "left"
		velocity.x = -speed
		moving = true
	elif Input.is_action_pressed("ui_down"):
		current_dir = "down"
		velocity.y = speed
		moving = true
	elif Input.is_action_pressed("ui_up"):
		current_dir = "up"
		velocity.y = -speed
		moving = true

	play_anim()

func play_anim():
	var anim = $AnimatedSprite2D

	match current_dir:
		"right":
			anim.flip_h = false
			anim.play("side_walk" if moving else "side_idle")
		"left":
			anim.flip_h = true
			anim.play("side_walk" if moving else "side_idle")
		"down":
			anim.flip_h = false
			anim.play("front_walk" if moving else "front_idle")
		"up":
			anim.flip_h = false
			anim.play("back_walk" if moving else "back_idle")


func handle_attack():
	if Input.is_action_just_pressed("attack") and not attack_ip:
		global.player_current_attack = true
		attack_ip = true
		$attack_cooldown.start()

		var shape = $PlayerHitBox/HitCollision.shape
		if shape is CircleShape2D:
			match current_dir:
				"right":
					$AnimatedSprite2D.flip_h = false
					$AnimatedSprite2D.play("side_attack")
					$PlayerHitBox/HitCollision.position = Vector2(40, 20)
					shape.radius = 40
				"left":
					$AnimatedSprite2D.flip_h = true
					$AnimatedSprite2D.play("side_attack")
					$PlayerHitBox/HitCollision.position = Vector2(-40, 20)
					shape.radius = 40
				"down":
					$AnimatedSprite2D.play("front_attack")
					$PlayerHitBox/HitCollision.position = Vector2(20, 40)
					shape.radius = 30
				"up":
					$AnimatedSprite2D.play("back_attack")
					$PlayerHitBox/HitCollision.position = Vector2(-20, -40)
					shape.radius = 30

func _on_attack_cooldown_timeout():
	global.player_current_attack = false
	attack_ip = false
	$PlayerHitBox.monitoring = false  # ✅ 确保攻击结束后关闭命中
	$attack_cooldown.stop()

func _on_PlayerHitBox_body_entered(body):
	if body.has_method("enemy"):
		# 检测敌人进入攻击区域，仅用于额外提示
		pass

func _on_PlayerHitBox_body_exited(body):
	pass

func take_damage(amount: int):
	global.player_health -= amount
	print("⚠️ 玩家受击，当前血量：", global.player_health)
	if global.player_health < 0:
		global.player_health = 0
	update_health_bar()

func update_health_bar():
	var bar = $healthBar
	bar.max_value = global.player_max_health
	bar.value = global.player_health
	bar.visible = global.player_health < global.player_max_health

func _on_regen_timer_timeout():
	if global.player_health < global.player_max_health:
		global.player_health += global.player_regen_rate
		if global.player_health > global.player_max_health:
			global.player_health = global.player_max_health
	update_health_bar()
func get_attack_direction() -> Vector2:
	match current_dir:
		"right": return Vector2.RIGHT
		"left": return Vector2.LEFT
		"up": return Vector2.UP
		"down": return Vector2.DOWN
		_: return Vector2.ZERO

func current_camera():
	if global.current_scene in ["world", "hometown"]:
		$Camera2D.enabled = true
		$cliffsidecamera.enabled = false
	elif global.current_scene == "cliffside":
		$Camera2D.enabled = false
		$cliffsidecamera.enabled = true
func check_attack_hit_sector():
	print("⚔️ 开始检测扇形命中")
	var origin = global_position
	var attack_dir = get_attack_direction()
	var half_angle_rad = deg_to_rad(attack_angle_degrees / 2)

	for node in get_tree().get_nodes_in_group("Enemy"):
		if node == self:
			continue
		if node.has_method("enemy") and node.has_method("take_damage"):
			
			var to_enemy = node.global_position - origin
			var distance = to_enemy.length()
			
			if distance > attack_radius:
				continue
			var angle = attack_dir.angle_to(to_enemy.normalized())
			print("📍 检测敌人：", node.name, " 距离：", distance, " 角度：")
			if abs(angle) <= half_angle_rad:
				node.take_damage(20)
				print("💥 命中敌人：", node.name)


func _on_animated_sprite_2d_frame_changed():
	if attack_ip and $AnimatedSprite2D.animation.ends_with("_attack"):
		var frame = $AnimatedSprite2D.frame
		if frame in [1, 2]:
			check_attack_hit_sector()
