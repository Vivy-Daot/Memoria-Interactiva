extends CanvasLayer

## Panel de opciones simple (pantalla completa + volumen maestro). Se abre desde
## el menú principal con el botón "Opciones".

const BUS_MASTER := 0

@onready var fullscreen_check: CheckButton = $Dim/Center/Panel/VBox/Fullscreen
@onready var volume_slider: HSlider = $Dim/Center/Panel/VBox/VolRow/Volume
@onready var close_button: Button = $Dim/Center/Panel/VBox/Close


func _ready() -> void:
	visible = false
	fullscreen_check.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	volume_slider.value_changed.connect(_on_volume_changed)
	close_button.pressed.connect(close)
	# Refleja el volumen maestro actual en el slider.
	volume_slider.value = clampf(db_to_linear(AudioServer.get_bus_volume_db(BUS_MASTER)) * 100.0, 0.0, 100.0)


func open() -> void:
	visible = true


func close() -> void:
	visible = false


func toggle() -> void:
	visible = not visible


func _on_fullscreen_toggled(pressed: bool) -> void:
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if pressed else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)


func _on_volume_changed(value: float) -> void:
	AudioServer.set_bus_mute(BUS_MASTER, value <= 0.0)
	if value > 0.0:
		AudioServer.set_bus_volume_db(BUS_MASTER, linear_to_db(value / 100.0))