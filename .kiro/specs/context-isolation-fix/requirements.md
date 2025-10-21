# Requirements Document

## Introduction

O sistema de stories precisa garantir isolamento completo entre contextos diferentes. Atualmente há vazamento de dados entre contextos, onde stories do Chat Principal aparecem em outros contextos como Sinais Rebeca, causando confusão na experiência do usuário e violando a separação lógica dos contextos.

## Requirements

### Requirement 1

**User Story:** Como usuário, eu quero que os stories do Chat Principal apareçam apenas no Chat Principal, para que não haja confusão entre diferentes contextos.

#### Acceptance Criteria

1. WHEN o usuário acessa a view Sinais Rebeca THEN o sistema SHALL mostrar apenas stories com contexto "sinais_rebeca"
2. WHEN o usuário acessa a view Chat Principal THEN o sistema SHALL mostrar apenas stories com contexto "principal"
3. WHEN o usuário acessa favoritos do Sinais Rebeca THEN o sistema SHALL mostrar apenas favoritos salvos no contexto "sinais_rebeca"

### Requirement 2

**User Story:** Como usuário, eu quero que cada contexto mantenha seus próprios favoritos separadamente, para que eu possa organizar meus conteúdos por categoria.

#### Acceptance Criteria

1. WHEN o usuário salva um story como favorito no contexto Sinais Rebeca THEN o sistema SHALL armazenar com contexto "sinais_rebeca"
2. WHEN o usuário acessa favoritos do Chat Principal THEN o sistema SHALL mostrar apenas favoritos com contexto "principal"
3. WHEN o usuário acessa favoritos do Sinais Rebeca THEN o sistema SHALL mostrar apenas favoritos com contexto "sinais_rebeca"

### Requirement 3

**User Story:** Como desenvolvedor, eu quero que as consultas ao banco sejam filtradas por contexto, para garantir isolamento de dados entre diferentes seções do app.

#### Acceptance Criteria

1. WHEN o sistema carrega stories para um contexto específico THEN o sistema SHALL aplicar filtro WHERE contexto = contexto_atual
2. WHEN o sistema carrega favoritos para um contexto específico THEN o sistema SHALL aplicar filtro WHERE contexto = contexto_atual
3. IF uma consulta não especifica contexto THEN o sistema SHALL usar contexto "principal" como padrão

### Requirement 4

**User Story:** Como usuário, eu quero que os círculos de notificação (verde/azul) sejam calculados corretamente para cada contexto, para saber quando há conteúdo novo em cada seção.

#### Acceptance Criteria

1. WHEN há stories não vistos no Chat Principal THEN o sistema SHALL mostrar círculo verde apenas no Chat Principal
2. WHEN há stories não vistos no Sinais Rebeca THEN o sistema SHALL mostrar círculo azul apenas no Sinais Rebeca
3. WHEN o usuário vê todos os stories de um contexto THEN o sistema SHALL remover o círculo apenas daquele contexto