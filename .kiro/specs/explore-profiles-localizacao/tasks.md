# Implementation Plan: Explore Profiles - Sistema de Localização

- [x] 1. Criar Data Models e Estruturas



  - Criar classe `AdditionalLocation` com lógica de edição
  - Adicionar campos ao `SpiritualProfileModel` para localizações adicionais
  - Implementar métodos `toJson()` e `fromJson()` para serialização
  - Adicionar validações de limite (máximo 2 localizações)
  - _Requirements: 2.1, 3.1, 7.1, 7.3_



- [ ] 2. Criar Componente de Localização Principal
  - [ ] 2.1 Implementar `PrimaryLocationCard` widget
    - Criar card com gradiente roxo/azul
    - Adicionar ícone de casa (🏠)
    - Exibir cidade e estado
    - Adicionar subtexto "(Automática do seu perfil)"


    - Aplicar estilos elegantes com sombras
    - _Requirements: 2.2, 2.3, 2.4, 6.1, 6.2_

- [ ] 3. Criar Componente de Localização Adicional
  - [ ] 3.1 Implementar `AdditionalLocationCard` widget
    - Criar card branco com sombra suave
    - Adicionar ícone de pin de localização (📍)


    - Exibir cidade e estado
    - Adicionar badge de restrição de edição
    - Implementar botões de editar e remover
    - Adicionar animações de entrada/saída
    - _Requirements: 3.1, 4.1, 4.2, 5.1, 6.1, 6.2, 6.4_
  


  - [ ] 3.2 Implementar lógica de restrição de edição
    - Calcular dias desde última edição
    - Desabilitar botão de editar se < 30 dias
    - Mostrar mensagem "Editável em X dias"
    - Adicionar tooltip explicativo
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_


- [ ] 4. Criar Dialog de Seleção de Localização
  - [ ] 4.1 Implementar `LocationSelectorDialog` widget
    - Criar dialog modal elegante
    - Adicionar dropdown de estados brasileiros
    - Adicionar dropdown de cidades (filtrado por estado)
    - Adicionar mensagem informativa sobre restrição


    - Implementar botões Cancelar e Adicionar
    - _Requirements: 3.1, 3.2, 4.1, 6.1, 6.3_
  
  - [ ] 4.2 Implementar lógica de seleção
    - Carregar lista de estados
    - Carregar cidades baseado no estado selecionado
    - Validar seleção antes de adicionar
    - Retornar cidade e estado selecionados

    - _Requirements: 3.1, 8.3_

- [ ] 5. Criar Seção de Filtros de Localização
  - [ ] 5.1 Implementar `LocationFilterSection` widget
    - Criar container principal com título "Localização de Encontros"
    - Adicionar `PrimaryLocationCard`
    - Adicionar lista de `AdditionalLocationCard`

    - Adicionar contador "X de 2 localizações"
    - Adicionar botão "Adicionar Localização"
    - Implementar lógica de enable/disable do botão
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 6.1, 6.5_

- [ ] 6. Atualizar ExploreProfilesController
  - [x] 6.1 Adicionar gerenciamento de localizações


    - Adicionar observable para localizações adicionais
    - Implementar método `addAdditionalLocation()`
    - Implementar método `removeAdditionalLocation()`
    - Implementar método `editAdditionalLocation()`
    - Validar limite de 2 localizações
    - _Requirements: 3.1, 3.2, 5.1, 5.2, 5.3_
  


  - [ ] 6.2 Implementar persistência no Firestore
    - Salvar localizações ao adicionar
    - Atualizar Firestore ao remover
    - Atualizar timestamps de edição
    - Carregar localizações ao inicializar


    - Implementar tratamento de erros
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_
  
  - [ ] 6.3 Adicionar feedback ao usuário
    - Mostrar snackbar ao adicionar localização
    - Mostrar snackbar ao remover localização
    - Mostrar mensagem de erro quando apropriado
    - Mostrar mensagem de limite atingido
    - Usar cores apropriadas (verde/vermelho)
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5_

- [ ] 7. Integrar com ExploreProfilesView
  - [ ] 7.1 Adicionar header com título motivacional
    - Adicionar título "Espero esses Sinais..."
    - Adicionar mensagem motivacional abaixo
    - Aplicar tipografia elegante
    - Posicionar acima dos filtros
    - _Requirements: 1.1, 1.2, 1.3, 1.4_
  
  - [ ] 7.2 Integrar LocationFilterSection
    - Adicionar seção de filtros após o header
    - Conectar com controller
    - Implementar callbacks de ações
    - Testar fluxo completo
    - _Requirements: 2.1, 3.1, 5.1_

- [ ] 8. Implementar Busca por Localização
  - [ ] 8.1 Atualizar query de busca de perfis
    - Filtrar perfis por localização principal
    - Incluir perfis de localizações adicionais
    - Ordenar por proximidade da localização principal
    - Implementar paginação eficiente
    - _Requirements: 9.1, 9.2, 9.3, 9.4_
  
  - [ ] 8.2 Adicionar feedback quando não há resultados
    - Mostrar mensagem "Nenhum perfil encontrado nessas localizações"
    - Sugerir expandir busca ou adicionar mais localizações
    - _Requirements: 9.5_

- [ ] 9. Adicionar Animações e Polish
  - [ ] 9.1 Implementar animações de transição
    - Slide in ao adicionar localização
    - Fade out ao remover localização
    - Bounce effect em confirmações
    - Hover states em botões e cards
    - _Requirements: 6.4_
  
  - [ ] 9.2 Refinar estilos visuais
    - Ajustar cores e gradientes
    - Refinar sombras e elevações
    - Ajustar espaçamentos
    - Garantir consistência visual
    - _Requirements: 6.1, 6.2, 6.3, 6.5_

- [ ]* 10. Testes e Validação
  - [ ]* 10.1 Testes unitários
    - Testar lógica de `AdditionalLocation`
    - Testar validações do controller
    - Testar cálculos de dias até edição
    - _Requirements: Todos_
  
  - [ ]* 10.2 Testes de integração
    - Testar fluxo completo de adicionar/remover
    - Testar persistência no Firestore
    - Testar restrições de edição
    - Testar busca por localização
    - _Requirements: Todos_
