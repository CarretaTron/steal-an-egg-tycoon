# Catálogo de decoração — criação no Blender

Kit concluído com **20 modelos originais**, 97 MeshParts e 10.716 triângulos. As referências de árvores, plantas e rochas vieram dos mapas locais fornecidos pelo usuário; a modelagem foi feita no Blender. A seleção manual das peças e a decoração do mapa ficam com o desenvolvedor.

## Usar no Studio

O catálogo está em `Workspace > CatalogoDecoracao`, afastado da área jogável, próximo de **X = 1600**. No Explorer:

1. Expanda `CatalogoDecoracao > Modelos_Para_Copiar` e selecione o **Model** da peça desejada. Pressione **F** para enquadrá-lo na câmera.
2. Use **Ctrl+D** para duplicar o modelo completo, incluindo seu pivô e eventual colisão simples.
3. Mova a cópia para a pasta de decoração do mapa e posicione com as ferramentas de mover, girar e escalar. O pivô fica no chão da peça.

`Vitrine_Nao_Copiar` contém plataforma, pedestais e placas. A biblioteca limpa também está em `ServerStorage > BibliotecaDecoracao`, pronta para obter novas cópias. Não é necessário executar nenhum helper para usar o catálogo já instalado.

## Conteúdo

- Árvores: campestre, cerejeira rosa, palmeira bananeira, pinheiro nevado, salgueiro do pântano e árvore carbonizada.
- Plantas: arbustos florido e arredondado, samambaia, flores silvestres, cogumelos luminosos, cacto e juncos.
- Complementos: pedras com musgo, arenito, rocha vulcânica, tronco caído, toco com raízes e cristais de gelo e do vazio.

## Fontes e cadeia de criação

| Arquivo | Função |
|---|---|
| [Referencias/](Referencias/) | Amostras visuais, painel e registro dos caminhos nos mapas originais |
| [build_decoration.py](build_decoration.py) | Gerador das cenas e modelos originais; preserva cenas existentes |
| [CatalogoDecoracao.blend](CatalogoDecoracao.blend) | Cena final editável no Blender |
| [Exportacoes/](Exportacoes/) | Vinte FBX finais, um por modelo |
| [geometry.json](geometry.json) | Geometria completa em coordenadas locais Roblox, Y para cima e medidas em studs |
| [installation-spec.json](installation-spec.json) | Nomes, biomas, cores sRGB, limites e definição usada na instalação |
| [FBXCatalog.luau](FBXCatalog.luau) | Ajuste das importações FBX para escala, orientação, cores, pivôs e colisões |
| [Showroom.luau](Showroom.luau) | Montagem explícita da vitrine no modo Editar |
| [CatalogBuilder.luau](CatalogBuilder.luau) | Alternativa geométrica e protótipos; não é a rota da entrega final |
| [verify_decoration.py](verify_decoration.py) e [verify_catalog.luau](verify_catalog.luau) | Verificações da geometria e do catálogo |

A cadeia final é **gerador → `.blend` → FBX → Importer do Studio → IDs de malha registrados → modelos nativos RBXM**. `AssetService:CreateAssetAsync` não estava disponível nessa sessão; a entrega usa as malhas publicadas pelo Importer. A instalação corrigiu a diferença de escala de 100 vezes, aplicou giro de 180° no eixo Y e restaurou as cores sRGB. O protótipo está preservado em `CatalogoDecoracao_Prototipo.blend`, `geometry_prototype.json` e [Prototipo/](Prototipo/).

Os helpers ficam no `DecoracaoToolkit` e só atuam quando chamados explicitamente. Não há execução automática na inicialização do jogo. Os arquivos nativos, o manifesto de IDs e os relatórios estão na [entrega de decoração](../../Resultados/Decoracao/README.md).

## Verificação e limite da entrega

Foram conferidos os 20 modelos, 97 MeshParts, limites, pivôs, tamanhos, cores, materiais e ancoragem. A recarga de malhas por ID foi confirmada para árvore, palmeira e cristais, e a serialização nativa foi conferida por ida e volta. As 1.656 peças e os 25 scripts do mapa existente permaneceram preservados. Não houve reinício do Studio, Play ou teste com dois clientes nesta etapa.

O catálogo tem entrega própria. O portátil principal não foi regenerado: existem alterações locais da etapa de bases interrompida e versões posteriores de outro desenvolvedor. Além disso, o exportador atual de `Map/scene.json` recusa essas malhas decorativas. Para capturar somente o mapa principal, mova temporariamente `Workspace.CatalogoDecoracao` para `ServerStorage`; recoloque depois. Cópias decorativas já espalhadas pelo mapa também exigem suporte de malhas no exportador antes de um portátil correspondente ser gerado. Preserve os modelos nativos; não converta malhas em blocos para contornar essa limitação.
