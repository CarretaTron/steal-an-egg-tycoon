# Steal an Egg Tycoon — V3 continuada

A etapa atual continua o trabalho de escolha da base e construção manual: nascer na praça, escolher um terreno livre, posicionar o kit guardado e visualizar o modelo real semitransparente antes de confirmar. Os atalhos de martelo, livro, rebirth e missões e o mapa editado foram preservados. Consulte **HUD.md** para a etapa anterior da interface.

Correção aplicada: preservar o mapa editado ao iniciar Play e manter o contador de rebirth imediatamente ao lado do dinheiro, em uma linha horizontal com espaço de 10 pixels. A comparação Edit → Play, a compilação e a verificação do pacote passaram; o teste visual final da linha dinheiro/rebirth foi assumido pelo usuário.

Atualizado em 21/10/2026, a partir da V3 existente e dos fontes parciais recebidos no RAR. O lugar conectado no Studio continua sendo 119288590672557. A V2 fica desativada em ServerStorage/EggTycoonV2_Backup; a cópia portátil também contém esse backup, seus scripts e metadados.

## Jogar

No projeto vinculado já aberto no Roblox Studio, pressione Play. Você nasce na praça e escolhe uma tycoon na placa verde da entrada; cada jogador pode possuir somente um terreno por servidor. Entre no terreno e abra **Construir** para posicionar o kit gratuito guardado no inventário: habitat, incubadora, processador, vendedor e esteiras. O cartão **Paredes e cobertura** monta as defesas fixas gratuitamente quando você decidir; uma base nova começa aberta.

A prévia mostra o modelo real semitransparente, com contorno verde ou vermelho conforme a posição. Gire antes de confirmar. Ela não bloqueia o personagem nem a seleção do terreno; o servidor valida a posição e o inventário ao colocar. Conecte habitat → esteiras → processador → vendedor.

O ciclo é roubar ovo, escapar do guardião, incubar, produzir a cada quatro segundos, processar e vender. A primeira venda de um pintinho básico é $32. Sem conexão válida, cada habitat guarda até 20 recursos. Perfis antigos mantêm construções, criaturas e defesas salvas, restauradas após escolher um terreno. Após rebirth, monte novamente o kit gratuito.

O arquivo StealAnEggTycoonV3.rbxlx desta pasta é o projeto portátil. A correção faz `WorldFactory` reutilizar o mapa já editado, renovando apenas as malhas de ovos e guardiões por sessão. O empacotador passa a embutir o mapa capturado em `Map/scene.json`. Como arquivo portátil, abre sem o vínculo da experiência. Para testar permissões de malhas e salvamento, use o lugar vinculado ou associe sua cópia a um lugar autorizado. A geometria Blender é reconstruída por EditableMesh e convertida em conteúdo estático via AssetService por sessão; ovos e guardiões replicaram em dois clientes nos ensaios anteriores. As exportações FBX acompanham o projeto como alternativa para importação manual; essa alternativa não foi necessária no lugar testado.

O Studio usa EggTycoonV3_DEV_v1, separado do nome LIVE usado em servidores publicados. O acesso às APIs respondeu no lugar conectado. Falhas de carregamento recusam a entrada sem substituir progresso; com APIs explicitamente desativadas, o Studio informa modo de sessão.

## Novidades desta continuação

- Habitats com três melhorias individuais, preços de $1.500, $7.500 e $30.000, e produção de +25%, +50% e +75%. Guardar e recolocar preserva nível e identidade.
- Criaturas agora abre as abas Habitats, Livro e Missões. O livro revela as sete espécies conforme as descobertas e mostra suas prévias 3D, recurso, incubação, renda e guardião. As prévias usam as malhas estáticas existentes e carregam ao rolar.
- Sete missões: primeiro nascimento, primeira venda, 25 recursos vendidos, três descobertas, três melhorias de habitat, uma bateria destruída e sete descobertas.
- As recompensas são peças de construção, resgatadas uma vez pelo servidor. Missões não concedem dinheiro direto. Contadores, resgates e descobertas persistem após rebirth.
- Incubações salvam o tempo conectado restante. Recursos já em trânsito têm identificadores e registro de pagamento pendente. Falhas no salvamento de saída mantêm um retrato para novas tentativas.
- Aviso ao dono no início da tentativa válida de roubo e melhoria de bateria comprada durante ataque aplicada somente na reconstrução.
- Animações de caminhada, ataque e produção; interface ajustada para telas menores; placas e árvore retiradas do caminho central da expedição.

## Controles

| Ação | Computador | Celular |
|---|---|---|
| Escolher tycoon | Segurar E na placa verde da entrada | Segurar o indicador da placa verde |
| Roubar ou entregar | Segurar E no indicador | Segurar o indicador |
| Construir | B ou Construir | Construir |
| Posicionar | Apontar e clicar/Colocar | Tocar o chão e Colocar |
| Girar | R ou Girar | Girar |
| Mover, guardar, melhorar habitat | Selecionar a construção | Tocar a construção |
| Livro e missões | Botões 📖 Livro e 📜 Missões | Botões 📖 Livro e 📜 Missões |
| Abandonar transporte | G | Botão da interface |
| Atacar | Clique com arma equipada | Golpear/Atirar |

## Evidência incluída

Nesta etapa de escolha de base, os programas reproduzíveis de `Tests/` passaram: 42 casos de ciclo de vida, 359 verificações de combate, 13 casos funcionais do guia e 28 contratos estáticos do preview. Os 24 fontes compilaram; os nove alterados foram aplicados e conferidos no Studio em Edit. Consulte `Resultados/Testes/escolha-base-preview.json` e `Tests/README.md`.

São testes offline com a engine simulada. Play, simulador e testes visuais do fluxo novo não foram executados nesta continuação, conforme a passagem anterior para o usuário. Ainda é necessário conferir no jogo a escolha das bases com dois jogadores, a montagem manual, a aparência do preview e a reentrada em outro terreno.

Os JSON anteriores em `Resultados/Testes/` preservam os seguintes resultados históricos da V3; não são certificação do novo fluxo de escolha:

- Integração com dois clientes: 31 verificações, incluindo primeira venda natural de $32, geometria replicada, bateria, roubo, morte, entrega, rebirth e recarga persistente.
- Regressões do servidor: 98 verificações de construção, circuitos, armazenamento, pagamento único, recuperação com falhas simuladas, bateria e combate. Os casos de falhas usam DataStore em memória e não escrevem perfis reais.
- Percurso físico: 13 verificações em 133,71 s. Após uma aproximação inicial ao ovo, os personagens caminham; o dono percorreu 1.175 studs, o ladrão 1.088 e a perseguição do dono 486. Dez golpes de bastão quebraram a bateria e a criatura foi entregue uma vez. Perfis originais foram restaurados.
- A primeira tentativa de percurso também está registrada: encontrou uma placa bloqueando a passagem. A versão validada já inclui a circulação corrigida.
- Novo sistema de missões: 12 verificações de conclusão, recompensa em peças, resgate único e persistência. Livro e missões também foram abertos por cliques reais no cliente; a visualização de espécies desbloqueadas usou uma simulação temporária apenas da interface, sem salvar descobertas.
- O relatório móvel registra resolução, FPS, quantidade de bases, construções, criaturas e limites da interface. O ensaio usa um cliente e sete bases preenchidas artificialmente, totalizando oito bases, 64 criaturas e 456 construções. É desempenho no simulador do computador; falta medir em celular físico.

Os scripts StudioQA, StudioRegression, StudioTraversal, StudioMobile e StudioStress estão desativados na entrega. Os módulos QA não executam ao serem incluídos. Ative apenas o script do ensaio desejado e lance-o por StudioTestService com seu argumento exato. O jogo normal não usa os ensaios.

## Arquivos

- Client/, Server/ e Shared/: fontes editáveis; Resultados/Fontes/ contém a cópia da entrega.
- Map/AuthoredMap.rbxm: snapshot nativo exato do mapa editado, incluindo paredes e objetos externos.
- Map/scene.json: dados estáticos usados no portátil, com pivôs transparentes para a arte renovada por sessão.
- export_authored_map.luau: captura a versão editada do mapa para a próxima entrega.
- Blender/: arquivo .blend, gerador Python, geometry.json e 19 exportações FBX. O gerador grava ao lado do próprio script, ou na pasta indicada por ET_OUT.
- Backups/: exportação tipada da V2. O projeto de antes desta continuação permanece em ../Backups/AntesContinuacao/.
- Resultados/manifesto-fontes.json: hashes dos fontes usados para montar o portátil.

## Alterar o mapa e atualizar a entrega

As alterações feitas no modo Edit devem ser reutilizadas diretamente quando iniciar Play. Para enviar essas mudanças ao GitHub ou incluí-las no portátil, reexporte o mapa com `export_authored_map.luau` antes de executar `package_project.py`. Preserve o snapshot `Map/AuthoredMap.rbxm` e os dados de `Map/scene.json`; o empacotador usa o JSON no lugar do mapa antigo e atualiza automaticamente as cópias de fontes e Map em Resultados. Execute `verify_package.py` e compare Edit → Play antes de entregar. Preserve os backups históricos.

O exportador JSON deve recusar tipos não suportados, como Unions ou malhas decorativas ainda sem representação, com erro explícito. Não aceite perda de geometria nem substituição silenciosa por blocos. O RBXM preserva o conteúdo nativo exato; resolva o suporte antes de produzir um portátil equivalente. A cena atual e suas 32 ruas, oito bases, 14 ninhos e 14 guardiões foram conferidos no pacote; a comparação em Play está em `Resultados/Testes/mapa-edit-play.json`.

A rodada geral final de bugs foi adiada conforme solicitado. Monetização, trocas e produção offline continuam fora desta versão. Nenhuma publicação foi realizada nesta continuação.
