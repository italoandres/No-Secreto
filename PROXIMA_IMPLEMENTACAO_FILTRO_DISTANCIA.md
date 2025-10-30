# Próxima Implementação: Filtro de Distância

## Requisitos do Usuário

### Filtro de Distância
- **Range**: 5 km até 400+ km
- **Base**: Distância até a cidade que o usuário mora (do perfil)
- **Componente**: Slider ou dropdown

### Toggle de Preferência
- **Nome**: "Tenho mais interesse em pessoas que correspondam a essa preferência"
- **Tipo**: Switch/Toggle
- **Mensagem quando ativado**: 
  > "Com este sinal, podemos saber em quais tipos de perfil tem mais interesse, mas ainda sim podem aparecer outros que não correspondem exatamente."

### Botão Salvar
- **Ação**: Salvar filtros no Firestore
- **Feedback**: Snackbar de sucesso

### Dialog de Confirmação ao Voltar
- **Trigger**: Usuário clica em voltar (back button) com alterações não salvas
- **Título**: "Salvar alterações?"
- **Mensagem**: "Gostaria de salvar as alterações no seu filtro de busca?"
- **Botões**: 
  - "Descartar" (vermelho/cinza)
  - "Salvar" (roxo/azul)

## Estrutura de Implementação

### 1. Data Model
```dart
class SearchFilters {
  final int maxDistance; // em km (5 a 400+)
  final bool prioritizeDistance; // toggle de preferência
  final DateTime? lastUpdated;
  
  // Salvar no perfil do usuário
}
```

### 2. Componentes Necessários

#### DistanceFilterCard
- Slider de 5 km a 400+ km
- Label mostrando distância selecionada
- Ícone de localização

#### PreferenceToggleCard
- Switch elegante
- Mensagem explicativa (aparece quando ativado)
- Ícone de coração/estrela

#### FilterActionsBar
- Botão "Salvar" (fixo no bottom)
- Botão "Resetar" (opcional)

### 3. Controller Logic

```dart
// No ExploreProfilesController

final RxInt maxDistance = 50.obs; // padrão 50km
final RxBool prioritizeDistance = false.obs;
final RxBool hasUnsavedChanges = false.obs;

Future<void> loadSearchFilters();
Future<void> saveSearchFilters();
void resetFilters();
Future<bool> showSaveDialog(BuildContext context);
```

### 4. Integração na View

- Adicionar seção de filtros após LocationFilterSection
- Implementar WillPopScope para detectar back button
- Mostrar dialog de confirmação se hasUnsavedChanges

## Design Sugerido

### Cores
- Primary: `#7B68EE` (Roxo)
- Secondary: `#4169E1` (Azul)
- Success: `#10B981` (Verde)

### Layout
```
┌─────────────────────────────────────┐
│  📍 Distância de Você               │
├─────────────────────────────────────┤
│  [====●========] 50 km              │
│  5 km                      400+ km  │
├─────────────────────────────────────┤
│  ❤️ Tenho mais interesse...         │
│  [Toggle: OFF]                      │
│                                     │
│  ℹ️ Com este sinal, podemos...     │
│  (aparece quando toggle ON)         │
├─────────────────────────────────────┤
│  [Salvar Filtros]                   │
└─────────────────────────────────────┘
```

## Arquivos a Criar

1. `lib/models/search_filters_model.dart`
2. `lib/components/distance_filter_card.dart`
3. `lib/components/preference_toggle_card.dart`
4. `lib/components/filter_actions_bar.dart`
5. `lib/components/save_filters_dialog.dart`

## Arquivos a Modificar

1. `lib/controllers/explore_profiles_controller.dart` - Adicionar lógica de filtros
2. `lib/views/explore_profiles_view.dart` - Adicionar seção de filtros + WillPopScope
3. `lib/models/spiritual_profile_model.dart` - Adicionar campo searchFilters (opcional)

## Fluxo de Uso

1. Usuário ajusta slider de distância
2. Usuário ativa/desativa toggle de preferência
3. Usuário clica em "Salvar"
4. Sistema salva no Firestore
5. Snackbar de sucesso aparece
6. Filtros são aplicados na busca

### Fluxo de Voltar sem Salvar

1. Usuário faz alterações
2. Usuário clica em voltar
3. Dialog aparece: "Salvar alterações?"
4. Usuário escolhe:
   - "Descartar" → Volta sem salvar
   - "Salvar" → Salva e volta

## Persistência no Firestore

### Opção 1: No perfil do usuário
```javascript
spiritual_profiles/{profileId}
{
  searchFilters: {
    maxDistance: 50,
    prioritizeDistance: true,
    lastUpdated: Timestamp
  }
}
```

### Opção 2: Collection separada
```javascript
search_filters/{userId}
{
  maxDistance: 50,
  prioritizeDistance: true,
  lastUpdated: Timestamp
}
```

## Validações

- ✅ Distância mínima: 5 km
- ✅ Distância máxima: 400 km
- ✅ Salvar apenas se houver alterações
- ✅ Confirmar antes de descartar alterações

## Próximos Passos

1. Criar spec completa (requirements.md, design.md, tasks.md)
2. Implementar data model
3. Criar componentes visuais
4. Adicionar lógica no controller
5. Integrar na view
6. Implementar WillPopScope
7. Testar fluxo completo

## Estimativa

- **Complexidade**: Média
- **Tempo**: 2-3 horas
- **Arquivos novos**: 5
- **Arquivos modificados**: 3
- **Linhas de código**: ~800

## Observações Importantes

1. **Cálculo de Distância**: Precisará de uma função para calcular distância entre cidades (pode usar fórmula de Haversine ou API)
2. **Performance**: Filtrar por distância pode ser pesado, considerar cache
3. **UX**: Slider deve ser suave e responsivo
4. **Feedback**: Mostrar quantos perfis correspondem aos filtros

---

**Status**: Pronto para implementação
**Prioridade**: Alta
**Dependências**: Sistema de localização (✅ completo)
