# 📊 Fluxo Visual - Sistema de Email de Certificação

## 🎯 Visão Geral do Fluxo

```
┌─────────────────────────────────────────────────────────────────┐
│                    SISTEMA DE CERTIFICAÇÃO                       │
│                  Email: sinais.aplicativo@gmail.com              │
└─────────────────────────────────────────────────────────────────┘

┌──────────────┐
│   USUÁRIO    │
│   📱 App     │
└──────┬───────┘
       │
       │ 1. Preenche formulário
       │    - Email da compra
       │    - Upload comprovante
       ↓
┌──────────────────────┐
│  FORMULÁRIO SUBMIT   │
│  ✅ Validação OK     │
└──────┬───────────────┘
       │
       │ 2. Salva no Firestore
       ↓
┌──────────────────────────────────────┐
│  FIRESTORE                           │
│  Collection: spiritual_certifications│
│  ├─ userId                           │
│  ├─ userEmail                        │
│  ├─ purchaseEmail                    │
│  ├─ proofImageUrl                    │
│  ├─ status: "pending"                │
│  └─ requestedAt                      │
└──────┬───────────────────────────────┘
       │
       │ 3. Trigger: Email Service
       ↓
┌────────────────────────────────────────────┐
│  EMAIL SERVICE                             │
│  EmailService.notifyAdminNewRequest()      │
│                                            │
│  📧 Para: sinais.aplicativo@gmail.com     │
│  📝 Assunto: 🏆 Nova Solicitação          │
│  🎨 Template: HTML Profissional           │
└────────┬───────────────────────────────────┘
         │
         │ 4. Email enviado
         ↓
┌──────────────────────────────────────┐
│  📬 CAIXA DE ENTRADA ADMIN           │
│  sinais.aplicativo@gmail.com         │
│                                      │
│  ┌────────────────────────────────┐ │
│  │ 🏆 Nova Solicitação            │ │
│  │ De: Sistema Sinais             │ │
│  │                                │ │
│  │ Nome: João Silva               │ │
│  │ Email App: joao@email.com      │ │
│  │ Email Compra: joao@outro.com   │ │
│  │                                │ │
│  │ [Ver Comprovante] [Painel]     │ │
│  └────────────────────────────────┘ │
└──────┬───────────────────────────────┘
       │
       │ 5. Admin analisa
       ↓
┌──────────────────────┐
│  DECISÃO DO ADMIN    │
│                      │
│  ┌────────────────┐  │
│  │   APROVAR ✅   │  │
│  └────────────────┘  │
│         OU           │
│  ┌────────────────┐  │
│  │   REJEITAR ❌  │  │
│  └────────────────┘  │
└──────┬───────────────┘
       │
       ├─────────────────────────────────┐
       │                                 │
       │ APROVAÇÃO                       │ REJEIÇÃO
       ↓                                 ↓
┌──────────────────────┐        ┌──────────────────────┐
│  UPDATE FIRESTORE    │        │  UPDATE FIRESTORE    │
│  status: "approved"  │        │  status: "rejected"  │
│  reviewedAt: now()   │        │  rejectionReason     │
└──────┬───────────────┘        └──────┬───────────────┘
       │                               │
       │ 6. Notifica usuário           │ 6. Notifica usuário
       ↓                               ↓
┌──────────────────────┐        ┌──────────────────────┐
│  EMAIL APROVAÇÃO     │        │  EMAIL REJEIÇÃO      │
│  Para: joao@email    │        │  Para: joao@email    │
│  ✅ Parabéns!        │        │  ❌ Revisão Necessária│
└──────┬───────────────┘        └──────┬───────────────┘
       │                               │
       │ 7. Usuário recebe             │ 7. Usuário recebe
       ↓                               ↓
┌──────────────────────┐        ┌──────────────────────┐
│  📬 INBOX USUÁRIO    │        │  📬 INBOX USUÁRIO    │
│                      │        │                      │
│  ✅ Certificação     │        │  ❌ Solicitação      │
│     Aprovada!        │        │     Precisa Revisão  │
│                      │        │                      │
│  - Selo no perfil    │        │  - Motivo explicado  │
│  - Benefícios        │        │  - Como corrigir     │
│  - Versículo         │        │  - Tentar novamente  │
└──────────────────────┘        └──────────────────────┘
```

---

## 📧 Detalhes dos Emails

### 1️⃣ Email para Admin (Nova Solicitação)

```
┌─────────────────────────────────────────────────────┐
│                                                     │
│  🏆 Nova Solicitação de Certificação                │
│  Sistema Sinais - Preparado(a) para os Sinais      │
│                                                     │
├─────────────────────────────────────────────────────┤
│                                                     │
│  ⚡ AÇÃO NECESSÁRIA                                 │
│  Uma nova solicitação aguarda sua análise          │
│                                                     │
│  📋 DETALHES DA SOLICITAÇÃO                        │
│  ┌───────────────────────────────────────────────┐ │
│  │ 👤 Nome: João Silva                           │ │
│  │ 📧 Email App: joao@email.com                  │ │
│  │ 🛒 Email Compra: joao@compra.com              │ │
│  │ 📅 Data: 14/10/2025                           │ │
│  │ 🆔 ID: abc123xyz                              │ │
│  └───────────────────────────────────────────────┘ │
│                                                     │
│  🎯 PRÓXIMOS PASSOS                                │
│  1. Ver comprovante                                │
│  2. Acessar painel admin                           │
│  3. Aprovar ou rejeitar                            │
│                                                     │
│  ┌──────────────────┐  ┌──────────────────┐       │
│  │ 📄 Ver Comprovante│  │ ⚙️ Painel Admin  │       │
│  └──────────────────┘  └──────────────────┘       │
│                                                     │
│  💡 Prazo: 3 dias úteis                            │
│                                                     │
└─────────────────────────────────────────────────────┘
```

### 2️⃣ Email para Usuário (Aprovação)

```
┌─────────────────────────────────────────────────────┐
│                                                     │
│  ✅ Certificação Aprovada!                          │
│  Parabéns, João Silva!                             │
│                                                     │
├─────────────────────────────────────────────────────┤
│                                                     │
│  🎉 🏆 🎊                                           │
│                                                     │
│  Sua certificação foi aprovada com sucesso!        │
│                                                     │
│  🌟 BENEFÍCIOS DA CERTIFICAÇÃO                     │
│  ┌───────────────────────────────────────────────┐ │
│  │ ✅ Selo de verificação no perfil              │ │
│  │ ✅ Maior visibilidade nas buscas              │ │
│  │ ✅ Acesso a recursos exclusivos               │ │
│  │ ✅ Credibilidade aumentada                    │ │
│  │ ✅ Prioridade no suporte                      │ │
│  └───────────────────────────────────────────────┘ │
│                                                     │
│  🙏 BÊNÇÃO ESPECIAL                                │
│  "Bem-aventurados os que têm fome e sede           │
│   de justiça, porque serão fartos."                │
│  - Mateus 5:6                                      │
│                                                     │
│  ┌──────────────────┐                              │
│  │ 📱 Abrir Sinais App│                            │
│  └──────────────────┘                              │
│                                                     │
└─────────────────────────────────────────────────────┘
```

### 3️⃣ Email para Usuário (Rejeição)

```
┌─────────────────────────────────────────────────────┐
│                                                     │
│  📋 Solicitação de Certificação                     │
│  Revisão Necessária                                │
│                                                     │
├─────────────────────────────────────────────────────┤
│                                                     │
│  Olá, João Silva!                                  │
│                                                     │
│  Sua solicitação precisa de alguns ajustes.        │
│                                                     │
│  📝 MOTIVO DA REVISÃO                              │
│  ┌───────────────────────────────────────────────┐ │
│  │ Comprovante ilegível. Por favor, envie        │ │
│  │ uma imagem mais clara do documento.           │ │
│  └───────────────────────────────────────────────┘ │
│                                                     │
│  🔄 PRÓXIMOS PASSOS                                │
│  1. Revise o motivo acima                          │
│  2. Prepare documentação correta                   │
│  3. Envie nova solicitação                         │
│  4. Aguarde análise (3 dias úteis)                 │
│                                                     │
│  💡 DICAS IMPORTANTES                              │
│  ✓ Comprovante legível                             │
│  ✓ Email correto                                   │
│  ✓ Dados visíveis                                  │
│  ✓ Formato JPG ou PNG                              │
│                                                     │
│  🙏 PALAVRA DE ENCORAJAMENTO                       │
│  "Não desanimemos de fazer o bem, pois             │
│   no tempo próprio colheremos."                    │
│  - Gálatas 6:9                                     │
│                                                     │
│  ┌──────────────────┐                              │
│  │ 📱 Tentar Novamente│                            │
│  └──────────────────┘                              │
│                                                     │
└─────────────────────────────────────────────────────┘
```

---

## 🔄 Fluxo de Estados

```
┌─────────────┐
│   PENDING   │ ← Estado inicial
│   (Pendente)│
└──────┬──────┘
       │
       │ Admin analisa
       │
       ├──────────────────────────┐
       │                          │
       ↓                          ↓
┌──────────────┐          ┌──────────────┐
│   APPROVED   │          │   REJECTED   │
│  (Aprovado)  │          │  (Rejeitado) │
└──────┬───────┘          └──────┬───────┘
       │                         │
       │ Email ✅                │ Email ❌
       │                         │
       ↓                         ↓
┌──────────────┐          ┌──────────────┐
│ Usuário      │          │ Usuário pode │
│ certificado  │          │ tentar       │
│ no perfil    │          │ novamente    │
└──────────────┘          └──────────────┘
```

---

## 📊 Métricas do Sistema

### Tempos Esperados

```
┌────────────────────────────────────────────┐
│  Ação                    │  Tempo          │
├────────────────────────────────────────────┤
│  Envio de email          │  < 1 segundo    │
│  Análise do admin        │  até 3 dias     │
│  Notificação ao usuário  │  < 1 segundo    │
│  Atualização no perfil   │  Imediato       │
└────────────────────────────────────────────┘
```

### Taxa de Sucesso

```
┌────────────────────────────────────────────┐
│  Métrica                 │  Objetivo       │
├────────────────────────────────────────────┤
│  Entrega de emails       │  > 99%          │
│  Tempo de resposta       │  < 3 dias       │
│  Taxa de aprovação       │  Variável       │
│  Satisfação do usuário   │  > 90%          │
└────────────────────────────────────────────┘
```

---

## 🎨 Cores dos Templates

```
┌─────────────────────────────────────────────────┐
│  Tipo de Email    │  Cor Principal  │  Gradiente│
├─────────────────────────────────────────────────┤
│  Admin (Nova)     │  Laranja        │  #FFA726  │
│  Aprovação        │  Verde          │  #4CAF50  │
│  Rejeição         │  Laranja        │  #FF9800  │
└─────────────────────────────────────────────────┘
```

---

## ✅ Checklist de Funcionamento

### Para Cada Solicitação:

- [ ] Formulário preenchido corretamente
- [ ] Arquivo de comprovante enviado
- [ ] Dados salvos no Firestore
- [ ] Email enviado para `sinais.aplicativo@gmail.com`
- [ ] Admin recebe notificação
- [ ] Admin analisa comprovante
- [ ] Decisão tomada (aprovar/rejeitar)
- [ ] Status atualizado no Firestore
- [ ] Email enviado ao usuário
- [ ] Usuário notificado do resultado

---

## 🎯 Resumo Final

```
┌──────────────────────────────────────────────────┐
│                                                  │
│  ✅ Sistema 100% Configurado                     │
│                                                  │
│  📧 Email: sinais.aplicativo@gmail.com          │
│  🎨 Templates: HTML Profissionais               │
│  🔄 Retry: Automático                           │
│  📊 Logs: Detalhados                            │
│  ⚡ Status: Pronto para Uso                     │
│                                                  │
└──────────────────────────────────────────────────┘
```

---

**Última atualização:** 14/10/2025  
**Versão:** 1.0  
**Status:** ✅ Operacional
