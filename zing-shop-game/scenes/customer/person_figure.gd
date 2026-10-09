@tool
class_name PersonFigure
extends Control

## Boneco provisório desenhado por código, até termos sprites de clientes.

enum Mood { NEUTRAL, HAPPY, ANGRY }

const SKIN_COLOR := Color("f2c4a0")
const OUTLINE_COLOR := Color("1c1030")

@export var body_color: Color = Color("8f6ae6"):
	set(value):
		body_color = value
		queue_redraw()
@export var mood: Mood = Mood.NEUTRAL:
	set(value):
		mood = value
		queue_redraw()


func _draw() -> void:
	var line_width := maxf(size.x * 0.02, 1.5)
	var r := size.x * 0.24
	var head := Vector2(size.x * 0.5, r + 2.0)
	var body_top := head.y + r * 0.8
	var body := Rect2(size.x * 0.12, body_top, size.x * 0.76, size.y - body_top)

	draw_rect(body, body_color)
	draw_rect(body, OUTLINE_COLOR, false, line_width)
	draw_circle(head, r, SKIN_COLOR)
	draw_arc(head, r, 0.0, TAU, 32, OUTLINE_COLOR, line_width)

	var eye_radius := maxf(r * 0.1, 1.5)
	draw_circle(head + Vector2(-0.38, -0.1) * r, eye_radius, OUTLINE_COLOR)
	draw_circle(head + Vector2(0.38, -0.1) * r, eye_radius, OUTLINE_COLOR)

	match mood:
		Mood.HAPPY:
			draw_arc(head + Vector2(0.0, 0.2) * r, r * 0.35, 0.3, PI - 0.3, 12, OUTLINE_COLOR, line_width)
		Mood.ANGRY:
			draw_arc(head + Vector2(0.0, 0.75) * r, r * 0.3, PI + 0.4, TAU - 0.4, 12, OUTLINE_COLOR, line_width)
			draw_line(head + Vector2(-0.6, -0.45) * r, head + Vector2(-0.18, -0.25) * r, OUTLINE_COLOR, line_width)
			draw_line(head + Vector2(0.6, -0.45) * r, head + Vector2(0.18, -0.25) * r, OUTLINE_COLOR, line_width)
		_:
			draw_line(head + Vector2(-0.25, 0.45) * r, head + Vector2(0.25, 0.45) * r, OUTLINE_COLOR, line_width)
