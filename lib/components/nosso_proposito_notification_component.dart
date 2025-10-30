import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:whatsapp_chat/services/notification_service.dart';
import 'package:whatsapp_chat/views/notifications_view.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NossoPropositoNotificationComponent extends StatelessWidget {
  const NossoPropositoNotificationComponent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<int>(
      stream: NotificationService.getContextUnreadCount(
          currentUser.uid, 'nosso_proposito'),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;

        return Container(
          width: 50,
          height: 50,
          margin: const EdgeInsets.only(left: 16),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(0),
              backgroundColor: Colors.white38,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            onPressed: () {
              Get.to(() => const NotificationsView());
            },
            child: Stack(
              children: [
                // Ícone de notificação centralizado
                const Center(
                  child: Icon(
                    Icons.notifications_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                ),

                // Badge com contador (só aparece se houver notificações)
                if (unreadCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white,
                          width: 1,
                        ),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        unreadCount > 99 ? '99+' : unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
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
      },
    );
  }
}

// Versão com animação para quando há notificações
class AnimatedNossoPropositoNotificationComponent extends StatefulWidget {
  const AnimatedNossoPropositoNotificationComponent({Key? key})
      : super(key: key);

  @override
  State<AnimatedNossoPropositoNotificationComponent> createState() =>
      _AnimatedNossoPropositoNotificationComponentState();
}

class _AnimatedNossoPropositoNotificationComponentState
    extends State<AnimatedNossoPropositoNotificationComponent>
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
      end: 1.1,
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

    return StreamBuilder<int>(
      stream: NotificationService.getContextUnreadCount(
          currentUser.uid, 'nosso_proposito'),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;

        // Controlar animação baseado nas notificações
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (unreadCount > 0) {
            _startPulseAnimation();
          } else {
            _stopPulseAnimation();
          }
        });

        return AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: unreadCount > 0 ? _scaleAnimation.value : 1.0,
              child: Container(
                width: 50,
                height: 50,
                margin: const EdgeInsets.only(left: 16),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(0),
                    backgroundColor: Colors.white38,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  onPressed: () {
                    _stopPulseAnimation();
                    Get.to(() => const NotificationsView());
                  },
                  child: Stack(
                    children: [
                      // Ícone de notificação centralizado
                      const Center(
                        child: Icon(
                          Icons.notifications_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),

                      // Badge com contador
                      if (unreadCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.white,
                                width: 1,
                              ),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              unreadCount > 99 ? '99+' : unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
