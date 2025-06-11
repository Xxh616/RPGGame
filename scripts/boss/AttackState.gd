# res://scripts/states/AttackState.gd
extends BossState
class_name BossAttackState


var damage_frames := [3, 4]        # 要在这两个帧索引造成伤害
var processed_frames := []         # 已经处理过伤害的帧
var anim_finished := false         # 用来检测动画播完
var player_has_attack:=false
func _init(_owner: Boss) -> void:
	owner = _owner

func enter(prev_state: String) -> void:
	# 重置状态
	processed_frames.clear()
	anim_finished = false
	owner.velocity = Vector2.ZERO

	# 计算朝向后缀，并更新 last_facing_dir
	var dv = (owner.player_node.global_position - owner.global_position).normalized()
	var suffix := ""
	if abs(dv.x) > abs(dv.y):
		suffix ="left" if  dv.x < 0 else "right"
		owner.anim_sprite.flip_h = dv.x < 0
	else:
		suffix = "up" if dv.y < 0   else "down"
	owner.last_facing_dir = suffix

	# 更新判定区
	owner.update_attack_area(suffix)
	var dir = "right" if suffix=="left" else suffix
	# 播放攻击动画（SpriteFrames 中取消 Loop）
	owner.anim_sprite.play("attack_" + dir)

func physics_update(delta: float) -> void:
	# 攻击期间不移动
	pass

func process(delta: float) -> void:
	if owner.player_in_safe_zone:
		owner.change_state(owner.States.RETURN)
		return
	var anim_name = owner.anim_sprite.animation
	if not anim_name.begins_with("attack_"):
		return

	var total = owner.anim_sprite.sprite_frames.get_frame_count(anim_name)
	var cur = owner.anim_sprite.frame

	# 1) 检查是否到要造成伤害的帧
	if cur in damage_frames and not (cur in processed_frames):
		_do_damage(cur)
		processed_frames.append(cur)

	# 2) 检测动画最后一帧，完成后切状态
	if cur == total - 1 and not anim_finished:
		anim_finished = true
		player_has_attack=false
		_on_attack_done()

func _do_damage(cur:int) -> void:
	# 遍历判定区内的 bodies，只对 player_node 造成一次伤害
	for body in owner.attack_area.get_overlapping_bodies():
		if body == owner.player_node and body.has_method("take_damage"):
			if cur==3:
				body.take_damage(20)
				player_has_attack=true
				break  # 每个攻击帧只命中一次
			elif cur==4 and !player_has_attack:
				body.take_damage(5)
				player_has_attack=true
				break
func _on_attack_done() -> void:
	# 重置冷却
	owner.time_since_last_attack = 0.0
	if owner.is_player_in_attack_range():
		# —— 直接重播本状态，不走 change_state() —— 
		processed_frames.clear()
		anim_finished = false
		# 播放一次性攻击动画
		owner.anim_sprite.play(owner.anim_sprite.animation)
		return
	# 根据玩家距离，切回 Chase 或 Idle
	if owner.is_player_in_chase_range():
		owner.change_state(owner.States.CHASE)
	else:
		owner.change_state(owner.States.IDLE)

func exit(next_state: String) -> void:
	# 可选：清理或停止动画
	pass
