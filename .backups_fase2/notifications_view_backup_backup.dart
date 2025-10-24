import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:whatsapp_chat/models/notification_model.dart';
import 'package:whatsapp_chat/services/notification_service.dart';
import 'package:whatsapp_chat/components/notification_item_component.dart';
import 'package:whatsapp_chat/views/story_favorites_view.dart';
import 'package:whatsapp_chat/utils/test_notifications.dart';

class NotificationsView extends StatefulWidget {
  final String? contexto; // Contexto de onde foi chamada (principal, sinais_rebeca, sinais_isaque)
  
  const NotificationsView({Key? key, this.contexto}) : super(key: key);

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  final ScrollController _scrollController = ScrollController();
  bool _isMarkingAsRead = false;

  @override
  void initState() {
    super.initState();
    _markAllAsReadAfterDelay();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Marcar todas as notificações como lidas após um pequeno delay
  void _markAllAsReadAfterDelay() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && !_isMarkingAsRead) {
        _markAllAsRead();
      }
    });
  }

  // Marcar todas as notificações como lidas
  Future<void> _markAllAsRead() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || _isMarkingAsRead) return;

    setState(() {
      _isMarkingAsRead = true;
    });

    try {
      // Se há contexto específico, marcar apenas notificações desse contexto
      if (widget.contexto != null) {
        await NotificationService.markContextNotificationsAsRead(currentUser.uid, widget.contexto!);
      } else {
        await NotificationService.markAllNotificationsAsRead(currentUser.uid);
      }
    } catch (e) {
      print('Erro ao marcar notificações como lidas: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isMarkingAsRead = false;
        });
      }
    }
  }

  // Refresh das notificações
  Future<void> _onRefresh() async {
    // Aguardar um pouco para simular o refresh
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Marcar todas como lidas novamente
    await _markAllAsRead();
  }

  // Cor do ícone de bookmark baseada no contexto
  Color _getBookmarkColor() {
    switch (widget.contexto) {
      case 'sinais_rebeca':
        return const Color(0xFF38b6ff); // Azul para Sinais Rebeca
      case 'sinais_isaque':
        return const Color(0xFFf76cec); // Rosa para Sinais Isaque
      case 'nosso_proposito':
        return Colors.amber.shade700; // Dourado para Nosso Propósito
      default:
        return Colors.white; // Branco para Principal
    }
  }

  // Construir ícone de bookmark customizado
  Widget _buildBookmarkIcon() {
    if (widget.contexto == 'nosso_proposito') {
      // Ícone metade azul e metade rosa para Nosso Propósito
      return SizedBox(
        width: 24,
        height: 24,
        child: Stack(
          children: [
            // Metade esquerda azul
            Positioned(
              left: 0,
              top: 0,
              child: ClipRect(
                child: Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: 0.5,
                  child: Icon(
                    Icons.bookmark,
                    color: const Color(0xFF38b6ff), // Azul
                    size: 24,
                  ),
                ),
              ),
            ),
            // Metade direita rosa
            Positioned(
              right: 0,
              top: 0,
              child: ClipRect(
                child: Align(
                  alignment: Alignment.centerRight,
                  widthFactor: 0.5,
                  child: Icon(
                    Icons.bookmark,
                    color: const Color(0xFFf76cec), // Rosa
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Ícone normal para outros contextos
      return Icon(
        Icons.bookmark,
        color: _getBookmarkColor(),
        size: 24,
      );
    }
  }

  // Título da AppBar baseado no contexto
  String _getAppBarTitle() {
    switch (widget.contexto) {
      case 'nosso_proposito':
        return 'Notificações - Nosso Propósito';
      case 'sinais_rebeca':
        return 'Notificações - Sinais de Rebeca';
      case 'sinais_isaque':
        return 'Notificações - Sinais de Isaque';
      default:
        return 'Notificações';
    }
  }

  // Título do estado vazio baseado no contexto
  String _getEmptyStateTitle() {
    switch (widget.contexto) {
      case 'nosso_proposito':
        return 'Nenhuma notificação do Propósito';
      case 'sinais_rebeca':
        return 'Nenhuma notificação de Rebeca';
      case 'sinais_isaque':
        return 'Nenhuma notificação de Isaque';
      default:
        return 'Nenhuma notificação ainda';
    }
  }

  // Mensagem do estado vazio baseada no contexto
  String _getEmptyStateMessage() {
    switch (widget.contexto) {
      case 'nosso_proposito':
        return 'Você receberá notificações quando\nalguém interagir com stories do\nNosso Propósito';
      case 'sinais_rebeca':
        return 'Você receberá notificações quando\nalguém interagir com stories dos\nSinais de Rebeca';
      case 'sinais_isaque':
        return 'Você receberá notificações quando\nalguém interagir com stories dos\nSinais de Isaque';
      default:
        return 'Você receberá notificações quando\nalguém interagir com seus stories';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Notificações'),
          backgroundColor: Colors.amber.shade700,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Usuário não autenticado'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          _getAppBarTitle(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.amber.shade700,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        actions: [
          // Botão direto para Stories Favoritos (contexto dinâmico)
          IconButton(
            onPressed: () {
              final contextoAtual = widget.contexto ?? 'principal';
              print('🔔 BOTÃO NOTIFICAÇÕES: Abrindo favoritos do contexto: $contextoAtual');
              Get.to(() => StoryFavoritesView(contexto: contextoAtual));
            },
            icon: _buildBookmarkIcon(),
            tooltip: 'Stories Salvos',
          ),
          
          // Botão para marcar todas como lidas
          if (!_isMarkingAsRead)
            IconButton(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all, color: Colors.white),
              tooltip: 'Marcar todas como lidas',
            ),
          
          // Indicador de loading
          if (_isMarkingAsRead)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: widget.contexto != null 
          ? NotificationService.getContextNotifications(currentUser.uid, widget.contexto!)
          : NotificationService.getUserNotifications(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Erro ao carregar notificações',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tente novamente mais tarde',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {}); // Força rebuild para tentar novamente
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade700,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Tentar Novamente'),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return RefreshIndicator(
              onRefresh: _onRefresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Container(
                  height: MediaQuery.of(context).size.height - 200,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none,
                          size: 80,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _getEmptyStateTitle(),
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getEmptyStateMessage(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade400,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Botões de teste (apenas para debug)
                        TestNotifications.buildTestButton(),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length + 1, // +1 para o painel de teste
              itemBuilder: (context, index) {
                // Se é o último item, mostrar painel de teste
                if (index == notifications.length) {
                  return TestNotifications.buildTestButton();
                }
                
                final notification = notifications[index];
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: NotificationItemComponent(
                    notification: notification,
                    onTap: () => _handleNotificationTap(notification),
                    onDelete: () => _handleNotificationDelete(notification),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  // Lidar com tap na notificação
  void _handleNotificationTap(NotificationModel notification) async {
    try {
      await NotificationService.handleNotificationTap(notification);
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível abrir a notificação',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Lidar com exclusão de notificação
  void _handleNotificationDelete(NotificationModel notification) async {
    // Mostrar diálogo de confirmação
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Excluir Notificação'),
        content: const Text('Tem certeza que deseja excluir esta notificação?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await NotificationService.deleteNotification(notification.id);
        
        Get.snackbar(
          'Sucesso',
          'Notificação excluída',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      } catch (e) {
        Get.snackbar(
          'Erro',
          'Não foi possível excluir a notificação',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }
}