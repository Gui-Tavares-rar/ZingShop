# Assets do Zing Shop

Lista dos assets escolhidos para substituir os desenhos provisórios feitos por código.
Ao baixar, confira a licença na página e registre o crédito em `CREDITS.md`.

**Direção visual:** base em pixel art, com mistura proposital de estilos quando for engraçado
(ex.: banheiro em foto real com sujeira em pixel). O jogo é em visão frontal, então packs
top-down (16×16 de RPG/mercado) não servem.

## Para baixar

| Asset | Uso no jogo | Licença | Baixado |
|---|---|---|---|
| [Pixel Art Portrait Generator](https://v-ktor.itch.io/pixel-art-portrait-generator) (V-ktor) | Clientes, chefe e segurança. Feito em Godot, com código-fonte: dá para gerar clientes aleatórios no próprio jogo. | MIT / CC BY 4.0 | [ ] |
| [Pixel Mart](https://ghostpixxells.itch.io/pixel-mart) (ghostpixxells) | Produtos do mercado (substitui os sprites de RPG em `tiles/`). | Preço livre — conferir | [ ] |
| [Coins Asset](https://greenbear8.itch.io/coins-asset) (GreenBear8) | Moedas da gaveta e da mesa de troco. | CC BY 4.0 (exige crédito) | [ ] |
| [Dollar](https://havran.itch.io/dollar) (Havran) | Base das notas: recolorir para parecer real (R$ 2 a R$ 100). | Grátis — conferir | [ ] |
| [Convenience Store Audio Pack](https://fulminisictus.itch.io/convenience-store-audio-pack) (Fulminisictus) | Gaveta do caixa, moedas no balcão, bipe do scanner, ambiente da loja. | Preço livre — conferir | [ ] |
| [UI Clicky Sound and FX Pack](https://gmorkh.itch.io/uiscp) (Gmorkh) | Cliques e sons de interface. | Grátis — conferir | [ ] |
| [Dialogue Blips Free](https://heyheythere.itch.io/dialogue-blips-free) (heyheythere) | Vozes "blip" das falas dos NPCs (6 vozes). No projeto só ficam as vozes, em `addons/dialogue_blips/`; o resto do pack (caixa de diálogo, temas, fonte pixel `hearth`, demo) está em `extras/dialogue-blips-free/`. | CC BY 4.0 — crédito: `Dialogue Blips Free by heyheythere - https://heyheythere.itch.io/dialogue-blips-free - CC BY 4.0` | [x] |

## Para desenhar

Ferramentas: [Piskel](https://www.piskelapp.com) (grátis, no navegador) ou Aseprite/LibreSprite.

- [ ] Cerveja (lata): hoje usa a poção verde de RPG (`tiles/potion_green_01.png`) como quebra-galho
- [ ] Sacola (papel ou plástico)
- [ ] Maquininha de cartão (telas: aguardando, processando, aprovado)
- [ ] Notas de real a partir do pack Dollar (recolorir cada valor)
- [ ] Sujeira do banheiro em pixel (ou gerada por código em blocos de pixel)

## Outras fontes

- Foto do banheiro: [Vaso sanitário de cerâmica branca](https://unsplash.com/pt-br/fotografias/vaso-sanitario-de-ceramica-branca-VCVI5QUvFAY),
  por [Gabor Monori](https://unsplash.com/@gabor) no Unsplash. Licença Unsplash: uso livre, inclusive comercial,
  sem crédito obrigatório (mas vamos creditar mesmo assim). Banheiro abandonado com pichação; a sujeira em pixel vai por cima.
  No projeto: `assets/backgrounds/bathroom.jpg` (reduzida para 1920 px); o original em resolução cheia está em `extras/originais/`.

## Efeitos sonoros (Freesound)

Em `zing-shop-game/assets/sounds/`; os originais estão em `extras/originais/sons/`.
Os arquivos do jogo foram cortados, normalizados e (a água) emendados para repetir sem pausa.

| Som | Arquivo | Origem | Licença |
|---|---|---|---|
| Sino de balcão (chegada do cliente) | `bell.wav` | [Reception Bell](https://freesound.org/s/398281/) por FlashTrauma | CC0 |
| Alarme de erro | `alarm.wav` | [Incorrect Buzzer](https://freesound.org/s/700641/) por Producing_RayLite | CC0 |
| Jato de água (mangueira) | `water_spray.wav` | [20060727.kitchen.jet.wav](https://freesound.org/s/21198/) por dobroide | CC BY 4.0, crédito: `20060727.kitchen.jet.wav by dobroide - https://freesound.org/s/21198/ - CC BY 4.0` |
