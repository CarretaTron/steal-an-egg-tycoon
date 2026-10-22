# Tarefa: bases com portal laser

| Campo | Valor |
|---|---|
| Status | done |
| Responsável | codex-a, sessão principal |
| Atualizado em | 2026-10-21, America/Sao_Paulo |
| Branch | codex/bases-laser |
| PR | https://github.com/CarretaTron/steal-an-egg-tycoon/pull/2 |
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

- Dois referenciais primitivos reconstruídos e vistos no Studio; removidos os temporários após a inspeção. Nenhum script de referência executado; nenhuma base laser encontrada. Criado pavilhão próprio com portal laser.
- BaseShell revisão 2 aplicado às oito bases (133 peças por base). Piso, pivô, bateria, OwnerSign/labels, pastas de jogadores e claim preservados. Nenhuma mudança em economia, layout salvo ou defesa lógica.
- Comparação dos 25 fontes atuais encontrou Client/HudGuide mais recentes no Studio; capturados conscientemente no checkout isolado. GeometryData difere apenas no newline final; mantido fonte remoto. Somente BaseShell.Source foi modificado no aplicativo; 24 fontes continuam idênticos ao início.
- Backup dos 25 fontes e das bases anteriores em Backups/AntesBaseLaser. ArteBases contém fonte de projeto, referências e ensaio reproduzível; fonte canônico em Shared/BaseShell.
- Resultados/BasesLaser/validacao-studio.json: 2.651 verificações estruturais, 118 de apresentação Combat em clone isolado, raios para Battery, oito pivôs/identidades e Apply repetido, 1.329 peças externas preservadas. Serialização nativa ida/volta aprovada; 25 fontes compilaram.
- Map/AuthoredMap.rbxm e scene.json reexportados em Edit (3.098 instâncias, sete raízes). Catálogo próprio retirado temporariamente durante captura e restaurado. Nenhum temporário incluído no cenário final.
- Portátil regenerado a partir dos fontes modernos capturados e mapa novo. Verificador aprovado: 25 fontes/cópias, oito ensaios desativados, 2.199 peças estáticas, 32 segmentos da praça, oito bases, 14 ninhos/guardiões e V2 preservada.
- Sem Play, reinício, dois clientes, perfis ou desempenho nesta tarefa. Demonstração ModeloBaseLaser.rbxm é somente fixture isolada com OwnerUserId=-1; não é substituto funcional de um plot.

## Passagem

Registro inicial publicado em 8b75ae8; entrega publicada em cf93ae6. Não publicada a experiência Roblox.

Studio e Blender liberados. Próximo passo: usuário conferir visual em Play ao escolher terreno; não há nova tarefa de mecânica pendente. Documentos e changelog atualizados. As alterações locais antigas permanecem intactas na pasta original. A versão atual está no checkout gerenciado e no portátil da entrega. Não importar snapshots de oito plots por cima do mapa existente.