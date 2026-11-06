class_name GameSession
extends RefCounted

## Guarda em que dia da semana o jogador está, para a cena do dia poder ser recarregada.

static var _current_day: DayData


## Chamada pela cena do dia ao abrir: devolve o dia que deve ser jogado.
## Na primeira vez usa o dia configurado na cena.
static func start(configured_day: DayData) -> DayData:
	if _current_day == null:
		_current_day = configured_day
	return _current_day


## Fim do dia: segue para o próximo. No último dia da semana, quem chama usa reset().
static func finish(played_day: DayData) -> void:
	_current_day = played_day.next_day


## Novo jogo: esquece o progresso e volta ao dia configurado na cena.
static func reset() -> void:
	_current_day = null
