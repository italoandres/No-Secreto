# Requirements Document - Melhorias no Sistema de Chat de Matches

## Introduction

Este documento define os requisitos para melhorar o sistema de chat de matches mútuos, incluindo reorganização da navegação, correção do alinhamento de mensagens e implementação de indicadores de leitura.

## Requirements

### Requirement 1: Reorganização da Navegação de Matches

**User Story:** Como usuário, quero acessar meus matches aceitos através de Comunidade > Vitrine de Propósito, para ter uma navegação mais organizada e intuitiva.

#### Acceptance Criteria

1. WHEN o usuário acessa a página principal THEN o ícone de matches aceitos NÃO deve aparecer ao lado de "Comunidade"
2. WHEN o usuário navega para Comunidade > Vitrine de Propósito THEN deve ver o ícone de matches aceitos junto com "Gerencie seus matches", "Explorar perfis" e "Configure sua vitrine de propósito"
3. WHEN o usuário clica em "Gerencie seus matches" THEN deve ver a página com notificações de interesse e cards de "MATCH MÚTUO!"
4. WHEN o usuário clica em "Conversar" em um card de match mútuo THEN deve abrir a página de chat romântico

### Requirement 2: Correção do Alinhamento de Mensagens

**User Story:** Como usuário, quero que minhas mensagens apareçam do lado direito e as mensagens do outro usuário do lado esquerdo, para ter uma experiência de chat clara e intuitiva.

#### Acceptance Criteria

1. WHEN o usuário atual envia uma mensagem THEN a mensagem deve aparecer alinhada à direita com fundo gradiente azul/rosa
2. WHEN o outro usuário envia uma mensagem THEN a mensagem deve aparecer alinhada à esquerda com fundo branco
3. WHEN o chat carrega mensagens THEN cada mensagem deve verificar o senderId contra o userId atual para determinar o alinhamento
4. WHEN há múltiplas mensagens THEN o alinhamento deve alternar corretamente entre esquerda e direita baseado no remetente

### Requirement 3: Implementação de Indicadores de Leitura

**User Story:** Como usuário, quero ver quando minhas mensagens foram visualizadas pelo outro usuário, para saber se a pessoa leu minha mensagem.

#### Acceptance Criteria

1. WHEN uma mensagem é enviada THEN deve ter um campo `isRead: false` por padrão
2. WHEN o destinatário abre o chat THEN todas as mensagens não lidas devem ser marcadas como `isRead: true`
3. WHEN uma mensagem do usuário atual está não lida THEN deve mostrar ícone de check simples (✓) em cinza
4. WHEN uma mensagem do usuário atual está lida THEN deve mostrar ícone de check duplo (✓✓) em azul
5. WHEN o usuário envia uma nova mensagem THEN o contador de não lidas do outro usuário deve incrementar
6. WHEN o destinatário abre o chat THEN o contador de não lidas deve zerar

### Requirement 4: Validação do Visual do Estado Vazio

**User Story:** Como usuário, quero ver um estado vazio bonito e inspirador quando ainda não há mensagens no chat, para me sentir motivado a iniciar a conversa.

#### Acceptance Criteria

1. WHEN o chat não tem mensagens THEN deve mostrar:
   - Coração pulsante (💕) animado
   - Título "Vocês têm um Match! 🎉"
   - Card com versículo bíblico sobre amor (1 Coríntios 13:4)
   - Corações flutuantes animados
   - Mensagem de incentivo "Comece uma conversa! 💬"
2. WHEN o usuário envia a primeira mensagem THEN o estado vazio deve desaparecer e mostrar as mensagens
3. WHEN o chat tem mensagens THEN o estado vazio NÃO deve aparecer

### Requirement 5: Correção do Erro de Hero Tag Duplicado

**User Story:** Como desenvolvedor, quero corrigir o erro de Hero tags duplicados, para evitar crashes e warnings no console.

#### Acceptance Criteria

1. WHEN o app carrega THEN NÃO deve mostrar erro "There are multiple heroes that share the same tag within a subtree"
2. WHEN navega entre telas THEN as animações Hero devem funcionar corretamente
3. WHEN há múltiplos perfis na tela THEN cada Hero tag deve ser único usando o userId

## Success Metrics

- Navegação intuitiva com matches acessíveis via Comunidade > Vitrine de Propósito
- Mensagens alinhadas corretamente (direita para usuário atual, esquerda para outro)
- Indicadores de leitura funcionando (check simples/duplo, cinza/azul)
- Estado vazio inspirador e funcional
- Zero erros de Hero tags duplicados no console
