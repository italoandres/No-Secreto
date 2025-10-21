import 'package:flutter/material.dart';
import '../services/robust_notification_handler.dart';
import '../components/robust_conversar_button.dart';

/// Componente robusto para notificações de interesse que evita duplicatas
class RobustInterestNotification extends StatefulWidget {
  final Map<String, dynamic> notificationData;
  final VoidCallback? onNotificationUpdated;

  const RobustInterestNotification({
    Key? key,
    required this.notificationData,
    this.onNotificationUpdated,
  }) : super(key: key);

  @override
  _RobustInterestNotificationState createState() => _RobustInterestNotificationState();
}

class _RobustInterestNotificationState extends State<RobustInterestNotification> {
  bool _isProcessing = false;
  String? _currentStatus;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.notificationData['status'];
  }

  Future<void> _handleResponse(String action) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final notificationId = widget.notificationData['id'] ?? 
                           widget.notificationData['notificationId'];
      
      if (notificationId == null) {
        _showError('ID da notificação não encontrado');
        return;
      }

      print('📝 Processando resposta: $action para notificação: $notificationId');

      // Verificar se já foi respondida
      final alreadyResponded = await RobustNotificationHandler
          .isNotificationAlreadyResponded(notificationId);

      if (alreadyResponded && _currentStatus != 'pending') {
        print('ℹ️ Notificação já foi respondida, tratando graciosamente');
        _showInfo('Esta notificação já foi processada');
        return;
      }

      // Processar resposta
      await RobustNotificationHandler.respondToNotification(notificationId, action);

      // Atualizar estado local
      setState(() {
        _currentStatus = action;
      });

      // Mostrar feedback
      if (action == 'accepted') {
        _showSuccess('Interesse aceito! 💕');
      } else {
        _showInfo('Resposta enviada');
      }

      // Chamar callback se fornecido
      if (widget.onNotificationUpdated != null) {
        widget.onNotificationUpdated!();
      }

    } catch (e) {
      print('❌ Erro ao processar resposta: $e');
      
      // Não mostrar erro se for duplicata
      if (e.toString().contains('já foi respondida')) {
        _showInfo('Esta notificação já foi processada');
      } else {
        _showError('Erro ao processar resposta. Tente novamente.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showInfo(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fromUserName = widget.notificationData['fromUserName'] ?? 'Usuário';
    final message = widget.notificationData['message'] ?? 'Tem interesse em você';
    final fromUserId = widget.notificationData['fromUserId'];

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Text(
                    fromUserName.isNotEmpty ? fromUserName[0].toUpperCase() : 'U',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fromUserName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        message,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                // Indicador de status
                if (_currentStatus != null && _currentStatus != 'pending')
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _currentStatus == 'accepted' ? Colors.green : Colors.grey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _currentStatus == 'accepted' ? 'Aceito' : 'Rejeitado',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),

            SizedBox(height: 16),

            // Ações
            if (_currentStatus == 'pending') ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : () => _handleResponse('rejected'),
                      icon: _isProcessing
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(Icons.close),
                      label: Text('Rejeitar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : () => _handleResponse('accepted'),
                      icon: _isProcessing
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(Icons.favorite),
                      label: Text('Aceitar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (_currentStatus == 'accepted' && fromUserId != null) ...[
              // Mostrar botão conversar se foi aceito
              Center(
                child: RobustConversarButton(
                  otherUserId: fromUserId,
                  otherUserName: fromUserName,
                  onChatCreated: () {
                    _showSuccess('Chat criado! Você pode conversar agora 💬');
                  },
                ),
              ),
            ] else ...[
              // Status final
              Center(
                child: Text(
                  _currentStatus == 'accepted' 
                      ? '💕 Interesse aceito!' 
                      : '❌ Interesse rejeitado',
                  style: TextStyle(
                    color: _currentStatus == 'accepted' ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],

            // Indicador de processamento
            if (_isProcessing) ...[
              SizedBox(height: 8),
              Center(
                child: Text(
                  'Processando...',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Lista robusta de notificações de interesse
class RobustInterestNotificationsList extends StatefulWidget {
  final String userId;

  const RobustInterestNotificationsList({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  _RobustInterestNotificationsListState createState() => _RobustInterestNotificationsListState();
}

class _RobustInterestNotificationsListState extends State<RobustInterestNotificationsList> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('interests')
          .where('toUserId', isEqualTo: widget.userId)
          .orderBy('dataCriacao', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Erro ao carregar notificações'),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: Text('Tentar Novamente'),
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final notifications = snapshot.data?.docs ?? [];

        if (notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Nenhuma notificação ainda',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notificationDoc = notifications[index];
            final notificationData = {
              'id': notificationDoc.id,
              ...notificationDoc.data() as Map<String, dynamic>,
            };

            return RobustInterestNotification(
              notificationData: notificationData,
              onNotificationUpdated: () {
                // Refresh da lista se necessário
                setState(() {});
              },
            );
          },
        );
      },
    );
  }
}