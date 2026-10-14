extends CanvasLayer

## Popup modal de confirmación Sí/No, reutilizable.
## Uso: instanciar, conectar 'confirmed' / 'cancelled' y llamar a open().

signal confirmed
signal cancelled

@onready var _title: Label = $Dim/Center/Panel/VBox/Title
@onready var _yes_button: Button = $Dim/Center/Panel/VBox/Buttons/Yes
@onready var _no_button: Button = $Dim/Center/Panel/VBox/Buttons/No


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_yes_button.pressed.connect(_on_yes_pressed)
	_no_button.pressed.connect(_on_no_pressed)


func open(message: String = "¿Quieres seguir?") -> void:
	_title.text = message
	visible = true
	add_to_group("modal_popups")
	get_tree().paused = true


func _close() -> void:
	visible = false
	remove_from_group("modal_popups")


func _on_yes_pressed() -> void:
	_close()
	confirmed.emit()


func _on_no_pressed() -> void:
	_close()
	cancelled.emit()
