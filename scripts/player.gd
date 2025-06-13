# res://scripts/Player.gd
extends CharacterBody2D
class_name Player

# —— Exported properties and external references —— 
@export var speed := 100                              # Movement speed
@export var charge_move_speed := 30                   # Speed while charging
@export var max_charge_time := 1.5                    # Maximum charge duration
@export var attack_radius := 60                       # Attack detection radius
@export var attack_angle_degrees := 90                # Attack angle

var thumpornot = false                                # Toggle between normal and heavy attack

# HitBox configuration: offset distance + half-size of the rectangle 
# (Adjust to match your art dimensions)
@export var hitbox_offset := 12                       # Offset from player center in pixels
@export var hitbox_halfsize := Vector2(23.5, 29)      # Half-size of hitbox (width=47, height=58)

# —— State IDs enumeration —— 
enum States {
	IDLE,
	MOVE,
	CHARGE,
	ATTACK,
	HEAVY_ATTACK,
	DEAD
}

var states := {}                                      # Holds instances of each state
var current_state                                    # Reference to current state object
var current_state_type: int = -1                      # Ensure first change_state enters IDLE

var current_dir := "down"                             # Facing direction: "up", "down", "left", "right"
var moving := false                                   # Is the player moving?

# Charging and basic attack flags
var is_charging := false
var charge_time := 0.0
var attack_ip := false
var attack_index := 0

# Pickup-related
var nearby_drops := []                                # List of ItemDrop instances in range
var itemselect: ItemDrop = null

# —— Cached node references —— 
@onready var sprite_groups := {
	"idle":   $idle,
	"run":    $run,
	"attack": $attack,
	"dead":   $dead
}
@onready var anim_player   := $AnimPlayer
@onready var charge_bar    := $charge_bar
@onready var pickup_area   := $PickupArea as Area2D
@onready var health_bar    := $healthBar

# —— HitBox (Area2D with CollisionShape2D) references —— 
@onready var hitbox_area  := $PlayerHitBox           as Area2D
@onready var hitbox_shape := $PlayerHitBox/HitCollision

func _ready() -> void:
	# If a next spawn position is set, teleport player there
	if global.next_spawn_posx != 0 or global.next_spawn_posy != 0:
		global_position = Vector2(global.next_spawn_posx, global.next_spawn_posy)
		if global.next_face_direction != "":
			current_dir = global.next_face_direction
			PlayAnim("idle_%s" % current_dir, true)
		global.next_spawn_posx = 0
		global.next_spawn_posy = 0
		global.next_face_direction = ""
	print(">>> Player.gd _ready() called")

	# 1) Instantiate each state with self reference
	states[States.IDLE]         = preload("res://scripts/playerstates/IdleState.gd").new(self)
	states[States.MOVE]         = preload("res://scripts/playerstates/MoveState.gd").new(self)
	states[States.CHARGE]       = preload("res://scripts/playerstates/ChargeState.gd").new(self)
	states[States.ATTACK]       = preload("res://scripts/playerstates/AttackState.gd").new(self)
	states[States.HEAVY_ATTACK] = preload("res://scripts/playerstates/AttackState.gd").new(self)
	states[States.DEAD]         = preload("res://scripts/playerstates/DeadState.gd").new(self)

	# 2) Connect pickup area signals
	pickup_area.connect("area_entered", Callable(self, "_on_pickup_area_entered"))
	pickup_area.connect("area_exited",  Callable(self, "_on_pickup_area_exited"))

	# 3) Initialize charge bar
	charge_bar.visible = false
	charge_bar.max_value = 100
	charge_bar.value = 0

	# —— Initialize HitBox shape & signals —— 
	var rect = RectangleShape2D.new()
	rect.extents = hitbox_halfsize
	hitbox_shape.shape = rect

	# Disable HitBox monitoring at start
	hitbox_area.monitoring  = false
	hitbox_area.monitorable = false

	# Connect HitBox body_entered signal for enemy hit detection
	hitbox_area.connect("body_entered", Callable(self, "_on_HitBox_body_entered"))

	# Position HitBox based on facing direction
	_update_hitbox_offset()

	# 4) Switch to initial IDLE state
	change_state(States.IDLE)
	print(">>> After change_state, current_state_type=", current_state_type)

func player():
	pass

func _physics_process(delta: float) -> void:
	# Let the state machine handle physics updates
	if current_state:
		current_state.physics_update(delta)

	# Apply movement
	move_and_slide()

	# Refresh pickup labels each frame
	_refresh_drop_labels()

	# Update health bar UI
	update_health_bar()

	# If health ≤ 0 and not already DEAD, switch to DEAD state
	if global.player_health <= 0 and current_state_type != States.DEAD:
		change_state(States.DEAD)

func _process(delta: float) -> void:
	# Let the state machine handle per-frame logic
	if current_state:
		current_state.process(delta)

func change_state(new_state_type: int) -> void:
	if current_state_type == new_state_type:
		return
	# Exit current state
	if current_state:
		current_state.exit(str(current_state_type))
	# Update state references
	current_state_type = new_state_type
	current_state = states[new_state_type]
	# Mark heavy attack if switching to HEAVY_ATTACK
	if new_state_type == States.HEAVY_ATTACK:
		states[States.HEAVY_ATTACK].is_heavy = true
	# Enter new state
	current_state.enter(str(current_state_type))

# —— Below are helper methods used by states or other logic —— #

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
	if current_state_type == States.DEAD:
		return "dead"
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
	# Damage is reduced by defense factor
	var factor = 100.0 / (100.0 + global.player_defense)
	global.player_health -= (amount * factor)
	if global.player_health < 0:
		global.player_health = 0
	update_health_bar()
	print("⚠️ Player took damage, current health: ", global.player_health)

func update_health_bar() -> void:
	health_bar.max_value = global.player_max_health
	health_bar.value = global.player_health
	health_bar.visible = global.player_health < global.player_max_health

# —— Update HitBox position based on facing direction —— #
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

# —— Called when HitBox detects a body, applies damage to enemies —— #
func _on_HitBox_body_entered(body: Node) -> void:
	if body.is_in_group("Enemy") and body.has_method("take_damage"):
		var factor = (100.0 + global.player_attack) / 100.0
		if thumpornot:
			body.take_damage(50 * factor + 0.2 * global.player_attack)
		else:
			body.take_damage(20 * factor)
		print("💥 Hit enemy:", body.name)
