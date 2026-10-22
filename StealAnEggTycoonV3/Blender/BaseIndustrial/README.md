# Base industrial modelada no Blender

Modelo original feito a partir das três prints fornecidas pelo proprietário: estrutura cinza com studs, janelas largas com moldura branca, cobertura sólida, placa de madeira e uma fachada com lasers vermelhos. A cerca cruzada dos mapas locais aparece somente como uma faixa discreta abaixo das janelas. Não foram importados scripts ou sistemas dos mapas de referência.

O visual foi modelado no Blender e transferido pelo FBX/Importer do Studio. São **sete malhas, 13.440 vértices e 20.688 triângulos**. Os studs da cobertura e do forro fazem parte da mesma malha `Roof`, para o recorte visual do teto continuar funcionando como um único objeto.

## Arquivos de criação

| Arquivo | Conteúdo |
|---|---|
| `build_base.py` | Gerador reproduzível; cria uma cena nova e recusa uma cena existente com o mesmo nome |
| `BaseIndustrial.blend` | Cena de criação, com as cenas anteriores preservadas |
| `Exportacoes/BaseIndustrial.fbx` | Sete malhas visuais destinadas ao Importer |
| `geometry.json` | Vértices, triângulos, cores, limites e plano das peças nativas |
| `installation-spec.json` | Definição compacta da instalação, sem os vértices e triângulos |
| `base-blender.png` | Render da prévia no Blender |
| `BaseShell.luau`, `BaseIndustrialData.luau` | Cópias de transporte dos fontes usados na instalação |
| `verify_base_shell.luau` | Ensaio estrutural executável em clones no modo Editar |

Os fontes oficiais são **`Shared/BaseShell.luau` e `Shared/BaseIndustrialData.luau`**, no checkout atual `C:/Users/alexp/.codex/worktrees/bases-laser/Roblox aura`. Edite esses fontes antes de regenerar as cópias de entrega; o checkout antigo em `D:/Roblox aura` conserva trabalho anterior ainda não integrado.

## Transferência e montagem

O Blender usa Z para cima. O JSON guarda coordenadas Roblox `[X, Y, Z]`, obtidas de `[Blender X, Blender Z, -Blender Y]`, em studs, com pivô na origem. A transferência final usa IDs permanentes de malha gerados pelo Importer, registrados em `BaseIndustrialData.luau`.

O módulo `BaseShell`, revisão 3, combina as sete malhas visuais com peças nativas para colisões, vidro, lasers, luminárias e degraus. As malhas decorativas não calculam colisão ou dano. O portal tem 140 × 25 studs e 35 feixes; o caminho central de 16 studs e a grade de construção continuam livres. Piso, pivô, bateria, placa e conteúdo dos jogadores mantêm suas identidades; a cor dos oito pisos foi ajustada para cinza.

As peças de prévia de piso, placa/texto, lasers, degraus e luminárias existentes na cena Blender não entram no FBX; são referências para os objetos nativos do Studio. Não importe essas prévias junto com os objetos já instalados.

O exportador do mapa preserva as novas MeshParts estáticas com seus IDs e tamanho inicial. Não substitua as malhas por caixas nem remova os studs para contornar problemas de exportação. A entrega nativa está em `Resultados/BaseIndustrial/`.

## Verificação e limites

Foram executadas 1.846 verificações estruturais em clones e 1.688 de apresentação, preservação e compilação em Editar. Os 26 fontes compilaram, os 23 fontes anteriores fora dessa troca ficaram iguais e sete malhas foram carregadas por uma instância nova do módulo. Preservadas 1.321 peças fora dos pisos; os oito pisos mantiveram transformação, tamanho e identidade, com a mudança de cor intencional.

Esses resultados não são um teste de caminhada, combate real, toque ou desempenho. Não houve Play, reinício do Studio, dois clientes ou acesso a perfis nesta etapa. A experiência Roblox não foi publicada.

O filtro de seleção do Client ignora RoofCollision para alcançar máquinas por cima do teto. Três raios em Edit confirmaram a correção e a preservação do bloqueio de combate; não foi um teste de clique ou toque em Play.
