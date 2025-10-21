# Requirements Document

## Introduction

Este documento define os requisitos para expandir o sistema de localização mundial, adicionando estados/províncias e cidades pré-selecionadas para os principais países do mundo, seguindo o mesmo padrão já implementado para o Brasil.

Atualmente, apenas o Brasil possui dados estruturados de estados e cidades. Usuários de outros países precisam digitar manualmente suas cidades. Esta funcionalidade visa melhorar a experiência do usuário oferecendo dropdowns com opções pré-definidas para os principais países.

## Requirements

### Requirement 1: Estrutura de Dados para Países Prioritários

**User Story:** Como desenvolvedor, quero ter uma estrutura de dados organizada com estados/províncias e cidades dos principais países, para que usuários desses países tenham a mesma experiência que usuários brasileiros.

#### Acceptance Criteria

1. WHEN o sistema é inicializado THEN deve existir um arquivo de dados contendo estados/províncias e cidades para os seguintes países prioritários:
   - Estados Unidos (50 estados + principais cidades)
   - Portugal (18 distritos + principais cidades)
   - Canadá (10 províncias + 3 territórios + principais cidades)
   - Argentina (23 províncias + principais cidades)
   - México (32 estados + principais cidades)
   - Espanha (17 comunidades autônomas + principais cidades)
   - França (13 regiões + principais cidades)
   - Itália (20 regiões + principais cidades)
   - Alemanha (16 estados + principais cidades)
   - Reino Unido (4 países constituintes + principais cidades)

2. WHEN os dados são estruturados THEN cada país deve ter:
   - Lista de estados/províncias/regiões
   - Mapa de cidades por estado/província/região
   - Nomenclatura apropriada (estado, província, região, distrito, etc.)

3. WHEN os dados são acessados THEN deve haver métodos helper para:
   - Obter lista de estados/províncias de um país
   - Obter lista de cidades de um estado/província
   - Verificar se um país tem dados estruturados disponíveis

### Requirement 2: Lógica Condicional Multi-País

**User Story:** Como usuário de qualquer país com dados estruturados, quero selecionar meu estado/província e cidade de dropdowns, para que eu tenha uma experiência consistente e fácil de usar.

#### Acceptance Criteria

1. WHEN o usuário seleciona um país com dados estruturados THEN o sistema deve exibir:
   - Dropdown de estados/províncias/regiões (com nomenclatura apropriada)
   - Dropdown de cidades (baseado no estado/província selecionado)

2. WHEN o usuário seleciona um país sem dados estruturados THEN o sistema deve exibir:
   - Campo de texto livre para digitar a cidade
   - Sem dropdown de estados/províncias

3. WHEN o usuário muda de país THEN o sistema deve:
   - Resetar os campos de estado/província e cidade
   - Atualizar a interface para mostrar os campos apropriados

4. WHEN o usuário seleciona um estado/província THEN o sistema deve:
   - Carregar as cidades correspondentes no dropdown
   - Resetar a seleção de cidade anterior

### Requirement 3: Nomenclatura Localizada

**User Story:** Como usuário, quero ver os termos corretos para divisões administrativas do meu país (estado, província, distrito, etc.), para que a interface seja clara e familiar.

#### Acceptance Criteria

1. WHEN o sistema exibe campos de localização THEN deve usar a nomenclatura correta:
   - Brasil: "Estado"
   - Estados Unidos: "Estado"
   - Canadá: "Província/Território"
   - Portugal: "Distrito"
   - Argentina: "Província"
   - México: "Estado"
   - Espanha: "Comunidade Autônoma"
   - França: "Região"
   - Itália: "Região"
   - Alemanha: "Estado"
   - Reino Unido: "País"

2. WHEN o sistema salva a localização THEN deve usar o formato apropriado:
   - Países com estados: "Cidade - Sigla do Estado"
   - Países sem siglas: "Cidade, Estado/Província"
   - Países sem dados estruturados: "Cidade, País"

### Requirement 4: Validação e Formato de Salvamento

**User Story:** Como desenvolvedor, quero que os dados de localização sejam salvos de forma consistente e validada, para que possamos fazer buscas e filtros eficientes no futuro.

#### Acceptance Criteria

1. WHEN o usuário preenche a localização THEN o sistema deve validar:
   - País é obrigatório
   - Estado/província é obrigatório (se o país tiver dados estruturados)
   - Cidade é obrigatória (dropdown ou texto livre)

2. WHEN os dados são salvos no Firebase THEN deve incluir:
   - `country`: Nome do país
   - `state`: Nome do estado/província (ou null)
   - `city`: Nome da cidade
   - `fullLocation`: String formatada para exibição
   - `hasStructuredData`: Boolean indicando se usou dados estruturados

3. WHEN o formato de localização é gerado THEN deve seguir:
   - Com dados estruturados: "Cidade - Estado" ou "Cidade, Estado"
   - Sem dados estruturados: "Cidade, País"

### Requirement 5: Performance e Escalabilidade

**User Story:** Como desenvolvedor, quero que o sistema de localização seja performático mesmo com grandes volumes de dados, para que a experiência do usuário seja fluida.

#### Acceptance Criteria

1. WHEN os dados de localização são carregados THEN deve:
   - Carregar apenas os dados do país selecionado
   - Usar lazy loading para cidades
   - Não impactar o tempo de carregamento inicial da tela

2. WHEN o usuário interage com dropdowns THEN deve:
   - Responder instantaneamente (< 100ms)
   - Suportar busca/filtro nos dropdowns (opcional)
   - Manter o estado durante navegação

3. WHEN novos países são adicionados THEN deve:
   - Ser fácil adicionar novos arquivos de dados
   - Não requerer mudanças na lógica principal
   - Seguir o mesmo padrão de estrutura

### Requirement 6: Fallback e Compatibilidade

**User Story:** Como usuário de um país sem dados estruturados, quero ainda poder cadastrar minha localização livremente, para que eu não seja impedido de usar o aplicativo.

#### Acceptance Criteria

1. WHEN um país não tem dados estruturados THEN o sistema deve:
   - Exibir campo de texto livre para cidade
   - Não exibir dropdown de estados/províncias
   - Validar que a cidade foi preenchida

2. WHEN dados antigos são migrados THEN o sistema deve:
   - Manter compatibilidade com formato anterior
   - Não quebrar perfis existentes
   - Permitir atualização gradual

3. WHEN há erro ao carregar dados THEN o sistema deve:
   - Fazer fallback para campo de texto livre
   - Exibir mensagem amigável ao usuário
   - Logar o erro para debugging

### Requirement 7: Expansão Futura

**User Story:** Como desenvolvedor, quero que o sistema seja facilmente expansível, para que possamos adicionar mais países no futuro sem refatoração.

#### Acceptance Criteria

1. WHEN a arquitetura é implementada THEN deve:
   - Usar padrão de factory/strategy para carregar dados
   - Ter interface clara para adicionar novos países
   - Documentar o processo de adição de novos países

2. WHEN novos países são priorizados THEN deve ser possível:
   - Adicionar arquivo de dados seguindo template
   - Registrar o país na lista de países com dados estruturados
   - Testar isoladamente sem afetar países existentes

3. WHEN a comunidade contribui THEN deve:
   - Ter documentação clara de como contribuir
   - Validar formato dos dados automaticamente
   - Manter qualidade e consistência
