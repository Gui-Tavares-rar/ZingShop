class_name CustomerData
extends Resource

## Um cliente do dia: o que ele compra, como paga e quanto tempo aguenta esperar.

enum PaymentMethod { CARD, CASH }

@export var display_name: String = ""
@export_multiline var greeting: String = "Boa tarde!"
## Cor da roupa do boneco provisório, até termos sprites de clientes.
@export var body_color: Color = Color("8f6ae6")
@export var items: Array[ItemData] = []

@export_group("Pagamento")
@export var payment_method: PaymentMethod = PaymentMethod.CARD
## Quanto o cliente entrega em dinheiro, em centavos. Ignorado no cartão.
@export var cash_given_cents: int = 0

@export_group("Tempo")
## Segundos desde o início do dia em que o cliente entra na fila.
@export var arrival_time: float = 0.0
## Segundos que o cliente aguenta no caixa antes de desistir.
@export var patience_seconds: float = 60.0


func get_total_cents() -> int:
	var total := 0
	for item in items:
		total += item.price_cents
	return total
