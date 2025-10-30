# Requirements Document - Sistema de Notificações de Interesse

## Introduction

Este documento define os requisitos para criar um sistema de notificações de interesse que funcione perfeitamente, baseado no sistema funcional de convites do "Nosso Propósito". O objetivo é detectar quando alguém clica "Tenho Interesse" e notificar o usuário destinatário instantaneamente.

## Requirements

### Requirement 1: Detectar Interesse Demonstrado

**User Story:** Como usuário que recebe interesse, eu quero ser notificado instantaneamente quando alguém clica "Tenho Interesse" no meu perfil, para que eu saiba quem tem interesse em mim.

#### Acceptance Criteria

1. WHEN usuário A clica "Tenho Interesse" no perfil do usuário B THEN o sistema SHALL criar uma notificação de interesse no Firebase
2. WHEN a notificação é criada THEN ela SHALL conter fromUserId, fromUserName, toUserId, type='interest', status='pending'
3. WHEN a notificação é salva THEN o usuário B SHALL receber a notificação em tempo real via stream
4. WHEN há erro na criação THEN o sistema SHALL mostrar mensagem de erro clara
5. WHEN o interesse já foi demonstrado THEN o sistema SHALL prevenir duplicatas

### Requirement 2: Exibir Notificações de Interesse

**User Story:** Como usuário que recebeu interesse, eu quero ver uma lista clara das notificações de interesse, para que eu possa decidir como responder.

#### Acceptance Criteria

1. WHEN o usuário tem notificações pendentes THEN o sistema SHALL exibir o componente InterestNotificationsComponent
2. WHEN as notificações são exibidas THEN elas SHALL mostrar foto, nome, mensagem e tempo do interessado
3. WHEN há múltiplas notificações THEN elas SHALL ser ordenadas por data (mais recente primeiro)
4. WHEN não há notificações THEN o componente SHALL ficar oculto
5. WHEN há notificações não lidas THEN o sistema SHALL mostrar contador visual

### Requirement 3: Responder a Interesse

**User Story:** Como usuário que recebeu interesse, eu quero poder responder com "Também Tenho", "Não Tenho" ou "Ver Perfil", para que eu possa gerenciar os interesses recebidos.

#### Acceptance Criteria

1. WHEN o usuário clica "Também Tenho" THEN o sistema SHALL marcar como aceito e criar match mútuo
2. WHEN o usuário clica "Não Tenho" THEN o sistema SHALL marcar como rejeitado
3. WHEN o usuário clica "Ver Perfil" THEN o sistema SHALL navegar para o perfil do interessado
4. WHEN uma resposta é dada THEN o sistema SHALL atualizar o status no Firebase
5. WHEN há erro na resposta THEN o sistema SHALL mostrar mensagem de erro e manter estado anterior

### Requirement 4: Integração com Sistema Existente

**User Story:** Como usuário, eu quero que o sistema de interesse se integre perfeitamente com a interface existente, para que eu tenha uma experiência consistente.

#### Acceptance Criteria

1. WHEN o usuário clica "Tenho Interesse" em qualquer perfil THEN o sistema SHALL usar a mesma função de criar notificação
2. WHEN as notificações aparecem THEN elas SHALL usar o mesmo design visual dos convites do Nosso Propósito
3. WHEN há notificações THEN elas SHALL aparecer na mesma área dos convites (se houver)
4. WHEN o usuário navega THEN o contador de notificações SHALL ser atualizado em tempo real
5. WHEN há match mútuo THEN o sistema SHALL notificar ambos usuários

### Requirement 5: Persistência e Tempo Real

**User Story:** Como usuário, eu quero que as notificações sejam salvas e sincronizadas em tempo real, para que eu não perca nenhuma notificação.

#### Acceptance Criteria

1. WHEN uma notificação é criada THEN ela SHALL ser salva na coleção 'interest_notifications' do Firebase
2. WHEN o usuário abre o app THEN ele SHALL receber todas as notificações pendentes via stream
3. WHEN há mudanças nas notificações THEN a interface SHALL atualizar automaticamente
4. WHEN o usuário está offline THEN as notificações SHALL ser sincronizadas quando voltar online
5. WHEN há erro de rede THEN o sistema SHALL tentar novamente automaticamente

### Requirement 6: Validações e Segurança

**User Story:** Como sistema, eu quero validar todas as operações de interesse, para que apenas interações válidas sejam processadas.

#### Acceptance Criteria

1. WHEN um interesse é demonstrado THEN o sistema SHALL verificar se o usuário destinatário existe
2. WHEN um interesse é demonstrado THEN o sistema SHALL verificar se não há interesse pendente duplicado
3. WHEN uma resposta é dada THEN o sistema SHALL verificar se a notificação ainda está pendente
4. WHEN há operação inválida THEN o sistema SHALL mostrar erro específico
5. WHEN há tentativa de spam THEN o sistema SHALL limitar a frequência de interesses