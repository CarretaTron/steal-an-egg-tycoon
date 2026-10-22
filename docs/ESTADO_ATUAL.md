# Estado atual — 22/10/2026

## Etapa atual: gerador industrial com painel de vida

Oito geradores originais do Blender substituem as baterias visuais: carcaça verde, grelhas, portas, ferragens e chassi cinza com studs. Console superior inclinado com SurfaceGui 1024 × 320: vida em números grandes, barra, nível ativo e contagem de reconstrução. As legendas flutuantes BatteryLabel foram removidas.

Fontes: Shared/Generator.luau (revisão 2) e GeneratorData.luau, integrados a BaseShell, WorldFactory e Combat. Battery mantém identidade e posição; sua hitbox invisível de 12 × 7 × 6 recebe os ataques. As sete malhas por modelo e o painel são não físicos/sem query. Terrenos livres continuam ocultando a bateria; base ocupada mostra o modelo e visor. Dano, níveis e reconstrução são decididos pelo servidor, com melhoria adiada mostrada apenas após reconstruir.

Criação em Blender/GeradorIndustrial/; entrega atual em Resultados/GeradorIndustrial/, com portátil e fontes dos 28 módulos/scripts. Mapa com 2.974 instâncias em oito raízes, 201 malhas estáticas (48 bases + 56 geradores + 97 catálogo). LightInfluence, CanvasSize e SizingMode são preservados pelo exportador. Nenhuma malha foi convertida em caixa.

Validação em Edit: 208 verificações de instalação/identidade/idempotência; 24 de apresentação com Combat real e jogadores simulados em clones; 28 fontes compilados. O harness existente de Combat passou 365 verificações com mocks lexicais, hospedado no Studio Edit porque o CLI standalone não foi encontrado. Isso não é teste de arte, física, perfis ou clientes reais. Sem Play, dois clientes ou FPS nesta tarefa.

Registro: coordination/tasks/2026-10-22-codex-a-gerador-painel.md. Checkout gerenciado bases-laser; WIP original de D:/Roblox aura preservado. Branch da tarefa codex/gerador-painel-vida, integrada por avanço simples à codex/bases-blender/PR #3. Backups em Backups/AntesGeradorIndustrial/.

## Revisão anterior: bases sem cercas e teto sempre visível

As oito bases usam BaseShell revisão 4 e seis malhas originais do Blender: estrutura cinza com studs, janelas brancas, placa madeira, teto sólido e fachada com 35 lasers vermelhos. As faixas baixas de cerca foram removidas. Cada base tem 67 peças. O Client não possui mais o recorte local do teto: entrar ou construir mantém a cobertura visível. Colisões e filtro de seleção continuam preservados.

A versão está na branch `codex/bases-blender`, PR #3, após integrar a tarefa `codex/bases-sem-cercas-teto`. Checkout: `C:/Users/alexp/.codex/worktrees/bases-laser/Roblox aura`. O WIP antigo de D:/Roblox aura permanece separado. Entrega histórica sem cercas em `Resultados/SemCercasTeto/`, criação em `Blender/BaseIndustrialSemCercas/`, registro `coordination/tasks/2026-10-22-codex-a-sem-cercas-teto.md`.

Conferência desta revisão em Edit: 45 verificações de ausência das cercas, opacidade/colisão do teto, identidades por idempotência e reconstrução, com 26 fontes compilados. Portátil e cópias dos 26 fontes passaram no verificador, com V2 preservada e oito ensaios desativados. O mapa tem oito raízes, 2.830 instâncias e 145 malhas estáticas (48 das bases + 97 catálogo); as 145 foram comparadas ao XML final. Sem Play, perfis, dois clientes, clique/toque em execução ou FPS.

A estrutura vem pronta; máquinas, esteiras e kit manual continuam no fluxo de codex-b. Terrenos livres mantêm lasers desligados. Pisos, pivôs, bateria, placa e conteúdos permanecem preservados. O piso cinza foi introduzido na revisão anterior. A arte de revisão 3 e seus relatórios permanecem históricos em Resultados/BaseIndustrial/; backup imediato em Backups/AntesRemoverCercasTeto/. Não usar a entrega histórica para reintroduzir cercas ou recorte do teto.

O catálogo em X=1600 está incluído no mapa portátil. O exportador preserva MeshParts permanentes e InitialSize, usando colisores Part separados. O XML final não foi aberto em uma sessão nova do Studio; a experiência Roblox não foi publicada.

## Histórico: catálogo de decoração


O pedido de bases deste chat foi interrompido pelo usuário. Seus fontes locais permanecem preservados; as branches de codex-b contêm continuação posterior e não foram sobrescritas. Esta etapa adiciona somente arte e um catálogo separado, sem alterar os sistemas ou paredes do jogo.

Há vinte modelos originais do Blender prontos em `Workspace/CatalogoDecoracao/Modelos_Para_Copiar`, próximo de X=1600, e uma biblioteca limpa em `ServerStorage/BibliotecaDecoracao`. Selecione um Model, use F para enquadrar e Ctrl+D para copiar. A cena, gerador, geometria e vinte FBX estão em `StealAnEggTycoonV3/Blender/Decoracao/`; a entrega nativa e os relatórios estão em `StealAnEggTycoonV3/Resultados/Decoracao/`.

Conferência aprovada: vinte modelos, 97 malhas permanentes, 10.716 triângulos; tamanhos, cores, materiais, pivôs e ancoragem; 1.656 peças e 25 scripts anteriores preservados. Recarga por ID de três malhas e serialização nativa de ida e volta verificadas. Sem Play, reinício ou dois clientes nesta etapa. O catálogo não exige execução de scripts para copiar seus modelos.

A branch `codex-a/catalogo-decoracao-blender` entregou inicialmente a arte separadamente, preservando o checkout antigo. Essa arte já foi integrada à continuação de codex-b e ao mapa atual. A limitação inicial do exportador foi resolvida nesta etapa para MeshParts visuais permanentes; mantenha os colisores Part separados. Consulte o histórico em `coordination/tasks/2026-10-21-codex-a-catalogo-decoracao.md`.

## Histórico anterior deste checkout

A V3 jogável e a etapa de HUD estão nos arquivos existentes. O projeto completo foi publicado no repositório público https://github.com/CarretaTron/steal-an-egg-tycoon, com documentação para dois desenvolvedores usando Codex. A importação `2963104` contém 140 arquivos; um clone novo confirmou que todos chegaram idênticos e passou na verificação do pacote. Consulte também `coordination/tasks/2026-10-20-codex-a-repositorio.md`.

A tarefa anterior, na branch `codex-b/concluir-escolha-base-preview`, continuou a etapa iniciada em `codex-a/escolha-base-preview`. O usuário transferiu a continuação e forneceu um RAR com nove fontes mais recentes ainda não integrados ao pacote. Essa versão passa a nascer na praça, escolher terreno e montar o kit manualmente, com prévia do objeto real semitransparente. O mapa editado e a HUD anterior são preservados. Consulte `coordination/tasks/2026-10-21-codex-b-concluir-base-preview.md` para validações e passagem.

## Projeto preservado

O inventário anterior à criação dos documentos de colaboração contém 127 arquivos, totalizando 10.567.710 bytes, incluindo o RAR original na raiz. Naquele inventário havia 24 fontes Luau e 19 FBX de criaturas. A árvore atual possui 26 fontes, além dos vinte FBX de decoração e um FBX de base. Documentação, arte e registros posteriores aumentam o total.

| Local | Conteúdo e autoridade |
|---|---|
| `StealAnEggTycoonV3/Client/`, `Server/`, `Shared/` | Fontes editáveis da versão atual |
| `StealAnEggTycoonV3/Blender/` | Cenas e geradores de criaturas, decoração e bases; geometria, backups e FBX |
| `StealAnEggTycoonV3/Map/` | Captura do mapa editado: `AuthoredMap.rbxm` nativo e `scene.json` para empacotamento |
| `StealAnEggTycoonV3/export_authored_map.luau` | Exportação da captura após alterações manuais no mapa |
| `StealAnEggTycoonV3/StealAnEggTycoonV3.rbxlx` | Lugar portátil; a correção passa a embutir o mapa de `Map/scene.json` e renovar a arte por sessão |
| `StealAnEggTycoonV3/Resultados/` | Pacote de entrega e cópias derivadas dos fontes, arte e relatórios |
| `StealAnEggTycoonV3/Backups/` | V2 e estados anteriores preservados; não são a versão ativa |
| `StealAnEggTycoonV3.rar` | Arquivo original recebido, preservado integralmente |

O lugar conectado documentado é `119288590672557`. A V2 permanece desativada em `ServerStorage/EggTycoonV2_Backup`. Não há publicação da experiência registrada nesta entrega. O arquivo portátil não mantém o vínculo da experiência; permissões e persistência precisam de um lugar autorizado.

## Jogo existente

O ciclo é roubar ovo, fugir do guardião, levar à base, incubar, produzir, processar, vender e melhorar a base. São sete biomas e espécies, oito terrenos, construção livre em grade, habitats, incubadoras, processadores, esteiras, vendedor, bateria externa e porta a laser. A praça e o corredor são zonas sem PvP; guardiões continuam perigosos no corredor.

O kit inicial fica no inventário, sem posicionamento automático. A estrutura atual vem pronta, com a proteção da entrada dependente da propriedade e da bateria. A antiga etapa de escolha manual das defesas foi substituída pelo pedido posterior de redesenhar as bases. Construções, criaturas e defesas de perfis antigos são preservadas e restauradas somente após a escolha do terreno. Rebirth volta ao kit manual. As criaturas produzem a cada quatro segundos; a primeira venda natural de um pintinho básico é $32. Cada habitat desconectado armazena até 20 recursos. O servidor controla o percurso e o pagamento dos recursos; os objetos visuais não decidem o dinheiro.

Há combate, invasão por bateria, transporte de criatura e devolução/transferência conforme o desfecho, além de melhorias e rebirth. Habitats têm três melhorias individuais de $1.500, $7.500 e $30.000, com bônus de produção de +25%, +50% e +75%. Guardar e recolocar mantém identidade e nível.

O livro acompanha as sete descobertas. As sete missões cobrem primeiro nascimento, primeira venda, 25 recursos vendidos, três descobertas, três melhorias de habitat, bateria destruída e sete descobertas. O servidor concede peças de construção uma única vez por recompensa; missões não creditam dinheiro direto. Contadores, resgates e descobertas persistem após rebirth.

## Última etapa: HUD

O visual segue as referências enviadas: atalhos coloridos, contornos pretos, texto branco e textura de studs. O ícone de construção usa martelo; o livro fica abaixo dele. Os detalhes e as evidências estão em `StealAnEggTycoonV3/HUD.md`.

- 🔨 **Construir** aparece somente na própria tycoon; reúne máquinas, esteiras e melhorias. Sair da base fecha o menu e cancela a prévia.
- 📖 **Livro** abre as sete espécies com silhuetas bloqueadas, seleção e detalhes; habitats têm aba própria.
- ♻️ **Renascer** tem atalho próprio; o contador de rebirth acompanha o dinheiro.
- 📜 **Missões** abre objetivos e recompensas por clique. O antigo painel persistente foi removido. Abrir o menu ativa a seta de orientação, que continua após fechá-lo.
- Dinheiro verde aparece no canto inferior esquerdo, abreviado em K/M/B/T. Barras de bateria e energia foram removidas da HUD.
- Em telas móveis, atalhos usam duas colunas e alvos de pelo menos 44 pixels; menus abertos ocultam atalhos e dinheiro para evitar sobreposição.

A orientação acompanha expedição, transporte, incubação e produção. O transporte de criatura roubada recebe rota pelo anel externo, evitando a praça segura. A implementação principal dessa etapa está em `Client/Client.client.luau` e `Shared/HudGuide.luau`; o empacotador inclui o módulo novo.

O contador de rebirth fica imediatamente ao lado do texto do dinheiro, com espaço de 10 pixels. `UIListLayout` é o único responsável pelas posições; os textos usam largura natural, e o ajuste de fonte para valores grandes é cacheado por texto e viewport. Não há disputa de posição entre a atualização da HUD e o redimensionamento. A conferência visual final fica com o usuário.

## Preservação do mapa

`WorldFactory` passa a reutilizar o mapa editado em vez de reconstruir o cenário antigo a cada Play. Apenas as malhas de ovos e guardiões são renovadas por sessão. O mapa manual é preservado em `Map/AuthoredMap.rbxm`, um snapshot nativo exato que inclui paredes e objetos externos; `Map/scene.json` fornece o cenário estático e os pivôs transparentes usados para recriar a arte de sessão.

O empacotador passa a usar `scene.json`, em lugar do mapa antigo do backup, e a atualizar as cópias de fontes e mapa da entrega automaticamente. Alterações manuais futuras funcionam diretamente no Play da sessão editada, mas precisam ser reexportadas com `export_authored_map.luau` antes do empacotamento para chegarem ao GitHub e ao portátil. Nenhum backup anterior deve ser excluído.

O exportador JSON deve falhar diante de tipos não suportados, como uma Union ou uma malha decorativa que não possa representar. Não pode perder geometria ou trocar objetos silenciosamente por blocos. O snapshot RBXM conserva o conteúdo nativo enquanto o suporte do portátil é resolvido.

A comparação Edit/Play do mapa e a verificação do pacote anterior estão registradas em `Resultados/Testes/mapa-edit-play.json` e na tarefa `2026-10-20-codex-a-mapa-rebirth.md`. O teste visual final da linha dinheiro/rebirth foi assumido pelo usuário. Nesta continuação, as raízes do Workspace e os fontes foram comparados antes da aplicação; nenhum snapshot manual foi substituído.

## Arte e persistência

A arte de ovos e guardiões usa dados Blender reconstruídos com EditableMesh e convertidos pelo AssetService por sessão; essa geometria foi vista em dois clientes numa etapa anterior. Seus 19 FBX originais acompanham o projeto como alternativa. A decoração e as bases atuais foram transferidas por FBX/Importer, com IDs de malhas permanentes. O gerador de criaturas grava ao lado do script ou no caminho definido por `ET_OUT`.

Os testes do Studio usam `EggTycoonV3_DEV_v1`, separado do armazenamento LIVE. O acesso às APIs respondeu no lugar vinculado. Falhas de carregamento impedem substituir o progresso; com APIs explicitamente desativadas, há modo de sessão informado ao jogador. Incubações guardam tempo conectado restante; recursos em trânsito possuem identificação e registro de pagamento pendente; falhas de salvamento final mantêm um retrato para nova tentativa.

## Evidências já incluídas

Os relatórios estão em `StealAnEggTycoonV3/Resultados/Testes/`. Estes são resultados registrados na etapa anterior, não novos ensaios executados durante a criação do repositório:

| Evidência | Resultado documentado e limite |
|---|---|
| Integração | 31 verificações em dois clientes, incluindo venda natural de $32, replicação, bateria, roubo, morte, entrega, rebirth e recarga |
| Regressões do servidor | 98 verificações de construção, circuitos, armazenamento, pagamento único, falhas simuladas, bateria e combate; falhas usam DataStore em memória |
| Percurso validado | 13 verificações em 133,71 s; caminhada após aproximação inicial ao ovo, bateria quebrada em dez golpes e uma transferência; perfis restaurados |
| Missões | 12 verificações de progresso, recompensa em peças, resgate único e persistência |
| HUD | Cliques no computador e no simulador móvel, livro com sete itens, visibilidade do martelo, menus e orientação; prévias desbloqueadas usaram fixture temporária sem gravar descobertas |
| Desempenho móvel | Relatório final de HUD registra cerca de 80,6 FPS no simulador com oito bases, 64 criaturas e 456 construções; um cliente e sete bases preenchidas artificialmente |

A primeira tentativa de percurso, que encontrou uma placa bloqueando o caminho, foi preservada junto com o ensaio corrigido. Não há teste de desempenho em celular físico nem demonstração equivalente com oito clientes reais. Não repetir a alegação antiga de 110 testes offline sem os arquivos que a comprovem.

Scripts `StudioQA`, `StudioRegression`, `StudioTraversal`, `StudioMobile` e `StudioStress` estão desativados na entrega; módulos QA não devem iniciar ensaios ao serem incluídos. Consulte os scripts e os relatórios antes de ativar um ensaio específico.

## Validações anteriores e próxima continuidade

A continuação de escolha de base e prévia está aplicada no Studio em Edit e no portátil da branch `codex-b/concluir-escolha-base-preview`. Foram aprovados os três ensaios offline do jogo (42 casos de ciclo de vida, 359 verificações de combate, 13 casos do guia), 28 contratos estáticos do preview, a compilação dos 24 fontes e a verificação do pacote. O verificador compara também o Source e a hierarquia dos 24 fontes embutidos; nove adulterações em cópias temporárias foram recusadas. Evidências em `Resultados/Testes/escolha-base-preview.json`, `validacao-pacote.json` e `Tests/`.

O próximo passo é o teste visual assumido pelo usuário, agora com o modelo industrial: escolha de terreno, kit manual, seleção de máquinas e teto sempre visível, prévia e rotação, dois jogadores, saída/reentrada e preservação do perfil antigo. Nenhum Play nem simulador foi iniciado nesta continuação. Os ensaios históricos precisam ser adaptados ao novo fluxo de escolha antes de executá-los novamente. Studio está liberado em Edit, com os oito ensaios desativados; Blender não foi utilizado naquela continuação de codex-b; foi utilizado nas etapas posteriores de decoração e bases.

Busque o remoto e leia a branch e a tarefa atual antes de trabalhar; `main` pode continuar na importação anterior até integração. O workflow de verificação ainda é exemplo opcional. A revisão geral de bugs e testes em celular físico continuam pendentes. Monetização, trocas e renda offline são etapas futuras.
