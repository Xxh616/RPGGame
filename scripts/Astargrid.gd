# res://scripts/AStarGrid.gd
extends RefCounted
class_name AStarGrid

@export var allow_diagonal: bool = false
var tilemap: TileMap

func _init(_tilemap: TileMap) -> void:
	tilemap = _tilemap

func get_path(start_global: Vector2, goal_global: Vector2) -> Array:
	# 1) 把世界坐标转换到 TileMap2D 的本地坐标，再转成格子坐标 Vector2i
	var local_start = tilemap.to_local(start_global)
	var local_goal  = tilemap.to_local(goal_global)
	var start_cell: Vector2i = tilemap.local_to_map(local_start)
	var goal_cell:  Vector2i = tilemap.local_to_map(local_goal)

	# 2) A* 基础数据结构
	var open_set:    Array     = [ start_cell ]
	var closed_set:  Array     = []
	var came_from:   Dictionary= {}
	var g_score:     Dictionary= { start_cell: 0.0 }
	var f_score:     Dictionary= { start_cell: _heuristic(start_cell, goal_cell) }

	# 3) A* 主循环
	while open_set.size() > 0:
		var current: Vector2i = _get_lowest_f(open_set, f_score)
		if current == goal_cell:
			return _reconstruct_path(came_from, current)

		open_set.erase(current)
		closed_set.append(current)

		for neighbor in _get_neighbors(current):
			if neighbor in closed_set:
				continue
			var tentative_g = g_score.get(current, INF) + 1.0
			if neighbor not in open_set:
				open_set.append(neighbor)
			elif tentative_g >= g_score.get(neighbor, INF):
				continue
			came_from[neighbor]    = current
			g_score[neighbor]      = tentative_g
			f_score[neighbor]      = tentative_g + _heuristic(neighbor, goal_cell)

	# 找不到路径
	return []

func _get_neighbors(cell: Vector2i) -> Array:
	var dirs = [
		Vector2i( 1, 0), Vector2i(-1, 0),
		Vector2i( 0, 1), Vector2i( 0,-1)
	]
	if allow_diagonal:
		dirs += [
			Vector2i( 1, 1), Vector2i( 1,-1),
			Vector2i(-1, 1), Vector2i(-1,-1)
		]
	var result: Array = []
	var used_rect: Rect2i = tilemap.get_used_rect()
	for d in dirs:
		var nb = cell + d
		# 先保证在地图已用区内，再保证瓦片 id != -1
		if used_rect.has_point(nb):
			var tid = tilemap.get_cellv(nb)
			if tid != TileMap.INVALID_CELL:
				result.append(nb)
	return result

func _heuristic(a: Vector2i, b: Vector2i) -> float:
	# 曼哈顿距离
	return abs(a.x - b.x) + abs(a.y - b.y)

func _get_lowest_f(open_set: Array, f_score: Dictionary) -> Vector2i:
	var best = open_set[0]
	var best_f = f_score.get(best, INF)
	for cell in open_set:
		var f = f_score.get(cell, INF)
		if f < best_f:
			best_f = f
			best = cell
	return best

func _reconstruct_path(came_from: Dictionary, current: Vector2i) -> Array:
	var cells: Array = []
	# 回溯格子坐标路径
	while true:
		cells.insert(0, current)
		if not came_from.has(current):
			break
		current = came_from[current]
	# 转换到世界坐标（取瓦片中心）
	var world_path: Array = []
	for c in cells:
		var w = tilemap.map_to_world(c) + tilemap.cell_size * 0.5
		world_path.append(w)
	return world_path
