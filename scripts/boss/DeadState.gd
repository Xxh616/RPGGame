# res://scripts/states/BossDeadState.gd
extends BossState
class_name BossDeadState

var has_queued_free: bool = false   # Whether queue_free() has already been executed

func _init(_owner: Boss) -> void:
	owner = _owner

func enter(prev_state: String) -> void:
	# Stop all movement
	owner.velocity = Vector2.ZERO
	# Play the death animation (ensure Loop is disabled in SpriteFrames)
	owner.anim_sprite.play("dead")
	has_queued_free = false

func physics_update(delta: float) -> void:
	# No physics updates needed in the death state
	pass

func process(delta: float) -> void:
	# Wait until the 'dead' animation reaches its final frame
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
	# Optional cleanup on exit (none needed here)
	pass
