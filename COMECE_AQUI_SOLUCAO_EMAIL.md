# 🚨 COMECE AQUI - Email Não Está Chegando

## ❌ Seu Problema
Você criou uma solicitação de certificação no app, mas o email **NÃO chegou** em `sinais.aplicativo@gmail.com`

---

## ✅ Solução em 3 Passos (10 minutos)

### **PASSO 1: Deploy das Cloud Functions** ⏱️ 3 min

Abra o terminal e execute:

```bash
cd functions
npm install
cd ..
firebase deploy --only functions
```

**Aguarde 2-5 minutos.** Você verá:
```
✔  functions[sendCertificationRequestEmail]: Successful create operation
✔  functions[sendCertificationApprovalEmail]: Successful create operation
```

---

### **PASSO 2: Configurar Gmail** ⏱️ 5 min

#### **2.1. Gerar Senha de App**

1. Abra este link: https://myaccount.google.com/apppasswords
2. Se pedir, ative "Verificação em 2 etapas" primeiro
3. Clique em "Selecionar app" → "Outro"
4. Digite: "Firebase Sinais"
5. Clique em "Gerar"
6. **COPIE a senha** (16 caracteres, ex: `abcd efgh ijkl mnop`)

#### **2.2. Configurar no Firebase**

```bash
firebase functions:config:set email.user="sinais.aplicativo@gmail.com"
firebase functions:config:set email.password="COLE_A_SENHA_AQUI"
```

**⚠️ IMPORTANTE:** Substitua `COLE_A_SENHA_AQUI` pela senha que você copiou!

#### **2.3. Re-deploy (OBRIGATÓRIO)**

```bash
firebase deploy --only functions
```

---

### **PASSO 3: Testar** ⏱️ 2 min

1. Abra o app
2. Crie uma nova solicitação de certificação
3. Aguarde 30 segundos
4. Verifique `sinais.aplicativo@gmail.com`
5. **Verifique também a pasta SPAM**

---

## 🔍 Verificar se Funcionou

```bash
firebase functions:log
```

**Deve mostrar:**
```
📧 Nova solicitação de certificação: [ID]
✅ Email enviado com sucesso para: sinais.aplicativo@gmail.com
```

---

## ❌ Ainda Não Funciona?

### **Verificação Rápida:**

```bash
# 1. Functions deployadas?
firebase functions:list

# 2. Credenciais configuradas?
firebase functions:config:get

# 3. Ver erros nos logs
firebase functions:log --limit 20
```

---

## 📚 Documentação Completa

Se precisar de mais detalhes, consulte:

1. **[SOLUCAO_RAPIDA_EMAIL.md](SOLUCAO_RAPIDA_EMAIL.md)** - Solução detalhada
2. **[DIAGNOSTICO_EMAIL_NAO_RECEBIDO.md](DIAGNOSTICO_EMAIL_NAO_RECEBIDO.md)** - Diagnóstico completo
3. **[VERIFICAR_CONFIGURACAO_EMAIL.md](VERIFICAR_CONFIGURACAO_EMAIL.md)** - Verificação passo a passo

---

## 🎯 Causas Mais Comuns

1. **Functions não deployadas** (80% dos casos)
   - Solução: Execute o PASSO 1

2. **Credenciais não configuradas** (15% dos casos)
   - Solução: Execute o PASSO 2

3. **Plano Firebase não é Blaze** (5% dos casos)
   - Solução: Faça upgrade no console Firebase

---

## 💡 Dica Importante

Após configurar as variáveis de ambiente, **SEMPRE** faça re-deploy:

```bash
firebase functions:config:set email.user="..."
firebase functions:config:set email.password="..."
firebase deploy --only functions  # ← NÃO ESQUEÇA!
```

---

## 🆘 Precisa de Ajuda?

Execute e me envie o resultado:

```bash
firebase functions:list
firebase functions:config:get
firebase functions:log --limit 20
```

---

## ⏱️ Tempo Estimado

- **PASSO 1:** 3 minutos (deploy)
- **PASSO 2:** 5 minutos (configurar Gmail)
- **PASSO 3:** 2 minutos (testar)

**Total:** ~10 minutos

---

## ✅ Quando Funcionar

Você receberá um email bonito com:

```
🏆 Nova Solicitação de Certificação Espiritual

👤 Nome do Usuário: [Nome]
📧 Email do Usuário: [Email]
🛒 Email de Compra: [Email de compra]
📅 Data da Solicitação: [Data]
🆔 ID da Solicitação: [ID]

[Botão: 📄 Ver Comprovante]
```

---

**Boa sorte! Se seguir os 3 passos, vai funcionar! 🚀**
