# Requirements Document: Explore Profiles - Sistema de Localização

## Introduction
Revolucionar a tela Explore Profiles com um sistema inteligente de localização que permite aos usuários encontrar matches baseados em suas preferências geográficas, utilizando dados já cadastrados no perfil da vitrine.

## Glossary
- **Sistema**: Aplicativo "No Secreto com o Pai"
- **Usuário**: Pessoa autenticada usando o aplicativo
- **Perfil Vitrine**: Perfil espiritual completo do usuário (SpiritualProfileModel)
- **Localização Principal**: Cidade/estado onde o usuário mora (já cadastrado no perfil)
- **Localizações Adicionais**: Até 2 localizações extras de interesse para matches
- **Explore Profiles**: Tela de descoberta de perfis compatíveis

## Requirements

### Requirement 1: Título e Mensagem Motivacional

**User Story:** Como usuário, quero ver uma mensagem inspiradora no topo da tela Explore Profiles, para me sentir motivado a encontrar conexões significativas.

#### Acceptance Criteria

1. WHEN o usuário acessa Explore Profiles THEN o Sistema SHALL exibir o título "Espero esses Sinais..." no topo da tela
2. WHEN o título é exibido THEN o Sistema SHALL mostrar a mensagem "Levaremos seus sinais em consideração, mas mostraremos as opções mais adequadas entre as disponíveis para você" abaixo do título
3. THE Sistema SHALL usar tipografia elegante e moderna para o título e mensagem
4. THE Sistema SHALL posicionar o título e mensagem acima dos filtros de busca

### Requirement 2: Localização Principal Automática

**User Story:** Como usuário, quero que minha localização principal seja automaticamente preenchida com os dados do meu perfil, para não precisar digitar novamente.

#### Acceptance Criteria

1. WHEN o usuário acessa os filtros de localização THEN o Sistema SHALL buscar a localização do perfil vitrine do usuário
2. WHEN a localização do perfil existe THEN o Sistema SHALL exibir cidade e estado como "Localização Principal"
3. THE Sistema SHALL usar os campos `city` e `state` do SpiritualProfileModel
4. WHEN a localização principal é exibida THEN o Sistema SHALL mostrar um ícone de casa (home) ao lado
5. THE Sistema SHALL marcar a localização principal como não editável diretamente nos filtros

### Requirement 3: Adicionar Localizações Adicionais

**User Story:** Como usuário, quero adicionar até 2 localizações adicionais de interesse, para encontrar matches em outras cidades que me interessam.

#### Acceptance Criteria

1. WHEN o usuário clica em "Adicionar Localização" THEN o Sistema SHALL abrir um seletor de localização
2. WHEN o usuário tem menos de 2 localizações adicionais THEN o Sistema SHALL permitir adicionar nova localização
3. WHEN o usuário já tem 2 localizações adicionais THEN o Sistema SHALL desabilitar o botão "Adicionar Localização"
4. THE Sistema SHALL exibir contador "X de 2 localizações adicionadas"
5. WHEN uma localização é adicionada THEN o Sistema SHALL salvar no perfil do usuário com timestamp

### Requirement 4: Restrições de Edição Mensal

**User Story:** Como usuário, quero entender as restrições de edição das localizações, para planejar minhas escolhas com cuidado.

#### Acceptance Criteria

1. WHEN o usuário visualiza localizações adicionais THEN o Sistema SHALL exibir tooltip "Você pode editar suas localizações uma vez por mês"
2. WHEN o usuário editou uma localização há menos de 30 dias THEN o Sistema SHALL desabilitar a edição
3. WHEN a edição está desabilitada THEN o Sistema SHALL mostrar mensagem "Próxima edição disponível em X dias"
4. WHEN o usuário pode editar THEN o Sistema SHALL mostrar ícone de edição ativo
5. THE Sistema SHALL calcular o período de 30 dias desde a última edição

### Requirement 5: Remover Localizações

**User Story:** Como usuário, quero poder remover localizações adicionais a qualquer momento, para ajustar minhas preferências.

#### Acceptance Criteria

1. WHEN o usuário clica em remover localização THEN o Sistema SHALL mostrar confirmação "Tem certeza?"
2. WHEN o usuário confirma remoção THEN o Sistema SHALL remover a localização imediatamente
3. WHEN uma localização é removida THEN o Sistema SHALL permitir adicionar nova após 30 dias
4. THE Sistema SHALL salvar timestamp da remoção
5. WHEN o usuário remove localização THEN o Sistema SHALL atualizar contador de localizações

### Requirement 6: Interface Elegante e Moderna

**User Story:** Como usuário, quero uma interface visualmente atraente e intuitiva, para ter uma experiência agradável ao configurar minhas preferências.

#### Acceptance Criteria

1. THE Sistema SHALL usar cards com sombras suaves para cada localização
2. THE Sistema SHALL usar ícones intuitivos (casa, pin de localização, editar, remover)
3. THE Sistema SHALL usar cores consistentes com o tema do app (roxo/azul)
4. WHEN o usuário interage com elementos THEN o Sistema SHALL fornecer feedback visual (animações sutis)
5. THE Sistema SHALL usar espaçamento adequado entre elementos (16-24px)

### Requirement 7: Persistência de Dados

**User Story:** Como usuário, quero que minhas preferências de localização sejam salvas permanentemente, para não precisar configurar novamente.

#### Acceptance Criteria

1. WHEN o usuário adiciona localização THEN o Sistema SHALL salvar no Firestore imediatamente
2. WHEN o usuário remove localização THEN o Sistema SHALL atualizar Firestore imediatamente
3. THE Sistema SHALL armazenar localizações em array no SpiritualProfileModel
4. THE Sistema SHALL armazenar timestamps de última edição para cada localização
5. WHEN o app é reaberto THEN o Sistema SHALL carregar localizações salvas automaticamente

### Requirement 8: Validação e Feedback

**User Story:** Como usuário, quero receber feedback claro sobre minhas ações, para entender o que está acontecendo.

#### Acceptance Criteria

1. WHEN o usuário adiciona localização THEN o Sistema SHALL mostrar snackbar "Localização adicionada com sucesso"
2. WHEN o usuário remove localização THEN o Sistema SHALL mostrar snackbar "Localização removida"
3. WHEN o usuário tenta adicionar mais de 2 localizações THEN o Sistema SHALL mostrar mensagem "Limite de 2 localizações atingido"
4. WHEN ocorre erro THEN o Sistema SHALL mostrar mensagem de erro clara
5. THE Sistema SHALL usar cores apropriadas (verde para sucesso, vermelho para erro)

### Requirement 9: Integração com Busca

**User Story:** Como usuário, quero que os resultados de busca considerem minhas localizações configuradas, para ver perfis relevantes.

#### Acceptance Criteria

1. WHEN o usuário tem localizações configuradas THEN o Sistema SHALL filtrar perfis por essas localizações
2. WHEN o usuário busca perfis THEN o Sistema SHALL priorizar localização principal
3. WHEN existem localizações adicionais THEN o Sistema SHALL incluir perfis dessas localizações
4. THE Sistema SHALL ordenar resultados por proximidade da localização principal
5. WHEN não há perfis nas localizações THEN o Sistema SHALL mostrar mensagem apropriada
