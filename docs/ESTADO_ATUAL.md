# Estado atual — 20/10/2026

A V3 jogável e a etapa de HUD estão nos arquivos existentes. O projeto completo foi publicado no repositório público https://github.com/CarretaTron/steal-an-egg-tycoon, com documentação para dois desenvolvedores usando Codex. A importação `2963104` contém 140 arquivos; um clone novo confirmou que todos chegaram idênticos e passou na verificação do pacote. Consulte também `coordination/tasks/2026-10-20-codex-a-repositorio.md`.

## Projeto preservado

O inventário anterior à criação dos documentos de colaboração contém 127 arquivos, totalizando 10.567.710 bytes, incluindo o RAR original na raiz. Há 24 fontes Luau na árvore principal e 19 exportações FBX. Documentação e registros criados depois aumentam esse total.

| Local | Conteúdo e autoridade |
|---|---|
| `StealAnEggTycoonV3/Client/`, `Server/`, `Shared/` | Fontes editáveis da versão atual |
| `StealAnEggTycoonV3/Blender/` | Cena Blender, cena original, backup `.blend1`, gerador Python, geometria e 19 FBX |
| `StealAnEggTycoonV3/StealAnEggTycoonV3.rbxlx` | Lugar portátil que recria mapa e malhas ao iniciar |
| `StealAnEggTycoonV3/Resultados/` | Pacote de entrega e cópias derivadas dos fontes, arte e relatórios |
| `StealAnEggTycoonV3/Backups/` | V2 e estados anteriores preservados; não são a versão ativa |
| `StealAnEggTycoonV3.rar` | Arquivo original recebido, preservado integralmente |

O lugar conectado documentado é `119288590672557`. A V2 permanece desativada em `ServerStorage/EggTycoonV2_Backup`. Não há publicação da experiência registrada nesta entrega. O arquivo portátil não mantém o vínculo da experiência; permissões e persistência precisam de um lugar autorizado.

## Jogo existente

O ciclo é roubar ovo, fugir do guardião, levar à base, incubar, produzir, processar, vender e melhorar a base. São sete biomas e espécies, oito terrenos, construção livre em grade, habitats, incubadoras, processadores, esteiras, vendedor, bateria externa e porta a laser. A praça e o corredor são zonas sem PvP; guardiões continuam perigosos no corredor.

O kit inicial já tem uma linha conectada. As criaturas produzem a cada quatro segundos; a primeira venda natural de um pintinho básico é $32. Cada habitat desconectado armazena até 20 recursos. O servidor controla o percurso e o pagamento dos recursos; os objetos visuais não decidem o dinheiro.

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

## Arte e persistência

Os dados do Blender são reconstruídos com EditableMesh e convertidos em conteúdo estático pelo AssetService por sessão. A geometria dos ovos e guardiões foi vista em dois clientes. As 19 exportações FBX acompanham o projeto como alternativa manual; a rota FBX não foi necessária no lugar testado. O gerador Blender grava ao lado do script ou no caminho definido por `ET_OUT`.

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

## Próxima continuidade

A publicação do backup completo e os registros de colaboração estão concluídos. Leia as tarefas e busque as alterações do remoto antes da próxima etapa. O exemplo de workflow em `docs/verificar-pacote.workflow.yml` é opcional e ainda não está ativo; o verificador local foi executado com sucesso. Novos recursos ficam sujeitos à próxima etapa solicitada. O usuário adiou a revisão geral de bugs; isso não significa que todos os critérios do projeto foram certificados. Testes físicos de celular e avaliação completa dos critérios restantes continuam pendentes. Monetização, trocas e renda offline são etapas futuras.
