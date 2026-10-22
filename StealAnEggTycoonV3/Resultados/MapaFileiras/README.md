# Avenida de tycoons

Mapa reorganizado a partir da referência fornecida pelo usuário. Oito bases em quatro pares, com as portas voltadas para a rua central, conforme a imagem anotada. A praça circular e o spawn central continuam na frente; biomas e entrada de expedição ficam ao fundo.

## Abrir

- `StealAnEggTycoonV3.rbxlx`: projeto completo atualizado, com os 28 fontes incorporados.
- `AuthoredMap.rbxm`: snapshot nativo do modo Editar; não importar sobre um mundo existente sem comparar/preservar o conteúdo.
- `scene.json`: entrada do empacotador, com 3.952 instâncias e 675 malhas permanentes.
- `Fontes/`: cópias dos fontes entregues. Edite os oficiais em Shared/Server/Client antes de empacotar novamente.
- `referencia-layout.png`, `previa-geral.jpg`, `previa-portas.jpg`: referência e capturas reais do Studio.

## Layout

Centros X=-230/+230, Y=1; Z=500,780,1060,1340. Terrenos de 160 × 160 studs, distantes pelo menos 120 studs. Portas opostas distam 300 studs; portas vizinhas da mesma fileira, 280. Estimativa a 18 studs/s carregando: 16,7 s e 15,6 s, sem cronometragem em jogo. Rua de 32 studs, acessos de 20; biomas/ninhos/guardiões deslocados 1.000 studs. Rua permite PvP; corredor seguro agora em X±90, Z1600..2950.

Cem cópias de modelos já criados no Blender: 32 árvores, 40 arbustos, 16 flores e 12 pedras. Catálogo e arquivos de criação preservados. Vinte cópias de módulos existentes alongam o paredão. Chão em duas peças adjacentes para respeitar o limite de 2.048 studs por eixo.

## Evidências

- `validacao-studio.json`: 6.095 verificações em Edit, 56 rotas de roubo simuladas, 95 amostras de continuidade do chão, 28 fontes compilados. Confere orientação, preservação dos conteúdos locais, apoio dos geradores e idempotência. Isso não simula uma partida entre jogadores.
- `validacao-portatil.json`: 675 malhas comparadas ao XML, oito bases/100 decorações e todos os eixos de peças dentro do limite.
- `validacao-pacote.json`: fontes/cópias/portátil consistentes, V2 preservada e oito ensaios desativados.
- `Antes/`: captura do Studio antes da tarefa, preservando também alterações manuais que ainda não constavam no mapa versionado.

Sem Play, perfis, dois clientes, dispositivo móvel físico ou medição de FPS nesta etapa. Ensaios históricos com navegação circular permanecem desativados e precisam de atualização antes de certificar este cenário.

`arrange_avenue.luau` é uma operação explícita de Edit, não roda no jogo e exige backup/configuração carregados pelo responsável. `verificar-layout.luau` usa as referências anteriores guardadas pela montagem na mesma sessão; não é um teste independente para um servidor em execução.

Checkout atual: C:/Users/alexp/.codex/worktrees/bases-laser/Roblox aura. WIP antigo de D:/Roblox aura preservado; esta entrega tem pasta nova. Registro: coordination/tasks/2026-10-22-codex-a-mapa-fileiras.md. GitHub: https://github.com/CarretaTron/steal-an-egg-tycoon/pull/3.
