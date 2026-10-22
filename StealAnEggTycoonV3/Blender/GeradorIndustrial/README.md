# Gerador industrial

Modelo original criado no Blender a partir da referência fotográfica do proprietário: carcaça verde, chassi cinza, portas de manutenção, grelhas de ventilação, dobradiças, puxadores e acabamentos com studs que acompanham a estética das bases. Não inclui marcas ou logotipos reais.

O conjunto tem **sete malhas, 4.072 vértices e 7.452 triângulos**. As dimensões de projeto são aproximadamente **12 × 7 × 6 studs**. A origem fica no chão, no centro do gerador; a frente aponta para Roblox `-Z`. Os dados JSON usam Roblox Y para cima; o Blender usa a conversão `[X, -RobloxZ, RobloxY]`.

## Arquivos

| Arquivo | Uso |
|---|---|
| `build_generator.py` | Gerador reproduzível; cria uma cena nova e preserva as cenas anteriores |
| `GeradorIndustrial.blend` | Cena de criação do modelo |
| `Exportacoes/GeradorIndustrial.fbx` | Sete malhas visuais para o Importer do Studio |
| `geometry.json` | Vértices, triângulos, cores e limites de cada malha |
| `installation-spec.json` | Definição compacta de materiais, limites e painel nativo |
| `roblox-assets.json` | IDs permanentes das malhas transferidas ao Roblox |
| `gerador-blender.png` | Render do modelo no Blender |
| `Generator.luau`, `GeneratorData.luau` | Cópias de transporte dos fontes usados na instalação |

Os fontes oficiais são **`Shared/Generator.luau` e `Shared/GeneratorData.luau`** no checkout atual `C:/Users/alexp/.codex/worktrees/bases-laser/Roblox aura/StealAnEggTycoonV3`. Edite esses fontes antes de atualizar cópias de entrega. A pasta original `D:/Roblox aura` conserva trabalho anterior separado.

## Grupos de malha

- `GI_CarcacaVerde`: gabinete e portas verdes.
- `GI_ChassiCinza`: base, suportes e console.
- `GI_GrelhasEscuras`: recessos, ventilação e componentes escuros.
- `GI_Ferragens`: dobradiças, travas, puxadores e fixadores metálicos.
- `GI_MoldurasClaras`: borda física clara do painel.
- `GI_RelevosVerdes`: aletas, bordas e relevos verdes.
- `GI_DetalhesAmarelos`: marcações discretas de atenção ao lado do console.

A importação FBX foi feita com escala **0,01**. A transformação registrada nos dados de instalação aplica a correção de orientação **yaw π**. Não aplique novamente essa rotação às peças já instaladas. As malhas visuais usam IDs permanentes; a peça de acerto e o painel são objetos nativos do Studio.

## Painel de vida integrado

O painel substitui a tampa superior frontal. Seu centro relativo à origem do modelo é `(0, 6.2, -1.85)`, com tamanho `(7.6, 2.4, 0.14)` e rotação X de **+55°**. A interface usa a face `Front`; a normal aponta para a frente e para cima, permitindo ler o visor do lado externo da base.

A `SurfaceGui` usa **FixedSize**, canvas **1024 × 320** e fonte de **90 pixels** para a contagem de vida. As informações aparecem diretamente na superfície física do painel, sem legenda flutuante. O texto verdadeiro, a vida e o estado de reconstrução são criados e atualizados pelo servidor; a geometria e o texto de demonstração da cena Blender não calculam vida nem dinheiro.

O retângulo de tela e os textos da coleção de prévia são referências visuais e **ficam fora do FBX**. Não importe essa prévia junto com o painel nativo já instalado. Preserve a identidade da peça `Battery` e a autoridade do servidor ao ajustar o visual. Os arquivos e backups das versões anteriores permanecem preservados.

## Apoio no chão — revisão 3

Generator mede o piso externo com raycast, ignorando terrenos/máquinas, guardiões, ninhos e personagens. A origem das sete malhas e do painel e a hitbox Battery compartilham esse apoio. O mapa autoral tinha o piso interno em Y1 e a grama em Y0; a revisão anterior herdava um vão de 1 stud. A geometria Blender já tinha a origem no chão e foi preservada. Sem superfície válida, mantém a pose anterior.
