extends CharacterBody2D
class_name EnemyBase

@export var move_speed: float = 60
@export var max_health: int = 100
@export var attack_range: float = 20
@export var attack_trigger_range: float = 120.0

var health: int
var player: Node = null
var attacking := false
var attack_cooldown := false
var can_take_damage := true
var player_chase := false
var player_in_attack_zone := false

func _ready():
	add_to_group("Enemy")
	health = max_health
	init_timers()
	play_idle_animation()

func _physics_process(_delta):
	handle_chase()
	update_health()
	move_and_slide()

func handle_chase():
	if not player or health <= 0:
		return

	$AnimatedSprite2D.flip_h = player.position.x < position.x
	var dist = position.distance_to(player.position)

	if attacking:
		return

	if player_chase and not attack_cooldown:
		if dist <= attack_trigger_range:
			perform_attack()
		else:
			velocity = (player.position - position).normalized() * move_speed
			play_walk_animation()
	else:
		velocity = Vector2.ZERO
		play_idle_animation()



func take_damage(amount: int):
	pass

func die():
	can_take_damage = false
	attacking = false
	velocity = Vector2.ZERO

	# 2) 播放死亡动画（子类可以 override play_death_animation）
	play_death_animation()

	# 3) 启动 death_timer，等待动画播放完或稍微延迟再真正掉落 + 销毁
	if has_node("death_timer"):
		$death_timer.start()
	else:
		# 万一没有 Timer，就直接掉落并销毁
		_spawn_drops()
		queue_free()

func _spawn_drops():
	# 调用“虚方法” get_drop_list()，让子类返回一个掉落列表
	var drop_data_list : Array = get_drop_list()
	for data in drop_data_list:
		# data 预期是一个字典，至少包含 { "scene": PackedScene, "offset": Vector2 }
		var packed = data.get("scene")
		var offset = data.get("offset", Vector2.ZERO)
		if packed and packed is PackedScene:
			var instance = packed.instantiate() as Node2D
			# 把它加到“世界”根节点下（当前场景）
			var world = get_tree().current_scene as Node2D
			world.add_child(instance)
			instance.global_position = self.global_position + offset
func get_drop_list() -> Array:
	# 默认情况下，基类不掉任何东西。子类 override 这个方法返回自己的掉落物
	return []
func update_health():
	if has_node("healthbar"):
		var bar = $healthbar
		bar.value = health
		bar.visible = health < max_health
func enemy():
	pass
		
# 可被子类重写的方法
func perform_attack():
	pass
func get_damage_amount():
	return 20
func play_idle_animation():
	pass
func play_walk_animation():
	pass
func play_death_animation():
	pass
func init_timers():
	pass
