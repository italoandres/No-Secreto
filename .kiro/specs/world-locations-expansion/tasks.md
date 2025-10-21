# Implementation Plan

- [x] 1. Criar arquitetura base e interfaces


  - Criar interface `LocationDataInterface` com métodos abstratos
  - Criar classe `LocationDataProvider` (factory pattern)
  - Criar classe `LocationErrorHandler` para tratamento de erros
  - _Requirements: 1.3, 5.3, 6.3_





- [x] 2. Refatorar dados existentes do Brasil


  - [ ] 2.1 Adicionar mapa de siglas de estados ao `BrazilLocationsData`
    - Criar `stateAbbreviations` com siglas de todos os estados
    - _Requirements: 1.2, 2.2_






  - [ ] 2.2 Criar implementação `BrazilLocationData` usando a interface
    - Implementar todos os métodos da `LocationDataInterface`
    - Usar dados de `BrazilLocationsData` existente


    - Implementar formatação "Cidade - UF"
    - _Requirements: 1.2, 2.2, 3.2_





- [ ] 3. Implementar dados dos Estados Unidos
  - [x] 3.1 Criar arquivo `usa_locations_data.dart`


    - Lista de 50 estados
    - Mapa de siglas dos estados
    - Principais cidades por estado (top 5-10 por estado)





    - _Requirements: 1.1, 1.2_

  - [ ] 3.2 Criar implementação `USALocationData`
    - Implementar interface `LocationDataInterface`


    - Usar label "Estado"
    - Implementar formatação "City, ST"
    - _Requirements: 2.1, 3.1, 3.2_

- [ ] 4. Implementar dados de Portugal
  - [ ] 4.1 Criar arquivo `portugal_locations_data.dart`
    - Lista de 18 distritos
    - Principais cidades por distrito
    - _Requirements: 1.1, 1.2_

  - [ ] 4.2 Criar implementação `PortugalLocationData`
    - Implementar interface `LocationDataInterface`
    - Usar label "Distrito"
    - Implementar formatação "Cidade, Distrito"
    - _Requirements: 2.1, 3.1, 3.2_

- [ ] 5. Implementar dados do Canadá
  - [ ] 5.1 Criar arquivo `canada_locations_data.dart`
    - Lista de 10 províncias e 3 territórios
    - Mapa de siglas das províncias/territórios
    - Principais cidades por província/território
    - _Requirements: 1.1, 1.2_

  - [ ] 5.2 Criar implementação `CanadaLocationData`
    - Implementar interface `LocationDataInterface`
    - Usar label "Província/Território"
    - Implementar formatação "City, PR"
    - _Requirements: 2.1, 3.1, 3.2_

- [ ] 6. Implementar dados da Argentina
  - [ ] 6.1 Criar arquivo `argentina_locations_data.dart`
    - Lista de 23 províncias + CABA
    - Principais cidades por província
    - _Requirements: 1.1, 1.2_

  - [ ] 6.2 Criar implementação `ArgentinaLocationData`
    - Implementar interface `LocationDataInterface`
    - Usar label "Província"
    - Implementar formatação "Ciudad, Provincia"
    - _Requirements: 2.1, 3.1, 3.2_

- [ ] 7. Implementar dados do México
  - [ ] 7.1 Criar arquivo `mexico_locations_data.dart`
    - Lista de 32 estados
    - Principais cidades por estado
    - _Requirements: 1.1, 1.2_

  - [ ] 7.2 Criar implementação `MexicoLocationData`
    - Implementar interface `LocationDataInterface`
    - Usar label "Estado"
    - Implementar formatação "Ciudad, Estado"
    - _Requirements: 2.1, 3.1, 3.2_

- [ ] 8. Implementar dados da Espanha
  - [ ] 8.1 Criar arquivo `spain_locations_data.dart`
    - Lista de 17 comunidades autônomas
    - Principais cidades por comunidade
    - _Requirements: 1.1, 1.2_

  - [ ] 8.2 Criar implementação `SpainLocationData`
    - Implementar interface `LocationDataInterface`
    - Usar label "Comunidade Autônoma"
    - Implementar formatação "Ciudad, Comunidad"
    - _Requirements: 2.1, 3.1, 3.2_

- [ ] 9. Implementar dados da França
  - [ ] 9.1 Criar arquivo `france_locations_data.dart`
    - Lista de 13 regiões
    - Principais cidades por região
    - _Requirements: 1.1, 1.2_

  - [ ] 9.2 Criar implementação `FranceLocationData`
    - Implementar interface `LocationDataInterface`
    - Usar label "Região"
    - Implementar formatação "Ville, Région"
    - _Requirements: 2.1, 3.1, 3.2_

- [ ] 10. Implementar dados da Itália
  - [ ] 10.1 Criar arquivo `italy_locations_data.dart`
    - Lista de 20 regiões
    - Principais cidades por região
    - _Requirements: 1.1, 1.2_

  - [ ] 10.2 Criar implementação `ItalyLocationData`
    - Implementar interface `LocationDataInterface`
    - Usar label "Região"
    - Implementar formatação "Città, Regione"
    - _Requirements: 2.1, 3.1, 3.2_

- [ ] 11. Implementar dados da Alemanha
  - [ ] 11.1 Criar arquivo `germany_locations_data.dart`
    - Lista de 16 estados (Länder)
    - Principais cidades por estado
    - _Requirements: 1.1, 1.2_

  - [ ] 11.2 Criar implementação `GermanyLocationData`
    - Implementar interface `LocationDataInterface`
    - Usar label "Estado"
    - Implementar formatação "Stadt, Land"
    - _Requirements: 2.1, 3.1, 3.2_

- [ ] 12. Implementar dados do Reino Unido
  - [ ] 12.1 Criar arquivo `uk_locations_data.dart`
    - Lista de 4 países constituintes (Inglaterra, Escócia, País de Gales, Irlanda do Norte)
    - Principais cidades por país
    - _Requirements: 1.1, 1.2_

  - [ ] 12.2 Criar implementação `UKLocationData`
    - Implementar interface `LocationDataInterface`
    - Usar label "País"
    - Implementar formatação "City, Country"
    - _Requirements: 2.1, 3.1, 3.2_

- [ ] 13. Registrar todos os países no LocationDataProvider
  - Adicionar todas as implementações ao mapa `_providers`
  - Verificar que todos os códigos de país estão corretos (ISO 3166-1)
  - Testar método `hasStructuredData()` para todos os países
  - _Requirements: 1.3, 5.3_

- [ ] 14. Atualizar ProfileIdentityTaskView
  - [ ] 14.1 Adicionar campo `_locationData` ao state
    - Adicionar variável para armazenar `LocationDataInterface`
    - Adicionar variável `_selectedCountryCode`
    - _Requirements: 2.1, 2.3_

  - [ ] 14.2 Atualizar método `_onCountryChanged`
    - Obter código do país selecionado
    - Carregar dados estruturados via `LocationDataProvider`
    - Resetar estado e cidade ao mudar país
    - _Requirements: 2.3, 2.4_

  - [ ] 14.3 Criar método `_buildLocationFields`
    - Verificar se país tem dados estruturados
    - Retornar dropdowns ou campo de texto conforme necessário
    - _Requirements: 2.1, 2.2, 6.1_

  - [ ] 14.4 Criar método `_buildStateDropdown`
    - Usar label dinâmico de `_locationData.stateLabel`
    - Popular com `_locationData.getStates()`
    - Implementar validação
    - Resetar cidade ao mudar estado
    - _Requirements: 2.1, 2.4, 3.1, 4.1_

  - [ ] 14.5 Criar método `_buildCityDropdown`
    - Popular com `_locationData.getCitiesForState()`
    - Desabilitar se estado não selecionado
    - Implementar validação
    - _Requirements: 2.1, 4.1_

  - [ ] 14.6 Atualizar método `_buildCityTextField`
    - Usar para países sem dados estruturados
    - Manter validação existente
    - _Requirements: 6.1_

  - [ ] 14.7 Atualizar método de salvamento
    - Usar `_locationData.formatLocation()` se disponível
    - Adicionar campo `countryCode` ao Firebase
    - Adicionar campo `hasStructuredData` ao Firebase
    - Manter compatibilidade com formato anterior
    - _Requirements: 3.2, 4.2, 4.3, 6.2_

- [ ] 15. Adicionar tratamento de erros
  - Implementar try-catch ao carregar dados de localização
  - Fazer fallback para campo de texto em caso de erro
  - Logar erros para debugging
  - Exibir mensagem amigável ao usuário
  - _Requirements: 6.3_

- [ ] 16. Atualizar WorldLocationsData
  - Adicionar método `getCountryCode(countryName)` se não existir
  - Verificar que todos os países têm códigos corretos
  - _Requirements: 1.3_

- [ ] 17. Criar documentação
  - Documentar como adicionar novos países
  - Criar template de arquivo de dados
  - Documentar estrutura de dados esperada
  - Adicionar exemplos de uso
  - _Requirements: 7.1, 7.2, 7.3_

- [ ]* 18. Criar testes unitários
  - [ ]* 18.1 Testar LocationDataInterface implementations
    - Testar cada implementação de país
    - Verificar formatação de localização
    - Validar siglas de estados
    - _Requirements: 1.2, 3.2_

  - [ ]* 18.2 Testar LocationDataProvider
    - Testar factory pattern
    - Verificar detecção de países com dados estruturados
    - Validar retorno de provedores corretos
    - _Requirements: 1.3_

  - [ ]* 18.3 Testar LocationErrorHandler
    - Testar tratamento de erros
    - Verificar mensagens de fallback
    - _Requirements: 6.3_

- [ ]* 19. Criar testes de widget
  - [ ]* 19.1 Testar dropdowns de localização
    - Testar renderização de dropdowns
    - Verificar interação do usuário
    - Validar estados de loading
    - _Requirements: 2.1, 5.1_

  - [ ]* 19.2 Testar validação de campos
    - Testar validação de campos obrigatórios
    - Verificar mensagens de erro
    - Validar reset de campos
    - _Requirements: 4.1_

- [ ]* 20. Criar testes de integração
  - [ ]* 20.1 Testar fluxo completo de seleção
    - Testar seleção de país → estado → cidade
    - Verificar mudança entre países
    - Validar salvamento no Firebase
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 4.2_

  - [ ]* 20.2 Testar performance
    - Medir tempo de carregamento de dropdowns
    - Verificar uso de memória
    - Validar responsividade da UI
    - _Requirements: 5.1, 5.2_

- [ ] 21. Validar e testar manualmente
  - Testar com cada país implementado
  - Verificar formatação de localização
  - Validar salvamento no Firebase
  - Testar fallback para países sem dados estruturados
  - Verificar compatibilidade com dados existentes
  - _Requirements: 2.1, 2.2, 3.2, 4.2, 6.1, 6.2_
