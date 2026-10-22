# Base industrial sem cercas — revisão 4

Criação atual sem as faixas baixas de madeira. O gerador build_base.py cria uma cena nova BaseIndustrialSemCercas, preservando cenas anteriores, e exporta seis malhas (12.864 vértices, 19.632 triângulos). BaseIndustrial.blend, Exportacoes/BaseIndustrial.fbx, geometry.json e installation-spec.json pertencem a esta revisão.

A geometria das seis partes restantes não mudou; o Studio reutiliza os seis IDs permanentes de Shared/BaseIndustrialData.luau. A cena anterior com sete malhas continua histórica em Blender/BaseIndustrial/. Não reintroduzir BI_CercaMadeira ao atualizar os fontes ou importar modelos.

O teto continua opaco. O Client não usa mais LocalTransparencyModifier para ocultar a cobertura ao entrar ou construir. Os fontes oficiais são Client/Client.client.luau e Shared/BaseShell.luau/BaseIndustrialData.luau no checkout gerenciado bases-laser.
