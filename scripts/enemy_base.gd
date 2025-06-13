extends CharacterBody2D
class_name EnemyBase

# New fields: attack area offset and half-size
@export var attack_offset : Vector2 = Vector2(15, 5)    # Distance from character center to attack area center
@export var attack_halfsize  : Vector2 = Vector2(20, 10) # Half-extents of the attack area rectangle

# Cached references to AttackArea and its CollisionShape2D
@onready var attack_area  := $AttackArea as Area2D
@onready var attack_shape := $AttackArea/CollisionShape2D as CollisionShape2D

# New state flag: whether damage detection is enabled
var attack_valid : bool = false

# Inspector-exposed list of EnemyConfig resources
@export var configs: Array[EnemyConfig] = []
var config: EnemyConfig                         # The currently selected config

# Player reference and return point
@export var player_path: NodePath
var return_point: Vector2 = Vector2.ZERO

# State enumeration
enum States {
	IDLE,
	PATROL,
	CHASE,
	ATTACK,
	RETURN,
	DEAD
}

# Internal state machine variables
var states: Dictionary = {}          # Holds instances of each state
var current_state                   # Reference to the current state instance
var current_state_type: int = -1     # The current state enum value
@export var initial_position: Vector2 = Vector2.ZERO
@export var patrol_points: Array[Vector2] = []
var patrol_index: int = 0            # Index of the current patrol target

# Attributes and status
var health: int
var is_invincible: bool = false
var invincible_timer: float = 0.0
var idle_time: float = 0.0

# Cached player reference and last facing direction
var player: CharacterBody2D = null
var last_facing_dir: String = "down"

# Cached node references
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar := $healthBar as ProgressBar

func _ready() -> void:
	# Select a random config from the list if available
	if configs.size() > 0:
		config = configs[randi() % configs.size()]
	else:
		push_error("EnemyBase.gd: No configs resource list provided!")
		return

	print("Loaded Goblin")
	# Validate that a config was assigned
	if config == null:
		push_error("EnemyBase.gd: You must assign an EnemyConfig resource in the Inspector!")
		return

	# Initialize return point using the provided initial position
	return_point = initial_position

	# Apply sprite frames from config
	if anim_sprite and config.sprite_frames:
		anim_sprite.frames = config.sprite_frames
	else:
		push_error("EnemyBase.gd: anim_sprite not found or config.sprite_frames is unset!")

	# Initialize health and health bar visibility
	health = config.max_health
	if health_bar:
		health_bar.max_value = config.max_health
		health_bar.value = health
		health_bar.visible = false

	# Add this node to the "Enemy" group for hit detection
	add_to_group("Enemy")

	# Acquire player reference based on the NodePath
	if player_path != null and has_node(player_path):
		player = get_node(player_path) as CharacterBody2D
	else:
		push_error("EnemyBase.gd: Cannot find player reference! Check player_path or assign player directly.")

	# Instantiate and cache each state script
	states[States.IDLE]   = preload("res://scripts/states/IdleState.gd").new(self)
	states[States.PATROL] = preload("res://scripts/states/PatrolState.gd").new(self)
	states[States.CHASE]  = preload("res://scripts/states/ChaseState.gd").new(self)
	states[States.ATTACK] = preload("res://scripts/states/AttackState.gd").new(self)
	states[States.RETURN] = preload("res://scripts/states/ReturnState.gd").new(self)
	states[States.DEAD]   = preload("res://scripts/states/DeadState.gd").new(self)

	# Disable attack area monitoring by default
	attack_area.monitoring  = false
	attack_area.monitorable = false

	# Start in the IDLE state
	current_state_type = -1  # Ensure change_state will apply the first time
	change_state(States.IDLE)

func _physics_process(delta: float) -> void:
	# Handle idle timing and transitions if in IDLE
	if current_state_type == States.IDLE:
		idle_time += delta
		play_animation("idle")  # Continuously play idle animation

		# If player enters chase range, switch immediately to CHASE
		if is_player_in_chase_range():
			idle_time = 0.0
			change_state(States.CHASE)
			return

		# If idle time exceeds max_idle_time, switch to PATROL
		if idle_time >= config.max_idle_time:
			idle_time = 0.0
			change_state(States.PATROL)
			return

		return  # Skip further logic while idling

	# Otherwise, delegate to the current state's physics_update
	if current_state:
		current_state.physics_update(delta)

	# Handle invincibility timer
	if is_invincible:
		invincible_timer -= delta
		if invincible_timer <= 0.0:
			is_invincible = false
			anim_sprite.modulate = Color(1, 1, 1, 1)

	# Update health bar and attack area every physics frame
	update_healthbar()
	update_attack_area()

func _process(delta: float) -> void:
	# Delegate to current state's non-physics process method
	if current_state:
		current_state.process(delta)

func change_state(new_state_type: int) -> void:
	# Do nothing if we're already in the requested state
	if current_state_type == new_state_type:
		return

	# Call exit on the old state if it exists
	if current_state:
		current_state.exit(str(current_state_type))

	current_state_type = new_state_type
	current_state = states.get(new_state_type, null)

	# Reset idle timer when entering IDLE
	if new_state_type == States.IDLE:
		idle_time = 0.0

	# Call enter on the new state
	if current_state:
		current_state.enter(str(current_state_type))

# Public methods for state scripts to call:

func is_player_in_chase_range() -> bool:
	if player == null:
		return false
	return global_position.distance_to(player.global_position) <= config.chase_range

func is_player_in_attack_range() -> bool:
	if player == null:
		return false
	return global_position.distance_to(player.global_position) <= config.attack_range

func is_player_lost_sight() -> bool:
	# Consider the player lost if beyond 1.25x chase range
	if player == null:
		return true
	return global_position.distance_to(player.global_position) > config.chase_range * 1.25

func take_damage(amount: float) -> void:
	# Ignore damage if invincible or already dead
	if is_invincible or current_state_type == States.DEAD:
		return

	var factor = 100.0 / (config.defense + 100.0)
	health -= amount * factor
	if health < 0:
		health = 0

	update_healthbar()

	if health <= 0:
		change_state(States.DEAD)
	else:
		# Enter invincibility blink
		is_invincible = true
		invincible_timer = config.invincible_time
		anim_sprite.modulate = Color(1, 1, 1, 0.5)

func play_animation(state: String) -> void:
	var anim_name: String

	if state == "idle":
		# Default to idle_down with no horizontal flip
		anim_name = "idle_down"
		anim_sprite.flip_h = false
	else:
		# Determine facing direction based on velocity or last_facing_dir
		var dir_vec: Vector2 = velocity
		var dir_name: String = last_facing_dir

		if dir_vec.length() > 0:
			if abs(dir_vec.x) > abs(dir_vec.y):
				# Horizontal movement takes priority
				if dir_vec.x >= 0:
					dir_name = "right"
					anim_sprite.flip_h = false
				else:
					dir_name = "right"
					anim_sprite.flip_h = true
			else:
				# Vertical movement
				if dir_vec.y < 0:
					dir_name = "up"
				else:
					dir_name = "down"
				anim_sprite.flip_h = false

			last_facing_dir = dir_name
		else:
			# No movement: keep previous facing, but normalize flip for left
			if last_facing_dir == "left":
				dir_name = "right"
			else:
				dir_name = last_facing_dir

		anim_name = "%s_%s" % [state, dir_name]

	if anim_sprite.animation != anim_name:
		anim_sprite.play(anim_name)

func update_healthbar() -> void:
	# Update health bar value and visibility based on current health
	if health_bar:
		health_bar.max_value = config.max_health
		health_bar.value = health
		health_bar.visible = (health < config.max_health)

func get_patrol_point() -> Vector2:
	# Return the current patrol point or own position if none defined
	if patrol_points.size() == 0:
		return global_position
	return patrol_points[patrol_index]

func advance_to_next_patrol() -> void:
	# Advance patrol_index, wrapping around the list
	if patrol_points.size() == 0:
		return
	patrol_index = (patrol_index + 1) % patrol_points.size()

func reset_patrol() -> void:
	# Reset patrol_index to start over
	patrol_index = 0

func _spawn_drops() -> void:
	if config == null:
		return

	# Preload the ItemDrop scene
	var drop_scene: PackedScene = preload("res://scenes/item_drop.tscn")

	for drop_data in config.drops:
		# chance is between 0.0 and 1.0
		if randf() < drop_data.chance and drop_data.item != null:
			var drop_instance = drop_scene.instantiate() as ItemDrop
			if drop_instance == null:
				push_error("EnemyBase.gd: Failed to cast instantiated node to ItemDrop!")
				continue
			drop_instance.item_id = drop_data.item.id
			drop_instance.count   = drop_data.count
			get_parent().add_child(drop_instance)
			drop_instance.global_position = global_position + drop_data.offset

func update_attack_area() -> void:
	# Update shape extents if needed
	var rect = attack_shape.shape as RectangleShape2D
	rect.extents = attack_halfsize

	# Position the Area2D based on last_facing_dir
	match last_facing_dir:
		"up":
			attack_area.position = Vector2(0, -attack_offset.y)
		"down":
			attack_area.position = Vector2(0, attack_offset.y)
		"right":
			attack_area.position = Vector2(attack_offset.x, 0)
		"left":
			attack_area.position = Vector2(-attack_offset.x, 0)

	# Keep rotation unchanged
	attack_area.rotation_degrees = 0

func _on_attack_area_body_entered(body: Node) -> void:
	if body == player:
		attack_valid = true

func _on_attack_area_body_exited(body: Node) -> void:
	if body == player:
		attack_valid = false
