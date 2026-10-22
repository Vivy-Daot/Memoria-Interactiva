extends CanvasLayer

@onready var health_bar = $HealthBar
@onready var stamina_bar = $StaminaBar
@onready var minimap_camera = $MinimapViewport/Camera2D

var player_ref: Node2D = null
var minimap_vertical_follow_limit: float = INF

func _ready() -> void:
	$MinimapViewport.world_2d = get_viewport().world_2d

func _process(_delta: float) -> void:
	if is_instance_valid(player_ref):
		var target_position: Vector2 = player_ref.global_position
		target_position.y = minf(target_position.y, minimap_vertical_follow_limit)
		minimap_camera.global_position = target_position

func set_player(player: Node2D) -> void:
	player_ref = player

func set_minimap_vertical_follow_limit(world_y: float) -> void:
	minimap_vertical_follow_limit = world_y

func set_health(current: float, max_value: float) -> void:
	health_bar.max_value = max_value
	health_bar.value = current

func set_stamina(current: float, max_value: float) -> void:
	stamina_bar.max_value = max_value
	stamina_bar.value = current
