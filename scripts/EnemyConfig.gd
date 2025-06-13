extends Resource
class_name EnemyConfig

# — Basic attributes —
@export var enemy_name: String        = "Goblin"
@export var max_health: int           = 100
@export var speed: float              = 40.0
@export var run_speed: float          = 70.0
@export var chase_range: float        = 150.0
@export var attack_range: float       = 40.0
@export var invincible_time: float    = 0.8
@export var defense: int              = 10
@export var attack: int               = 10

# — Maximum idle time before switching state —
@export var max_idle_time: float      = 1.5

# — Sprite animation resource for this enemy —
@export var sprite_frames: SpriteFrames

@export_group("Drop Table")
# — Array of DropInfo resources specifying possible item drops —
@export var drops: Array[DropInfo]    = []
