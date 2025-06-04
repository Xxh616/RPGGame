# res://scripts/Player.gd
extends CharacterBody2D

# —— 导出与外部引用 —— 
@export var speed := 100
@export var charge_move_speed := 30
@export var max_charge_time := 1.5
@export var attack_radius := 60
@export var attack_angle_degrees := 90

# HitBox 的配置：偏移距离 + 矩形半宽半高（请根据自己美术图尺寸调节）
@export var hitbox_offset := 12                  # 矩形中心距离角色中心的像素偏移
@export var hitbox_halfsize := Vector2(23.5, 29)          # 矩形半宽(30)半高(40)，整块尺寸 = (60×80)

# —— 枚举各个状态 ID —— 
enum States {
	IDLE,
	MOVE,
	CHARGE,
	ATTACK,
	HEAVY_ATTACK,
	DEAD
}

var states := {}                  # 存放各状态实例
var current_state                 # 当前 State 对象引用
var current_state_type: int = -1   # 初始设为 -1，保证第一次 change_state(IDLE) 会真正进入 enter()

var current_dir := "down"         # "up", "down", "left", "right"
var moving := false

# 蓄力与普通攻击相关
var is_charging := false
var charge_time := 0.0
var attack_ip := false
var attack_index := 0

# 拾取相关
var nearby_drops := []    # 当前碰到的掉落物引用列表
var itemselect: ItemDrop = null

# —— 缓存节点引用 —— 
@onready var sprite_groups := {
	"idle":   $idle,
	"run":    $run,
	"attack": $attack
}
@onready var anim_player   := $AnimPlayer
@onready var charge_bar    := $charge_bar
@onready var pickup_area   := $PickupArea as Area2D
@onready var health_bar    := $healthBar

# —— 新增：HitBox 相关引用 —— 
# 场景里必须有：Player (CharacterBody2D)
#    └─ HitBox (Area2D)
#         └─ CollisionShape2D (RectangleShape2D)
@onready var hitbox_area  := $PlayerHitBox           as Area2D
@onready var hitbox_shape := $PlayerHitBox/HitCollision

func _ready() -> void:
	if global.next_spawn_posx != 0 or global.next_spawn_posy != 0:
		global_position = Vector2(global.next_spawn_posx, global.next_spawn_posy)
		if global.next_face_direction != "":
			current_dir = global.next_face_direction
			PlayAnim("idle_%s" % current_dir, true)
		global.next_spawn_posx = 0
		global.next_spawn_posy = 0
		global.next_face_direction = ""
	print(">>> Player.gd _ready() called")

	# 1) 实例化各个状态并传入 self
	states[States.IDLE]         = preload("res://scripts/playerstates/IdleState.gd").new(self)
	states[States.MOVE]         = preload("res://scripts/playerstates/MoveState.gd").new(self)
	states[States.CHARGE]       = preload("res://scripts/playerstates/ChargeState.gd").new(self)
	states[States.ATTACK]       = preload("res://scripts/playerstates/AttackState.gd").new(self)
	states[States.HEAVY_ATTACK] = preload("res://scripts/playerstates/AttackState.gd").new(self)
	states[States.DEAD]         = preload("res://scripts/playerstates/DeadState.gd").new(self)

	# 2) 初始化拾取区域信号
	pickup_area.connect("area_entered", Callable(self, "_on_pickup_area_entered"))
	pickup_area.connect("area_exited",  Callable(self, "_on_pickup_area_exited"))

	# 3) 设置蓄力条初始隐藏
	charge_bar.visible = false
	charge_bar.max_value = 100
	charge_bar.value = 0

	# —— 新增：初始化 HitBox 的形状 & 信号 —— 
	var rect = RectangleShape2D.new()
	rect.extents = hitbox_halfsize
	hitbox_shape.shape = rect

	# 一开始让 HitBox 不检测
	hitbox_area.monitoring   = false
	hitbox_area.monitorable  = false

	# 绑定 HitBox 的 body_entered 信号，用于“检测到敌人进入红色矩形时掉血”
	hitbox_area.connect("body_entered", Callable(self, "_on_HitBox_body_entered"))

	# 首次让 HitBox 放到“朝下”位置
	_update_hitbox_offset()

	# 4) 直接切到初始状态 IDLE
	change_state(States.IDLE)
	print(">>> After change_state, current_state_type=", current_state_type)

func player():
	pass

func _physics_process(delta: float) -> void:
	# 由状态机接管：调用当前状态的 physics_update
	if current_state:
		current_state.physics_update(delta)

	# 统一执行移动
	move_and_slide()

	# 每帧都需要刷新拾取提示
	_refresh_drop_labels()

	# 刷新血条
	update_health_bar()

	# 如果血量 <= 0，且当前没在 DEAD，就切 Dead
	if global.player_health <= 0 and current_state_type != States.DEAD:
		change_state(States.DEAD)



func _process(delta: float) -> void:
	# 由状态机接管：调用当前状态的 process
	if current_state:
		current_state.process(delta)



func change_state(new_state_type: int) -> void:
	if current_state_type == new_state_type:
		return
	# 先调用 exit
	if current_state:
		current_state.exit(str(current_state_type))
	# 更新状态引用与编号
	current_state_type = new_state_type
	current_state = states[new_state_type]
	# 如果要切 HEAVY_ATTACK，需要先标记 is_heavy = true
	if new_state_type == States.HEAVY_ATTACK:
		states[States.HEAVY_ATTACK].is_heavy = true
	# 进入时调用 enter
	current_state.enter(str(current_state_type))



# —— 以下为之前散落的功能，作为状态机的“被调用者”或“辅助函数”保留在这里 —— #

func PlayAnim(anim_name: String, force_play := false) -> void:
	if anim_player == null:
		print(">>> ERROR: anim_player is null!")
		return
	if not force_play and anim_player.current_animation == anim_name:
		return
	anim_player.speed_scale = 1.5 if is_charging else 2.5
	for key in sprite_groups.keys():
		sprite_groups[key].visible = (key == current_action_group())
	set_flip_by_direction()
	anim_player.play(anim_name)



func current_action_group() -> String:
	if attack_ip:
		return "attack"
	elif moving:
		return "run"
	else:
		return "idle"



func set_flip_by_direction() -> void:
	var flip = current_dir == "left"
	var group = sprite_groups[current_action_group()]
	for child in group.get_children():
		if child is Sprite2D:
			child.flip_h = flip



func _on_pickup_area_entered(area: Area2D) -> void:
	var drop = area.get_parent()
	if drop is ItemDrop:
		nearby_drops.append(drop)



func _on_pickup_area_exited(area: Area2D) -> void:
	var drop = area.get_parent()
	if drop is ItemDrop:
		nearby_drops.erase(drop)
		drop.show_label(false)
		if itemselect == drop:
			itemselect = null



func _refresh_drop_labels() -> void:
	if nearby_drops.is_empty():
		itemselect = null
		return
	var nearest = nearby_drops[0]
	var best_d2 = (nearest.global_position - global_position).length_squared()
	for d in nearby_drops:
		var d2 = (d.global_position - global_position).length_squared()
		if d2 < best_d2:
			best_d2 = d2
			nearest = d
	for d in nearby_drops:
		d.show_label(d == nearest)
	itemselect = nearest



func get_attack_direction() -> Vector2:
	match current_dir:
		"right": return Vector2.RIGHT
		"left":  return Vector2.LEFT
		"up":    return Vector2.UP
		"down":  return Vector2.DOWN
		_:       return Vector2.ZERO



func take_damage(amount: int) -> void:
	global.player_health -= amount
	if global.player_health < 0:
		global.player_health = 0
	update_health_bar()
	print("⚠️ 玩家受击, 当前血量: ", global.player_health)



func update_health_bar() -> void:
	health_bar.max_value = global.player_max_health
	health_bar.value = global.player_health
	health_bar.visible = global.player_health < global.player_max_health



# —— 新增：根据 current_dir 更新 HitBox (红色矩形) 的偏移 —— #
func _update_hitbox_offset() -> void:
	match current_dir:
		"right":
			hitbox_area.position = Vector2(hitbox_offset, 0)
			hitbox_area.rotation_degrees = 0
		"left":
			hitbox_area.position = Vector2(-hitbox_offset, 0)
			hitbox_area.rotation_degrees = 0
		"down":
			hitbox_area.position = Vector2(0, hitbox_offset)
			hitbox_area.rotation_degrees = 0
		"up":
			hitbox_area.position = Vector2(0, -hitbox_offset)
			hitbox_area.rotation_degrees = 0
		_:
			hitbox_area.position = Vector2(0, hitbox_offset)
			hitbox_area.rotation_degrees = 0



# —— 新增：当 HitBox 检测到碰撞时，调用此函数让敌人掉血 —— #
func _on_HitBox_body_entered(body: Node) -> void:
	if body.is_in_group("Enemy") and body.has_method("take_damage"):
		body.take_damage(50)
		print("💥 击中敌人:", body.name)
