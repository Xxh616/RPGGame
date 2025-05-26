extends CharacterBody2D
#蓄力
var is_charging := false
var queued_charge := false  # 是否等待进入蓄力
var charge_time := 0.0
@export var max_charge_time := 1.5  # 最大蓄力时间（秒）


@export var charge_move_speed := 30  # 蓄力时移动速度
@export var speed := 100
@export var attack_radius := 60
@export var attack_angle_degrees := 90
var move_speed := 0
var current_dir := "down"
var moving := false
var attack_ip := false
var attack_index := 0  # 0 = first, 1 = second

@onready var sprite_groups := {
	"idle": $idle,
	"attack": $attack,
	"run": $run
}

func _ready():
	$regen_timer.wait_time = global.player_regen_interval
	$regen_timer.start()
	update_health_bar()
	$AnimPlayer.play("down_idle")
	$AnimPlayer.connect("animation_finished", Callable(self, "_on_AnimPlayer_animation_finished"))
	$charge_bar.visible = false
	$charge_bar.max_value = 100
	$charge_bar.value = 0

func _process(delta):
	if is_charging:
		charge_time += delta
		var ratio = charge_time / max_charge_time
		$charge_bar.value = min(ratio * 100, 100)

		if ratio >= 1.0:
			$charge_bar.modulate = Color(1, 0, 0)  # 红色
		else:
			$charge_bar.modulate = Color(1, 1, 1)  # 原始颜色（白）
	elif Input.is_action_pressed("attack") and not attack_ip and not is_charging:
		start_charge()
	if Input.is_action_just_pressed("attack") and not attack_ip:
		start_charge()
	elif Input.is_action_just_released("attack") and is_charging:
		release_charge()
func start_charge():
	is_charging = true
	charge_time = 0.0
	$charge_bar.visible = true
	$charge_bar.value = 0

func release_charge():
	is_charging = false
	$charge_bar.visible = false

	if charge_time >= max_charge_time:
		perform_heavy_attack()
	else:
		handle_attack()
func perform_heavy_attack():
	attack_ip = true
	print("💥 重击释放！")
	PlayAnim("%s_thump_attack" % (current_dir if current_dir == "up" or current_dir == "down" else "side"))
	check_attack_hit_sector()  # 可替换为专属重击范围逻辑
func _physics_process(delta):
	handle_movement()
	move_and_slide()
	update_health_bar()
	current_camera()

	if global.player_health <= 0:
		global.player_alive = false
		global.player_health = 0
		print("💀 玩家死亡")
		queue_free()
func current_action_group() -> String:
	if attack_ip:
		return "attack"
	elif moving:
		return "run"
	else:
		return "idle"

func set_flip_by_direction():
	var flip := current_dir == "left"
	var group = sprite_groups[current_action_group()]
	for child in group.get_children():
		if child is Sprite2D:
			child.flip_h = flip

func PlayAnim(anim_name: String, force_play := false):
	if not force_play and $AnimPlayer.current_animation == anim_name:
		return
	$AnimPlayer.speed_scale = 1.5 if is_charging else 2.5
	for key in sprite_groups.keys():
		sprite_groups[key].visible = (key == current_action_group())
	set_flip_by_direction()
	print("play: " + anim_name)

	$AnimPlayer.play(anim_name)

func player():
	pass

func handle_movement():
	if attack_ip:
		velocity = Vector2.ZERO
		moving = false
		return

	moving = false
	velocity = Vector2.ZERO
	if is_charging:
		move_speed = charge_move_speed
	else:
		move_speed = speed
	var previous_dir = current_dir

# 检查输入
	if Input.is_action_pressed("ui_right"):
		current_dir = "right"
		velocity.x = move_speed
		moving = true
		PlayAnim("side_run", current_dir != previous_dir)
	elif Input.is_action_pressed("ui_left"):
		current_dir = "left"
		velocity.x = -move_speed
		moving = true
		PlayAnim("side_run", current_dir != previous_dir)
	elif Input.is_action_pressed("ui_down"):
		current_dir = "down"
		velocity.y = move_speed
		moving = true
		PlayAnim("down_run", current_dir != previous_dir)
	elif Input.is_action_pressed("ui_up"):
		current_dir = "up"
		velocity.y = -move_speed
		moving = true
		PlayAnim("up_run", current_dir != previous_dir)
	if not moving and not attack_ip:
		if current_dir == "left" or current_dir == "right":
			PlayAnim("side_idle")
		else:
			PlayAnim("%s_idle" % current_dir)

func handle_attack():
	attack_ip = true
	attack_index = (attack_index + 1) % 2

	var anim_name = "%s_%s_attack" % [
		current_dir if current_dir == "up" or current_dir == "down" else "side",
		"first" if attack_index == 0 else "second"
	]
	print("▶️ 播放普通攻击动画: ", anim_name)
	PlayAnim(anim_name)

	var shape = $PlayerHitBox/HitCollision.shape
	if shape is CircleShape2D:
		match current_dir:
			"right":
				$PlayerHitBox/HitCollision.position = Vector2(40, 20)
				shape.radius = 40
			"left":
				$PlayerHitBox/HitCollision.position = Vector2(-40, 20)
				shape.radius = 40
			"down":
				$PlayerHitBox/HitCollision.position = Vector2(20, 40)
				shape.radius = 30
			"up":
				$PlayerHitBox/HitCollision.position = Vector2(-20, -40)
				shape.radius = 30

func _on_AnimPlayer_animation_finished(anim_name):
	if anim_name.ends_with("attack"):
		attack_ip = false
		if current_dir == "left" or current_dir == "right":
			PlayAnim("side_idle")
		else:
			PlayAnim("%s_idle" % current_dir)

func _on_attack_cooldown_timeout():
	global.player_current_attack = false
	attack_ip = false
	$PlayerHitBox.monitoring = false
	$attack_cooldown.stop()

func take_damage(amount: int):
	global.player_health -= amount
	print("⚠️ 玩家受击, 当前血量: ", global.player_health)
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
			if abs(angle) <= half_angle_rad:
				node.take_damage(20)
				print("💥 命中敌人: ", node.name)


func _on_anim_player_animation_finished(anim_name):
	if anim_name.ends_with("attack") or anim_name.ends_with("thump_attack"):
		attack_ip = false

		# ✅ 动画刚结束时，如果仍在按着攻击键，立刻进入蓄力状态
		if Input.is_action_pressed("attack"):
			start_charge()
		else:
			# 回到 idle 状态
			if current_dir == "left" or current_dir == "right":
				PlayAnim("side_idle")
			else:
				PlayAnim("%s_idle" % current_dir)
