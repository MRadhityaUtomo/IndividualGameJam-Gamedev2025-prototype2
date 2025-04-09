extends Resource
class_name SleightRecipe

@export var card_names: Array[String]  # Combo requirement
@export var name: String = "Unnamed Sleight"
@export var mana_cost: int = -1  # -1 = use sum of cards' cost

# The attack logic data (like a super CardResource)
@export var bullet_scene: PackedScene
@export var bullet_speed: float = 400.0
@export var bullet_count: int = 5
@export var spread_angle: float = 15.0
@export var fire_delay: float = 0.2
@export var is_burst: bool = false
@export var bullet_damage: int = 10
@export var card_image: Texture2D
