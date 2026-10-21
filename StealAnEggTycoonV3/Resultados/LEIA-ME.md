# Steal an Egg Tycoon — V3 continuada

A etapa atual redesenhou a interface conforme as referências: atalhos de martelo, livro, rebirth e missões, dinheiro em destaque e orientação por seta. Consulte **HUD.md** para o funcionamento e a validação dessa etapa.

Atualizado em 20/10/2026, a partir da V3 existente. O lugar conectado no Studio continua sendo 119288590672557. A V2 fica desativada em ServerStorage/EggTycoonV2_Backup; a cópia portátil agora também contém esse backup, seus scripts e metadados.

## Jogar

No projeto vinculado já aberto no Roblox Studio, pressione Play. O ciclo é roubar ovo, escapar do guardião, incubar, produzir a cada quatro segundos, processar e vender. O kit inicial já possui uma linha conectada. A primeira venda de um pintinho básico é $32. Sem conexão válida, cada habitat guarda até 20 recursos.

O arquivo StealAnEggTycoonV3.rbxlx desta pasta contém os fontes atualizados e recria o mapa e as malhas ao iniciar. Como arquivo portátil, abre sem o vínculo da experiência. Para testar permissões de malhas e salvamento, use o lugar vinculado ou associe sua cópia a um lugar autorizado. A geometria Blender é reconstruída por EditableMesh e convertida em conteúdo estático via AssetService por sessão; ovos e guardiões replicaram em dois clientes. As exportações FBX acompanham o projeto como alternativa para importação manual; essa alternativa não foi necessária no lugar testado.

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
| Roubar ou entregar | Segurar E no indicador | Segurar o indicador |
| Construir | B ou Construir | Construir |
| Posicionar | Apontar e clicar/Colocar | Tocar o chão e Colocar |
| Girar | R ou Girar | Girar |
| Mover, guardar, melhorar habitat | Selecionar a construção | Tocar a construção |
| Livro e missões | Botões 📖 Livro e 📜 Missões | Botões 📖 Livro e 📜 Missões |
| Abandonar transporte | G | Botão da interface |
| Atacar | Clique com arma equipada | Golpear/Atirar |

## Evidência incluída

Os arquivos JSON em Testes guardam os resultados obtidos nesta continuação:

- Integração com dois clientes: 31 verificações, incluindo primeira venda natural de $32, geometria replicada, bateria, roubo, morte, entrega, rebirth e recarga persistente.
- Regressões do servidor: 98 verificações de construção, circuitos, armazenamento, pagamento único, recuperação com falhas simuladas, bateria e combate. Os casos de falhas usam DataStore em memória e não escrevem perfis reais.
- Percurso físico: 13 verificações em 133,71 s. Após uma aproximação inicial ao ovo, os personagens caminham; o dono percorreu 1.175 studs, o ladrão 1.088 e a perseguição do dono 486. Dez golpes de bastão quebraram a bateria e a criatura foi entregue uma vez. Perfis originais foram restaurados.
- A primeira tentativa de percurso também está registrada: encontrou uma placa bloqueando a passagem. A versão validada já inclui a circulação corrigida.
- Novo sistema de missões: 12 verificações de conclusão, recompensa em peças, resgate único e persistência. Livro e missões também foram abertos por cliques reais no cliente; a visualização de espécies desbloqueadas usou uma simulação temporária apenas da interface, sem salvar descobertas.
- O relatório móvel registra resolução, FPS, quantidade de bases, construções, criaturas e limites da interface. O ensaio usa um cliente e sete bases preenchidas artificialmente, totalizando oito bases, 64 criaturas e 456 construções. É desempenho no simulador do computador; falta medir em celular físico.

Os scripts StudioQA, StudioRegression, StudioTraversal, StudioMobile e StudioStress estão desativados na entrega. Os módulos QA não executam ao serem incluídos. Ative apenas o script do ensaio desejado e lance-o por StudioTestService com seu argumento exato. O jogo normal não usa os ensaios.

## Arquivos

- Fontes/: cópia dos scripts Luau que compõem esta entrega.
- Blender/: arquivo .blend, gerador Python, geometry.json e 19 exportações FBX. O gerador grava ao lado do próprio script, ou na pasta indicada por ET_OUT.
- Backups/: exportação tipada da V2. O projeto de antes desta continuação permanece em ../Backups/AntesContinuacao/.
- manifesto-fontes.json: hashes dos fontes usados para montar o portátil.

A rodada geral final de bugs foi adiada conforme solicitado. Monetização, trocas e produção offline continuam fora desta versão. Nenhuma publicação foi realizada nesta continuação.
