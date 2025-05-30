# res://scripts/SlimeConfig.gd
extends Resource
class_name SlimeConfig

@export_group("外观")
@export var sprite_frames: SpriteFrames
@export var sprite_scale: Vector2 = Vector2.ONE
@export var sprite_modulate: Color = Color(1,1,1)

@export_group("参数")
@export var jump_speed:      float = 80.0
@export var damage_amount:   int   = 10
@export var attack_anim_time:     float = 0.5
@export var attack_cooldown_time: float = 1.0
@export var attack_landing_frame: int   = 5
@export var attack_hit_range:     float = 20.0

@export_group("额外技能")
@export var skills: Array[PackedScene] = []

@export_group("掉落表")
# —— 这里 drops 数组里存 DropInfo 资源 —— 
@export var drops: Array[DropInfo] = []
