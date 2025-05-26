extends Node

# 🧍‍♂️ 玩家状态
var player_health: int = 100
var player_max_health: int = 100
var player_alive: bool = true
var player_current_attack: bool = false
var player_regen_rate: int = 20
var player_regen_interval: float = 3.0

# 🌍 场景管理
var current_scene: String = "world"
var transition_scene: bool = false

# 📍 位置记录
var player_exited_cliffside_posx = 194
var player_exited_cliffside_posy = 24
var player_start_posx = 85
var player_start_posy = 95
var game_first_load: bool = true
