# Tarefa: concluir escolha de base e prévia de construção

| Campo | Valor |
|---|---|
| Status | in_progress |
| Responsável | codex-b, continuação autorizada pelo proprietário |
| Atualizado em | 2026-10-21, America/Sao_Paulo |
| Branch | codex-b/concluir-escolha-base-preview |
| Commit de partida | 2bd667ac454bfc4c5f8521fa155d946a05199884 |
| Pedido autorizado | Continuar o estado do outro Codex: spawn central, escolha de tycoon, construção manual e prévia do modelo semitransparente; salvar alterações neste GitHub |

## Origem e responsabilidade

- Continuação da tarefa codex-a/escolha-base-preview, explicitamente transferida pelo usuário. A branch contém o registro inicial; o RAR de 21/10 contém fontes parciais adicionais ainda não empacotados.
- Integração de Client/Client.client.luau, Shared/Art.luau, HudGuide.luau, Config.luau; Server/Bootstrap, Building, Combat, Persistence, Production e WorldFactory conforme necessário ao contrato.
- Preservar mapa autorado, HUD, V2 e backups. Nenhuma alteração de Blender necessária.
- Atualizar fontes derivados, portátil, relatório, changelog e estado atual após validações pertinentes.

## Sessão

- Studio 119288590672557, sessão f8a8ea27-5747-4b4a-b5fe-37098c6d329f, encontrado em Edit; uso exclusivo desta continuação para comparação e aplicação. Snapshot dos scripts lidos antes de substituição.
- A passagem anterior informa que o usuário assumiu os testes visuais. Não iniciar Play/simulador automaticamente nesta continuação; executar compilação e validações estáticas/pacote, registrando os limites.
- Blender não utilizado.

## Estado para passagem

- Diagnóstico e revisão concluídos; nove fontes corrigidos/aplicados no Studio em Edit. O mapa não foi substituído e nenhum Play/simulador foi iniciado.
- RAR recebido: SHA256 `9d64278d79144173b8e3c7f9b1c2b5e9a48a989d16dda5ea10c106e519ee9f4c`. Nove fontes adicionais importados para continuação; o backup `Backups/AntesEscolhaBase/` conserva os originais.
- Comparação antes da aplicação: os 12 fontes ativos lidos no Studio correspondem à branch de partida, sem divergência extra; mapa com oito terrenos, sete biomas, 14 ninhos, 14 guardiões e raízes externas preservadas. O `Map/scene.json` do RAR é idêntico ao da branch.
- Testes novos executados: `Tests/claim_lifecycle_offline.py` (42 casos), `Tests/combat_offline.py` (359 verificações), `Tests/client_preview_guide_offline.py` (13 casos funcionais + 28 contratos estáticos). Dependências de engine simuladas, sem DataStore/Studio.
- Compilação dos 24 fontes pelo Luau CLI aprovada; os nove alterados também compilaram no Studio antes da aplicação. Validação física, visual e replicação do fluxo novo ficam com o usuário; os relatórios históricos não certificam a nova etapa.
- Próximo passo: regenerar portátil e cópias, conferir a igualdade dos fontes aplicados/empacotados e publicar a entrega.
