extends CharacterBody2D
class_name Boss

@export var chase_speed: float        = 80.0
@export var stopping_distance: float = 40    # Matches the attack range
@export var attack_cooldown: float   = 1.5   # Seconds between attacks
@onready var attack_area: Area2D            = $AttackArea
@onready var attack_shape: RectangleShape2D = $AttackArea/CollisionShape2D.shape
var attack_range = 10

enum States { IDLE, CHASE, ATTACK, DEAD, RETURN }

var states: Dictionary = {}
var current_state: BossState = null
var current_state_type: int = -1

# Timer for attack cooldown
var time_since_last_attack: float = 999.0

# --- Safe zone & return point ---
@export var safe_zone_path: NodePath
@export var home_position: Vector2 = Vector2(376, 189)

# --- Player safe zone flag ---
var player_in_safe_zone: bool = false

@onready var safe_zone: Area2D = get_node(safe_zone_path)
# Cache nodes
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var agent: NavigationAgent2D      = $NavigationAgent2D
@export var player_path: NodePath           # In the Inspector: set to "../player"
@onready var player_node: Node2D = get_node(player_path)  # Adjust path as needed

# --- Health system ---
@export var max_health: int = 100
var health: int
@export var attack: int = 200
@export var defense: int = 300
# Cache the health bar control (ProgressBar or TextureProgress)
@onready var health_bar := $healthBar

# Last facing direction, used for Idle state
var last_facing_dir: String = "down"

func _ready() -> void:
	# Register all state instances
	states[States.IDLE]   = BossIdleState.new(self)
	states[States.CHASE]  = BossChaseState.new(self)
	states[States.ATTACK] = BossAttackState.new(self)
	states[States.DEAD]   = BossDeadState.new(self)
	states[States.RETURN] = BossReturnState.new(self)
	# Configure navigation
	agent.max_speed = chase_speed
	agent.target_desired_distance = stopping_distance
	add_to_group("Enemy")
	change_state(States.IDLE)

func _physics_process(delta: float) -> void:
	update_healthbar()
	if current_state:
		current_state.physics_update(delta)

func _process(delta: float) -> void:
	# Accumulate attack cooldown timer
	time_since_last_attack += delta
	if current_state:
		current_state.process(delta)

func change_state(new_state: int) -> void:
	if new_state == current_state_type:
		return
	if current_state:
		current_state.exit(str(new_state))
	current_state_type = new_state
	current_state = states[new_state]
	print("Boss changed state %s" % current_state_type)
	if current_state:
		current_state.enter(str(current_state_type))

func is_player_in_chase_range() -> bool:
	# Start chasing if the player is within twice the attack distance
	return player_node and global_position.distance_to(player_node.global_position) <= stopping_distance * 2

func is_player_in_attack_range() -> bool:
	# Attack only when within stopping_distance
	return player_node and global_position.distance_to(player_node.global_position) <= stopping_distance

func update_attack_area(dir: String) -> void:
	# Reposition and resize the attack area based on facing direction
	var offset := Vector2.ZERO
	var extents := Vector2(10, 10)
	var rot_deg := 0.0

	match dir:
		"up":
			offset = Vector2(0, -attack_range)
			rot_deg = -90
			extents = Vector2(30, 20)
		"down":
			offset = Vector2(0, attack_range)
			rot_deg = 90
			extents = Vector2(30, 20)
		"left":
			offset = Vector2(-attack_range, 0)
			rot_deg = 0
			extents = Vector2(30, 20)
		"right":
			offset = Vector2(attack_range, 0)
			rot_deg = 0
			extents = Vector2(30, 20)

	# Apply position, rotation, and size
	attack_area.position = offset
	attack_area.rotation_degrees = rot_deg
	attack_shape.extents = extents

func _on_safe_zone_enter(body: Node) -> void:
	if body == player_node:
		player_in_safe_zone = true
		# As soon as player enters safe zone, interrupt any chase or attack and return home
		change_state(States.RETURN)

func _on_safe_zone_exit(body: Node) -> void:
	if body == player_node:
		player_in_safe_zone = false

func take_damage(amount: int) -> void:
	# Ignore damage if already dead
	if current_state_type == States.DEAD:
		return
	var factor = 100.0 / (100 + defense)
	health = max(health - amount * factor, 0)
	health_bar.value = health

	if health == 0:
		change_state(States.DEAD)

func update_healthbar() -> void:
	"""
	Update the health bar's value and visibility based on current health:
	only show the bar when health is below maximum.
	"""
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = health
		health_bar.visible = (health < max_health)
