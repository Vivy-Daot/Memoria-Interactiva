extends Node

## Nivel 1. La pausa la gestiona el propio PauseMenu (instanciado en la escena),
## así que aquí solo se conecta el HUD al personaje.

@onready var character = $MainCharacter
@onready var hud = $TouchControls


func _ready() -> void:
	character.health_changed.connect(hud.set_health)
	character.stamina_changed.connect(hud.set_stamina)
	hud.set_player(character)
