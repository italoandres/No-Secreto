import 'package:flutter/material.dart';
import 'package:whatsapp_chat/models/notification_category.dart';

/// Widget de tab para categoria de notificação
/// Exibe ícone, badge com contador e estado ativo/inativo
class NotificationCategoryTab extends StatelessWidget {
  /// Categoria da notificação
  final NotificationCategory category;
  
  /// Contador de notificações não lidas
  final int badgeCount;
  
  /// Se a categoria está ativa
  final bool isActive;
  
  /// Callback ao tocar na tab
  final VoidCallback onTap;

  const NotificationCategoryTab({
    Key? key,
    required this.category,
    required this.badgeCount,
    required this.isActive,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: category.semanticLabel,
      hint: 'Toque para ver notificações',
      button: true,
      selected: isActive,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? category.backgroundColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? category.color : Colors.grey.shade300,
              width: isActive ? 2 : 1,
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Conteúdo principal (ícone + texto)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Ícone
                  Icon(
                    category.icon,
                    color: isActive ? category.color : Colors.grey.shade600,
                    size: 28,
                  ),
                  const SizedBox(height: 4),
                  
                  // Nome da categoria
                  Text(
                    category.displayName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      color: isActive ? category.color : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              
              // Badge com contador
              if (badgeCount > 0)
                Positioned(
                  right: -8,
                  top: -8,
                  child: _buildBadge(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Constrói o badge com contador
  Widget _buildBadge() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        constraints: const BoxConstraints(
          minWidth: 20,
          minHeight: 20,
        ),
        child: Text(
          badgeCount > 99 ? '99+' : badgeCount.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// Widget alternativo com layout horizontal (ícone + texto lado a lado)
class NotificationCategoryTabHorizontal extends StatelessWidget {
  final NotificationCategory category;
  final int badgeCount;
  final bool isActive;
  final VoidCallback onTap;

  const NotificationCategoryTabHorizontal({
    Key? key,
    required this.category,
    required this.badgeCount,
    required this.isActive,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: category.semanticLabel,
      hint: 'Toque para ver notificações',
      button: true,
      selected: isActive,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? category.backgroundColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? category.color : Colors.grey.shade300,
              width: isActive ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ícone com badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    category.icon,
                    color: isActive ? category.color : Colors.grey.shade600,
                    size: 24,
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: _buildSmallBadge(),
                    ),
                ],
              ),
              const SizedBox(width: 8),
              
              // Nome da categoria
              Text(
                category.displayName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? category.color : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmallBadge() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        constraints: const BoxConstraints(
          minWidth: 16,
          minHeight: 16,
        ),
        child: Text(
          badgeCount > 99 ? '99+' : badgeCount.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// Widget minimalista com apenas emoji e badge
class NotificationCategoryTabMinimal extends StatelessWidget {
  final NotificationCategory category;
  final int badgeCount;
  final bool isActive;
  final VoidCallback onTap;

  const NotificationCategoryTabMinimal({
    Key? key,
    required this.category,
    required this.badgeCount,
    required this.isActive,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: category.semanticLabel,
      hint: 'Toque para ver notificações',
      button: true,
      selected: isActive,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: isActive ? category.backgroundColor : Colors.grey.shade100,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? category.color : Colors.transparent,
              width: 2,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: category.color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: Text(
                  category.emoji,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
              if (badgeCount > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: _buildBadge(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        constraints: const BoxConstraints(
          minWidth: 20,
          minHeight: 20,
        ),
        child: Text(
          badgeCount > 99 ? '99+' : badgeCount.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
