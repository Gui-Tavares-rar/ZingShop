class_name Hud
extends PanelContainer

## Barra do topo: dia, clientes atendidos, ganho do dia, progresso da meta e medidor do banheiro.

@onready var _day_label: Label = %DayLabel
@onready var _served_label: Label = %ServedLabel
@onready var _earnings_label: Label = %EarningsLabel
@onready var _week_label: Label = %WeekLabel
@onready var _bathroom_bar: ProgressBar = %BathroomBar


func refresh(day_number: int, served: int, customer_count: int, earnings_cents: int, week_cents: int, goal_cents: int, bathroom_meter: float) -> void:
	_day_label.text = "Dia %d" % day_number
	_served_label.text = "Atendidos: %d/%d" % [served, customer_count]
	_earnings_label.text = "Ganho do dia: " + Money.format(earnings_cents)
	_week_label.text = "Meta da semana: %s / %s" % [Money.format(week_cents), Money.format(goal_cents)]
	_bathroom_bar.value = bathroom_meter
