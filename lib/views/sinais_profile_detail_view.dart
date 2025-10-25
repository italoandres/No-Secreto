import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/scored_profile.dart';
import '../components/photo_gallery_section.dart';
import '../components/value_highlight_chips.dart';

/// Tela de detalhes completos do perfil de recomendação
class SinaisProfileDetailView extends StatelessWidget {
  const SinaisProfileDetailView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ScoredProfile profile = Get.arguments as ScoredProfile;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Conteúdo principal
          CustomScrollView(
            slivers: [
              // App Bar com foto de fundo
              _buildSliverAppBar(profile),

              // Conteúdo
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Informações básicas
                    _buildBasicInfo(profile),

                    const Divider(height: 32, thickness: 1),

                    // Bio
                    if (profile.bio?.isNotEmpty == true)
                      _buildBioSection(profile),

                    // Galeria de fotos
                    if (profile.photos.length > 1) _buildPhotoGallery(profile),

                    // Valores e informações
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: ValueHighlightChips(profile: profile),
                    ),

                    const SizedBox(height: 100), // Espaço para o botão fixo
                  ],
                ),
              ),
            ],
          ),

          // Botão voltar
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: _buildBackButton(),
          ),

          // Badge de certificação
          if (profile.hasCertification)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 16,
              child: _buildCertificationBadge(),
            ),

          // Botão "Tenho Interesse" fixo na parte inferior
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildInterestButton(profile),
          ),
        ],
      ),
    );
  }

  /// App Bar com foto de fundo
  Widget _buildSliverAppBar(ScoredProfile profile) {
    return SliverAppBar(
      expandedHeight: 400,
      pinned: false,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Hero(
          tag: 'profile_${profile.userId}',
          child: Image.network(
            profile.photoUrl ?? '',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.grey[300],
              child: const Icon(Icons.person, size: 80, color: Colors.grey),
            ),
          ),
        ),
      ),
    );
  }

  /// Informações básicas
  Widget _buildBasicInfo(ScoredProfile profile) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nome e idade
          Row(
            children: [
              Flexible(
                child: Text(
                  '${profile.name}, ${profile.age}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ),
              // Ícone verificado dourado (se certificado)
              if (profile.hasCertification) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.verified,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          // Localização
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 18,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  profile.formattedLocation,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                profile.formattedDistance,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Seção de bio
  Widget _buildBioSection(ScoredProfile profile) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sobre mim',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            profile.bio ?? '',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// Galeria de fotos
  Widget _buildPhotoGallery(ScoredProfile profile) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Fotos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: profile.photos.length,
              itemBuilder: (context, index) {
                return Container(
                  width: 150,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: DecorationImage(
                      image: NetworkImage(profile.photos[index]),
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Botão voltar
  Widget _buildBackButton() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(30),
      elevation: 4,
      child: InkWell(
        onTap: () => Get.back(),
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: const Icon(
            Icons.arrow_back,
            color: Color(0xFF2C3E50),
            size: 24,
          ),
        ),
      ),
    );
  }

  /// Badge de certificação
  Widget _buildCertificationBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
          Icon(Icons.verified, color: Colors.white, size: 18),
          SizedBox(width: 6),
          Text(
            'Certificado',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Botão "Tenho Interesse" fixo
  Widget _buildInterestButton(ScoredProfile profile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              // TODO: Implementar lógica de interesse
              Get.back(result: 'interest');
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4169E1), Color(0xFF1E90FF)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4169E1).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite,
                    color: Colors.white,
                    size: 26,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Tenho Interesse',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
