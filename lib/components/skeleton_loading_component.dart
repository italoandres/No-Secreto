import 'package:flutter/material.dart';

/// Componente de skeleton loading para melhor UX
class SkeletonLoadingComponent extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Color? baseColor;
  final Color? highlightColor;

  const SkeletonLoadingComponent({
    Key? key,
    this.width,
    this.height,
    this.borderRadius,
    this.baseColor,
    this.highlightColor,
  }) : super(key: key);

  @override
  State<SkeletonLoadingComponent> createState() =>
      _SkeletonLoadingComponentState();
}

class _SkeletonLoadingComponentState extends State<SkeletonLoadingComponent>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.baseColor ?? Colors.grey[300]!;
    final highlightColor = widget.highlightColor ?? Colors.grey[100]!;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(4),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: [
                (_animation.value - 1).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 1).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton para card de match
class MatchCardSkeleton extends StatelessWidget {
  const MatchCardSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Profile photo skeleton
          const SkeletonLoadingComponent(
            width: 70,
            height: 70,
            borderRadius: BorderRadius.all(Radius.circular(35)),
          ),

          const SizedBox(width: 16),

          // Content skeleton
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name skeleton
                const SkeletonLoadingComponent(
                  width: 120,
                  height: 18,
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),

                const SizedBox(height: 8),

                // Status skeleton
                const SkeletonLoadingComponent(
                  width: 80,
                  height: 14,
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),

                const SizedBox(height: 8),

                // Message skeleton
                const SkeletonLoadingComponent(
                  width: double.infinity,
                  height: 14,
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Button skeleton
          const SkeletonLoadingComponent(
            width: 100,
            height: 32,
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ],
      ),
    );
  }
}

/// Skeleton para lista de matches
class MatchesListSkeleton extends StatelessWidget {
  final int itemCount;

  const MatchesListSkeleton({
    Key? key,
    this.itemCount = 5,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (context, index) => const MatchCardSkeleton(),
    );
  }
}

/// Skeleton para mensagem de chat
class ChatMessageSkeleton extends StatelessWidget {
  final bool isFromCurrentUser;

  const ChatMessageSkeleton({
    Key? key,
    this.isFromCurrentUser = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isFromCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isFromCurrentUser) ...[
            const SkeletonLoadingComponent(
              width: 32,
              height: 32,
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isFromCurrentUser ? Colors.grey[200] : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLoadingComponent(
                    width: MediaQuery.of(context).size.width * 0.4,
                    height: 16,
                    borderRadius: const BorderRadius.all(Radius.circular(4)),
                  ),
                  const SizedBox(height: 4),
                  const SkeletonLoadingComponent(
                    width: 60,
                    height: 12,
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                  ),
                ],
              ),
            ),
          ),
          if (isFromCurrentUser) ...[
            const SizedBox(width: 8),
            const SkeletonLoadingComponent(
              width: 32,
              height: 32,
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ],
        ],
      ),
    );
  }
}

/// Skeleton para lista de mensagens
class ChatMessagesSkeleton extends StatelessWidget {
  final int messageCount;

  const ChatMessagesSkeleton({
    Key? key,
    this.messageCount = 8,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: messageCount,
      itemBuilder: (context, index) => ChatMessageSkeleton(
        isFromCurrentUser: index % 3 == 0, // Varia entre usuário atual e outro
      ),
    );
  }
}

/// Skeleton para perfil
class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Profile photo
        const SkeletonLoadingComponent(
          width: 100,
          height: 100,
          borderRadius: BorderRadius.all(Radius.circular(50)),
        ),

        const SizedBox(height: 16),

        // Name
        const SkeletonLoadingComponent(
          width: 150,
          height: 20,
          borderRadius: BorderRadius.all(Radius.circular(4)),
        ),

        const SizedBox(height: 8),

        // Age and location
        const SkeletonLoadingComponent(
          width: 100,
          height: 16,
          borderRadius: BorderRadius.all(Radius.circular(4)),
        ),

        const SizedBox(height: 16),

        // Bio lines
        ...List.generate(
            3,
            (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SkeletonLoadingComponent(
                    width: double.infinity,
                    height: 14,
                    borderRadius: const BorderRadius.all(Radius.circular(4)),
                  ),
                )),
      ],
    );
  }
}
