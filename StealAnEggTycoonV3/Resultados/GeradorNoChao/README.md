# Geradores apoiados no chão

Correção de Generator revisão 3. A montagem anterior usava a altura do piso interno (Y1), deixando os pés 1 stud acima da grama (Y0). Agora um raycast mede o apoio e posiciona Battery, sete malhas e painel juntos. A geometria Blender, IDs, identidade da Battery, X/Z, rotação e HP foram preservados.

- `StealAnEggTycoonV3.rbxlx`: projeto completo atualizado, com os 28 fontes incorporados.
- `AuthoredMap.rbxm` e `scene.json`: captura do modo Editar; 2.974 instâncias e 201 MeshParts permanentes.
- `Generator.luau`: cópia do fonte oficial Shared/Generator.luau revisão 3.
- `PlotsAntes.rbxm`: backup antes do ajuste.
- `validacao-studio.json`: 320 verificações nas oito bases e 68 em quatro montagens sintéticas (básica sem Parent, autoral, elevada e sem apoio). Inclui reconstrução e idempotência.
- `validacao-play-leitura.json`: leitura do servidor durante Play iniciado pelo usuário; oito geradores com pés em Y0. O agente não iniciou nem interrompeu o teste.
- `validacao-portatil.json`: 201 malhas preservadas no XML e 96 conferências de alinhamento nos snapshots. `verify_package.py` confirmou os 28 fontes/cópias, V2 preservada e oito ensaios desativados.

Nenhum teste geral de combate, perfil, múltiplos clientes ou FPS foi realizado nesta correção. O portátil foi conferido por XML, sem abrir uma segunda sessão do Studio. Sem superfície válida, a montagem mantém a pose anterior.

Fonte editável no checkout bases-laser: `C:/Users/alexp/.codex/worktrees/bases-laser/Roblox aura/StealAnEggTycoonV3/Shared/Generator.luau`. O WIP anterior de `D:/Roblox aura` permanece separado. Arte Blender/FBX está em Blender/GeradorIndustrial/ e não foi remodelada nesta revisão.

GitHub: https://github.com/CarretaTron/steal-an-egg-tycoon/pull/3
Registro: coordination/tasks/2026-10-22-codex-a-gerador-chao.md
