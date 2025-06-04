# PlayerState.gd
extends RefCounted
class_name PlayerState   # 把原来的 State 改为 PlayerState

# 每个 State 都会拿到一个 owner（也就是 Player 或 Goblin 本体），用于访问共享数据与方法
var owner

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
