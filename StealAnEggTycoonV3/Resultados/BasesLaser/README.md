# Bases com portal a laser

O novo visual já foi aplicado aos **oito terrenos no Studio**, em modo Editar: pilares creme e arenito, cercas de madeira em mel com travessas cruzadas, bordas turquesa, placa com moldura dourada e um ovo no portal. O teto de vidro quase transparente mantém a cobertura com colisão. A entrada tem sete feixes vermelhos; o laser fica oculto no terreno livre e ativa depois da reivindicação da base.

A inspiração veio das duas cercas reconstruídas e vistas dos mapas locais. Não havia uma base laser nesses arquivos; o portal é arte original adaptada ao funcionamento do projeto. Cada base usa `BaseShellRevision = 2` e 133 peças de apresentação.

## Arquivos

| Arquivo | Uso |
|---|---|
| `PlotsLaser.rbxm` | Snapshot dos oito terrenos. Para restauração, compare com a versão atual antes de substituir; não importe por cima dos oito plots existentes. |
| `ModeloBaseLaser.rbxm` | Prévia visual isolada, com `OwnerUserId = -1` e lasers acesos. Esse valor é uma fixture, sem jogador real. **Não use como uma base funcional do jogo.** |
| `SnapshotMapa/AuthoredMap.rbxm` | Snapshot nativo do mapa em Editar. |
| `SnapshotMapa/scene.json` | Dados estáticos do mapa usados para montar a entrega portátil. |
| `SnapshotMapa/scene.json.zstd` | Cópia comprimida para transferência. |
| `antes.jpg`, `depois.jpg`, `referencias.jpg` | Evidências visuais do antes/depois e das referências reconstruídas. |
| `validacao-studio.json` | Resultados e limites da validação em Editar. |

O fonte oficial é `Shared/BaseShell.luau`, na branch `codex/bases-laser`; consulte também `ArteBases/README.md`. O portátil dessa branch foi atualizado preservando a continuação recente dos sistemas e as mudanças de Client/HudGuide já existentes no Studio. O catálogo de decoração continua em sua entrega `.rbxm` separada; foi removido do Workspace apenas durante a captura principal e restaurado em seguida.

## Conferências realizadas

- 2.651 asserções estruturais em dois clones, incluindo limites, cobertura, entrada e reaplicação sem duplicar a estrutura.
- 118 asserções da apresentação pelo módulo Combat real em clone isolado, incluindo três raycasts até a bateria.
- 1.329 peças existentes fora da estrutura preservadas; os oito pivôs permaneceram iguais. Mantidos os pisos e suas transformações, tamanhos e cores, além da identidade de Battery, Claim e OwnerSign e dos conteúdos dos terrenos.
- Serialização nativa de ida e volta aprovada. Os backups anteriores estão em `Backups/AntesBaseLaser/`, com 25 fontes e `PlotsAntes.rbxm`.

Não foram executados Play, reinício do Studio, clientes, DataStore nem um ciclo real de combate ou roubo. As verificações geométricas usam amostras e não substituem um teste de caminhada.

O arquivo `StealAnEggTycoonV3.rbxlx` nesta pasta é a cópia completa do portátil atualizado desta branch; pode ser aberto como lugar separado. Não substitui o lugar conectado nem publica a experiência automaticamente.
