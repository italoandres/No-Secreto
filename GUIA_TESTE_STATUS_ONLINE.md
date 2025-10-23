# 🧪 GUIA DE TESTE: Status Online no ChatView

**Data:** 22/10/2025  
**O que testar:** Atualização automática de `lastSeen`

---

## 📋 PRÉ-REQUISITOS

1. App compilado com as mudanças
2. Acesso ao Firebase Console
3. Dois usuários para testar:
   - @italolior (usa ChatView antigo)
   - @italo19 (usa RomanticMatchChatView novo)

---

## 🧪 TESTE 1: Verificar Atualização no Firestore

### Objetivo:
Confirmar que o ChatView está atualizando o campo `lastSeen` no Firestore.

### Passos:

1. **Abrir Firebase Console:**
   - Ir para: https://console.firebase.google.com
   - Selecionar seu projeto
   - Ir para "Firestore Database"

2. **Fazer login no app com @italolior:**
   - Abrir o app
   - Fazer login
   - Aguardar carregar a HomeView (ChatView)

3. **Verificar no Firestore:**
   - No Firebase Console, navegar para:
     ```
     Collection: usuarios
     Document: {id do italolior}
     ```
   - Procurar o campo `lastSeen`
   - **Anotar o timestamp**

4. **Aguardar 30 segundos:**
   - Deixar o app aberto
   - Não fechar nem minimizar
   - Aguardar 30 segundos

5. **Verificar novamente:**
   - Atualizar a página do Firebase Console (F5)
   - Verificar se `lastSeen` foi atualizado
   - **Deve mostrar um timestamp mais recente**

### ✅ Resultado Esperado:

- `lastSeen` deve ser atualizado ao abrir o app
- `lastSeen` deve ser atualizado novamente após 30 segundos
- Timestamp deve ser atual (não "há muito tempo")

### ❌ Se Falhar:

- Verificar se o app compilou corretamente
- Verificar se há erros no console do app
- Verificar se o OnlineStatusService está funcionando

---

## 🧪 TESTE 2: Verificar Status no RomanticMatchChatView

### Objetivo:
Confirmar que o RomanticMatchChatView consegue ler o `lastSeen` atualizado.

### Passos:

1. **Com @italolior ainda logado:**
   - Deixar o app aberto
   - Aguardar 1-2 minutos

2. **Fazer login com @italo19 (em outro dispositivo/navegador):**
   - Abrir o app
   - Fazer login com @italo19
   - Ir para "Matches Aceitos"

3. **Abrir chat com @italolior:**
   - Clicar no match com @italolior
   - Abrir o RomanticMatchChatView

4. **Verificar o texto de status online:**
   - No topo da tela, abaixo do nome
   - Deve mostrar algo como:
     - "Online agora" (se menos de 5 minutos)
     - "Online há 2 minutos" (se entre 5-30 minutos)
     - "Online há 1 hora" (se mais de 30 minutos)

### ✅ Resultado Esperado:

**ANTES da correção:**
- ❌ "Online há muito tempo"

**DEPOIS da correção:**
- ✅ "Online agora" ou "Online há X minutos" (tempo correto)

### ❌ Se Falhar:

- Verificar se @italolior realmente está com o app aberto
- Verificar se o `lastSeen` está sendo atualizado no Firestore (Teste 1)
- Verificar se há erros no RomanticMatchChatView

---

## 🧪 TESTE 3: Verificar Cor do Indicador

### Objetivo:
Confirmar que a cor do indicador de status está correta.

### Passos:

1. **No RomanticMatchChatView (com @italo19):**
   - Observar a cor do círculo ao lado do nome
   - Deve mudar conforme o tempo:

### ✅ Cores Esperadas:

- 🟢 **Verde** = Online agora (menos de 5 minutos)
- 🟡 **Amarelo** = Online recentemente (5-30 minutos)
- 🔴 **Vermelho** = Offline (mais de 30 minutos)
- ⚪ **Cinza** = Sem dados

### Teste Dinâmico:

1. **@italolior fecha o app**
2. **Aguardar 6 minutos**
3. **@italo19 atualiza o chat**
4. **Cor deve mudar de verde para amarelo**

---

## 🧪 TESTE 4: Verificar Timer (Avançado)

### Objetivo:
Confirmar que o timer está funcionando e atualizando a cada 30 segundos.

### Passos:

1. **Abrir Firebase Console em uma aba**
2. **Abrir app com @italolior em outra aba**
3. **Observar o campo `lastSeen` no Firestore**
4. **Aguardar e verificar:**
   - T=0s: `lastSeen` atualizado (ao abrir)
   - T=30s: `lastSeen` atualizado novamente
   - T=60s: `lastSeen` atualizado novamente
   - T=90s: `lastSeen` atualizado novamente

### ✅ Resultado Esperado:

- Atualização a cada 30 segundos
- Timestamp sempre atual
- Sem erros no console

---

## 🧪 TESTE 5: Verificar Limpeza (Dispose)

### Objetivo:
Confirmar que o timer é cancelado ao fechar o app.

### Passos:

1. **Abrir app com @italolior**
2. **Aguardar 1 minuto** (para confirmar que está atualizando)
3. **Fechar o app completamente**
4. **Aguardar 1 minuto**
5. **Verificar no Firestore:**
   - `lastSeen` NÃO deve ser atualizado após fechar
   - Último timestamp deve ser de quando fechou

### ✅ Resultado Esperado:

- Timer para de atualizar ao fechar o app
- Sem memory leaks
- Sem erros

---

## 📊 CHECKLIST DE VALIDAÇÃO

Marque conforme testa:

- [ ] **Teste 1:** `lastSeen` atualiza ao abrir app
- [ ] **Teste 1:** `lastSeen` atualiza a cada 30 segundos
- [ ] **Teste 2:** RomanticMatchChatView mostra tempo correto
- [ ] **Teste 2:** Não mostra mais "há muito tempo"
- [ ] **Teste 3:** Cor do indicador está correta
- [ ] **Teste 3:** Cor muda conforme o tempo
- [ ] **Teste 4:** Timer funciona consistentemente
- [ ] **Teste 5:** Timer para ao fechar app

---

## 🐛 PROBLEMAS COMUNS

### Problema 1: `lastSeen` não atualiza

**Possíveis causas:**
- OnlineStatusService não está funcionando
- Permissões do Firestore
- Usuário não autenticado

**Solução:**
- Verificar logs do app
- Verificar regras do Firestore
- Verificar se FirebaseAuth.instance.currentUser não é null

### Problema 2: RomanticMatchChatView ainda mostra "há muito tempo"

**Possíveis causas:**
- Cache do app
- `lastSeen` não está sendo atualizado
- Lendo o campo errado

**Solução:**
- Limpar cache do app
- Verificar Teste 1 primeiro
- Verificar se o campo é `lastSeen` (não `last_seen`)

### Problema 3: Timer não para ao fechar app

**Possíveis causas:**
- `dispose()` não está sendo chamado
- Timer não está sendo cancelado

**Solução:**
- Verificar se `_onlineStatusTimer?.cancel()` está no dispose
- Verificar se dispose está sendo chamado

---

## 📝 RELATÓRIO DE TESTE

Após testar, preencha:

**Data do teste:** ___/___/2025  
**Testado por:** _______________

**Resultados:**
- Teste 1: ☐ Passou ☐ Falhou
- Teste 2: ☐ Passou ☐ Falhou
- Teste 3: ☐ Passou ☐ Falhou
- Teste 4: ☐ Passou ☐ Falhou
- Teste 5: ☐ Passou ☐ Falhou

**Observações:**
_________________________________
_________________________________
_________________________________

**Status Final:** ☐ Aprovado ☐ Reprovado

---

## 🎯 PRÓXIMO PASSO

Se todos os testes passarem:
- ✅ PASSO 1 está completo
- ➡️ Prosseguir para PASSO 2 (fazer ChatView ler mensagens de match_chats)

Se algum teste falhar:
- ❌ Corrigir o problema
- 🔄 Repetir os testes

---

**Criado por:** Kiro  
**Versão:** 1.0  
**Status:** Pronto para uso
