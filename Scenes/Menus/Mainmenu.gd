extends Node

## Menú principal. El botón "Opciones" abre el panel OptionsMenu.tscn.

@onready var options_menu = $OptionsMenu
@onready var collection = $Collection


func _process(_delta: float) -> void:
	# Todos los botones del menú son Buttons interactivos por toque (ver
	# input_devices/pointing/emulate_mouse_from_touch). "Pause" (Esc) sigue
	# abriendo las opciones como atajo de teclado.
	if Input.is_action_just_pressed("Pause"):
		_open_options()


func _on_iniciar_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Gameplay/main.tscn")


func _on_quitar_pressed() -> void:
	get_tree().quit()


func _on_opciones_pressed() -> void:
	_open_options()


func _open_options() -> void:
	if is_instance_valid(options_menu):
		options_menu.open()


func _on_cartas_pressed() -> void:
	if is_instance_valid(collection) and not collection.visible:
		collection.open()
