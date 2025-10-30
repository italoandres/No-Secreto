# 🎨 Guia de Teste - Modal Moderno de Comentários

## 📋 Visão Geral

Este guia descreve como testar o novo modal moderno de comentários nos Stories, inspirado no Instagram/Telegram.

---

## ✅ Checklist de Testes

### 1. Abertura do Modal

**Como testar:**
1. Abra um Story no app
2. Toque no botão "Comentários" (ícone de chat)

**Comportamento esperado:**
- ✅ Modal desliza suavemente de baixo para cima (300ms)
- ✅ Ocupa 90% da tela inicialmente
- ✅ Background branco com bordas arredondadas no topo (20px)
- ✅ Barrinha cinza de arrasto visível no topo
- ✅ Overlay escuro semi-transparente atrás do modal

---

### 2. Cabeçalho (ModalHeader)

**Elementos visíveis:**
- ✅ Botão "X" para fechar (canto superior esquerdo)
- ✅ Título do Story (bold, 16px)
- ✅ Descrição do Story (cinza, 13px)
- ✅ Botão "Ver mais/Ver menos" se descrição for longa

**Como testar:**
- Toque em "Ver mais" → descrição expande
- Toque em "Ver menos" → descrição colapsa
- Toque no "X" → modal fecha

---

### 3. Seções de Comentários

**Ordem das seções:**
1. 🔥 **Chats em Alta** (laranja)
2. 🌱 **Chats Recentes** (verde)
3. ✨ **Chats do Pai** (roxo)

**Como testar:**
- Verifique se os comentários aparecem nas seções corretas
- Comentários com >20 reações OU >5 respostas → Chats em Alta
- Comentários <24h com baixo engajamento → Chats Recentes
- Comentários fixados (isCurated=true) → Chats do Pai

**Visual esperado:**
- ✅ Headers de seção com emoji e cor específica
- ✅ Fonte 18px, weight 600
- ✅ Espaçamento de 24px entre seções

---

### 4. Cards de Comentários

**Elementos de cada card:**
- ✅ Foto de perfil (32px, circular)
- ✅ Nome do usuário (bold, 16px)
- ✅ Timestamp (cinza, 12px, alinhado à direita)
- ✅ Estatísticas: ❤️ [count] 💭 [count] "Última resposta há X"
- ✅ Texto do comentário (15px, preto)
- ✅ Botões: Curtir + Responder

**Visual especial para "Chats em Alta":**
- ✅ Background com gradient (laranja claro → branco)
- ✅ Borda laranja sutil

**Visual para "Chats do Pai":**
- ✅ Badge roxo "Fixado pelo Arauto" com ícone ✨

---

### 5. Interações - Curtir

**Como testar:**
1. Toque no botão de coração de um comentário

**Comportamento esperado:**
- ✅ **Optimistic update**: UI atualiza IMEDIATAMENTE
- ✅ Ícone muda de outline → filled (ou vice-versa)
- ✅ Cor muda de cinza → vermelho (ou vice-versa)
- ✅ **Animação especial do coração:**
  - Scale: 1.0 → 1.2 → 1.0
  - Duration: 200ms
  - Curve: elasticOut
- ✅ Contador anima com fade + slide
- ✅ Se houver erro, reverte automaticamente

---

### 6. Interações - Responder

**Como testar:**
1. Toque no botão "Responder" de um comentário

**Comportamento esperado:**
- ✅ Dialog aparece mostrando:
  - Título "Respostas"
  - "Respondendo a [Nome]:"
  - Trecho do comentário original
  - Mensagem: "A funcionalidade de respostas será implementada na próxima etapa!"
- ✅ Botão "Entendi" fecha o dialog

---

### 7. Enviar Novo Comentário

**Como testar:**
1. Digite um comentário no campo fixo no rodapé
2. Toque no botão de enviar (ícone de avião)

**Comportamento esperado:**
- ✅ SnackBar de loading aparece: "Enviando comentário..."
- ✅ Campo de texto limpa automaticamente
- ✅ SnackBar de sucesso (verde): "Comentário enviado!" ✓
- ✅ Lista de comentários recarrega
- ✅ **Scroll automático** para o topo (500ms, suave)
- ✅ Novo comentário aparece na seção "Chats Recentes"

**Se houver erro:**
- ✅ SnackBar vermelho: "Erro ao enviar: [mensagem]"
- ✅ Botão "Tentar novamente" disponível

---

### 8. Campo de Input Fixo

**Elementos:**
- ✅ TextField com placeholder: "Escreva o que o Pai falou ao seu coração..."
- ✅ Background cinza claro (grey[100])
- ✅ Border radius 24px
- ✅ Botão de enviar circular (44px)
- ✅ Botão desabilitado quando campo vazio
- ✅ Altura fixa de 60px
- ✅ Border top sutil

**Como testar:**
- Digite texto → botão fica azul e habilitado
- Apague texto → botão fica cinza e desabilitado
- Campo permanece visível durante scroll

---

### 9. Pull-to-Dismiss

**Como testar:**
1. Arraste o modal para baixo pela barrinha cinza

**Comportamento esperado:**
- ✅ Modal acompanha o gesto
- ✅ Pode arrastar até 50% da tela (minChildSize)
- ✅ Se arrastar além do threshold → modal fecha
- ✅ Se soltar antes → modal volta para 90%
- ✅ Animação suave e responsiva

---

### 10. Estados Especiais

#### Estado de Loading
**Como ver:**
- Abra o modal enquanto comentários estão carregando

**Visual esperado:**
- ✅ 5 cards placeholder com shimmer effect
- ✅ Foto, nome e texto em cinza claro
- ✅ Animação sutil (opcional)

#### Estado Vazio
**Como ver:**
- Abra um Story sem comentários

**Visual esperado:**
- ✅ Ícone de chat grande (64px, cinza)
- ✅ Título: "Nenhum comentário ainda"
- ✅ Mensagem: "Seja o primeiro a compartilhar..."
- ✅ Botão azul: "Escrever comentário"
- ✅ Centralizado verticalmente

---

## 🎯 Cenários de Teste Completos

### Cenário 1: Primeiro Comentário
1. Abra um Story sem comentários
2. Veja o estado vazio
3. Digite um comentário
4. Envie
5. Veja o comentário aparecer em "Chats Recentes"

### Cenário 2: Curtir e Descurtir
1. Abra um Story com comentários
2. Curta um comentário → veja animação
3. Descurta o mesmo comentário → veja animação reversa
4. Contador deve atualizar corretamente

### Cenário 3: Navegação Completa
1. Abra o modal
2. Scroll pelas 3 seções
3. Leia a descrição expandida do Story
4. Curta alguns comentários
5. Tente responder (veja dialog)
6. Adicione um novo comentário
7. Feche o modal com pull-to-dismiss

---

## 🐛 Problemas Conhecidos

Nenhum problema conhecido no momento. Se encontrar algum, documente aqui:

- [ ] Problema 1: [descrição]
- [ ] Problema 2: [descrição]

---

## 📱 Compatibilidade

**Testado em:**
- [ ] Android (emulador)
- [ ] Android (dispositivo real)
- [ ] iOS (simulador)
- [ ] iOS (dispositivo real)

**Versões do Flutter:**
- Versão mínima: Flutter 3.0+
- Versão testada: [sua versão]

---

## 🎨 Comparação Visual

### Antes (Modal Antigo)
- Navegação com Navigator.push
- Tela cheia
- Sem animações especiais
- Layout simples de lista

### Depois (Modal Moderno)
- Bottom Sheet deslizante
- 90% da tela
- Animações suaves em tudo
- Seções organizadas
- Visual Instagram/Telegram
- Optimistic updates
- Feedback visual rico

---

## ✨ Próximos Passos

Após validar este modal:
1. **Etapa 5**: Implementar tela de respostas (threads)
2. **Melhorias futuras**:
   - Menções (@usuario)
   - Reações além de curtir (❤️ 🙏 🔥)
   - Notificações push
   - Paginação infinita

---

## 📞 Suporte

Se encontrar problemas ou tiver dúvidas:
- Verifique os logs do console
- Revise o código em `lib/views/stories/modern_community_comments_view.dart`
- Consulte o design em `.kiro/specs/modernizar-modal-comentarios-stories/design.md`

---

**Data de criação**: 2025-01-XX  
**Última atualização**: 2025-01-XX  
**Versão**: 1.0
