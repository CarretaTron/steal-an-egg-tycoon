# Gerador industrial com painel de vida

Oito bases recebem gerador original verde/cinza modelado no Blender, com grelhas, portas, ferragens e studs. Sete malhas por modelo,4.072 vértices/7.452 triângulos. A SurfaceGui fica presa ao console superior inclinado: vida, barra, nível ativo e reconstrução aparecem diretamente no painel. Sem legenda flutuante de bateria.

- StealAnEggTycoonV3.rbxlx: portátil completo com28 fontes e mapa atual.
- BasesComGeradores.rbxm e Mapa/: capturas nativas dos oito terrenos/cenário.
- PreviaGerador.rbxm: modelo isolado de demonstração, OwnerUserId=-1. Não usar como terreno funcional.
- PlotsAntes.rbxm: snapshot anterior para recuperação.
- previa-studio.jpg e Blender/GeradorIndustrial/gerador-blender.png: prévias visuais.
- validacao-studio.json, validacao-pacote.json e validacao-portatil.json: evidências e limites.
- combat-harness.luau e validacao-combate-mocks.json: reprodução do teste existente com mocks; não valida arte/física.
- manifesto-entrega.json e manifesto-fontes.json: hashes e tamanhos.
- Transferencia/: buffers comprimidos usados na exportação.

Battery conserva identidade/posição; agora é hitbox invisível de 12 × 7 × 6. As malhas e painel não interceptam raios. HP e níveis são servidor; melhorias durante invasão só aparecem após reconstruir. A visibilidade por propriedade foi preservada: geradores ficam ocultos nos terrenos livres.

Instalação:208 verificações em Edit. Comportamento:24 verificações com Combat real em clones e365 do harness com mocks lexicais hospedado em Edit. Os28 fontes compilaram. Sem Play, perfis, dois clientes, física real ou medição de desempenho. CLI Luau standalone não disponível. Nenhuma publicação da experiência.

Criação completa em Blender/GeradorIndustrial/. Backups em Backups/AntesGeradorIndustrial/. Checkout atual C:/Users/alexp/.codex/worktrees/bases-laser/Roblox aura. A pasta D:/Roblox aura preserva WIP antigo; não substituir os fontes do checkout atual por eles.
