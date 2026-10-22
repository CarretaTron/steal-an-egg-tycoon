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

Praça circular na frente, rua central até os biomas, duas fileiras de quatro bases voltadas uma à outra, árvores/arbustos/plantas do catálogo existente. Preservar160x160studs, IDs de terrenos e layouts relativos; adaptar geometria/configuração/rota da seta ao novo mapa. Não criar sistemas do roadmap nem alterar economia/perfis.

## Arquivos sob responsabilidade

- Shared/Config.luau, HudGuide.luau; Server/WorldFactory.luau conforme dependências espaciais.
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

- Inventário e interpretação confirmados; montagem pendente.

## Validação e evidências

| Verificação realmente executada | Resultado | Relatório/artefato e ambiente |
|---|---|---|
| Inventário de terrenos e catálogo | Oito bases160x160;20modelos existentes | Studio Edit, somente leitura |

## Estado para passagem

- Último envio: registro inicial desta tarefa.
- Próximo passo concreto: preparar backup e montar novo layout com portas para o eixo central.
- Pendências: fontes espaciais, composição, conferência visual/geometria, snapshot/portátil/envio.
- WIP antigo de D:/Roblox aura preservado.
- Studio em uso; Blender livre. Atualizar CHANGELOG/estado na conclusão.