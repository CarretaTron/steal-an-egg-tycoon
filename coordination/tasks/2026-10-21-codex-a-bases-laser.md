# Tarefa: bases com portal laser

| Campo | Valor |
|---|---|
| Status | in_progress |
| Responsável | codex-a, sessão principal |
| Atualizado em | 2026-10-21, America/Sao_Paulo |
| Branch | codex/bases-laser |
| Commit de partida | 07112df + catálogo 204e284 integrados no checkout isolado |
| Pedido autorizado | Substituir o visual antigo das oito bases por estrutura original inspirada nas melhores bases dos mapas locais, com portal laser |

## Objetivo e limites

- Novo pedido visual; preservar paredes prontas, máquinas livres, spawn na praça e escolha do terreno da continuação de codex-b.
- Referências locais lidas apenas como dados. Não executar scripts nem sistemas dos mapas recebidos.
- Preservar pisos, pivôs, propriedade, placas funcionais, baterias, claim pads, construções e criaturas.
- Abertura existente 16 x 18 no Z local -80; grade interna livre. Atualizar BaseShell e sua revisão para persistir em Edit e no próximo Play.
- Checkout principal D:/Roblox aura tem alterações antigas não commitadas: não serão sobrescritas nem incluídas. Trabalho em checkout isolado gerenciado.

## Arquivos sob responsabilidade

- Shared/BaseShell.luau; ArteBases/; Resultados/BasesLaser/; backups antes da troca.
- Snapshot Map/ e pacote somente depois de conferir fontes modernos versus Studio; catálogo decorativo preservado como entrega própria.
- Este registro, CHANGELOG e docs/ESTADO_ATUAL.

## Sessões

- Studio 330fe260-7f84-4510-873a-e7721707f8e0, lugar 119288590672557, Edit. Única sessão conectada; nenhum outro chat local ativo neste projeto. BaseShell lido e idêntico ao remoto 07112df.
- Registro remoto antigo de codex-b ainda in_progress refere-se à sessão f8a8ea27; novo pedido do proprietário substitui o visual, sem reverter sua funcionalidade. As mudanças conhecidas foram integradas no checkout isolado.
- Somente root faz mutações. Agentes fazem referências e revisão read-only. Sem iniciar Play/simulador; testes visuais antes transferidos ao usuário.
- Blender não altera a cena de criaturas/decoração; casca em peças Studio para preservar edição e colisões.

## Mudanças e validação

Em andamento. Referências, backup, visual final e resultados serão registrados ao concluir.

## Passagem

Registro publicado antes das alterações no Studio. Não publicar experiência Roblox. Manter protótipos e backups.