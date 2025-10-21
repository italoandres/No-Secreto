import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:whatsapp_chat/controllers/unified_notification_controller.dart';
import 'package:whatsapp_chat/views/notifications_view.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationIconComponent extends StatelessWidget {
  final String? contexto; // Contexto de onde está sendo usado
  
  const NotificationIconComponent({Key? key, this.contexto}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser == null) {
      return const SizedBox.shrink();
    }

    // Inicializar o controller se ainda não foi
    final controller = Get.put(UnifiedNotificationController());

    return Obx(() {
      // Somar todas as 3 categorias para o badge total
      final unreadCount = controller.storiesUnreadCount.value + 
                         controller.interestUnreadCount.value + 
                         controller.systemUnreadCount.value;
      
      return GestureDetector(
        onTap: () {
          Get.to(() => const NotificationsView());
        },
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Stack(
            children: [
              // Ícone de sino
              Icon(
                Icons.notifications_outlined,
                color: Colors.white,
                size: 28,
              ),
              
              // Badge com contador (só aparece se houver notificações)
              if (unreadCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white,
                        width: 1,
                      ),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }
}

// Versão alternativa com animação de pulse quando há notificações
class AnimatedNotificationIconComponent extends StatefulWidget {
  const AnimatedNotificationIconComponent({Key? key}) : super(key: key);

  @override
  State<AnimatedNotificationIconComponent> createState() => _AnimatedNotificationIconComponentState();
}

class _AnimatedNotificationIconComponentState extends State<AnimatedNotificationIconComponent>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _startPulseAnimation() {
    _animationController.repeat(reverse: true);
  }

  void _stopPulseAnimation() {
    _animationController.stop();
    _animationController.reset();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser == null) {
      return const SizedBox.shrink();
    }

    // Inicializar o controller se ainda não foi
    final controller = Get.put(UnifiedNotificationController());

    return Obx(() {
      // Somar todas as 3 categorias para o badge total
      final unreadCount = controller.storiesUnreadCount.value + 
                         controller.interestUnreadCount.value + 
                         controller.systemUnreadCount.value;
      
      // Controlar animação baseado nas notificações
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (unreadCount > 0) {
          _startPulseAnimation();
        } else {
          _stopPulseAnimation();
        }
      });
      
      return GestureDetector(
        onTap: () {
          _stopPulseAnimation();
          Get.to(() => const NotificationsView());
        },
        child: Container(
          padding: const EdgeInsets.all(8),
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: unreadCount > 0 ? _scaleAnimation.value : 1.0,
                child: Stack(
                  children: [
                    // Ícone de sino
                    Icon(
                      Icons.notifications_outlined,
                      color: Colors.white,
                      size: 28,
                    ),
                    
                    // Badge com contador
                    if (unreadCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white,
                              width: 1,
                            ),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    });
  }
}

// Componente simples para usar em outros lugares
class SimpleNotificationIcon extends StatelessWidget {
  final Color? iconColor;
  final double? iconSize;
  final VoidCallback? onTap;

  const SimpleNotificationIcon({
    Key? key,
    this.iconColor,
    this.iconSize,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser == null) {
      return const SizedBox.shrink();
    }

    // Inicializar o controller se ainda não foi
    final controller = Get.put(UnifiedNotificationController());

    return Obx(() {
      // Somar todas as 3 categorias para o badge total
      final unreadCount = controller.storiesUnreadCount.value + 
                         controller.interestUnreadCount.value + 
                         controller.systemUnreadCount.value;
      
      return InkWell(
        onTap: onTap ?? () => Get.to(() => const NotificationsView()),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Badge(
            isLabelVisible: unreadCount > 0,
            label: Text(
              unreadCount > 99 ? '99+' : unreadCount.toString(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            child: Icon(
              Icons.notifications_outlined,
              color: iconColor ?? Colors.white,
              size: iconSize ?? 24,
            ),
          ),
        ),
      );
    });
  }
}