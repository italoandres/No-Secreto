# Requirements Document

## Introduction

O sistema precisa de um sistema completo de perfis espirituais que funcione como uma "vitrine de propósito" para os usuários. Este sistema deve promover conexões autênticas baseadas em valores espirituais, sem estimular carência afetiva ou dependência emocional. O perfil deve ser acessível quando outros usuários clicarem no username, mas apenas após a conclusão completa do cadastro através de um processo dinâmico e moderno de tarefas.

## Requirements

### Requirement 1

**User Story:** Como um usuário do app, eu quero completar meu perfil através de um processo dinâmico de tarefas, para que eu possa ter uma "vitrine de propósito" completa que represente minha identidade espiritual.

#### Acceptance Criteria

1. WHEN um usuário acessa "Detalhes do Perfil" THEN o sistema SHALL mostrar uma interface de conclusão de tarefas dinâmica e moderna
2. WHEN o usuário completa uma tarefa THEN o sistema SHALL atualizar visualmente o progresso de conclusão
3. WHEN todas as tarefas forem concluídas THEN o sistema SHALL ativar a página de apresentação do perfil
4. WHEN o perfil estiver incompleto THEN outros usuários SHALL ver uma mensagem de "Perfil em construção"

### Requirement 2

**User Story:** Como um usuário, eu quero adicionar até 3 fotos ao meu perfil (1 principal obrigatória + 2 secundárias opcionais), para que eu possa me apresentar de forma autêntica e com propósito.

#### Acceptance Criteria

1. WHEN o usuário adiciona a foto principal THEN o sistema SHALL validar que é uma foto apropriada
2. WHEN o usuário adiciona fotos secundárias THEN o sistema SHALL permitir até 2 fotos adicionais
3. WHEN as fotos são salvas THEN o sistema SHALL armazená-las no Firebase Storage
4. WHEN as fotos são exibidas THEN o sistema SHALL mostrar orientação sobre manter "olhar com propósito, não sensualidade"

### Requirement 3

**User Story:** Como um usuário, eu quero preencher minha identidade espiritual com informações básicas, para que outros usuários possam conhecer minha localização e faixa etária.

#### Acceptance Criteria

1. WHEN o usuário preenche identidade THEN o sistema SHALL capturar nome/@ (já existente), cidade/estado e idade
2. WHEN a cidade for preenchida THEN o sistema SHALL validar formato "Cidade - Estado"
3. WHEN a idade for preenchida THEN o sistema SHALL validar que é um número válido
4. WHEN os dados forem salvos THEN o sistema SHALL armazenar no Firestore

### Requirement 4

**User Story:** Como um usuário, eu quero responder perguntas específicas sobre minha fé e propósito, para que minha biografia reflita meus valores espirituais de forma estruturada.

#### Acceptance Criteria

1. WHEN o usuário acessa biografia THEN o sistema SHALL apresentar 7 perguntas específicas
2. WHEN o usuário responde "Qual é o seu propósito?" THEN o sistema SHALL limitar a 300 caracteres
3. WHEN o usuário responde perguntas de múltipla escolha THEN o sistema SHALL validar as opções disponíveis
4. WHEN todas as respostas obrigatórias forem preenchidas THEN o sistema SHALL marcar a tarefa como concluída

### Requirement 5

**User Story:** Como um usuário solteiro, eu quero demonstrar interesse em outros perfis através de um sistema seguro, para que possamos estabelecer conexões baseadas em interesse mútuo.

#### Acceptance Criteria

1. WHEN um usuário solteiro visita outro perfil solteiro THEN o sistema SHALL mostrar botão "Tenho Interesse"
2. WHEN ambos usuários clicarem em "Tenho Interesse" THEN o sistema SHALL liberar botão "Conhecer Melhor"
3. WHEN "Conhecer Melhor" for clicado THEN o sistema SHALL abrir chat temporário de 7 dias
4. WHEN o chat temporário expirar THEN o sistema SHALL oferecer opção de continuar no "Nosso Propósito"

### Requirement 6

**User Story:** Como um usuário que completou o curso oficial, eu quero exibir o selo "Preparado(a) para os Sinais", para que outros usuários saibam que estou alinhado com os ensinamentos.

#### Acceptance Criteria

1. WHEN um usuário completa o curso oficial THEN o sistema SHALL disponibilizar opção de selo
2. WHEN o selo for ativado THEN o sistema SHALL exibir "Preparado(a) para os Sinais Confirmado" no perfil
3. WHEN outros usuários visualizam o perfil THEN o sistema SHALL destacar visualmente o selo
4. WHEN usuários filtram perfis THEN o sistema SHALL permitir busca por usuários com selo

### Requirement 7

**User Story:** Como visitante de um perfil, eu quero ver uma apresentação completa e organizada do usuário, para que eu possa conhecer sua identidade espiritual de forma clara.

#### Acceptance Criteria

1. WHEN um usuário clica em um username THEN o sistema SHALL abrir a página de perfil completa
2. WHEN o perfil for exibido THEN o sistema SHALL mostrar todas as seções organizadas: fotos, identidade, biografia, interações
3. WHEN o perfil for visitado THEN o sistema SHALL exibir aviso fixo sobre "terreno sagrado"
4. WHEN o perfil estiver incompleto THEN o sistema SHALL mostrar "Perfil em construção"

### Requirement 8

**User Story:** Como administrador do sistema, eu quero garantir que todas as interações mantenham o caráter espiritual e seguro do app, para que as conexões honrem os valores cristãos.

#### Acceptance Criteria

1. WHEN qualquer perfil for visitado THEN o sistema SHALL exibir aviso "Este app é um terreno sagrado. Conexões aqui devem honrar Deus."
2. WHEN conteúdo inapropriado for detectado THEN o sistema SHALL ter mecanismos de moderação
3. WHEN usuários interagem THEN o sistema SHALL manter logs para auditoria
4. WHEN problemas forem reportados THEN o sistema SHALL permitir moderação administrativa