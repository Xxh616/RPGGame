# DeadState.gd
extends State

var death_timer := 0.0
var death_duration := 1.0  # 死亡动画时长

func enter(prev_state:String) -> void:
	owner.play_animation("die")
	death_timer = 0.0
	# 禁止碰撞/移动
	owner.set_collision_layer(0)
	owner.set_collision_mask(0)
	owner.velocity = Vector2.ZERO

func physics_update(delta: float) -> void:
	death_timer += delta
	if death_timer >= death_duration:
		owner.queue_free()  # 播放完死亡动画后，销毁哥布林节点

func process(delta: float) -> void:
	pass
