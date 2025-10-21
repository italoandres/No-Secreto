# Requirements Document

## Introduction

O sistema atual tem um problema crítico onde o sexo do usuário não é validado corretamente pelo email no Firestore. Quando um usuário faz login, o sistema sobrescreve o sexo correto que está salvo no Firestore com o valor incorreto do SharedPreferences local, causando inconsistências na experiência do usuário (usuários femininos veem conteúdo masculino e vice-versa).

## Requirements

### Requirement 1

**User Story:** Como um usuário que já tem uma conta cadastrada, eu quero que meu sexo seja validado corretamente pelo que está salvo no Firestore baseado no meu email, para que eu veja o conteúdo apropriado para meu sexo.

#### Acceptance Criteria

1. WHEN um usuário faz login THEN o sistema SHALL buscar o sexo correto no Firestore baseado no email
2. WHEN o sexo do Firestore for diferente do SharedPreferences THEN o sistema SHALL atualizar o SharedPreferences com o valor correto do Firestore
3. WHEN o login for concluído THEN o usuário SHALL ver o conteúdo apropriado para seu sexo (botões corretos no chat principal)

### Requirement 2

**User Story:** Como um usuário novo fazendo primeiro cadastro, eu quero que meu sexo seja salvo corretamente no Firestore durante o onboarding, para que nas próximas vezes que eu fizer login o sistema lembre corretamente do meu sexo.

#### Acceptance Criteria

1. WHEN um usuário novo seleciona seu sexo no onboarding THEN o sistema SHALL salvar o sexo no Firestore
2. WHEN o usuário novo completa o cadastro THEN o sistema SHALL sincronizar o sexo entre SharedPreferences e Firestore
3. WHEN o usuário novo faz login pela primeira vez THEN o sistema SHALL manter a consistência entre as duas fontes de dados

### Requirement 3

**User Story:** Como desenvolvedor, eu quero que o sistema tenha uma fonte única de verdade para o sexo do usuário, para que não haja inconsistências entre diferentes partes do sistema.

#### Acceptance Criteria

1. WHEN há conflito entre SharedPreferences e Firestore THEN o Firestore SHALL ser considerado a fonte de verdade
2. WHEN o sistema detecta inconsistência THEN o sistema SHALL corrigir automaticamente o SharedPreferences
3. WHEN o usuário faz logout e login novamente THEN o sexo SHALL permanecer consistente baseado no Firestore

### Requirement 4

**User Story:** Como um usuário existente com dados inconsistentes, eu quero que o sistema corrija automaticamente meu sexo na próxima vez que eu fizer login, para que eu não precise reconfigurar manualmente.

#### Acceptance Criteria

1. WHEN um usuário com dados inconsistentes faz login THEN o sistema SHALL detectar a inconsistência automaticamente
2. WHEN a inconsistência for detectada THEN o sistema SHALL corrigir o SharedPreferences com o valor do Firestore
3. WHEN a correção for aplicada THEN o usuário SHALL ver imediatamente o conteúdo correto sem precisar fazer logout/login novamente