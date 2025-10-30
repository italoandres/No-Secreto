# Requisitos - Sistema de Certificação Espiritual com Verificação

## Introdução

Sistema completo para certificação espiritual do curso "No Secreto com o Pai", permitindo que usuários solicitem o selo através de upload de comprovante, e que administradores aprovem/rejeitem as solicitações via email ou painel admin.

## Requirements

### Requirement 1: Solicitação de Certificação pelo Usuário

**User Story:** Como usuário do app, quero solicitar minha certificação espiritual enviando o comprovante do curso, para que eu possa receber o selo verificado no meu perfil.

#### Acceptance Criteria

1. WHEN o usuário acessa "Vitrine de Propósito" → "Certificação Espiritual" THEN o sistema SHALL exibir um formulário com fundo âmbar/dourado
2. WHEN o formulário é exibido THEN o sistema SHALL mostrar campos para:
   - Upload de comprovante (PDF ou imagem)
   - Email da compra do curso
   - Email do usuário no app (pré-preenchido)
3. WHEN o usuário seleciona um arquivo THEN o sistema SHALL validar que é PDF, JPG, JPEG ou PNG
4. WHEN o usuário preenche todos os campos obrigatórios THEN o sistema SHALL habilitar o botão "Enviar para Verificação"
5. WHEN o usuário envia a solicitação THEN o sistema SHALL salvar no Firebase com status "pending"
6. WHEN a solicitação é enviada THEN o sistema SHALL exibir mensagem "Solicitação enviada! Você receberá resposta em até 3 dias úteis"

### Requirement 2: Notificação por Email ao Admin

**User Story:** Como administrador, quero receber um email quando um usuário solicita certificação, para que eu possa revisar e aprovar/rejeitar rapidamente.

#### Acceptance Criteria

1. WHEN uma solicitação é criada THEN o sistema SHALL enviar email para sinais.app@gmail.com
2. WHEN o email é enviado THEN o sistema SHALL incluir:
   - Nome do usuário
   - Email da compra
   - Email do app
   - Link para download do comprovante
   - Link para aprovar
   - Link para rejeitar
3. WHEN o admin clica em "Aprovar" no email THEN o sistema SHALL atualizar o status para "approved"
4. WHEN o admin clica em "Rejeitar" no email THEN o sistema SHALL atualizar o status para "rejected"

### Requirement 3: Painel Admin para Gerenciar Certificações

**User Story:** Como administrador, quero acessar um painel para gerenciar todas as solicitações de certificação, para ter controle total do processo.

#### Acceptance Criteria

1. WHEN o admin acessa o painel THEN o sistema SHALL listar todas as solicitações com status "pending"
2. WHEN uma solicitação é exibida THEN o sistema SHALL mostrar:
   - Foto do usuário
   - Nome completo
   - Email da compra
   - Email do app
   - Data da solicitação
   - Botão para visualizar comprovante
   - Botões "Aprovar" e "Rejeitar"
3. WHEN o admin clica em "Aprovar" THEN o sistema SHALL atualizar isSpiritualCertified para true
4. WHEN o admin clica em "Rejeitar" THEN o sistema SHALL manter isSpiritualCertified como false
5. WHEN o status muda THEN o sistema SHALL enviar notificação in-app para o usuário

### Requirement 4: Notificação In-App para o Usuário

**User Story:** Como usuário, quero receber uma notificação no app quando minha certificação for aprovada ou rejeitada, para saber o resultado imediatamente.

#### Acceptance Criteria

1. WHEN a certificação é aprovada THEN o sistema SHALL criar notificação "Parabéns! Sua certificação espiritual foi aprovada ✅"
2. WHEN a certificação é rejeitada THEN o sistema SHALL criar notificação "Sua solicitação de certificação precisa de revisão. Entre em contato conosco."
3. WHEN a notificação é criada THEN o sistema SHALL exibir no ícone de notificações
4. WHEN o usuário clica na notificação THEN o sistema SHALL navegar para a tela de certificação

### Requirement 5: Exibição do Selo no Perfil

**User Story:** Como usuário certificado, quero que meu selo apareça automaticamente no perfil, para que outros usuários vejam minha preparação espiritual.

#### Acceptance Criteria

1. WHEN isSpiritualCertified é true THEN o sistema SHALL exibir selo dourado no perfil
2. WHEN o usuário visualiza seu próprio perfil THEN o sistema SHALL mostrar status "Certificado ✓"
3. WHEN outro usuário visualiza o perfil certificado THEN o sistema SHALL exibir o selo visível
4. WHEN o usuário não tem certificação THEN o sistema SHALL mostrar botão "Solicitar Certificação"

### Requirement 6: Upload e Armazenamento de Arquivos

**User Story:** Como sistema, preciso fazer upload seguro dos comprovantes para o Firebase Storage, para garantir que os arquivos estejam disponíveis para revisão.

#### Acceptance Criteria

1. WHEN o usuário seleciona um arquivo THEN o sistema SHALL validar tamanho máximo de 5MB
2. WHEN o arquivo é válido THEN o sistema SHALL fazer upload para Firebase Storage em /certifications/{userId}/{timestamp}
3. WHEN o upload é concluído THEN o sistema SHALL salvar a URL no documento da solicitação
4. WHEN o upload falha THEN o sistema SHALL exibir mensagem de erro clara
5. WHEN o admin visualiza THEN o sistema SHALL permitir download do arquivo original

### Requirement 7: Histórico de Solicitações

**User Story:** Como usuário, quero ver o histórico das minhas solicitações de certificação, para acompanhar o status.

#### Acceptance Criteria

1. WHEN o usuário acessa a tela de certificação THEN o sistema SHALL mostrar histórico de solicitações
2. WHEN há solicitação pendente THEN o sistema SHALL exibir "Aguardando aprovação..."
3. WHEN a certificação foi aprovada THEN o sistema SHALL exibir "Aprovada em [data]"
4. WHEN a certificação foi rejeitada THEN o sistema SHALL exibir "Rejeitada em [data]" com opção de reenviar
