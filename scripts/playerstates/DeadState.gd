# res://scripts/states/DeadState.gd
extends PlayerState
class_name PlayerDeadState

var has_played_death_anim := false

func _init(_owner) -> void:
	owner = _owner

func enter(prev_state: String) -> void:
	# 进入死亡状态时，立刻禁止一切输入、停止人物移动
	owner.velocity = Vector2.ZERO
	owner.attack_ip = false
	owner.is_charging = false
	owner.moving = false

	# 播放死亡动画：根据 current_dir 决定用 up/down/side
	var base_dir = owner.current_dir if owner.current_dir in ["up", "down"] else "side"
	var anim_name = "%s_death" % base_dir
	owner.play_animation(anim_name)  # 播一遍死亡动画

	# 确保动画回调只触发一次
	has_played_death_anim = false

	# 如果你需要在动画结束后做清理或回收，可以监听 animation_finished
	if owner.has_node("AnimPlayer"):
		var anim_player = owner.get_node("AnimPlayer") as AnimationPlayer
		if not anim_player.is_connected("animation_finished", Callable(self, "_on_death_animation_finished")):
			anim_player.connect("animation_finished", Callable(self, "_on_death_animation_finished"))


func physics_update(delta: float) -> void:
	# 死亡状态时，不允许任何移动或切换
	owner.velocity = Vector2.ZERO
	# 不需要调用 owner.change_state()，除非你让死亡后某个时机自动重生
	pass

func process(delta: float) -> void:
	# 不做额外逻辑，角色保持死亡动画即可
	pass

func exit(next_state: String) -> void:
	# 离开死亡状态前，如果有需要断开信号或重置标志，写在这里
	if owner.has_node("AnimPlayer"):
		var anim_player = owner.get_node("AnimPlayer") as AnimationPlayer
		if anim_player.is_connected("animation_finished", Callable(self, "_on_death_animation_finished")):
			anim_player.disconnect("animation_finished", Callable(self, "_on_death_animation_finished"))


# 当死亡动画结束时触发的回调
func _on_death_animation_finished(anim_name: String) -> void:
	# 确保只响应一次“死亡动画播放完”事件
	if has_played_death_anim:
		return
	has_played_death_anim = true

	# 如果动画名不是以下几种之一，则忽略（防止其他动画也触发此函数）
	var valid_names = ["down_death", "up_death", "side_death"]
	if anim_name in valid_names:
		# 1) 停止角色的所有运动、碰撞
		owner.velocity = Vector2.ZERO
		owner.set_physics_process(false)   # 禁用 physics 处理
		owner.set_process(false)           # 禁用 process 处理

		# 2) （可选）播放一个“消失”淡出效果，或延时再删除节点
		#    这里举例延时 0.5 秒后 queue_free()
		owner.get_tree().create_timer(0.5).connect("timeout", Callable(self, "_on_death_timeout"))

func _on_death_timeout() -> void:
	# 1) 角色真正下线或删除
	owner.queue_free()

	# 2) （可选）如果你想重生或切场景，可以在这里进行
	#    get_tree().change_scene("res://scenes/YourRespawnScene.tscn")
	pass
