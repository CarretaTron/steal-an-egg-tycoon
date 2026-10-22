# Bases industriais — entrega

As oito bases do Studio receberam um modelo original criado no Blender, seguindo de perto as prints do proprietário: casco cinza com studs, janelas largas brancas, teto sólido, placa de madeira e uma fachada com **35 lasers vermelhos**. A cerca de madeira cruzada aparece como detalhe baixo e discreto. O portal mede 140 × 25 studs; terrenos livres mantêm os lasers desligados.

Cada base usa **68 peças**, incluindo sete MeshParts permanentes. A estrutura vem pronta, e as máquinas continuam livres para construir e mover. A bateria e os sistemas de propriedade e proteção continuam decididos pelo servidor.

## Arquivos

| Arquivo ou pasta | Uso |
|---|---|
| `BasesIndustriais.rbxm` | Snapshot nativo dos oito terrenos atualizados |
| `PreviaBaseIndustrial.rbxm` | Demonstração visual isolada com lasers acesos; usa `OwnerUserId = -1`, sem jogador real, e não deve ser usada como terreno funcional |
| `Mapa/AuthoredMap.rbxm` | Snapshot nativo do cenário capturado no modo Editar |
| `Mapa/scene.json` | Dados estáticos usados para montar o portátil, incluindo MeshParts com IDs permanentes |
| `validacao-studio.json` | Resultados e limites da conferência no Studio |
| `StealAnEggTycoonV3.rbxlx` | Projeto portátil atualizado com os 26 fontes e o mapa |
| `previa-studio.jpg` | Captura da demonstração visual isolada |
| `validacao-pacote.json`, `validacao-meshes-portatil.json`, `validacao-meshes-sintetica.json` | Verificações do pacote e das malhas |
| `manifesto-entrega.json` | Tamanhos e hashes dos fontes/artefatos principais |
| `Transferencia/` | Arquivos comprimidos usados na passagem dos dados do Studio para o disco |

O mapa capturado tem oito raízes e 2.838 instâncias. Inclui 153 MeshParts estáticas: 56 das oito bases e 97 do catálogo de decoração. A geometria não foi descartada ou substituída por blocos; os dados de tamanho inicial das malhas foram preservados no caminho de exportação.

Os arquivos de criação estão em `Blender/BaseIndustrial/`: cena `.blend`, gerador Python, FBX, geometria, definição compacta e render. Os fontes oficiais são `Shared/BaseShell.luau` (revisão 3) e `Shared/BaseIndustrialData.luau`, no checkout atual `C:/Users/alexp/.codex/worktrees/bases-laser/Roblox aura`.

Para restaurar um snapshot, compare-o com a cena atual e preserve a versão anterior. Não importe os oito terrenos por cima de outros oito terrenos existentes. A prévia isolada serve para examinar o visual e não substitui a montagem funcional do projeto.

## Conferências realizadas

- 1.846 verificações estruturais em clones no modo Editar.
- 1.688 verificações de apresentação, preservação e compilação; 26 fontes compilados, com 23 fontes anteriores preservados.
- Carregamento de sete malhas por uma instância nova de `BaseShell`.
- Preservadas 1.321 peças fora dos pisos. Os oito pisos mantiveram transformação, tamanho e identidade; sua cor mudou intencionalmente para cinza.

As malhas visuais são não colidíveis. Paredes, vidro e cobertura têm colisões próprias; o acesso central para construção permanece livre. Os studs do teto pertencem à mesma malha `Roof`, preservando seu recorte visual.

Não houve Play, reinício, dois clientes, acesso a perfis ou medição de FPS. As verificações em Editar não certificam caminhada, combate ou interface em execução. O portátil atualizado acompanha esta entrega: 26 fontes/cópias idênticos, V2 preservada e oito ensaios desativados. As 153 malhas foram conferidas no XML final, sem abri-lo numa nova sessão do Studio. A experiência Roblox não foi publicada.

O filtro de seleção do Client ignora RoofCollision para alcançar máquinas por cima do teto. Três raios em Edit confirmaram a correção e a preservação do bloqueio de combate; não foi um teste de clique ou toque em Play.
