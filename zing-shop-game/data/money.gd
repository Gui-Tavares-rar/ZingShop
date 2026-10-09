class_name Money
extends RefCounted

## Utilitários de dinheiro. Todos os valores são inteiros em centavos,
## para o troco nunca sofrer erro de arredondamento.

const COINS: Array[int] = [1, 10, 25, 50, 100]
const BILLS: Array[int] = [200, 500, 1000, 2000, 5000, 10000]

const _COLORS := {
	1: Color("c97b4a"),
	10: Color("d9b44a"),
	25: Color("e0c25a"),
	50: Color("c8c8d0"),
	100: Color("e6d27a"),
	200: Color("7fa8c9"),
	500: Color("b48ad1"),
	1000: Color("e0846f"),
	2000: Color("f2c14e"),
	5000: Color("d9955a"),
	10000: Color("5aa3d9"),
}


## Ex.: 1075 -> "R$ 10,75".
static func format(cents: int) -> String:
	var prefix := "-R$ " if cents < 0 else "R$ "
	var value := absi(cents)
	@warning_ignore("integer_division")
	return "%s%d,%02d" % [prefix, value / 100, value % 100]


## Rótulo curto para moedas e notas. Ex.: 25 -> "R$ 0,25", 500 -> "R$ 5".
static func format_short(cents: int) -> String:
	if cents % 100 == 0:
		@warning_ignore("integer_division")
		return "R$ %d" % (cents / 100)
	return format(cents)


static func is_coin(cents: int) -> bool:
	return cents in COINS


static func color_of(cents: int) -> Color:
	return _COLORS.get(cents, Color.WHITE)
