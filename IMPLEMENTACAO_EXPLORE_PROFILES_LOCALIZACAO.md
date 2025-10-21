# Implementação: Explore Profiles - Sistema de Localização

## Status: EM PROGRESSO (50% Completo)

## ✅ Implementado

### 1. Data Models (Task 1) ✅
**Arquivos:**
- `lib/models/additional_location_model.dart`
- `lib/models/spiritual_profile_model.dart` (atualizado)

**Funcionalidades:**
- Modelo `AdditionalLocation` com lógica de edição (30 dias)
- Métodos `canEdit`, `daysUntilCanEdit`, `editStatusMessage`
- Serialização JSON completa
- Campo `additionalLocations` adicionado ao `SpiritualProfileModel`

### 2. Componentes Visuais (Tasks 2-3) ✅
**Arquivos:**
- `lib/components/primary_location_card.dart`
- `lib/components/additional_location_card.dart`

**Funcionalidades:**
- **PrimaryLocationCard**: Card elegante com gradiente roxo/azul, ícone de casa
- **AdditionalLocationCard**: Card com badge de status, botões editar/remover, animações
- Dialog de confirmação para remover localização
- Lógica de restrição de edição implementada

## 🔄 Próximas Tasks (Faltam)

### Task 4: Dialog de Seleção de Localização
**Arquivo a criar:** `lib/components/location_selector_dialog.dart`

**Implementar:**
```dart
class LocationSelectorDialog extends StatefulWidget {
  final Function(String city, String state) onLocationSelected;
  
  // Dropdown de estados brasileiros
  // Dropdown de cidades (filtrado por estado)
  // Botões Cancelar e Adicionar
}
```

**Estados brasileiros:**
```dart
final estados = [
  'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA',
  'MT', 'MS', 'MG', 'PA', 'PB', 'PR', 'PE', 'PI', 'RJ', 'RN',
  'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO'
];
```

### Task 5: Seção de Filtros Completa
**Arquivo a criar:** `lib/components/location_filter_section.dart`

**Implementar:**
```dart
class LocationFilterSection extends StatelessWidget {
  final String? primaryCity;
  final String? primaryState;
  final List<AdditionalLocation> additionalLocations;
  final VoidCallback onAddLocation;
  final Function(int index) onRemoveLocation;
  final Function(int index) onEditLocation;
  final bool canAddMore;
  
  // Container com:
  // - Título "Localização de Encontros"
  // - PrimaryLocationCard
  // - Lista de AdditionalLocationCard
  // - Contador "X de 2 localizações"
  // - Botão "Adicionar Localização"
}
```

### Task 6: Controller Logic
**Arquivo a atualizar:** `lib/controllers/explore_profiles_controller.dart`

**Adicionar métodos:**
```dart
// Observables
final Rx<List<AdditionalLocation>> additionalLocations = Rx<List<AdditionalLocation>>([]);
final RxString primaryCity = ''.obs;
final RxString primaryState = ''.obs;

// Métodos
Future<void> loadUserLocations();
Future<void> addAdditionalLocation(String city, String state);
Future<void> removeAdditionalLocation(int index);
Future<void> editAdditionalLocation(int index, String city, String state);
bool canAddMoreLocations();
```

### Task 7: Integração com ExploreProfilesView
**Arquivo a atualizar:** `lib/views/explore_profiles_view.dart`

**Adicionar:**
1. Header com título "Espero esses Sinais..."
2. Mensagem motivacional
3. LocationFilterSection após o header
4. Conectar com controller

### Task 8: Busca por Localização
**Arquivo a atualizar:** `lib/repositories/explore_profiles_repository.dart`

**Implementar:**
```dart
Future<List<SpiritualProfileModel>> searchByLocations({
  required String primaryCity,
  required String primaryState,
  List<AdditionalLocation>? additionalLocations,
});
```

## 📋 Checklist de Implementação

- [x] 1. Criar Data Models
- [x] 2. Criar PrimaryLocationCard
- [x] 3. Criar AdditionalLocationCard
- [ ] 4. Criar LocationSelectorDialog
- [ ] 5. Criar LocationFilterSection
- [ ] 6. Atualizar ExploreProfilesController
- [ ] 7. Integrar com ExploreProfilesView
- [ ] 8. Implementar busca por localização
- [ ] 9. Adicionar animações e polish
- [ ] 10. Testes (opcional)

## 🎨 Design System

### Cores
```dart
Primary: Color(0xFF7B68EE)  // Roxo médio
Secondary: Color(0xFF4169E1) // Azul royal
Success: Color(0xFF10B981)   // Verde
Warning: Color(0xFFF59E0B)   // Laranja
Error: Color(0xFFEF4444)     // Vermelho
```

### Espaçamentos
- Card padding: 16-20px
- Entre elementos: 12-16px
- Margens: 16-24px

## 🔧 Como Continuar

### Passo 1: Criar LocationSelectorDialog
```bash
# Criar arquivo
lib/components/location_selector_dialog.dart

# Implementar:
# - Dropdown de estados
# - Dropdown de cidades (pode usar lista simplificada ou API)
# - Validação
# - Botões de ação
```

### Passo 2: Criar LocationFilterSection
```bash
# Criar arquivo
lib/components/location_filter_section.dart

# Implementar:
# - Usar PrimaryLocationCard
# - Usar AdditionalLocationCard em lista
# - Botão "Adicionar Localização"
# - Contador de localizações
```

### Passo 3: Atualizar Controller
```bash
# Editar arquivo
lib/controllers/explore_profiles_controller.dart

# Adicionar:
# - Observables para localizações
# - Métodos CRUD
# - Persistência no Firestore
# - Validações
```

### Passo 4: Integrar na View
```bash
# Editar arquivo
lib/views/explore_profiles_view.dart

# Adicionar:
# - Header motivacional
# - LocationFilterSection
# - Conectar callbacks
```

## 📝 Notas Importantes

1. **Limite de 2 Localizações**: Validar no controller antes de adicionar
2. **Restrição de 30 Dias**: Já implementada no model
3. **Persistência**: Salvar no Firestore imediatamente após mudanças
4. **Feedback**: Usar snackbars para todas as ações
5. **Animações**: Já implementadas nos cards

## 🐛 Possíveis Problemas

1. **Lista de Cidades**: Pode ser grande, considerar busca ou API
2. **Performance**: Usar pagination na busca de perfis
3. **Cache**: Considerar cache das localizações do usuário
4. **Sincronização**: Garantir que mudanças sejam salvas antes de buscar

## 📚 Referências

- Spec completa: `.kiro/specs/explore-profiles-localizacao/`
- Requirements: `requirements.md`
- Design: `design.md`
- Tasks: `tasks.md`

## Data da Implementação
18 de Outubro de 2025 - Sessão 1 (50% completo)
