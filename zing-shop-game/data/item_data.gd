class_name ItemData
extends Resource

## Produto vendido no mercado.

@export var display_name: String = ""
## Preço em centavos (ex.: 1075 = R$ 10,75).
@export var price_cents: int = 0
@export var texture: Texture2D
## Só pode ser vendida a maiores de 18 anos (ver DayData.verify_age_for_alcohol).
@export var is_alcoholic: bool = false
