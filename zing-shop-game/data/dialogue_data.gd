class_name DialogueData
extends Resource

## Falas fixas do jogo: reações dos clientes e recados do chefe. Cada situação tem uma lista de
## variações e o jogo sorteia uma. Dentro do texto, {nome} é trocado pelo valor da situação
## (por exemplo {penalty} vira "R$ 5,00"). Deixe a lista vazia para ficar em silêncio.
## As falas particulares de cada cliente (saudação e perguntas) ficam em data/customers/.

@export_group("Cliente")
## Entrega o documento depois de o jogador pedir.
@export var customer_hands_id: Array[String] = []
## É levado pelo segurança.
@export var customer_removed: Array[String] = []
## Vai pagar no cartão.
@export var customer_pays_card: Array[String] = []
## Vai pagar em dinheiro. {cash} = valor entregue.
@export var customer_pays_cash: Array[String] = []
## Agradece depois de pagar no cartão.
@export var customer_thanks_card: Array[String] = []
## Agradece depois de receber o troco certo.
@export var customer_thanks_cash: Array[String] = []
## Recebeu troco a menos.
@export var customer_change_short: Array[String] = []
## Recebeu troco a mais (ou errado).
@export var customer_change_wrong: Array[String] = []
## Perdeu a paciência e foi embora.
@export var customer_gives_up: Array[String] = []

@export_group("Chefe")
## Abre o dia. {day} = número do dia.
@export var boss_day_start: Array[String] = []
## O jogador atendeu quem devia ter barrado. {penalty} = desconto.
@export var boss_served_should_bar: Array[String] = []
## O jogador barrou quem estava certo. {penalty} = desconto.
@export var boss_barred_wrongly: Array[String] = []
## O jogador barrou quem devia.
@export var boss_praise_barred: Array[String] = []
## Troco errado. {expected} = troco certo, {given} = troco dado, {penalty} = desconto.
@export var boss_wrong_change: Array[String] = []
## O cliente foi embora sem pagar.
@export var boss_customer_left: Array[String] = []
## O medidor lotou e o jogador vai para o banheiro (vai no fim do recado).
@export var boss_bathroom_start: Array[String] = []
## O banheiro ficou limpo.
@export var boss_bathroom_done: Array[String] = []


## Sorteia uma variação da lista e troca os {nome} pelos valores dados.
## Lista vazia devolve texto vazio.
func pick(lines: Array[String], values: Dictionary = {}) -> String:
	if lines.is_empty():
		return ""
	return lines[randi() % lines.size()].format(values)
