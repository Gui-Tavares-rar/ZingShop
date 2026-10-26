class_name CustomerQueue
extends RefCounted

## Fila do dia: cada cliente chega no seu horário e espera a vez de ser atendido.

## Alguém entrou ou saiu da fila.
signal changed

## Clientes esperando, o primeiro é o próximo a ser atendido.
var waiting: Array[CustomerData] = []

## Clientes que ainda não chegaram, em ordem de chegada.
var _arrivals: Array[CustomerData] = []
var _clock := 0.0


func _init(customers: Array[CustomerData]) -> void:
	_arrivals = customers.duplicate()
	_arrivals.sort_custom(func(a: CustomerData, b: CustomerData) -> bool: return a.arrival_time < b.arrival_time)


## Avança o relógio do dia e coloca na fila quem já chegou.
func advance(delta: float) -> void:
	_clock += delta
	var arrived := false
	while not _arrivals.is_empty() and _arrivals[0].arrival_time <= _clock:
		waiting.append(_arrivals.pop_front())
		arrived = true
	if arrived:
		changed.emit()


func has_waiting() -> bool:
	return not waiting.is_empty()


## Tira o primeiro da fila para ser atendido.
func next() -> CustomerData:
	var customer: CustomerData = waiting.pop_front()
	changed.emit()
	return customer


## Ninguém está esperando e ninguém mais vai chegar.
func is_finished() -> bool:
	return _arrivals.is_empty() and waiting.is_empty()
