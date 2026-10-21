# Tarefa: preservar mapa editado e estabilizar rebirth na HUD

| Campo | Valor |
|---|---|
| Status | in_progress |
| Responsável | codex-a, sessão principal; agente HUD no cliente |
| Atualizado em | 2026-10-20, America/Sao_Paulo |
| Branch | codex-a/preservar-mapa-rebirth |
| Commit de partida | 05cafb2 |
| Pedido autorizado | Preservar alterações manuais do modo Editar no teste e corrigir contador de rebirth que muda de posição |

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

- Pendente: correções, comparação Edit/Play, estabilidade da HUD, pacote e envio da branch.
- Registrar resultados reais e liberar a sessão ao terminar.
