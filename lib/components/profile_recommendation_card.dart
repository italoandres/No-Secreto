import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/scored_profile.dart';
import 'match_score_badge.dart';
import 'value_highlight_chips.dart';
import 'deus_e_pai_badge.dart';
import 'hobbies_chips_modern.dart';

/// Card de recomendação de perfil com foto colapsável e notificação temporária
class ProfileRecommendationCard extends StatefulWidget {
  final ScoredProfile profile;
  final VoidCallback onInterest;
  final VoidCallback onPass;
  final VoidCallback onTapDetails;

  const ProfileRecommendationCard({
    Key? key,
    required this.profile,
    required this.onInterest,
    required this.onPass,
    required this.onTapDetails,
  }) : super(key: key);

  @override
  State<ProfileRecommendationCard> createState() =>
      _ProfileRecommendationCardState();
}

class _ProfileRecommendationCardState extends State<ProfileRecommendationCard> {
  int _currentPhotoIndex = 0;
  bool _showNotification = true;

  @override
  void initState() {
    super.initState();
    // Esconder notificação após 5 segundos
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showNotification = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final cardHeight = screenHeight * 0.85;

    return Container(
      height: cardHeight,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: CustomScrollView(
          slivers: [
            // FOTO COLAPSÁVEL (SliverAppBar)
            SliverAppBar(
              expandedHeight: 400,
              pinned: false,
              floating: false,
              automaticallyImplyLeading: false,
              backgroundColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                background: _buildPhotoSection(),
              ),
            ),

            // INFORMAÇÕES (SliverList)
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header com nome e match score
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Nome, idade e localização
                          Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        '${widget.profile.name}, ${widget.profile.age}',
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2C3E50),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    // Ícone verificado dourado (se certificado)
                                    if (widget.profile.hasCertification) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFFFFD700),
                                              Color(0xFFFFA500)
                                            ],
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.verified,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  widget.profile.formattedLocation,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                widget.profile.formattedDistance,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Badges lado a lado
                          Row(
                            children: [
                              // Match Score Badge
                              Expanded(
                                child: MatchScoreBadge(
                                    score: widget.profile.score),
                              ),
                              const SizedBox(width: 12),
                              // Deus é Pai Badge (sempre aparece)
                              Expanded(
                                child: DeusEPaiBadge(
                                  isMember: widget.profile.isDeusEPaiMember,
                                  onTap: widget.onTapDetails,
                                ),
                              ),
                            ],
                          ),

                          // Hobbies modernos logo abaixo dos badges
                          HobbiesChipsModern(profile: widget.profile),
                        ],
                      ),
                    ),

                    // Valores destacados
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ValueHighlightChips(profile: widget.profile),
                    ),

                    const SizedBox(height: 16),

                    // Botão "Ver Perfil Completo"
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildViewFullProfileButton(),
                    ),

                    const SizedBox(height: 16),

                    // Botões de ação
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Seção de foto com navegação e notificação
  Widget _buildPhotoSection() {
    final photos = widget.profile.photos;
    final hasMultiplePhotos = photos.length > 1;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Foto principal
        GestureDetector(
          onTap: widget.onTapDetails,
          onHorizontalDragEnd: hasMultiplePhotos ? _handlePhotoSwipe : null,
          child: CachedNetworkImage(
            imageUrl: photos.isNotEmpty
                ? photos[_currentPhotoIndex]
                : 'https://via.placeholder.com/400',
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey[200],
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey[300],
              child: const Icon(Icons.person, size: 80, color: Colors.grey),
            ),
          ),
        ),

        // Gradiente sutil no topo
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 150,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.4),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Indicador de fotos
        if (hasMultiplePhotos)
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: _buildPhotoIndicator(photos.length),
          ),

        // Badge de certificação (se tiver)
        if (widget.profile.hasCertification)
          Positioned(
            top: 16,
            right: 16,
            child: _buildCertificationBadge(),
          ),

        // NOTIFICAÇÃO TEMPORÁRIA (sobre a foto)
        if (_showNotification)
          Positioned(
            top: 60,
            left: 16,
            right: 16,
            child: AnimatedOpacity(
              opacity: _showNotification ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: _buildNotificationBanner(),
            ),
          ),
      ],
    );
  }

  /// Notificação temporária sobre a foto
  Widget _buildNotificationBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4169E1).withOpacity(0.95),
            const Color(0xFF6A5ACD).withOpacity(0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nova Recomendação!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Perfil selecionado especialmente para você',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 20),
            onPressed: () {
              setState(() {
                _showNotification = false;
              });
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  /// Indicador de múltiplas fotos
  Widget _buildPhotoIndicator(int photoCount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        photoCount,
        (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index == _currentPhotoIndex
                ? Colors.white
                : Colors.white.withOpacity(0.4),
          ),
        ),
      ),
    );
  }

  /// Badge de certificação espiritual
  Widget _buildCertificationBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, color: Colors.white, size: 16),
          SizedBox(width: 4),
          Text(
            'Certificado',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Botão "Ver Perfil Completo"
  Widget _buildViewFullProfileButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTapDetails,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFF4169E1),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.visibility_outlined,
                color: Color(0xFF4169E1),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Ver Perfil Completo',
                style: TextStyle(
                  color: Color(0xFF4169E1),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Botões de ação (Interesse / Passar)
  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Botão Passar
          Expanded(
            child: _buildActionButton(
              icon: Icons.close,
              label: 'Passar',
              color: Colors.grey[400]!,
              onTap: widget.onPass,
            ),
          ),
          const SizedBox(width: 16),
          // Botão Interesse
          Expanded(
            flex: 2,
            child: _buildActionButton(
              icon: Icons.favorite,
              label: 'Tenho Interesse',
              color: const Color(0xFF4169E1),
              onTap: widget.onInterest,
              isPrimary: true,
            ),
          ),
        ],
      ),
    );
  }

  /// Botão de ação individual
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isPrimary ? color : Colors.transparent,
            border: Border.all(
              color: color,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isPrimary ? Colors.white : color,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isPrimary ? Colors.white : color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Manipula swipe horizontal para trocar fotos
  void _handlePhotoSwipe(DragEndDetails details) {
    if (details.primaryVelocity == null) return;

    final photos = widget.profile.photos;
    if (photos.length <= 1) return;

    setState(() {
      if (details.primaryVelocity! < 0) {
        // Swipe para esquerda - próxima foto
        _currentPhotoIndex = (_currentPhotoIndex + 1) % photos.length;
      } else {
        // Swipe para direita - foto anterior
        _currentPhotoIndex =
            (_currentPhotoIndex - 1 + photos.length) % photos.length;
      }
    });
  }
}
