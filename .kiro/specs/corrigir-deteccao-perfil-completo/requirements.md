# Requirements Document

## Introduction

O sistema de detecção de perfil completo está falhando ao identificar perfis que estão 100% completos. O problema ocorre porque o `ProfileCompletionDetector` verifica primeiro o campo `isProfileComplete` no Firestore, e se ele estiver `false`, retorna imediatamente sem verificar as outras condições (tarefas completas, progresso 100%, etc.). Isso cria uma dependência circular onde o perfil nunca é marcado como completo porque a detecção falha antes de validar os dados reais.

## Glossary

- **ProfileCompletionDetector**: Serviço responsável por detectar quando um perfil espiritual está completo
- **SpiritualProfileModel**: Modelo de dados do perfil espiritual do usuário
- **isProfileComplete**: Campo booleano no Firestore que indica se o perfil está completo
- **completionTasks**: Mapa de tarefas obrigatórias (photos, identity, biography, preferences)
- **completionPercentage**: Percentual de completude do perfil (0.0 a 1.0)
- **VitrineConfirmationView**: Tela de confirmação mostrada quando o perfil é completado

## Requirements

### Requirement 1

**User Story:** Como usuário que completa todas as tarefas do perfil, eu quero que o sistema detecte automaticamente a completude e mostre a tela de confirmação, para que eu possa visualizar minha vitrine de propósito.

#### Acceptance Criteria

1. WHEN o usuário completa a última tarefa obrigatória do perfil, THE ProfileCompletionDetector SHALL verificar as condições reais de completude antes de verificar o campo isProfileComplete
2. WHEN todas as tarefas obrigatórias estão completas E o completionPercentage é 100%, THE ProfileCompletionDetector SHALL retornar true independentemente do valor de isProfileComplete
3. IF o ProfileCompletionDetector detecta que o perfil está completo mas isProfileComplete é false, THEN THE Sistema SHALL atualizar automaticamente o campo isProfileComplete para true no Firestore
4. WHEN o perfil é detectado como completo pela primeira vez, THE Sistema SHALL mostrar a VitrineConfirmationView ao usuário
5. THE ProfileCompletionDetector SHALL validar a completude baseado em: mainPhotoUrl preenchida, hasBasicInfo true, hasBiography true, todas as tarefas obrigatórias true, e completionPercentage >= 1.0

### Requirement 2

**User Story:** Como desenvolvedor, eu quero que a lógica de detecção seja robusta e não dependa de um único campo, para que inconsistências de dados não impeçam a detecção correta.

#### Acceptance Criteria

1. THE ProfileCompletionDetector SHALL priorizar a validação de dados reais sobre o campo isProfileComplete
2. WHEN há inconsistência entre isProfileComplete e os dados reais, THE Sistema SHALL corrigir automaticamente o campo isProfileComplete
3. THE ProfileCompletionDetector SHALL registrar logs detalhados quando detectar e corrigir inconsistências
4. THE Sistema SHALL garantir que a correção automática não cause loops infinitos ou múltiplas atualizações
5. WHEN a correção automática é executada, THE Sistema SHALL invalidar o cache do ProfileCompletionDetector para forçar nova verificação

### Requirement 3

**User Story:** Como usuário, eu quero que a tela de confirmação apareça imediatamente após completar o perfil, para que eu tenha feedback instantâneo do meu progresso.

#### Acceptance Criteria

1. WHEN o perfil é detectado como completo, THE Sistema SHALL mostrar a VitrineConfirmationView dentro de 1 segundo
2. THE Sistema SHALL garantir que a VitrineConfirmationView seja mostrada apenas uma vez por sessão
3. WHEN a VitrineConfirmationView é mostrada, THE Sistema SHALL marcar hasBeenShown como true no Firestore
4. THE Sistema SHALL verificar hasBeenShown antes de mostrar a confirmação para evitar exibições duplicadas
5. WHEN o usuário fecha a VitrineConfirmationView, THE Sistema SHALL navegar para a tela de visualização da vitrine
