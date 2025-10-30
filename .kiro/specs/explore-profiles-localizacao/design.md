# Design Document: Explore Profiles - Sistema de Localização

## Overview
Design de uma interface elegante e moderna para o sistema de localização do Explore Profiles, permitindo aos usuários configurar sua localização principal (automática) e até 2 localizações adicionais de interesse, com restrições de edição mensal.

## Architecture

### Componentes Principais
```
ExploreProfilesView (Atualizada)
├── Header com Título Motivacional
├── Filtros de Localização (Novo)
│   ├── Localização Principal (Read-only)
│   ├── Localizações Adicionais (Editável)
│   └── Botão Adicionar Localização
├── Lista de Perfis (Existente)
└── Profile Cards (Existente)
```

### Novos Componentes
1. **LocationFilterSection** - Seção de filtros de localização
2. **PrimaryLocationCard** - Card da localização principal
3. **AdditionalLocationCard** - Card de localização adicional
4. **LocationSelectorDialog** - Dialog para selecionar localização
5. **LocationEditRestrictionBadge** - Badge mostrando restrição de edição

## Components and Interfaces

### 1. LocationFilterSection

**Responsabilidade:** Container principal dos filtros de localização

**Interface:**
```dart
class LocationFilterSection extends StatelessWidget {
  final String? primaryCity;
  final String? primaryState;
  final List<AdditionalLocation> additionalLocations;
  final VoidCallback onAddLocation;
  final Function(int index) onRemoveLocation;
  final Function(int index) onEditLocation;
  final bool canAddMore;
  
  const LocationFilterSection({
    Key? key,
    this.primaryCity,
    this.primaryState,
    required this.additionalLocations,
    required this.onAddLocation,
    required this.onRemoveLocation,
    required this.onEditLocation,
    required this.canAddMore,
  }) : super(key: key);
}
```

**Layout:**
```
┌─────────────────────────────────────┐
│  📍 Localização de Encontros        │
├─────────────────────────────────────┤
│  🏠 Localização Principal           │
│  Bauru - SP                         │
│  (Automática do seu perfil)         │
├─────────────────────────────────────┤
│  📌 Localizações Adicionais (1/2)   │
│                                     │
│  ┌───────────────────────────────┐ │
│  │ 📍 São Paulo - SP             │ │
│  │ Editável em: 15 dias    ✏️ 🗑️ │ │
│  └───────────────────────────────┘ │
│                                     │
│  [+ Adicionar Localização]          │
└─────────────────────────────────────┘
```

### 2. PrimaryLocationCard

**Responsabilidade:** Exibir localização principal (não editável)

**Interface:**
```dart
class PrimaryLocationCard extends StatelessWidget {
  final String city;
  final String state;
  
  const PrimaryLocationCard({
    Key? key,
    required this.city,
    required this.state,
  }) : super(key: key);
}
```

**Estilo:**
- Background: Gradiente roxo/azul suave
- Ícone: 🏠 (casa) em destaque
- Texto: "Localização Principal" em bold
- Subtexto: "(Automática do seu perfil)" em cinza
- Não tem botões de ação

### 3. AdditionalLocationCard

**Responsabilidade:** Exibir e gerenciar localização adicional

**Interface:**
```dart
class AdditionalLocationCard extends StatelessWidget {
  final String city;
  final String state;
  final DateTime lastEditedAt;
  final bool canEdit;
  final VoidCallback onEdit;
  final VoidCallback onRemove;
  
  const AdditionalLocationCard({
    Key? key,
    required this.city,
    required this.state,
    required this.lastEditedAt,
    required this.canEdit,
    required this.onEdit,
    required this.onRemove,
  }) : super(key: key);
}
```

**Estilo:**
- Background: Branco com sombra suave
- Ícone: 📍 (pin de localização)
- Badge: "Editável em X dias" ou "Editável agora"
- Botões: Editar (✏️) e Remover (🗑️)
- Animação: Slide in ao adicionar, fade out ao remover

### 4. LocationSelectorDialog

**Responsabilidade:** Dialog para selecionar cidade e estado

**Interface:**
```dart
class LocationSelectorDialog extends StatefulWidget {
  final Function(String city, String state) onLocationSelected;
  
  const LocationSelectorDialog({
    Key? key,
    required this.onLocationSelected,
  }) : super(key: key);
}
```

**Layout:**
```
┌─────────────────────────────────────┐
│  Adicionar Localização              │
├─────────────────────────────────────┤
│                                     │
│  Estado:                            │
│  [Dropdown: SP ▼]                   │
│                                     │
│  Cidade:                            │
│  [Dropdown: São Paulo ▼]            │
│                                     │
│  ℹ️ Você pode editar esta           │
│     localização uma vez por mês     │
│                                     │
│  [Cancelar]  [Adicionar]            │
└─────────────────────────────────────┘
```

## Data Models

### AdditionalLocation Model

```dart
class AdditionalLocation {
  final String city;
  final String state;
  final DateTime addedAt;
  final DateTime? lastEditedAt;
  
  AdditionalLocation({
    required this.city,
    required this.state,
    required this.addedAt,
    this.lastEditedAt,
  });
  
  bool get canEdit {
    if (lastEditedAt == null) return true;
    final daysSinceEdit = DateTime.now().difference(lastEditedAt!).inDays;
    return daysSinceEdit >= 30;
  }
  
  int get daysUntilCanEdit {
    if (canEdit) return 0;
    final daysSinceEdit = DateTime.now().difference(lastEditedAt!).inDays;
    return 30 - daysSinceEdit;
  }
  
  Map<String, dynamic> toJson() => {
    'city': city,
    'state': state,
    'addedAt': Timestamp.fromDate(addedAt),
    'lastEditedAt': lastEditedAt != null 
        ? Timestamp.fromDate(lastEditedAt!) 
        : null,
  };
  
  factory AdditionalLocation.fromJson(Map<String, dynamic> json) {
    return AdditionalLocation(
      city: json['city'] as String,
      state: json['state'] as String,
      addedAt: (json['addedAt'] as Timestamp).toDate(),
      lastEditedAt: json['lastEditedAt'] != null
          ? (json['lastEditedAt'] as Timestamp).toDate()
          : null,
    );
  }
}
```

### Atualização do SpiritualProfileModel

```dart
// Adicionar ao SpiritualProfileModel
class SpiritualProfileModel {
  // ... campos existentes ...
  
  // Novos campos
  final List<AdditionalLocation>? additionalLocations;
  
  // Atualizar construtor e métodos fromJson/toJson
}
```

## UI/UX Design

### Cores e Tipografia

**Cores:**
- Primary: `#7B68EE` (Roxo médio)
- Secondary: `#4169E1` (Azul royal)
- Success: `#10B981` (Verde)
- Warning: `#F59E0B` (Laranja)
- Error: `#EF4444` (Vermelho)
- Background: `#F9FAFB` (Cinza muito claro)
- Card: `#FFFFFF` (Branco)

**Tipografia:**
- Título Principal: 24px, Bold, Roxo escuro
- Mensagem Motivacional: 14px, Regular, Cinza médio
- Título de Seção: 18px, SemiBold, Preto
- Texto de Card: 16px, Medium, Preto
- Subtexto: 14px, Regular, Cinza
- Badge: 12px, Medium, Branco

### Animações

1. **Adicionar Localização:**
   - Slide in from bottom (300ms)
   - Bounce effect ao final

2. **Remover Localização:**
   - Fade out (200ms)
   - Slide out to right (200ms)

3. **Botão Desabilitado:**
   - Opacity 0.5
   - Cursor not-allowed

4. **Hover States:**
   - Botões: Scale 1.05
   - Cards: Elevação aumenta

### Responsividade

**Mobile (< 600px):**
- Cards ocupam largura total
- Botões empilhados verticalmente
- Padding reduzido

**Tablet (600-900px):**
- Cards com max-width 500px
- Botões lado a lado
- Padding médio

**Desktop (> 900px):**
- Cards com max-width 600px
- Layout centralizado
- Padding generoso

## Error Handling

### Cenários de Erro

1. **Falha ao Carregar Localização Principal:**
   - Mostrar placeholder "Localização não disponível"
   - Sugerir completar perfil

2. **Falha ao Adicionar Localização:**
   - Snackbar vermelho: "Erro ao adicionar localização. Tente novamente."
   - Manter dialog aberto

3. **Falha ao Remover Localização:**
   - Snackbar vermelho: "Erro ao remover localização. Tente novamente."
   - Não remover da UI

4. **Limite de Localizações Atingido:**
   - Snackbar laranja: "Você já tem 2 localizações adicionais"
   - Desabilitar botão "Adicionar"

5. **Tentativa de Editar Antes de 30 Dias:**
   - Snackbar laranja: "Você poderá editar em X dias"
   - Mostrar tooltip explicativo

## Testing Strategy

### Unit Tests

1. **AdditionalLocation Model:**
   - Test `canEdit` logic
   - Test `daysUntilCanEdit` calculation
   - Test JSON serialization

2. **Location Controller:**
   - Test add location
   - Test remove location
   - Test edit restrictions
   - Test limit of 2 locations

### Widget Tests

1. **LocationFilterSection:**
   - Test rendering with 0, 1, 2 locations
   - Test add button enabled/disabled
   - Test remove button functionality

2. **AdditionalLocationCard:**
   - Test edit button enabled/disabled
   - Test days until edit display
   - Test remove confirmation

### Integration Tests

1. **Full Flow:**
   - Add location → Save → Reload → Verify
   - Remove location → Save → Reload → Verify
   - Edit restriction → Wait → Edit → Verify

## Performance Considerations

1. **Lazy Loading:**
   - Carregar localizações apenas quando necessário
   - Cache de estados/cidades

2. **Debouncing:**
   - Debounce de 300ms em buscas de cidade

3. **Optimistic Updates:**
   - Atualizar UI imediatamente
   - Reverter se falhar

4. **Firestore Queries:**
   - Usar índices compostos para busca por localização
   - Limitar resultados (pagination)

## Implementation Notes

### Ordem de Implementação

1. **Fase 1: Data Models**
   - Criar AdditionalLocation model
   - Atualizar SpiritualProfileModel
   - Criar migrations se necessário

2. **Fase 2: UI Components**
   - LocationFilterSection
   - PrimaryLocationCard
   - AdditionalLocationCard
   - LocationSelectorDialog

3. **Fase 3: Controller Logic**
   - Adicionar métodos ao ExploreProfilesController
   - Implementar validações
   - Implementar persistência

4. **Fase 4: Integration**
   - Integrar com ExploreProfilesView
   - Conectar com busca de perfis
   - Testar fluxo completo

5. **Fase 5: Polish**
   - Adicionar animações
   - Refinar estilos
   - Adicionar feedback visual

## Dependencies

- `cloud_firestore`: Persistência de dados
- `get`: State management e navegação
- `intl`: Formatação de datas
- Componentes existentes do app

## Accessibility

1. **Semantic Labels:**
   - Todos os botões com labels descritivos
   - Ícones com tooltips

2. **Keyboard Navigation:**
   - Tab order lógico
   - Enter para confirmar ações

3. **Screen Readers:**
   - Anúncios de mudanças de estado
   - Descrições de ícones

4. **Color Contrast:**
   - Mínimo 4.5:1 para texto
   - Mínimo 3:1 para elementos interativos
