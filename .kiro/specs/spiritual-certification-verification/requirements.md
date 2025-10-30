# Requirements Document - Sistema de Verificação de Certificação Espiritual

## Introduction

Este documento define os requisitos para implementar um sistema completo de verificação de certificação espiritual, onde usuários podem solicitar o selo "Preparado(a) para os Sinais" enviando comprovante de conclusão do curso. O sistema inclui upload de anexo, validação de emails, aprovação manual pelo administrador e notificações por email.

## Requirements

### Requirement 1: Formulário de Solicitação de Certificação

**User Story:** Como usuário que completou o curso "Preparado(a) para os Sinais", quero enviar uma solicitação de certificação com comprovante, para que o administrador possa verificar e aprovar meu selo.

#### Acceptance Criteria

1. WHEN o usuário acessa a página "Certificação Espiritual" THEN o sistema SHALL exibir um formulário de solicitação
2. WHEN o usuário preenche o formulário THEN o sistema SHALL solicitar:
   - Upload de anexo (comprovante de conclusão do curso)
   - Email usado na compra do curso
   - Email do app (pré-preenchido, mas editável)
3. WHEN o usuário tenta enviar sem preencher campos obrigatórios THEN o sistema SHALL exibir mensagens de validação
4. WHEN o usuário envia a solicitação THEN o sistema SHALL salvar no Firebase com status "pending"
5. WHEN a solicitação é enviada THEN o sistema SHALL exibir mensagem "Em até 3 dias úteis você poderá receber o selo de verificação"

### Requirement 2: Upload de Comprovante

**User Story:** Como usuário, quero fazer upload do comprovante de conclusão do curso, para provar que completei o treinamento oficial.

#### Acceptance Criteria

1. WHEN o usuário clica no botão de upload THEN o sistema SHALL permitir selecionar imagem ou PDF
2. WHEN o arquivo é selecionado THEN o sistema SHALL fazer upload para Firebase Storage
3. WHEN o upload está em progresso THEN o sistema SHALL exibir indicador de progresso
4. WHEN o upload é concluído THEN o sistema SHALL exibir preview do arquivo
5. WHEN o usuário quer remover o arquivo THEN o sistema SHALL permitir excluir e selecionar outro
6. IF o arquivo exceder 5MB THEN o sistema SHALL exibir erro "Arquivo muito grande. Máximo 5MB"

### Requirement 3: Validação de Emails

**User Story:** Como usuário, quero informar meu email de compra e confirmar meu email do app, para que o administrador possa validar minha identidade.

#### Acceptance Criteria

1. WHEN o formulário é carregado THEN o sistema SHALL pré-preencher o campo "Email do App" com o email do usuário logado
2. WHEN o usuário digita no campo "Email da Compra" THEN o sistema SHALL validar formato de email
3. WHEN o usuário deixa o campo "Email da Compra" vazio THEN o sistema SHALL exibir erro "Campo obrigatório"
4. WHEN o usuário edita o "Email do App" THEN o sistema SHALL permitir alteração
5. IF os emails forem diferentes THEN o sistema SHALL exibir aviso informativo "Os emails podem ser diferentes"

### Requirement 4: Notificação por Email ao Administrador

**User Story:** Como administrador, quero receber email quando houver nova solicitação de certificação, para que eu possa revisar e aprovar rapidamente.

#### Acceptance Criteria

1. WHEN uma solicitação é enviada THEN o sistema SHALL enviar email para sinais.app@gmail.com
2. WHEN o email é enviado THEN o sistema SHALL incluir:
   - Nome do usuário
   - Email do app
   - Email da compra
   - Link para o comprovante anexado
   - Link direto para o painel admin
3. IF o envio de email falhar THEN o sistema SHALL registrar erro mas não bloquear a solicitação
4. WHEN o email é enviado THEN o sistema SHALL usar template HTML profissional

### Requirement 5: Painel de Aprovação do Administrador

**User Story:** Como administrador, quero visualizar todas as solicitações pendentes e aprovar/rejeitar cada uma, para garantir que apenas usuários legítimos recebam o selo.

#### Acceptance Criteria

1. WHEN o admin acessa o painel THEN o sistema SHALL listar todas as solicitações com status "pending"
2. WHEN o admin visualiza uma solicitação THEN o sistema SHALL exibir:
   - Foto do usuário
   - Nome completo
   - Email do app
   - Email da compra
   - Comprovante anexado (visualização)
   - Data da solicitação
3. WHEN o admin clica em "Aprovar" THEN o sistema SHALL:
   - Atualizar status para "approved"
   - Adicionar o selo ao perfil do usuário
   - Enviar email de aprovação ao usuário
4. WHEN o admin clica em "Rejeitar" THEN o sistema SHALL:
   - Atualizar status para "rejected"
   - Solicitar motivo da rejeição
   - Enviar email de rejeição ao usuário com o motivo
5. WHEN o admin aprova/rejeita THEN o sistema SHALL registrar timestamp e ID do admin

### Requirement 6: Notificação por Email ao Usuário

**User Story:** Como usuário, quero receber email quando minha solicitação for aprovada ou rejeitada, para saber o status da minha certificação.

#### Acceptance Criteria

1. WHEN a solicitação é aprovada THEN o sistema SHALL enviar email ao usuário com:
   - Mensagem de parabéns
   - Confirmação do selo ativo
   - Benefícios do selo
2. WHEN a solicitação é rejeitada THEN o sistema SHALL enviar email ao usuário com:
   - Motivo da rejeição
   - Instruções para nova solicitação
3. WHEN o email é enviado THEN o sistema SHALL usar o email do app do usuário
4. IF o envio falhar THEN o sistema SHALL registrar erro e tentar reenviar

### Requirement 7: Status da Solicitação

**User Story:** Como usuário, quero visualizar o status da minha solicitação de certificação, para saber se está pendente, aprovada ou rejeitada.

#### Acceptance Criteria

1. WHEN o usuário tem solicitação pendente THEN o sistema SHALL exibir:
   - Badge "Aguardando Aprovação"
   - Mensagem "Em análise. Você receberá resposta em até 3 dias úteis"
   - Data da solicitação
2. WHEN o usuário tem solicitação aprovada THEN o sistema SHALL exibir:
   - Badge "Aprovado"
   - Selo ativo no perfil
   - Data de aprovação
3. WHEN o usuário tem solicitação rejeitada THEN o sistema SHALL exibir:
   - Badge "Rejeitado"
   - Motivo da rejeição
   - Botão "Solicitar Novamente"
4. WHEN o usuário clica em "Solicitar Novamente" THEN o sistema SHALL permitir nova solicitação

### Requirement 8: Integração com Firebase

**User Story:** Como desenvolvedor, quero armazenar todas as solicitações no Firebase, para garantir persistência e sincronização em tempo real.

#### Acceptance Criteria

1. WHEN uma solicitação é criada THEN o sistema SHALL salvar em `certification_requests/{requestId}`
2. WHEN o documento é salvo THEN o sistema SHALL incluir:
   - userId
   - userEmail (email do app)
   - purchaseEmail (email da compra)
   - proofUrl (URL do comprovante no Storage)
   - status (pending/approved/rejected)
   - requestedAt (timestamp)
   - reviewedAt (timestamp, quando aprovado/rejeitado)
   - reviewedBy (ID do admin)
   - rejectionReason (se rejeitado)
3. WHEN o status muda THEN o sistema SHALL atualizar o documento em tempo real
4. WHEN o comprovante é enviado THEN o sistema SHALL salvar em `certification_proofs/{userId}/{filename}`

### Requirement 9: Validação de Segurança

**User Story:** Como administrador do sistema, quero garantir que apenas usuários autenticados possam solicitar certificação, para prevenir abusos.

#### Acceptance Criteria

1. WHEN um usuário não autenticado tenta acessar THEN o sistema SHALL redirecionar para login
2. WHEN um usuário já tem selo aprovado THEN o sistema SHALL exibir status e não permitir nova solicitação
3. WHEN um usuário tem solicitação pendente THEN o sistema SHALL não permitir enviar outra
4. IF o usuário tentar manipular dados THEN o sistema SHALL validar no backend via Security Rules

### Requirement 10: Experiência do Usuário

**User Story:** Como usuário, quero uma interface clara e intuitiva para solicitar minha certificação, para facilitar o processo.

#### Acceptance Criteria

1. WHEN o usuário acessa a página THEN o sistema SHALL exibir instruções claras
2. WHEN o usuário preenche o formulário THEN o sistema SHALL fornecer feedback visual
3. WHEN há erro THEN o sistema SHALL exibir mensagens claras e acionáveis
4. WHEN a solicitação é enviada THEN o sistema SHALL exibir confirmação visual
5. WHEN o usuário aguarda aprovação THEN o sistema SHALL exibir prazo estimado (3 dias úteis)
