class_name CustomerArrival
extends Resource

## Um cliente chegando num dia: quem é e quando entra na fila.
## Separa o horário do cliente, que muda de dia para dia, para o mesmo cliente
## poder aparecer em vários dias.

@export var customer: CustomerData
## Segundos desde o início do dia em que o cliente entra na fila.
@export var arrival_time: float = 0.0
