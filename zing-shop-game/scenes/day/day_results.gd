class_name DayResults
extends RefCounted

## Placar de um dia: quem foi atendido, quem desistiu, quanto o jogador ganhou e por que perdeu.

var served := 0
var lost := 0
## Clientes barrados pelo segurança.
var removed := 0
var commission_cents := 0
var penalty_cents := 0

## Descontos por motivo: motivo -> {count, cents}.
var _penalties: Dictionary = {}


func add_sale(total_cents: int, commission_rate: float) -> void:
	served += 1
	commission_cents += roundi(total_cents * commission_rate)


func add_lost_customer() -> void:
	lost += 1


func add_removed_customer() -> void:
	removed += 1


func add_penalty(cents: int, reason: String) -> void:
	penalty_cents += cents
	var entry: Dictionary = _penalties.get(reason, {"count": 0, "cents": 0})
	entry.count += 1
	entry.cents += cents
	_penalties[reason] = entry


func earnings_cents() -> int:
	return commission_cents - penalty_cents


func summary_lines(customer_count: int) -> PackedStringArray:
	var lines := PackedStringArray([
		"Clientes atendidos: %d de %d" % [served, customer_count],
		"Foram embora: %d" % lost,
		"Barrados pelo segurança: %d" % removed,
		"",
		"Comissões: %s" % Money.format(commission_cents),
	])
	for reason: String in _penalties:
		var entry: Dictionary = _penalties[reason]
		lines.append("%s (%d×): %s" % [reason, entry.count, Money.format(-entry.cents)])
	lines.append("")
	lines.append("Ganho do dia: %s" % Money.format(earnings_cents()))
	return lines
