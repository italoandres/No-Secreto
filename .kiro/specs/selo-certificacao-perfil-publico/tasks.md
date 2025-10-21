# Implementation Plan

- [x] 1. Atualizar ProfileDisplayView para exibir selo de certificação


  - Adicionar variável de estado `hasApprovedCertification` (boolean)
  - Implementar método `_checkCertificationStatus()` que usa `CertificationStatusHelper.hasApprovedCertification(userId)`
  - Chamar `_checkCertificationStatus()` após carregar o perfil com sucesso
  - Adicionar tratamento de erros silencioso (ocultar selo em caso de erro)
  - Adicionar logs detalhados usando `EnhancedLogger` para debugging
  - _Requirements: 1.1, 1.2, 1.3, 1.5, 3.3, 3.4_


- [ ] 1.1 Modificar o método `_buildAppBar` para exibir o selo dourado
  - Adicionar ícone `Icons.verified` com cor `Colors.amber[700]` ao lado do username
  - Adicionar condicional `if (hasApprovedCertification)` para mostrar/ocultar selo
  - Adicionar `Tooltip` com mensagem "Certificação Espiritual Aprovada"
  - Garantir espaçamento adequado (8px) entre username e selo
  - Manter selo existente de preparação para os sinais (`hasSinaisPreparationSeal`)


  - _Requirements: 2.2, 2.3, 2.4_

- [ ] 2. Verificar e ajustar EnhancedVitrineDisplayView
  - Confirmar que variável `hasApprovedCertification` já existe
  - Confirmar que método `_checkCertificationStatus()` já está implementado
  - Verificar que o método é chamado após carregar o perfil

  - Confirmar que `ProfileHeaderSection` recebe parâmetro `hasVerification` corretamente
  - _Requirements: 1.1, 1.4, 2.1, 2.4_

- [ ] 2.1 Verificar e ajustar ProfileHeaderSection component
  - Confirmar que o componente aceita parâmetro `hasVerification` (boolean)
  - Verificar se o selo é exibido ao lado do `displayName` quando `hasVerification == true`
  - Confirmar uso de `Icons.verified` com cor `Colors.amber[700]`


  - Verificar `Tooltip` com mensagem "Certificação Espiritual Aprovada"
  - Garantir espaçamento adequado (8px) entre nome e selo
  - Se necessário, implementar a exibição do selo no componente
  - _Requirements: 2.2, 2.3, 2.4_

- [x] 3. Validar consistência visual entre as views


  - Comparar design do selo em ProfileDisplayView com ProfileCompletionView
  - Comparar design do selo em EnhancedVitrineDisplayView com ProfileCompletionView
  - Garantir que ícone, cor, tamanho e tooltip são idênticos em todas as views
  - Verificar que o selo aparece na mesma posição relativa (próximo ao nome/username)
  - _Requirements: 2.3, 2.5_



- [ ] 3.1 Testar cenários de exibição do selo
  - Testar visualização de perfil com certificação aprovada (selo deve aparecer)
  - Testar visualização de perfil sem certificação (selo não deve aparecer)
  - Testar visualização do próprio perfil com certificação (selo deve aparecer)



  - Testar com erro de rede (perfil deve carregar, selo não deve aparecer)
  - Testar com userId null/vazio (selo não deve aparecer, sem erros)
  - _Requirements: 1.1, 1.2, 2.1, 2.4, 2.5_

- [ ] 3.2 Validar logs e tratamento de erros
  - Verificar que logs são gerados quando certificação é verificada com sucesso
  - Verificar que erros são logados quando verificação falha
  - Confirmar que erros não impedem carregamento do perfil
  - Validar que selo é ocultado silenciosamente em caso de erro
  - _Requirements: 3.3, 3.4, 3.5_

- [ ] 4. Documentar implementação e preparar para integração futura
  - Adicionar comentários no código explicando a verificação de certificação
  - Documentar estrutura de dados do status de certificação
  - Adicionar nota sobre preparação para filtros de busca futuros
  - Documentar que o campo pode ser usado como critério de filtro
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_
