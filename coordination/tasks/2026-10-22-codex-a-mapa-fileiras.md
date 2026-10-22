# Tarefa: mapa em duas fileiras com decoração existente

| Campo | Valor |
|---|---|
| Status | in_progress |
| Responsável | codex-a / chat de arte e mapa |
| Atualizado em | 2026-10-22, America/Sao_Paulo |
| Branch | codex/mapa-fileiras-decorado |
| Commit de partida | 757ec10 |
| Issue/PR | https://github.com/CarretaTron/steal-an-egg-tycoon/pull/3 |
| Pedido autorizado | Reorganizar bases como referência e usar decoração pronta; usuário confirmou oito bases em quatro pares e portas voltadas à rua central |

## Objetivo e limites

Praça circular na frente, rua central até os biomas, duas fileiras de quatro bases voltadas uma à outra, árvores/arbustos/plantas do catálogo existente. Preservar 160 × 160 studs, IDs de terrenos e layouts relativos; adaptar geometria/configuração/rota da seta ao novo mapa. Não criar sistemas do roadmap nem alterar economia/perfis.

## Ajuste solicitado durante a entrega

O usuário pediu bases um pouco menores e mais próximas da entrada para ver os bichos. A interpretação comunicada é a entrada dos biomas. Novo padrão 144 × 144 (10% menor), centros X±190, Z440/684/928/1172; corredor deslocado +660 Z em vez de +1000. Rua de 32 studs e quatro pares permanecem. Half72 para novos layouts; bases de saves antigos que ocupam a borda conservam half80, sem alterar IDs, grade, circuitos, criaturas ou inventário.

Esta continuação também adapta BaseShell, Combat, Building, BuildRules, Bootstrap e Client aos limites reais. Backups imediatos em Backups/AntesMapaCompacto/. A versão de avenida maior já exportada permanece histórica em Resultados/MapaFileiras/.

## Arquivos sob responsabilidade

- Shared/Config.luau, HudGuide.luau, BaseShell.luau, BuildRules.luau; Server/WorldFactory.luau, Combat.luau, Building.luau, Bootstrap.server.luau; Client/Client.client.luau conforme dependências espaciais e compatibilidade de layouts antigos.
- Map/, helper reproduzível de montagem, pacote pelo empacotador e verify_package.py se necessário.
- Resultados/MapaFileiras/, Backups/AntesMapaFileiras/, registros e documentação.
- Blender/FBX não serão alterados: reutilizar BibliotecaDecoracao existente.

## Sessões e artefatos compartilhados

| Recurso | Sessão/cena/lugar | Responsável e período de uso | Estado |
|---|---|---|---|
| Studio | bf607684-6849-4833-8719-47dd6d748e8e / ROUBE UM TYCOON DE OVOS /119288590672557 | codex-a nesta tarefa em Edit | em uso |
| Blender | Não utilizado; criação existente preservada | nenhum | livre |

Sessão anterior foi fechada; nova sessão corresponde ao mesmo lugar pelo nome/ID. Fontes Config/HudGuide/BaseShell/Generator/WorldFactory lidos antes de edição. Sem iniciar/parar Play do usuário. Root controla mutações; subagentes apenas analisam arquivos locais.

## Mudanças realizadas

- Config.MapLayout centraliza oito centros X±230, Y1, Z500/780/1060/1340. Portas para X0, rua de 32 studs e oito ramais de 20. Identidades, pisos e todos os conteúdos locais preservados.
- Cem cópias da biblioteca: 32 árvores, 40 arbustos, 16 flores e 12 pedras. Criação Blender e catálogo originais preservados; sem novas malhas/publicações.
- Corredor, sete biomas, 14 ninhos e 14 guardiões deslocados +1.000 Z. Guardian.HomeZ atualizado. Config.IsSafe e HudGuide atualizados; rua entre bases permite PvP.
- Chão ampliado em dois tiles adjacentes (1400 e 1000 studs), após identificar o clamp do engine em 2048. WorldFactory e helper reproduzem os dois tiles e os mesmos ramais.
- Vinte cópias dos módulos do paredão alongam laterais; parede ao fundo deslocada. Árvores primitivas preservadas no backup e histórico do Studio.
- Fontes ao vivo dos cinco módulos relevantes correspondiam aos locais antes da edição. Backup fresco do Studio (2.980 instâncias/207 malhas) e mapa versionado anterior (2.974/201) preservados separadamente. A diferença manual de uma árvore não foi descartada: moveu junto do primeiro bioma.
- Snapshot final com 3.952 instâncias, seis raízes e 675 malhas. Pacote e cópias dos 28 fontes regenerados. Resultados/MapaFileiras/ tem projeto completo, fontes, imagens, referência, snapshots e relatórios.

## Validação e evidências

| Verificação realmente executada | Resultado | Relatório/artefato e ambiente |
|---|---|---|
| Inventário de terrenos e catálogo | Oito bases de 160 × 160 studs e 20 modelos existentes | Studio Edit, somente leitura |

| Preservação/posição/acessos/rotas | 6.095 verificações aprovadas | validacao-studio.json, Studio Edit |
| Guia de roubo | 56 rotas chegam à própria base em até cinco etapas sem cruzar zona segura | Simulação geométrica, sem jogadores |
| Chão e compilação | 95 amostras contínuas e 28 fontes compilados | Studio Edit |
| Reaplicar helper | Retorna AlreadyApplied, sem duplicação | Studio Edit |
| Pacote e XML | 675 malhas preservadas, 28 fontes iguais, V2 e oito ensaios desativados | validacao-portatil.json e validacao-pacote.json |
| Geometria do portátil | Oito bases, 100 decorações, distância mínima de 120 studs e eixos de peças até 2048 | XML e scene.json |
| Revisão independente | Sem problemas relevantes | layout_contract, somente leitura |

## Estado para passagem

- Branch da tarefa publicada e integrada por avanço simples em codex/bases-blender/PR #3.
- Próximo passo: avaliação visual do usuário e continuação do pedido escolhido por ele.
- Sem Play, perfis, dois clientes ou medição móvel de FPS nesta etapa. Tempos entre portas são estimativas geométricas, não medição com jogadores.
- Ensaios históricos com rotas circulares continuam desativados e precisam ser adaptados antes de certificar o novo layout. Revisão geral de bugs não foi retomada.
- Studio liberado pelo agente, sem iniciar/parar Play; Blender não utilizado.
- WIP antigo de D:/Roblox aura preservado. Entrega nova copiada em Resultados/MapaFileiras/. CHANGELOG e estado atual atualizados.
