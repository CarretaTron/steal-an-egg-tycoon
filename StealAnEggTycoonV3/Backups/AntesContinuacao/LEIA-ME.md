# Steal an Egg Tycoon V3

Primeira versão jogável: roube um ovo, fuja do guardião, incube na sua base e conecte habitat → processador → vendedor para ganhar dinheiro. Destrua a bateria de outra base para abrir a entrada por 30 segundos e tente levar uma criatura para um habitat livre seu.

## Abrir e testar

Prefira continuar no projeto **STEAL AN EGG TYCOON** já aberto no Roblox Studio: ele conserva o vínculo com a experiência e suas permissões. Clique em **Play** para jogar; para testar invasões, inicie um servidor local com dois jogadores pela guia de testes.

O arquivo **StealAnEggTycoonV3.rbxlx** é uma cópia portátil com os scripts e a estrutura da V3. Abra pelo Roblox Studio e clique em **Play**: o mapa e as malhas são montados ao iniciar. Esta cópia abre com **PlaceId 0**; associe-a novamente ao lugar da experiência para usar seus DataStores e as permissões de criação de malhas. O acesso do Studio às APIs deve estar permitido nesse lugar. Quando as APIs estiverem desativadas, o jogo identifica o teste como **Sessão**, sem prometer salvamento persistente.

## Controles

| Ação | Computador | Celular |
|---|---|---|
| Roubar ovo/criatura ou incubar | Segure **E** no indicador próximo | Segure o indicador |
| Construir | **B** ou botão **Construir** | Botão **Construir** |
| Posicionar peça | Aponte para a grade e clique **Colocar** | Toque no terreno e em **Colocar** |
| Girar durante a construção | **R** ou **Girar** | **Girar** |
| Mover/guardar | Selecione uma construção e escolha a ação | Toque na construção e escolha a ação |
| Cancelar construção | **Esc** ou **Cancelar** | **Cancelar** |
| Abandonar transporte | **G** ou botão da interface | Botão da interface |
| Usar arma equipada | Clique, mirando com o mouse | **Golpear/Atirar**, mirando pelo centro da tela |

O kit inicial já traz uma linha de produção conectada. A coleta é automática após o processamento. Sem conexão, o habitat guarda até 20 recursos. Carregar impede usar armas. Praça e corredor protegem de PvP; os guardiões continuam perigosos.

## Conteúdo

- Sete biomas, 14 ninhos e 14 guardiões; sete criaturas e seus recursos.
- Oito bases separadas, construção na grade, incubação, esteiras, processamento e venda.
- Baterias, roubos entre jogadores, bastão, blasters, melhorias e rebirth.
- Interface em português, controles por toque, salvamento e recuperação de transferências.
- Fontes nas pastas **Shared**, **Server** e **Client**; modelos originais, FBX, geometria e gerador na pasta **Blender**.

Monetização, trocas e renda offline ficam fora desta versão. Os scripts StudioQA do arquivo portátil estão desativados; a suíte não interfere no jogo normal.

## Validação

- **Testes offline: 110 aprovados** — 50 de construção/produção, 36 de persistência e 24 de combate. São testes de lógica com dependências simuladas.
- **Roblox Studio, dois clientes:** 31 verificações passaram em 52,77 segundos, com ambos em modo **Persistente**. A primeira venda natural rendeu **$32**, sem adicionar dinheiro ao teste desse ciclo. Ovos, guardiões e 26 peças de malha replicaram nos dois clientes.
- O teste integrado passou por incubação, venda, quebra de bateria, roubo, abandono, morte, entrega, rebirth, recarga do perfil e restauração do layout.
- **Simulador móvel do Studio: aprovado**, em resolução **750 × 381** e com toque ativado. Um cliente ativo e sete bases preenchidas para o ensaio totalizaram oito bases ocupadas, 64 criaturas e 456 construções. Replicaram 6.141 peças, incluindo 2.363 peças de malha.
- Nesse ensaio de **10 segundos e 600 quadros**, a média foi **59,99 FPS**, com tempo de quadro P95 de **17,7 ms** e pior quadro de **18,8 ms**. Nenhum elemento da interface excedeu os limites da tela. A limpeza dos dados temporários e o salvamento após o teste foram confirmados.
- Cliques nativos no simulador abriram **Construir**, fecharam o painel e restauraram a interface principal. A aba de esteiras e a opção de colocar esteira iniciaram a construção, com botões de **44 pixels**.
- **Pendente em aparelho físico:** medição de desempenho em celular real. O resultado do simulador atende ao alvo de 30 FPS nesse ambiente de teste; não comprova a mesma taxa em todos os aparelhos.

Nenhum destes arquivos publica a experiência automaticamente.
