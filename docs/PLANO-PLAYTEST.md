# Plano do playtest (23/11/2026)

Playtest da build com Prólogo, Dia 1 e Dia 2, feito pelos colegas na semana de 16/11/2026.

## O que apontaram

1. A faxina do banheiro começa sem explicação nem transição.
2. O troco não é intuitivo.
3. Os clientes deveriam ter pressa variada.
4. Os avisos do chefe precisam de mais destaque.
5. Depois de 3 erros seguidos de troco em dinheiro, o jogo deveria dar uma dica do valor.

## PRs, nesta ordem

Marque `[x]` quando o PR for mesclado.

### [ ] 1. `feat/layout-cores-em-destaque` (item 4)

A branch já existe no GitHub, ainda sem commits próprios.

- `BossToast` no topo central, maior, com cor por tipo (bronca / elogio / info) via
  `say(message, kind)`.
- Fila de recados; tempo na tela proporcional ao tamanho do texto.
- "-R$ X" flutuante no HUD quando há desconto.
- Medidor do banheiro pisca quando sobe.

### [ ] 2. `feat/transicao-faxina` (item 1)

- Nova cena `bathroom_intro` antes do `_bathroom.start()` em `main.gd::_reprimand`:
  "Hora da faxina!", o motivo, como jogar, botão "Pegar a mangueira".
- Texto completo só na 1ª vez (flag no `GameSession`); depois, versão curta.
- Paciência dos clientes congelada enquanto o cartão está na tela.

### [ ] 3. `feat/troco-intuitivo` (itens 2 e 5)

- Clique simples adiciona 1 unidade da nota/moeda (segurar + scroll vira atalho).
- Monitor mostra RECEBIDO / TOTAL / TROCO ?; botão "Entregar troco" em destaque.
- A bronca diz quanto faltou ou sobrou.
- Dica: `consecutive_wrong_change` no `GameSession`, atravessando os dias (Dia 1 tem só 2
  clientes em dinheiro, Dia 2 tem 5). Ao chegar a 3, o próximo cliente em dinheiro mostra o troco
  no monitor e o chefe fala o valor; o contador zera.

### [ ] 4. `feat/pressa-clientes` (item 3)

- `enum Haste {CALMO, NORMAL, APRESSADO}` em `CustomerData` (~35 / 22 / 12 s de paciência).
- Ícone na fila e no cliente; fala própria por pressa; apressado fica nervoso cedo.
- Redistribuir: Lia e Beto apressados, Dona Marta e Seu Antônio calmos.
- Gorjeta opcional para quem é atendido rápido.

## Decisões em aberto (perguntar ao usuário)

- Contador de erros atravessando os dias, ou permitir corrigir o troco como no Prólogo?
- O "TROCO ?" no monitor facilita demais?
- Perguntar aos colegas se a confusão foi o gesto (segurar + scroll) ou a conta.
