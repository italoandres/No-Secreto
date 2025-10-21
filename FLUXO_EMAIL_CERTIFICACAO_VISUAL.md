# 📧 Fluxo Visual - Sistema de Emails

## 🎯 Como Funciona

```
┌─────────────────────────────────────────────────────────────┐
│                    USUÁRIO NO APP                            │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ 1. Envia solicitação
                            │    de certificação
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    FIRESTORE                                 │
│  Collection: certification_requests                          │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ {                                                    │   │
│  │   userName: "João",                                 │   │
│  │   userEmail: "joao@email.com",                      │   │
│  │   purchaseEmail: "joao@gmail.com",                  │   │
│  │   proofFileUrl: "https://...",                      │   │
│  │   status: "pending"                                 │   │
│  │ }                                                    │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ 2. Trigger automático
                            │    onCreate
                            ▼
┌─────────────────────────────────────────────────────────────┐
│              CLOUD FUNCTION                                  │
│  sendCertificationRequestEmail()                             │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │ 1. Lê dados da solicitação                         │    │
│  │ 2. Monta email HTML bonito                         │    │
│  │ 3. Envia via Nodemailer + Gmail                    │    │
│  └────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ 3. Email enviado
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    📧 GMAIL                                  │
│                                                              │
│  Para: sinais.aplicativo@gmail.com                          │
│  Assunto: 🏆 Nova Solicitação de Certificação              │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │ 🏆 Nova Solicitação de Certificação                │    │
│  │                                                     │    │
│  │ 👤 Nome: João                                       │    │
│  │ 📧 Email: joao@email.com                            │    │
│  │ 🛒 Email Compra: joao@gmail.com                     │    │
│  │ 📅 Data: 14/10/2025 15:30                           │    │
│  │                                                     │    │
│  │ [📄 Ver Comprovante]                                │    │
│  └────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ 4. Admin revisa
                            ▼
┌─────────────────────────────────────────────────────────────┐
│              ADMIN NO PAINEL                                 │
│                                                              │
│  Opções:                                                     │
│  ┌─────────────┐  ┌─────────────┐                          │
│  │  ✅ Aprovar  │  │  ❌ Rejeitar │                          │
│  └─────────────┘  └─────────────┘                          │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ 5. Atualiza status
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    FIRESTORE                                 │
│  Update: status = "approved" ou "rejected"                   │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ 6. Trigger automático
                            │    onUpdate
                            ▼
┌─────────────────────────────────────────────────────────────┐
│              CLOUD FUNCTION                                  │
│  sendCertificationApprovalEmail()                            │
│  ou                                                          │
│  sendCertificationRejectionEmail()                           │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ 7. Email enviado
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    📧 GMAIL                                  │
│                                                              │
│  Para: joao@email.com                                        │
│                                                              │
│  SE APROVADO:                                                │
│  ┌────────────────────────────────────────────────────┐    │
│  │ 🎉 Parabéns, João!                                  │    │
│  │                                                     │    │
│  │ 🏆 Certificação Aprovada!                           │    │
│  │                                                     │    │
│  │ Sua certificação espiritual foi aprovada.          │    │
│  │ Agora você possui o selo no app!                   │    │
│  └────────────────────────────────────────────────────┘    │
│                                                              │
│  SE REJEITADO:                                               │
│  ┌────────────────────────────────────────────────────┐    │
│  │ 📋 Revisão Necessária                               │    │
│  │                                                     │    │
│  │ Sua solicitação precisa de ajustes.                │    │
│  │                                                     │    │
│  │ Motivo: [motivo fornecido pelo admin]              │    │
│  └────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔄 Resumo do Fluxo

1. **Usuário** → Envia solicitação no app
2. **Firestore** → Salva documento
3. **Cloud Function** → Detecta novo documento (onCreate)
4. **Email** → Enviado para admin automaticamente
5. **Admin** → Revisa e aprova/rejeita
6. **Firestore** → Status atualizado
7. **Cloud Function** → Detecta mudança (onUpdate)
8. **Email** → Enviado para usuário automaticamente

---

## ⚡ Triggers Automáticos

### **Trigger 1: onCreate**
```javascript
.document('certification_requests/{requestId}')
.onCreate()
```
**Quando:** Novo documento criado
**Ação:** Envia email para admin

### **Trigger 2: onUpdate**
```javascript
.document('certification_requests/{requestId}')
.onUpdate()
```
**Quando:** Status muda para "approved" ou "rejected"
**Ação:** Envia email para usuário

---

## 📧 Templates de Email

### **1. Email para Admin**
- ✅ Design profissional
- ✅ Todas as informações da solicitação
- ✅ Link direto para o comprovante
- ✅ Call-to-action claro

### **2. Email de Aprovação**
- ✅ Mensagem de parabéns
- ✅ Visual celebrativo
- ✅ Informações sobre o selo

### **3. Email de Rejeição**
- ✅ Tom respeitoso
- ✅ Motivo da rejeição
- ✅ Instruções para correção

---

## 🎨 Características dos Emails

✅ **HTML Responsivo**
✅ **Design Moderno**
✅ **Cores do Brand**
✅ **Emojis para clareza**
✅ **Call-to-actions claros**
✅ **Footer profissional**

---

## 🔐 Segurança

✅ **Senha de App Gmail** (não senha real)
✅ **Variáveis de ambiente** (não no código)
✅ **HTTPS automático**
✅ **Autenticação Firebase**

---

## 💰 Custo

**Plano Blaze:**
- 2 milhões de invocações/mês = **GRÁTIS**
- Depois: $0.40 por milhão

**Para certificações:**
- 100/mês = **GRÁTIS**
- 1000/mês = **GRÁTIS**
- 10.000/mês ≈ **$0.20**

---

**Sistema 100% automático! 🚀**

