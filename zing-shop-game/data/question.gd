class_name Question
extends Resource

## Uma pergunta que o jogador pode fazer ao cliente na inspeção, e a resposta dele.

## Texto do botão que o jogador clica.
@export var prompt: String = ""
## O que o cliente responde. É aqui que ficam as pistas (nervosismo, contradições).
@export_multiline var answer: String = ""
