class_name IdentityData
extends Resource

## Carteira de identidade que o cliente entrega na inspeção: nome, data de nascimento e foto.
## O jogador confere a foto com o rosto do cliente. Um documento falso mostra a foto de outra
## pessoa; isso é marcado em CustomerData.problems.

@export var holder_name: String = ""
@export_range(1, 31) var birth_day: int = 1
@export_range(1, 12) var birth_month: int = 1
@export var birth_year: int = 1990
## Quem aparece na foto. Vazio = o próprio dono do documento. Num documento falso,
## aponte para outro cliente.
@export var photo_of: CustomerData


## Idade completa na data dada.
func age_on(year: int, month: int, day: int) -> int:
	var age := year - birth_year
	if month < birth_month or (month == birth_month and day < birth_day):
		age -= 1
	return age


## Ex.: "05/03/1990".
func birth_text() -> String:
	return "%02d/%02d/%d" % [birth_day, birth_month, birth_year]
