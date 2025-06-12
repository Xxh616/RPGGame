# Global.gd
extends Node

# 🧍‍♂️ 玩家状态
var player_health: int = 100
var player_max_health: int = 100
var player_alive: bool = true
var player_current_attack: bool = false
var player_regen_rate: int = 5
var player_regen_interval: float = 3.0
var player_attack: int = 1
var player_defense: int = 1
var player_status: int = 5
var first_enter_game=true
var visible_range=Vector2(0.107,0.1)

# 🌍 场景管理
var current_scene: String = "hometown"
var transition_scene: bool = false

# 📍 位置记录（用来切换时存放玩家位置）
var player_exited_cliffside_posx = 194
var player_exited_cliffside_posy = 24
var player_start_posx = 85
var player_start_posy = 95

# —— 新增部分 —— 
# 存储“切换后玩家应该出现的全局坐标”
var next_spawn_posx: float = 0
var next_spawn_posy: float = 0

# 存储“切换后玩家朝向”（可选，如果你想让切换后保持面朝方向）
var next_face_direction: String = ""
# —— 新增结束 —— 

var game_first_load: bool = true
