# Tarefa: catálogo de árvores e decoração no Blender

| Campo | Valor |
|---|---|
| Status | done |
| Responsável | codex-a, sessão principal |
| Atualizado em | 2026-10-21, America/Sao_Paulo |
| Branch | codex-a/catalogo-decoracao-blender |
| Commit de partida | 2bd667a |
| Pedido autorizado | Deixar a etapa de bases de lado; examinar Mapas open source, criar árvores e decorações próprias inspiradas nos exemplos mais bonitos e disponibilizar um catálogo no Studio |

## Objetivo e limites

- A etapa anterior foi interrompida por pedido explícito. Seus nove fontes locais, backups e RAR modificado permanecem intactos, sem aplicação ou commit nesta tarefa.
- As branches remotas codex-b/concluir-escolha-base-preview e codex-b/base-fixa-seta-paredes já contêm continuação independente da base. Não substituir seus scripts, paredes ou mapas pelo checkout local antigo.
- Ler as referências locais como dados visuais; não executar scripts dos mapas recebidos nem importar seus sistemas.
- Criar arte original, colorida e de poucos polígonos, em pasta e cena Blender separadas. Não alterar a cena das criaturas.
- Disponibilizar modelos duplicáveis em uma área de catálogo fora do mapa jogável; nenhuma mudança nos sistemas do jogo ou decoração automática da praça.

## Arquivos sob responsabilidade

- StealAnEggTycoonV3/Blender/Decoracao/: gerador, cena, geometria, exportações e referências documentadas.
- StealAnEggTycoonV3/Resultados/Decoracao/: catálogo independente e instruções de reutilização.
- Este registro, CHANGELOG.md e docs/ESTADO_ATUAL.md.
- Mapas open source/ permanece somente leitura e não será publicado automaticamente.

## Sessões e artefatos compartilhados

| Recurso | Sessão/cena/lugar | Responsável | Estado |
|---|---|---|---|
| Studio | 330fe260-7f84-4510-873a-e7721707f8e0, lugar 119288590672557 | codex-a, somente nova raiz CatalogoDecoracao | Edit, liberado |
| Blender | cena inicial não salva com Cube/Camera/Light; criar cena e arquivo novos | codex-a | liberado |

O mapa e scripts atuais do Studio são de outra continuação e serão preservados. Não iniciar Play nem simulador. O catálogo será entregue separadamente, sem empacotar os fontes antigos ou substituir Map/scene.json.

## Mudanças e validação

- Nove referências primitivas reconstruídas no Blender e observadas; arquivos de origem lidos como dados, sem executar seus scripts. Quatro referências de MeshPart foram inventariadas por ID, sem alegar visualização de sua geometria.
- Vinte modelos originais, 97 partes e 10.716 triângulos gerados em cena Blender separada. Cenas anteriores e protótipo preservados. Vinte FBX finais e geometry.json conferidos; pivô de cada modelo normalizado no chão.
- Publicação por CreateAssetAsync indisponível na sessão; fallback FBX/Importer aprovado primeiro com uma árvore. Os modelos finais usam 97 IDs permanentes do Importer, sem conteúdo efêmero na entrega final. Correções de escala de 100 vezes, giro Y de 180 graus e paleta sRGB aplicadas pelo helper próprio.
- `Workspace/CatalogoDecoracao/Modelos_Para_Copiar`: vitrine em X1600. `ServerStorage/BibliotecaDecoracao`: biblioteca de vinte modelos na origem, sem código. Nenhuma decoração distribuída automaticamente no mapa.
- `Resultados/Decoracao/validacao-studio.json`: vinte modelos/97 partes, ancoragem, pivôs, tamanhos, cores e materiais aprovados. Preservadas todas as 1.656 peças e os 25 scripts da baseline do Studio. Recarga de três malhas por ID e ida/volta da serialização nativa aprovadas. Sem Play, reinício ou teste de dois clientes.
- `Resultados/Decoracao/validacao-geometria.json`: índices, finitude, triângulos, chão, orçamento e hashes dos BLEND/FBX aprovados. Revisão independente comparou nomes e vértices dos vinte FBX à geometria (<2e-5 de diferença).
- Entrega nativa `CatalogoDecoracao.rbxm` (323.689 bytes) e `DecoracaoToolkit.rbxm` (14.687 bytes), manifesto de IDs e manifesto dos arquivos. A biblioteca pode ser obtida das cópias do catálogo; o toolkit contém somente helpers/definições.
- Não reconstruído o portátil principal nem Map/scene.json: este checkout contém fontes antigos da etapa interrompida e a continuação de codex-b está em outras branches. O catálogo é importável separadamente sobre a versão atual.

## Estado para passagem

- Registro inicial enviado em `6ac3cb3`; entrega acompanha o commit de fechamento desta tarefa na branch publicada.
- Próximo passo: escolher e duplicar modelos para decorar manualmente. No Explorer, selecionar Model, F para enquadrar, Ctrl+D para duplicar.
- Antes de capturar só o cenário principal com o exportador atual, mover temporariamente a vitrine para ServerStorage. Cópias decorativas colocadas no mapa exigem ampliar o suporte de malhas no exportador; os RBXM próprios já preservam a geometria nativa.
- Studio e Blender liberados ao concluir, sem Play iniciado. Nenhuma edição adicional da etapa de bases foi realizada. CHANGELOG e estado atual atualizados.
