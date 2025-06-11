# res://scripts/boss/BossState.gd
extends RefCounted
class_name BossState

var owner  # 会被 new(owner) 传进来

func _init(_owner) -> void:
	owner = _owner

func enter(prev_state: String) -> void:
	pass

func physics_update(delta: float) -> void:
	pass

func process(delta: float) -> void:
	pass

func exit(next_state: String) -> void:
	pass
