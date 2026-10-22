# Tarefa: remover cercas e manter teto visível

| Campo | Valor |
|---|---|
| Status | done |
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

## Entrega concluída

- Cerca BI_CercaMadeira removida dos oito terrenos e de Shared/BaseIndustrialData.luau. Shared/BaseShell.luau passou à revisão 4; idempotência e reconstrução não restauram a cerca.
- Client perdeu RestoreRoofCutaway, UpdateRoofCutaway e suas três chamadas. Roof permanece opaco; colisão, CanQuery e filtro de seleção preservados.
- Fontes do Studio comparados e encontrados iguais aos locais antes de alterar. Somente esses três fontes foram editados. Root foi o único mutador das sessões.
- Criação Blender atual em nova cena/arquivo Blender/BaseIndustrialSemCercas/. Seis malhas, 12.864 vértices e 19.632 triângulos. IDs existentes das seis partes reaproveitados, sem nova importação.
- Mapa exportado em Edit: 2.830 instâncias, oito raízes, 145 MeshParts. Captura prévia e fontes rev3 em Backups/AntesRemoverCercasTeto/. Resultados históricos preservados.
- Entrega atual em Resultados/SemCercasTeto/: portátil completo, fontes em manifesto, snapshot, prévia, relatórios e hashes.
- Validação: 45 verificações em Edit (ausência de cercas, opacidade/colisão, idempotência e reconstrução) e 26 fontes compilados. Pacote/cópias passaram no verificador. XML comparado às 145 malhas e InitialSize, nenhuma cerca restante.
- Sem Play, dois clientes, perfis, dados persistentes ou medições de desempenho. Conferência visual realizada no Studio e na cena Blender. Sessões liberadas em Edit/nova cena; oito ensaios continuam desativados.
- CHANGELOG e ESTADO_ATUAL atualizados. Branch da tarefa será integrada por avanço simples à codex/bases-blender e enviada ao PR #3 existente, preservando o fluxo de entrega.
