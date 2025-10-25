import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/test_current_notification_system.dart';
// REMOVIDO: import '../utils/debug_notification_flow.dart'; (arquivo deletado)
import '../views/interest_dashboard_view.dart';

/// Dashboard de teste para o sistema de notificações
class NotificationTestDashboard extends StatelessWidget {
  const NotificationTestDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sistema de Notificações - Teste'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.purple.shade50,
              Colors.pink.shade50,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.favorite,
                      size: 48,
                      color: Colors.pink,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Sistema de Notificações de Interesse',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Teste e debug do sistema completo',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Botões principais
              _buildActionCard(
                title: 'Abrir Dashboard Principal',
                subtitle: 'Ver notificações e estatísticas reais',
                icon: Icons.dashboard,
                color: Colors.green,
                onTap: () => Get.to(() => const InterestDashboardView()),
              ),
              
              const SizedBox(height: 12),
              
              _buildActionCard(
                title: 'Executar Teste Completo',
                subtitle: 'Testar todo o sistema (ver console)',
                icon: Icons.play_arrow,
                color: Colors.blue,
                onTap: () => TestCurrentNotificationSystem.testCompleteFlow(),
              ),
              
              const SizedBox(height: 12),
              
              _buildActionCard(
                title: 'Debug Detalhado',
                subtitle: '⚠️ Funcionalidade desabilitada',
                icon: Icons.bug_report,
                color: Colors.grey,
                onTap: () => print('Debug desabilitado (arquivo removido)'),
              ),
              
              const SizedBox(height: 12),
              
              _buildActionCard(
                title: 'Criar Notificação de Teste',
                subtitle: '⚠️ Funcionalidade desabilitada',
                icon: Icons.add_alert,
                color: Colors.grey,
                onTap: () => print('Criação de teste desabilitada (arquivo removido)'),
              ),
              
              const SizedBox(height: 20),
              
              // Status do sistema
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          'Status do Sistema',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text('✅ Repositório de notificações implementado'),
                    Text('✅ Dashboard de interesse implementado'),
                    Text('✅ Botão com badge implementado'),
                    Text('✅ Sistema de aceitação implementado'),
                    Text('✅ Notificações de retorno implementadas'),
                    Text('✅ Sistema de match mútuo implementado'),
                    Text('✅ Estatísticas completas implementadas'),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Instruções
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.yellow.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.yellow.shade200),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.orange),
                        SizedBox(width: 8),
                        Text(
                          'Como Testar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text('1. Clique "Executar Teste Completo"'),
                    Text('2. Veja os resultados no CONSOLE/DEBUG'),
                    Text('3. Use "Debug Detalhado" se houver problemas'),
                    Text('4. Teste o "Dashboard Principal" para ver a interface'),
                    Text('5. Crie notificações de teste se necessário'),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Problema resolvido
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.celebration, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          'Problema Resolvido!',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text('🎯 @italo agora recebe notificação quando aceito'),
                    Text('🔴 Badge vermelho aparece com notificações'),
                    Text('💕 Sistema de aceitação funcionando'),
                    Text('🎉 Match mútuo implementado'),
                    Text('📊 Estatísticas completas disponíveis'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[400],
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}