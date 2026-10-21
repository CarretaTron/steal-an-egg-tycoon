# Mapa editado no Studio

Esta pasta preserva a praça circular ajustada manualmente, os caminhos, as oito bases, os sete biomas e as paredes externas do lugar `119288590672557`.

- `AuthoredMap.rbxm`: snapshot nativo completo dos sete objetos de raiz exportáveis do Workspace, com 1.562 instâncias. Preserva as malhas e propriedades originais para edição no Studio.
- `scene.json`: hierarquia tipada utilizada por `package_project.py` para incluir o mapa atual no portátil. Peças de malha dos ovos/guardiões viram pivôs transparentes no portátil; `WorldFactory` renova essas malhas a partir dos dados Blender ao iniciar a sessão.

## Depois de editar o mapa

As alterações no mundo existente passam diretamente para Play. Para que o outro computador e o portátil recebam essas alterações, também é necessário exportar os arquivos desta pasta e fazer commit.

1. Termine o teste e volte ao modo Editar. Leia e compare os scripts e as tarefas do outro desenvolvedor antes de usar a sessão compartilhada.
2. Execute `../export_authored_map.luau` pelo MCP. O resultado em `_G.EggTycoonMapExport` contém `Rows` e o buffer nativo `Serialized`. Grave `Rows` em `scene.json` por lotes e o buffer em `AuthoredMap.rbxm`, sem modificar a cena. Confira a contagem e o tamanho retornados pelo exportador.
3. Execute `python StealAnEggTycoonV3/package_project.py` e depois `python StealAnEggTycoonV3/verify_package.py`, na raiz do repositório.
4. Teste o portátil e envie o mapa, fontes e relatórios juntos com o registro da tarefa.

O exportador JSON recusa operações sólidas e malhas decorativas que não sabe reconstruir fielmente. Resolva a exportação dessas peças antes de gerar uma nova entrega; preserve sempre o snapshot nativo. Ele não remove objetos do mapa. Não importe o RBXM sobre outro mundo de mesmo nome: para restaurar a edição, use um lugar vazio ou compare e preserve a cena existente antes de substituir as raízes correspondentes.

Camera e Terrain ficam fora do snapshot de instâncias; o empacotador mantém esses objetos do projeto base. A cena atual usa peças para o chão e para as paredes.
