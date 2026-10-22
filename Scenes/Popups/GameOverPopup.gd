extends CanvasLayer

## Popup de derrota. Cuando la vida del jugador llega a cero se muestra
## "Perdiste" y, al continuar, se vuelve al menú principal.

signal finished

@onready var _continue_button: Button = $Dim/Center/Panel/VBox/Continue


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_continue_button.pressed.connect(_on_continue_pressed)


func open() -> void:
	visible = true
	add_to_group("modal_popups")
	get_tree().paused = true


func _on_continue_pressed() -> void:
	visible = false
	remove_from_group("modal_popups")
	finished.emit()