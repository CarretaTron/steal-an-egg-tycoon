# Orientações para agentes — Steal an Egg Tycoon

Este repositório reúne o projeto inteiro, incluindo fontes, arquivos do Roblox Studio, criação no Blender, exportações, backups e relatórios. Dois desenvolvedores podem trabalhar nele por chats separados do Codex. O Git registra a coordenação; ele não sincroniza chats nem alterações ainda abertas no Studio.

## Antes de alterar arquivos

1. Leia `README.md`, `CHANGELOG.md`, `docs/ESTADO_ATUAL.md` e `docs/COORDENACAO.md`.
2. Confira `git status`, a branch atual, os remotos e os registros em `coordination/tasks/`. Faça `git fetch` e atualize a base com segurança antes de iniciar. Preserve alterações locais; não use reset, clean ou force push para contornar divergências.
3. Crie uma branch para a tarefa e um arquivo próprio em `coordination/tasks/`, copiando `TEMPLATE.md`. Declare responsável, objetivo, arquivos envolvidos e uso de Studio/Blender. Publique esse registro para que o outro desenvolvedor possa vê-lo. Um arquivo não constitui trava automática: conflitos de escopo exigem coordenação.
4. Continue a solicitação atual do usuário. Não implemente recursos do roadmap apenas porque constam nele. A etapa que criou este repositório é backup completo e coordenação; a revisão geral de bugs foi adiada pelo usuário.

## Fontes e artefatos

- Edite os fontes em `StealAnEggTycoonV3/Client/`, `Server/` e `Shared/`. `Resultados/Fontes/` e os pacotes em `Resultados/` são cópias de entrega. Atualize-os pelo empacotador quando a tarefa exigir nova entrega.
- Configuração central: `Shared/Config.luau`. O servidor decide dinheiro, propriedade, construção, dano, missões e persistência. Preserve essa autoridade.
- `Server/WorldFactory.luau` preserva o mapa existente e renova apenas ovos/guardiões por sessão; gera o mapa básico quando não existe um mundo. Edições manuais são versionadas em `StealAnEggTycoonV3/Map/`: reexporte `AuthoredMap.rbxm` e `scene.json` no modo Editar antes de executar o empacotador. Não substitua esse mapa pelo snapshot antigo. Consulte `Map/README.md`.
- Preserve o protótipo V2 desativado, backups, tentativas de teste e os arquivos originais. Não exclua artefatos para reduzir o repositório sem solicitação.
- Os arquivos de criação estão em `StealAnEggTycoonV3/Blender/`: `.blend`, gerador Python, `geometry.json` e FBX. Combine a posse de arquivos binários antes de editá-los; Git não mescla duas cenas Blender com segurança. Registre qual fonte gerou cada exportação.

## Studio e Blender compartilhados

- Antes de escrever no Studio, leia o conteúdo atual dos scripts envolvidos e compare com os fontes locais e o registro da tarefa. Outra pessoa pode ter mudanças que ainda não chegaram ao Git. Preserve-as ou incorpore-as conscientemente.
- Somente um responsável por vez pode executar mutações ou iniciar/parar testes na mesma sessão do Studio. Um playtest iniciado por outro chat pode interromper o trabalho em andamento. Registre o uso da sessão na tarefa e avise o desenvolvedor antes de disputar uma sessão já ocupada.
- A mesma regra vale para edições na mesma cena Blender. Leitura dos fontes locais e trabalho em áreas independentes podem continuar em paralelo.
- Não habilite ensaios StudioQA/Regression/Traversal/Mobile/Stress no jogo normal. Execute apenas o teste necessário e restaure o estado desativado na entrega.
- Use os dados de desenvolvimento nos testes. Não trate falha de carregamento como perfil vazio nem sobrescreva progresso existente.

## Ao concluir ou passar uma tarefa

1. Valide a alteração com verificações adequadas ao escopo. Diga claramente o que foi executado, o resultado e o que ficou pendente. Simulador móvel não é celular físico; preenchimento artificial de bases não equivale a oito clientes reais.
2. Revise o diff e atualize o registro da tarefa, `CHANGELOG.md` e, quando mudar o estado do jogo, `docs/ESTADO_ATUAL.md`. Registre caminhos, evidências e próximos passos. Não copie tokens, credenciais ou dados pessoais de jogadores.
3. Faça commit dos fontes e registros relacionados e envie a branch ao remoto autorizado. Sincronize novamente antes de integrar; resolva conflitos a partir das mudanças conhecidas. Abra PR quando esse for o fluxo adotado pelos desenvolvedores.
4. Se duas versões conflitantes não puderem ser conciliadas pelo histórico e pelo escopo das tarefas, preserve ambas e peça ao desenvolvedor a decisão específica. Não escolha silenciosamente a versão local, remota ou do Studio.

O pedido de criar e enviar este repositório já autoriza as ações necessárias de Git/GitHub. Estas orientações não criam uma nova confirmação obrigatória para ações já autorizadas.
