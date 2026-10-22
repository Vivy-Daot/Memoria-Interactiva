extends CanvasLayer

## Popup de victoria: muestra "Ganaste!" y, al continuar, vuelve al menú
## principal. La invitación a seguir jugando solo se muestra si todavía quedan
## cartas por coleccionar.

signal finished

@onready var _subtitle: Label = $Dim/Center/Panel/VBox/Subtitle
@onready var _continue_button: Button = $Dim/Center/Panel/VBox/Continue


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_continue_button.pressed.connect(_on_continue_pressed)


func open() -> void:
	# Si ya se coleccionaron todas las cartas no queda nada por aprender, así que
	# se oculta la línea que invita a volver a jugar.
	_subtitle.visible = CollectibleManager.collected_count() < CollectibleManager.total()
	visible = true
	add_to_group("modal_popups")
	get_tree().paused = true


func _on_continue_pressed() -> void:
	visible = false
	remove_from_group("modal_popups")
	finished.emit()