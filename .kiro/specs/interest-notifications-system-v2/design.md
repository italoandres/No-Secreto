# Design do Sistema de Notificações de Interesse em Matches - V2

## Overview

O sistema será implementado seguindo exatamente a mesma arquitetura bem-sucedida do sistema de notificações do "nosso propósito". Utilizaremos os mesmos serviços, repositórios e modelos existentes, apenas adicionando novos componentes específicos para notificações de interesse em matches.

## Architecture

### Componentes Principais

1. **InterestNotificationComponent** - Componente visual para exibir o ícone de notificação na tela de matches
2. **Extensão do NotificationService** - Métodos específicos para criar notificações de interesse
3. **Integração com MatchesController** - Trigger para criar notificações quando interesse é demonstrado
4. **Reutilização da NotificationsView** - Usar a tela existente com contexto 'interest_matches'

### Fluxo de Dados

```
Usuário demonstra interesse → MatchesController → NotificationService → NotificationRepository → Firestore
                                                                                                      ↓
InterestNotificationComponent ← NotificationService ← NotificationRepository ← Stream do Firestore
```

## Components and Interfaces

### 1. InterestNotificationComponent

**Localização:** `lib/components/interest_notification_component.dart`

**Responsabilidades:**
- Exibir ícone de notificação na tela de matches
- Mostrar badge com contador de notificações não lidas
- Navegar para NotificationsView com contexto 'interest_matches'
- Usar StreamBuilder para atualizações em tempo real

**Interface:**
```dart
class InterestNotificationComponent extends StatelessWidget {
  const InterestNotificationComponent({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // Implementação idêntica ao NossoPropositoNotificationComponent
    // mas usando contexto 'interest_matches'
  }
}
```

### 2. Extensão do NotificationService

**Localização:** `lib/services/notification_service.dart` (extensão)

**Novos Métodos:**
```dart
// Criar notificação de interesse
static Future<void> createInterestNotification({
  required String interestedUserId,
  required String interestedUserName,
  required String interestedUserAvatar,
  required String targetUserId,
}) async

// Processar demonstração de interesse
static Future<void> processInterestNotification({
  required String interestedUserId,
  required String interestedUserName,
  required String interestedUserAvatar,
  required String targetUserId,
}) async
```

### 3. Integração com MatchesController

**Localização:** `lib/controllers/matches_controller.dart` (modificação)

**Modificações:**
- Adicionar chamada para `NotificationService.processInterestNotification()` quando interesse é demonstrado
- Importar e usar o NotificationService existente

### 4. Reutilização da NotificationsView

**Localização:** `lib/views/notifications_view.dart` (sem modificação)

**Uso:**
- Usar a tela existente passando `contexto: 'interest_matches'`
- O sistema existente já suporta contextos diferentes
- Não requer modificações na tela

## Data Models

### Reutilização do NotificationModel Existente

**Localização:** `lib/models/notification_model.dart` (sem modificação)

**Campos Utilizados:**
```dart
NotificationModel(
  id: 'interest_${targetUserId}_${interestedUserId}_${timestamp}',
  userId: targetUserId, // Quem recebe a notificação
  type: 'interest_match', // Novo tipo de notificação
  relatedId: interestedUserId, // ID do usuário que demonstrou interesse
  fromUserId: interestedUserId,
  fromUserName: interestedUserName,
  fromUserAvatar: interestedUserAvatar,
  content: 'demonstrou interesse no seu perfil',
  isRead: false,
  createdAt: DateTime.now(),
  contexto: 'interest_matches', // Contexto específico
)
```

## Error Handling

### Estratégias de Tratamento de Erro

1. **Falha na Criação de Notificação:**
   - Não bloquear o processo de demonstração de interesse
   - Log do erro para debugging
   - Continuar operação normalmente

2. **Falha na Conexão com Firestore:**
   - Retry automático (implementado no NotificationRepository existente)
   - Fallback para operação offline
   - Sincronização quando conexão for restaurada

3. **Falha na Atualização da UI:**
   - StreamBuilder com tratamento de erro
   - Exibição de estado de erro amigável
   - Botão de retry se necessário

## Testing Strategy

### Testes Unitários

1. **InterestNotificationComponent:**
   - Teste de renderização com diferentes contadores
   - Teste de navegação ao clicar
   - Teste de atualização em tempo real

2. **NotificationService (extensão):**
   - Teste de criação de notificação de interesse
   - Teste de processamento de interesse
   - Teste de tratamento de erros

3. **Integração com MatchesController:**
   - Teste de trigger de notificação ao demonstrar interesse
   - Teste de não criação de notificação para auto-interesse

### Testes de Integração

1. **Fluxo Completo:**
   - Usuário A demonstra interesse em usuário B
   - Notificação é criada no Firestore
   - Usuário B vê a notificação na UI
   - Usuário B clica e navega para o perfil

2. **Testes de Performance:**
   - Múltiplas notificações simultâneas
   - Atualização em tempo real com muitos usuários
   - Limpeza automática de notificações antigas

## Implementation Notes

### Padrões a Seguir

1. **Reutilização Máxima:**
   - Usar exatamente a mesma estrutura do NossoPropositoNotificationComponent
   - Não modificar serviços existentes, apenas estender
   - Reutilizar NotificationsView sem modificações

2. **Consistência Visual:**
   - Mesmo estilo de ícone e badge
   - Mesma animação (se implementada)
   - Mesma navegação e comportamento

3. **Contexto Isolado:**
   - Usar 'interest_matches' como contexto
   - Não interferir com outras notificações
   - Permitir gerenciamento independente

### Pontos de Integração

1. **MatchesController:**
   - Adicionar uma linha de código no método que processa interesse
   - Importar NotificationService
   - Chamar processInterestNotification()

2. **MatchesListView:**
   - Adicionar InterestNotificationComponent na AppBar ou área apropriada
   - Posicionamento similar ao usado no nosso propósito

3. **Firestore:**
   - Usar a mesma coleção 'notifications'
   - Usar os mesmos índices existentes
   - Aproveitar as regras de segurança já configuradas

## Performance Considerations

### Otimizações

1. **Stream Efficiency:**
   - Usar o mesmo padrão de Stream do NotificationService existente
   - Filtrar por contexto no nível do Firestore
   - Cache automático do GetX

2. **UI Updates:**
   - StreamBuilder com builder otimizado
   - Evitar rebuilds desnecessários
   - Usar const constructors onde possível

3. **Memory Management:**
   - Dispose automático dos streams
   - Cleanup de listeners
   - Reutilização de widgets

## Security Considerations

### Validações

1. **Autorização:**
   - Verificar se usuário pode criar notificação
   - Validar IDs de usuário
   - Prevenir spam de notificações

2. **Dados Sensíveis:**
   - Não expor informações privadas
   - Usar apenas dados públicos do perfil
   - Respeitar configurações de privacidade

3. **Rate Limiting:**
   - Prevenir múltiplas notificações do mesmo usuário
   - Implementar cooldown se necessário
   - Validar frequência de interesse