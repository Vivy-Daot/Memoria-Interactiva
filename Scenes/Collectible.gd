extends Area2D

## Carta coleccionable en el mundo. Al tocarla, el jugador la obtiene: se guarda
## en el gestor, se muestra el popup de la carta y, al cerrarlo, se avanza el
## recorrido (cuenta la run y vuelve al Nivel 1, o muestra la victoria si se
## completaron todas las runs). Sustituye a la antigua "Salida" del Nivel 2.

const CARD_POPUP_SCENE := "res://Scenes/CardPopup.tscn"
const VICTORY_POPUP := preload("res://Scenes/VictoryPopup.tscn")
const NEXT_LEVEL := "res://Scenes/main.tscn"
const MAIN_MENU_SCENE := "res://Scenes/Mainmenu.tscn"

## Si se deja vacío, se entrega la siguiente carta sin obtener.
@export var card_id: String = ""

var _taken := false
var _base_y := 0.0
var _time := 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_base_y = position.y
	$Sprite2D.texture = CollectibleManager.load_texture(CollectibleManager.CARD_TEXTURE)


func _process(delta: float) -> void:
	# Pequeño flotar para llamar la atención sobre la carta.
	_time += delta
	position.y = _base_y + sin(_time * 2.5) * 6.0


func _on_body_entered(body: Node2D) -> void:
	if _taken or not body.is_in_group("Player"):
		return
	_taken = true
	var card: Dictionary = CollectibleManager.get_card(card_id) if card_id != "" else CollectibleManager.pick_next()
	if card.is_empty():
		return
	CollectibleManager.collect(card.id)
	_show_card(card)


func _show_card(card: Dictionary) -> void:
	var popup = load(CARD_POPUP_SCENE).instantiate()
	add_child(popup)
	popup.closed.connect(_on_card_closed)
	popup.open(card.title, card.text, CollectibleManager.load_texture(card.texture))


func _on_card_closed() -> void:
	GameState.runs_completed += 1
	if GameState.runs_completed >= GameState.RUNS_TO_WIN:
		_show_victory()
		return
	get_tree().paused = false
	get_tree().change_scene_to_file(NEXT_LEVEL)


func _show_victory() -> void:
	var popup = VICTORY_POPUP.instantiate()
	add_child(popup)
	popup.finished.connect(_on_victory_finished)
	popup.open()


func _on_victory_finished() -> void:
	GameState.reset()
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)