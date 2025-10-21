# Design Document - Sincronização de Dados do Perfil para Vitrine

## Overview

Este documento descreve o design para sincronizar e exibir todos os campos cadastrados no ProfileCompletionView na vitrine pública (EnhancedVitrineDisplayView). A solução envolve criar novos componentes de UI reutilizáveis e atualizar a vitrine para exibir todas as informações do perfil de forma organizada e visualmente atraente.

## Architecture

### Componentes Existentes
- `ProfileHeaderSection` - Header com foto e nome
- `BasicInfoSection` - Informações básicas (cidade, idade)
- `SpiritualInfoSection` - Informações espirituais (propósito, fé)
- `RelationshipStatusSection` - Status de relacionamento e família

### Novos Componentes a Criar
1. **EducationInfoSection** - Educação e formação acadêmica
2. **LifestyleInfoSection** - Estilo de vida (altura, fumante, bebida)
3. **HobbiesSection** - Hobbies e interesses
4. **LanguagesSection** - Idiomas falados
5. **PhotoGallerySection** - Galeria de fotos (principal + secundárias)
6. **LocationInfoSection** - Localização completa (cidade, estado, país)

### Estrutura de Pastas
```
lib/
├── components/
│   ├── profile_header_section.dart (existente)
│   ├── basic_info_section.dart (existente)
│   ├── spiritual_info_section.dart (existente)
│   ├── relationship_status_section.dart (existente)
│   ├── education_info_section.dart (NOVO)
│   ├── lifestyle_info_section.dart (NOVO)
│   ├── hobbies_section.dart (NOVO)
│   ├── languages_section.dart (NOVO)
│   ├── photo_gallery_section.dart (NOVO)
│   └── location_info_section.dart (NOVO)
├── views/
│   └── enhanced_vitrine_display_view.dart (atualizar)
└── models/
    └── spiritual_profile_model.dart (já existe)
```

## Components and Interfaces

### 1. EducationInfoSection

**Propósito**: Exibir informações sobre educação e formação acadêmica

**Props**:
```dart
{
  String? education,           // Nível educacional
  String? universityCourse,    // Curso superior
  String? courseStatus,        // "Se formando" ou "Formado(a)"
  String? university,          // Instituição
  String? occupation,          // Profissão atual
}
```

**Layout**:
```
┌─────────────────────────────────────┐
│ 🎓 Educação e Carreira              │
├─────────────────────────────────────┤
│ 📚 Formação                         │
│ Engenharia de Software              │
│ Universidade Federal de São Paulo   │
│ Status: Formado(a)                  │
│                                     │
│ 💼 Profissão                        │
│ Desenvolvedor Full Stack            │
└─────────────────────────────────────┘
```

### 2. LifestyleInfoSection

**Propósito**: Exibir informações sobre estilo de vida

**Props**:
```dart
{
  String? height,              // Altura
  String? smokingStatus,       // Status de fumante
  String? drinkingStatus,      // Status de bebida
}
```

**Layout**:
```
┌─────────────────────────────────────┐
│ 🌟 Estilo de Vida                   │
├─────────────────────────────────────┤
│ 📏 Altura: 1.75m                    │
│ 🚭 Fumante: Não fumo                │
│ 🍷 Bebida: Socialmente              │
└─────────────────────────────────────┘
```

### 3. HobbiesSection

**Propósito**: Exibir hobbies e interesses

**Props**:
```dart
{
  List<String>? hobbies,       // Lista de hobbies
}
```

**Layout**:
```
┌─────────────────────────────────────┐
│ 🎯 Hobbies e Interesses             │
├─────────────────────────────────────┤
│ ┌─────────┐ ┌─────────┐ ┌─────────┐│
│ │ 🎸 Música│ │ 📚 Leitura│ │ ⚽ Esportes││
│ └─────────┘ └─────────┘ └─────────┘│
│ ┌─────────┐ ┌─────────┐            │
│ │ 🎨 Arte  │ │ 🍳 Culinária│          │
│ └─────────┘ └─────────┘            │
└─────────────────────────────────────┘
```

### 4. LanguagesSection

**Propósito**: Exibir idiomas falados

**Props**:
```dart
{
  List<String>? languages,     // Lista de idiomas
}
```

**Layout**:
```
┌─────────────────────────────────────┐
│ 🗣️ Idiomas                          │
├─────────────────────────────────────┤
│ • Português (Nativo)                │
│ • Inglês (Fluente)                  │
│ • Espanhol (Intermediário)          │
└─────────────────────────────────────┘
```

### 5. PhotoGallerySection

**Propósito**: Exibir galeria de fotos (principal + secundárias)

**Props**:
```dart
{
  String? mainPhotoUrl,        // Foto principal
  String? secondaryPhoto1Url,  // Foto secundária 1
  String? secondaryPhoto2Url,  // Foto secundária 2
}
```

**Layout**:
```
┌─────────────────────────────────────┐
│ 📸 Galeria de Fotos                 │
├─────────────────────────────────────┤
│ ┌───────────┐ ┌───────────┐        │
│ │           │ │           │        │
│ │  Foto 1   │ │  Foto 2   │        │
│ │           │ │           │        │
│ └───────────┘ └───────────┘        │
└─────────────────────────────────────┘
```

**Funcionalidades**:
- Clicar na foto abre em tela cheia
- Swipe para navegar entre fotos
- Indicador de quantidade de fotos

### 6. LocationInfoSection

**Propósito**: Exibir localização completa

**Props**:
```dart
{
  String? city,                // Cidade
  String? state,               // Estado
  String? fullLocation,        // Localização completa
  String? country,             // País
}
```

**Layout**:
```
┌─────────────────────────────────────┐
│ 📍 Localização                      │
├─────────────────────────────────────┤
│ São Paulo - SP, Brasil              │
└─────────────────────────────────────┘
```

## Data Models

### SpiritualProfileModel (já existe)

Todos os campos necessários já existem no modelo:

```dart
class SpiritualProfileModel {
  // Fotos
  String? mainPhotoUrl;
  String? secondaryPhoto1Url;
  String? secondaryPhoto2Url;
  
  // Localização
  String? city;
  String? state;
  String? fullLocation;
  String? country;
  
  // Idiomas
  List<String>? languages;
  
  // Física
  String? height;
  
  // Profissional
  String? occupation;
  
  // Educação
  String? education;
  String? universityCourse;
  String? courseStatus;
  String? university;
  
  // Estilo de Vida
  String? smokingStatus;
  String? drinkingStatus;
  
  // Interesses
  List<String>? hobbies;
  
  // Intimidade (PÚBLICO)
  bool? isVirgin;
}
```

## Error Handling

### Campos Vazios
- **Estratégia**: Ocultar seção completamente se não houver dados
- **Exemplo**: Se `hobbies` for null ou vazio, não mostrar HobbiesSection

### Imagens Quebradas
- **Estratégia**: Mostrar placeholder com ícone
- **Fallback**: Avatar com iniciais do nome

### Dados Inválidos
- **Estratégia**: Validar dados antes de exibir
- **Exemplo**: Se `age` for negativo, não exibir

## Testing Strategy

### Testes Unitários
1. Testar cada componente isoladamente
2. Testar com dados completos
3. Testar com dados parciais
4. Testar com dados vazios

### Testes de Integração
1. Testar vitrine com perfil completo
2. Testar vitrine com perfil parcial
3. Testar navegação entre fotos
4. Testar responsividade

### Casos de Teste

#### Caso 1: Perfil Completo
```dart
// Dado um perfil com todos os campos preenchidos
// Quando o usuário visualiza a vitrine
// Então todas as seções devem ser exibidas
```

#### Caso 2: Perfil Parcial
```dart
// Dado um perfil com apenas campos obrigatórios
// Quando o usuário visualiza a vitrine
// Então apenas seções com dados devem ser exibidas
```

#### Caso 3: Galeria de Fotos
```dart
// Dado um perfil com 3 fotos
// Quando o usuário clica em uma foto
// Então a foto deve abrir em tela cheia
```

## UI/UX Considerations

### Ordem das Seções
1. **Header** (foto, nome, username, selo)
2. **Localização** (cidade, estado, país)
3. **Informações Básicas** (idade, idiomas)
4. **Informações Espirituais** (propósito, fé, valores)
5. **Educação e Carreira** (formação, profissão)
6. **Estilo de Vida** (altura, fumante, bebida)
7. **Hobbies e Interesses**
8. **Status de Relacionamento** (solteiro, filhos, virgindade)
9. **Sobre Mim** (texto livre)
10. **Galeria de Fotos**

### Cores e Ícones

| Seção | Cor | Ícone |
|-------|-----|-------|
| Educação | `Colors.blue[600]` | `Icons.school` |
| Estilo de Vida | `Colors.green[600]` | `Icons.spa` |
| Hobbies | `Colors.purple[600]` | `Icons.interests` |
| Idiomas | `Colors.orange[600]` | `Icons.language` |
| Galeria | `Colors.pink[600]` | `Icons.photo_library` |
| Localização | `Colors.teal[600]` | `Icons.location_on` |

### Responsividade
- Mobile: 1 coluna
- Tablet: 2 colunas para algumas seções
- Desktop: Layout otimizado com sidebar

### Acessibilidade
- Todos os ícones com labels
- Contraste adequado de cores
- Suporte a leitores de tela
- Navegação por teclado

## Performance Considerations

### Lazy Loading
- Carregar fotos secundárias apenas quando necessário
- Usar placeholders enquanto carrega

### Caching
- Cache de imagens com `CachedNetworkImage`
- Cache de dados do perfil

### Otimizações
- Evitar rebuilds desnecessários com `const` widgets
- Usar `ListView.builder` para listas longas
- Comprimir imagens antes de upload

## Security Considerations

### Privacidade
- Respeitar configurações de privacidade do usuário
- Não exibir dados sensíveis sem consentimento
- Permitir ocultar seções específicas (futuro)

### Validação
- Validar todos os dados antes de exibir
- Sanitizar texto para evitar XSS
- Validar URLs de imagens

## Migration Strategy

### Fase 1: Criar Componentes
1. Criar todos os novos componentes
2. Testar componentes isoladamente
3. Documentar props e uso

### Fase 2: Atualizar Vitrine
1. Adicionar novos componentes à vitrine
2. Testar com dados reais
3. Ajustar layout e espaçamento

### Fase 3: Testes e Ajustes
1. Testar em diferentes dispositivos
2. Coletar feedback de usuários
3. Fazer ajustes finais

### Fase 4: Deploy
1. Deploy em produção
2. Monitorar erros
3. Fazer hotfixes se necessário

## Future Enhancements

### Filtros de Pesquisa
- Filtrar por educação
- Filtrar por hobbies
- Filtrar por idiomas
- Filtrar por localização
- Filtrar por estilo de vida

### Personalização
- Permitir reordenar seções
- Permitir ocultar seções
- Temas personalizados

### Interações
- Curtir hobbies em comum
- Comentar em fotos
- Compartilhar perfil

## Diagrams

### Fluxo de Dados
```
ProfileCompletionView
        ↓
   (Salva dados)
        ↓
    Firestore
        ↓
   (Carrega dados)
        ↓
SpiritualProfileRepository
        ↓
EnhancedVitrineDisplayView
        ↓
   (Renderiza)
        ↓
  Componentes UI
```

### Hierarquia de Componentes
```
EnhancedVitrineDisplayView
├── ProfileHeaderSection
├── LocationInfoSection (NOVO)
├── BasicInfoSection
│   └── LanguagesSection (NOVO)
├── SpiritualInfoSection
├── EducationInfoSection (NOVO)
├── LifestyleInfoSection (NOVO)
├── HobbiesSection (NOVO)
├── RelationshipStatusSection
│   └── (inclui isVirgin)
├── AboutMeSection
└── PhotoGallerySection (NOVO)
```

## Implementation Notes

### Padrão de Componentes
Todos os componentes devem seguir este padrão:

```dart
class ExampleSection extends StatelessWidget {
  final String? data;
  
  const ExampleSection({
    Key? key,
    this.data,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // Se não houver dados, não renderizar
    if (data?.isEmpty ?? true) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título da seção
          Text('Título', style: TextStyle(...)),
          const SizedBox(height: 16),
          
          // Conteúdo
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(...),
            child: // Conteúdo aqui
          ),
        ],
      ),
    );
  }
}
```

### Consistência Visual
- Usar `AppColors` para cores
- Usar `BorderRadius.circular(16)` para cards
- Usar `EdgeInsets.all(20)` para padding interno
- Usar `EdgeInsets.symmetric(horizontal: 16)` para padding externo
- Usar `SizedBox(height: 24)` para espaçamento entre seções

### Tratamento de Nulls
- Sempre verificar se o campo é null ou vazio
- Usar operador `?.` para acessar propriedades
- Usar `??` para valores padrão
- Retornar `SizedBox.shrink()` se não houver dados
