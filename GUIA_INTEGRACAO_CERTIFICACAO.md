# 🚀 Guia Rápido de Integração - Sistema de Certificação

## ⚡ Integração em 5 Minutos

### 1️⃣ Adicionar Dependências

```yaml
# pubspec.yaml
dependencies:
  firebase_storage: ^11.0.0
  image_picker: ^1.0.0
  file_picker: ^6.0.0
  cloud_functions: ^4.0.0
```

Execute:
```bash
flutter pub get
```

---

### 2️⃣ Inicializar Serviço

```dart
// lib/main.dart ou onde você inicializa os serviços GetX

import 'package:get/get.dart';
import 'services/certification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Inicializar serviço de certificação
  Get.put(CertificationService());
  
  runApp(MyApp());
}
```

---

### 3️⃣ Adicionar Botão no Perfil

```dart
// Em profile_completion_view.dart ou onde você lista as tarefas

import '../views/certification_status_view.dart';

// Adicionar card de certificação
ListTile(
  leading: Container(
    padding: EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: Color(0xFF6B46C1).withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Icon(
      Icons.verified_user,
      color: Color(0xFF6B46C1),
    ),
  ),
  title: Text('Certificação Espiritual'),
  subtitle: Text('Obtenha seu selo de verificação'),
  trailing: Icon(Icons.chevron_right),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CertificationStatusView(),
      ),
    );
  },
)
```

---

### 4️⃣ Mostrar Selo no Perfil (Opcional)

```dart
// Em profile_display_view.dart ou onde você mostra o perfil

import '../services/certification_service.dart';

class ProfileDisplayView extends StatelessWidget {
  final String userId;
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: CertificationService.to.checkCertificationStatus(userId),
      builder: (context, snapshot) {
        final hasCertification = snapshot.data ?? false;
        
        return Stack(
          children: [
            // Avatar do usuário
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(userPhotoUrl),
            ),
            
            // Selo de verificação
            if (hasCertification)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.verified,
                    color: Color(0xFF6B46C1),
                    size: 24,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
```

---

### 5️⃣ Configurar Firebase

#### A. Firestore Rules

```javascript
// firestore.rules

rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Função auxiliar para verificar se é admin
    function isAdmin() {
      return request.auth != null && 
             get(/databases/$(database)/documents/usuarios/$(request.auth.uid)).data.isAdmin == true;
    }
    
    // Regras para certification_requests
    match /certification_requests/{requestId} {
      // Usuário pode ler apenas suas próprias solicitações
      allow read: if request.auth != null && 
                  resource.data.userId == request.auth.uid;
      
      // Usuário pode criar solicitação
      allow create: if request.auth != null && 
                    request.resource.data.userId == request.auth.uid &&
                    request.resource.data.status == 'pending';
      
      // Apenas admin pode atualizar
      allow update: if isAdmin();
      
      // Admin pode ler todas
      allow list: if isAdmin();
    }
  }
}
```

#### B. Storage Rules

```javascript
// storage.rules

rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    
    // Regras para comprovantes de certificação
    match /certification_proofs/{fileName} {
      // Permitir upload apenas para usuários autenticados
      allow create: if request.auth != null &&
                    request.resource.size < 5 * 1024 * 1024 && // Máx 5MB
                    request.resource.contentType.matches('image/.*|application/pdf');
      
      // Permitir leitura para admin e dono
      allow read: if request.auth != null;
      
      // Permitir delete apenas para admin
      allow delete: if request.auth != null &&
                    get(/databases/$(database)/documents/usuarios/$(request.auth.uid)).data.isAdmin == true;
    }
  }
}
```

#### C. Criar Índices

Execute no Firebase Console ou use o link gerado automaticamente:

```javascript
// Índice 1: Buscar solicitações do usuário
Collection: certification_requests
Fields: userId (Ascending), submittedAt (Descending)

// Índice 2: Listar pendentes para admin
Collection: certification_requests
Fields: status (Ascending), submittedAt (Ascending)
```

---

## 🎯 Casos de Uso Comuns

### Verificar se Usuário Tem Certificação

```dart
final hasCertification = await CertificationService.to
    .checkCertificationStatus(userId);

if (hasCertification) {
  print('Usuário certificado! 👑');
}
```

### Obter Status da Solicitação

```dart
final service = CertificationService.to;
final request = service.currentRequest;

if (request != null) {
  print('Status: ${request.statusText}');
  print('Enviado em: ${request.submittedAt}');
  
  if (request.isPending) {
    print('Aguardando análise...');
  } else if (request.isApproved) {
    print('Aprovado! 🎉');
  }
}
```

### Escutar Mudanças em Tempo Real

```dart
CertificationService.to.watchUserRequest().listen((request) {
  if (request != null) {
    print('Status atualizado: ${request.statusText}');
    
    if (request.isApproved) {
      // Mostrar notificação de aprovação
      Get.snackbar(
        'Parabéns!',
        'Sua certificação foi aprovada! 🎉',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    }
  }
});
```

---

## 🔧 Configuração de Cloud Functions

### Criar Função para Enviar Email

```javascript
// functions/index.js

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');

admin.initializeApp();

// Configurar transporte de email
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: 'sinais.app@gmail.com',
    pass: functions.config().email.password
  }
});

// Função para notificar admin
exports.sendAdminCertificationEmail = functions.https.onCall(async (data, context) => {
  const { requestId, userDisplayName, userEmail, purchaseEmail, proofImageUrl, submittedAt } = data;
  
  const mailOptions = {
    from: 'Sinais App <sinais.app@gmail.com>',
    to: 'sinais.app@gmail.com',
    subject: `🔔 Nova Solicitação de Certificação - ${userDisplayName}`,
    html: `
      <h2>Nova Solicitação de Certificação</h2>
      <p><strong>Usuário:</strong> ${userDisplayName}</p>
      <p><strong>Email do App:</strong> ${userEmail}</p>
      <p><strong>Email da Compra:</strong> ${purchaseEmail}</p>
      <p><strong>Data:</strong> ${new Date(submittedAt).toLocaleString('pt-BR')}</p>
      <p><strong>Comprovante:</strong> <a href="${proofImageUrl}">Ver Comprovante</a></p>
      <p><a href="https://console.firebase.google.com/project/YOUR_PROJECT/firestore/data/certification_requests/${requestId}">Analisar no Firebase</a></p>
    `
  };
  
  await transporter.sendMail(mailOptions);
  return { success: true };
});

// Função para notificar aprovação
exports.sendCertificationApprovalEmail = functions.https.onCall(async (data, context) => {
  const { userEmail, userDisplayName } = data;
  
  const mailOptions = {
    from: 'Sinais App <sinais.app@gmail.com>',
    to: userEmail,
    subject: '✅ Certificação Aprovada - Parabéns!',
    html: `
      <h2>Parabéns, ${userDisplayName}!</h2>
      <p>Sua certificação espiritual foi <strong>APROVADA</strong>! 🎉</p>
      <p>Seu selo de verificação já está ativo no seu perfil.</p>
      <p>Agora você pode:</p>
      <ul>
        <li>✨ Mostrar seu selo de verificação</li>
        <li>🌟 Ter mais credibilidade na comunidade</li>
        <li>🎯 Acessar recursos exclusivos</li>
      </ul>
      <p><a href="YOUR_APP_LINK">Abrir App</a></p>
    `
  };
  
  await transporter.sendMail(mailOptions);
  return { success: true };
});
```

### Deploy das Functions

```bash
cd functions
npm install
firebase deploy --only functions
```

---

## 📱 Testando o Sistema

### 1. Teste Manual

```dart
// Criar arquivo: lib/utils/test_certification_system.dart

import 'package:flutter/material.dart';
import '../views/certification_status_view.dart';

void testCertificationSystem(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => CertificationStatusView(),
    ),
  );
}
```

### 2. Teste de Upload

```dart
// Testar upload de arquivo
final file = File('path/to/test/image.jpg');
final success = await CertificationService.to.submitRequest(
  purchaseEmail: 'test@example.com',
  proofFile: file,
);

print('Upload success: $success');
```

### 3. Verificar no Firebase

1. Abra Firebase Console
2. Vá em Firestore
3. Verifique collection `certification_requests`
4. Vá em Storage
5. Verifique pasta `certification_proofs`

---

## 🎨 Personalização

### Mudar Cores

```dart
// Em certification_request_view.dart e certification_status_view.dart

final Color _primaryColor = const Color(0xFF6B46C1); // Roxo padrão

// Altere para sua cor preferida:
final Color _primaryColor = const Color(0xFF1E88E5); // Azul
final Color _primaryColor = const Color(0xFF43A047); // Verde
final Color _primaryColor = const Color(0xFFE53935); // Vermelho
```

### Customizar Mensagens

```dart
// Em certification_service.dart

String getStatusMessage(CertificationRequestModel request) {
  switch (request.status) {
    case CertificationStatus.pending:
      return 'Sua mensagem personalizada aqui';
    // ...
  }
}
```

---

## ⚠️ Troubleshooting

### Erro: "Permission denied"
**Solução**: Verifique as regras do Firestore e Storage

### Erro: "File too large"
**Solução**: Arquivo maior que 5MB. Comprima a imagem

### Erro: "Invalid email"
**Solução**: Verifique o formato do email

### Email não enviado
**Solução**: 
1. Verifique se as Cloud Functions estão deployadas
2. Verifique as credenciais do email
3. Veja os logs no Firebase Console

---

## 📊 Monitoramento

### Ver Estatísticas

```dart
final stats = await CertificationRepository.getStatistics();

print('Pendentes: ${stats['pending']}');
print('Aprovadas: ${stats['approved']}');
print('Rejeitadas: ${stats['rejected']}');
print('Total: ${stats['total']}');
```

### Logs

```dart
// Ativar logs detalhados
CertificationService.to.enableDebugMode();
```

---

## ✅ Checklist de Integração

- [ ] Dependências adicionadas
- [ ] Serviço inicializado no main.dart
- [ ] Botão adicionado no perfil
- [ ] Firestore rules configuradas
- [ ] Storage rules configuradas
- [ ] Índices criados no Firestore
- [ ] Cloud Functions deployadas
- [ ] Email configurado
- [ ] Testado upload de arquivo
- [ ] Testado fluxo completo
- [ ] Selo aparecendo no perfil

---

## 🎉 Pronto!

Seu sistema de certificação espiritual está integrado e funcionando!

**Próximos passos**:
1. Implementar painel administrativo
2. Adicionar notificações push
3. Criar dashboard de métricas

---

**Dúvidas?** Consulte a documentação completa em `SISTEMA_CERTIFICACAO_ESPIRITUAL_IMPLEMENTADO.md`
