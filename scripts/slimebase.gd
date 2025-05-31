# res://scripts/SlimeBase.gd
extends EnemyBase
class_name SlimeBase

signal died

# —— 配置资源 —— 
@export var config: SlimeConfig                    # 可拖入 .tres 配置文件
# —— 外观可视化参数 —— 
@export var sprite_frames: SpriteFrames            # 备用帧集
@export var sprite_scale: Vector2 = Vector2.ONE
@export var sprite_modulate: Color = Color(1,1,1)

# —— 基础行为参数 —— 
@export var jump_speed: float           = 80.0
@export var damage_amount: int          = 10
@export var attack_anim_time: float     = 0.5
@export var attack_cooldown_time: float = 1.0
@export var attack_landing_frame: int   = 5
@export var attack_hit_range: float     = 20.0

# —— 缓存节点引用 —— 
@onready var sprite: AnimatedSprite2D     = $AnimatedSprite2D
@onready var detection_area: Area2D       = $detection_area
@onready var hit_box: Area2D              = $enemy_hit_box
@onready var attack_timer: Timer          = $attack_timer
@onready var cooldown_timer: Timer        = $attack_cooldown_timer
@onready var damage_timer: Timer          = $enemy_damage_timer
# 注意：基类的 death_timer 已经挂在 EnemyBase 场景里，SlimeBase 这里无需再挂

# —— 内部状态 —— 
var has_landed: bool = false
var attack_target_position: Vector2

func _ready() -> void:
	super._ready()                # 调用 EnemyBase._ready()
	_apply_appearance_and_params()
	_instantiate_skills()
	
	

func _apply_appearance_and_params() -> void:
	# 外观
	if config:
		sprite.frames   = config.sprite_frames
		sprite.scale    = config.sprite_scale
		sprite.modulate = config.sprite_modulate
	else:
		sprite.frames   = sprite_frames
		sprite.scale    = sprite_scale
		sprite.modulate = sprite_modulate

	# 同步调整 hit_box 中的 CollisionShape2D（假设是 RectangleShape2D）
	var cs = hit_box.get_node("CollisionShape2D").shape
	if cs is RectangleShape2D:
		cs.extents *= sprite.scale

	# 行为参数
	if config:
		jump_speed           = config.jump_speed
		damage_amount        = config.damage_amount
		attack_anim_time     = config.attack_anim_time
		attack_cooldown_time = config.attack_cooldown_time
		attack_landing_frame = config.attack_landing_frame
		attack_hit_range     = config.attack_hit_range

func _instantiate_skills() -> void:
	if config and config.skills:
		for skill_scene in config.skills:
			var skill_node = skill_scene.instantiate()
			add_child(skill_node)
			if skill_node.has_method("set_owner_slime"):
				skill_node.set_owner_slime(self)

func init_timers() -> void:
	# 只初始化 _attack_timer_ 和 _cooldown_timer_，death_timer 交给基类处理
	attack_timer.wait_time    = attack_anim_time
	cooldown_timer.wait_time  = attack_cooldown_time
	attack_timer.connect("timeout", Callable(self, "_on_attack_timer_timeout"))
	cooldown_timer.connect("timeout", Callable(self, "_on_attack_cooldown_timer_timeout"))
	damage_timer.connect("timeout", Callable(self, "_on_enemy_damage_timer_timeout"))



# —— 攻击流程 —— #
func perform_attack() -> void:
	if not player or cooldown_timer.time_left > 0:
		return
	attacking = true
	has_landed = false
	attack_target_position = player.position

	hit_box.global_position = attack_target_position
	hit_box.visible         = true
	hit_box.monitoring      = false

	velocity = (attack_target_position - position).normalized() * jump_speed
	sprite.animation = "attack"
	attack_timer.start()

func _on_animated_frame_changed() -> void:
	if attacking and not has_landed and sprite.animation == "attack" and sprite.frame == attack_landing_frame:
		_on_attack_land()

func _on_attack_land() -> void:
	has_landed = true
	if attack_target_position.distance_to(player.position) <= attack_hit_range:
		player.take_damage(damage_amount)

func _on_attack_timer_timeout() -> void:
	attack_timer.stop()
	velocity = Vector2.ZERO
	attacking = false
	sprite.animation = "idle"
	cooldown_timer.start()

func _on_attack_cooldown_timer_timeout() -> void:
	# 自动等待下一次攻击
	pass

func _on_animation_finished() -> void:
	if attacking and has_landed and sprite.animation == "attack":
		hit_box.visible    = false
		hit_box.monitoring = false

# —— 探测与追踪 —— #
func _on_detection_area_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		player = body
		player_chase = true

func _on_detection_area_body_exited(body: Node) -> void:
	player_chase = false

# —— 受击与死亡 —— #
func take_damage(amount: int) -> void:
	if not can_take_damage:
		return
	health -= amount
	if health <= 0:
		die()   # 这里调用的是基类 EnemyBase.die()
	else:
		can_take_damage = false
		damage_timer.start()

func get_drop_list() -> Array:
	var result: Array = []
	if not config:
		return result

	for drop_info in config.drops:
		var item_res: Item = drop_info.get("item")
		var chance_f: float = drop_info.get("chance")
		var cnt: int        = drop_info.get("count")

		# 把 offset 拿出来，如果没有就用 Vector2.ZERO
		var off: Vector2 = Vector2.ZERO

		if item_res == null:
			continue
		# 随机判定：randf() < chance_f 时才真正掉落这一项
		if randf() < chance_f:
			result.append({
				"item": item_res,
				"count": cnt,
				"offset": off
			})
	return result
func _spawn_item_drop(item_res: Item, count: int, offset: Vector2) -> void:
	# “item_drop.tscn” 预先设计一个拾取节点，根节点要有 ItemDrop.gd 脚本
	# 假设你的 ItemDrop 场景路径是：res://scenes/item_drop.tscn
	var drop_scene := preload("res://scenes/item_drop.tscn") as PackedScene
	var drop_node  = drop_scene.instantiate() as Node2D

	# 设置它需要的属性：
	drop_node.item_id = item_res.id
	drop_node.count   = count

	# 把它加到当前游戏场景的根节点（world 场景）下
	var world := get_tree().current_scene as Node2D
	world.add_child(drop_node)

	# 放到史莱姆死亡位置 + 配置的偏移量
	drop_node.global_position = global_position + offset
func _spawn_drops() -> void:
	# 1) 拿到一个要掉落的列表（上面 get_drop_list 随机挑选好哪些要掉落）
	var drop_list = get_drop_list()
	# 2) 如果列表不为空，就一个个实例化
	for info in drop_list:
		var item_res = info.get("item")
		var cnt      = info.get("count")
		var off      = info.get("offset")
		_spawn_item_drop(item_res, cnt, off)
# —— 覆盖动画方法 —— #
func play_idle_animation():
	sprite.animation = "idle"
func play_walk_animation():
	sprite.animation = "walk"
func play_death_animation():
	sprite.animation = "death"


func _on_enemy_damage_timer_timeout() -> void:
	can_take_damage = true
	damage_timer.stop()


func _on_death_timer_timeout() -> void:
	_spawn_drops()
	queue_free()
