# Requirements Document

## Introduction

Este documento define os requisitos para sincronizar todas as informações cadastradas no ProfileCompletionView para aparecerem no perfil público da vitrine (EnhancedVitrineDisplayView). Atualmente, muitos campos são cadastrados mas não são exibidos na vitrine pública.

## Glossary

- **ProfileCompletionView**: Tela onde o usuário completa seu perfil espiritual
- **EnhancedVitrineDisplayView**: Tela de visualização pública do perfil (vitrine)
- **SpiritualProfileModel**: Modelo de dados que armazena todas as informações do perfil
- **Firestore**: Banco de dados onde os perfis são armazenados
- **Campos Obrigatórios**: Campos necessários para completar o perfil (photos, identity, biography, preferences)
- **Campos Opcionais**: Campos que enriquecem o perfil mas não são obrigatórios (certification, aboutMe, hobbies, etc.)

## Requirements

### Requirement 1

**User Story:** Como usuário que completou meu perfil, eu quero que todas as informações que cadastrei apareçam na minha vitrine pública, para que outros usuários possam me conhecer melhor.

#### Acceptance Criteria

1. WHEN o usuário visualiza sua vitrine pública, THE EnhancedVitrineDisplayView SHALL exibir todos os campos preenchidos do perfil
2. WHEN o usuário cadastra informações adicionais (altura, profissão, educação, hobbies), THE EnhancedVitrineDisplayView SHALL exibir essas informações em seções apropriadas
3. WHEN o usuário atualiza qualquer campo no ProfileCompletionView, THE EnhancedVitrineDisplayView SHALL refletir as mudanças imediatamente após recarregar
4. WHEN um campo opcional não foi preenchido, THE EnhancedVitrineDisplayView SHALL ocultar a seção correspondente ou mostrar mensagem apropriada
5. THE EnhancedVitrineDisplayView SHALL organizar as informações em seções lógicas e visualmente atraentes

### Requirement 2

**User Story:** Como usuário visitando o perfil de outro usuário, eu quero ver informações detalhadas sobre a pessoa, para que eu possa decidir se tenho interesse em conhecê-la melhor.

#### Acceptance Criteria

1. WHEN um visitante acessa a vitrine de outro usuário, THE EnhancedVitrineDisplayView SHALL exibir todas as informações públicas do perfil
2. WHEN o perfil contém informações sobre educação, THE EnhancedVitrineDisplayView SHALL exibir curso, universidade e status de formação
3. WHEN o perfil contém informações sobre estilo de vida, THE EnhancedVitrineDisplayView SHALL exibir altura, fumante, bebida e hobbies
4. WHEN o perfil contém idiomas, THE EnhancedVitrineDisplayView SHALL exibir a lista de idiomas falados
5. WHEN o perfil contém informação sobre virgindade, THE EnhancedVitrineDisplayView SHALL exibir essa informação na seção de relacionamento

### Requirement 3

**User Story:** Como desenvolvedor, eu quero que os componentes da vitrine sejam reutilizáveis e organizados, para que seja fácil adicionar novos campos no futuro.

#### Acceptance Criteria

1. THE sistema SHALL criar componentes separados para cada seção de informações (educação, estilo de vida, hobbies)
2. WHEN um novo campo é adicionado ao SpiritualProfileModel, THE sistema SHALL permitir adicionar o campo à vitrine sem modificar código existente
3. THE sistema SHALL usar componentes existentes (BasicInfoSection, SpiritualInfoSection) como referência
4. THE sistema SHALL manter consistência visual entre todas as seções
5. THE sistema SHALL garantir que todos os componentes sejam responsivos e acessíveis

### Requirement 4

**User Story:** Como usuário, eu quero que minha galeria de fotos (principal + 2 secundárias) seja exibida de forma atraente na vitrine, para que eu possa mostrar diferentes aspectos da minha vida.

#### Acceptance Criteria

1. WHEN o usuário tem foto principal, THE EnhancedVitrineDisplayView SHALL exibir a foto principal no header
2. WHEN o usuário tem fotos secundárias, THE EnhancedVitrineDisplayView SHALL exibir uma galeria com todas as fotos
3. WHEN o usuário clica em uma foto da galeria, THE sistema SHALL abrir a foto em tela cheia
4. WHEN o usuário não tem fotos secundárias, THE EnhancedVitrineDisplayView SHALL ocultar a seção de galeria
5. THE galeria SHALL exibir as fotos em um layout grid responsivo

### Requirement 5

**User Story:** Como usuário, eu quero que as informações sejam organizadas de forma lógica e fácil de ler, para que visitantes possam entender rapidamente quem eu sou.

#### Acceptance Criteria

1. THE EnhancedVitrineDisplayView SHALL organizar informações em ordem de importância: Header → Básico → Espiritual → Educação → Estilo de Vida → Família
2. WHEN uma seção não tem informações, THE EnhancedVitrineDisplayView SHALL ocultar a seção completamente
3. THE EnhancedVitrineDisplayView SHALL usar ícones apropriados para cada tipo de informação
4. THE EnhancedVitrineDisplayView SHALL usar cores consistentes com o tema do app
5. THE EnhancedVitrineDisplayView SHALL garantir espaçamento adequado entre seções para facilitar leitura

## Campos a Serem Sincronizados

### Campos Já Exibidos ✅
- mainPhotoUrl (foto principal)
- displayName (nome)
- username (@usuario)
- city (cidade)
- age (idade)
- purpose (propósito)
- faithPhrase (frase de fé)
- isDeusEPaiMember (membro Deus é Pai)
- relationshipStatus (status de relacionamento)
- hasChildren (tem filhos)
- childrenDetails (detalhes dos filhos)
- wasPreviouslyMarried (já foi casado)
- readyForPurposefulRelationship (pronto para relacionamento com propósito)
- nonNegotiableValue (valor inegociável)
- aboutMe (sobre mim)

### Campos a Adicionar 🆕
- **Fotos**: secondaryPhoto1Url, secondaryPhoto2Url
- **Localização**: fullLocation, state, country
- **Idiomas**: languages (lista)
- **Física**: height (altura)
- **Profissional**: occupation (profissão)
- **Educação**: education, universityCourse, courseStatus, university
- **Estilo de Vida**: smokingStatus, drinkingStatus
- **Interesses**: hobbies (lista)
- **Intimidade**: isVirgin (virgem ou não) - **PÚBLICO**

### Campos Privados (Não Exibir) 🔒
- blockedUsers (interno)
- allowInteractions (interno)
- completionTasks (interno)
- isProfileComplete (interno)

## Notas Técnicas

- Todos os campos já existem no `SpiritualProfileModel`
- Os dados já são salvos no Firestore
- Apenas a exibição na vitrine precisa ser implementada
- Componentes devem seguir o padrão dos existentes (BasicInfoSection, SpiritualInfoSection)
- Usar ícones do Material Design
- Manter consistência com o tema AppColors
