extends CanvasLayer

## Pantalla de colección: muestra todas las cartas (las no obtenidas aparecen
## bloqueadas) y permite examinar cada una en detalle. Se abre desde el menú
## principal.

const COLUMNS := 3
## Número de casillas que muestra la colección (3x3). Se reservan aunque
## todavía no existan cartas suficientes, para dejar espacio a las futuras.
const MAX_SLOTS := 9
## Tamaño fijo (en píxeles) del icono de cada carta en la cuadrícula. Mantiene
## todas las casillas con el mismo icono sin importar la longitud del título.
const CARD_ICON_SIZE := Vector2i(48, 64)

@onready var _grid: GridContainer = $Dim/Center/Panel/VBox/Grid
@onready var _card_popup = $CardPopup
@onready var _close_button: Button = $Dim/Center/Panel/VBox/Close


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_close_button.pressed.connect(close)


func open() -> void:
	visible = true
	_refresh()


func close() -> void:
	visible = false


func _refresh() -> void:
	for child in _grid.get_children():
		child.queue_free()
	_grid.columns = COLUMNS
	var slots: int = maxi(CollectibleManager.CARDS.size(), MAX_SLOTS)
	for i in range(slots):
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(140, 140)
		# Icono de tamaño uniforme para todas las casillas. Con expand_icon cada
		# botón escalaba el icono según el espacio que dejara su texto (los
		# títulos cortos quedaban enormes y los largos casi invisibles), así que
		# el icono se dibuja a un tamaño fijo preescalado (ver _make_icon).
		btn.expand_icon = false
		if i < CollectibleManager.CARDS.size():
			var card: Dictionary = CollectibleManager.CARDS[i]
			if CollectibleManager.is_collected(card.id):
				btn.text = card.title
				btn.icon = _make_icon(CollectibleManager.load_texture(card.texture))
				btn.pressed.connect(_on_card_pressed.bind(card.id))
			else:
				btn.text = "???"
				btn.disabled = true
		else:
			# Casilla vacía reservada para cartas futuras.
			btn.text = "???"
			btn.disabled = true
		_grid.add_child(btn)


## Devuelve una textura del icono escalada a un tamaño fijo (CARD_ICON_SIZE),
## para que todas las cartas muestren su icono del mismo tamaño.
func _make_icon(texture: Texture2D) -> Texture2D:
	if texture == null:
		return null
	var img := texture.get_image()
	if img == null:
		return texture
	img.resize(CARD_ICON_SIZE.x, CARD_ICON_SIZE.y, Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(img)


func _on_card_pressed(id: String) -> void:
	var card: Dictionary = CollectibleManager.get_card(id)
	if card.is_empty():
		return
	_card_popup.open(card.title, card.text, CollectibleManager.load_texture(card.texture))
