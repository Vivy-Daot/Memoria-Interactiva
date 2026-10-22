extends CanvasLayer

## Popup que muestra una carta coleccionable en detalle (arte + título + texto).
## Se usa tanto al recoger una carta por primera vez como al examinarla desde la
## colección del menú principal.

signal closed

@onready var _image: TextureRect = $Dim/Center/Panel/VBox/Image
@onready var _title: Label = $Dim/Center/Panel/VBox/Title
@onready var _text: Label = $Dim/Center/Panel/VBox/Text
@onready var _button: Button = $Dim/Center/Panel/VBox/Close


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_button.pressed.connect(_on_close_pressed)


func open(title: String, text: String, texture: Texture2D) -> void:
	_title.text = title
	_text.text = text
	_image.texture = texture
	visible = true
	add_to_group("modal_popups")
	get_tree().paused = true


func _on_close_pressed() -> void:
	visible = false
	remove_from_group("modal_popups")
	get_tree().paused = false
	closed.emit()