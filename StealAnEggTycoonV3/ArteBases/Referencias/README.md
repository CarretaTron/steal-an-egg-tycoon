# Referências de bases

Esta pasta contém somente a inspeção de propriedades visuais dos três mapas locais em `Mapas open source/`. A leitura usa o parser limitado de `Blender/Decoracao/Referencias/extract_reference_samples.py`; não executa scripts, módulos, UI, pacotes ou sistemas desses lugares. Os originais ficam intactos e não são publicados por esta tarefa.

## Amostras reconstruíveis

`bases-referencia.json` guarda duas amostras compostas inteiramente de primitivas. As translações de CFrame foram recentradas; Y=0 representa o ponto inferior. As matrizes de rotação, tamanhos, paletas, materiais e transparências foram preservados como dados de referência.

| Amostra | Origem | Peças visíveis | Dimensões X × Y × Z |
|---|---|---:|---|
| Curral_portao_madeira | `2.rbxlx`, `Workspace/Plots/7/ToUpdate/StarterPen` | 128 | 53,50 × 4,00 × 53,50 |
| Base_grama_degraus_cerca | `MeuMapa.rbxlx`, `Workspace/Plots/Base_7/Build` | 41 | 55,39 × 5,94 × 44,47 |

A primeira amostra tem cercas, pilares escuros e um portão de duas folhas; usa madeira em RGB 162/81/0 e 86/66/54. A segunda apresenta piso de grama verde, solo em camadas, degraus na entrada e cerca de madeira; a paleta principal é RGB 109/225/0, 112/78/39, 170/109/55 e 121/69/16. O arquivo `place 114326934417838 Quebrar e Roubar um Ovo.rbxl` contém a mesma estrutura visual de bases de `MeuMapa.rbxlx`.

Não há MeshParts ou Unions nas duas amostras selecionadas. A extração não afirma que malhas externas de outros modelos foram vistas. Os hashes e quantidades dos três arquivos de origem estão no inventário JSON.

## Lasers

A varredura não encontrou peças Neon visíveis dentro dos plots nem objetos nomeados Laser/Barrier nas bases. Os três arquivos têm sete plots cada. Também foram examinados os modelos de bases, portas e templates em ReplicatedStorage/ServerStorage: `PlotUpgrades` reutiliza a cerca com jardim; as portas restantes pertencem a casas de Halloween/incubadoras.

Os nomes de laser encontrados são de outros conteúdos:

- `2.rbxlx`: `ReplicatedStorage/Assets/Particles/ScrambleBossVFX/MechBoss/LaserPillar`, `LaserBeam` e `LaserSweep`; UI e módulos de eventos também mencionam laser.
- `MeuMapa.rbxlx`: `ReplicatedStorage/Trails/Laser_Trail`.
- `place 114326934417838 Quebrar e Roubar um Ovo.rbxl`: `ReplicatedStorage/Trails/Laser_Trail`.

O novo portão a laser do projeto pode combinar a inspiração arquitetônica dessas referências com sua própria arte, mantendo os contratos de segurança do jogo. Esta inspeção não deve ser citada como visualização de uma base laser que não foi encontrada nos arquivos.

## Reproduzir a inspeção

Execute `inspect_base_references.py` com Python 3.12 e `zstd.dll` disponível. O script lê os três mapas, gera o inventário e extrai apenas as duas amostras selecionadas. Nenhuma escrita é feita nos mapas de origem ou no Studio.
