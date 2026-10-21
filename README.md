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
  Blender/                      # .blend, .blend1, gerador, geometria e 19 FBX
  Backups/                      # V2 e snapshots anteriores à continuação/HUD
  Resultados/                   # Entrega, cópias dos fontes, Blender e testes
  StealAnEggTycoonV3.rbxlx       # Projeto portátil do Roblox Studio
  package_project.py            # Montagem do portátil e manifesto
  verify_package.py             # Verificação da entrega
StealAnEggTycoonV3.rar           # Arquivo original, preservado
coordination/tasks/             # Um registro por tarefa dos desenvolvedores
docs/                          # Estado, coordenação e planejamento
.github/                       # Modelos de tarefa e pull request
```

Edite `Client/`, `Server/` e `Shared/`. `Resultados/Fontes/` contém cópias da entrega; editar somente essas cópias deixa o jogo e o pacote inconsistentes. Os snapshots e o RAR são históricos. Os arquivos binários cabem no Git normal; esta entrega não depende de Git LFS.

## Abrir e continuar

```sh
git clone https://github.com/CarretaTron/steal-an-egg-tycoon.git
cd steal-an-egg-tycoon
```

1. Clone este repositório e abra `StealAnEggTycoonV3/StealAnEggTycoonV3.rbxlx` no Roblox Studio.
2. Pressione Play. O portátil recria o mapa e as malhas por sessão. Para testar DataStore e permissões de malha, associe a cópia a uma experiência em que você tenha acesso. Consulte o LEIA-ME antes de habilitar ensaios.
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

Esse verificador confere os hashes e as cópias dos 24 fontes Luau, os 19 FBX, o arquivo Blender, a leitura do portátil, o backup da V2 e os oito scripts de ensaio desativados. Execute-o antes de entregar alterações no pacote. Os testes de jogabilidade continuam sendo realizados no Studio.

O exemplo [verificar-pacote.workflow.yml](docs/verificar-pacote.workflow.yml) permite automatizar essa verificação no GitHub. Para ativá-lo, um desenvolvedor com permissão de publicação de workflows pode copiá-lo para `.github/workflows/verify.yml`. Ele é entregue como exemplo e não está ativo.

Depois de alterar fontes, monte o portátil com `package_project.py`, atualize as cópias correspondentes em `Resultados/Fontes/` e a cópia do portátil na pasta principal, e execute o verificador. O empacotador parte do snapshot `Backups/AntesContinuacao/`; alterações manuais posteriores no mapa precisam ser exportadas e preservadas antes de reconstruir o pacote.

Os atributos do Git preservam os bytes dos arquivos para manter válidos os hashes da entrega e os backups originais.

A importação de 20/10/2026 foi validada por um clone novo do GitHub: os 140 arquivos versionados chegaram idênticos à pasta original, e o verificador do pacote passou também no clone.

## Estado da versão

A etapa mais recente é a HUD: martelo dentro da própria base, livro, rebirth e missões por botões, dinheiro em destaque e seta de orientação. Os relatórios incluem integração com dois clientes, regressões do servidor e ensaio móvel no simulador. O teste em celular físico e a rodada geral final de bugs ainda estão pendentes. Monetização, trocas e produção offline ficam para outra etapa.

O repositório é público por solicitação do proprietário. A criação deste repositório não publica a experiência no Roblox.
