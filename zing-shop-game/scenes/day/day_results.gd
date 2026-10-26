class_name DayResults
extends RefCounted

## Placar de um dia: quem foi atendido, quem desistiu e quanto o jogador ganhou.

var served := 0
var lost := 0
var commission_cents := 0
var penalty_cents := 0


func add_sale(total_cents: int, commission_rate: float) -> void:
	served += 1
	commission_cents += roundi(total_cents * commission_rate)


func add_lost_customer() -> void:
	lost += 1


func add_penalty(cents: int) -> void:
	penalty_cents += cents


func earnings_cents() -> int:
	return commission_cents - penalty_cents


func summary_lines(customer_count: int) -> PackedStringArray:
	return PackedStringArray([
		"Clientes atendidos: %d de %d" % [served, customer_count],
		"Foram embora: %d" % lost,
		"Comissões: %s" % Money.format(commission_cents),
		"Descontos do chefe: %s" % Money.format(-penalty_cents),
		"",
		"Ganho do dia: %s" % Money.format(earnings_cents()),
	])
