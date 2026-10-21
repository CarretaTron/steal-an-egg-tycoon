# Tarefa: base fixa, orientação suave e paredes com janelas

| Campo | Valor |
|---|---|
| Status | in_progress |
| Responsável | codex-b, continuação do pedido do proprietário |
| Atualizado em | 2026-10-21, America/Sao_Paulo |
| Branch | codex-b/base-fixa-seta-paredes |
| Commit de partida | 62a925e37683ad28f651162946588c3df7fe32c2 |
| Pedido autorizado | Restaurar estrutura pronta, impedir posicionamento livre, oferecer ocultar seta, suavizar orientação e mudar paredes inspiradas na referência enviada |

## Interpretação e escopo

- Manter spawn na praça e escolha do terreno; restaurar estrutura e linha inicial prontas, com posições fixas e expansão por compra/upgrade validado pelo servidor.
- Preservar identidades, níveis, criaturas, incubações e valores pendentes de perfis anteriores ao converter layouts para posições fixas.
- Melhorar seta/caminho e permitir ocultar toda a orientação. Separar resolução de destino da renderização por quadro; evitar movimento a 6,7 atualizações por segundo.
- Paredes da base com blocos cinza e studs, janelas largas emolduradas, placa superior e lasers vermelhos; preservar piso, posição dos oito terrenos e mapa externo.
- Fontes previstos: Building, Bootstrap, Persistence, Config/novo layout compartilhado; Client/HudGuide; WorldFactory/Combat e módulo de estrutura. Atualizar pacote, mapa e documentação quando necessário.

## Sessões

- Studio 119288590672557, sessão f8a8ea27-5747-4b4a-b5fe-37098c6d329f, encontrado em Edit. Os 24 hashes dos fontes lidos correspondem ao estado entregue; preservar mudanças manuais do mapa.
- Somente a sessão principal aplica fontes/mapa. Sem Play/simulador automático, conforme a passagem de testes visuais para o usuário; compilar e executar ensaios offline pertinentes.
- Blender não precisa de novos modelos nesta etapa.

## Passagem

- Diagnóstico em andamento. O cliente atual atualiza a seta dentro da rotina limitada a 0,15 segundo; mover câmera/jogador entre atualizações causa os saltos vistos na referência.
- Publicar fontes e artefatos nesta branch durante a execução. Manter PR anterior atualizado ao integrar a continuação, sem perder o histórico.
