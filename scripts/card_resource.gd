extends Resource
class_name CardResource

@export var card_name: String
@export var bullet_scene: PackedScene
@export var bullet_speed: float
@export var bullet_count: int
@export var spread_angle: float
@export var card_image: Texture2D
@export var fire_delay: float
@export var is_burst: bool 
@export var mana_cost: int
@export var bullet_damage: int
@export var start_delay: float = 0.0

# Pattern type (used by PatternManager)
@export_enum("SPREAD", "BURST", "SPIRAL", "FAN", "RING", "SPIN", "ALTERNATE_RING", "FLOWER", "CROSS_SPIN","CONVERGE")
var pattern_type: String

@export var lock_tags: Array[String] = []
# Optional parameters for Cross Spin Pattern
@export var per_arm_dist: float = 100.0
@export var cross_spin_distance: float = 64.0  
@export var cross_spin_duration: float = 5.0  
@export var cross_spin_speed: float = 90.0     

# For Lock In pattern
@export var convergence_delay: float  # e.g., 1.5
@export var converge_radius: float  # e.g., 1.5
