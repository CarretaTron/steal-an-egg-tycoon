# Próximas etapas

Este arquivo organiza pendências. Ele não autoriza implementar tudo de uma vez. O pedido atual é o repositório completo e a coordenação entre dois Codex; a etapa de HUD já está nos arquivos existentes. O usuário pediu trabalho em etapas e deixou a revisão geral de bugs para depois.

## Etapa atual: backup e colaboração

- Preservar os arquivos originais, RAR, fontes editáveis, cenas Blender, geometria, FBX, lugares Roblox, backups e relatórios.
- Publicação concluída: https://github.com/CarretaTron/steal-an-egg-tycoon .
- Disponibilizar instruções de instalação, empacotamento, coordenação por tarefa e histórico de mudanças.
- O dono pode conceder ao amigo permissão de escrita; cada desenvolvedor usa sua própria autenticação. A leitura e o clone ficam públicos.
- Clone conferido: 140 arquivos idênticos aos locais e pacote validado no clone. Repetir a verificação quando a entrega mudar.

## Depois, conforme a próxima tarefa solicitada

A HUD solicitada foi implementada com martelo, livro, renascer, missões por clique, seta e dinheiro destacado. Mudanças adicionais nessa interface devem partir do teste do usuário e ter escopo próprio. Livro e missões de progressão também já existem; não tratá-los como recursos ainda não iniciados.

Antes de produzir uma nova entrega, combine qual desenvolvedor cuida de cada módulo e de qual sessão Studio/Blender. Consulte `ESTADO_ATUAL.md` para não repetir a etapa já concluída.

## Validação final pendente

Os relatórios existentes são evidência parcial importante. A revisão final deve confrontar a especificação e registrar cada critério com seu ensaio e resultado, sem substituir resultados ausentes por suposições:

- Jogador novo concluir ovo até primeira venda, sem dinheiro de teste; confirmar novamente no pacote final.
- Reavaliar os sete guardiões, progressão de dificuldade e clareza visual dos ataques.
- Repetir invasão, quebra de bateria, roubo, perseguição, recuperação e entrega com dois jogadores na versão final.
- Confirmar exclusão de criaturas/guardiões dos danos de armas e proteção de zonas seguras, inclusive tiros de fora.
- Conferir reposicionamento e reconexão de esteiras sem duplicação de recursos/dinheiro.
- Exercitar morte, saída, destino ocupado, transferência interrompida e falhas de salvamento sem perda ou duplicação.
- Reentrar em outro terreno e validar restauração relativa do layout; rebirth deve aplicar o reset uma única vez.
- Medir interface, construção e desempenho em celular físico com oito bases ocupadas, alvo mínimo de 30 FPS. O simulador atual usa um cliente e preenchimento artificial das outras bases.
- Validar instalação em outro computador e uso das permissões do lugar; se a rota EditableMesh/AssetService falhar nesse ambiente, validar a importação FBX antes de alterar todos os modelos.

O usuário adiou a rodada geral de correções. Quando ela for solicitada, crie tarefas pequenas por problema observado e associe cada correção à evidência correspondente.

## Fora da primeira versão

Monetização, trocas entre jogadores e renda offline ficam para uma etapa posterior. Nenhuma dessas funcionalidades deve ser iniciada como parte do backup ou de uma tarefa de HUD.
