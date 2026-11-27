# Zing Shop

Jogo em Godot 4.7 (GDScript): o jogador é caixa de mercado. Escaneia produtos, recebe em
dinheiro ou cartão, dá troco, a partir do Dia 2 confere documentos (idade para cerveja) e, quando
erra, leva bronca do chefe e vai limpar o banheiro. Visão frontal, pixel art com mistura
proposital de estilos (banheiro em foto real com sujeira em pixel; ver `docs/ASSETS.md`).

Tudo em português: textos do jogo, comentários `##`, commits, PRs e conversa com o usuário.

## Rodar e checar

O projeto Godot fica em `zing-shop-game/`. O binário do editor está fora do repo:
`../Godot_v4.7.2-stable_linux.x86_64` (a partir da raiz do repo).

Depois de mexer em script ou cena, confira sem abrir janela:

```bash
cd zing-shop-game
../../Godot_v4.7.2-stable_linux.x86_64 --headless --path . --import
../../Godot_v4.7.2-stable_linux.x86_64 --headless --path . --quit-after 120
```

Pronto quando as duas saem sem linhas de `ERROR`/`SCRIPT ERROR`. O teste de jogabilidade é do
usuário: ele abre o jogo e libera o merge.

Ao salvar cenas/recursos novos o Godot gera ou troca `uid`; commite essas mudanças junto.

## Como o jogo é montado

- **Dados em `.tres`**, código em `data/*.gd` (classes `Resource`): dias em `data/days/`,
  clientes em `data/customers/`, produtos em `data/items/`, falas genéricas em
  `data/dialogues.tres`. Mudança de balanceamento ou de fala é edição de `.tres`, não de script.
- **`scenes/main.gd`** é a cena do dia: fila de clientes, paciência, decisões, bronca e banheiro.
  Foi dividido em partes (`scenes/checkout/`, `scenes/day/`, `scenes/bathroom/`, `scenes/ui/`);
  mantenha ele como orquestrador e ponha lógica nova na parte correspondente.
- **`GameSession`** (`data/game_session.gd`, estático) guarda o dia atual e o dinheiro da semana
  entre recargas da cena, e salva em `user://progresso.cfg` se o Prólogo já foi concluído.
- **Chefe fala pelo `BossToast`** (`scenes/ui/boss_toast.gd`).

## Regra de design: uma mecânica por dia

Mecânica nova entra num dia próprio, anunciada pelo chefe no `DayData.boss_intro`, mesmo que o
tutorial já a mostre. Ordem atual:

| Dia | Data no jogo | O que entra |
|---|---|---|
| Prólogo | 15/03 | Tutorial guiado (`DayData.tutorial`): sem paciência, sem desconto, não conta para a meta |
| Dia 1 | 16/03 | Caixa: escanear, cobrar, troco. Sem documentos |
| Dia 2 | 17/03 | Inspeção de documentos. Meta R$ 100 |

## Fluxo de trabalho

1. Branch `feat/<assunto>` a partir da `main`.
2. Commit(s) e PR no GitHub (`Gui-Tavares-rar/ZingShop`).
3. O usuário testa e faz o merge. Ajuste pequeno vai direto na `main` só se ele autorizar.

Histórico: PR #1 Dia 1 · #2 inspeção, Dias 1 e 2, menu, falas, sons, meta da semana, pausa ·
#3 Prólogo com tutorial interativo · #4 Dia 1 sem documentos, inspeção só no Dia 2.

## Próximo trabalho

O playtest dos colegas (semana de 16/11/2026) virou um plano de 4 PRs, ainda não implementado:
leia `docs/PLANO-PLAYTEST.md` antes de começar qualquer um deles ou ao reportar o progresso.
