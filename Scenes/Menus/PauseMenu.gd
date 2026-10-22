extends CanvasLayer

## Menú de pausa (táctil). Se instancia dentro de cada nivel.
## Procesa siempre (PROCESS_MODE_ALWAYS) para poder abrir/cerrar la pausa aunque
## el árbol esté pausado. Recibe la acción "Pause" (botón táctil o tecla Esc).

const MAIN_MENU_SCENE := "res://Scenes/Menus/Mainmenu.tscn"

@onready var _options_menu = $OptionsMenu
@onready var _resume_button: Button = $Dim/Center/Panel/VBox/Resume
@onready var _menu_button: Button = $Dim/Center/Panel/VBox/MainMenu
@onready var _options_button: Button = $Dim/Center/Panel/VBox/Options


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_resume_button.pressed.connect(resume)
	_menu_button.pressed.connect(_on_main_menu_pressed)
	_options_button.pressed.connect(_on_options_pressed)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("Pause"):
		toggle()


func toggle() -> void:
	if visible:
		resume()
	elif _can_pause():
		pause()


## No abrir la pausa si hay otro popup modal en pantalla (p. ej. confirmación).
func _can_pause() -> bool:
	return get_tree().get_nodes_in_group("modal_popups").is_empty()


func pause() -> void:
	visible = true
	get_tree().paused = true


func resume() -> void:
	visible = false
	get_tree().paused = false


func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func _on_options_pressed() -> void:
	_options_menu.open()