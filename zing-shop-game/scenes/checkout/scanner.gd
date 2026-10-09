class_name Scanner
extends Control

## Leitor de código de barras da mesa. Pisca e apita ao registrar um item.

const BODY_COLOR := Color("1c1030")
const IDLE_COLOR := Color("e5484d")
const BEEP_COLOR := Color("46c46e")
const BEEP_TIME := 0.2
const BEEP_FREQUENCY := 1800.0
const BEEP_DURATION := 0.09

var _laser_color := IDLE_COLOR
var _beep_player := AudioStreamPlayer.new()


func _ready() -> void:
	_beep_player.stream = _make_beep_sound()
	_beep_player.volume_db = -8.0
	add_child(_beep_player)


func beep() -> void:
	_beep_player.play()
	_laser_color = BEEP_COLOR
	queue_redraw()
	await get_tree().create_timer(BEEP_TIME).timeout
	_laser_color = IDLE_COLOR
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BODY_COLOR)
	var glass := Rect2(Vector2(10.0, 10.0), size - Vector2(20.0, 20.0))
	draw_rect(glass, _laser_color.darkened(0.7))
	var center := glass.get_center()
	var half := glass.size * 0.45
	draw_line(center - Vector2(half.x, 0.0), center + Vector2(half.x, 0.0), _laser_color, 3.0)
	draw_line(center - half, center + half, _laser_color, 2.0)
	draw_line(center + Vector2(-half.x, half.y), center + Vector2(half.x, -half.y), _laser_color, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(0.0, size.y + 18.0), "SCANNER",
		HORIZONTAL_ALIGNMENT_CENTER, size.x, 14, Color.WHITE)


## Bipe gerado por código, para não depender de arquivo de áudio por enquanto.
func _make_beep_sound() -> AudioStreamWAV:
	var mix_rate := 22050
	var sample_count := int(mix_rate * BEEP_DURATION)
	var samples := PackedByteArray()
	samples.resize(sample_count * 2)
	for i in sample_count:
		var value := sin(TAU * BEEP_FREQUENCY * i / mix_rate) * 0.4
		samples.encode_s16(i * 2, int(value * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = mix_rate
	stream.data = samples
	return stream
