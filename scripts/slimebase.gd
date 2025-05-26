# res://scripts/SlimeBase.gd
extends EnemyBase        # 继承已注册的 EnemyBase
class_name SlimeBase    # 注册为全局类型
signal died
# —— 配置资源 —— 
@export var config: SlimeConfig                    # 可拖入 .tres 配置文件

# —— 外观可视化参数 —— 
@export var sprite_frames: SpriteFrames            # 备用帧集（当 config 未设置时使用）
@export var sprite_scale: Vector2 = Vector2.ONE
@export var sprite_modulate: Color = Color(1,1,1)

# —— 基础行为参数（可被 config 覆盖） —— 
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
@onready var death_timer: Timer           = $death_timer

# —— 内部状态 —— 
var has_landed: bool = false
var attack_target_position: Vector2


func _ready() -> void:
	super._ready()                # 调用 EnemyBase._ready()
	_apply_appearance_and_params()
	_instantiate_skills()
	init_timers()
	_connect_signals()

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

	# 同步调整 hit_box 里的 CollisionShape2D（以 RectangleShape2D 为例）
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
	attack_timer.wait_time    = attack_anim_time
	cooldown_timer.wait_time  = attack_cooldown_time
	attack_timer.connect("timeout", Callable(self, "_on_attack_timer_timeout"))
	cooldown_timer.connect("timeout", Callable(self, "_on_attack_cooldown_timer_timeout"))

func _connect_signals() -> void:
	sprite.connect("frame_changed", Callable(self, "_on_animated_frame_changed"))
	sprite.connect("animation_finished", Callable(self, "_on_animation_finished"))
	detection_area.connect("body_entered", Callable(self, "_on_detection_area_body_entered"))
	detection_area.connect("body_exited", Callable(self, "_on_detection_area_body_exited"))
	hit_box.connect("body_entered", Callable(self, "_on_enemy_hit_box_body_entered"))
	hit_box.connect("body_exited", Callable(self, "_on_enemy_hit_box_body_exited"))
	damage_timer.connect("timeout", Callable(self, "_on_enemy_damage_timer_timeout"))
	death_timer.connect("timeout", Callable(self, "_on_death_timer_timeout"))

# —— 攻击流程 —— #
func perform_attack() -> void:
	if not player or attack_cooldown:
		return
	attacking       = true
	attack_cooldown = true
	has_landed      = false
	attack_target_position = player.position

	hit_box.global_position = attack_target_position
	hit_box.visible         = true
	hit_box.monitoring      = false

	velocity = (attack_target_position - position).normalized() * jump_speed
	sprite.play("attack")
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
	sprite.play("idle")
	cooldown_timer.start()

func _on_attack_cooldown_timer_timeout() -> void:
	attack_cooldown = false

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

# —— 命中区域（留空扩展） —— #
func _on_enemy_hit_box_body_entered(body: Node) -> void:
	pass
func _on_enemy_hit_box_body_exited(body: Node) -> void:
	pass

# —— 受击与死亡 —— #
func take_damage(amount: int) -> void:
	if not can_take_damage:
		return
	health -= amount
	if health <= 0:
		die()
	else:
		can_take_damage = false
		damage_timer.start()

func _on_enemy_damage_timer_timeout() -> void:
	can_take_damage = true

func die() -> void:
	attacking       = false
	attack_cooldown = true
	sprite.play("death")
	death_timer.start()

func _on_death_timer_timeout() -> void:
	emit_signal("died")
	queue_free()
