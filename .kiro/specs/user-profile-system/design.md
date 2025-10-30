# Design Document

## Overview

O sistema de perfil de usuário com username único (@) será integrado ao menu administrativo existente e utilizará a infraestrutura já implementada de validação de username. A funcionalidade permitirá edição de nome e criação/edição de username com verificação em tempo real de disponibilidade.

## Architecture

### Componentes Existentes (Reutilização)
- `UsernameRepository` - Gerenciamento de usernames no Firebase
- `UsernameValidator` - Validação de formato e regras
- `UsernameSettingsView` - Tela de edição (já implementada)
- `UsuarioModel` - Modelo de dados do usuário

### Novos Componentes
- Integração no menu `showAdminOpts()` 
- Atualização de strings de localização
- Melhorias na UI da tela existente

## Components and Interfaces

### 1. Menu Integration (chat_view.dart)

```dart
// Adicionar nova opção no showAdminOpts()
ListTile(
  title: Text(AppLanguage.lang('editar_perfil')),
  trailing: const Icon(Icons.keyboard_arrow_right),
  leading: const Icon(Icons.edit),
  onTap: () {
    Get.back();
    Get.to(() => UsernameSettingsView(user: user));
  },
),
```

### 2. Localization Updates (language.dart)

```dart
// Adicionar novas strings
'editar_perfil': 'Editar Perfil',
'username_disponivel': 'Username disponível!',
'username_indisponivel': 'Username não disponível',
'verificando_username': 'Verificando disponibilidade...',
'perfil_atualizado': 'Perfil atualizado com sucesso!',
```

### 3. Enhanced UsernameSettingsView

**Melhorias na UI:**
- Avatar com opção de mudança (placeholder)
- Melhor feedback visual para validação
- Sugestões de username mais inteligentes
- Loading states mais claros

### 4. Firebase Structure

```
Collection: usuarios/{userId}
{
  nome: string,
  username: string,
  imgUrl: string?,
  updatedAt: timestamp
}

Collection: usernames/{username}
{
  userId: string,
  username: string,
  createdAt: timestamp
}
```

## Data Models

### UsuarioModel Enhancement
```dart
class UsuarioModel {
  String? id;
  String? nome;
  String? username;  // Já existe
  String? imgUrl;
  // ... outros campos existentes
}
```

### UsernameValidationResult (Já existe)
```dart
class UsernameValidationResult {
  final bool isValid;
  final bool isAvailable;
  final String? errorMessage;
  final List<String> suggestions;
  final bool isChecking;
}
```

## Error Handling

### Validation Errors
- **Formato inválido**: Caracteres especiais, muito curto/longo
- **Username indisponível**: Já existe no sistema
- **Erro de rede**: Falha na verificação
- **Palavras reservadas**: Lista de termos proibidos

### Network Errors
- Timeout na verificação de disponibilidade
- Falha ao salvar no Firebase
- Conflito de concorrência (username tomado durante salvamento)

### User Feedback
- Loading indicators durante verificação
- Mensagens de erro claras e acionáveis
- Sugestões automáticas para usernames indisponíveis
- Confirmação de sucesso após salvamento

## Testing Strategy

### Unit Tests
- `UsernameValidator.validate()` - Todos os cenários de validação
- `UsernameRepository` - Métodos de verificação e salvamento
- Debounce logic - Timing correto das verificações

### Integration Tests
- Fluxo completo de edição de perfil
- Verificação em tempo real de username
- Salvamento e sincronização com Firebase

### UI Tests
- Navegação do menu para tela de edição
- Estados de loading e feedback visual
- Responsividade em diferentes tamanhos de tela

### Real-time Testing
- Teste com múltiplos usuários simultâneos
- Verificação de conflitos de username
- Performance da verificação em tempo real

## Implementation Flow

### Phase 1: Menu Integration
1. Adicionar opção "Editar Perfil" no `showAdminOpts()`
2. Adicionar strings de localização
3. Testar navegação

### Phase 2: UI Enhancements
1. Melhorar feedback visual na `UsernameSettingsView`
2. Adicionar placeholder para avatar
3. Otimizar layout mobile

### Phase 3: Real-time Testing
1. Testar com emulador Android
2. Verificar performance da validação
3. Testar cenários de erro

### Phase 4: Polish & Optimization
1. Melhorar sugestões de username
2. Otimizar debounce timing
3. Adicionar analytics (futuro)

## Security Considerations

### Username Validation
- Sanitização de input
- Prevenção de XSS através de caracteres especiais
- Rate limiting para verificações (futuro)

### Firebase Security Rules
```javascript
// Regra para coleção usernames
match /usernames/{username} {
  allow read: if true;
  allow write: if request.auth != null 
    && request.auth.uid == resource.data.userId;
}
```

### Data Privacy
- Username é público por design (rede social)
- Nome pode ser editado pelo próprio usuário
- Logs de debug não devem conter dados sensíveis

## Performance Considerations

### Debounce Strategy
- 500ms delay para verificação de username
- Cancelamento de requests pendentes
- Cache local de verificações recentes (futuro)

### Firebase Optimization
- Índices otimizados para queries de username
- Transações atômicas para evitar conflitos
- Cleanup de usernames órfãos

### Mobile Performance
- Lazy loading de sugestões
- Otimização de rebuilds desnecessários
- Memory management para controllers