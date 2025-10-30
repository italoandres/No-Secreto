# Design Document

## Overview

O refinamento da vitrine de propósito visa criar uma apresentação visual completa e organizada do perfil espiritual do usuário. O design seguirá uma estrutura hierárquica com a foto e nome centralizados no topo, seguidos por seções organizadas de informações pessoais, espirituais e de relacionamento.

## Architecture

### Component Structure
```
EnhancedVitrineDisplayView (Refined)
├── ProfileHeaderSection
│   ├── ProfilePhotoWidget
│   ├── ProfileNameWidget
│   └── VerificationBadgeWidget
├── BasicInfoSection
│   ├── LocationWidget
│   ├── AgeWidget
│   └── MovementBadgeWidget
├── SpiritualInfoSection
│   ├── PurposeWidget
│   ├── FaithPhraseWidget
│   └── RelationshipReadinessWidget
├── RelationshipStatusSection
│   ├── MaritalStatusWidget
│   ├── ChildrenStatusWidget
│   ├── VirginityStatusWidget (optional)
│   └── PreviousMarriageWidget
└── AdditionalInfoSection
    ├── NonNegotiableValueWidget
    └── AboutMeWidget
```

### Data Flow
```
SpiritualProfileModel → EnhancedVitrineDisplayView → UI Components
```

## Components and Interfaces

### 1. ProfileHeaderSection
**Responsabilidade:** Exibir foto, nome e badge de verificação centralizados

**Interface:**
```dart
class ProfileHeaderSection extends StatelessWidget {
  final String? photoUrl;
  final String displayName;
  final bool hasVerification;
  final String? username;
}
```

**Layout:**
- Foto circular (120x120) centralizada
- Nome em fonte grande e bold abaixo da foto
- Username em fonte menor e cinza
- Badge de verificação sobreposto à foto (canto inferior direito)

### 2. BasicInfoSection
**Responsabilidade:** Mostrar informações básicas visíveis

**Interface:**
```dart
class BasicInfoSection extends StatelessWidget {
  final String? city;
  final int? age;
  final bool? isDeusEPaiMember;
}
```

**Layout:**
- Cards horizontais com ícones
- Localização com ícone de pin
- Idade com ícone de calendário
- Movimento "Deus é Pai" com badge especial

### 3. SpiritualInfoSection
**Responsabilidade:** Exibir informações espirituais e de propósito

**Interface:**
```dart
class SpiritualInfoSection extends StatelessWidget {
  final String? purpose;
  final String? faithPhrase;
  final bool? readyForPurposefulRelationship;
  final String? nonNegotiableValue;
}
```

### 4. RelationshipStatusSection
**Responsabilidade:** Mostrar status de relacionamento e informações familiares

**Interface:**
```dart
class RelationshipStatusSection extends StatelessWidget {
  final RelationshipStatus? relationshipStatus;
  final bool? hasChildren;
  final bool? isVirgin;
  final bool? wasPreviouslyMarried;
}
```

### 5. Enhanced SpiritualProfileModel
**Novos campos necessários:**
```dart
class SpiritualProfileModel {
  // Campos existentes...
  
  // Novos campos para refinamento
  bool? hasChildren;
  bool? isVirgin;
  bool? wasPreviouslyMarried;
  String? childrenDetails; // "2 filhos" ou "Sem filhos"
  
  // Campos de localização mais detalhados
  String? state; // "SP", "RJ", etc.
  String? fullLocation; // "São Paulo - SP"
}
```

## Data Models

### Enhanced Profile Data Structure
```dart
// Estrutura expandida para incluir novos campos
Map<String, dynamic> profileData = {
  // Informações básicas
  'displayName': 'João Silva',
  'username': '@joao_silva',
  'mainPhotoUrl': 'https://...',
  'age': 28,
  'city': 'São Paulo',
  'state': 'SP',
  'fullLocation': 'São Paulo - SP',
  
  // Informações espirituais
  'purpose': 'Servir a Deus e formar uma família cristã',
  'faithPhrase': 'Deus é fiel em todas as coisas',
  'isDeusEPaiMember': true,
  'readyForPurposefulRelationship': true,
  'hasSinaisPreparationSeal': true,
  'nonNegotiableValue': 'Fidelidade e honestidade',
  
  // Status de relacionamento
  'relationshipStatus': RelationshipStatus.solteiro,
  'hasChildren': false,
  'isVirgin': true, // opcional
  'wasPreviouslyMarried': false,
  'childrenDetails': null,
  
  // Informações adicionais
  'aboutMe': 'Amo música e natureza...',
};
```

### Question Configuration Model
```dart
class VitrineQuestionConfig {
  final String questionId;
  final String questionText;
  final QuestionType type;
  final bool isRequired;
  final bool isPrivate;
  final List<String>? options;
  
  // Exemplos de novas perguntas
  static List<VitrineQuestionConfig> additionalQuestions = [
    VitrineQuestionConfig(
      questionId: 'hasChildren',
      questionText: 'Você tem filhos?',
      type: QuestionType.yesNo,
      isRequired: true,
      isPrivate: false,
    ),
    VitrineQuestionConfig(
      questionId: 'isVirgin',
      questionText: 'Você é virgem?',
      type: QuestionType.yesNo,
      isRequired: false,
      isPrivate: true,
    ),
    VitrineQuestionConfig(
      questionId: 'wasPreviouslyMarried',
      questionText: 'Você já foi casado(a)?',
      type: QuestionType.yesNo,
      isRequired: true,
      isPrivate: false,
    ),
  ];
}
```

## Error Handling

### Data Validation
- Verificar se campos obrigatórios estão presentes
- Validar formato de dados (idade, localização)
- Tratar campos opcionais graciosamente

### UI Error States
- Loading states para cada seção
- Placeholder para informações não disponíveis
- Fallbacks para imagens não carregadas

### Privacy Handling
- Respeitar configurações de privacidade
- Mostrar "Não informado" para campos privados
- Permitir que usuário escolha não exibir informações sensíveis

## Testing Strategy

### Unit Tests
- Testes para cada widget component
- Validação de data models
- Testes de formatação de dados

### Integration Tests
- Fluxo completo de carregamento da vitrine
- Testes de interação entre componentes
- Validação de estados de loading e erro

### Visual Tests
- Screenshots de diferentes estados
- Testes de responsividade
- Validação de layout em diferentes dispositivos

## Implementation Phases

### Phase 1: Model Enhancement
- Adicionar novos campos ao SpiritualProfileModel
- Criar migrations para dados existentes
- Implementar validações

### Phase 2: UI Components
- Criar novos widgets de seção
- Implementar ProfileHeaderSection
- Desenvolver RelationshipStatusSection

### Phase 3: Question Integration
- Adicionar novas perguntas ao processo de criação
- Integrar com formulários existentes
- Implementar lógica de privacidade

### Phase 4: Visual Polish
- Aplicar design system
- Implementar animações
- Otimizar performance

## Design Specifications

### Visual Hierarchy
1. **Header (Foto + Nome)** - Mais proeminente
2. **Informações Básicas** - Visibilidade alta
3. **Informações Espirituais** - Destaque médio
4. **Status de Relacionamento** - Organizado em cards
5. **Informações Adicionais** - Seção expandível

### Color Scheme
- **Primary:** Azul espiritual (#2196F3)
- **Secondary:** Verde esperança (#4CAF50)
- **Accent:** Dourado verificação (#FFD700)
- **Text:** Cinza escuro (#333333)
- **Background:** Branco/Cinza claro (#F5F5F5)

### Typography
- **Nome:** 24px, Bold
- **Seções:** 18px, SemiBold
- **Conteúdo:** 16px, Regular
- **Detalhes:** 14px, Regular

### Icons
- Localização: `Icons.location_on`
- Idade: `Icons.cake`
- Movimento: Custom badge icon
- Verificação: `Icons.verified`
- Filhos: `Icons.family_restroom`
- Relacionamento: `Icons.favorite`

### Spacing
- Padding geral: 16px
- Espaçamento entre seções: 24px
- Espaçamento interno de cards: 12px
- Margem da foto: 32px (top/bottom)

## Accessibility

### Screen Reader Support
- Semantic labels para todos os elementos
- Descrições alternativas para ícones
- Ordem lógica de navegação

### Visual Accessibility
- Contraste adequado para textos
- Tamanhos de fonte legíveis
- Indicadores visuais claros

### Interaction Accessibility
- Áreas de toque adequadas
- Feedback visual para interações
- Suporte a navegação por teclado