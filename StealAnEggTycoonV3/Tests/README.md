# Verificações offline da escolha de base

Os três ensaios do jogo usam Python 3 e o executável oficial do Luau. Não iniciam Studio, não acessam a rede e não alteram DataStores. Informe o caminho do Luau com `--luau`, pela variável `LUAU_BIN` ou disponibilize `luau` no PATH. A verificação do pacote usa apenas Python.

Na raiz do repositório:

```sh
python StealAnEggTycoonV3/Tests/claim_lifecycle_offline.py --luau /caminho/luau
python StealAnEggTycoonV3/Tests/combat_offline.py --luau /caminho/luau
python StealAnEggTycoonV3/Tests/client_preview_guide_offline.py --luau /caminho/luau
python StealAnEggTycoonV3/verify_package.py
python StealAnEggTycoonV3/Tests/verify_package_offline.py
```

Os programas carregam os fontes atuais. O ensaio de ciclo de vida isola as funções reais de escolha e rebirth e usa os módulos de persistência, construção e produção com dependências simuladas. Cobre kit guardado, concorrência, rollback, reentrada, incubação e pagamento único. O ensaio de combate verifica o módulo real e o contrato dos oito terrenos de `Map/scene.json`. O ensaio do guia executa os destinos e verifica separadamente os contratos estáticos do preview.

Resultados de 21/10/2026: 42 casos de ciclo de vida, 359 verificações de combate, 13 casos do guia e 28 contratos estáticos aprovados. O resultado não certifica física, renderização, replicação, toque nem funcionamento num celular real. O fluxo visual novo fica para teste manual, conforme a passagem do usuário.

Depois de editar fontes, execute `package_project.py` antes de `verify_package.py`. O portátil e as cópias em `Resultados/Fontes` precisam conter a mesma versão dos fontes principais.

`verify_package_offline.py` testa o verificador com nove adulterações em cópias temporárias: fonte, nome, tipo, hierarquia, duplicação, instância extra, ensaio habilitado e fonte ausente. As nove foram recusadas; os portáteis originais permaneceram intactos. Não precisa do Luau.
