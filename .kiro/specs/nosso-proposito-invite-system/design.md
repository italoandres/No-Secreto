# Design Document

## Overview

O sistema de convites do chat "Nosso Propósito" será restaurado e melhorado para fornecer uma experiência completa de formação de parcerias, incluindo interface de convite sempre visível, sistema de @menções funcional, e restrições apropriadas para manter o propósito do chat compartilhado.

## Architecture

### Componentes Principais

1. **PurposeInviteButton**: Botão fixo para enviar convites (quando sem parceiro)
2. **PurposeInvitesComponent**: Componente para exibir convites recebidos (já existe)
3. **MentionAutocompleteComponent**: Autocomplete para @menções (já existe)
4. **ChatRestrictionBanner**: Banner de restrição quando sem parceiro
5. **InviteModal**: Modal para envio de convites com abas

### Fluxo de Dados

```
Usuario sem parceiro → PurposeInviteButton → InviteModal → Firebase
Usuario com convites → PurposeInvitesComponent → Resposta → Firebase
Usuario com parceiro → Chat normal + @menções → Firebase
```

## Components and Interfaces

### 1. PurposeInviteButton Component

**Localização**: Será adicionado ao topo do chat quando usuário não tem parceiro

**Props**:
- `user: UsuarioModel` - Usuário atual
- `onInviteSent: Function` - Callback quando convite é enviado

**Estado**:
- `isLoading: bool` - Estado de carregamento
- `showModal: bool` - Controle do modal

**Design Visual**:
- Botão com gradiente azul/rosa
- Ícone de adicionar pessoa
- Texto "Adicionar Parceiro(a)"
- Posicionado no topo do chat, abaixo do banner "Nosso Propósito"

### 2. InviteModal Component

**Estrutura**:
```dart
class InviteModal extends StatefulWidget {
  final UsuarioModel currentUser;
  final Function(String email, String message) onSendInvite;
}
```

**Abas**:
1. **Aba "Buscar Usuário"**:
   - Campo de busca por email
   - Preview do usuário encontrado
   - Validação em tempo real

2. **Aba "Mensagem do Convite"**:
   - Campo de texto para mensagem personalizada
   - Placeholder com sugestão padrão
   - Contador de caracteres

**Validações**:
- Email deve existir no sistema
- Usuário não pode ser do mesmo sexo
- Usuário não pode estar bloqueado
- Não pode haver convite pendente

### 3. ChatRestrictionBanner Component

**Funcionalidade**:
- Exibido quando usuário não tem parceiro
- Mensagem: "Você precisa ter uma pessoa adicionada para iniciar esse chat"
- Design com gradiente azul/rosa
- Ícone de aviso
- Botão "Adicionar Parceiro" integrado

**Comportamento**:
- Aparece no topo do chat
- Desaparece quando parceria é criada
- Bloqueia campo de mensagem

### 4. Enhanced Mention System

**Melhorias no Sistema Atual**:
- Correção do bug de menções não funcionando
- Melhor integração com PurposePartnershipRepository
- Feedback visual quando menção é enviada
- Tratamento de erros

**Fluxo de Menção**:
1. Usuário digita @ → Autocomplete aparece
2. Usuário seleciona usuário → Menção inserida
3. Usuário envia mensagem → Convite de menção enviado
4. Usuário mencionado recebe convite → Pode aceitar/recusar
5. Se aceito → Usuário adicionado ao chat

## Data Models

### Estruturas Existentes (Mantidas)

1. **PurposeInviteModel** - Já implementado
2. **PurposePartnershipModel** - Já implementado  
3. **PurposeChatModel** - Já implementado

### Novos Estados de Interface

```dart
class InviteSystemState {
  bool hasActivePartnership;
  bool hasPendingInvites;
  bool isLoading;
  String? errorMessage;
  List<PurposeInviteModel> pendingInvites;
}
```

## Error Handling

### Tipos de Erro

1. **Erro de Validação**:
   - Email não encontrado
   - Usuário do mesmo sexo
   - Usuário bloqueado
   - Convite duplicado

2. **Erro de Rede**:
   - Falha na conexão Firebase
   - Timeout de operação
   - Erro de permissão

3. **Erro de Estado**:
   - Usuário já tem parceiro
   - Convite já respondido
   - Parceria inválida

### Tratamento de Erros

```dart
try {
  await sendInvite();
} catch (e) {
  if (e is ValidationException) {
    showValidationError(e.message);
  } else if (e is NetworkException) {
    showNetworkError();
  } else {
    showGenericError();
  }
}
```

## Testing Strategy

### Testes de Unidade

1. **PurposeInviteButton**:
   - Renderização correta baseada no estado
   - Abertura do modal
   - Estados de loading

2. **InviteModal**:
   - Validação de email
   - Troca entre abas
   - Envio de convite

3. **ChatRestrictionBanner**:
   - Exibição condicional
   - Integração com estado de parceria

### Testes de Integração

1. **Fluxo Completo de Convite**:
   - Envio → Recebimento → Aceitação → Chat ativo

2. **Sistema de Menções**:
   - Digitação @ → Autocomplete → Seleção → Envio

3. **Restrições de Chat**:
   - Sem parceiro → Bloqueado
   - Com parceiro → Liberado

### Testes de UI

1. **Responsividade**:
   - Diferentes tamanhos de tela
   - Orientação portrait/landscape

2. **Acessibilidade**:
   - Leitores de tela
   - Navegação por teclado

3. **Estados Visuais**:
   - Loading states
   - Error states
   - Success states

## Implementation Plan

### Fase 1: Restauração Básica
1. Adicionar PurposeInviteButton ao chat
2. Conectar com InviteModal existente
3. Corrigir sistema de menções

### Fase 2: Restrições e Validações
1. Implementar ChatRestrictionBanner
2. Adicionar validações de convite
3. Melhorar tratamento de erros

### Fase 3: Melhorias de UX
1. Animações e transições
2. Feedback visual melhorado
3. Estados de loading otimizados

### Fase 4: Testes e Polimento
1. Testes abrangentes
2. Correção de bugs
3. Otimização de performance

## Security Considerations

### Validações de Segurança

1. **Autenticação**:
   - Verificar usuário logado
   - Validar permissões

2. **Autorização**:
   - Verificar se pode enviar convite
   - Validar acesso ao chat

3. **Sanitização**:
   - Limpar inputs de usuário
   - Validar dados antes de salvar

4. **Rate Limiting**:
   - Limitar convites por usuário
   - Prevenir spam

### Regras de Negócio

1. **Parcerias**:
   - Apenas usuários de sexos opostos
   - Uma parceria ativa por usuário
   - Convites únicos por par de usuários

2. **Bloqueios**:
   - Usuários bloqueados não podem enviar convites
   - Bloqueios são permanentes
   - Bloqueios são unidirecionais

3. **Menções**:
   - Apenas usuários com parceria podem mencionar
   - Menções geram convites automáticos
   - Limite de menções por mensagem

## Performance Considerations

### Otimizações

1. **Lazy Loading**:
   - Carregar convites sob demanda
   - Paginar lista de usuários

2. **Caching**:
   - Cache de estado de parceria
   - Cache de usuários mencionáveis

3. **Debouncing**:
   - Busca de usuários com delay
   - Validação de email com throttle

4. **Batch Operations**:
   - Agrupar operações Firebase
   - Minimizar reads/writes

### Monitoramento

1. **Métricas**:
   - Taxa de aceitação de convites
   - Tempo de resposta de busca
   - Erros de validação

2. **Logs**:
   - Eventos de convite
   - Erros de sistema
   - Performance de queries

## Accessibility

### Requisitos de Acessibilidade

1. **Navegação**:
   - Suporte a navegação por teclado
   - Ordem lógica de foco
   - Atalhos de teclado

2. **Leitores de Tela**:
   - Labels descritivos
   - Anúncios de mudanças de estado
   - Estrutura semântica

3. **Contraste**:
   - Cores com contraste adequado
   - Indicadores visuais claros
   - Suporte a modo escuro

4. **Tamanhos**:
   - Botões com tamanho mínimo
   - Texto legível
   - Espaçamento adequado