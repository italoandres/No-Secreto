# Implementation Plan

- [x] 1. Criar componentes base de UI modernos



  - Criar componentes visuais fundamentais que serão reutilizados
  - Implementar hierarquia visual e estilos consistentes
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_


- [x] 1.1 Criar ModalHeader component


  - Implementar lib/components/stories/modal_header.dart
  - Incluir botão de voltar, título do Story e descrição expansível
  - Aplicar estilos: título bold 16px, descrição grey 13px
  - Adicionar funcionalidade "Ver mais/Ver menos" para descrição
  - _Requirements: 4.1, 2.1, 2.2_

- [x] 1.2 Criar SectionHeader component


  - Implementar lib/components/stories/section_header.dart
  - Suportar três tipos: "Chats em Alta" (🔥), "Chats Recentes" (🌱), "Chats do Pai" (✨)
  - Aplicar cores específicas por seção (orange, green, purple)
  - Estilo: fontSize 18, FontWeight.w600
  - _Requirements: 4.2, 4.3, 4.4_

- [x] 1.3 Criar EngagementActionsRow component


  - Implementar lib/components/stories/engagement_actions_row.dart
  - Adicionar botão de curtir com ícone de coração (outline/filled)
  - Adicionar botão "Responder" com ícone de chat
  - Implementar animação de scale (0.95) ao tocar
  - Exibir contadores mesmo quando zero
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

- [x] 1.4 Criar FixedCommentInput component


  - Implementar lib/components/stories/fixed_comment_input.dart
  - TextField com border radius 24px e background grey[100]
  - Placeholder: "Escreva o que o Pai falou ao seu coração..."
  - Botão enviar circular (44px) que desabilita quando vazio
  - Altura fixa de 60px com border top
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_

- [x] 2. Refatorar ModernCommentCard com hierarquia visual



  - Transformar o card existente em versão moderna com visual hierarchy clara
  - Implementar layout inspirado no Instagram/Telegram
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 6.1, 6.2, 6.3, 6.4, 6.5_

- [x] 2.1 Criar UserInfoRow sub-component


  - Implementar lib/components/stories/user_info_row.dart
  - Layout: foto de perfil (32px) + nome (bold 16px) + timestamp (grey 12px)
  - Posicionar timestamp alinhado à direita
  - _Requirements: 2.1, 2.2_

- [x] 2.2 Criar CommentText sub-component


  - Implementar lib/components/stories/comment_text.dart
  - Estilo: fontSize 15, cor black87, fontWeight normal
  - Suportar múltiplas linhas com quebra automática
  - _Requirements: 2.3_


- [x] 2.3 Criar StatsRow sub-component

  - Implementar lib/components/stories/stats_row.dart
  - Exibir: ❤️ [count] 💭 [count] "Última resposta há X"
  - Estilo: fontSize 13, fontWeight w500, cor grey[700]
  - Posicionar entre nome e texto do comentário
  - _Requirements: 6.1, 6.2, 6.4_

- [x] 2.4 Refatorar ModernCommentCard integrando sub-components


  - Atualizar lib/components/community_comment_card.dart
  - Integrar UserInfoRow, StatsRow, CommentText e EngagementActionsRow
  - Aplicar padding 16px, margin bottom 12px, border radius 12px
  - Background: grey[50] para normal, gradient para destacados
  - Adicionar parâmetro isHighlighted para "Chats em Alta"
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 6.3_

- [x] 3. Implementar lógica de categorização de comentários



  - Criar sistema para organizar comentários em seções
  - Implementar algoritmo de classificação baseado em engajamento
  - _Requirements: 4.2, 4.4, 6.3_

- [x] 3.1 Criar modelo SectionedComments


  - Implementar lib/models/sectioned_comments.dart
  - Definir enum CommentSection (trending, recent, featured)
  - Criar classe SectionedComments com listas separadas
  - _Requirements: 4.2_


- [x] 3.2 Implementar lógica de categorização

  - Criar lib/services/comment_categorizer_service.dart
  - trending: comentários com >20 reações OU >5 respostas
  - recent: comentários <24h com baixo engajamento
  - featured: comentários com isPinned = true
  - Ordenar trending por engajamento total (reações + respostas)
  - Ordenar recent por timestamp (mais recente primeiro)
  - _Requirements: 4.2, 4.4, 6.3_

- [x] 4. Criar ModernCommunityCommentsView com Bottom Sheet


  - Implementar view principal usando showModalBottomSheet
  - Substituir navegação tradicional por modal deslizante
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 4.1, 4.5, 5.1, 5.2_


- [x] 4.1 Criar estrutura base do ModernCommunityCommentsView

  - Implementar lib/views/stories/modern_community_comments_view.dart
  - Usar DraggableScrollableSheet com initialChildSize: 0.9
  - Configurar minChildSize: 0.5, maxChildSize: 0.95
  - Aplicar borderRadius superior (20px) e background branco
  - _Requirements: 1.1, 1.2, 1.3_

- [x] 4.2 Integrar ModalHeader no topo

  - Adicionar ModalHeader como widget fixo no topo
  - Passar storyTitle e storyDescription como parâmetros
  - Implementar callback onClose para fechar modal
  - _Requirements: 4.1, 5.1_

- [x] 4.3 Implementar área scrollável com seções

  - Criar ListView.builder para conteúdo scrollável
  - Renderizar SectionHeader + lista de cards para cada seção
  - Ordem: Chats em Alta → Chats Recentes → Chats do Pai
  - Aplicar padding e espaçamento entre seções
  - _Requirements: 4.2, 4.3, 4.4, 4.5_

- [x] 4.4 Integrar FixedCommentInput no rodapé

  - Adicionar FixedCommentInput como widget fixo na parte inferior
  - Implementar callback onSubmit para adicionar comentário
  - Garantir que permanece visível durante scroll
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_

- [x] 4.5 Conectar com StoryInteractionsRepository

  - Carregar comentários usando repository existente
  - Implementar listener para atualizações em tempo real
  - Categorizar comentários usando CommentCategorizerService
  - Atualizar UI quando novos comentários chegarem
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

- [x] 5. Atualizar EnhancedStoriesViewerView para usar Bottom Sheet



  - Modificar chamada de navegação para usar showModalBottomSheet
  - Manter código antigo como fallback
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 7.1, 7.2, 7.3, 7.4, 7.5_

- [x] 5.1 Substituir Navigator.push por showModalBottomSheet


  - Localizar botão "Comentários" em lib/views/enhanced_stories_viewer_view.dart
  - Substituir MaterialPageRoute por showModalBottomSheet
  - Configurar isScrollControlled: true
  - Passar storyId, storyTitle e storyDescription
  - _Requirements: 1.1, 1.2_


- [x] 5.2 Adicionar configurações de modal

  - backgroundColor: Colors.transparent (para ver overlay)
  - enableDrag: true (permitir pull-to-dismiss)
  - isDismissible: true (fechar ao tocar fora)
  - shape: RoundedRectangleBorder com borderRadius superior
  - _Requirements: 1.2, 1.3, 1.4_


- [x] 5.3 Manter código antigo como fallback




  - Envolver nova implementação em try-catch
  - Se showModalBottomSheet falhar, usar Navigator.push antigo
  - Adicionar log para monitorar falhas
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

- [x] 6. Implementar funcionalidades de interação



  - Adicionar lógica de curtir e responder comentários
  - Conectar com backend existente
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 7.1, 7.2, 7.3, 7.4, 7.5_


- [x] 6.1 Implementar funcionalidade de curtir

  - Adicionar método toggleLike em ModernCommunityCommentsView
  - Chamar StoryInteractionsRepository.likeComment
  - Atualizar estado local imediatamente (optimistic update)
  - Alternar ícone entre outline e filled
  - Animar transição com scale animation
  - _Requirements: 3.1, 3.4, 7.1, 7.2_


- [x] 6.2 Implementar funcionalidade de responder

  - Adicionar método onReply em ModernCommunityCommentsView
  - Navegar para tela de respostas (preparar para Etapa 5)
  - Passar commentId e dados do comentário pai
  - _Requirements: 3.3, 3.5_


- [x] 6.3 Implementar envio de novo comentário

  - Conectar FixedCommentInput.onSubmit com repository
  - Chamar StoryInteractionsRepository.addComment
  - Limpar campo após envio bem-sucedido
  - Mostrar feedback visual (SnackBar ou animação)
  - Scroll automático para o novo comentário
  - _Requirements: 5.3, 5.4, 5.5, 7.2, 7.3_

- [x] 7. Adicionar animações e polimentos finais

  - Implementar animações suaves e feedback visual
  - Garantir experiência fluida
  - _Requirements: 1.2, 1.3, 3.4, 6.3_


- [x] 7.1 Adicionar animação de abertura do modal

  - Configurar duration: 300ms com Curves.easeOutCubic
  - Garantir deslize suave de baixo para cima
  - _Requirements: 1.2_


- [x] 7.2 Adicionar animação de pull-to-dismiss
  - Implementar gesto de arrastar para baixo
  - Adicionar indicador visual (barra horizontal no topo)
  - Fechar modal quando arrastado além do threshold
  - _Requirements: 1.3_


- [x] 7.3 Adicionar animações de botões
  - Implementar scale animation (0.95) ao tocar botões
  - Duration: 150ms com Curves.easeInOut
  - Aplicar em todos os botões de ação

  - _Requirements: 3.4_

- [x] 7.4 Adicionar animação de like
  - Implementar scale animation especial para coração
  - Scale: 1.0 → 1.2 → 1.0
  - Duration: 200ms com Curves.elasticOut

  - Adicionar mudança de cor suave
  - _Requirements: 3.4, 6.3_

- [x] 7.5 Adicionar estados de loading e empty


  - Criar widget de loading (shimmer effect) para comentários
  - Criar estado vazio com ilustração e mensagem amigável
  - Adicionar botão "Seja o primeiro a comentar"
  - _Requirements: 4.5_

- [ ] 8. Testes e validação
  - Escrever testes para garantir qualidade
  - Validar comportamento em diferentes cenários
  - _Requirements: Todos_

- [ ] 8.1 Escrever testes unitários para CommentCategorizerService
  - Testar categorização de comentários trending
  - Testar categorização de comentários recent
  - Testar categorização de comentários featured
  - Validar ordenação dentro de cada categoria
  - _Requirements: 4.2, 4.4_

- [ ] 8.2 Escrever widget tests para componentes
  - Testar ModernCommentCard com diferentes dados
  - Testar EngagementActionsRow (like/unlike)
  - Testar FixedCommentInput (validação e envio)
  - Testar ModalHeader (expansão de descrição)
  - _Requirements: 2.1, 2.2, 2.3, 3.1, 3.2, 3.3, 5.4, 5.5_

- [ ] 8.3 Escrever integration tests para fluxo completo
  - Testar abertura do modal a partir do Story
  - Testar envio de comentário e aparição na lista
  - Testar curtir comentário e atualização de contador
  - Testar pull-to-dismiss
  - _Requirements: 1.1, 1.2, 1.3, 3.4, 5.3, 6.3_

- [x] 9. Documentação e cleanup



  - Documentar novos componentes
  - Remover código não utilizado
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

- [x] 9.1 Adicionar documentação inline

  - Documentar todos os novos componentes com dartdoc
  - Adicionar exemplos de uso nos comentários
  - Documentar parâmetros e callbacks
  - _Requirements: Todos_


- [x] 9.2 Criar guia de teste visual

  - Criar arquivo GUIA_TESTE_MODAL_MODERNO.md
  - Incluir screenshots do antes/depois
  - Listar cenários de teste manual
  - Documentar comportamentos esperados
  - _Requirements: Todos_


- [ ] 9.3 Avaliar remoção de código antigo
  - Após validação completa, considerar remover CommunityCommentsView antiga
  - Manter por enquanto como fallback
  - Adicionar comentário de deprecation
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_
