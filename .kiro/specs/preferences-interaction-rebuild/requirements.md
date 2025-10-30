# Requirements Document - Preferências de Interação (Rebuild)

## Introduction

Esta spec define a reimplementação completa do sistema de preferências de interação para perfis espirituais. O sistema atual apresenta problemas críticos de tipos de dados (Timestamp vs Bool) que impedem o funcionamento correto. Esta reimplementação criará uma solução limpa, robusta e livre de conflitos de tipos.

## Requirements

### Requirement 1

**User Story:** Como um usuário completando meu perfil espiritual, eu quero configurar minhas preferências de interação de forma simples e confiável, para que outros usuários saibam como podem interagir comigo.

#### Acceptance Criteria

1. WHEN o usuário acessa a tarefa "Preferências de Interação" THEN o sistema SHALL exibir uma interface clara com opções de configuração
2. WHEN o usuário seleciona "Permitir Demonstrações de Interesse" THEN o sistema SHALL armazenar esta preferência como boolean true
3. WHEN o usuário desmarca "Permitir Demonstrações de Interesse" THEN o sistema SHALL armazenar esta preferência como boolean false
4. WHEN o usuário clica em "Salvar Preferências" THEN o sistema SHALL persistir as configurações no Firestore sem erros de tipo
5. WHEN as preferências são salvas com sucesso THEN o sistema SHALL marcar a tarefa "preferences" como completa (true)

### Requirement 2

**User Story:** Como desenvolvedor, eu quero um sistema de preferências que seja robusto e livre de conflitos de tipos, para que não ocorram erros durante operações de update no Firestore.

#### Acceptance Criteria

1. WHEN o sistema salva preferências THEN todos os campos boolean SHALL ser armazenados como tipo boolean nativo
2. WHEN o sistema lê preferências existentes THEN SHALL converter automaticamente qualquer tipo incorreto para boolean
3. WHEN ocorre um erro de tipo durante update THEN o sistema SHALL aplicar correção automática e tentar novamente
4. WHEN a correção automática é aplicada THEN o sistema SHALL registrar logs detalhados da operação
5. IF a correção automática falhar THEN o sistema SHALL usar método de fallback (set com merge)

### Requirement 3

**User Story:** Como usuário, eu quero que minhas preferências de interação sejam refletidas corretamente na vitrine pública, para que outros usuários vejam as opções corretas de interação.

#### Acceptance Criteria

1. WHEN as preferências são salvas THEN o sistema SHALL atualizar o status de completude do perfil
2. WHEN "Permitir Demonstrações de Interesse" está ativo THEN outros usuários SHALL ver o botão "Tenho Interesse"
3. WHEN "Permitir Demonstrações de Interesse" está inativo THEN o botão de interesse SHALL estar oculto ou desabilitado
4. WHEN o perfil está completo THEN a vitrine pública SHALL ser ativada automaticamente
5. WHEN a vitrine é ativada THEN o usuário SHALL receber confirmação visual do sucesso

### Requirement 4

**User Story:** Como administrador do sistema, eu quero logs detalhados e sistema de recuperação automática, para que problemas de dados sejam identificados e corrigidos automaticamente.

#### Acceptance Criteria

1. WHEN o sistema detecta dados corrompidos THEN SHALL registrar logs detalhados com tipos e valores
2. WHEN uma correção é aplicada THEN o sistema SHALL registrar o método usado e o resultado
3. WHEN múltiplas tentativas de correção são feitas THEN cada tentativa SHALL ser logada separadamente
4. WHEN todas as correções falham THEN o sistema SHALL registrar erro crítico com stack trace completo
5. WHEN a operação é bem-sucedida THEN o sistema SHALL registrar log de sucesso com dados finais

### Requirement 5

**User Story:** Como usuário, eu quero uma experiência fluida e sem erros ao configurar preferências, para que eu possa completar meu perfil sem frustrações técnicas.

#### Acceptance Criteria

1. WHEN o usuário acessa a tela THEN a interface SHALL carregar rapidamente sem erros
2. WHEN o usuário altera configurações THEN as mudanças SHALL ser refletidas imediatamente na UI
3. WHEN o usuário salva preferências THEN SHALL ver feedback visual claro (loading, sucesso, erro)
4. WHEN ocorre um erro THEN o usuário SHALL ver mensagem amigável sem detalhes técnicos
5. WHEN a operação é bem-sucedida THEN o usuário SHALL ser redirecionado automaticamente ou ver confirmação clara

### Requirement 6

**User Story:** Como desenvolvedor, eu quero uma arquitetura limpa e separada de responsabilidades, para que o código seja maintível e testável.

#### Acceptance Criteria

1. WHEN o sistema é implementado THEN SHALL ter separação clara entre UI, lógica de negócio e persistência
2. WHEN dados são manipulados THEN SHALL usar validação e sanitização adequadas
3. WHEN erros ocorrem THEN SHALL ter tratamento específico por tipo de erro
4. WHEN operações assíncronas são executadas THEN SHALL ter timeout e retry apropriados
5. WHEN o código é estruturado THEN SHALL seguir padrões estabelecidos do projeto