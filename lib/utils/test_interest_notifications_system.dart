import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:whatsapp_chat/components/interest_notifications_component.dart';
import 'package:whatsapp_chat/components/interest_button_component.dart';
import 'package:whatsapp_chat/repositories/interest_notification_repository.dart';

/// Tela de teste para o sistema de notificações de interesse
class TestInterestNotificationsSystem extends StatefulWidget {
  const TestInterestNotificationsSystem({super.key});

  @override
  State<TestInterestNotificationsSystem> createState() => _TestInterestNotificationsSystemState();
}

class _TestInterestNotificationsSystemState extends State<TestInterestNotificationsSystem> {
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId != null) {
        final count = await InterestNotificationRepository.getUnreadNotificationsCount(currentUserId);
        setState(() {
          _unreadCount = count;
        });
      }
    } catch (e) {
      print('Erro ao carregar contador: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teste - Sistema de Interesse'),
        backgroundColor: const Color(0xFFfc6aeb),
        foregroundColor: Colors.white,
        actions: [
          if (_unreadCount > 0)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$_unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            Text(
              '🎯 Sistema de Notificações de Interesse',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFFfc6aeb),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Baseado no sistema funcional de convites do "Nosso Propósito"',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),

            // Status do usuário atual
            _buildCurrentUserStatus(),
            const SizedBox(height: 24),

            // Componente de notificações (mesmo design dos convites)
            const InterestNotificationsComponent(),
            const SizedBox(height: 24),

            // Seção de testes
            _buildTestSection(),
            const SizedBox(height: 24),

            // Botões de ação
            _buildActionButtons(),
            const SizedBox(height: 24),

            // Estatísticas
            _buildStatsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentUserStatus() {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                'Usuário Atual',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Nome: ${currentUser?.displayName ?? 'Não informado'}'),
          Text('Email: ${currentUser?.email ?? 'Não informado'}'),
          Text('ID: ${currentUser?.uid ?? 'Não logado'}'),
          Text('Notificações não lidas: $_unreadCount'),
        ],
      ),
    );
  }

  Widget _buildTestSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.science, color: Colors.green),
              const SizedBox(width: 8),
              Text(
                'Teste de Interesse',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Exemplo de botão de interesse
          Text(
            'Exemplo de botão "Tenho Interesse":',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          
          // Botão de teste (usando IDs de exemplo)
          InterestButtonComponent(
            targetUserId: 'St2kw3cgX2MMPxlLRmBDjYm2nO22', // ID da @itala3
            targetUserName: 'Itala',
            targetUserEmail: 'itala@gmail.com',
            onInterestSent: () {
              _loadUnreadCount(); // Recarregar contador
              Get.snackbar(
                'Teste Realizado! ✅',
                'Interesse enviado para Itala. Verifique se ela recebeu a notificação!',
                backgroundColor: Colors.green,
                colorText: Colors.white,
                duration: const Duration(seconds: 3),
              );
            },
          ),
          
          const SizedBox(height: 12),
          Text(
            '💡 Este botão envia uma notificação de interesse para @itala3. Se você for a @itala3, verá a notificação aparecer acima!',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.green.shade700,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ações de Teste',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _loadUnreadCount,
                icon: const Icon(Icons.refresh),
                label: const Text('Atualizar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _showStats,
                icon: const Icon(Icons.analytics),
                label: const Text('Estatísticas'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _testCreateInterest,
            icon: const Icon(Icons.favorite),
            label: const Text('Criar Interesse de Teste'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFfc6aeb),
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics, color: Colors.purple),
              const SizedBox(width: 8),
              Text(
                'Como Funciona',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.purple.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          _buildHowItWorksStep('1', 'Usuário clica "Tenho Interesse"', Icons.favorite),
          _buildHowItWorksStep('2', 'Notificação é salva no Firebase', Icons.cloud_upload),
          _buildHowItWorksStep('3', 'Destinatário recebe em tempo real', Icons.notifications),
          _buildHowItWorksStep('4', 'Pode responder: "Também Tenho", "Não Tenho" ou "Ver Perfil"', Icons.reply),
          _buildHowItWorksStep('5', 'Se ambos têm interesse = Match! 💕', Icons.celebration),
        ],
      ),
    );
  }

  Widget _buildHowItWorksStep(String number, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.purple.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(icon, size: 16, color: Colors.purple.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.purple.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showStats() async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) {
        Get.snackbar('Erro', 'Usuário não está logado');
        return;
      }

      final stats = await InterestNotificationRepository.getUserInterestStats(currentUserId);
      
      Get.dialog(
        AlertDialog(
          title: const Text('📊 Suas Estatísticas'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('💕 Interesses enviados: ${stats['sent']}'),
              Text('💌 Interesses recebidos: ${stats['received']}'),
              Text('✅ Seus interesses aceitos: ${stats['acceptedSent']}'),
              Text('💖 Interesses que você aceitou: ${stats['acceptedReceived']}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Fechar'),
            ),
          ],
        ),
      );
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao carregar estatísticas: $e');
    }
  }

  void _testCreateInterest() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        Get.snackbar('Erro', 'Usuário não está logado');
        return;
      }

      // Criar interesse de teste para @itala3
      await InterestNotificationRepository.createInterestNotification(
        fromUserId: currentUser.uid,
        fromUserName: currentUser.displayName ?? 'Usuário Teste',
        fromUserEmail: currentUser.email ?? 'teste@teste.com',
        toUserId: 'St2kw3cgX2MMPxlLRmBDjYm2nO22', // ID da @itala3
        toUserEmail: 'itala@gmail.com',
        message: 'Interesse de teste criado através do sistema! 💕',
      );

      _loadUnreadCount();
      
      Get.snackbar(
        'Teste Criado! ✅',
        'Interesse de teste enviado para @itala3',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Erro',
        e.toString().replaceAll('Exception: ', ''),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}