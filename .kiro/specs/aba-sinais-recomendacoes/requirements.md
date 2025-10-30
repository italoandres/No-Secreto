# Requirements Document - Aba Sinais com Recomendações Semanais

## Introduction

A Aba Sinais é o coração do sistema de matching do aplicativo, onde usuários recebem recomendações personalizadas de perfis compatíveis baseadas em valores, princípios e compatibilidade espiritual. Diferente de outros aplicativos de namoro que priorizam aparência física, a Aba Sinais equilibra foto e informações de valores (50/50), destacando compatibilidade profunda antes da atração superficial.

## Glossary

- **Sistema de Sinais**: Interface de recomendação de perfis compatíveis
- **Recomendação Semanal**: Conjunto de até 6 perfis sugeridos por semana
- **Match Score**: Pontuação de compatibilidade calculada pelo algoritmo de matching
- **Card de Perfil**: Componente visual que exibe foto e valores de um perfil recomendado
- **Valores Destacados**: Informações de princípios e compatibilidade exibidas no card
- **Interesse Mútuo**: Quando dois usuários demonstram interesse um pelo outro
- **Refresh Semanal**: Renovação automática das recomendações toda segunda-feira

## Requirements

### Requirement 1

**User Story:** Como usuário do aplicativo, quero receber recomendações semanais de perfis compatíveis baseadas em meus valores e preferências, para que eu possa conhecer pessoas com compatibilidade profunda.

#### Acceptance Criteria

1. WHEN o usuário acessa a aba Sinais pela primeira vez na semana, THE Sistema de Sinais SHALL carregar até 6 perfis recomendados baseados no algoritmo de matching
2. WHILE o usuário visualiza a aba Sinais, THE Sistema de Sinais SHALL exibir contador indicando quantos perfis restam para visualizar na semana atual
3. WHEN todas as recomendações da semana são visualizadas, THE Sistema de Sinais SHALL exibir mensagem informando que novas recomendações estarão disponíveis na próxima segunda-feira
4. WHEN chega segunda-feira às 00:00, THE Sistema de Sinais SHALL renovar automaticamente as recomendações semanais
5. WHERE o usuário possui perfil completo e filtros configurados, THE Sistema de Sinais SHALL priorizar perfis com maior match score

### Requirement 2

**User Story:** Como usuário visualizando um perfil recomendado, quero ver a foto ocupando metade superior da tela e valores/princípios na metade inferior, para que eu possa avaliar compatibilidade antes de aparência.

#### Acceptance Criteria

1. THE Card de Perfil SHALL dividir a tela verticalmente em duas seções iguais (50% superior para foto, 50% inferior para valores)
2. THE Card de Perfil SHALL exibir foto principal do perfil na seção superior com qualidade otimizada
3. THE Card de Perfil SHALL exibir na seção inferior os seguintes Valores Destacados: certificação espiritual, match score, movimento Deus é Pai, virgindade, educação, idiomas e hobbies em comum
4. WHEN um valor possui alta compatibilidade (score > 80%), THE Card de Perfil SHALL destacar visualmente este valor com ícone e cor diferenciada
5. THE Card de Perfil SHALL exibir nome, idade e cidade do perfil recomendado

### Requirement 3

**User Story:** Como usuário avaliando um perfil recomendado, quero poder demonstrar interesse ou passar para o próximo perfil, para que eu possa gerenciar minhas recomendações de forma eficiente.

#### Acceptance Criteria

1. THE Card de Perfil SHALL exibir dois botões de ação na parte inferior: "Demonstrar Interesse" e "Passar"
2. WHEN o usuário clica em "Demonstrar Interesse", THE Sistema de Sinais SHALL registrar o interesse e notificar o perfil recomendado
3. WHEN o usuário clica em "Passar", THE Sistema de Sinais SHALL remover o card atual e exibir próximo perfil recomendado
4. WHEN ocorre interesse mútuo (ambos demonstraram interesse), THE Sistema de Sinais SHALL criar match e notificar ambos usuários
5. THE Sistema de Sinais SHALL permitir gestos de swipe (direita para interesse, esquerda para passar)

### Requirement 4

**User Story:** Como usuário interessado em um perfil, quero poder visualizar informações detalhadas antes de demonstrar interesse, para que eu possa tomar decisão informada.

#### Acceptance Criteria

1. WHEN o usuário toca na área de valores do Card de Perfil, THE Sistema de Sinais SHALL expandir card mostrando informações completas do perfil
2. THE Sistema de Sinais SHALL exibir no card expandido: galeria de fotos, biografia, valores espirituais detalhados, hobbies completos e localização
3. THE Sistema de Sinais SHALL permitir navegação entre fotos do perfil através de gestos horizontais
4. WHEN o usuário fecha o card expandido, THE Sistema de Sinais SHALL retornar à visualização padrão do card
5. THE Sistema de Sinais SHALL manter botões de ação visíveis mesmo no card expandido

### Requirement 5

**User Story:** Como usuário que demonstrou interesse em perfis, quero visualizar lista de interesses pendentes e matches confirmados, para que eu possa acompanhar minhas conexões.

#### Acceptance Criteria

1. THE Sistema de Sinais SHALL exibir aba secundária "Meus Interesses" mostrando perfis onde demonstrei interesse
2. THE Sistema de Sinais SHALL exibir aba secundária "Matches" mostrando perfis com interesse mútuo confirmado
3. WHEN ocorre novo match, THE Sistema de Sinais SHALL exibir animação celebratória e permitir envio de primeira mensagem
4. THE Sistema de Sinais SHALL ordenar lista de matches por data mais recente primeiro
5. WHILE aguardando resposta de interesse, THE Sistema de Sinais SHALL exibir status "Aguardando resposta" no perfil

### Requirement 6

**User Story:** Como usuário sem recomendações disponíveis, quero entender por que não recebi sugestões e como melhorar minhas chances, para que eu possa otimizar meu perfil.

#### Acceptance Criteria

1. WHEN não há perfis compatíveis disponíveis, THE Sistema de Sinais SHALL exibir mensagem explicativa com sugestões de melhoria
2. THE Sistema de Sinais SHALL sugerir ações como: completar perfil, ajustar filtros, expandir localização ou aguardar novos usuários
3. WHEN o perfil do usuário está incompleto, THE Sistema de Sinais SHALL exibir botão direcionando para completar perfil
4. WHEN os filtros são muito restritivos, THE Sistema de Sinais SHALL sugerir ajuste de preferências
5. THE Sistema de Sinais SHALL exibir estatísticas de compatibilidade do usuário (quantos perfis correspondem aos filtros)

### Requirement 7

**User Story:** Como usuário visualizando recomendações, quero entender por que cada perfil foi recomendado, para que eu possa confiar no algoritmo de matching.

#### Acceptance Criteria

1. THE Card de Perfil SHALL exibir badge com percentual de compatibilidade (Match Score)
2. WHEN o usuário toca no Match Score, THE Sistema de Sinais SHALL exibir breakdown detalhado mostrando pontuação por categoria
3. THE Sistema de Sinais SHALL destacar visualmente os 3 principais fatores de compatibilidade
4. THE Sistema de Sinais SHALL exibir ícones indicativos para valores em comum (ex: ambos certificados, ambos do movimento)
5. WHERE há hobbies em comum, THE Sistema de Sinais SHALL listar especificamente quais hobbies são compartilhados

### Requirement 8

**User Story:** Como usuário do aplicativo, quero receber notificações sobre novas recomendações e matches, para que eu não perca oportunidades de conexão.

#### Acceptance Criteria

1. WHEN novas recomendações semanais são disponibilizadas, THE Sistema de Sinais SHALL enviar notificação push informando quantidade de novos perfis
2. WHEN ocorre match mútuo, THE Sistema de Sinais SHALL enviar notificação push imediata para ambos usuários
3. WHEN alguém demonstra interesse no perfil do usuário, THE Sistema de Sinais SHALL enviar notificação informando novo interesse
4. THE Sistema de Sinais SHALL respeitar configurações de notificação do usuário
5. THE Sistema de Sinais SHALL agrupar múltiplas notificações do mesmo tipo para evitar spam

### Requirement 9

**User Story:** Como usuário mobile, quero que a interface seja responsiva e fluida, para que eu tenha experiência agradável ao navegar pelos perfis.

#### Acceptance Criteria

1. THE Card de Perfil SHALL carregar fotos de forma progressiva (placeholder → baixa qualidade → alta qualidade)
2. THE Sistema de Sinais SHALL implementar animações suaves de transição entre cards (300ms)
3. WHEN o usuário realiza swipe, THE Sistema de Sinais SHALL fornecer feedback visual imediato
4. THE Sistema de Sinais SHALL funcionar offline mostrando perfis já carregados e sincronizar ações quando reconectar
5. THE Sistema de Sinais SHALL otimizar consumo de dados carregando apenas imagens necessárias

### Requirement 10

**User Story:** Como administrador do sistema, quero monitorar métricas de engajamento da aba Sinais, para que eu possa otimizar o algoritmo de matching.

#### Acceptance Criteria

1. THE Sistema de Sinais SHALL registrar taxa de interesse (quantos perfis recebem interesse vs. são passados)
2. THE Sistema de Sinais SHALL registrar tempo médio de visualização por perfil
3. THE Sistema de Sinais SHALL registrar taxa de conversão (interesse → match → conversa)
4. THE Sistema de Sinais SHALL registrar quais valores destacados recebem mais atenção
5. THE Sistema de Sinais SHALL gerar relatório semanal de performance do algoritmo de matching
