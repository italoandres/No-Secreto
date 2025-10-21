# 📧 Guia Completo: Configuração de Emails com Firebase Cloud Functions

## ✅ O que foi implementado

Sistema completo de envio de emails automáticos para certificação espiritual usando Firebase Cloud Functions + Nodemailer + Gmail.

---

## 📋 Pré-requisitos

1. ✅ Projeto Firebase configurado
2. ✅ Plano Blaze (pay-as-you-go) do Firebase
3. ✅ Conta Gmail para envio de emails
4. ✅ Node.js instalado (versão 18+)
5. ✅ Firebase CLI instalado

---

## 🚀 Passo a Passo - Configuração

### **1. Instalar Firebase CLI** (se ainda não tiver)

```bash
npm install -g firebase-tools
```

### **2. Fazer login no Firebase**

```bash
firebase login
```

### **3. Inicializar Functions no projeto**

Na raiz do seu projeto Flutter:

```bash
firebase init functions
```

Selecione:
- ✅ Use an existing project (selecione seu projeto)
- ✅ JavaScript
- ✅ ESLint: Yes
- ✅ Install dependencies: Yes

### **4. Configurar Gmail para envio de emails**

#### **4.1. Ativar verificação em 2 etapas no Gmail**

1. Acesse: https://myaccount.google.com/security
2. Ative "Verificação em duas etapas"

#### **4.2. Gerar senha de app**

1. Acesse: https://myaccount.google.com/apppasswords
2. Selecione "App": Outro (nome personalizado)
3. Digite: "Firebase Functions"
4. Clique em "Gerar"
5. **Copie a senha gerada** (16 caracteres)

### **5. Configurar variáveis de ambiente no Firebase**

```bash
firebase functions:config:set email.user="sinais.aplicativo@gmail.com"
firebase functions:config:set email.password="sua-senha-app-aqui"
```

**Substitua:**
- `sinais.aplicativo@gmail.com` → Seu email Gmail
- `sua-senha-app-aqui` → A senha de app gerada no passo 4.2

### **6. Instalar dependências**

```bash
cd functions
npm install
```

### **7. Deploy das Functions**

```bash
firebase deploy --only functions
```

---

## 📧 Emails que serão enviados

### **1. Email para Admin (Nova Solicitação)**

**Trigger:** Quando um usuário cria uma nova solicitação de certificação

**Para:** `sinais.aplicativo@gmail.com`

**Conteúdo:**
- Nome do usuário
- Email do usuário
- Email de compra
- Data da solicitação
- Link para o comprovante
- ID da solicitação

### **2. Email de Aprovação (Para o Usuário)**

**Trigger:** Quando admin aprova a certificação

**Para:** Email do usuário

**Conteúdo:**
- Mensagem de parabéns
- Confirmação da aprovação
- Informações sobre o selo

### **3. Email de Rejeição (Para o Usuário)**

**Trigger:** Quando admin rejeita a certificação

**Para:** Email do usuário

**Conteúdo:**
- Notificação de revisão necessária
- Motivo da rejeição (se fornecido)
- Instruções para correção

---

## 🧪 Testar as Functions

### **Teste Local (Emulador)**

```bash
cd functions
npm run serve
```

### **Teste em Produção**

1. Crie uma nova solicitação de certificação no app
2. Verifique o email `sinais.aplicativo@gmail.com`
3. Aprove/rejeite no painel admin
4. Verifique o email do usuário

---

## 📊 Monitorar Logs

### **Ver logs em tempo real:**

```bash
firebase functions:log
```

### **Ver logs no console:**

https://console.firebase.google.com/project/SEU_PROJETO/functions/logs

---

## 💰 Custos

### **Plano Blaze (Pay-as-you-go)**

- **Invocações:** 2 milhões/mês GRÁTIS
- **Depois:** $0.40 por milhão
- **Rede:** 5GB/mês GRÁTIS

**Estimativa para certificações:**
- 100 solicitações/mês = **GRÁTIS**
- 1000 solicitações/mês = **GRÁTIS**
- 10.000 solicitações/mês ≈ **$0.20**

---

## 🔧 Troubleshooting

### **Erro: "Insufficient permissions"**

```bash
firebase deploy --only functions --force
```

### **Erro: "Invalid login credentials"**

Verifique se:
1. Verificação em 2 etapas está ativada
2. Senha de app foi gerada corretamente
3. Variáveis de ambiente foram configuradas

```bash
# Ver configurações atuais
firebase functions:config:get

# Reconfigurar
firebase functions:config:set email.user="seu-email@gmail.com"
firebase functions:config:set email.password="sua-senha-app"
```

### **Email não está chegando**

1. Verifique os logs: `firebase functions:log`
2. Verifique spam/lixo eletrônico
3. Teste com outro email
4. Verifique se o Gmail não bloqueou

---

## 📝 Estrutura de Arquivos Criada

```
functions/
├── index.js                 # Cloud Functions (emails)
├── package.json            # Dependências
├── .eslintrc.js           # Configuração ESLint
└── .gitignore             # Arquivos ignorados

```

---

## 🎯 Próximos Passos

1. ✅ Instalar Firebase CLI
2. ✅ Configurar Gmail (senha de app)
3. ✅ Configurar variáveis de ambiente
4. ✅ Deploy das functions
5. ✅ Testar enviando uma solicitação
6. ✅ Verificar email recebido

---

## 🔐 Segurança

- ✅ Senha de app (não a senha real do Gmail)
- ✅ Variáveis de ambiente no Firebase (não no código)
- ✅ HTTPS automático
- ✅ Autenticação Firebase

---

## 📞 Suporte

Se tiver problemas:

1. Verifique os logs: `firebase functions:log`
2. Teste localmente: `npm run serve`
3. Verifique configurações: `firebase functions:config:get`

---

## ✅ Checklist Final

- [ ] Firebase CLI instalado
- [ ] Login no Firebase feito
- [ ] Functions inicializadas
- [ ] Gmail configurado (senha de app)
- [ ] Variáveis de ambiente configuradas
- [ ] Dependências instaladas
- [ ] Deploy realizado
- [ ] Teste enviado
- [ ] Email recebido

---

**Pronto! Agora os emails serão enviados automaticamente! 📧✨**

