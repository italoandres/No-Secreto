# Design Document

## Overview

Este documento descreve o design técnico para expandir o sistema de localização mundial, permitindo que usuários de múltiplos países tenham acesso a dropdowns estruturados de estados/províncias e cidades, similar ao que já existe para o Brasil.

O design foca em:
- Arquitetura extensível e escalável
- Performance otimizada
- Fácil manutenção e adição de novos países
- Compatibilidade com dados existentes

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Profile Identity View                     │
│                  (profile_identity_task_view.dart)           │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              LocationDataProvider (Factory)                  │
│  - getCountriesWithStructuredData()                         │
│  - getLocationData(countryCode)                             │
│  - hasStructuredData(countryCode)                           │
└────────────────────────┬────────────────────────────────────┘
                         │
         ┌───────────────┼───────────────┐
         ▼               ▼               ▼
┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│   Brazil    │  │     USA     │  │  Portugal   │
│  Location   │  │  Location   │  │  Location   │
│    Data     │  │    Data     │  │    Data     │
└─────────────┘  └─────────────┘  └─────────────┘
         │               │               │
         └───────────────┴───────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              LocationDataInterface                           │
│  - getStates() / getProvinces() / getRegions()              │
│  - getCitiesForState(state)                                 │
│  - getStateLabelName()                                      │
│  - getLocationFormat(city, state)                           │
└─────────────────────────────────────────────────────────────┘
```

### Data Flow

1. **Seleção de País**
   - Usuário seleciona país no dropdown
   - Sistema verifica se país tem dados estruturados
   - Interface atualiza para mostrar campos apropriados

2. **Carregamento de Estados/Províncias**
   - LocationDataProvider retorna dados do país
   - Dropdown é populado com estados/províncias
   - Label é atualizado com nomenclatura correta

3. **Carregamento de Cidades**
   - Usuário seleciona estado/província
   - Sistema carrega cidades correspondentes
   - Dropdown de cidades é atualizado

4. **Salvamento**
   - Sistema formata localização conforme padrão do país
   - Dados são salvos no Firebase com estrutura consistente

## Components and Interfaces

### 1. LocationDataInterface (Abstract Class)

Interface base que todos os provedores de dados de localização devem implementar.

```dart
abstract class LocationDataInterface {
  /// Nome do país
  String get countryName;
  
  /// Código do país (ISO 3166-1 alpha-2)
  String get countryCode;
  
  /// Label para o campo de estado/província/região
  /// Ex: "Estado", "Província", "Distrito", "Região"
  String get stateLabel;
  
  /// Retorna lista de estados/províncias/regiões
  List<String> getStates();
  
  /// Retorna lista de cidades para um estado/província
  List<String> getCitiesForState(String state);
  
  /// Retorna formato de localização
  /// Ex: "São Paulo - SP" ou "Paris, Île-de-France"
  String formatLocation(String city, String state);
  
  /// Indica se o país usa siglas para estados
  bool get useStateAbbreviation;
  
  /// Retorna sigla do estado (se aplicável)
  String? getStateAbbreviation(String state);
}
```

### 2. LocationDataProvider (Factory)

Classe responsável por fornecer os dados de localização apropriados para cada país.

```dart
class LocationDataProvider {
  static final Map<String, LocationDataInterface> _providers = {
    'BR': BrazilLocationData(),
    'US': USALocationData(),
    'PT': PortugalLocationData(),
    'CA': CanadaLocationData(),
    'AR': ArgentinaLocationData(),
    'MX': MexicoLocationData(),
    'ES': SpainLocationData(),
    'FR': FranceLocationData(),
    'IT': ItalyLocationData(),
    'DE': GermanyLocationData(),
    'GB': UKLocationData(),
  };
  
  /// Verifica se um país tem dados estruturados
  static bool hasStructuredData(String countryCode) {
    return _providers.containsKey(countryCode);
  }
  
  /// Retorna o provedor de dados para um país
  static LocationDataInterface? getLocationData(String countryCode) {
    return _providers[countryCode];
  }
  
  /// Retorna lista de códigos de países com dados estruturados
  static List<String> getCountriesWithStructuredData() {
    return _providers.keys.toList();
  }
  
  /// Retorna lista de nomes de países com dados estruturados
  static List<String> getCountryNamesWithStructuredData() {
    return _providers.values.map((p) => p.countryName).toList();
  }
}
```

### 3. Implementações Específicas por País

#### BrazilLocationData (já existe, será refatorado)

```dart
class BrazilLocationData implements LocationDataInterface {
  @override
  String get countryName => 'Brasil';
  
  @override
  String get countryCode => 'BR';
  
  @override
  String get stateLabel => 'Estado';
  
  @override
  bool get useStateAbbreviation => true;
  
  @override
  List<String> getStates() => BrazilLocationsData.states;
  
  @override
  List<String> getCitiesForState(String state) {
    return BrazilLocationsData.getCitiesForState(state);
  }
  
  @override
  String formatLocation(String city, String state) {
    final abbr = getStateAbbreviation(state);
    return '$city - $abbr';
  }
  
  @override
  String? getStateAbbreviation(String state) {
    return BrazilLocationsData.stateAbbreviations[state];
  }
}
```

#### USALocationData

```dart
class USALocationData implements LocationDataInterface {
  @override
  String get countryName => 'Estados Unidos';
  
  @override
  String get countryCode => 'US';
  
  @override
  String get stateLabel => 'Estado';
  
  @override
  bool get useStateAbbreviation => true;
  
  @override
  List<String> getStates() => USALocationsData.states;
  
  @override
  List<String> getCitiesForState(String state) {
    return USALocationsData.getCitiesForState(state);
  }
  
  @override
  String formatLocation(String city, String state) {
    final abbr = getStateAbbreviation(state);
    return '$city, $abbr';
  }
  
  @override
  String? getStateAbbreviation(String state) {
    return USALocationsData.stateAbbreviations[state];
  }
}
```

#### PortugalLocationData

```dart
class PortugalLocationData implements LocationDataInterface {
  @override
  String get countryName => 'Portugal';
  
  @override
  String get countryCode => 'PT';
  
  @override
  String get stateLabel => 'Distrito';
  
  @override
  bool get useStateAbbreviation => false;
  
  @override
  List<String> getStates() => PortugalLocationsData.districts;
  
  @override
  List<String> getCitiesForState(String district) {
    return PortugalLocationsData.getCitiesForDistrict(district);
  }
  
  @override
  String formatLocation(String city, String district) {
    return '$city, $district';
  }
  
  @override
  String? getStateAbbreviation(String state) => null;
}
```

### 4. Atualização da View

A view `profile_identity_task_view.dart` será atualizada para usar o novo sistema:

```dart
class _ProfileIdentityTaskViewState extends State<ProfileIdentityTaskView> {
  String? _selectedCountry;
  String? _selectedCountryCode;
  String? _selectedState;
  String? _selectedCity;
  LocationDataInterface? _locationData;
  
  void _onCountryChanged(String? countryName) {
    setState(() {
      _selectedCountry = countryName;
      _selectedCountryCode = WorldLocationsData.getCountryCode(countryName);
      _selectedState = null;
      _selectedCity = null;
      
      // Carregar dados estruturados se disponível
      if (_selectedCountryCode != null) {
        _locationData = LocationDataProvider.getLocationData(_selectedCountryCode!);
      } else {
        _locationData = null;
      }
    });
  }
  
  Widget _buildLocationFields() {
    // Se tem dados estruturados, mostrar dropdowns
    if (_locationData != null) {
      return Column(
        children: [
          _buildStateDropdown(),
          const SizedBox(height: 16),
          _buildCityDropdown(),
        ],
      );
    }
    
    // Caso contrário, mostrar campo de texto
    return _buildCityTextField();
  }
  
  Widget _buildStateDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedState,
      decoration: InputDecoration(
        labelText: '${_locationData!.stateLabel} *',
        prefixIcon: const Icon(Icons.map),
      ),
      items: _locationData!.getStates().map((state) {
        return DropdownMenuItem(
          value: state,
          child: Text(state),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedState = value;
          _selectedCity = null;
        });
      },
      validator: (value) => value == null ? 'Selecione ${_locationData!.stateLabel.toLowerCase()}' : null,
    );
  }
  
  Widget _buildCityDropdown() {
    final cities = _selectedState != null
        ? _locationData!.getCitiesForState(_selectedState!)
        : <String>[];
    
    return DropdownButtonFormField<String>(
      value: _selectedCity,
      decoration: const InputDecoration(
        labelText: 'Cidade *',
        prefixIcon: Icon(Icons.location_city),
      ),
      items: cities.map((city) {
        return DropdownMenuItem(
          value: city,
          child: Text(city),
        );
      }).toList(),
      onChanged: _selectedState != null
          ? (value) {
              setState(() {
                _selectedCity = value;
              });
            }
          : null,
      validator: (value) => value == null ? 'Selecione uma cidade' : null,
    );
  }
  
  String _buildFullLocation() {
    if (_locationData != null && _selectedState != null && _selectedCity != null) {
      return _locationData!.formatLocation(_selectedCity!, _selectedState!);
    } else if (_selectedCity != null && _selectedCountry != null) {
      return '$_selectedCity, $_selectedCountry';
    }
    return '';
  }
}
```

## Data Models

### Firebase Document Structure

```javascript
{
  // Campos de localização
  country: "Estados Unidos",
  countryCode: "US",
  state: "California",
  city: "Los Angeles",
  fullLocation: "Los Angeles, CA",
  hasStructuredData: true,
  
  // Outros campos do perfil
  languages: ["Inglês", "Espanhol"],
  age: 28,
  // ...
}
```

### Estrutura de Dados por País

Cada arquivo de dados de país seguirá este padrão:

```dart
class [Country]LocationsData {
  /// Lista de estados/províncias/regiões
  static const List<String> states = [
    'State 1',
    'State 2',
    // ...
  ];
  
  /// Mapa de siglas (se aplicável)
  static const Map<String, String> stateAbbreviations = {
    'State 1': 'S1',
    'State 2': 'S2',
    // ...
  };
  
  /// Mapa de cidades por estado
  static const Map<String, List<String>> citiesByState = {
    'State 1': [
      'City 1',
      'City 2',
      // ...
    ],
    'State 2': [
      'City 3',
      'City 4',
      // ...
    ],
  };
  
  /// Retorna cidades de um estado
  static List<String> getCitiesForState(String state) {
    return citiesByState[state] ?? [];
  }
}
```

## Error Handling

### Cenários de Erro

1. **Dados não encontrados**
   - Fallback para campo de texto livre
   - Log de erro para debugging
   - Mensagem amigável ao usuário

2. **Estado/Província inválido**
   - Validação no dropdown
   - Resetar seleção de cidade
   - Mensagem de erro clara

3. **Cidade não encontrada**
   - Validação no dropdown
   - Opção de adicionar manualmente (futuro)
   - Feedback visual

### Implementação

```dart
class LocationErrorHandler {
  static void handleDataLoadError(String countryCode, dynamic error) {
    // Log erro
    safePrint('Erro ao carregar dados de $countryCode: $error');
    
    // Analytics
    FirebaseAnalytics.instance.logEvent(
      name: 'location_data_error',
      parameters: {
        'country_code': countryCode,
        'error': error.toString(),
      },
    );
  }
  
  static String getFallbackMessage(String countryName) {
    return 'Não foi possível carregar as cidades de $countryName. '
           'Por favor, digite sua cidade manualmente.';
  }
}
```

## Testing Strategy

### Unit Tests

1. **LocationDataInterface Implementations**
   - Testar cada implementação de país
   - Verificar formatação de localização
   - Validar siglas de estados

2. **LocationDataProvider**
   - Testar factory pattern
   - Verificar detecção de países com dados estruturados
   - Validar retorno de provedores corretos

### Integration Tests

1. **Profile Identity View**
   - Testar fluxo completo de seleção
   - Verificar mudança entre países
   - Validar salvamento no Firebase

2. **Data Loading**
   - Testar carregamento de estados
   - Verificar carregamento de cidades
   - Validar performance

### Widget Tests

1. **Dropdowns**
   - Testar renderização de dropdowns
   - Verificar interação do usuário
   - Validar estados de loading

2. **Validação**
   - Testar validação de campos obrigatórios
   - Verificar mensagens de erro
   - Validar reset de campos

## Performance Considerations

### Otimizações

1. **Lazy Loading**
   - Carregar dados apenas quando país é selecionado
   - Não carregar todos os países na inicialização
   - Cache de dados carregados

2. **Memory Management**
   - Usar const para dados estáticos
   - Liberar dados não utilizados
   - Evitar duplicação de dados

3. **UI Responsiveness**
   - Usar FutureBuilder para carregamento assíncrono
   - Mostrar loading indicators
   - Debounce em buscas (se implementado)

### Métricas

- Tempo de carregamento de dropdown: < 100ms
- Memória utilizada por país: < 500KB
- Tempo de salvamento: < 1s

## Migration Strategy

### Dados Existentes

1. **Perfis com Brasil**
   - Já compatíveis com novo sistema
   - Nenhuma migração necessária

2. **Perfis com Outros Países**
   - Manter campo `city` como está
   - Adicionar campo `hasStructuredData: false`
   - Permitir atualização gradual

### Rollout

1. **Fase 1**: Implementar arquitetura base
2. **Fase 2**: Adicionar 3 países prioritários (EUA, Portugal, Canadá)
3. **Fase 3**: Adicionar 7 países restantes
4. **Fase 4**: Monitorar e otimizar
5. **Fase 5**: Expandir para mais países baseado em demanda

## Future Enhancements

1. **Busca em Dropdowns**
   - Implementar busca/filtro em dropdowns grandes
   - Melhorar UX para países com muitos estados

2. **Autocomplete**
   - Sugerir cidades enquanto usuário digita
   - Usar dados estruturados como fonte

3. **Geolocalização**
   - Detectar localização automaticamente
   - Pré-selecionar país/estado/cidade

4. **Contribuição da Comunidade**
   - Permitir usuários sugerirem cidades faltantes
   - Sistema de validação de contribuições

5. **Internacionalização**
   - Traduzir nomes de países/estados
   - Suportar múltiplos idiomas

6. **Analytics**
   - Rastrear países mais usados
   - Identificar cidades faltantes
   - Priorizar expansão baseado em dados
