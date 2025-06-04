# res://scripts/HouseController.gd
#
# 这个脚本在 _ready() 阶段：
# 1. 自动读取 TileMap 已铺瓦片的范围 (Rect2i)；
# 2. 将瓦片坐标范围转换为世界像素边界；
# 3. 计算半屏补偿后，为 Camera2D 动态赋值 limit_left/top/right/bottom，
#    从而使摄像机永远不会移出瓦片区域以外、显示空白。
#
# 使用步骤：
# 1. 在场景（例如 House.tscn）的根节点（Node2D）上挂载此脚本。
# 2. 在 Inspector 里，将 tilemap_node_path 设置为你的 TileMap 节点路径（例如 "TileMap"）。
# 3. 将 player_node_path 设置为你的 Player 节点路径（例如 "player"），并确保 Player 下面有一个名为 "Camera2D" 的子节点。
# 4. 运行场景后，相机会自动跟随玩家并受限于瓦片范围。

extends Node2D

# —— 在 Inspector 中指定 —— 
@export var tilemap_node_path: NodePath
@export var player_node_path: NodePath

func _ready():
	# ---- 1. 获取 TileMap 节点 ----
	if not has_node(tilemap_node_path):
		push_error("HouseController.gd: 找不到 tilemap_node_path = %s" % str(tilemap_node_path))
		return
	var tilemap := get_node(tilemap_node_path) as TileMap

	# ---- 2. 获取 Player 节点 ----
	if not has_node(player_node_path):
		push_error("HouseController.gd: 找不到 player_node_path = %s" % str(player_node_path))
		return
	var player := get_node(player_node_path) as Node2D

	# ---- 3. 确保 Player 下挂有一个 Camera2D ----
	if not player.has_node("Camera2D"):
		push_error("HouseController.gd: 在 player 节点下未找到 Camera2D，请确认 Player 下挂了名为 'Camera2D' 的子节点")
		return
	var cam := player.get_node("Camera2D") as Camera2D

	# ---- 4. 读取 TileMap 已使用瓦片的范围（瓦片坐标空间 Rect2i） ----
	var used_rect: Rect2i = tilemap.get_used_rect()
	# 举例：若瓦片范围是横向 16 列、纵向 12 行，
	# 那么 used_rect.position == Vector2i(0,0)，used_rect.size == Vector2i(16,12)

	# ---- 5. 获取每个瓦片的像素尺寸（Godot 4 中用 get_cell_size()） ----
	var cell_size: Vector2 = tilemap.get_cell_size()
	# 例如，如果你的瓦片集每个瓦片大小是 32×32 像素，则 cell_size == Vector2(32, 32)

	# ---- 6. 计算“瓦片世界左上角”对应的像素坐标 ----
	# map_to_world(瓦片坐标) 将瓦片坐标 (Vector2i) 转换为世界像素坐标 (Vector2)
	var map_world_top_left: Vector2 = tilemap.map_to_world(used_rect.position)
	# 如果 TileMap 没做任何偏移，这里就是 (0,0)。否则它会返回带偏移的实际值。

	# ---- 7. 计算“瓦片世界右下角”对应的像素坐标 ----
	# used_rect.size 是 Vector2i，需要先转为 Vector2，再乘以 cell_size
	var map_world_bottom_right: Vector2 =map_world_top_left + used_rect.size.to_vector2() * cell_size
	# 注意：to_vector2() 会把 Vector2i 转换成 Vector2。

	# ---- 8. 获取当前视口 (Viewport) 可视大小，并计算半屏尺寸 ----
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	var half_vp: Vector2 = vp_size * 0.5

	# ---- 9. 根据“瓦片世界左右上下边界” 加/减 半屏尺寸，计算 Camera2D 的 limit ----
	# Camera2D.limit_left/limit_top/limit_right/limit_bottom 作用于“摄像机中心点”坐标：
	var limit_left:   int = int(map_world_top_left.x + half_vp.x)
	var limit_top:    int = int(map_world_top_left.y + half_vp.y)
	var limit_right:  int = int(map_world_bottom_right.x - half_vp.x)
	var limit_bottom: int = int(map_world_bottom_right.y - half_vp.y)

	# ---- 10. 将计算结果赋给 Camera2D ----
	cam.limit_left   = limit_left
	cam.limit_top    = limit_top
	cam.limit_right  = limit_right
	cam.limit_bottom = limit_bottom

	# ---- 11. 启用此 Camera2D 并让它跟随玩家 ----
	cam.current = true
	cam.make_current()

	# （可选）如需平滑跟随可额外开启平滑
	# cam.smoothing_enabled = true
	# cam.smoothing_speed = 5.0
