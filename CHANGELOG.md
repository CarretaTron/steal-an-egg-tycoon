# Changelog

Histórico compartilhado pelos dois desenvolvedores e suas sessões do Codex. Atualize junto com a alteração entregue, vinculando o arquivo da tarefa e, quando disponível, o commit ou PR. Registre separadamente o que foi implementado, validado e o que continua pendente.

## 2026-10-20 — Mapa editado preservado e rebirth junto ao saldo

- `WorldFactory` preserva a praça, caminhos, paredes e bases editados no Studio. Somente as malhas de ovos e guardiões são renovadas por sessão, mantendo prompts e labels.
- Mapa autorado versionado em `Map/AuthoredMap.rbxm` e `Map/scene.json`; empacotador e verificador incluem o mapa atual e atualizam as cópias da entrega.
- Comparação Edit/Play confirmou os 32 segmentos da praça e as 82 peças das paredes com transformações, cores e materiais preservados; 14 ovos e prompts, 14 guardiões e inicialização repetida conferidos. Evidência em `Resultados/Testes/mapa-edit-play.json`.
- Rebirth fica imediatamente ao lado do dinheiro, com espaço de 10 pixels e um único layout horizontal. Não há reposicionamento concorrente por frame. Valores grandes ajustam a fonte quando necessário.
- Scripts compilados no Studio; pacote verificado. O teste visual final da linha dinheiro/rebirth fica com o usuário, que assumiu os testes. Não foi iniciado novo Play nem simulador para essa revisão visual.
- Registro: `coordination/tasks/2026-10-20-codex-a-mapa-rebirth.md`.

## 2026-10-20 — Preparação do repositório compartilhado

- Inclusão do projeto completo disponível na pasta: fontes, portátil `.rbxlx`, arquivos `.blend`/`.blend1`, geometria, gerador Blender, 19 exportações FBX, backups da V2 e V3, RAR original e resultados dos ensaios.
- Adicionados guia para os Codex, protocolo de coordenação, estado atual, roadmap, registros de tarefa e modelos de issue/pull request.
- Incluído exemplo de workflow para verificar a integridade do pacote no GitHub. O verificador local foi executado; a automação depende de ativação com permissão de publicação de workflows.
- Visibilidade solicitada pelo proprietário: **pública**.
- Repositório criado e enviado: https://github.com/CarretaTron/steal-an-egg-tycoon . Importação inicial no commit `2963104`.
- Clone novo conferido: 140 arquivos idênticos aos locais e verificação do pacote aprovada também no clone. Os documentos de conclusão acompanham o commit seguinte.

## 2026-10-20 — HUD com botões e orientação

- Interface com cores vivas, textura de studs, contornos marcados e títulos legíveis, inspirada nas referências fornecidas pelo proprietário.
- Botão 🔨 Construir visível somente dentro do próprio terreno. Reúne máquinas, esteiras e melhorias; sair da base encerra a construção.
- Botão 📖 Livro abaixo do martelo, com sete espécies, descobertas, prévias 3D e acesso aos habitats.
- Botões ♻️ Renascer e 📜 Missões. As missões abrem por interação, sem o painel permanente no centro da tela.
- Dinheiro em verde na região inferior esquerda, valores abreviados e quantidade de rebirths ao lado. Retiradas as barras de bateria e energia da HUD.
- Novo módulo `Shared/HudGuide.luau`: seta na tela e marcadores no chão, com destino conforme a missão e o transporte atual.
- Layout e painéis adaptados para computador e celular. Backup anterior preservado em `Backups/AntesHUD/`.
- Validação registrada em `Resultados/Testes/hud-interacao.json`: martelo contextual, sete entradas do livro, missões, seta e acesso às melhorias por cliques no Studio.
- Ensaio móvel em `Resultados/Testes/hud-desempenho-movel.json`: 705 × 338, oito bases ocupadas, 64 criaturas, 456 construções, média de 80,59 FPS e nenhum elemento detectado fora da tela. Ensaio em um cliente com sete bases preenchidas artificialmente; falta teste em aparelho físico.
- Pacote verificado: 24 fontes e cópias correspondentes, 19 FBX, backup V2 incluído e oito scripts de ensaio desativados.

## 2026-10-20 — Continuação da V3, livro e progressão

- Três níveis de melhoria por habitat: custos de $1.500, $7.500 e $30.000, com bônus de produção de 25%, 50% e 75%. Guardar e recolocar preserva identidade e nível.
- Livro de descobertas para as sete espécies e sete missões de progressão, com recompensas em peças de construção e resgate único no servidor. Descobertas, contadores e resgates persistem após rebirth.
- Incubação preserva o tempo conectado restante ao salvar. Recursos em trânsito possuem identificadores e registro de pagamento pendente; falhas no salvamento de saída preservam um retrato para nova tentativa.
- Aviso ao dono no início de uma tentativa válida de roubo. Melhorias de bateria compradas durante invasão entram na reconstrução.
- Reservas e recuperação de transferências reforçadas; restrições de movimento e armas aplicadas antes das operações de persistência.
- Ajustes nas placas e árvore que bloqueavam o percurso da expedição; animações de caminhada, ataque e produção.
- Evidências incluídas: integração com dois clientes (31 verificações, primeira venda natural de $32), regressões do servidor (98 verificações), percurso físico (13 verificações) e progressão (12 verificações). Falhas de DataStore foram ensaiadas em memória.
- A primeira tentativa do percurso, que encontrou uma passagem bloqueada, também está preservada nos relatórios.

## Base recebida — V3 e protótipo V2

- A V3 existente já continha o núcleo do tycoon, sete biomas, oito bases, produção, combate, segurança, roubo, construção e persistência, além dos modelos Blender.
- O protótipo V2 e seus scripts foram preservados desativados. Os snapshots anteriores à continuação permanecem no repositório.
- Este registro descreve o estado encontrado e continuado; não atribui autoria nem datas anteriores que não foram confirmadas.

## Pendências conhecidas

- Medir o desempenho num celular físico.
- Rodada geral final de bugs e revisão dos critérios de conclusão do jogo, conforme a etapa autorizada pelo proprietário.
- Preservar e exportar eventuais edições manuais recentes do mapa conectado antes de reconstruir o portátil a partir do snapshot antigo.
- Monetização, trocas e renda offline fora do escopo da primeira versão.
