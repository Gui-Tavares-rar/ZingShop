class_name DayData
extends Resource

## Configuração de um dia de expediente (uma fase).

@export var day_number: int = 1
## Nome do dia no HUD e no resumo. Vazio mostra "Dia N".
@export var title: String = ""
## Dia de treinamento (o Prólogo): o chefe guia o jogador passo a passo (ver Tutorial).
## Ninguém perde a paciência, erros não descontam do salário e o ganho não conta para a meta.
@export var tutorial: bool = false
## Data do dia no jogo; o jogador usa para calcular a idade nos documentos.
@export var date_year: int = 2026
@export_range(1, 12) var date_month: int = 3
@export_range(1, 31) var date_day: int = 16
## Quem aparece no dia e quando. Os clientes ficam em data/customers/.
@export var arrivals: Array[CustomerArrival] = []
## Dia que começa depois deste. Vazio no último dia da semana.
@export var next_day: DayData

@export_group("Economia")
## Fração do valor de cada venda que vira comissão para o jogador.
@export_range(0.0, 1.0, 0.01) var commission_rate: float = 0.25
## Desconto no ganho do dia ao errar o troco, em centavos.
@export var wrong_change_penalty_cents: int = 300
## Meta de dinheiro da semana (o aluguel), em centavos. Vale no último dia: quem junta isso ou
## mais, somando todos os dias, vence; senão, perde.
@export var week_goal_cents: int = 8000

@export_group("Tempo")
## Multiplica a paciência de todos os clientes do dia. Abaixo de 1 os clientes desistem
## mais rápido; acima de 1, aguentam mais.
@export_range(0.25, 3.0, 0.05) var patience_multiplier: float = 1.0

@export_group("Inspeção")
## Liga a fase de inspeção: antes de escanear, o jogador conversa com o cliente,
## vê o documento e decide entre atender ou chamar o segurança.
@export var inspection_enabled: bool = false
## Problemas que o jogador deve barrar neste dia. Um cliente com qualquer um deles
## deve ser barrado; os outros devem ser atendidos.
@export var active_rules: Array[CustomerData.Problem] = []
## Quem compra bebida alcoólica precisa ter 18 anos ou mais. O jogador pede o documento se o
## cliente não entregou; menor de idade deve ser barrado.
@export var verify_age_for_alcohol: bool = false
## Desconto no ganho do dia ao decidir errado, em centavos.
@export var wrong_decision_penalty_cents: int = 500
## Quanto o medidor do banheiro sobe (de 0 a 100) ao decidir errado.
@export_range(0.0, 100.0) var wrong_decision_bathroom: float = 35.0

@export_group("Banheiro")
## Quanto o medidor do banheiro sobe (de 0 a 100) ao errar o troco.
@export_range(0.0, 100.0) var wrong_change_bathroom: float = 35.0
## Quanto o medidor do banheiro sobe quando um cliente desiste de esperar.
@export_range(0.0, 100.0) var timeout_bathroom: float = 40.0
## Velocidade da perda de paciência dos clientes enquanto o jogador lava o banheiro.
@export_range(0.0, 1.0, 0.05) var bathroom_patience_multiplier: float = 0.5


## O cliente deve ser barrado hoje? Tem um problema das regras do dia, ou é menor comprando álcool.
func should_bar(customer: CustomerData) -> bool:
	if customer.has_violation(active_rules):
		return true
	return verify_age_for_alcohol and customer.buys_alcohol() and customer.id_card != null \
		and customer.id_card.age_on(date_year, date_month, date_day) < 18


## Segundos que o cliente aguenta no caixa neste dia.
func patience_for(customer: CustomerData) -> float:
	return customer.patience_seconds * patience_multiplier


## A meta da semana, que fica configurada no último dia da sequência.
func week_goal() -> int:
	var last := self
	var guard := 0
	while last.next_day != null and guard < 100:
		last = last.next_day
		guard += 1
	return last.week_goal_cents


## Ex.: "Prólogo" ou "Dia 1".
func display_title() -> String:
	return title if not title.is_empty() else "Dia %d" % day_number


func today_text() -> String:
	return "%02d/%02d/%d" % [date_day, date_month, date_year]


func customer_count() -> int:
	return arrivals.size()
