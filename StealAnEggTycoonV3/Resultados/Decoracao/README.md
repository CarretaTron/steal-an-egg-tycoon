# Entrega do catálogo de decoração

Catálogo concluído com **20 peças originais criadas no Blender**, 97 MeshParts e 10.716 triângulos, inspirado nas árvores e decorações dos mapas locais enviados pelo usuário.

## Encontrar e copiar as peças

No Studio conectado, abra `Workspace > CatalogoDecoracao > Modelos_Para_Copiar`. A vitrine fica próxima de **X = 1600**, separada do mapa jogável.

1. Selecione o **Model** completo da árvore ou decoração no Explorer e pressione **F** para enquadrar.
2. Pressione **Ctrl+D** para criar uma cópia.
3. Mova a cópia para a pasta de decoração do mapa e posicione-a. Os modelos têm pivô no chão, cores prontas e peças ancoradas.

Use apenas os modelos em `Modelos_Para_Copiar`; `Vitrine_Nao_Copiar` contém placas, pedestais e plataforma. A pasta `ServerStorage > BibliotecaDecoracao` guarda as mesmas peças sem a vitrine. O usuário escolhe onde decorar; esta etapa não distribuiu peças pelo cenário.

## Arquivos entregues

| Arquivo | Conteúdo |
|---|---|
| [CatalogoDecoracao.rbxm](CatalogoDecoracao.rbxm) | Catálogo nativo para inserir em uma cópia do lugar e obter as peças prontas |
| [DecoracaoToolkit.rbxm](DecoracaoToolkit.rbxm) | Definições e helpers de edição; não executam automaticamente no jogo |
| [manifesto-assets.json](manifesto-assets.json) | IDs de malha e dados da instalação final |
| [validacao-studio.json](validacao-studio.json) | Resultado das conferências no Studio |
| [validacao-geometria.json](validacao-geometria.json) | Verificações dos dados geométricos e exportações |
| [kit-blender.png](kit-blender.png) | Prévia do kit no Blender |
| [catalogo-studio.jpg](catalogo-studio.jpg) | Prévia da vitrine instalada no Studio |

Para inserir um RBXM em outro lugar, use **Inserir do arquivo** no Explorer. Se já houver um catálogo ou uma biblioteca com o mesmo nome, mantenha a versão anterior identificada e confira o conteúdo antes de substituir. A inserção do modelo nativo dispensa reimportar os vinte FBX.

Insira `CatalogoDecoracao.rbxm` no Workspace. O toolkit é opcional e deve ficar em ServerStorage. A biblioteca limpa pode ser recriada copiando os vinte Models de `Modelos_Para_Copiar` para uma pasta `BibliotecaDecoracao` em ServerStorage e aplicando `Model:PivotTo(CFrame.identity)` a cada cópia; a vitrine não faz parte dessa biblioteca. Os hashes dos dois RBXM estão em [manifesto-arquivos.json](manifesto-arquivos.json).

Os fontes de criação estão em [Blender/Decoracao](../../Blender/Decoracao/README.md): cena `.blend`, gerador Python, vinte FBX finais, geometria completa, definição de instalação e referências. A cadeia usada foi **gerador → Blender → FBX → Importer do Studio → IDs de malha → RBXM**. A publicação por `AssetService:CreateAssetAsync` não estava disponível; a rota final foi o Importer. Escala, orientação de 180° no eixo Y e cores sRGB foram ajustadas na instalação.

## O que foi validado

Conferidos os 20 modelos e 97 MeshParts, pivôs, limites, tamanhos, cores, materiais e ancoragem. Houve recarga por ID de amostras de árvore, palmeira e cristais e ida e volta da serialização nativa. As 1.656 peças e os 25 scripts do mapa existente foram preservados. Não foram executados reinício do Studio, Play nem ensaio com dois clientes; esses resultados não certificam esses testes.

Este é um pacote separado do portátil principal. O portátil não foi regenerado, preservando a etapa de bases interrompida e versões posteriores do outro desenvolvedor. O exportador de `Map/scene.json` ainda recusa as novas malhas decorativas. Para uma captura só do mapa principal, mova temporariamente `Workspace.CatalogoDecoracao` para `ServerStorage` e devolva depois; modelos copiados para o cenário também precisarão de suporte de malhas no exportador. Os RBXM desta pasta preservam a entrega nativa sem alterar o mapa principal.
