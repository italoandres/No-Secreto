# 🔧 Guia de Teste: Notificações Pulsantes

## 📋 Problema Identificado

Nos logs, vimos que:
1. **Idade sempre null**: `✅ [CARD] Dados encontrados: itala, idade: null`
2. **Nenhuma notificação "new"**: Apenas "pending" e "viewed"
3. **Sem pulsação**: Porque não há notificações com status "new"

## ✅ Solução Implementada

### 1. **Script para Adicionar Idades**
- Arquivo: `lib/utils/add_age_to_test_profiles.dart`
- Adiciona idades aleatórias (18-35 anos) aos perfis sem idade
- Pula perfis que já têm idade

### 2. **Script para Criar Notificações "New"**
- Arquivo: `lib/utils/create_new_interest_notifications.dart`
- Converte até 2 notificações "pending" em "new"
- Essas notificações vão pulsar!

### 3. **Botões na View de Debug**
- **"Adicionar Idades aos Perfis"** (botão amarelo 🎂)
- **"Criar Notificações 'New' (Pulsantes)"** (botão laranja 🔔)

## 🧪 Como Testar

### Passo 1: Adicionar Idades
1. Vá para **Menu → Debug Test Profiles**
2. Clique em **"Adicionar Idades aos Perfis"** (botão amarelo)
3. Aguarde a mensagem de sucesso
4. Verifique os logs: `✅ Usuário xxx → idade: 25`

### Passo 2: Criar Notificações "New"
1. Na mesma tela, clique em **"Criar Notificações 'New' (Pulsantes)"** (botão laranja)
2. Aguarde a mensagem de sucesso
3. Verifique os logs: `✅ Notificação xxx → status: new`

### Passo 3: Ver as Notificações Pulsando
1. Vá para **Aba Sinais → Notificações**
2. Você deve ver:
   - **Notificações "new"**: 
     - ✅ Pulsando continuamente (escala 100% → 103%)
     - ✅ Borda rosa grossa (3px)
     - ✅ Sombra rosa
     - ✅ Nome com idade (ex: "itala, 25")
   
   - **Notificações "pending"**:
     - ✅ Sem pulsar
     - ✅ Borda rosa clara (2px)
     - ✅ Nome com idade
   
   - **Notificações "viewed"**:
     - ✅ Sem pulsar
     - ✅ Borda cinza clara (2px)
     - ✅ Nome com idade

### Passo 4: Testar Mudança de Status
1. Clique em qualquer lugar de uma notificação "new"
2. Ela deve:
   - ✅ Parar de pulsar imediatamente
   - ✅ Mudar borda para cinza clara
   - ✅ Status muda para "viewed"
   - ✅ Contador no menu diminui

## 📊 Comportamento Esperado

### Notificação "new" (Nova)
```
┌─────────────────────────────────┐
│ 💗 PULSANDO (1.0 → 1.03)       │
│ ┌───────────────────────────┐  │
│ │ 👤 itala, 25              │  │ ← Idade dinâmica
│ │ 💕 MATCH!                 │  │
│ │                           │  │
│ │ Tem interesse em você...  │  │
│ │                           │  │
│ │ há 1 minuto               │  │
│ │                           │  │
│ │ [Ver Perfil] [Conversar]  │  │
│ └───────────────────────────┘  │
└─────────────────────────────────┘
   Borda rosa grossa (3px)
```

### Notificação "viewed" (Visualizada)
```
┌─────────────────────────────────┐
│ SEM PULSAR                      │
│ ┌───────────────────────────┐  │
│ │ 👤 itala, 28              │  │ ← Idade dinâmica
│ │                           │  │
│ │ Tem interesse em você...  │  │
│ │                           │  │
│ │ há 5 minutos              │  │
│ │                           │  │
│ │ [Ver Perfil] [Não] [Sim]  │  │
│ └───────────────────────────┘  │
└─────────────────────────────────┘
   Borda cinza clara (2px)
```

## 🔍 Verificação nos Logs

### Logs Esperados ao Adicionar Idades:
```
🔧 Iniciando adição de idades aos perfis de teste...
📊 Total de usuários encontrados: 10
✅ Usuário xxx (itala) → idade: 25
✅ Usuário yyy (italo) → idade: 28
✅ Processo concluído!
📊 Perfis atualizados: 10
```

### Logs Esperados ao Criar Notificações "New":
```
🔧 Iniciando criação de notificações "new"...
📊 Notificações "pending" encontradas: 2
✅ Notificação Rr3ROWpOAgiDBYphGPKj → status: new
   De: itala para: qZrIbFibaQgyZSYCXTJHzxE1sVv1
✅ Processo concluído!
📊 Notificações convertidas para "new": 2
💡 Agora essas notificações devem pulsar!
```

### Logs Esperados ao Carregar Dashboard:
```
🔍 [CARD] Buscando dados do usuário: 05mJSRmm6GSy8ll9q0504XSWhgN2
✅ [CARD] Dados encontrados: itala, idade: 25  ← Idade aparece!
```

## 🎯 Checklist de Teste

- [ ] Idades adicionadas aos perfis
- [ ] Notificações "new" criadas
- [ ] Notificações "new" estão pulsando
- [ ] Borda rosa grossa nas notificações "new"
- [ ] Idade aparece corretamente (ex: "itala, 25")
- [ ] Ao clicar, notificação para de pulsar
- [ ] Borda muda para cinza após clicar
- [ ] Status muda de "new" para "viewed"
- [ ] Contador no menu diminui
- [ ] Notificações "viewed" têm borda cinza
- [ ] Notificações "pending" têm borda rosa clara

## 🚀 Próximos Passos

Se tudo funcionar:
1. ✅ Pulsação contínua funcionando
2. ✅ Bordas corretas por status
3. ✅ Idades dinâmicas
4. ✅ Contador preciso

Se ainda houver problemas:
1. Verifique os logs do console
2. Confirme que os scripts foram executados
3. Recarregue a página (F5)
4. Limpe o cache do navegador
