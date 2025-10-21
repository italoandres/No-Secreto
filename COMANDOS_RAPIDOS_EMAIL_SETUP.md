# ⚡ Comandos Rápidos - Setup de Email

## 🚀 Configuração Rápida (5 minutos)

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
- Selecione: JavaScript
- ESLint: Yes
- Install: Yes

### **4. Configurar Email**

**Gerar senha de app Gmail:**
1. https://myaccount.google.com/apppasswords
2. Criar senha para "Firebase Functions"
3. Copiar senha gerada

**Configurar no Firebase:**
```bash
firebase functions:config:set email.user="sinais.aplicativo@gmail.com"
firebase functions:config:set email.password="COLE_SENHA_APP_AQUI"
```

### **5. Instalar Dependências**
```bash
cd functions
npm install
```

### **6. Deploy**
```bash
firebase deploy --only functions
```

---

## ✅ Verificar se funcionou

```bash
# Ver logs
firebase functions:log

# Ver configurações
firebase functions:config:get
```

---

## 🧪 Testar

1. Abra o app
2. Envie uma solicitação de certificação
3. Verifique o email: `sinais.aplicativo@gmail.com`

---

## 🔧 Comandos Úteis

```bash
# Ver logs em tempo real
firebase functions:log --follow

# Redeploy
firebase deploy --only functions --force

# Testar localmente
cd functions && npm run serve

# Ver configurações
firebase functions:config:get

# Limpar configurações
firebase functions:config:unset email
```

---

## ❌ Se der erro

```bash
# Reconfigurar email
firebase functions:config:set email.user="seu-email@gmail.com"
firebase functions:config:set email.password="sua-senha-app"

# Redeploy forçado
firebase deploy --only functions --force

# Ver erros
firebase functions:log
```

---

## 📧 Emails Configurados

✅ **Nova Solicitação** → Admin (`sinais.aplicativo@gmail.com`)
✅ **Aprovação** → Usuário
✅ **Rejeição** → Usuário

---

**Pronto! 🎉**

