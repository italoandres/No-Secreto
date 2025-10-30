# Requirements Document - Sistema de Aprovação de Certificação Espiritual

## Introduction

Este documento define os requisitos para um sistema completo de aprovação/reprovação de certificações espirituais. O sistema permitirá que administradores revisem solicitações de certificação e tomem decisões (aprovar/reprovar) de forma rápida e eficiente, seja através de links no email ou através do painel administrativo no app. Quando uma decisão for tomada, o usuário receberá notificação automática no app e, se aprovado, o selo de certificação aparecerá visualmente em seu perfil.

## Requirements

### Requirement 1: Botões de Ação Rápida no Email

**User Story:** Como administrador, quero receber emails com links diretos para aprovar ou reprovar certificações, para que eu possa tomar decisões rapidamente sem precisar abrir o app.

#### Acceptance Criteria

1. WHEN o email de solicitação de certificação é enviado THEN o email SHALL incluir dois botões/links claramente visíveis: "Aprovar Certificação" e "Reprovar Certificação"
2. WHEN o administrador clica no botão "Aprovar Certificação" THEN o sistema SHALL processar a aprovação automaticamente através de uma Cloud Function
3. WHEN o administrador clica no botão "Reprovar Certificação" THEN o sistema SHALL abrir uma página web simples solicitando o motivo da reprovação
4. WHEN a aprovação é processada via link do email THEN o sistema SHALL atualizar o status no Firestore para "approved"
5. WHEN a reprovação é processada via link do email THEN o sistema SHALL atualizar o status no Firestore para "rejected" com o motivo fornecido
6. WHEN uma ação é processada via email THEN o sistema SHALL exibir uma página de confirmação ao administrador

### Requirement 2: Painel Administrativo de Certificações

**User Story:** Como administrador, quero acessar um painel no app para revisar todas as solicitações de certificação pendentes, para que eu possa analisar os comprovantes antes de tomar uma decisão.

#### Acceptance Criteria

1. WHEN o administrador acessa o painel de certificações THEN o sistema SHALL exibir uma lista de todas as solicitações pendentes ordenadas por data
2. WHEN o administrador visualiza uma solicitação THEN o sistema SHALL exibir: nome do usuário, email, email de compra, data da solicitação, e preview do comprovante
3. WHEN o administrador clica no comprovante THEN o sistema SHALL abrir o arquivo em tela cheia para visualização detalhada
4. WHEN o administrador clica em "Aprovar" no painel THEN o sistema SHALL solicitar confirmação antes de processar
5. WHEN o administrador clica em "Reprovar" no painel THEN o sistema SHALL solicitar o motivo da reprovação antes de processar
6. WHEN uma decisão é tomada no painel THEN o sistema SHALL atualizar o status imediatamente e remover da lista de pendentes
7. WHEN não há solicitações pendentes THEN o sistema SHALL exibir uma mensagem amigável informando que não há solicitações

### Requirement 3: Notificação Automática ao Usuário

**User Story:** Como usuário que solicitou certificação, quero receber uma notificação no app quando minha solicitação for aprovada ou reprovada, para que eu saiba o resultado imediatamente.

#### Acceptance Criteria

1. WHEN uma certificação é aprovada THEN o sistema SHALL criar uma notificação no app para o usuário informando a aprovação
2. WHEN uma certificação é reprovada THEN o sistema SHALL criar uma notificação no app para o usuário informando a reprovação e o motivo
3. WHEN o usuário abre a notificação de aprovação THEN o sistema SHALL navegar para a tela de perfil mostrando o selo
4. WHEN o usuário abre a notificação de reprovação THEN o sistema SHALL navegar para a tela de certificação permitindo nova solicitação
5. WHEN uma notificação é criada THEN o sistema SHALL garantir que ela apareça na lista de notificações do usuário
6. WHEN o usuário já visualizou a notificação THEN o sistema SHALL marcar como lida mas manter no histórico

### Requirement 4: Exibição Visual do Selo de Certificação

**User Story:** Como usuário certificado, quero que meu selo de certificação espiritual apareça visualmente no meu perfil, para que outros usuários possam ver que sou certificado.

#### Acceptance Criteria

1. WHEN um usuário tem certificação aprovada THEN o sistema SHALL exibir um selo/badge de certificação espiritual no cabeçalho do perfil
2. WHEN outro usuário visualiza o perfil de um certificado THEN o selo SHALL ser claramente visível e destacado
3. WHEN o usuário clica no selo THEN o sistema SHALL exibir informações sobre a certificação (data de aprovação, significado)
4. WHEN o perfil é exibido na vitrine THEN o selo SHALL aparecer também nos cards de perfil
5. WHEN o perfil é exibido em listas de busca THEN o selo SHALL aparecer como indicador visual
6. WHEN o usuário não tem certificação aprovada THEN o selo SHALL não aparecer em nenhum lugar

### Requirement 5: Histórico e Auditoria de Certificações

**User Story:** Como administrador, quero visualizar o histórico completo de todas as certificações (aprovadas e reprovadas), para que eu possa auditar decisões e acompanhar estatísticas.

#### Acceptance Criteria

1. WHEN o administrador acessa a aba de histórico THEN o sistema SHALL exibir todas as certificações processadas
2. WHEN o histórico é exibido THEN o sistema SHALL mostrar: usuário, data da solicitação, data da decisão, status, e quem aprovou/reprovou
3. WHEN o administrador filtra por status THEN o sistema SHALL exibir apenas certificações com aquele status
4. WHEN o administrador busca por usuário THEN o sistema SHALL encontrar todas as solicitações daquele usuário
5. WHEN o administrador visualiza uma certificação histórica THEN o sistema SHALL permitir visualizar o comprovante original
6. WHEN há múltiplas solicitações do mesmo usuário THEN o sistema SHALL exibir todas em ordem cronológica

### Requirement 6: Segurança e Validação de Links

**User Story:** Como sistema, quero garantir que apenas administradores autorizados possam aprovar/reprovar certificações através dos links de email, para prevenir fraudes.

#### Acceptance Criteria

1. WHEN um link de aprovação/reprovação é gerado THEN o sistema SHALL incluir um token único e criptografado
2. WHEN um link é acessado THEN o sistema SHALL validar que o token é válido e não expirou
3. WHEN um link já foi usado THEN o sistema SHALL impedir uso duplicado e exibir mensagem apropriada
4. WHEN um link expira (após 7 dias) THEN o sistema SHALL exibir mensagem informando que a ação deve ser feita pelo painel
5. WHEN um token inválido é detectado THEN o sistema SHALL registrar a tentativa suspeita e negar acesso
6. WHEN uma ação é processada THEN o sistema SHALL registrar o IP e timestamp para auditoria

### Requirement 7: Email de Confirmação ao Administrador

**User Story:** Como administrador, quero receber um email de confirmação após processar uma certificação, para ter registro da ação tomada.

#### Acceptance Criteria

1. WHEN uma certificação é aprovada THEN o sistema SHALL enviar email de confirmação ao administrador que aprovou
2. WHEN uma certificação é reprovada THEN o sistema SHALL enviar email de confirmação ao administrador que reprovou
3. WHEN o email de confirmação é enviado THEN o sistema SHALL incluir: nome do usuário, ação tomada, data/hora, e link para o painel
4. WHEN múltiplas ações são tomadas em sequência THEN o sistema SHALL enviar emails individuais para cada ação
5. IF o envio do email de confirmação falhar THEN o sistema SHALL registrar o erro mas não reverter a ação

### Requirement 8: Atualização em Tempo Real

**User Story:** Como administrador com o painel aberto, quero ver atualizações em tempo real quando novas solicitações chegam ou quando outro admin processa uma solicitação, para manter informações sempre atualizadas.

#### Acceptance Criteria

1. WHEN uma nova solicitação é criada THEN o painel admin SHALL atualizar automaticamente mostrando a nova solicitação
2. WHEN outro administrador processa uma solicitação THEN o painel SHALL remover automaticamente da lista de pendentes
3. WHEN o usuário está visualizando uma solicitação e ela é processada por outro admin THEN o sistema SHALL exibir notificação informando
4. WHEN há mudanças no status THEN o sistema SHALL usar Firestore listeners para atualização em tempo real
5. WHEN a conexão é perdida THEN o sistema SHALL exibir indicador de offline e reconectar automaticamente
