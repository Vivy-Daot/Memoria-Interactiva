# Scenes/LevelExit.gd
extends Area2D

## Zona de salida. Al entrar el jugador puede:
##  - viajar directamente a 'target_scene', o
##  - pedir confirmación ("¿Quieres seguir?") antes de viajar, y
##  - contar el recorrido como completado (condición de victoria).

@export var target_scene: String = ""
## Pide confirmación Sí/No antes de viajar.
@export var ask_confirmation: bool = false
## Cuenta esta salida como un "run" completado. Al llegar a GameState.RUNS_TO_WIN
## se muestra la victoria y se vuelve al menú principal.
@export var completes_run: bool = false
## Escena a la que se vuelve si el jugador rechaza la confirmación.
@export_file("*.tscn") var reject_scene: String = "res://Scenes/Gameplay/main.tscn"

const CONFIRM_POPUP := preload("res://Scenes/Popups/ConfirmPopup.tscn")
const VICTORY_POPUP := preload("res://Scenes/Popups/VictoryPopup.tscn")
const MAIN_MENU_SCENE := "res://Scenes/Menus/Mainmenu.tscn"

var _busy := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if _busy or not body.is_in_group("Player"):
		return
	if target_scene == "" or not ResourceLoader.exists(target_scene):
		return
	_busy = true

	if completes_run:
		GameState.runs_completed += 1
		if GameState.runs_completed >= GameState.RUNS_TO_WIN:
			_show_victory()
			return

	if ask_confirmation:
		_show_confirmation()
	else:
		_travel()


func _travel() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(target_scene)


func _go_back() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(reject_scene)


func _go_to_main_menu() -> void:
	GameState.reset()
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func _show_confirmation() -> void:
	var popup = CONFIRM_POPUP.instantiate()
	add_child(popup)
	popup.confirmed.connect(_travel)
	popup.cancelled.connect(_go_back)
	popup.open("¿Quieres seguir?")


func _show_victory() -> void:
	var popup = VICTORY_POPUP.instantiate()
	add_child(popup)
	popup.finished.connect(_go_to_main_menu)
	popup.open()
