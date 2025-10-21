# 🔧 Troubleshooting Avançado - Sistema de Emails

## ❌ Problemas Comuns e Soluções

---

### **1. Email não está chegando**

#### **Diagnóstico:**
```bash
# Ver logs das functions
firebase functions:log

# Ver logs em tempo real
firebase functions:log --follow
```

#### **Possíveis causas:**

**A) Configuração incorreta**
```bash
# Verificar configurações
firebase functions:config:get

# Deve mostrar:
# {
#   "email": {
#     "user": "sinais.aplicativo@gmail.com",
#     "password": "xxxx xxxx xxxx xxxx"
#   }
# }
```

**Solução:**
```bash
firebase functions:config:set email.user="sinais.aplicativo@gmail.com"
firebase functions:config:set email.password="SUA_SENHA_APP"
firebase deploy --only functions --force
```

**B) Senha de app incorreta**
- Gere nova senha: https://myaccount.google.com/apppasswords
- Configure novamente

**C) Gmail bloqueou**
- Verifique: https://myaccount.google.com/notifications
- Permita acesso se bloqueado

**D) Email na pasta spam**
- Verifique spam/lixo eletrônico
- Marque como "não é spam"

---

### **2. Erro: "Invalid login credentials"**

#### **Causa:**
Senha de app incorreta ou não configurada

#### **Solução:**
```bash
# 1. Gerar nova senha de app
# https://myaccount.google.com/apppasswords

# 2. Reconfigurar
firebase functions:config:set email.password="NOVA_SENHA_APP"

# 3. Redeploy
firebase deploy --only functions --force
```

---

### **3. Erro: "Insufficient permissions"**

#### **Causa:**
Projeto não está no plano Blaze

#### **Solução:**
1. Acesse: https://console.firebase.google.com/project/SEU_PROJETO/usage
2. Clique em "Modificar plano"
3. Selecione "Blaze (Pay as you go)"
4. Adicione cartão de crédito

**Não se preocupe:** 2 milhões de invocações/mês são GRÁTIS

---

### **4. Function não está sendo executada**

#### **Diagnóstico:**
```bash
# Ver se a function foi deployada
firebase functions:list

# Deve mostrar:
# sendCertificationRequestEmail
# sendCertificationApprovalEmail
```

#### **Solução:**
```bash
# Redeploy
firebase deploy --only functions --force

# Verificar novamente
firebase functions:list
```

---

### **5. Erro: "ECONNREFUSED" ou "ETIMEDOUT"**

#### **Causa:**
Problema de rede ou firewall

#### **Solução:**
```bash
# Testar conexão
ping smtp.gmail.com

# Se falhar, verificar firewall/proxy
```

---

### **6. Email demora muito para chegar**

#### **Causa:**
Normal - pode demorar até 5 minutos

#### **Verificar:**
```bash
# Ver logs para confirmar envio
firebase functions:log

# Procurar por:
# "✅ Email enviado com sucesso"
```

---

### **7. Erro: "Module not found"**

#### **Causa:**
Dependências não instaladas

#### **Solução:**
```bash
cd functions
rm -rf node_modules
rm package-lock.json
npm install
firebase deploy --only functions
```

---

### **8. Erro ao fazer deploy**

#### **Erro comum:**
```
Error: HTTP Error: 403, The caller does not have permission
```

#### **Solução:**
```bash
# 1. Verificar se está logado
firebase login --reauth

# 2. Verificar projeto
firebase use --add

# 3. Tentar novamente
firebase deploy --only functions --force
```

---

### **9. Function executou mas email não foi enviado**

#### **Diagnóstico:**
```bash
# Ver logs detalhados
firebase functions:log --only sendCertificationRequestEmail

# Procurar por erros
```

#### **Possíveis erros:**

**A) "Error: Invalid email"**
```javascript
// Verificar se o email está correto no Firestore
// certification_requests/{id}
// Campo: userEmail ou purchaseEmail
```

**B) "Error: Connection timeout"**
```bash
# Verificar se o Gmail está acessível
curl https://smtp.gmail.com:587
```

---

### **10. Testar localmente**

#### **Emulador:**
```bash
cd functions
npm run serve
```

#### **Testar manualmente:**
```javascript
// Criar arquivo test.js em functions/
const admin = require('firebase-admin');
admin.initializeApp();

const db = admin.firestore();

// Criar documento de teste
db.collection('certification_requests').add({
  userName: 'Teste',
  userEmail: 'seu-email@gmail.com',
  purchaseEmail: 'seu-email@gmail.com',
  proofFileUrl: 'https://example.com/proof.jpg',
  status: 'pending',
  requestedAt: admin.firestore.FieldValue.serverTimestamp()
});
```

```bash
node test.js
```

---

### **11. Verificar se Gmail está configurado corretamente**

#### **Checklist:**
- [ ] Verificação em 2 etapas ativada
- [ ] Senha de app gerada
- [ ] Senha de app tem 16 caracteres
- [ ] Senha configurada no Firebase
- [ ] Deploy realizado após configuração

#### **Testar Gmail:**
```bash
# Instalar nodemailer globalmente
npm install -g nodemailer

# Criar test-email.js
```

```javascript
const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: 'sinais.aplicativo@gmail.com',
    pass: 'SUA_SENHA_APP_AQUI'
  }
});

transporter.sendMail({
  from: 'sinais.aplicativo@gmail.com',
  to: 'seu-email@gmail.com',
  subject: 'Teste',
  text: 'Teste de email'
}, (error, info) => {
  if (error) {
    console.log('Erro:', error);
  } else {
    console.log('Sucesso:', info.response);
  }
});
```

```bash
node test-email.js
```

---

### **12. Logs úteis para debug**

#### **Ver todos os logs:**
```bash
firebase functions:log
```

#### **Ver logs de uma function específica:**
```bash
firebase functions:log --only sendCertificationRequestEmail
```

#### **Ver logs com filtro:**
```bash
firebase functions:log | grep "Email"
```

#### **Ver logs das últimas 24h:**
```bash
firebase functions:log --since 24h
```

---

### **13. Resetar tudo e começar do zero**

```bash
# 1. Limpar configurações
firebase functions:config:unset email

# 2. Limpar functions
firebase functions:delete sendCertificationRequestEmail
firebase functions:delete sendCertificationApprovalEmail

# 3. Reconfigurar
firebase functions:config:set email.user="sinais.aplicativo@gmail.com"
firebase functions:config:set email.password="NOVA_SENHA_APP"

# 4. Reinstalar dependências
cd functions
rm -rf node_modules package-lock.json
npm install

# 5. Redeploy
firebase deploy --only functions
```

---

### **14. Contatos de Suporte**

**Firebase:**
- Documentação: https://firebase.google.com/docs/functions
- Stack Overflow: https://stackoverflow.com/questions/tagged/firebase-cloud-functions

**Gmail:**
- Senhas de app: https://myaccount.google.com/apppasswords
- Segurança: https://myaccount.google.com/security

---

### **15. Checklist Final de Debug**

- [ ] Firebase CLI instalado e atualizado
- [ ] Login no Firebase funcionando
- [ ] Projeto no plano Blaze
- [ ] Gmail com verificação em 2 etapas
- [ ] Senha de app gerada corretamente
- [ ] Variáveis de ambiente configuradas
- [ ] Dependências instaladas
- [ ] Deploy realizado com sucesso
- [ ] Logs não mostram erros
- [ ] Teste enviado
- [ ] Email verificado (incluindo spam)

---

**Se nada funcionar, entre em contato com os logs completos! 🔧**

