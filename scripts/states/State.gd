# State.gd
extends RefCounted
class_name State

# 由主脚本传入的引用，用来访问哥布林的属性、方法、场景树等
var owner

func _init(_owner):
	owner = _owner

# 进入该状态时调用（可选，如播放一次动画）
func enter(prev_state:String) -> void:
	pass

# 离开该状态时调用（可选，如重置参数）
func exit(next_state:String) -> void:
	pass

# 每帧更新时调用（物理相关逻辑写在这里）
func physics_update(delta: float) -> void:
	pass

# 每帧更新时调用（非物理，如播放动画、发送信号等）
func process(delta: float) -> void:
	pass
