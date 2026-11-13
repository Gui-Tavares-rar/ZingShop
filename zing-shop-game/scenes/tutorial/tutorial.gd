class_name Tutorial
extends Control

## Treinamento guiado do Prólogo. O chefe explica o jogo passo a passo, destacando a parte da tela
## de que está falando, e só segue quando o jogador faz o que foi pedido. Substitui o antigo texto
## "Como jogar" do menu.
##
## O roteiro inteiro está em _run(), na ordem em que acontece. Há dois tipos de passo:
## - _explain(): o chefe fala e espera o botão "Continuar". O resto da tela fica bloqueado.
## - _instruct(): o chefe pede uma ação e a tela fica livre; quem chama espera o sinal dessa ação.
##
## Os clientes do Prólogo ficam em data/customers/prologo_*.tres, na ordem de data/days/prologue.tres.
## Se trocar os clientes, confira se o roteiro ainda bate com eles (pagamento, documento, problemas).

const DIM_EXPLAIN := Color(0.0, 0.0, 0.0, 0.55)
const DIM_INSTRUCT := Color(0.0, 0.0, 0.0, 0.3)
const FRAME_COLOR := Color("ff6fa8")
const FRAME_MARGIN := 6.0
const FRAME_WIDTH := 3.0
## Tempo para o cliente terminar uma fala antes do próximo passo.
const SPEECH_WAIT := 1.6

var _main: Control
var _day: DayData
## O Main só chama o próximo cliente quando isto está ligado (ver wants_customer).
var _customer_allowed := false
var _finished := false
## Partes da tela destacadas no passo atual.
var _targets: Array[Control] = []
var _dim_color := Color.TRANSPARENT
var _pulse := 0.0

# Partes do jogo que o roteiro aponta. Preenchidas em begin().
var _inspection: InspectionPanel
var _checkout: Checkout
var _customer_view: CustomerView
var _hud: Hud
var _bathroom: Bathroom

@onready var _blocker: Control = %Blocker
@onready var _coach: PanelContainer = %Coach
@onready var _coach_text: RichTextLabel = %CoachText
@onready var _continue_button: Button = %ContinueButton


func _ready() -> void:
	_blocker.hide()
	_coach.hide()


## Começa o treinamento. `main` é a cena do dia (scenes/main.tscn).
func begin(main: Control, day: DayData) -> void:
	_main = main
	_day = day
	_inspection = main.get_node("%InspectionPanel")
	_checkout = main.get_node("%Checkout")
	_customer_view = main.get_node("%CustomerView")
	_hud = main.get_node("%HUD")
	_bathroom = main.get_node("%Bathroom")
	_checkout.change_rejected.connect(_on_change_rejected)
	_run()


## O Main pergunta isto antes de chamar o próximo cliente da fila.
func wants_customer() -> bool:
	return _customer_allowed


## O roteiro acabou e o dia pode terminar.
func is_finished() -> bool:
	return _finished


func _process(delta: float) -> void:
	if _targets.is_empty() and _dim_color.a == 0.0:
		return
	_pulse += delta
	queue_redraw()


## Escurece a tela fora das partes destacadas e desenha uma moldura piscando em cada uma.
func _draw() -> void:
	var visible_targets := _targets.filter(func(t: Control) -> bool: return is_instance_valid(t) and t.is_visible_in_tree())
	if _dim_color.a > 0.0:
		var hole := Rect2()
		for target: Control in visible_targets:
			var rect := _local_rect(target)
			hole = rect if hole.has_area() == false else hole.merge(rect)
		_draw_dim_around(hole)
	var alpha := 0.6 + 0.4 * sin(_pulse * 6.0)
	for target: Control in visible_targets:
		draw_rect(_local_rect(target), Color(FRAME_COLOR, alpha), false, FRAME_WIDTH)


func _draw_dim_around(hole: Rect2) -> void:
	var screen := Rect2(Vector2.ZERO, size)
	if not hole.has_area():
		draw_rect(screen, _dim_color)
		return
	hole = hole.intersection(screen)
	draw_rect(Rect2(0.0, 0.0, size.x, hole.position.y), _dim_color)
	draw_rect(Rect2(0.0, hole.end.y, size.x, size.y - hole.end.y), _dim_color)
	draw_rect(Rect2(0.0, hole.position.y, hole.position.x, hole.size.y), _dim_color)
	draw_rect(Rect2(hole.end.x, hole.position.y, size.x - hole.end.x, hole.size.y), _dim_color)


func _local_rect(target: Control) -> Rect2:
	var rect := target.get_global_rect()
	rect.position -= global_position
	return rect.grow(FRAME_MARGIN)


# --- Roteiro ---------------------------------------------------------------------------------

func _run() -> void:
	await _explain("Bem-vindo ao [b]Zing Shop[/b]! Eu sou o seu chefe e hoje é o seu primeiro dia no caixa.\n\nVou te ensinar tudo com clientes de verdade. Fica tranquilo: hoje é treino, ninguém vai embora e nada sai do seu salário.")
	await _explain("Aqui em cima fica o resumo do dia: quantos clientes você atendeu e quanto já ganhou. Cada venda te dá uma [b]comissão[/b].", [_hud])

	await _teach_card_sale()
	await _teach_cash_sale()
	await _teach_fake_document()
	await _teach_underage_alcohol()
	await _teach_bathroom()

	await _explain("Duas teclas pra lembrar:\n\n[b]P[/b] pausa e continua o jogo.\n[b]M[/b] volta para o menu (e a semana recomeça).")
	await _explain("Pronto, você está contratado!\n\nA partir de amanhã é pra valer: os clientes perdem a paciência e cada erro sai do seu salário. Junte [b]%s[/b] até o fim da semana para pagar o aluguel. Boa sorte!" % Money.format(_day.week_goal()))
	_hide_coach()
	_finished = true


## Cliente 1 (Dona Cida): documento certo, paga no cartão. Ensina paciência, inspeção, scanner,
## cobrar e maquininha.
func _teach_card_sale() -> void:
	await _call_customer()
	await _explain("Chegou o seu primeiro cliente!\n\nA barra em cima dele é a [b]paciência[/b]. Se ela zerar, o cliente vai embora sem pagar. Hoje ela não desce, mas a partir de amanhã, seja rápido!",
		[_part(_customer_view, "PatienceBar")])
	await _explain("Antes de passar as compras, você confere o [b]documento[/b] do cliente.\n\nCompare a [b]foto[/b] do documento com o [b]rosto[/b] do cliente. Aqui está tudo certo: é ela mesma.",
		[_part(_inspection, "Document"), _customer_view])
	await _explain("Aqui aparecem as compras do cliente e a [b]data de hoje[/b]. Você vai usar a data para calcular a idade de quem compra bebida alcoólica.",
		[_part(_inspection, "DocumentTitle"), _part(_inspection, "CartLabel")])
	await _decide("Está tudo certo com ela. Clique em [b]Atender[/b].",
		[_part(_inspection, "ServeButton")], _hint_customer_is_fine())

	_instruct("Ela colocou as compras na mesa.\n\n[b]Arraste[/b] cada item com o botão esquerdo do mouse até o [b]scanner[/b]. Quando ele apitar, solte o item: ele vai para a sacola.",
		[_part(_checkout, "ItemLandingArea"), _part(_checkout, "Scanner"), _part(_checkout, "Bag")])
	await _checkout.all_items_scanned
	_instruct("Tudo registrado! Agora clique em [b]Cobrar[/b] no monitor.",
		[_part(_part(_checkout, "Monitor"), "ChargeButton")])
	await _checkout.payment_started
	_instruct("Ela vai pagar no [b]cartão[/b]. É o mais fácil: clique na [b]maquininha[/b].",
		[_part(_checkout, "CardMachine")])
	await _checkout.sale_finished
	await _explain("Primeira venda feita! Olha a sua comissão aqui em cima.",
		[_part(_hud, "EarningsLabel")])


## Cliente 2 (Seu Valdir): não entrega o documento, paga em dinheiro. Ensina pedir documento,
## perguntas e troco.
func _teach_cash_sale() -> void:
	var customer := await _call_customer()
	_instruct("Esse cliente não entregou o documento. Clique em [b]Pedir documento[/b].",
		[_part(_inspection, "RequestButton")])
	await _inspection.document_requested
	await _wait(SPEECH_WAIT)
	await _explain("Foto e rosto batem. Tudo certo com o documento.",
		[_part(_inspection, "Document"), _customer_view])
	_instruct("Você também pode fazer [b]perguntas[/b] ao cliente. Às vezes as respostas entregam quem está mentindo.\n\nClique numa pergunta.",
		[_part(_inspection, "Questions")])
	await _inspection.question_asked
	await _wait(SPEECH_WAIT * 1.5)
	await _decide("Nada de estranho. Clique em [b]Atender[/b].",
		[_part(_inspection, "ServeButton")], _hint_customer_is_fine())

	_instruct("Agora é com você: escaneie todos os itens e clique em [b]Cobrar[/b].",
		[_part(_checkout, "ItemLandingArea"), _part(_checkout, "Scanner"), _part(_checkout, "Bag"),
			_part(_part(_checkout, "Monitor"), "ChargeButton")])
	await _checkout.payment_started
	var change := customer.cash_given_cents - customer.get_total_cents()
	await _explain("Ele vai pagar em [b]dinheiro[/b]. O monitor mostra o [b]TOTAL[/b] e quanto você [b]RECEBEU[/b].\n\nTroco = recebido − total\n%s − %s = [b]%s[/b]" % [
			Money.format(customer.cash_given_cents), Money.format(customer.get_total_cents()), Money.format(change)],
		[_part(_checkout, "Monitor")])
	_instruct("Monte o troco de [b]%s[/b]:\n\n• Na gaveta, [b]segure[/b] uma nota ou moeda.\n• Use o [b]scroll[/b] ou as [b]setas[/b] para mudar a quantidade.\n• [b]Solte[/b] na mesa de troco.\n\nClique numa pilha para devolver uma. Quando estiver certo, clique em [b]Entregar troco[/b]." % Money.format(change),
		[_part(_checkout, "CashDrawer"), _part(_checkout, "ChangeTray")])
	await _checkout.sale_finished
	await _explain("Troco certinho! A partir de amanhã, troco errado sai do seu salário. Então confira antes de entregar.")


## Cliente 3 (Diego): documento com a foto de outra pessoa. Ensina a chamar o segurança.
func _teach_fake_document() -> void:
	await _call_customer()
	await _explain("Olhe com atenção a [b]foto[/b] do documento e o [b]rosto[/b] deste cliente.",
		[_part(_inspection, "Document"), _customer_view])
	await _decide("Se a foto não for da mesma pessoa, o documento é [b]falso[/b] e você chama o segurança. Senão, atende.\n\nDecida: [b]Atender[/b] ou [b]Chamar segurança[/b]?",
		_decision_buttons(),
		"Olhe de novo: a pessoa da foto [b]não[/b] é esse cliente. Documento de outra pessoa é falso.\n\nClique em [b]Chamar segurança[/b].")
	await _explain("Isso aí! Documento falso: [b]segurança[/b] nele.\n\nMas cuidado: chamar o segurança para um cliente que está certo também é erro.")


## Cliente 4 (Júnior): menor de idade comprando cerveja. Ensina a regra dos 18 anos.
func _teach_underage_alcohol() -> void:
	var customer := await _call_customer()
	await _explain("[b]Bebida alcoólica[/b] só pode ser vendida para quem tem [b]18 anos ou mais[/b].\n\nConfira a data de nascimento no documento e a data de hoje.",
		[_part(_inspection, "Document"), _part(_inspection, "DocumentTitle"), _part(_inspection, "CartLabel")])
	var card := customer.id_card
	var age := card.age_on(_day.date_year, _day.date_month, _day.date_day)
	await _decide("A foto bate. Mas e a idade? Decida: [b]Atender[/b] ou [b]Chamar segurança[/b]?",
		_decision_buttons(),
		"Faça a conta: nasceu em %s e hoje é %s. Ele tem [b]%d anos[/b]. Menor de idade não leva cerveja!\n\nClique em [b]Chamar segurança[/b]." % [
			card.birth_text(), _day.today_text(), age])
	await _explain("Exato: ele tem só %d anos. Menor comprando bebida alcoólica: [b]segurança[/b]." % age)


## Medidor do banheiro e o minigame da mangueira.
func _teach_bathroom() -> void:
	await _wait(SPEECH_WAIT)
	await _explain("Por último: cada erro (troco errado, decisão errada ou cliente que desiste) desconta do seu salário e enche o medidor do [b]banheiro[/b].",
		[_part(_hud, "BathroomBar")])
	await _explain("Quando o medidor lota, você vai lavar o banheiro. E os clientes continuam esperando no caixa, só que com um pouco mais de paciência.\n\nVamos treinar!")
	_instruct("[b]Segure[/b] o botão esquerdo do mouse e passe a mangueira sobre a sujeira até limpar tudo.")
	_main.start_bathroom_drill()
	await _bathroom.cleaned
	await _explain("Brilhando! Agora você já sabe tudo.")


# --- Passos ----------------------------------------------------------------------------------

## Libera a entrada do próximo cliente da fila e espera ele chegar ao caixa.
func _call_customer() -> CustomerData:
	_hide_coach()
	_customer_allowed = true
	var customer: CustomerData = await _main.customer_called
	_customer_allowed = false
	await _wait(SPEECH_WAIT)
	return customer


## Pede uma decisão na inspeção e espera até ela ser a certa. A cada erro, mostra `wrong_hint`.
func _decide(prompt: String, targets: Array[Control], wrong_hint: String) -> void:
	_instruct(prompt, targets)
	while true:
		var correct: bool = await _main.decision_judged
		if correct:
			return
		_instruct(wrong_hint, targets)


## O chefe fala e espera o jogador clicar em "Continuar". O resto da tela fica bloqueado.
func _explain(text: String, targets: Array[Control] = []) -> void:
	_show_coach(text, targets, true)
	await _continue_button.pressed
	_hide_coach()


## O chefe pede uma ação. A tela fica livre para o jogador fazer o que foi pedido.
func _instruct(text: String, targets: Array[Control] = []) -> void:
	_show_coach(text, targets, false)


func _show_coach(text: String, targets: Array[Control], wait_for_button: bool) -> void:
	_coach_text.text = text
	_continue_button.visible = wait_for_button
	_blocker.visible = wait_for_button
	_targets = targets
	_dim_color = DIM_EXPLAIN if wait_for_button else (DIM_INSTRUCT if not targets.is_empty() else Color.TRANSPARENT)
	_coach.show()
	# O painel cresce com o texto; reset_size() faz ele encolher de novo em falas curtas.
	_coach.reset_size()
	if wait_for_button:
		_continue_button.grab_focus()
	queue_redraw()


func _hide_coach() -> void:
	_coach.hide()
	_blocker.hide()
	_targets = []
	_dim_color = Color.TRANSPARENT
	queue_redraw()


## Pausa entre passos, com a tela bloqueada: assim o jogador não faz a próxima ação antes de o
## roteiro estar esperando por ela.
func _wait(seconds: float) -> void:
	_hide_coach()
	_blocker.show()
	await get_tree().create_timer(seconds, false).timeout
	_blocker.hide()


## Troco errado no treino: o checkout não fecha a venda e o chefe explica.
func _on_change_rejected(given_cents: int, expected_cents: int) -> void:
	var difference := "faltam" if given_cents < expected_cents else "sobram"
	_instruct("Opa! Você colocou [b]%s[/b], mas o troco é [b]%s[/b]: %s %s.\n\nClique numa pilha para devolver uma, ou em [b]Recolher tudo[/b] para recomeçar. Depois clique em [b]Entregar troco[/b] de novo." % [
			Money.format(given_cents), Money.format(expected_cents), difference, Money.format(absi(expected_cents - given_cents))],
		[_part(_checkout, "CashDrawer"), _part(_checkout, "ChangeTray")])


func _hint_customer_is_fine() -> String:
	return "Calma! O documento confere e está tudo certo. Chamar o segurança à toa também é erro.\n\nClique em [b]Atender[/b]."


func _decision_buttons() -> Array[Control]:
	return [_part(_inspection, "ServeButton"), _part(_inspection, "SecurityButton")]


## Um nó com nome único (%) dentro da cena `scene`, por exemplo o botão Atender da inspeção.
func _part(scene: Node, unique_name: String) -> Control:
	return scene.get_node("%" + unique_name)
