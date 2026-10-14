extends CanvasLayer

## Popup de introducción por páginas. Explica cada parte de la interfaz en una
## ventana (al estilo de ConfirmPopup: panel centrado sobre un fondo oscurecido)
## y deja el objetivo para la última. Solo se muestra la primera vez por sesión.

## Solo se muestra una vez por sesión (mientras el juego sigue abierto).
static var _shown_this_session := false

## Páginas del tutorial: cada una explica una parte de la interfaz.
## Las acciones de la partida (Saltar, Correr, Impulso) van agrupadas y la
## última página es el objetivo.
## Cada página tiene una ilustración (el nombre del nodo dentro de "Illustration")
## que muestra el elemento de la interfaz al que se refiere.
const PAGES := [
	{
		"title": "Bienvenido a Memoria Interactiva",
		"text": "Memoria Interactiva es un videojuego educativo desarrollado como proyecto de grado, cuyo objetivo es promover el conocimiento, la identidad y las costumbres del Palenque de San Basilio a través de una experiencia interactiva.",
		"illustration": "Welcome",
	},
	{
		"title": "Movimiento",
		"text": "Muévete arrastrando este control en cualquier dirección.",
		"illustration": "Joystick",
	},
	{
		"title": "Acciones",
		"text": "Saltar, Correr e Impulso.\nEstos botones sirven para saltar, correr e impulsarte.",
		"illustration": "Actions",
	},
	{
		"title": "Salud y energía",
		"text": "Barra roja: indica tu salud actual. Si llega a cero, pierdes.\n\nBarra azul: se gasta al realizar acciones. Espera a que se recargue para volver a usarla.",
		"illustration": "Bars",
	},
	{
		"title": "Minimapa",
		"text": "Muestra tu posición y los alrededores del mapa.",
		"illustration": "Minimap",
	},
	{
		"title": "Pausa",
		"text": "Pon pausa al juego.",
		"illustration": "Pause",
	},
	{
		"title": "Objetivo",
		"text": "Avanza, toca el tambor y luego busca y recoge las cartas.",
		"illustration": "Arrow",
	},
]

@onready var _title: Label = $Dim/Center/Panel/VBox/Title
@onready var _illustration: CenterContainer = $Dim/Center/Panel/VBox/Illustration
@onready var _text: Label = $Dim/Center/Panel/VBox/Text
@onready var _prev: Button = $Dim/Center/Panel/VBox/Nav/Prev
@onready var _next: Button = $Dim/Center/Panel/VBox/Nav/Next
@onready var _timer: Timer = $Timer
@onready var _minimap_shot: TextureRect = $Dim/Center/Panel/VBox/Illustration/Minimap/Shot
@onready var _minimap_viewport: SubViewport = $MinimapViewport
@onready var _minimap_camera: Camera2D = $MinimapViewport/Camera2D

var _index := 0


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Solo la primera vez que se entra al nivel 1 en esta sesión.
	if _shown_this_session:
		queue_free()
		return
	_shown_this_session = true
	# La página "Minimapa" muestra una vista real del mundo en curso: un
	# SubViewport que comparte el mundo 2D y una cámara que apunta al jugador.
	_minimap_viewport.world_2d = get_viewport().world_2d
	_minimap_shot.texture = _minimap_viewport.get_texture()
	_prev.pressed.connect(_on_prev_pressed)
	_next.pressed.connect(_on_next_pressed)
	_timer.one_shot = true
	_timer.timeout.connect(open)
	_timer.start()


func open() -> void:
	_index = 0
	_refresh()
	_center_minimap()
	visible = true
	add_to_group("modal_popups")
	get_tree().paused = true


## Centra la cámara del minimapa en el jugador para que la página "Minimapa"
## muestre la zona actual del juego.
func _center_minimap() -> void:
	var player := get_tree().get_first_node_in_group("Player")
	if player is Node2D:
		_minimap_camera.global_position = (player as Node2D).global_position


func close() -> void:
	visible = false
	remove_from_group("modal_popups")
	get_tree().paused = false


## Refresca la página actual y el estado de los botones de navegación.
func _refresh() -> void:
	var page: Dictionary = PAGES[_index]
	_title.text = page.title
	_text.text = page.text
	# Muestra solo la ilustración de la página actual.
	for child in _illustration.get_children():
		child.visible = child.name == page.illustration
	_prev.disabled = _index == 0
	_next.text = "Siguiente" if _index < PAGES.size() - 1 else "Empezar"


func _on_prev_pressed() -> void:
	if _index > 0:
		_index -= 1
		_refresh()


func _on_next_pressed() -> void:
	if _index < PAGES.size() - 1:
		_index += 1
		_refresh()
	else:
		close()
