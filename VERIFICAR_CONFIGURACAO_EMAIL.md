# ✅ Script de Verificação Automática - Email Cloud Functions

## 🎯 Execute estes comandos em ordem

Copie e cole cada comando no terminal e me envie o resultado.

---

## **1️⃣ Verificar Firebase CLI**

```bash
firebase --version
```

**Esperado:** Versão 12.x.x ou superior

**Se der erro:** 
```bash
npm install -g firebase-tools
```

---

## **2️⃣ Verificar Login**

```bash
firebase login:list
```

**Esperado:** Mostrar seu email logado

**Se não estiver logado:**
```bash
firebase login
```

---

## **3️⃣ Verificar Projeto Atual**

```bash
firebase projects:list
```

**Esperado:** Lista de projetos Firebase

**Anotar:** O ID do seu projeto (ex: `sinais-app-12345`)

---

## **4️⃣ Selecionar Projeto Correto**

```bash
firebase use
```

**Esperado:** Mostrar o projeto ativo

**Se não for o correto:**
```bash
firebase use SEU_PROJETO_ID
```

---

## **5️⃣ Verificar Functions Deployadas**

```bash
firebase functions:list
```

**✅ SUCESSO se mostrar:**
```
sendCertificationRequestEmail
sendCertificationApprovalEmail
```

**❌ PROBLEMA se:**
- Lista vazia
- Erro "No functions deployed"
- Comando não funciona

**SOLUÇÃO:**
```bash
cd functions
npm install
cd ..
firebase deploy --only functions
```

---

## **6️⃣ Verificar Configurações de Email**

```bash
firebase functions:config:get
```

**✅ SUCESSO se mostrar:**
```json
{
  "email": {
    "user": "sinais.aplicativo@gmail.com",
    "password": "xxxx xxxx xxxx xxxx"
  }
}
```

**❌ PROBLEMA se:**
- Vazio: `{}`
- Sem a chave "email"

**SOLUÇÃO:**

1. **Gerar senha de app do Gmail:**
   - Acesse: https://myaccount.google.com/apppasswords
   - Gere senha para "Firebase Sinais"
   - Copie a senha (16 caracteres)

2. **Configurar:**
```bash
firebase functions:config:set email.user="sinais.aplicativo@gmail.com"
firebase functions:config:set email.password="SUA_SENHA_APP_AQUI"
```

3. **Re-deploy (OBRIGATÓRIO):**
```bash
firebase deploy --only functions
```

---

## **7️⃣ Verificar Logs Recentes**

```bash
firebase functions:log --limit 20
```

**Procure por:**
- ✅ `📧 Nova solicitação de certificação`
- ✅ `✅ Email enviado com sucesso`
- ❌ `❌ Erro ao enviar email`
- ❌ `Invalid login credentials`

---

## **8️⃣ Verificar Plano Firebase**

1. Acesse: https://console.firebase.google.com
2. Selecione seu projeto
3. Clique em "⚙️ Configurações do projeto"
4. Vá em "Uso e faturamento"
5. Verifique se está no **Plano Blaze**

**Se estiver no Spark (gratuito):**
- Cloud Functions NÃO funcionam
- Faça upgrade para Blaze
- Não se preocupe: 2 milhões de invocações grátis/mês

---

## **9️⃣ Teste Manual**

Depois de tudo configurado:

1. Abra o app
2. Crie uma solicitação de certificação
3. Aguarde 30 segundos
4. Verifique: `sinais.aplicativo@gmail.com`
5. **Verifique também SPAM/LIXO ELETRÔNICO**

---

## **🔟 Ver Logs em Tempo Real**

Deixe este comando rodando enquanto testa:

```bash
firebase functions:log --only sendCertificationRequestEmail
```

**Você verá em tempo real:**
- Quando a function é acionada
- Se o email foi enviado
- Qualquer erro que ocorrer

---

## 📋 Resumo dos Comandos Principais

```bash
# 1. Verificar tudo
firebase --version
firebase login:list
firebase projects:list
firebase use
firebase functions:list
firebase functions:config:get

# 2. Deploy (se necessário)
cd functions
npm install
cd ..
firebase deploy --only functions

# 3. Configurar email (se necessário)
firebase functions:config:set email.user="sinais.aplicativo@gmail.com"
firebase functions:config:set email.password="SUA_SENHA_APP"
firebase deploy --only functions

# 4. Monitorar
firebase functions:log
```

---

## 🎯 Checklist Rápido

Execute e marque:

```bash
# ✅ CLI instalado?
firebase --version

# ✅ Logado?
firebase login:list

# ✅ Projeto correto?
firebase use

# ✅ Functions deployadas?
firebase functions:list

# ✅ Email configurado?
firebase functions:config:get

# ✅ Logs mostram atividade?
firebase functions:log --limit 10
```

---

## 🆘 Comandos de Emergência

Se nada funcionar, execute em ordem:

```bash
# 1. Reinstalar dependências
cd functions
rm -rf node_modules
npm install
cd ..

# 2. Limpar e re-deploy
firebase deploy --only functions --force

# 3. Ver status
firebase functions:list

# 4. Ver logs
firebase functions:log --limit 50
```

---

## 💡 Dicas Importantes

1. **Sempre re-deploy após configurar variáveis:**
   ```bash
   firebase functions:config:set email.user="..."
   firebase deploy --only functions  # ← OBRIGATÓRIO
   ```

2. **Logs são seus amigos:**
   ```bash
   firebase functions:log
   ```

3. **Teste em tempo real:**
   ```bash
   firebase functions:log --only sendCertificationRequestEmail
   # Deixe rodando e crie uma solicitação no app
   ```

4. **Verifique SPAM:**
   - Primeiro email pode ir para spam
   - Marque como "Não é spam"

---

## 📞 Me Envie

Execute e me envie o resultado de:

```bash
firebase functions:list
firebase functions:config:get
firebase functions:log --limit 20
```

Com isso consigo identificar exatamente o problema! 🔍
