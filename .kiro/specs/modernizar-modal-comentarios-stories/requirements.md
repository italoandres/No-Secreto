# Requirements Document

## Introduction

Este documento define os requisitos para modernizar a interface do modal de comentários dos Stories, transformando-o de uma página tradicional em um modal deslizante moderno, inspirado nas melhores práticas de UX do Instagram e Telegram, mantendo toda a funcionalidade backend existente intacta.

## Glossary

- **Modal System**: O componente de interface que exibe os comentários sobre o conteúdo do Story
- **Bottom Sheet**: Painel deslizante que aparece da parte inferior da tela
- **Comment Card**: Cartão visual que representa um comentário individual
- **Engagement Actions**: Ações de interação (curtir, responder) disponíveis em cada comentário
- **Visual Hierarchy**: Organização visual que prioriza informações importantes
- **Pull-to-Dismiss**: Gesto de arrastar para baixo que fecha o modal
- **Story Viewer**: Tela principal que exibe os Stories em formato vertical

## Requirements

### Requirement 1

**User Story:** Como usuário visualizando um Story, eu quero que o modal de comentários deslize suavemente de baixo para cima, para que a experiência seja fluida e moderna como em apps populares

#### Acceptance Criteria

1. WHEN o usuário toca no botão "Comentários" durante a visualização de um Story, THE Modal System SHALL exibir usando showModalBottomSheet com isScrollControlled: true
2. WHEN o modal aparece, THE Modal System SHALL deslizar de baixo para cima com animação suave
3. WHEN o usuário arrasta o modal para baixo, THE Modal System SHALL permitir o gesto pull-to-dismiss
4. WHEN o usuário toca fora do modal, THE Modal System SHALL fechar automaticamente
5. WHILE o modal está aberto, THE Story Viewer SHALL permanecer visível em segundo plano com overlay escurecido

### Requirement 2

**User Story:** Como usuário lendo comentários, eu quero uma hierarquia visual clara nos cards de comentários, para que eu possa identificar rapidamente quem comentou, quando e o conteúdo

#### Acceptance Criteria

1. THE Comment Card SHALL exibir o nome do usuário com FontWeight.bold e fontSize: 16
2. THE Comment Card SHALL exibir a data/hora com fontSize: 12 e Colors.grey[600]
3. THE Comment Card SHALL exibir o texto do comentário com fontSize: 15 e cor de texto padrão
4. THE Comment Card SHALL posicionar o nome do usuário no topo do card
5. THE Comment Card SHALL posicionar a data/hora logo abaixo do nome, alinhada à esquerda

### Requirement 3

**User Story:** Como usuário interagindo com comentários, eu quero botões de ação visíveis e intuitivos, para que eu possa facilmente curtir e responder aos comentários

#### Acceptance Criteria

1. THE Engagement Actions SHALL exibir um ícone de coração (Icons.favorite_border) para reações
2. WHEN um comentário tem zero reações, THE Engagement Actions SHALL exibir o ícone de coração com "0" ao lado
3. THE Engagement Actions SHALL exibir um TextButton com texto "Responder" para iniciar respostas
4. WHEN o usuário toca no coração, THE Engagement Actions SHALL alternar para Icons.favorite preenchido
5. THE Engagement Actions SHALL posicionar os botões horizontalmente abaixo do texto do comentário

### Requirement 4

**User Story:** Como usuário navegando pelos comentários, eu quero ver claramente as diferentes seções (Chats em Alta, Chats Recentes, Chats do Pai), para que eu possa encontrar conversas relevantes rapidamente

#### Acceptance Criteria

1. THE Modal System SHALL exibir um cabeçalho fixo com título do Story e botão de voltar
2. THE Modal System SHALL organizar comentários em três seções distintas: "Chats em Alta", "Chats Recentes" e "Chats do Pai"
3. WHEN uma seção tem conteúdo, THE Modal System SHALL exibir um título de seção com fontSize: 18 e FontWeight.w600
4. THE Modal System SHALL usar ícones distintivos para cada seção (🔥 para Alta, 🌱 para Recentes, ✨ para Pai)
5. THE Modal System SHALL permitir scroll vertical contínuo através de todas as seções

### Requirement 5

**User Story:** Como usuário querendo comentar, eu quero um campo de entrada fixo na parte inferior, para que eu possa adicionar meu comentário a qualquer momento sem perder o contexto

#### Acceptance Criteria

1. THE Modal System SHALL exibir um campo de texto fixo na parte inferior do modal
2. THE Modal System SHALL manter o campo de entrada visível durante o scroll
3. WHEN o usuário toca no campo, THE Modal System SHALL expandir o teclado sem fechar o modal
4. THE Modal System SHALL exibir um botão "Enviar" ao lado do campo de texto
5. WHEN o campo está vazio, THE Modal System SHALL exibir placeholder "Escreva o que o Pai falou ao seu coração..."

### Requirement 6

**User Story:** Como usuário visualizando comentários populares, eu quero ver indicadores visuais de engajamento (número de respostas e reações), para que eu possa identificar conversas ativas

#### Acceptance Criteria

1. THE Comment Card SHALL exibir contador de respostas com ícone 💭 e número
2. THE Comment Card SHALL exibir contador de reações com ícone ❤️ e número
3. WHEN um comentário tem alta atividade (>20 reações ou >5 respostas), THE Comment Card SHALL destacar com borda sutil colorida
4. THE Comment Card SHALL exibir "Última resposta há X tempo" para comentários com respostas
5. THE Comment Card SHALL posicionar os contadores horizontalmente entre o nome e o texto do comentário

### Requirement 7

**User Story:** Como usuário do sistema, eu quero que todas as funcionalidades backend existentes continuem funcionando, para que nenhuma feature seja perdida na modernização

#### Acceptance Criteria

1. THE Modal System SHALL manter todas as chamadas existentes ao StoryInteractionsRepository
2. THE Modal System SHALL preservar a lógica de carregamento de comentários por storyId
3. THE Modal System SHALL manter a funcionalidade de adicionar novos comentários
4. THE Modal System SHALL preservar os listeners de atualização em tempo real
5. THE Modal System SHALL manter a integração com o modelo CommunityCommentModel sem alterações
