# Tarefa: gerador industrial com painel de vida

| Campo | Valor |
|---|---|
| Status | done |
| Responsável | codex-a, sessão principal |
| Branch | codex/gerador-painel-vida |
| Commit de partida | 1907492 |
| Pedido autorizado | Modelar gerador no Blender conforme foto, com HP diretamente no painel físico e substituir os geradores das oito bases |

## Escopo e arquivos

Nova arte original verde/cinza compatível com as bases. Painel SurfaceGui incorporado no lugar da tampa, sem Billboard flutuante. Preservar autoridade de HP, melhorias, reconstrução e propriedade. Fonte Battery continua identificável para combate.

Blender/GeradorIndustrial/, Shared/Generator.luau e dados, integração de BaseShell/WorldFactory/Combat conforme contratos; Map/, pacote e registros. Preservar revisão anterior em backup. Não implementar recursos fora deste pedido.

## Sessões

Studio 330 fe260-7 f84-4510-873 a-e7721707 f8 e0, lugar119288590672557: root único mutador, em Edit. Blender: root único mutador em cena/arquivo novos. Agentes auxiliam apenas novos arquivos de arte e leitura de contratos. Sem iniciar/parar Play, perfis ou dados de jogadores.

Checkout atual gerenciado bases-laser. WIP antigo de D:/Roblox aura permanece separado. Comparar fontes no Studio antes de aplicar. Registro publicado antes das mutações.

## Entrega e validação

- Gerador original Blender:7 malhas,4072 vértices/7452 triângulos; FBX importado de fato com escala.01 e correção de eixos registrada em GeneratorData. Cena anterior preservada. Template em ServerStorage/GeradorIndustrial_FBX.
- Generator.luau revisão2: montagem idempotente, malhas permanentes, hitbox invisível original12 ×7 ×6, painel SurfaceGui FixedSize1024 ×320 e fonte HP 90. Zero BillboardGui de bateria. Apresentação por propriedade e dados do servidor.
- Integração em BaseShell antes do early-return cobre mapa existente e geração nova. WorldFactory remove a criação da legenda antiga. Combat delega Present/Update, mantendo HP, níveis ativos, melhoria adiada e reconstrução.
- Exportador preserva LightInfluence0 no visor. Tests/combat_offline.py atualizado para dependência Generator via recording stub e contratos do mapa Blender atual. O teste não simula arte.
- Fontes lidos do Studio e iguais aos locais antes de editar. Alterados somente BaseShell, WorldFactory e Combat; criados Generator/GeneratorData. Battery e Floor mantêm identidades, posições e pivôs.
-208 verificações de instalação em oito bases,24 do Combat real em clones com jogadores simulados; dano180/200, melhoria adiada, brecha0/200, reconstrução450/450, vacância/retomada e raio acertando Battery através das malhas.28 fontes compilados.
- Harness existente passou365 verificações com mocks lexicais via loadstring em Studio Edit. CLI standalone indisponível; execução não certifica gráficos/física/replicação.
- Mapa capturado com2974 instâncias, oito raízes,201 MeshParts; pacote e201 malhas/visores conferidos. Entrega Resultados/GeradorIndustrial/; criação Blender/GeradorIndustrial/; backups AntesGeradorIndustrial/. Prévia isolada removida antes de capturar.
- Sem Play, perfis, dados persistentes, dois clientes ou FPS. Sem publicação da experiência. Studio liberado em Edit; oito ensaios desativados. Blender na cena nova. WIP original preservado.
- Branch será enviada e integrada por avanço simples ao PR #3/codex/bases-blender. CHANGELOG e ESTADO_ATUAL atualizados.
