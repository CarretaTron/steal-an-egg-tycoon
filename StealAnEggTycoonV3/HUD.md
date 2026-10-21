# Etapa: HUD inspirada nas referências

- Atalhos coloridos com ícones, contorno preto, letras brancas e textura de studs.
- 🔨 Construir aparece somente dentro da própria tycoon. Máquinas, esteiras e melhorias ficam nesse menu. Sair da base fecha a construção e cancela a prévia.
- 📖 Livro fica abaixo do martelo e abre a grade das sete espécies, com silhuetas bloqueadas e detalhes da seleção. Habitats continuam acessíveis na aba própria.
- ♻️ Renascer tem botão próprio. O contador de rebirths acompanha o dinheiro.
- 📜 Missões abre os objetivos e recompensas. Não existe mais o painel permanente de objetivos na tela.
- Dinheiro verde em destaque no canto inferior esquerdo, com abreviações K/M/B/T. Barras de bateria e energia removidas da HUD.
- Abrir Missões ativa a orientação para o próximo objetivo. A seta permanece após fechar o menu e acompanha transporte de ovo, incubação, produção e exploração. Criaturas roubadas recebem orientação pelo anel externo, fora da praça segura.
- Em telas móveis, os atalhos usam duas colunas com alvos de pelo menos 44 pixels; martelo fica acima do livro. Menus abertos ocultam os atalhos e o dinheiro para evitar sobreposição.

Fontes alterados: Client/Client.client.luau e o novo Shared/HudGuide.luau. O empacotador foi ajustado para incluir módulos novos na pasta Shared correta. Backup anterior em Backups/AntesHUD.

Validação: compilação no Studio, sete itens no livro, martelo visível na própria base e oculto fora dela, abertura dos menus por cliques no computador e no simulador móvel, melhorias acessíveis pelo martelo e seta ativa depois de fechar Missões. Resultados em Testes/hud-interacao.json; desempenho no simulador em Testes/hud-desempenho-movel.json quando concluído. O simulador não substitui teste em celular físico.

Esta etapa altera a interface. Economia, combate, modelos e salvamento permanecem nos sistemas existentes. O projeto vinculado no Studio preserva suas outras alterações; o portátil continua reconstruindo o mapa a partir dos fontes do gerador.
