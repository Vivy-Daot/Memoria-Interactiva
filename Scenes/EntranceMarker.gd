extends Sprite2D

## Removes only the exterior black background from the generated lantern,
## preserving its dark pixel-art outline.
func _ready() -> void:
	if texture == null:
		return
	var image: Image = texture.get_image()
	if image == null or image.is_empty():
		return
	var width: int = image.get_width()
	var height: int = image.get_height()
	var visited := PackedByteArray()
	visited.resize(width * height)
	var pending: Array[Vector2i] = []
	for x in range(width):
		pending.append(Vector2i(x, 0))
		pending.append(Vector2i(x, height - 1))
	for y in range(1, height - 1):
		pending.append(Vector2i(0, y))
		pending.append(Vector2i(width - 1, y))
	while not pending.is_empty():
		var point: Vector2i = pending.pop_back()
		var index: int = point.y * width + point.x
		if visited[index] != 0:
			continue
		visited[index] = 1
		var pixel: Color = image.get_pixelv(point)
		if pixel.r > 0.02 or pixel.g > 0.02 or pixel.b > 0.02:
			continue
		image.set_pixelv(point, Color(0.0, 0.0, 0.0, 0.0))
		if point.x > 0:
			pending.append(Vector2i(point.x - 1, point.y))
		if point.x < width - 1:
			pending.append(Vector2i(point.x + 1, point.y))
		if point.y > 0:
			pending.append(Vector2i(point.x, point.y - 1))
		if point.y < height - 1:
			pending.append(Vector2i(point.x, point.y + 1))
	texture = ImageTexture.create_from_image(image)
