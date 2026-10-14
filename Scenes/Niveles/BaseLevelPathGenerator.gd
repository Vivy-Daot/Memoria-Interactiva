@tool
extends Node2D

## Genera un fondo de pasto y, sobre él, un camino en forma de trenza
## (dos curvas que se entrecruzan) usando el TileMapLayer existente.
## Reemplaza el pintado manual tile por tile que tenía antes BaseLevel.

@export var tile_layer: TileMapLayer

@export_group("Área del nivel (en tiles)")
@export var map_width: int = 200
@export var map_height: int = 200

@export_group("Tiles")
## Fuente y coordenadas del tile de pasto (relleno de fondo)
@export var grass_source_id: int = 1
@export var grass_atlas_coords: Vector2i = Vector2i(0, 0)
## Fuente y coordenadas del tile de camino (ajusta esto según el tile
## "recto/abierto" que quieras usar de tu hoja Path_Tile)
@export var path_source_id: int = 0
@export var path_atlas_coords: Vector2i = Vector2i(1, 1)

@export_group("Forma de la trenza")
## Separación vertical entre el punto más alto y más bajo de cada hebra (en tiles)
@export var amplitude_tiles: float = 6.0
## Cuántos cruces completos ocurren a lo largo de todo el nivel
@export var cycles: float = 5.0
## Grosor de cada hebra del camino, en tiles a cada lado del centro
@export var strand_thickness: int = 1
## Fila (en tiles) donde se centra verticalmente la trenza
@export var center_row: int = 36

@export_group("Bosque (Caracoli)")
## TileMapLayer donde se pintan los árboles (hoja aparte del camino/pasto)
@export var forest_layer: TileMapLayer
## Fuente y coordenadas del tile de árbol dentro de ForestLayer
@export var tree_source_id: int = 0
@export var tree_atlas_coords: Vector2i = Vector2i(0, 0)
## Separación entre "casillas" candidatas para un árbol, en tiles
@export var tree_spacing: int = 7
@export var tree_row_spacing: int = 9
## Variación aleatoria de posición dentro de cada casilla, para que no se vea en cuadrícula
@export var tree_jitter: int = 2
## Probabilidad (0-1) de que una casilla candidata reciba un árbol
@export var tree_density: float = 0.65
## Cuántos tiles de margen se dejan libres de árboles alrededor del camino
@export_group("Bosque (Caracoli)")
@export var path_clear_margin_horizontal: int = 3
@export var path_clear_margin_vertical: int = 6
## 0 = aleatorio distinto cada vez que se genera; cualquier otro valor = reproducible
@export var tree_rng_seed: int = 0

@export_tool_button("Regenerar nivel")
var regenerate_action: Callable = generate


func _ready() -> void:
	if tile_layer == null:
		tile_layer = get_node_or_null("TileMapLayer") as TileMapLayer
	generate()


func generate() -> void:
	if tile_layer == null:
		tile_layer = get_node_or_null("TileMapLayer") as TileMapLayer
	if tile_layer == null:
		push_warning("BaseLevelPathGenerator: asigna 'tile_layer' en el inspector (o agrega un hijo llamado 'TileMapLayer').")
		return

	tile_layer.clear()
	_fill_background()
	_paint_braid()
	_paint_forest()


func _fill_background() -> void:
	for x in range(map_width):
		for y in range(map_height):
			tile_layer.set_cell(Vector2i(x, y), grass_source_id, grass_atlas_coords)


func _paint_braid() -> void:
	for x in range(map_width):
		var t := float(x) / float(map_width)
		var angle := t * TAU * cycles

		# Dos hebras desfasadas 180°: cuando una sube, la otra baja -> se cruzan
		var offset_a := sin(angle) * amplitude_tiles
		var offset_b := sin(angle + PI) * amplitude_tiles

		_paint_strand_column(x, center_row + int(round(offset_a)))
		_paint_strand_column(x, center_row + int(round(offset_b)))


func _paint_strand_column(x: int, center_y: int) -> void:
	for w in range(-strand_thickness, strand_thickness + 1):
		var y := center_y + w
		if y >= 0 and y < map_height:
			tile_layer.set_cell(Vector2i(x, y), path_source_id, path_atlas_coords)


## Dispersa el árbol "Caracoli" (versión simplificada) en la hoja ForestLayer,
## formando una especie de bosque sobre el pasto, dejando libre un margen
## alrededor del camino para que siga siendo transitable.
func _paint_forest() -> void:
	if forest_layer == null:
		forest_layer = get_node_or_null("ForestLayer") as TileMapLayer
	if forest_layer == null:
		push_warning("BaseLevelPathGenerator: agrega un TileMapLayer llamado 'ForestLayer' para el bosque.")
		return

	forest_layer.clear()

	var rng := RandomNumberGenerator.new()
	if tree_rng_seed != 0:
		rng.seed = tree_rng_seed
	else:
		rng.randomize()

	var y := tree_row_spacing
	while y < map_height:
		var x := tree_spacing
		while x < map_width:
			var jitter_x := rng.randi_range(-tree_jitter, tree_jitter)
			var jitter_y := rng.randi_range(-tree_jitter, tree_jitter)
			var cell := Vector2i(x + jitter_x, y + jitter_y)
			if rng.randf() <= tree_density and _is_far_from_path(cell):
				forest_layer.set_cell(cell, tree_source_id, tree_atlas_coords)
			x += tree_spacing
		y += tree_row_spacing


## Revisa si una celda (y su margen de seguridad) está libre del camino.
func _is_far_from_path(cell: Vector2i) -> bool:
	for dx in range(-path_clear_margin_horizontal, path_clear_margin_horizontal + 1):
		for dy in range(-path_clear_margin_vertical, path_clear_margin_vertical + 1):
			var check := Vector2i(cell.x + dx, cell.y + dy)

			if check.x < 0 or check.x >= map_width or check.y < 0 or check.y >= map_height:
				continue

			if tile_layer.get_cell_source_id(check) == path_source_id:
				return false

	return true
