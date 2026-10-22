# Avenida compacta — entrega vigente

Oito tycoons em quatro pares, portas para a rua central conforme a imagem anotada. Bases padrão reduzidas de 160 para 144 × 144 studs (10%). Centros X±190, Y1, Z440/684/928/1172. Entrada dos biomas 340 studs mais próxima que na primeira avenida. Cem decorações existentes do Blender reaproveitadas; arquivos de criação preservados.

Abra `StealAnEggTycoonV3.rbxlx` para o projeto completo. `AuthoredMap.rbxm` e `scene.json` capturam o mapa final, com 3.952 instâncias, seis raízes e 675 malhas permanentes. `Fontes/` é cópia de entrega dos 28 fontes; os editáveis ficam em Client/Server/Shared no checkout bases-laser. Não substitua um mundo aberto pelo RBXM sem comparar e preservar suas edições.

Máquinas, criaturas, gerador e grade de quatro studs mantêm as medidas. BaseShell revisão 5 adapta a casca e move gerador/painel juntos, apoiados no chão. Construção, HUD, claim, entrega, roubo e laser acompanham o tamanho efetivo. Layout antigo que precise do espaço/reserva/acessibilidade de 160 studs conserva essa dimensão durante a ocupação; IDs, posições, inventário e circuitos não são convertidos. Ao vagar, a base volta a 144.

Rua de 32 studs e acessos de 20. Corredor seguro X±90, Z1260..2610; rua entre bases permite PvP. Piso contínuo em dois tiles até Z1340, sem eixo de Part acima de 2048. Bases padrão deixam 100 studs entre si; portas vizinhas/opostas equivalem a 13,6/13,1 s estimados a 18 studs/s. Uma base legada de 160 pode diminuir essa margem, sem sobrepor os pisos. Paredão afastado mais 40 studs para liberar a última fileira.

## Evidências

- `validacao-studio.json`: 3.563 verificações, 56 rotas simuladas, 200 amostras do piso, 28 fontes compilados, dois layouts legados sintéticos preservados e zero interseções com paredões. Exercita os módulos reais de estado/defesa com perfis, personagens e visuais de máquinas simulados.
- `validacao-combate-mocks.json`: harness existente passou 365 verificações com mocks lexicais hospedados no Studio Edit. Fixtures legados de 160; CLI standalone indisponível.
- `validacao-portatil.json`, `validacao-pacote.json`: 675 malhas preservadas no XML, oito bases, cem decorações, 28 fontes iguais, V2 preservada e oito ensaios desativados.
- `previa-geral.jpg` e `previa-portas.jpg`: vistas da composição compacta, capturadas antes do afastamento final de 40 studs do paredão. A disposição das bases não mudou depois delas.
- `AntesAjusteParedao/`: tentativa preservada antes do afastamento final; não é a entrega vigente.

Sem Play, DataStore, perfis reais, dois clientes, celular físico ou FPS nesta etapa. Ensaios históricos de navegação circular continuam desativados e precisam de atualização antes de certificar este cenário.

`arrange_avenue.luau` exige o backup circular original ou retorna se já instalado. `compact_avenue.luau` migra a primeira avenida para a revisão 2. São operações explícitas de Edit e dependem dos módulos/backup carregados pelo responsável; não devem rodar na inicialização. `verificar-compacto.luau` usa o estado anterior da mesma sessão. `combat-harness.luau` usa apenas mocks lexicais.

Histórico maior em Resultados/MapaFileiras/. Backups em Backups/AntesMapaCompacto/ e AntesMapaFileiras/. Checkout: C:/Users/alexp/.codex/worktrees/bases-laser/Roblox aura; WIP antigo de D:/Roblox aura preservado. Registro: coordination/tasks/2026-10-22-codex-a-mapa-fileiras.md. GitHub: https://github.com/CarretaTron/steal-an-egg-tycoon/pull/3.
