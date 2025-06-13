extends Node

# 🧍‍♂️ Player state
var player_health: int = 100
var player_max_health: int = 100
var player_alive: bool = true
var player_current_attack: bool = false
var player_regen_rate: int = 5
var player_regen_interval: float = 3.0
var player_attack: int = 1
var player_defense: int = 1
var player_status: int = 5
var first_enter_game: bool = true
var visible_range: Vector2 = Vector2(0.107, 0.1)
var has_load: bool = false

# 🌍 Scene management
var current_scene: String = "hometown"
var transition_scene: bool = false

# 📍 Position records (to store player position when switching scenes)
var player_exited_cliffside_posx: float = 194
var player_exited_cliffside_posy: float = 24
var player_start_posx: float = 85
var player_start_posy: float = 95

# --- New additions ---
# Store the global coordinates where the player should spawn after a scene change
var next_spawn_posx: float = 0
var next_spawn_posy: float = 0

# Store the direction the player should face after a scene change (optional)
var next_face_direction: String = ""
# --- End new additions ---

var game_first_load: bool = true
