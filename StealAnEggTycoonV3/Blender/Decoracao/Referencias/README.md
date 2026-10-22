# Referências locais para o catálogo de decoração

`samples.json` contém treze amostras visuais extraídas dos mapas enviados pelo usuário em `Mapas open source/`. O objetivo é comparar silhuetas e paletas para criar peças próprias no Blender. Não contém scripts, interfaces, dados de jogadores ou lógica dos jogos de origem.

Os três arquivos de origem usam o formato binário Roblox com chunks Zstd, inclusive os dois arquivos com extensão `.rbxlx`. `extract_reference_samples.py` é um leitor limitado de propriedades visuais e hierarquia; não importa nem executa o jogo. Foi executado com Python 3.12 do runtime Codex e `zstd.dll` já presente nesse runtime.

Cada amostra informa arquivo e caminho completos no mapa original. Para `Part`, `WedgePart` e `CornerWedgePart`, a combinação `CFrame`, `size`, `Color3uint8` e `shape` permite montar uma referência fiel das formas primitivas. `CFrame` contém doze números na ordem usada por `CFrame.new`: posição XYZ seguida da matriz de rotação 3×3 em linhas. Cores são RGB de 0 a 255. As coordenadas ainda são as originais do mapa; centralize a amostra ao visualizar.

As quatro amostras de `2.rbxlx` são `MeshPart`. Seus IDs e tamanhos são referências, **não são a geometria**. Uma caixa com o tamanho do MeshPart não demonstra sua aparência. Para vê-las, carregue os IDs autorizados no Studio em uma pasta temporária, sem scripts, ou use uma cópia separada do mapa. O catálogo final deve usar modelos próprios do Blender.

Seleção inicial:

- `MeuMapa.rbxlx`: árvore de campo com copa verde, árvore seca ramificada, cacto, árvore nevada, árvore de copa rosa, árvore tropical, sakura, conjunto de pedras e tufo de grama. Esses modelos são predominantemente feitos de primitivas.
- `2.rbxlx`: flor luminosa e cogumelo da árvore encantada; samambaia da bananeira e arbusto de Zone12Props.
- `place 114326934417838 Quebrar e Roubar um Ovo.rbxl`: inventariado; repete boa parte das decorações Zone1–Zone8 presentes em `MeuMapa.rbxlx`, além de árvores alienígenas em MeshParts. Não foi duplicado nas amostras.

As paletas são dados extraídos; a escolha estética final exige observar as referências. Nenhum mapa completo foi aberto, nenhum script de origem foi executado e nenhum lugar foi alterado durante esta extração.
