# Tarefa: remover cercas e manter teto visível

| Campo | Valor |
|---|---|
| Status | in_progress |
| Responsável | codex-a, sessão principal |
| Atualizado em | 22/10/2026, America/Sao_Paulo |
| Branch | codex/bases-sem-cercas-teto |
| Commit de partida | 5609448 |
| Pedido autorizado | Remover cercas baixas de madeira das bases e impedir o desaparecimento do teto ao entrar |

## Objetivo e limites

Remover somente BI_CercaMadeira das bases e desativar o recorte local do teto. Preservar estrutura, bateria, lasers, colisões, máquinas, propriedade e conteúdo dos jogadores. Atualizar criação Blender, mapa, portátil, evidências e documentação. Não iniciar/parar Play ou usar dados de jogadores.

## Arquivos sob responsabilidade

Client/Client.client.luau; Shared/BaseShell.luau e BaseIndustrialData.luau; criação Blender em nova revisão; Map/ e Resultados/. Backups da revisão anterior preservados.

## Sessões compartilhadas

Studio 330fe260-7f84-4510-873a-e7721707f8e0, lugar119288590672557; root responsável por mutações. Blender: root responsável por nova revisão da criação. Agente auxiliar apenas leitura de contratos. Checkout gerenciado bases-laser; WIP antigo de D:/Roblox aura preservado.

## Validação e passagem

Registro publicado antes das mudanças. Comparar fontes atuais do Studio antes de aplicar. Ao concluir, enviar branch e atualizar o PR existente das bases com a integração conhecida.
