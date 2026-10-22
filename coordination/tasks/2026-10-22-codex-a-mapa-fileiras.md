# Tarefa: avenida de oito tycoons, decoração e versão compacta

| Campo | Valor |
|---|---|
| Status | done |
| Responsável | codex-a / chat de arte e mapa |
| Atualizado em | 2026-10-22, America/Sao_Paulo |
| Branch | codex/mapa-fileiras-decorado |
| Commit de partida | 757ec10 |
| Issue/PR | https://github.com/CarretaTron/steal-an-egg-tycoon/pull/3 |
| Pedido autorizado | Organizar como referência, reutilizar decoração e manter oito bases em quatro pares; portas para a rua central. Durante a entrega, reduzir um pouco e aproximar da entrada para ver os bichos |

## Objetivo e resultado

Oito bases padrão de 144 × 144 studs, redução de 10%, centros X±190, Y1, Z440/684/928/1172. Portas direcionadas para a rua central, praça/spawn na frente e expedição no fundo. Entrada dos biomas 340 studs mais próxima que na primeira avenida maior. Interpretação comunicada da palavra entrada: entrada dos biomas.

Cem modelos do catálogo existente: 32 árvores campestres, 40 arbustos, 16 flores e 12 pedras. Sete biomas, 14 ninhos e 14 guardiões movidos inteiros, offset final +660 em relação ao mapa circular. Chão em dois tiles, rua com PvP, corredor seguro X±90/Z1260..2610. Paredão manual estendido com vinte cópias e afastado 40 studs extras ao fundo; zero interseções com as bases.

## Arquivos sob responsabilidade

- Shared/Config, HudGuide, BaseShell e BuildRules.
- Server/WorldFactory, Combat, Building e Bootstrap; Client/Client.client.luau.
- Tests/combat_offline.py: somente dependências de mocks de BaseShell e PlotHalfFor.
- Map/arrange_avenue.luau, compact_avenue.luau, AuthoredMap.rbxm, scene.json e README.
- Pacote/Fontes/Map derivados pelo empacotador; Resultados/MapaCompacto/ é a entrega vigente.
- Resultados/MapaFileiras/ preserva a avenida maior; Backups/AntesMapaFileiras/ e AntesMapaCompacto/ preservam fontes/mapas.
- CHANGELOG e docs/ESTADO_ATUAL atualizados. Blender/FBX/catálogo originais preservados.

## Compatibilidade

Máquinas, criaturas, gerador e grade de quatro studs não foram escalados. BaseShell revisão 5 usa Half72 padrão e Half80 para um layout antigo que precise da borda, reserva de entrada ou acessibilidade anterior. Nenhuma conversão de ID, posição, criatura, inventário ou circuito. Base expandida fica assim até vagar; então retorna a 144. Todos os limites de construção/HUD/roubo/laser/claim/entrega respeitam a dimensão efetiva. Há guardas de dono/geração após carregamento de malhas e cancelamento de render se o responsável mudou.

## Sessões e preservação

| Recurso | Sessão/cena/lugar | Responsável e uso | Estado |
|---|---|---|---|
| Studio | bf607684-6849-4833-8719-47dd6d748e8e / ROUBE UM TYCOON DE OVOS /119288590672557 | root aplica e confere em Edit | livre |
| Blender | Biblioteca pronta; nenhuma cena editada | não utilizado | livre |

Fontes lidos antes de trocar. Nove fontes da redução comparados com os backups por assinatura e patches exatos; candidatos compilados antes da escrita. Antes da tarefa, o Studio tinha 2.980 instâncias/207 malhas e o mapa versionado, 2.974/201: ambos preservados separadamente. A árvore manual adicional acompanhou seu bioma. Não iniciar/interromper Play do usuário. Subagentes editaram somente os fontes combinados; apenas root alterou Studio. Checkout antigo de D:/Roblox aura preservado, com uma pasta nova de entrega compacta.

## Validação realmente executada

| Verificação | Resultado | Evidência/ambiente |
|---|---|---|
| Primeira avenida maior | 6.095 verificações e 56 rotas simuladas | Histórico Resultados/MapaFileiras/, Edit |
| Versão compacta final | 3.563 verificações, 56 rotas e 200 amostras do chão | Resultados/MapaCompacto/validacao-studio.json, Edit |
| Layouts legados | Borda e reserva antigas preservadas, sem alterar IDs/posições/inventário | Dois perfis sintéticos; módulos reais de estado e visuais de máquina simulados |
| Laser compacto | Gerador alcançável por fora; entrada bloqueada, saída permitida e brecha libera passagem | Combat real, personagens sintéticos com Humanoid; sem jogadores reais |
| Compilação | 28 fontes aprovados | Studio Edit |
| Harness existente de combate | 365 verificações aprovadas | validacao-combate-mocks.json, mocks lexicais hospedados no Studio; CLI indisponível |
| Preservação do mapa ao preparar mundo | Mesmo mundo e contagem de objetos | WorldFactory real em Edit |
| Parede e idempotência | Zero interseções; SetHalf não duplica/refaz uma base já correta | Edit |
| Pacote/XML | 675 malhas, oito bases, cem decorações, 28 fontes iguais, V2 preservada e oito ensaios desativados | validacao-portatil.json e validacao-pacote.json |
| Revisões independentes | Sem falha de gameplay relevante | layout_contract e compact_shell; guard do helper de migração incorporado |

## Passagem

- Branch enviada e integrada por avanço simples à codex/bases-blender/PR #3.
- Entrega atual Resultados/MapaCompacto/ contém portátil completo, cópias dos 28 fontes, snapshots, imagens, helpers e relatórios. Etapas e tentativas anteriores preservadas.
- Limitações: sem Play, DataStore, perfis reais, dois clientes, celular físico ou FPS. 13,1/13,6 s entre portas são estimativas geométricas. Base legada maior pode diminuir a distância de 100 studs dos padrões; pisos não se sobrepõem.
- Ensaios históricos de navegação circular permanecem desativados e exigem adaptação para certificar este mapa. A revisão geral de bugs não foi retomada.
- Helpers são operações explícitas de Edit: arrange aceita só o backup circular ou no-op na revisão final; compact migra a revisão 1 para a 2. Não executar na inicialização.
- Studio liberado; nenhum Play foi iniciado/parado pelo agente. Próximo passo é a avaliação visual do usuário e o pedido seguinte escolhido por ele.
