# Design Document - Sistema de Aprovação de Certificação Espiritual

## Overview

O sistema de aprovação de certificações será implementado usando uma arquitetura híbrida que combina Cloud Functions (para processamento de links de email), Firestore (para armazenamento de dados), e componentes Flutter (para interface administrativa e exibição de selos). O fluxo principal permite que administradores aprovem/reprovem certificações tanto via links de email quanto via painel administrativo, com notificações automáticas sendo enviadas aos usuários e selos sendo exibidos visualmente nos perfis aprovados.

## Architecture

### System Components

```
┌─────────────────────────────────────────────────────────────┐
│                     Email com Links                          │
│  [Aprovar Certificação] [Reprovar Certificação]             │
└────────────┬────────────────────────────┬───────────────────┘
             │                            │
             ▼                            ▼
┌────────────────────────┐    ┌──────────────────────────────┐
│  Cloud Function        │    │  Cloud Function              │
│  processApproval()     │    │  processRejection()          │
└────────────┬───────────┘    └──────────┬───────────────────┘
             │                            │
             └────────────┬───────────────┘
                          ▼
              ┌───────────────────────┐
              │   Firestore Update    │
              │   certifications/     │
              │   {requestId}         │
              └───────────┬───────────┘
                          │
          ┌───────────────┴───────────────┐
          ▼                               ▼
┌─────────────────────┐        ┌──────────────────────┐
│  Trigger Function   │        │  Admin Panel         │
│  onStatusChange()   │        │  (Real-time Update)  │
└─────────┬───────────┘        └──────────────────────┘
          │
          ├─────► Create User Notification
          ├─────► Update User Profile (add badge)
          ├─────► Send Confirmation Email to Admin
          └─────► Log Audit Trail
```

### Data Flow

1. **Email Link Click** → Cloud Function validates token → Updates Firestore
2. **Admin Panel Action** → Direct Firestore update → Triggers Cloud Function
3. **Status Change** → Notification created → User profile updated → Emails sent
4. **Profile View** → Reads certification status → Displays badge if approved

## Components and Interfaces

### 1. Cloud Functions

#### `processApproval(requestId, token)`
```javascript
// functions/index.js
exports.processApproval = functions.https.onRequest(async (req, res) => {
  const { requestId, token } = req.query;
  
  // Validate token
  const isValid = await validateToken(requestId, token);
  if (!isValid) {
    return res.status(403).send('Token inválido ou expirado');
  }
  
  // Check if already processed
  const certDoc = await admin.firestore()
    .collection('certifications')
    .doc(requestId)
    .get();
    
  if (certDoc.data().status !== 'pending') {
    return res.send('Esta solicitação já foi processada');
  }
  
  // Update certification status
  await admin.firestore()
    .collection('certifications')
    .doc(requestId)
    .update({
      status: 'approved',
      approvedAt: admin.firestore.FieldValue.serverTimestamp(),
      approvedBy: 'email_link',
      processedVia: 'email'
    });
  
  // Mark token as used
  await markTokenAsUsed(requestId, token);
  
  // Return success page
  res.send(generateSuccessPage('aprovada'));
});
```

#### `processRejection(requestId, token, reason)`
```javascript
exports.processRejection = functions.https.onRequest(async (req, res) => {
  const { requestId, token } = req.query;
  
  if (req.method === 'GET') {
    // Show rejection reason form
    return res.send(generateRejectionForm(requestId, token));
  }
  
  if (req.method === 'POST') {
    const { reason } = req.body;
    
    // Validate token
    const isValid = await validateToken(requestId, token);
    if (!isValid) {
      return res.status(403).send('Token inválido ou expirado');
    }
    
    // Update certification status
    await admin.firestore()
      .collection('certifications')
      .doc(requestId)
      .update({
        status: 'rejected',
        rejectedAt: admin.firestore.FieldValue.serverTimestamp(),
        rejectedBy: 'email_link',
        rejectionReason: reason,
        processedVia: 'email'
      });
    
    // Mark token as used
    await markTokenAsUsed(requestId, token);
    
    // Return success page
    return res.send(generateSuccessPage('reprovada'));
  }
});
```

#### `onCertificationStatusChange()`
```javascript
exports.onCertificationStatusChange = functions.firestore
  .document('certifications/{requestId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    
    // Only process if status changed from pending
    if (before.status === 'pending' && after.status !== 'pending') {
      const { userId, status, rejectionReason } = after;
      
      // Create notification for user
      await createUserNotification(userId, status, rejectionReason);
      
      // Update user profile if approved
      if (status === 'approved') {
        await updateUserProfile(userId, { spirituallyCertified: true });
      }
      
      // Send confirmation email to admin
      await sendAdminConfirmationEmail(after);
      
      // Log audit trail
      await logAuditTrail(context.params.requestId, after);
    }
  });
```

### 2. Flutter Services

#### `CertificationApprovalService`
```dart
class CertificationApprovalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Approve certification from admin panel
  Future<void> approveCertification(String requestId, String adminId) async {
    await _firestore.collection('certifications').doc(requestId).update({
      'status': 'approved',
      'approvedAt': FieldValue.serverTimestamp(),
      'approvedBy': adminId,
      'processedVia': 'admin_panel',
    });
  }
  
  // Reject certification from admin panel
  Future<void> rejectCertification(
    String requestId,
    String adminId,
    String reason,
  ) async {
    await _firestore.collection('certifications').doc(requestId).update({
      'status': 'rejected',
      'rejectedAt': FieldValue.serverTimestamp(),
      'rejectedBy': adminId,
      'rejectionReason': reason,
      'processedVia': 'admin_panel',
    });
  }
  
  // Get pending certifications (real-time)
  Stream<List<CertificationRequest>> getPendingCertifications() {
    return _firestore
        .collection('certifications')
        .where('status', isEqualTo: 'pending')
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CertificationRequest.fromFirestore(doc))
            .toList());
  }
  
  // Get certification history
  Stream<List<CertificationRequest>> getCertificationHistory({
    String? statusFilter,
    String? userIdFilter,
  }) {
    Query query = _firestore.collection('certifications');
    
    if (statusFilter != null) {
      query = query.where('status', isEqualTo: statusFilter);
    }
    
    if (userIdFilter != null) {
      query = query.where('userId', isEqualTo: userIdFilter);
    }
    
    return query
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CertificationRequest.fromFirestore(doc))
            .toList());
  }
}
```

#### `CertificationNotificationService`
```dart
class CertificationNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Create notification for user (called by Cloud Function)
  Future<void> createCertificationNotification(
    String userId,
    String status,
    String? rejectionReason,
  ) async {
    final notificationData = {
      'userId': userId,
      'type': status == 'approved' 
          ? 'certification_approved' 
          : 'certification_rejected',
      'title': status == 'approved'
          ? 'Certificação Aprovada! ✅'
          : 'Certificação Não Aprovada',
      'message': status == 'approved'
          ? 'Sua certificação espiritual foi aprovada! Seu selo já está visível no seu perfil.'
          : 'Sua solicitação de certificação não foi aprovada. Motivo: $rejectionReason',
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
      'actionType': status == 'approved' ? 'view_profile' : 'retry_certification',
    };
    
    await _firestore
        .collection('notifications')
        .add(notificationData);
  }
  
  // Handle notification tap
  void handleNotificationTap(BuildContext context, NotificationModel notification) {
    if (notification.actionType == 'view_profile') {
      Get.toNamed('/profile');
    } else if (notification.actionType == 'retry_certification') {
      Get.toNamed('/spiritual-certification-request');
    }
  }
}
```

### 3. Flutter Components

#### `CertificationApprovalPanelView`
```dart
class CertificationApprovalPanelView extends StatelessWidget {
  final CertificationApprovalService _service = Get.find();
  
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Painel de Certificações'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Pendentes'),
              Tab(text: 'Histórico'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildPendingTab(),
            _buildHistoryTab(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPendingTab() {
    return StreamBuilder<List<CertificationRequest>>(
      stream: _service.getPendingCertifications(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Nenhuma solicitação pendente'),
              ],
            ),
          );
        }
        
        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            return CertificationRequestCard(
              request: snapshot.data![index],
              onApprove: () => _handleApprove(snapshot.data![index]),
              onReject: () => _handleReject(snapshot.data![index]),
            );
          },
        );
      },
    );
  }
  
  Widget _buildHistoryTab() {
    return StreamBuilder<List<CertificationRequest>>(
      stream: _service.getCertificationHistory(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        
        return ListView.builder(
          itemCount: snapshot.data?.length ?? 0,
          itemBuilder: (context, index) {
            return CertificationHistoryCard(
              request: snapshot.data![index],
            );
          },
        );
      },
    );
  }
  
  Future<void> _handleApprove(CertificationRequest request) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('Confirmar Aprovação'),
        content: Text('Deseja aprovar a certificação de ${request.userName}?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: Text('Aprovar'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await _service.approveCertification(
        request.id,
        FirebaseAuth.instance.currentUser!.uid,
      );
      
      Get.snackbar(
        'Sucesso',
        'Certificação aprovada com sucesso!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    }
  }
  
  Future<void> _handleReject(CertificationRequest request) async {
    final TextEditingController reasonController = TextEditingController();
    
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('Reprovar Certificação'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Informe o motivo da reprovação:'),
            SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Ex: Comprovante ilegível',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Reprovar'),
          ),
        ],
      ),
    );
    
    if (confirmed == true && reasonController.text.isNotEmpty) {
      await _service.rejectCertification(
        request.id,
        FirebaseAuth.instance.currentUser!.uid,
        reasonController.text,
      );
      
      Get.snackbar(
        'Certificação Reprovada',
        'O usuário será notificado',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    }
  }
}
```

#### `CertificationRequestCard`
```dart
class CertificationRequestCard extends StatelessWidget {
  final CertificationRequest request;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  
  const CertificationRequestCard({
    required this.request,
    required this.onApprove,
    required this.onReject,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Icon(Icons.person),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.userName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        request.userEmail,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildInfoRow('Email de Compra', request.purchaseEmail),
            _buildInfoRow('Data da Solicitação', _formatDate(request.requestedAt)),
            SizedBox(height: 16),
            InkWell(
              onTap: () => _viewProof(context),
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Clique para ver comprovante'),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onReject,
                    icon: Icon(Icons.close),
                    label: Text('Reprovar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onApprove,
                    icon: Icon(Icons.check),
                    label: Text('Aprovar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }
  
  void _viewProof(BuildContext context) {
    Get.to(() => CertificationProofViewerView(
      proofUrl: request.proofUrl,
    ));
  }
  
  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }
}
```

#### `SpiritualCertificationBadge`
```dart
class SpiritualCertificationBadge extends StatelessWidget {
  final bool isCertified;
  final VoidCallback? onTap;
  
  const SpiritualCertificationBadge({
    required this.isCertified,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    if (!isCertified) return SizedBox.shrink();
    
    return GestureDetector(
      onTap: onTap ?? () => _showCertificationInfo(context),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.verified,
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 6),
            Text(
              'Certificado Espiritualmente',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showCertificationInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.verified, color: Colors.orange),
            SizedBox(width: 8),
            Text('Certificação Espiritual'),
          ],
        ),
        content: Text(
          'Este usuário possui certificação espiritual verificada, '
          'confirmando sua participação em cursos e práticas espirituais.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Entendi'),
          ),
        ],
      ),
    );
  }
}
```

## Data Models

### CertificationRequest Model
```dart
class CertificationRequest {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String purchaseEmail;
  final String proofUrl;
  final String status; // 'pending', 'approved', 'rejected'
  final Timestamp requestedAt;
  final Timestamp? approvedAt;
  final Timestamp? rejectedAt;
  final String? approvedBy;
  final String? rejectedBy;
  final String? rejectionReason;
  final String? processedVia; // 'email', 'admin_panel'
  
  CertificationRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.purchaseEmail,
    required this.proofUrl,
    required this.status,
    required this.requestedAt,
    this.approvedAt,
    this.rejectedAt,
    this.approvedBy,
    this.rejectedBy,
    this.rejectionReason,
    this.processedVia,
  });
  
  factory CertificationRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CertificationRequest(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userEmail: data['userEmail'] ?? '',
      purchaseEmail: data['purchaseEmail'] ?? '',
      proofUrl: data['proofUrl'] ?? '',
      status: data['status'] ?? 'pending',
      requestedAt: data['requestedAt'] ?? Timestamp.now(),
      approvedAt: data['approvedAt'],
      rejectedAt: data['rejectedAt'],
      approvedBy: data['approvedBy'],
      rejectedBy: data['rejectedBy'],
      rejectionReason: data['rejectionReason'],
      processedVia: data['processedVia'],
    );
  }
}
```

## Error Handling

### Token Validation Errors
- Invalid token → Display error page with link to admin panel
- Expired token → Display message to use admin panel
- Already used token → Display message that action was already processed

### Network Errors
- Offline during approval → Queue action and retry when online
- Firestore write failure → Display error and allow retry
- Cloud Function timeout → Implement retry logic with exponential backoff

### User Experience Errors
- Missing rejection reason → Prevent submission until provided
- Concurrent processing → Lock document during processing
- Notification delivery failure → Log error but don't block approval

## Testing Strategy

### Unit Tests
- Test token generation and validation logic
- Test certification status transitions
- Test notification creation logic
- Test badge visibility logic

### Integration Tests
- Test complete approval flow (email link → Firestore → notification)
- Test complete rejection flow with reason
- Test admin panel approval flow
- Test real-time updates in admin panel
- Test badge display on profile after approval

### Manual Testing Checklist
1. Send test certification request
2. Receive email with action buttons
3. Click "Aprovar" link → Verify success page
4. Check Firestore for status update
5. Verify user receives notification
6. Verify badge appears on profile
7. Test rejection flow with reason
8. Test admin panel approval
9. Test concurrent admin actions
10. Test token expiration

## Security Considerations

### Token Security
- Use crypto.randomBytes() for token generation
- Store token hash in Firestore, not plain text
- Set 7-day expiration on tokens
- Mark tokens as used after first use
- Log all token validation attempts

### Admin Authorization
- Verify admin role before showing panel
- Check admin permissions on every action
- Log all admin actions with timestamp and IP
- Implement rate limiting on approval endpoints

### Data Privacy
- Only show certification data to authorized admins
- Redact sensitive info in logs
- Implement proper Firestore security rules
- Encrypt proof URLs in transit

## Performance Optimization

### Caching Strategy
- Cache pending certifications count for badge
- Cache user certification status for profile display
- Invalidate cache on status change

### Query Optimization
- Index on status + requestedAt for pending list
- Index on userId for user history
- Limit history queries to last 100 records
- Use pagination for large result sets

### Real-time Updates
- Use Firestore listeners only for active views
- Unsubscribe from listeners when view is disposed
- Batch multiple updates when possible
