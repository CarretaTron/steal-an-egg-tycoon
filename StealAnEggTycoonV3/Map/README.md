# Mapa editado no Studio

Esta pasta preserva a praça circular ajustada manualmente, os caminhos, as oito bases, os sete biomas e as paredes externas do lugar `119288590672557`.

- `AuthoredMap.rbxm`: snapshot nativo completo dos seis objetos de raiz exportáveis do Workspace, com 3.952 instâncias. Preserva as malhas e propriedades originais para edição no Studio.
- `scene.json`: hierarquia tipada utilizada por `package_project.py` para incluir o mapa atual no portátil. 675 malhas estáticas permanentes mantêm geometria, IDs e InitialSize. Peças de malha dos ovos/guardiões viram pivôs transparentes no portátil; `WorldFactory` renova essas malhas a partir dos dados Blender ao iniciar a sessão.

## Depois de editar o mapa

As alterações no mundo existente passam diretamente para Play. Para que o outro computador e o portátil recebam essas alterações, também é necessário exportar os arquivos desta pasta e fazer commit.

1. Termine o teste e volte ao modo Editar. Leia e compare os scripts e as tarefas do outro desenvolvedor antes de usar a sessão compartilhada.
2. Execute `../export_authored_map.luau` pelo MCP. O resultado em `_G.EggTycoonMapExport` contém `Rows` e o buffer nativo `Serialized`. Grave `Rows` em `scene.json` por lotes e o buffer em `AuthoredMap.rbxm`, sem modificar a cena. Confira a contagem e o tamanho retornados pelo exportador.
3. Execute `python StealAnEggTycoonV3/package_project.py` e depois `python StealAnEggTycoonV3/verify_package.py`, na raiz do repositório.
4. Teste o portátil e envie o mapa, fontes e relatórios juntos com o registro da tarefa.

O exportador JSON recusa operações sólidas e malhas decorativas que não sabe reconstruir fielmente. Resolva a exportação dessas peças antes de gerar uma nova entrega; preserve sempre o snapshot nativo. Ele não remove objetos do mapa. Não importe o RBXM sobre outro mundo de mesmo nome: para restaurar a edição, use um lugar vazio ou compare e preserve a cena existente antes de substituir as raízes correspondentes.

Camera e Terrain ficam fora do snapshot de instâncias; o empacotador mantém esses objetos do projeto base. A cena atual usa peças para o chão e para as paredes.

## Captura das bases de jardim — 21/10/2026

Snapshot renovado em Edit depois de aplicar BaseShell revisão 2 às oito bases. Sete raízes, 3.098 instâncias e 2.199 peças estáticas, mantendo praça, caminhos, paredes externas, ninhos e guardiões. O catálogo decorativo de X=1600 foi excluído temporariamente da captura e restaurado no Studio; continua preservado no RBXM próprio. A captura não incluiu a prévia isolada nem as reconstruções temporárias das referências.

## Captura industrial — 22/10/2026

Snapshot atual renovado em Edit depois de aplicar BaseShell revisão 3 às oito bases: oito raízes, 2.838 instâncias, 1.872 peças estáticas e 153 MeshParts permanentes. O catálogo de decoração agora está incluído (97 malhas), junto das 56 malhas das bases. O mapa anterior está em Backups/AntesBaseBlender/MapRev2/.

O exportador aceita malhas visuais ancoradas, sem colisão/toque e com IDs permanentes; preserva InitialSize, tamanho, transformação, materiais e opções de renderização. Colisões continuam em Parts separados. Malhas com rig, SurfaceAppearance, IDs temporários, colisão própria ou operações sólidas interrompem a exportação. A prévia isolada não está no mapa.

Portátil regenerado e verificado com 26 fontes; todas as 153 malhas e suas dimensões originais foram comparadas com o XML final. Sem abrir o XML em outra sessão do Studio e sem novo Play nesta etapa.

## Captura sem cercas — 22/10/2026

Captura atual da revisão 4: oito raízes, 2.830 instâncias, 1.864 peças estáticas e 145 MeshParts (48 das bases e 97 do catálogo). Removidas somente as oito BI_CercaMadeira. Roof e RoofCollision preservados; o Client não esconde mais o teto.

Backup da captura anterior em Backups/AntesRemoverCercasTeto/MapRev3/. Portátil regenerado com 26 fontes; pacote e 145 malhas conferidos. Sem novo Play nesta revisão.

## Captura com geradores — 22/10/2026

Captura atual: oito raízes,2.974 instâncias e201 MeshParts permanentes. Oito geradores de sete malhas instalados sob as Battery originais; oito painéis SurfaceGui e nenhuma BillboardGui de bateria. Root Battery segue Part com colisão/consulta; as malhas visuais e painel não usam física. Sem prévia temporária no mapa.

CanvasSize1024 × 320, SizingModeFixedSize e LightInfluence0 preservados para os visores. Backup anterior em Backups/AntesGeradorIndustrial/MapAnterior/. Portátil com28 fontes conferido; sem novo Play.

## Apoio dos geradores — 22/10/2026

Generator revisão 3 posiciona os oito conjuntos no chão externo: Battery centro Y3,5, pés em Y0; antes estavam 1 stud acima da grama. Identidade, X/Z e orientação das baterias, pisos e restante do cenário preservados. Snapshot nativo e JSON renovados em Edit, com as mesmas 2.974 instâncias e 201 malhas. Evidências da revisão em Resultados/GeradorNoChao/.

## Avenida com quatro pares de bases — 22/10/2026

Oito terrenos de 160 × 160 studs preservados, centros X-230/+230, Y1 e Z500/780/1060/1340. Portas voltadas para X0, rua central de32studs, oito ramais de 20 studs. Pisos vizinhos deixam120 studs entre fileiras; portas opostas distam300 studs e portas da mesma fileira280 studs. Estimativa em velocidade de transporte inicial18studs/s:16,7 s e15,6 s, sem cronometragem de jogador.

Biomas, ninhos e guardiões movidos inteiros em+1.000 Z; passagem segura agora Z1600..2950. Rua entre as bases continua permitindo PvP. Config e HudGuide acompanham o cenário; WorldFactory preserva o mapa existente e usa as novas coordenadas em sua geração básica. O chão usa duas peças adjacentes, Z-700..700 e700..1700, respeitando o máximo2.048 studs por eixo de Part.

Cem modelos decorativos copiados do catálogo original:32 árvores,40 arbustos,16 flores e12 pedras;468 malhas adicionais. Vinte módulos de paredão existentes duplicados para alongar as laterais. Árvores primitivas ficam preservadas no snapshot anterior e no histórico do Studio. Catálogo original e criação Blender não foram alterados.

Snapshot final em Edit:3.952 instâncias,6 raízes e675 MeshParts permanentes. Backups do mapa efetivamente encontrado no Studio e da versão anterior do Git são distintos em Backups/AntesMapaFileiras/. Helper explícito arrange_avenue.luau não roda no jogo e retorna sem duplicar se a revisão já foi instalada. Resultados/MapaFileiras/ contém referências, imagens, fontes, portátil e relatórios. Sem Play nesta revisão.

## Revisão atual: avenida compacta — 22/10/2026

Substitui as medidas da avenida anterior: oito bases de 144 × 144 studs (10% menores), centros X±190, Y1 e Z440/684/928/1172. Todas as portas continuam para a rua central. Distância mínima entre terrenos padrão: 100 studs. Portas opostas distam 236 studs; portas da mesma fileira, 244. Estimativa de transporte inicial: 13,1 s e 13,6 s, sem cronometragem de jogadores.

A expedição fica 340 studs mais próxima que na revisão maior: offset total +660 em relação ao mapa circular; corredor seguro em X±90, Z1260..2610. Rua central termina em Z1310. Chão em dois tiles até Z1340. O paredão ao fundo recebe 40 studs extras de afastamento, com sobreposição entre parede e bases igual a zero no teste. As mesmas cem decorações foram reposicionadas.

BaseShell revisão 5 e Config.PlotHalf=72 acompanham a redução. Máquinas, criaturas, gerador e grade de quatro studs não foram escalados. Perfil antigo que precise do limite/reserva/acessibilidade anterior conserva uma base de 160 studs até sair, sem mover ou apagar máquinas, IDs ou conexões. Render, regras, HUD, roubo, laser, claim e entrega usam a dimensão efetiva do terreno.

Snapshot atual: 3.952 instâncias, seis raízes e 675 malhas. Resultados/MapaCompacto/ é a entrega vigente; Resultados/MapaFileiras/ preserva a etapa maior. Backups imediatos em Backups/AntesMapaCompacto/. arrange_avenue só aceita o mapa circular original ou a revisão já instalada; compact_avenue migra a revisão 1 para a 2. Ambos são operações explícitas de Edit, nunca executadas pelo jogo.
