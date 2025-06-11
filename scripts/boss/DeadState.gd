# res://scripts/states/BossDeadState.gd
extends BossState
class_name BossDeadState


var has_queued_free: bool = false   # 是否已执行 queue_free()

func _init(_owner: Boss) -> void:
	owner = _owner

func enter(prev_state: String) -> void:
	# 停止所有移动
	owner.velocity = Vector2.ZERO
	# 播放死亡动画（在 SpriteFrames 里，请务必取消 Loop）
	owner.anim_sprite.play("dead")
	has_queued_free = false

func physics_update(delta: float) -> void:
	# 死亡状态不需要物理更新
	pass

func process(delta: float) -> void:
	# 等待 death 动画播到最后一帧
	if has_queued_free:
		return
	if owner.anim_sprite.animation != "dead":
		return

	var anim_name = "dead"
	var total_frames = owner.anim_sprite.sprite_frames.get_frame_count(anim_name)
	var cur_frame = owner.anim_sprite.frame
	if cur_frame == total_frames - 1:
		has_queued_free = true
		owner.queue_free()

func exit(next_state: String) -> void:
	pass
