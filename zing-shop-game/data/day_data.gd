class_name DayData
extends Resource

## Configuração de um dia de expediente (uma fase).

@export var day_number: int = 1
@export var customers: Array[CustomerData] = []

@export_group("Economia")
## Fração do valor de cada venda que vira comissão para o jogador.
@export_range(0.0, 1.0, 0.01) var commission_rate: float = 0.1
## Desconto no ganho do dia ao errar o troco, em centavos.
@export var wrong_change_penalty_cents: int = 500

@export_group("Banheiro")
## Quanto o medidor do banheiro sobe (de 0 a 100) ao errar o troco.
@export_range(0.0, 100.0) var wrong_change_bathroom: float = 35.0
## Quanto o medidor do banheiro sobe quando um cliente desiste de esperar.
@export_range(0.0, 100.0) var timeout_bathroom: float = 40.0
## Velocidade da perda de paciência dos clientes enquanto o jogador lava o banheiro.
@export_range(0.0, 1.0, 0.05) var bathroom_patience_multiplier: float = 0.5
