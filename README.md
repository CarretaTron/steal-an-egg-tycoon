# Steal an Egg Tycoon

Repositório público: [CarretaTron/steal-an-egg-tycoon](https://github.com/CarretaTron/steal-an-egg-tycoon).

Projeto Roblox em desenvolvimento por duas pessoas com apoio de sessões separadas do Codex. Este repositório reúne os fontes, o projeto portátil do Studio, os arquivos de criação do Blender, as exportações, os backups e os relatórios de testes disponíveis nesta pasta.

O ciclo do jogo é roubar um ovo, fugir do guardião, incubar na base, produzir recursos, processar, vender e expandir ou defender o tycoon. Há sete biomas, oito terrenos, construção livre, combate, roubo de criaturas, salvamento, livro de descobertas e missões.

## Comece por aqui

- **Para os dois Codex:** leia [AGENTS.md](AGENTS.md), [coordenação](docs/COORDENACAO.md) e [estado atual](docs/ESTADO_ATUAL.md) antes de editar.
- **O que mudou:** [CHANGELOG.md](CHANGELOG.md).
- **Próximas etapas:** [roadmap](docs/ROADMAP.md).
- **Como jogar e testar:** [LEIA-ME do projeto](StealAnEggTycoonV3/LEIA-ME.md).
- **Última etapa de interface:** [HUD.md](StealAnEggTycoonV3/HUD.md).

## Arquivos incluídos

```text
StealAnEggTycoonV3/
  Client/                       # Fontes editáveis do cliente
  Server/                       # Fontes editáveis do servidor e ensaios
  Shared/                       # Configuração, construção, arte e guia da HUD
  Map/                          # Mapa editado: snapshot RBXM e dados scene.json
  Blender/                      # Criação de criaturas, decoração e bases; cenas, geradores e FBX
  Backups/                      # V2 e snapshots anteriores à continuação/HUD
  Resultados/                   # Entrega, cópias dos fontes, Blender e testes
  StealAnEggTycoonV3.rbxlx       # Projeto portátil do Roblox Studio
  package_project.py            # Montagem do portátil e manifesto
  export_authored_map.luau       # Captura das alterações manuais do mapa
  verify_package.py             # Verificação da entrega
StealAnEggTycoonV3.rar           # Arquivo original, preservado
coordination/tasks/             # Um registro por tarefa dos desenvolvedores
docs/                          # Estado, coordenação e planejamento
.github/                       # Modelos de tarefa e pull request
```

Edite os scripts em `Client/`, `Server/` e `Shared/`. O mapa editado tem seus arquivos de captura em `Map/`. `Resultados/Fontes/` e `Resultados/Map/` contêm cópias da entrega; editar somente essas cópias deixa o jogo e o pacote inconsistentes. Os backups e o RAR são históricos e devem ser preservados. Os arquivos binários cabem no Git normal; esta entrega não depende de Git LFS.

## Abrir e continuar

```sh
git clone https://github.com/CarretaTron/steal-an-egg-tycoon.git
cd steal-an-egg-tycoon
```

1. Clone este repositório e abra `StealAnEggTycoonV3/StealAnEggTycoonV3.rbxlx` no Roblox Studio.
2. O portátil usa o mapa capturado em `Map/scene.json`. `WorldFactory` reutiliza o cenário e renova a arte de ovos e guardiões por sessão. A revisão atual das bases foi conferida em Editar; seu teste visual em Play fica com o usuário. Para testar DataStore e permissões de malha, associe a cópia a uma experiência em que você tenha acesso. Consulte o LEIA-ME antes de habilitar ensaios.
3. No Blender, abra `StealAnEggTycoonV3/Blender/EggTycoonV3.blend`. O gerador `build_assets.py` e as exportações FBX estão na mesma pasta.
4. Antes de trabalhar numa etapa, registre responsável, branch e arquivos pretendidos em um novo arquivo de `coordination/tasks/`, usando [o modelo](coordination/tasks/TEMPLATE.md).
5. Entregue código e registro da tarefa no mesmo conjunto de commits. Ao terminar, atualize o changelog e informe testes realizados e pendências.

O GitHub registra o que foi commitado e enviado. Ele não sincroniza automaticamente as alterações abertas no Studio ou no Blender. Compare a versão conectada antes de substituir scripts, exporte mudanças de mapa e siga o protocolo de coordenação para sessões simultâneas.

### Mensagem para iniciar o outro Codex

> Continue este projeto a partir do repositório. Leia AGENTS.md, docs/COORDENACAO.md, docs/ESTADO_ATUAL.md, CHANGELOG.md e os registros em coordination/tasks/. Consulte as branches remotas. Registre sua tarefa e os arquivos que vai editar antes de começar; preserve o trabalho do outro desenvolvedor. Trabalhe nos fontes de Client/, Server/ e Shared/, e registre o resultado e as validações junto com o código. Não considere testes planejados como executados.

## Verificar a entrega

Na raiz do repositório, com Python 3 disponível:

```sh
python StealAnEggTycoonV3/verify_package.py
```

Esse verificador confere os hashes e as cópias dos 28 fontes Luau, os 19 FBX originais de criaturas, o arquivo Blender principal, a leitura do portátil, o backup da V2 e os oito scripts de ensaio desativados. A arte adicional possui seus próprios arquivos e relatórios em `Blender/Decoracao/` e `Blender/BaseIndustrial/`. Execute-o antes de entregar alterações no pacote. Os testes de jogabilidade continuam sendo realizados no Studio.

O exemplo [verificar-pacote.workflow.yml](docs/verificar-pacote.workflow.yml) permite automatizar essa verificação no GitHub. Para ativá-lo, um desenvolvedor com permissão de publicação de workflows pode copiá-lo para `.github/workflows/verify.yml`. Ele é entregue como exemplo e não está ativo.

Depois de alterar fontes, monte o portátil com `package_project.py` e execute o verificador. O empacotador passa a usar `Map/scene.json` para o mapa, em lugar do mapa antigo do backup, e a atualizar automaticamente as cópias dos fontes e do mapa na entrega. Confira também o portátil da pasta principal antes de enviar a nova versão. Preserve todos os backups.

### Preservar alterações feitas no mapa

Uma edição manual no Studio deve continuar funcionando ao pressionar Play: `WorldFactory` reutiliza o cenário e substitui somente a arte de ovos e guardiões que precisa ser gerada por sessão. Para essa edição chegar ao GitHub e ao portátil, capture novamente o mapa **antes** de empacotar:

1. Preserve o mapa editado no modo Edit e use `export_authored_map.luau` para atualizar a captura em `StealAnEggTycoonV3/Map/`.
2. Guarde `Map/AuthoredMap.rbxm`, snapshot nativo que preserva o conteúdo exato, incluindo paredes e objetos externos, e `Map/scene.json`, os dados estáticos usados no portátil. Os pivôs da arte criada por sessão são transparentes nessa representação estática.
3. Confira a exportação JSON. Tipos não suportados, como uma Union ou uma malha decorativa fora do suporte do exportador, devem interromper a exportação com erro. Não aceite conversão silenciosa para blocos nem perda de geometria; preserve o RBXM e acrescente suporte antes de gerar um portátil correspondente.
4. Execute o empacotador e o verificador; compare o mapa em Edit e Play e registre a evidência antes de publicar o pacote.

A comparação Edit/Play e a verificação do novo pacote passaram; consulte `Resultados/Testes/mapa-edit-play.json` e `validacao-pacote.json`. O teste visual final da linha dinheiro/rebirth foi assumido pelo usuário.

Os atributos do Git preservam os bytes dos arquivos para manter válidos os hashes da entrega e os backups originais.

A importação de 20/10/2026 foi validada por um clone novo do GitHub: os 140 arquivos versionados chegaram idênticos à pasta original, e o verificador do pacote passou também no clone.

## Bases atuais — 22/10/2026

As oito bases usam arte original do Blender em `Shared/BaseShell.luau` revisão 4: estrutura cinza com studs, janelas brancas, placa de madeira e 35 lasers vermelhos por fachada. As cercas baixas de madeira foram removidas; o teto permanece visível ao entrar e construir. As máquinas continuam livres. São seis malhas e 67 peças por base, mantendo piso, pivô, bateria e conteúdos.

A branch `codex/bases-blender` continua a integração de codex-b e do catálogo decorativo. A entrega histórica desta revisão de bases está em `Resultados/SemCercasTeto/`; criação e FBX em `Blender/BaseIndustrialSemCercas/`. A revisão sem cercas foi conferida com 26 fontes e145 malhas; a entrega atual com geradores está indicada abaixo. Conferência em Editar; sem novo Play, dois clientes ou medição de desempenho. O pavilhão da revisão 2 permanece no histórico e nos backups.

## Geradores atuais — 22/10/2026

As oito bases têm um gerador original criado no Blender, verde/cinza, com painel físico na parte superior. A vida, barra de integridade, nível ativo e tempo de reconstrução aparecem no próprio visor. Não há legenda flutuante de bateria. Arte em `Blender/GeradorIndustrial/`; entrega atual em `Resultados/GeradorIndustrial/`.

O portátil atual possui 28 fontes e201 MeshParts; pacote e visor conferidos em Edit. Bateria e regras de combate continuam sob autoridade do servidor. Geradores acompanham a visibilidade por propriedade já existente: terrenos livres mantêm a bateria oculta.

## Funcionalidades preservadas

A continuação integrada de codex-b foi entregue em `codex-b/concluir-escolha-base-preview`, a partir da etapa iniciada em `codex-a/escolha-base-preview` e dos fontes parciais do RAR recebido em 21/10. O jogador nasce na praça, escolhe um terreno livre e monta seu kit manualmente. A estrutura agora vem pronta conforme a etapa visual posterior; máquinas e esteiras são montadas pelo jogador. A prévia de posicionamento mostra o objeto real semitransparente. Perfis antigos preservam o progresso. Consulte o [registro da continuação](coordination/tasks/2026-10-21-codex-b-concluir-base-preview.md).

A HUD, o mapa editado e a posição do rebirth junto ao saldo foram preservados. Os relatórios anteriores incluem integração com dois clientes, regressões do servidor e ensaio móvel no simulador; não são certificação da nova etapa. O teste visual do fluxo novo fica com o usuário, conforme a passagem anterior. O teste em celular físico e a rodada geral final de bugs continuam pendentes. Monetização, trocas e produção offline ficam para outra etapa.

O repositório é público por solicitação do proprietário. A criação deste repositório não publica a experiência no Roblox.
