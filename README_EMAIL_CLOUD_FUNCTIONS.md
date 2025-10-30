# 📧 Sistema de Emails - Firebase Cloud Functions

## ✅ Implementação Completa

Sistema automático de envio de emails para certificação espiritual usando **Firebase Cloud Functions + Nodemailer + Gmail**.

---

## 🎯 O que foi criado

### **Arquivos:**
```
functions/
├── index.js              # 3 Cloud Functions (emails)
├── package.json          # Dependências
├── .eslintrc.js         # Config ESLint
└── .gitignore           # Ignorar node_modules

Documentação/
├── GUIA_CONFIGURACAO_EMAIL_CLOUD_FUNCTIONS.md  # Guia completo
├── COMANDOS_RAPIDOS_EMAIL_SETUP.md             # Comandos rápidos
├── FLUXO_EMAIL_CERTIFICACAO_VISUAL.md          # Fluxo visual
└── README_EMAIL_CLOUD_FUNCTIONS.md             # Este arquivo
```

### **3 Cloud Functions:**

1. **`sendCertificationRequestEmail`**
   - Trigger: onCreate em `certification_requests`
   - Envia email para admin quando nova solicitação é criada

2. **`sendCertificationApprovalEmail`**
   - Trigger: onUpdate em `certification_requests`
   - Envia email para usuário quando certificação é aprovada

3. **`sendCertificationRejectionEmail`**
   - Trigger: onUpdate em `certification_requests`
   - Envia email para usuário quando certificação é rejeitada

---

## 🚀 Setup Rápido (5 minutos)

### **1. Instalar Firebase CLI**
```bash
npm install -g firebase-tools
```

### **2. Login**
```bash
firebase login
```

### **3. Inicializar Functions**
```bash
firebase init functions
```

### **4. Gerar Senha de App Gmail**
1. Acesse: https://myaccount.google.com/apppasswords
2. Crie senha para "Firebase Functions"
3. Copie a senha gerada

### **5. Configurar Variáveis**
```bash
firebase functions:config:set email.user="sinais.aplicativo@gmail.com"
firebase functions:config:set email.password="SENHA_APP_AQUI"
```

### **6. Deploy**
```bash
cd functions
npm install
firebase deploy --only functions
```

---

## 📧 Emails Enviados

### **1. Para Admin (Nova Solicitação)**
- **Para:** `sinais.aplicativo@gmail.com`
- **Quando:** Usuário envia solicitação
- **Conteúdo:** Dados do usuário + link do comprovante

### **2. Para Usuário (Aprovação)**
- **Para:** Email do usuário
- **Quando:** Admin aprova
- **Conteúdo:** Mensagem de parabéns + informações do selo

### **3. Para Usuário (Rejeição)**
- **Para:** Email do usuário
- **Quando:** Admin rejeita
- **Conteúdo:** Motivo + instruções

---

## 🧪 Testar

1. Envie uma solicitação no app
2. Verifique `sinais.aplicativo@gmail.com`
3. Aprove/rejeite no painel admin
4. Verifique email do usuário

---

## 📊 Monitorar

```bash
# Ver logs
firebase functions:log

# Ver logs em tempo real
firebase functions:log --follow

# Console Firebase
https://console.firebase.google.com/project/SEU_PROJETO/functions/logs
```

---

## 💰 Custos

**Plano Blaze (Pay-as-you-go):**
- 2 milhões invocações/mês = **GRÁTIS**
- Depois: $0.40 por milhão

**Estimativa:**
- 100 certificações/mês = **GRÁTIS**
- 1000 certificações/mês = **GRÁTIS**
- 10.000 certificações/mês ≈ **$0.20**

---

## 🔧 Comandos Úteis

```bash
# Ver configurações
firebase functions:config:get

# Redeploy
firebase deploy --only functions --force

# Testar localmente
cd functions && npm run serve

# Ver logs
firebase functions:log
```

---

## ❌ Troubleshooting

### **Email não chegou?**
1. Verifique logs: `firebase functions:log`
2. Verifique spam/lixo eletrônico
3. Verifique configurações: `firebase functions:config:get`

### **Erro de autenticação?**
```bash
# Reconfigurar
firebase functions:config:set email.user="seu-email@gmail.com"
firebase functions:config:set email.password="sua-senha-app"
firebase deploy --only functions --force
```

---

## 📚 Documentação Completa

- **Guia Completo:** `GUIA_CONFIGURACAO_EMAIL_CLOUD_FUNCTIONS.md`
- **Comandos Rápidos:** `COMANDOS_RAPIDOS_EMAIL_SETUP.md`
- **Fluxo Visual:** `FLUXO_EMAIL_CERTIFICACAO_VISUAL.md`

---

## ✅ Checklist

- [ ] Firebase CLI instalado
- [ ] Login feito
- [ ] Functions inicializadas
- [ ] Senha de app Gmail gerada
- [ ] Variáveis configuradas
- [ ] Deploy realizado
- [ ] Teste enviado
- [ ] Email recebido ✅

---

## 🎉 Pronto!

Agora os emails serão enviados **automaticamente** sempre que:
- ✅ Nova solicitação for criada
- ✅ Certificação for aprovada
- ✅ Certificação for rejeitada

**Sistema 100% automático! 🚀**

