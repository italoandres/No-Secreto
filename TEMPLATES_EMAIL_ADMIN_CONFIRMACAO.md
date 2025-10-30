# 📧 Templates de Email para Confirmação de Administradores

## Visão Geral

Templates de email para enviar confirmações aos administradores após ações no sistema de certificações.

---

## 📝 Template 1: Confirmação de Aprovação

### Nome do Template
`admin-certification-approval-confirmation`

### Assunto
`✅ Certificação Aprovada - {{userName}}`

### Conteúdo HTML

```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Certificação Aprovada</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      line-height: 1.6;
      color: #333;
      max-width: 600px;
      margin: 0 auto;
      padding: 20px;
    }
    .header {
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      color: white;
      padding: 30px;
      text-align: center;
      border-radius: 10px 10px 0 0;
    }
    .content {
      background: #f9f9f9;
      padding: 30px;
      border-radius: 0 0 10px 10px;
    }
    .success-icon {
      font-size: 48px;
      margin-bottom: 10px;
    }
    .info-box {
      background: white;
      padding: 20px;
      border-radius: 8px;
      margin: 20px 0;
      border-left: 4px solid #4CAF50;
    }
    .info-row {
      margin: 10px 0;
    }
    .label {
      font-weight: bold;
      color: #666;
    }
    .value {
      color: #333;
    }
    .button {
      display: inline-block;
      padding: 12px 30px;
      background: #4CAF50;
      color: white;
      text-decoration: none;
      border-radius: 5px;
      margin: 20px 0;
    }
    .footer {
      text-align: center;
      margin-top: 30px;
      color: #666;
      font-size: 12px;
    }
  </style>
</head>
<body>
  <div class="header">
    <div class="success-icon">✅</div>
    <h1>Certificação Aprovada</h1>
    <p>Confirmação de Ação Administrativa</p>
  </div>
  
  <div class="content">
    <p>Olá <strong>{{adminName}}</strong>,</p>
    
    <p>Este email confirma que você aprovou com sucesso uma solicitação de certificação espiritual.</p>
    
    <div class="info-box">
      <h3>📋 Detalhes da Aprovação</h3>
      
      <div class="info-row">
        <span class="label">Usuário:</span>
        <span class="value">{{userName}}</span>
      </div>
      
      <div class="info-row">
        <span class="label">Email:</span>
        <span class="value">{{userEmail}}</span>
      </div>
      
      <div class="info-row">
        <span class="label">ID do Usuário:</span>
        <span class="value">{{userId}}</span>
      </div>
      
      <div class="info-row">
        <span class="label">ID da Certificação:</span>
        <span class="value">{{certificationId}}</span>
      </div>
      
      <div class="info-row">
        <span class="label">Data da Aprovação:</span>
        <span class="value">{{approvalDateFormatted}}</span>
      </div>
      
      <div class="info-row">
        <span class="label">Notas:</span>
        <span class="value">{{notes}}</span>
      </div>
    </div>
    
    <p><strong>O que acontece agora:</strong></p>
    <ul>
      <li>✅ O usuário receberá uma notificação de aprovação</li>
      <li>🎖️ O badge de certificação será exibido no perfil do usuário</li>
      <li>📊 A ação foi registrada no log de auditoria</li>
    </ul>
    
    <center>
      <a href="{{panelLink}}" class="button">Acessar Painel Administrativo</a>
    </center>
  </div>
  
  <div class="footer">
    <p>Este é um email automático de confirmação.</p>
    <p>Sistema de Certificações Espirituais</p>
  </div>
</body>
</html>
```

---

## 📝 Template 2: Confirmação de Reprovação

### Nome do Template
`admin-certification-rejection-confirmation`

### Assunto
`❌ Certificação Reprovada - {{userName}}`

### Conteúdo HTML

```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Certificação Reprovada</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      line-height: 1.6;
      color: #333;
      max-width: 600px;
      margin: 0 auto;
      padding: 20px;
    }
    .header {
      background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
      color: white;
      padding: 30px;
      text-align: center;
      border-radius: 10px 10px 0 0;
    }
    .content {
      background: #f9f9f9;
      padding: 30px;
      border-radius: 0 0 10px 10px;
    }
    .warning-icon {
      font-size: 48px;
      margin-bottom: 10px;
    }
    .info-box {
      background: white;
      padding: 20px;
      border-radius: 8px;
      margin: 20px 0;
      border-left: 4px solid #f44336;
    }
    .reason-box {
      background: #fff3cd;
      padding: 15px;
      border-radius: 8px;
      margin: 15px 0;
      border-left: 4px solid #ff9800;
    }
    .info-row {
      margin: 10px 0;
    }
    .label {
      font-weight: bold;
      color: #666;
    }
    .value {
      color: #333;
    }
    .button {
      display: inline-block;
      padding: 12px 30px;
      background: #f44336;
      color: white;
      text-decoration: none;
      border-radius: 5px;
      margin: 20px 0;
    }
    .footer {
      text-align: center;
      margin-top: 30px;
      color: #666;
      font-size: 12px;
    }
  </style>
</head>
<body>
  <div class="header">
    <div class="warning-icon">❌</div>
    <h1>Certificação Reprovada</h1>
    <p>Confirmação de Ação Administrativa</p>
  </div>
  
  <div class="content">
    <p>Olá <strong>{{adminName}}</strong>,</p>
    
    <p>Este email confirma que você reprovou uma solicitação de certificação espiritual.</p>
    
    <div class="info-box">
      <h3>📋 Detalhes da Reprovação</h3>
      
      <div class="info-row">
        <span class="label">Usuário:</span>
        <span class="value">{{userName}}</span>
      </div>
      
      <div class="info-row">
        <span class="label">Email:</span>
        <span class="value">{{userEmail}}</span>
      </div>
      
      <div class="info-row">
        <span class="label">ID do Usuário:</span>
        <span class="value">{{userId}}</span>
      </div>
      
      <div class="info-row">
        <span class="label">ID da Certificação:</span>
        <span class="value">{{certificationId}}</span>
      </div>
      
      <div class="info-row">
        <span class="label">Data da Reprovação:</span>
        <span class="value">{{rejectionDateFormatted}}</span>
      </div>
      
      <div class="info-row">
        <span class="label">Notas:</span>
        <span class="value">{{notes}}</span>
      </div>
    </div>
    
    <div class="reason-box">
      <h4>📝 Motivo da Reprovação</h4>
      <p>{{rejectionReason}}</p>
    </div>
    
    <p><strong>O que acontece agora:</strong></p>
    <ul>
      <li>📧 O usuário receberá uma notificação com o motivo da reprovação</li>
      <li>🔄 O usuário poderá enviar uma nova solicitação</li>
      <li>📊 A ação foi registrada no log de auditoria</li>
    </ul>
    
    <center>
      <a href="{{panelLink}}" class="button">Acessar Painel Administrativo</a>
    </center>
  </div>
  
  <div class="footer">
    <p>Este é um email automático de confirmação.</p>
    <p>Sistema de Certificações Espirituais</p>
  </div>
</body>
</html>
```

---

## 📝 Template 3: Resumo Diário

### Nome do Template
`admin-daily-certification-summary`

### Assunto
`📊 Resumo Diário de Certificações - {{date}}`

### Conteúdo HTML

```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Resumo Diário</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      line-height: 1.6;
      color: #333;
      max-width: 600px;
      margin: 0 auto;
      padding: 20px;
    }
    .header {
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      color: white;
      padding: 30px;
      text-align: center;
      border-radius: 10px 10px 0 0;
    }
    .content {
      background: #f9f9f9;
      padding: 30px;
      border-radius: 0 0 10px 10px;
    }
    .stats-grid {
      display: grid;
      grid-template-columns: repeat(2, 1fr);
      gap: 15px;
      margin: 20px 0;
    }
    .stat-card {
      background: white;
      padding: 20px;
      border-radius: 8px;
      text-align: center;
      box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }
    .stat-number {
      font-size: 36px;
      font-weight: bold;
      margin: 10px 0;
    }
    .stat-label {
      color: #666;
      font-size: 14px;
    }
    .approved { color: #4CAF50; }
    .rejected { color: #f44336; }
    .pending { color: #ff9800; }
    .total { color: #2196F3; }
    .button {
      display: inline-block;
      padding: 12px 30px;
      background: #667eea;
      color: white;
      text-decoration: none;
      border-radius: 5px;
      margin: 20px 0;
    }
    .footer {
      text-align: center;
      margin-top: 30px;
      color: #666;
      font-size: 12px;
    }
  </style>
</head>
<body>
  <div class="header">
    <h1>📊 Resumo Diário</h1>
    <p>Sistema de Certificações Espirituais</p>
    <p>{{date}}</p>
  </div>
  
  <div class="content">
    <p>Olá <strong>{{adminName}}</strong>,</p>
    
    <p>Aqui está o resumo das atividades de certificação de hoje:</p>
    
    <div class="stats-grid">
      <div class="stat-card">
        <div class="stat-number approved">{{approvedCount}}</div>
        <div class="stat-label">Aprovadas</div>
      </div>
      
      <div class="stat-card">
        <div class="stat-number rejected">{{rejectedCount}}</div>
        <div class="stat-label">Reprovadas</div>
      </div>
      
      <div class="stat-card">
        <div class="stat-number pending">{{pendingCount}}</div>
        <div class="stat-label">Pendentes</div>
      </div>
      
      <div class="stat-card">
        <div class="stat-number total">{{totalProcessed}}</div>
        <div class="stat-label">Total Processadas</div>
      </div>
    </div>
    
    <p><strong>Ações Recomendadas:</strong></p>
    <ul>
      <li>{{#if pendingCount}}✅ Há {{pendingCount}} certificações aguardando análise{{else}}✅ Todas as certificações foram processadas{{/if}}</li>
      <li>📊 Verifique o painel para mais detalhes</li>
      <li>📈 Acompanhe as métricas de aprovação</li>
    </ul>
    
    <center>
      <a href="{{panelLink}}" class="button">Acessar Painel Administrativo</a>
    </center>
  </div>
  
  <div class="footer">
    <p>Este é um email automático de resumo diário.</p>
    <p>Sistema de Certificações Espirituais</p>
  </div>
</body>
</html>
```

---

## 📝 Template 4: Alerta

### Nome do Template
`admin-certification-alert`

### Assunto
`🚨 Alerta - Sistema de Certificações`

### Conteúdo HTML

```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Alerta do Sistema</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      line-height: 1.6;
      color: #333;
      max-width: 600px;
      margin: 0 auto;
      padding: 20px;
    }
    .header {
      background: linear-gradient(135deg, #ff6b6b 0%, #c92a2a 100%);
      color: white;
      padding: 30px;
      text-align: center;
      border-radius: 10px 10px 0 0;
    }
    .content {
      background: #f9f9f9;
      padding: 30px;
      border-radius: 0 0 10px 10px;
    }
    .alert-icon {
      font-size: 48px;
      margin-bottom: 10px;
    }
    .alert-box {
      background: #fff3cd;
      padding: 20px;
      border-radius: 8px;
      margin: 20px 0;
      border-left: 4px solid #ff9800;
    }
    .details-box {
      background: white;
      padding: 15px;
      border-radius: 8px;
      margin: 15px 0;
      font-family: monospace;
      font-size: 12px;
    }
    .button {
      display: inline-block;
      padding: 12px 30px;
      background: #c92a2a;
      color: white;
      text-decoration: none;
      border-radius: 5px;
      margin: 20px 0;
    }
    .footer {
      text-align: center;
      margin-top: 30px;
      color: #666;
      font-size: 12px;
    }
  </style>
</head>
<body>
  <div class="header">
    <div class="alert-icon">🚨</div>
    <h1>Alerta do Sistema</h1>
    <p>Atenção Necessária</p>
  </div>
  
  <div class="content">
    <p>Olá <strong>{{adminName}}</strong>,</p>
    
    <p>Um alerta foi gerado no sistema de certificações:</p>
    
    <div class="alert-box">
      <h3>⚠️ {{alertType}}</h3>
      <p>{{alertMessage}}</p>
    </div>
    
    {{#if details}}
    <div class="details-box">
      <strong>Detalhes:</strong>
      <pre>{{details}}</pre>
    </div>
    {{/if}}
    
    <p><strong>Timestamp:</strong> {{timestamp}}</p>
    
    <p><strong>Ação Recomendada:</strong></p>
    <ul>
      <li>🔍 Verifique o painel administrativo</li>
      <li>📊 Analise os logs de auditoria</li>
      <li>🛠️ Tome as medidas necessárias</li>
    </ul>
    
    <center>
      <a href="{{panelLink}}" class="button">Acessar Painel Imediatamente</a>
    </center>
  </div>
  
  <div class="footer">
    <p>Este é um email automático de alerta.</p>
    <p>Sistema de Certificações Espirituais</p>
  </div>
</body>
</html>
```

---

## 🔧 Como Configurar os Templates

### 1. Adicionar Templates no Firebase

Os templates devem ser configurados na extensão Firebase Email Trigger:

1. Acesse o Firebase Console
2. Vá em Extensions
3. Encontre "Trigger Email"
4. Configure os templates acima

### 2. Estrutura de Dados

Cada template espera os seguintes dados:

#### Aprovação
```javascript
{
  adminName: string,
  userName: string,
  userEmail: string,
  userId: string,
  certificationId: string,
  approvalDateFormatted: string,
  notes: string,
  panelLink: string
}
```

#### Reprovação
```javascript
{
  adminName: string,
  userName: string,
  userEmail: string,
  userId: string,
  certificationId: string,
  rejectionDateFormatted: string,
  rejectionReason: string,
  notes: string,
  panelLink: string
}
```

#### Resumo Diário
```javascript
{
  adminName: string,
  date: string,
  approvedCount: number,
  rejectedCount: number,
  pendingCount: number,
  totalProcessed: number,
  panelLink: string
}
```

#### Alerta
```javascript
{
  adminName: string,
  alertType: string,
  alertMessage: string,
  details: object,
  timestamp: string,
  panelLink: string
}
```

---

## 📧 Testando os Templates

Use o serviço para testar:

```dart
// Testar email de aprovação
await AdminConfirmationEmailService().sendApprovalConfirmation(
  certificationId: 'test123',
  userId: 'user456',
  userEmail: 'usuario@teste.com',
  userName: 'João Silva',
  adminEmail: 'admin@teste.com',
  adminName: 'Admin Teste',
  notes: 'Teste de email',
);

// Testar email de reprovação
await AdminConfirmationEmailService().sendRejectionConfirmation(
  certificationId: 'test123',
  userId: 'user456',
  userEmail: 'usuario@teste.com',
  userName: 'João Silva',
  rejectionReason: 'Comprovante ilegível',
  adminEmail: 'admin@teste.com',
  adminName: 'Admin Teste',
);
```

---

## ✅ Checklist de Implementação

- [x] Template de confirmação de aprovação
- [x] Template de confirmação de reprovação
- [x] Template de resumo diário
- [x] Template de alerta
- [x] Serviço de envio de emails
- [ ] Configurar templates no Firebase
- [ ] Testar envio de emails
- [ ] Integrar com o sistema

---

**Próximo Passo:** Configurar os templates no Firebase Console e testar o envio de emails.
