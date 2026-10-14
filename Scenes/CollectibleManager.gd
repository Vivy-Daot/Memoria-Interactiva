class_name CollectibleManager
extends RefCounted

## Gestor de cartas coleccionables. Las cartas obtenidas se guardan en una
## variable estática, de modo que el estado persiste entre cambios de escena
## durante toda la sesión (igual que GameState).

## Arte de las cartas (una sola imagen compartida por todas las cartas).
const CARD_TEXTURE := "res://Assets/Collectibles/card_palenque.png"

## Catálogo de cartas coleccionables sobre el Palenque de San Basilio.
## 'texture' es el arte de cada carta.
const CARDS := [
	{
		"id": "card_01",
		"title": "El Primer Pueblo Libre de América",
		"text": "San Basilio de Palenque fue fundado en el siglo XVII por personas esclavizadas que escaparon del régimen colonial y construyeron su propia comunidad libre. Hoy se le considera el primer pueblo libre de América y el único palenque que sigue activo en la actualidad. Con cerca de 3.500 habitantes, en su mayoría afrodescendientes, sigue siendo un símbolo esencial de la resistencia y la identidad afrocolombiana.",
		"texture": CARD_TEXTURE,
	},
	{
		"id": "card_02",
		"title": "Patrimonio Cultural de la Humanidad",
		"text": "Desde 2005, la UNESCO reconoce al Palenque de San Basilio como Patrimonio Cultural Inmaterial de la Humanidad. Este reconocimiento honra su lengua criolla propia, su organización social solidaria y su riqueza musical: tres pilares que lo distinguen como un referente único de herencia afrocolombiana en el continente.",
		"texture": CARD_TEXTURE,
	},
	{
		"id": "card_03",
		"title": "La Lengua Palenquera",
		"text": "El Palenque conserva su propia lengua criolla, nacida de la mezcla entre lenguas africanas y el español colonial. Es una de las huellas vivas más valiosas de su historia, pero su uso ha disminuido entre las nuevas generaciones debido a la migración y la globalización, lo que pone en riesgo su transmisión hacia el futuro.",
		"texture": CARD_TEXTURE,
	},
	{
		"id": "card_04",
		"title": "El Origen de la Palabra Cimarrón",
		"text": "La palabra \"cimarrón\" nombraba originalmente al animal doméstico que escapaba de sus amos y se volvía salvaje. Con el tiempo, las personas esclavizadas que huían para fundar comunidades libres adoptaron este término para sí mismas, convirtiéndolo en un símbolo de libertad y resistencia que define hasta hoy la identidad del Palenque.",
		"texture": CARD_TEXTURE,
	},
	{
		"id": "card_05",
		"title": "Trenzas: Mapas Escondidos en el Cabello",
		"text": "Durante la época colonial, las mujeres afrodescendientes usaban los patrones de sus trenzas para codificar rutas de escape hacia los palenques. Cada peinado podía esconder un mapa: una forma de comunicación silenciosa que convertía el propio cuerpo en una herramienta de libertad, mucho antes de que existiera cualquier otro medio seguro para compartir esa información.",
		"texture": CARD_TEXTURE,
	},
	{
		"id": "card_06",
		"title": "La Música del Palenque",
		"text": "La riqueza musical es uno de los pilares por los que la UNESCO reconoció al Palenque como Patrimonio de la Humanidad. La música palenquera no es solo entretenimiento: es memoria viva, una forma de transmitir historia, identidad y comunidad de generación en generación.",
		"texture": CARD_TEXTURE,
	},
	{
		"id": "card_07",
		"title": "Una Identidad Compartida en Colombia",
		"text": "En Colombia, más de 4,6 millones de personas —el 9,34% de la población total— se autorreconocen como negras, afrocolombianas, raizales o palenqueras. El Palenque de San Basilio es uno de los símbolos más importantes de esa identidad compartida: un recordatorio de que su historia de resistencia le pertenece a todo el país, no solo a su propia comunidad.",
		"texture": CARD_TEXTURE,
	},
	{
		"id": "card_08",
		"title": "La Memoria Oral",
		"text": "Gran parte de la historia del Palenque se ha conservado a través de la tradición oral: relatos, enseñanzas y costumbres que pasan de boca en boca entre generaciones. Esta forma de memoria colectiva es también una de las más amenazadas, ya que depende de que alguien esté dispuesto a escuchar y seguir contando lo que escuchó.",
		"texture": CARD_TEXTURE,
	},
	{
		"id": "card_09",
		"title": "Resistir en el Presente",
		"text": "La historia de resistencia del Palenque no terminó en el siglo XVII. En 2006 fue reconocido como zona de desplazamiento forzado por el conflicto armado, y hoy la pobreza en su territorio supera en unos 10 puntos el promedio nacional, lo que empuja a muchos jóvenes a migrar hacia Cartagena y Barranquilla. Cada vez que alguien se va, se debilita un poco más la transmisión de las tradiciones que han mantenido viva a esta comunidad durante siglos.",
		"texture": CARD_TEXTURE,
	},
]

## Ids de las cartas ya obtenidas, en orden de recolección.
static var collected: Array[String] = []


static func total() -> int:
	return CARDS.size()


static func collected_count() -> int:
	return collected.size()


static func is_collected(id: String) -> bool:
	return collected.has(id)


static func get_card(id: String) -> Dictionary:
	for card in CARDS:
		if card.id == id:
			return card
	return {}


## Marca una carta como obtenida. Devuelve true solo si era nueva.
static func collect(id: String) -> bool:
	if id == "" or is_collected(id):
		return false
	collected.append(id)
	return true


## Devuelve la siguiente carta sin obtener (en orden). Si ya están todas,
## devuelve una al azar (para que el nivel siga teniendo una carta que dar).
static func pick_next() -> Dictionary:
	for card in CARDS:
		if not is_collected(card.id):
			return card
	if CARDS.is_empty():
		return {}
	return CARDS[randi() % CARDS.size()]


static func reset() -> void:
	collected.clear()


## Carga una textura de carta. En el editor el PNG puede no estar importado
## todavía, así que se cae al archivo directo como respaldo (funciona igual en
## desarrollo y en export).
static func load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var tex := load(path)
		if tex is Texture2D:
			return tex
	var img := Image.load_from_file(path)
	if img == null:
		return null
	return ImageTexture.create_from_image(img)