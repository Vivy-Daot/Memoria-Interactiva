extends Node2D

## Generador procedural del Nivel 2 (plataformas) de Memoria Interactiva.
##
## Construye el nivel encadenando fragmentos ("chunks") prediseñados en un
## orden aleatorio cada vez que la escena se carga, en lugar de generación
## 100% libre. Esto mantiene el nivel siempre jugable (cada chunk garantiza
## que su suelo conecta perfectamente con el anterior) mientras varía su
## recorrido, orden de retos y longitud en cada partida.

@export_group("Fragmentos")
## Chunk fijo con el que siempre empieza el nivel (zona segura de spawn).
@export var chunk_start: PackedScene
## Chunk fijo con el que siempre termina el nivel (incluye la salida).
@export var chunk_end: PackedScene
## Fragmentos intermedios que se combinan al azar.
@export var chunks_pool: Array[PackedScene] = []

@export_group("Longitud del nivel")
@export var min_chunks: int = 6
@export var max_chunks: int = 10

const MAIN_MENU_SCENE := "res://Scenes/Mainmenu.tscn"
const GAME_OVER_POPUP := preload("res://Scenes/GameOverPopup.tscn")

## Altura (world y) del origen del personaje cuando está de pie en el suelo
## (superficie en y=0). La cámara deja de bajar más allá de aquí, para no seguir
## al jugador cuando cae a un hueco.
const CAMERA_STOP_ORIGIN_Y := -77.0
## Avance mínimo en suelo entre checkpoints; se adapta a la longitud de cada plataforma.
const SAFE_CHECKPOINT_SPACING := 200.0

## Capas del fondo del Nivel 2 (de cielo a primer plano). Se replican dentro del
## minimapa porque el ParallaxBackground normal es un CanvasLayer y la cámara del
## minimapa (que solo ve el world_2d compartido) no lo dibuja.
const MINIMAP_BACKGROUND_LAYERS := [
	preload("res://Assets/Segundo Nivel/00_background.png"),
	preload("res://Assets/Segundo Nivel/05_mountains.png"),
	preload("res://Assets/Segundo Nivel/07_hills.png"),
	preload("res://Assets/Segundo Nivel/11_grass.png"),
]
## Tamaño del minimapa del Nivel 2: más ancho que alto, para ver un tramo más
## amplio del nivel a los lados SIN ganar altura.
const MINIMAP_SIZE := Vector2i(300, 200)
## Zoom de la cámara del minimapa. En Godot 4 un valor menor aleja la vista
## (se ve más zona del nivel). 0.5 -> 0.3 para alejar el minimapa del Nivel 2.
const MINIMAP_ZOOM := 0.3
## Sube la cámara del minimapa respecto al personaje: así el personaje queda en
## la parte baja del recuadro y no se muestra tanto vacío por debajo de él.
const MINIMAP_VERTICAL_OFFSET := 150.0

@export_group("Seguridad")
## Si el jugador cae por debajo de este límite (p. ej. falla un salto sobre
## un hueco), se le devuelve a la última posición segura en la que estaba
## tocando el suelo, en vez de dejarlo caer para siempre.
@export var fall_limit_y: float = 1500.0
## Porcentaje de la vida máxima que pierde el jugador cada vez que cae del nivel.
@export_range(0.0, 1.0, 0.05) var fall_damage_percent: float = 0.2

@onready var _player = $CharacterBody2D
@onready var _chunks_container: Node2D = $Chunks
@onready var _hud = $TouchControls
@onready var _camera: Camera2D = $CharacterBody2D/Camera2D

var _last_safe_position: Vector2
var _was_on_floor: bool = false
## Evita mostrar el popup de derrota más de una vez.
var _game_over := false


func _ready() -> void:
	randomize()
	_generate_level()
	_connect_hud()
	_setup_minimap()


## Conecta las señales del jugador a las barras del HUD. El nivel 2 instancia su
## propio TouchControls y, a diferencia del nivel 1 (main.gd), nadie lo conectaba,
## así que las barras de vida y stamina nunca se actualizaban.
func _connect_hud() -> void:
	if not is_instance_valid(_player) or _hud == null:
		return
	_hud.set_player(_player)
	_player.health_changed.connect(_hud.set_health)
	_player.stamina_changed.connect(_hud.set_stamina)
	# Refresca las barras: el jugador ya emitió su estado inicial en su _ready,
	# antes de que este HUD estuviera conectado.
	_hud.set_health(_player.health, _player.get_max_health())
	_hud.set_stamina(_player.stamina, _player.get_max_stamina())


## Configura el minimapa del Nivel 2: lo hace más ancho que alto, aleja la
## cámara, la sube respecto al personaje y le pone el fondo del nivel por detrás
## del mundo, de modo que muestre la misma imagen de fondo que el juego.
func _setup_minimap() -> void:
	if _hud == null or not _hud.has_node("MinimapViewport"):
		return
	if _hud.has_method("set_minimap_vertical_follow_limit"):
		_hud.set_minimap_vertical_follow_limit(CAMERA_STOP_ORIGIN_Y)
	var viewport: SubViewport = _hud.get_node("MinimapViewport")

	# Recuadro más ancho (mantiene la esquina superior derecha y la altura).
	viewport.size = MINIMAP_SIZE
	var display: TextureRect = _hud.get_node_or_null("MinimapDisplay")
	var outline: Panel = _hud.get_node_or_null("MinimapOutline")
	if display:
		display.offset_left = display.offset_right - float(MINIMAP_SIZE.x)
		display.offset_bottom = display.offset_top + float(MINIMAP_SIZE.y)
		if outline:
			outline.offset_left = display.offset_left
			outline.offset_top = display.offset_top
			outline.offset_right = display.offset_right
			outline.offset_bottom = display.offset_bottom

	var cam: Camera2D = viewport.get_node_or_null("Camera2D")
	if cam:
		cam.zoom = Vector2(MINIMAP_ZOOM, MINIMAP_ZOOM)
		# offset en Y negativo = cámara por encima del personaje.
		cam.offset = Vector2(0.0, -MINIMAP_VERTICAL_OFFSET)

	if viewport.has_node("Background"):
		return
	# CanvasLayer en capa -1: se dibuja por detrás del mundo (capa 0) y, a
	# diferencia de una cámara, no se mueve, así que el fondo queda fijo llenando
	# el minimapa mientras el nivel se desplaza por encima.
	var layer := CanvasLayer.new()
	layer.name = "Background"
	layer.layer = -1
	viewport.add_child(layer)
	for texture in MINIMAP_BACKGROUND_LAYERS:
		var rect := TextureRect.new()
		rect.texture = texture
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(rect)
		rect.set_anchors_preset(Control.PRESET_FULL_RECT)


## La cámara sigue al jugador en horizontal y al saltar, pero NO baja con él
## cuando cae a un hueco: se queda a la altura del suelo. Se usa global_position
## porque el personaje tiene scale 0.5 (con position el desplazamiento quedaría a
## la mitad y la cámara seguiría bajando).
func _update_camera_clamp() -> void:
	if _camera == null:
		return
	if _player.global_position.y > CAMERA_STOP_ORIGIN_Y:
		_camera.global_position = Vector2(_camera.global_position.x, CAMERA_STOP_ORIGIN_Y)
	else:
		_camera.position = Vector2.ZERO


func _physics_process(_delta: float) -> void:
	if _game_over or not is_instance_valid(_player):
		return

	_update_camera_clamp()

	var on_floor: bool = _player.is_on_floor()
	var just_landed: bool = on_floor and not _was_on_floor
	if on_floor and (just_landed or _player.position.x - _last_safe_position.x >= SAFE_CHECKPOINT_SPACING):
		_last_safe_position = _player.position
	_was_on_floor = on_floor

	if _player.position.y > fall_limit_y:
		_player.velocity = Vector2.ZERO
		_player.position = _last_safe_position
		_apply_fall_damage()


## Cada caída resta 'fall_damage_percent' de la vida máxima del jugador; si la
## vida llega a 0, se muestra el popup de derrota.
func _apply_fall_damage() -> void:
	if not is_instance_valid(_player):
		return
	_player.take_damage(_player.get_max_health() * fall_damage_percent)
	if _player.health <= 0.0:
		_show_game_over()


## Muestra el popup de derrota (una sola vez) y espera a que el jugador vuelva
## al menú principal.
func _show_game_over() -> void:
	if _game_over:
		return
	_game_over = true
	var popup = GAME_OVER_POPUP.instantiate()
	add_child(popup)
	popup.finished.connect(_on_game_over_finished)
	popup.open()


func _on_game_over_finished() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


## Limpia el nivel anterior (si lo hubiera) y arma uno nuevo desde cero.
func _generate_level() -> void:
	for child in _chunks_container.get_children():
		child.queue_free()

	var cursor := Vector2.ZERO
	cursor = _place_chunk(chunk_start, cursor)

	var chunk_count := randi_range(min_chunks, max_chunks)
	var previous_chunk: PackedScene = null
	for _i in range(chunk_count):
		var next_chunk := _pick_random_chunk(previous_chunk)
		if next_chunk == null:
			continue
		cursor = _place_chunk(next_chunk, cursor)
		previous_chunk = next_chunk

	_place_chunk(chunk_end, cursor)

	if is_instance_valid(_player):
		_player.velocity = Vector2.ZERO
		_player.position = Vector2(50, -50)
		_last_safe_position = _player.position
		_was_on_floor = false


## Elige un chunk al azar de la bolsa, evitando repetir el mismo fragmento
## dos veces seguidas (si la bolsa tiene más de una opción disponible).
func _pick_random_chunk(exclude: PackedScene) -> PackedScene:
	if chunks_pool.is_empty():
		return null
	if chunks_pool.size() == 1:
		return chunks_pool[0]

	var choice: PackedScene = chunks_pool[randi() % chunks_pool.size()]
	var attempts := 0
	while choice == exclude and attempts < 8:
		choice = chunks_pool[randi() % chunks_pool.size()]
		attempts += 1
	return choice


## Instancia un chunk en la posición "cursor" (su punto de entrada local es
## siempre (0,0), así que basta con colocar la raíz ahí) y devuelve la
## posición donde debe empezar el siguiente fragmento.
func _place_chunk(chunk_scene: PackedScene, cursor: Vector2) -> Vector2:
	if chunk_scene == null:
		return cursor

	var chunk := chunk_scene.instantiate()
	_chunks_container.add_child(chunk)
	chunk.position = cursor

	var offset := Vector2(300, 0)
	if chunk.has_method("get_exit_offset"):
		offset = chunk.get_exit_offset()

	return cursor + offset
