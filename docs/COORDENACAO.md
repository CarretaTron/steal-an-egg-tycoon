# Como trabalhar com dois Codex

O ponto de encontro dos dois chats é este repositório. Cada Codex precisa buscar as mudanças publicadas pelo outro. Um changelog local ainda não enviado e uma alteração feita somente no Studio não aparecem automaticamente no outro computador.

## Onde cada informação fica

| Registro | Uso |
|---|---|
| `README.md` | Entrada do projeto, estrutura e como começar |
| `AGENTS.md` | Regras de trabalho que um novo agente deve ler |
| `CHANGELOG.md` | Histórico das alterações integradas e evidências |
| `docs/ESTADO_ATUAL.md` | Retrato do que existe e das limitações conhecidas |
| `docs/ROADMAP.md` | Trabalho futuro e critérios ainda pendentes |
| `coordination/tasks/<data>-<responsavel>-<tarefa>.md` | Responsável, branch, arquivos, uso de apps e passagem de uma tarefa |

Use um registro por tarefa, por exemplo `2026-10-20-codex-a-hud.md`. Copie `coordination/tasks/TEMPLATE.md`; não substitua o template por uma tarefa real. Nomes como `codex-a` e `codex-b` distinguem os responsáveis, mas não são identidades automáticas do aplicativo.

## Iniciar uma tarefa

1. Leia o estado atual, o changelog e as tarefas em andamento. Confira alterações locais com `git status`.
2. Faça `git fetch`. Atualize a branch base sem descartar mudanças locais. Descubra a branch padrão pelo remoto; não suponha que se chama `main`.
3. Crie uma branch específica, como `codex-a/hud-ajuste-menu`. Registre o commit de partida e o objetivo em um novo arquivo de tarefa.
4. Declare os arquivos ou módulos sob sua responsabilidade e se precisa editar o Studio ou Blender. Envie a branch com o registro para que o outro desenvolvedor possa consultá-lo.
5. Se o outro registro já cobre os mesmos arquivos ou a mesma sessão, combinem a divisão antes de editar essa área. Trabalho independente pode continuar.

O registro é uma declaração de trabalho, sem exclusão automática. Dois registros criados ao mesmo tempo podem colidir. Nessa situação, os desenvolvedores devem definir quem fica com a área compartilhada; os Codex não devem presumir prioridade por horário de arquivo.

## Durante o trabalho

Atualize o registro quando o escopo mudar, quando usar uma sessão compartilhada ou quando descobrir uma dependência. Prefira mudanças pequenas por módulo. Construção, produção, combate, segurança, criaturas e salvamento precisam continuar coerentes com a autoridade do servidor.

Não use `CHANGELOG.md` como conversa contínua: mantenha nele o resultado das mudanças integradas. Detalhes transitórios, trabalho em andamento e passagem ficam no arquivo da tarefa. Uma issue pode representar a tarefa; o registro no repositório mantém o contexto disponível ao próximo Codex.

### Sessões do Roblox Studio

Antes de substituir scripts pelo MCP, leia a versão atual no Studio. Compare com a versão do repositório e preserve diferenças ainda não exportadas. Registre lugar, sessão, scripts lidos/alterados e eventual divergência no arquivo da tarefa.

Só um responsável executa mutações e testes na mesma sessão por vez. Iniciar ou parar Play pode interromper o ensaio do outro Codex. O fato de estarem em branches distintas não isola o aplicativo aberto. Para trabalho simultâneo, use cópias separadas do lugar e informe qual foi usada.

O lugar vinculado pode conter edições manuais do mapa. A correção atual faz `Server/WorldFactory.luau` reutilizar esse cenário ao iniciar Play, renovando apenas as malhas de ovos e guardiões por sessão. Mudanças feitas no modo Edit passam a valer diretamente nessa sessão; para chegarem ao GitHub e ao portátil, precisam ser capturadas antes do empacotamento.

Use `StealAnEggTycoonV3/export_authored_map.luau` para atualizar `Map/AuthoredMap.rbxm` e `Map/scene.json`. O RBXM nativo preserva o mapa exato, incluindo paredes e objetos externos. O JSON representa o cenário estático e os pivôs transparentes usados para repor a arte por sessão; ele é a entrada do mapa portátil. Registre os arquivos exportados e a comparação Edit → Play na tarefa. Preserve os backups anteriores.

O exportador JSON deve recusar tipos que não consegue preservar, como Unions ou malhas decorativas ainda não suportadas. Não ignore o erro, não descarte esses objetos e não os substitua silenciosamente por blocos. Preserve o snapshot nativo e atualize o suporte antes de gerar um pacote que se declare equivalente. A correção do mapa ainda aguarda sua validação de Edit → Play e do pacote; os testes anteriores não comprovam esse comportamento novo.

### Arquivos Blender e exportações

Combine quem altera cada `.blend`. Guarde o gerador Python e a geometria correspondente junto com os arquivos de criação e FBX. Evite duas edições simultâneas do mesmo binário. Se houver duas versões válidas, preserve ambas com nomes claros enquanto a integração é decidida; não resolva conflito binário escolhendo uma sem conferir o conteúdo.

### Fontes e pacotes

Os fontes editáveis são `StealAnEggTycoonV3/Client`, `Server` e `Shared`; a captura do mapa fica em `StealAnEggTycoonV3/Map`. O diretório `Resultados` reúne a entrega gerada, inclusive cópias `Fontes` e `Map`. Não faça a mesma correção manualmente nas duas árvores. Edite a árvore principal, reexporte o mapa se ele mudou e regenere a entrega com `package_project.py`. O empacotador passa a usar `Map/scene.json`, em lugar do mapa antigo do backup, e a atualizar as cópias de fontes e mapa automaticamente. Execute a verificação correspondente e confira as instruções do projeto antes dos geradores.

## Concluir e integrar

Revise o diff, execute as verificações pertinentes e registre resultados reais. Atualize tarefa, changelog e estado atual conforme a alteração. Faça commit do código junto com seus registros e publique a branch. Antes da integração, busque a base atualizada e resolva divergências pelo conteúdo e pelo histórico. O modelo de PR pede escopo, evidências e passagem para o próximo Codex.

Se não for possível decidir um conflito com as informações existentes, preserve as versões e peça ao desenvolvedor uma decisão concreta. Não use reset destrutivo, force push ou substituição cega do Studio para esconder a divergência.

Um trabalho interrompido deve ficar com status, commit enviado, próximos passos e sessão liberada ou ainda ocupada registrados. O outro Codex só consegue continuar o que foi salvo e publicado.

## Texto para iniciar um novo chat

Copie o texto abaixo e acrescente a tarefa concreta e o caminho local do clone:

> Este é o projeto Steal an Egg Tycoon. Leia README.md, AGENTS.md, CHANGELOG.md, docs/ESTADO_ATUAL.md e as tarefas de coordination/tasks antes de alterar arquivos. Busque as mudanças do remoto e preserve alterações locais e do Studio. Consulte docs/COORDENACAO.md, crie uma branch e um registro de tarefa próprios, declare os módulos e a sessão de Studio/Blender que vai usar. Continue somente a tarefa solicitada, registre o que mudou e os testes, e envie os fontes e registros para que o outro desenvolvedor possa continuar.

O repositório é público para leitura e clone. Para o amigo enviar mudanças diretamente, o dono pode conceder permissão de escrita; alternativamente, ele pode contribuir por fork e PR. Os registros não concedem permissões nem enviam mensagens automaticamente a outros chats.
