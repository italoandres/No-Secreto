# Implementation Plan - Sincronização de Dados do Perfil para Vitrine

## Tarefas de Implementação

- [x] 1. Criar componentes de UI para novas seções





- [ ] 1.1 Criar LocationInfoSection
  - Criar arquivo `lib/components/location_info_section.dart`
  - Implementar widget que exibe cidade, estado e país
  - Adicionar ícone de localização e formatação adequada
  - Ocultar seção se não houver dados de localização


  - _Requirements: 1.1, 2.1_

- [ ] 1.2 Criar EducationInfoSection
  - Criar arquivo `lib/components/education_info_section.dart`
  - Implementar widget que exibe educação, curso, universidade e profissão


  - Adicionar ícones apropriados para cada campo
  - Ocultar seção se não houver dados educacionais
  - _Requirements: 1.2, 2.2_

- [x] 1.3 Criar LifestyleInfoSection


  - Criar arquivo `lib/components/lifestyle_info_section.dart`
  - Implementar widget que exibe altura, status de fumante e bebida
  - Adicionar ícones apropriados para cada campo
  - Ocultar seção se não houver dados de estilo de vida
  - _Requirements: 1.3, 2.3_



- [ ] 1.4 Criar HobbiesSection
  - Criar arquivo `lib/components/hobbies_section.dart`
  - Implementar widget que exibe lista de hobbies em chips/tags
  - Usar layout grid responsivo para os hobbies


  - Ocultar seção se não houver hobbies cadastrados
  - _Requirements: 1.4, 2.3_

- [x] 1.5 Criar LanguagesSection




  - Criar arquivo `lib/components/languages_section.dart`
  - Implementar widget que exibe lista de idiomas
  - Adicionar ícone de idioma e formatação em lista
  - Ocultar seção se não houver idiomas cadastrados
  - _Requirements: 1.5, 2.4_





- [ ] 1.6 Criar PhotoGallerySection
  - Criar arquivo `lib/components/photo_gallery_section.dart`


  - Implementar widget que exibe galeria de fotos (principal + secundárias)
  - Adicionar funcionalidade de clicar para ver foto em tela cheia
  - Usar layout grid para exibir fotos
  - Ocultar seção se não houver fotos secundárias
  - _Requirements: 1.6, 4.1, 4.2, 4.3, 4.4, 4.5_

- [ ] 2. Atualizar RelationshipStatusSection para incluir virgindade
- [ ] 2.1 Adicionar campo isVirgin ao RelationshipStatusSection
  - Abrir arquivo `lib/components/relationship_status_section.dart`

  - Adicionar prop `bool? isVirgin` ao componente
  - Adicionar exibição do status de virgindade na seção
  - Usar ícone apropriado e texto claro
  - Ocultar campo se não estiver preenchido
  - _Requirements: 2.5_

- [ ] 3. Integrar novos componentes na EnhancedVitrineDisplayView
- [x] 3.1 Adicionar imports dos novos componentes

  - Abrir arquivo `lib/views/enhanced_vitrine_display_view.dart`

  - Adicionar imports de todos os novos componentes
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_

- [ ] 3.2 Atualizar método _buildVitrineContent
  - Adicionar LocationInfoSection após ProfileHeaderSection
  - Adicionar LanguagesSection dentro ou após BasicInfoSection
  - Adicionar EducationInfoSection após SpiritualInfoSection

  - Adicionar LifestyleInfoSection após EducationInfoSection
  - Adicionar HobbiesSection após LifestyleInfoSection
  - Atualizar RelationshipStatusSection com campo isVirgin



  - Adicionar PhotoGallerySection no final (antes do espaço do botão)
  - Manter espaçamento adequado entre seções (24px)
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 5.1, 5.2_


- [ ] 3.3 Passar dados do profileData para os novos componentes
  - Passar `fullLocation`, `state`, `country` para LocationInfoSection
  - Passar `education`, `universityCourse`, `courseStatus`, `university`, `occupation` para EducationInfoSection

  - Passar `height`, `smokingStatus`, `drinkingStatus` para LifestyleInfoSection

  - Passar `hobbies` para HobbiesSection
  - Passar `languages` para LanguagesSection
  - Passar `mainPhotoUrl`, `secondaryPhoto1Url`, `secondaryPhoto2Url` para PhotoGallerySection
  - Passar `isVirgin` para RelationshipStatusSection
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_


- [ ] 4. Implementar visualização de foto em tela cheia
- [ ] 4.1 Criar PhotoViewerScreen
  - Criar arquivo `lib/views/photo_viewer_screen.dart`
  - Implementar tela que exibe foto em tela cheia

  - Adicionar funcionalidade de swipe entre fotos
  - Adicionar botão de fechar
  - Adicionar indicador de posição (1/3, 2/3, etc.)
  - _Requirements: 4.3_

- [x] 4.2 Integrar PhotoViewerScreen com PhotoGallerySection

  - Adicionar navegação para PhotoViewerScreen ao clicar em foto
  - Passar lista de fotos e índice inicial
  - _Requirements: 4.3_



- [x] 5. Adicionar tratamento de erros e estados vazios

- [ ] 5.1 Implementar verificação de dados vazios em cada componente
  - Verificar se dados são null ou vazios antes de renderizar
  - Retornar `SizedBox.shrink()` se não houver dados
  - _Requirements: 5.2_


- [ ] 5.2 Implementar fallback para imagens quebradas
  - Adicionar `errorBuilder` em NetworkImage
  - Mostrar placeholder com ícone quando imagem falhar
  - _Requirements: 1.6, 4.1_


- [ ] 6. Testar e validar implementação
- [ ] 6.1 Testar com perfil completo
  - Criar perfil de teste com todos os campos preenchidos
  - Verificar se todas as seções aparecem corretamente
  - Verificar espaçamento e layout
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_

- [ ] 6.2 Testar com perfil parcial
  - Criar perfil de teste com apenas campos obrigatórios
  - Verificar se seções vazias são ocultadas
  - Verificar se não há erros de null
  - _Requirements: 1.4, 5.2_

- [ ] 6.3 Testar galeria de fotos
  - Testar com 1, 2 e 3 fotos
  - Testar clique para abrir em tela cheia
  - Testar swipe entre fotos
  - Testar com imagens quebradas
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_

- [ ] 6.4 Testar responsividade
  - Testar em diferentes tamanhos de tela
  - Verificar se layout se adapta corretamente
  - Verificar se textos não quebram
  - _Requirements: 3.4, 5.3, 5.4_

- [ ] 7. Ajustes finais e polimento
- [ ] 7.1 Ajustar cores e ícones
  - Verificar se cores estão consistentes com AppColors
  - Verificar se ícones são apropriados para cada seção
  - _Requirements: 5.3, 5.4_

- [ ] 7.2 Ajustar espaçamentos
  - Verificar espaçamento entre seções (24px)
  - Verificar padding interno dos cards (20px)
  - Verificar padding externo (16px horizontal)
  - _Requirements: 5.5_

- [ ] 7.3 Adicionar animações suaves (opcional)
  - Adicionar fade-in ao carregar seções
  - Adicionar animação ao abrir foto em tela cheia
  - _Requirements: 5.3_

## Notas de Implementação

### Ordem de Execução
1. Começar pelos componentes mais simples (LocationInfoSection, LanguagesSection)
2. Depois componentes médios (EducationInfoSection, LifestyleInfoSection, HobbiesSection)
3. Depois componente complexo (PhotoGallerySection)
4. Por último, integração e testes

### Padrão de Código
- Usar `const` sempre que possível
- Seguir padrão de nomenclatura existente
- Adicionar comentários em código complexo
- Usar `SizedBox.shrink()` para ocultar seções vazias

### Validação de Dados
- Sempre verificar null antes de acessar propriedades
- Usar operador `?.` para acesso seguro
- Usar `??` para valores padrão
- Validar listas vazias com `isEmpty`

### Performance
- Usar `CachedNetworkImage` para imagens
- Evitar rebuilds desnecessários
- Usar `ListView.builder` para listas longas

### Acessibilidade
- Adicionar `Semantics` para leitores de tela
- Usar contraste adequado de cores
- Adicionar labels em ícones

## Dependências

### Pacotes Necessários
- `cached_network_image` - Para cache de imagens
- `photo_view` - Para visualização de fotos em tela cheia (opcional)

### Arquivos a Modificar
- `lib/views/enhanced_vitrine_display_view.dart`
- `lib/components/relationship_status_section.dart`

### Arquivos a Criar
- `lib/components/location_info_section.dart`
- `lib/components/education_info_section.dart`
- `lib/components/lifestyle_info_section.dart`
- `lib/components/hobbies_section.dart`
- `lib/components/languages_section.dart`
- `lib/components/photo_gallery_section.dart`
- `lib/views/photo_viewer_screen.dart`

## Critérios de Aceitação

### Funcionalidade
- ✅ Todas as informações cadastradas aparecem na vitrine
- ✅ Seções vazias são ocultadas
- ✅ Galeria de fotos funciona corretamente
- ✅ Campo isVirgin aparece na seção de relacionamento
- ✅ Imagens quebradas têm fallback

### UI/UX
- ✅ Layout é visualmente atraente
- ✅ Espaçamento é consistente
- ✅ Cores seguem o tema do app
- ✅ Ícones são apropriados
- ✅ Responsivo em diferentes telas

### Performance
- ✅ Carregamento é rápido
- ✅ Imagens são cacheadas
- ✅ Não há travamentos

### Qualidade de Código
- ✅ Código é limpo e organizado
- ✅ Componentes são reutilizáveis
- ✅ Sem erros de null
- ✅ Sem warnings

## Estimativa de Tempo

- Componentes simples (1-3): ~2 horas
- Componentes médios (4-5): ~3 horas
- Componente complexo (6): ~2 horas
- Integração: ~1 hora
- Testes: ~2 horas
- Ajustes finais: ~1 hora

**Total estimado: ~11 horas**
