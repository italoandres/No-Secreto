import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import '../theme.dart';
import 'photo_gallery_section.dart';

/// Seção de cabeçalho do perfil com foto, nome e badge de verificação centralizados
class ProfileHeaderSection extends StatelessWidget {
  final String? photoUrl;
  final String displayName;
  final bool hasVerification;
  final String? username;

  const ProfileHeaderSection({
    Key? key,
    this.photoUrl,
    required this.displayName,
    this.hasVerification = false,
    this.username,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Profile Photo with Verification Badge
          Stack(
            children: [
              // Profile Photo (clicável)
              GestureDetector(
                onTap: () {
                  if (photoUrl?.isNotEmpty == true) {
                    _openPhotoViewer(context, photoUrl!);
                  }
                },
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: photoUrl?.isNotEmpty == true
                        ? kIsWeb
                            // Use Image.network for web to avoid CORS issues
                            ? Image.network(
                                photoUrl!,
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return _buildLoadingAvatar();
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  debugPrint(
                                      '❌ Error loading profile image (Web): $error');
                                  debugPrint('📸 Image URL: $photoUrl');
                                  return _buildAvatarFallback();
                                },
                              )
                            // Use CachedNetworkImage for mobile
                            : CachedNetworkImage(
                                imageUrl: photoUrl!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    _buildLoadingAvatar(),
                                errorWidget: (context, url, error) {
                                  debugPrint(
                                      '❌ Error loading profile image (Mobile): $error');
                                  debugPrint('📸 Image URL: $photoUrl');
                                  return _buildAvatarFallback();
                                },
                              )
                        : _buildAvatarFallback(),
                  ),
                ),
              ),

              // Verification Badge
              if (hasVerification)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700), // Gold color
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.verified,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 20),

          // Display Name
          Text(
            displayName,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
            textAlign: TextAlign.center,
          ),

          // Username
          if (username?.isNotEmpty == true) ...[
            const SizedBox(height: 4),
            Text(
              '@$username',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatarFallback() {
    // Create initials from display name
    String initials = _getInitials(displayName);

    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingAvatar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
      ),
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';

    List<String> nameParts = name.trim().split(' ');
    if (nameParts.length == 1) {
      return nameParts[0].substring(0, 1).toUpperCase();
    }

    String firstInitial = nameParts.first.substring(0, 1).toUpperCase();
    String lastInitial = nameParts.last.substring(0, 1).toUpperCase();

    return '$firstInitial$lastInitial';
  }

  /// Abre o visualizador de foto em tela cheia
  void _openPhotoViewer(BuildContext context, String photoUrl) {
    print('📸 Opening main photo viewer');
    print('📸 Photo URL: $photoUrl');

    try {
      Get.to(
        () => PhotoViewerScreen(
          photos: [photoUrl],
          initialIndex: 0,
        ),
        transition: Transition.fadeIn,
      );
    } catch (e) {
      print('❌ Error opening main photo viewer: $e');
    }
  }
}
