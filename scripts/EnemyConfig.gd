# res://scripts/EnemyConfig.gd
extends Resource
class_name EnemyConfig

# —— 基础属性 —— 
@export var enemy_name: String = "Goblin"
@export var max_health: int = 100
@export var speed: float = 40.0
@export var run_speed: float = 70.0
@export var chase_range: float = 150.0
@export var attack_range: float = 40.0
@export var invincible_time: float = 0.8
@export var defense=10
@export var attack=10
# —— 这里是丢失的字段：最大 Idle 停留时间 —— 
@export var max_idle_time: float = 1.5

# —— 初始位置和巡逻点 —— 
# —— 精灵动画资源 —— 
@export var sprite_frames: SpriteFrames
@export_group("掉落表")
# —— 这里 drops 数组里存 DropInfo 资源 —— 
@export var drops: Array[DropInfo] = []
