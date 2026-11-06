class_name CustomerData
extends Resource

## Um cliente: quem é, o que compra, como paga, o que diz e que problemas ele tem.
## Cada cliente fica no seu próprio arquivo em data/customers/ e é usado pelos dias.

enum PaymentMethod { CARD, CASH }
## Problemas que um cliente pode ter. O dia decide quais deles o jogador deve barrar
## (ver DayData.active_rules).
enum Problem { FAKE_ID, HIDDEN_ITEM }

@export var display_name: String = ""
@export_multiline var greeting: String = "Boa tarde!"
## Cor da roupa do boneco provisório, até termos sprites de clientes.
@export var body_color: Color = Color("8f6ae6")
## Sprite do cliente. Quando definido, substitui o boneco provisório.
@export var portrait: Texture2D
@export var items: Array[ItemData] = []

@export_group("Pagamento")
@export var payment_method: PaymentMethod = PaymentMethod.CARD
## Quanto o cliente entrega em dinheiro, em centavos. Ignorado no cartão.
@export var cash_given_cents: int = 0

@export_group("Tempo")
## Segundos que o cliente aguenta no caixa antes de desistir (multiplicado pela
## paciência do dia, ver DayData.patience_multiplier).
@export var patience_seconds: float = 60.0

@export_group("Voz")
## Blips tocados enquanto a fala é digitada no balão. Sem voz, o cliente fala em silêncio.
@export var voice: BlipVoice
## Multiplica o tom da voz, para clientes com a mesma voz soarem diferentes.
@export_range(0.5, 2.0, 0.05) var voice_pitch: float = 1.0

@export_group("Inspeção")
## Documento que o cliente mostra. Sem documento, nada é mostrado.
@export var id_card: IdentityData
## Se o cliente já entrega o documento ao chegar. Senão, o jogador precisa pedir.
@export var hands_over_id: bool = true
## Perguntas que o jogador pode fazer a este cliente.
@export var questions: Array[Question] = []
## Problemas reais deste cliente. O jogador só descobre investigando.
@export var problems: Array[Problem] = []


func get_total_cents() -> int:
	var total := 0
	for item in items:
		total += item.price_cents
	return total


func buys_alcohol() -> bool:
	for item in items:
		if item.is_alcoholic:
			return true
	return false


## O cliente tem algum problema que as regras do dia mandam barrar?
func has_violation(active_rules: Array[Problem]) -> bool:
	for problem in problems:
		if problem in active_rules:
			return true
	return false
