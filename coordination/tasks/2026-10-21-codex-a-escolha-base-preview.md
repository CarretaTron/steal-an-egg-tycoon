# Tarefa: escolher tycoon, montar base e prévia do modelo

| Campo | Valor |
|---|---|
| Status | in_progress |
| Responsável | codex-a, sessão principal e agentes por módulo |
| Atualizado em | 2026-10-21, America/Sao_Paulo |
| Branch | codex-a/escolha-base-preview |
| Commit de partida | 5c0596b |
| Pedido autorizado | Nascer na praça, escolher base livre, montar a própria base e posicionar com prévia do objeto real semitransparente |

## Escopo e divisão

- Servidor: `Bootstrap.server.luau`, `Building.luau`, `Persistence.luau`: lobby sem terreno, reivindicação validada pelo servidor, kit guardado, preservação de perfis existentes.
- Segurança: `Combat.luau`, `WorldFactory.luau`, `Shared/Config.luau`: paredes/cobertura opcionais construídas pelo jogador, estados livre/ocupado, laser apenas com defesa construída, nenhuma referência a Plot nulo.
- Cliente: `Client.client.luau`, `Shared/HudGuide.luau`: prévia com modelo verdadeiro translúcido e não físico, interface de defesa, orientação inicial para escolher/montar base.
- Principal: integração, comparação com Studio, backups, pacote, verificação, registros e publicação da branch.

## Contrato entre módulos

- Perfil carregado pode existir sem `Plot`/`PlotId`; snapshot ao cliente informa `NeedsClaim` e `DefensesBuilt`.
- `ClaimPlot` usa identificador e proximidade reais; um jogador tem no máximo um terreno, e um terreno no máximo um dono.
- Perfil novo começa com kit em inventário, sem auto posicionar máquinas. Layouts e criaturas existentes são restaurados só depois de escolher terreno.
- `Profile.DefensesBuilt`: false em perfil novo; migração preserva proteção de perfis antigos. `BuildDefenses` é escolha explícita dentro do botão Construir, com custo central e bloqueio de combate.
- Combat expõe `SetPlotVacant(plot)` e `BuildDefenses(state)`; Bootstrap trata comando, Reset aplica proteção conforme perfil.

## Sessões e validação

- Studio `119288590672557`, sessão principal exclusiva para aplicação. Estado inicial Edit. Agentes não usam o aplicativo.
- Blender não utilizado; a prévia reaproveita a arte atual do objeto.
- O usuário assumiu testes visuais na etapa anterior. Não iniciar Play ou simulador nesta etapa sem novo pedido; compilar fontes e verificar pacote é permitido.
- Preservar cenas manuais, perfis e todas as versões anteriores. Registrar limites das verificações e enviar fontes/registro ao GitHub ao terminar.
