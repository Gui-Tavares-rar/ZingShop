class_name QueueView
extends HBoxContainer

## Bonecos dos clientes esperando na fila.

const FIGURE_SIZE := Vector2(52.0, 116.0)


func show_customers(customers: Array[CustomerData]) -> void:
	for figure in get_children():
		remove_child(figure)
		figure.queue_free()
	# A fila cresce para a esquerda: o primeiro da fila fica mais perto do caixa.
	for i in range(customers.size() - 1, -1, -1):
		var figure := PersonFigure.new()
		figure.body_color = customers[i].body_color
		figure.custom_minimum_size = FIGURE_SIZE
		figure.size_flags_vertical = Control.SIZE_SHRINK_END
		figure.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(figure)
