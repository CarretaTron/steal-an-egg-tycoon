# Arte das bases

Novo visual das oito bases: pavilhão de jardim com pilares creme e arenito, cercas de madeira em mel, travessas cruzadas, bordas turquesa, teto de vidro com colisão e portal com ovo, moldura dourada e sete feixes vermelhos. O interior continua livre para as máquinas e habitats do jogador. O laser aparece após reivindicar o terreno.

As duas referências de cercas dos mapas locais foram reconstruídas e vistas. Não foi encontrada uma base laser nesses mapas; o portal é original. A extração de dados não executou scripts das referências. Consulte `Referencias/README.md` e `Referencias/bases-referencia.json` para origem, paletas e dimensões.

## Fontes e integração

- **Fonte oficial:** `Shared/BaseShell.luau`, na branch `codex/bases-laser`. A integração foi feita no checkout isolado da tarefa, preservando a versão recente do jogo e as mudanças de Client/HudGuide já abertas no Studio.
- `ArteBases/BaseShell.luau` é uma cópia de projeto para consulta. Altere o fonte oficial e mantenha esta cópia correspondente; não trate as duas como implementações independentes.
- `verify_base_shell.luau` contém as conferências estruturais da arte em clones no modo Editar; não é um ensaio automático para o jogo normal.
- O módulo aplica `BaseShellRevision = 2`, com 133 peças por base, e mantém os nomes usados pela segurança. A reaplicação foi conferida para não duplicar a estrutura.

A troca preserva os oito pivôs, pisos e conteúdos, além das instâncias Battery, Claim e OwnerSign usadas pelos sistemas. Não substitua esses objetos por cópias visuais sem preservar seus contratos. O portal continua ligado à reivindicação e à bateria do projeto.

## Entrega e validação

Os RBXM, snapshots de mapa, imagens e relatório estão em `Resultados/BasesLaser/`; o portátil foi atualizado nessa branch. O catálogo de árvores permanece separado, restaurado no Studio depois da captura do mapa principal.

Foram aprovadas 2.651 asserções estruturais em dois clones e 118 da apresentação pelo módulo Combat real em clone isolado, incluindo três raycasts até a bateria. Foram preservadas 1.329 peças existentes fora da estrutura e os oito pivôs. Os backups de 25 fontes e dos plots anteriores estão em `Backups/AntesBaseLaser/`.

Não houve Play, reinício, clientes ou DataStore nesta etapa. `ModeloBaseLaser.rbxm` é somente uma prévia com `OwnerUserId = -1` e lasers ligados, sem jogador real; não é uma base funcional. `PlotsLaser.rbxm` é um snapshot de restauração: compare antes de substituir, sem duplicar os oito terrenos existentes.
