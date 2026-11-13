class_name GameSession
extends RefCounted

## Guarda em que dia da semana o jogador está, para a cena do dia poder ser recarregada.
## Também lembra, entre uma vez e outra que o jogo é aberto, se o Prólogo já foi concluído.

const SAVE_PATH := "user://progresso.cfg"
const SAVE_SECTION := "progresso"
const SAVE_PROLOGUE_KEY := "prologo_concluido"

static var _current_day: DayData
## Dinheiro ganho nos dias já terminados desta semana.
static var banked_cents := 0
## O próximo jogo começa direto no dia depois do Prólogo. O menu liga isso antes de começar.
static var skip_prologue := false


## Chamada pela cena do dia ao abrir: devolve o dia que deve ser jogado.
## Na primeira vez usa o dia configurado na cena (o Prólogo), ou o seguinte se for para pular.
static func start(configured_day: DayData) -> DayData:
	if _current_day == null:
		_current_day = configured_day
		if skip_prologue and configured_day.tutorial and configured_day.next_day:
			_current_day = configured_day.next_day
	return _current_day


## Fim do dia: guarda o ganho e segue para o próximo. No último dia da semana, quem chama usa reset().
static func finish(played_day: DayData, earnings_cents: int) -> void:
	banked_cents += earnings_cents
	_current_day = played_day.next_day


## Novo jogo: esquece o progresso da semana e volta ao dia configurado na cena.
static func reset() -> void:
	banked_cents = 0
	_current_day = null
	skip_prologue = false


## O jogador já terminou o Prólogo alguma vez (fica salvo no computador).
static func is_prologue_done() -> bool:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return false
	return config.get_value(SAVE_SECTION, SAVE_PROLOGUE_KEY, false)


static func mark_prologue_done() -> void:
	var config := ConfigFile.new()
	config.load(SAVE_PATH)
	config.set_value(SAVE_SECTION, SAVE_PROLOGUE_KEY, true)
	config.save(SAVE_PATH)
