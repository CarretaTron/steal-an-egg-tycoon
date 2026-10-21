# Tarefa: preservar mapa editado e estabilizar rebirth na HUD

| Campo | Valor |
|---|---|
| Status | review |
| Responsável | codex-a, sessão principal; agente HUD no cliente |
| Atualizado em | 2026-10-20, America/Sao_Paulo |
| Branch | codex-a/preservar-mapa-rebirth |
| Commit de partida | 05cafb2 |
| Pedido autorizado | Preservar alterações manuais no teste e corrigir rebirth; no ajuste visual seguinte, aproximar o contador do valor do dinheiro como na referência |

## Objetivo e arquivos

- Principal: `Server/WorldFactory.luau`, integração do mapa autorado, exportação/empacotamento, backups, validações e documentação.
- Agente HUD: apenas `Client/Client.client.luau`, posição estável de dinheiro e rebirth. A sessão principal sincroniza o Studio e os artefatos de entrega.
- Cópias derivadas e `.rbxlx` serão atualizados após preservar o mapa editado.

## Sessões compartilhadas

- Studio: `119288590672557`, sessão `dc642739-e0c1-4a55-83ac-130a9d3b2022`, encontrado em Edit. Sessão principal usa leitura, aplicação das correções e testes desta tarefa. Não há outra tarefa ativa publicada no repositório.
- Blender: não utilizado.
- Scripts do Studio serão comparados aos fontes locais antes de qualquer substituição. O mapa manual não será substituído pelo snapshot antigo do pacote.

## Diagnóstico inicial

- `WorldFactory.Build()` destrói o mundo existente quando `RuntimeGenerated` difere de `RunService:IsRunning()`. Entrar em Play torna a condição diferente e apaga as alterações manuais internas.
- O layout da HUD altera a posição do rebirth numa rotina de redimensionamento e novamente pela largura do texto na atualização frequente.
- O mundo editado tem 1.414 descendentes; há também paredes e outros objetos manuais fora da pasta gerada.

## Validação e passagem

- Mapa preservado em `Map/AuthoredMap.rbxm` (snapshot nativo) e `Map/scene.json`, com 1.562 instâncias. O empacotador usa a cena atual e atualiza os artefatos automaticamente.
- Edit/Play já conferido: 32 trechos de praça e 82 peças de paredes mantiveram CFrame, Size, cor e material. Os 14 ovos mantiveram prompts, os 14 guardiões e seus labels carregaram, e repetir Build no contexto do servidor manteve as referências. Evidência em `Resultados/Testes/mapa-edit-play.json`.
- O usuário assumiu os testes e interrompeu a continuação pelo simulador. Não reiniciar Play nem simulador para esta revisão visual do rebirth.
- A variante com colunas fixas deixou espaço excessivo; o pedido seguinte é usar uma linha horizontal com espaço curto entre dinheiro e rebirth, sem dupla escrita de posição.
- Backup anterior a esse ajuste em `Backups/AntesRebirthJunto/Client.luau`. Os scripts anteriores e snapshot nativo do mapa estão em `Backups/AntesPreservarMapa/`.
- HUD adjacente aplicada no Edit: `EconomyRow` com layout horizontal, largura natural e espaço de 10 pixels. O layout é o único responsável pelas posições; o ajuste de fonte é cacheado por texto e viewport.
- Compilação da variante adjacente passou no Studio sem iniciar Play. O pacote e os fontes derivados acompanham esta revisão.
- Próximo passo: teste visual final pelo usuário e integração da branch `codex-a/preservar-mapa-rebirth`. Não reiniciar os testes assumidos pelo usuário sem novo pedido.
- O marcador temporário de QA já foi removido do mapa Edit; Blender não foi utilizado.
