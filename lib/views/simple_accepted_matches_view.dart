import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/accepted_match_model.dart';
import '../repositories/simple_accepted_matches_repository.dart';
import '../views/romantic_match_chat_view.dart';

/// Tela moderna e elegante de matches aceitos
class SimpleAcceptedMatchesView extends StatefulWidget {
  const SimpleAcceptedMatchesView({super.key});

  @override
  State<SimpleAcceptedMatchesView> createState() => _SimpleAcceptedMatchesViewState();
}

class _SimpleAcceptedMatchesViewState extends State<SimpleAcceptedMatchesView> {
  final _repository = SimpleAcceptedMatchesRepository();
  
  @override
  void initState() {
    super.initState();
    debugPrint('🔍 [MATCHES_VIEW] Iniciando stream de matches aceitos');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'Matches Aceitos',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFFFF6B9D),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => setState(() {}),
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Usuário não autenticado'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => setState(() {}),
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<List<AcceptedMatchModel>>(
      stream: _repository.getAcceptedMatchesStream(currentUser.uid),
      builder: (context, snapshot) {
        // Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        // Error
        if (snapshot.hasError) {
          debugPrint('❌ [MATCHES_VIEW] Erro no stream: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Erro ao carregar matches',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Tentar Novamente'),
                ),
              ],
            ),
          );
        }

        final matches = snapshot.data ?? [];
        
        debugPrint('📊 [MATCHES_VIEW] Matches recebidos: ${matches.length}');

        // Empty
        if (matches.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_border, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Nenhum match aceito ainda',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Aceite interesses para começar a conversar',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        // Success - Lista de matches
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: matches.length,
          itemBuilder: (context, index) {
            final match = matches[index];
            
            debugPrint('🎨 [UI] Exibindo match: ${match.otherUserName}');
            debugPrint('   nameWithAge: ${match.nameWithAge}');
            debugPrint('   formattedLocation: ${match.formattedLocation}');
            
            return _buildMatchCard(match);
          },
        );
      },
    );
  }

  Widget _buildMatchCard(AcceptedMatchModel match) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Linha principal: Avatar + Info + Badge
            Row(
              children: [
                // Avatar com status online e foto real
                Stack(
                  children: [
                    _buildModernAvatar(match),
                    // Bolinha de status online
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: _getOnlineStatusColor(),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                
                // Informações principais
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nome com idade
                      Text(
                        match.nameWithAge,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[900],
                        ),
                      ),
                      const SizedBox(height: 4),
                      
                      // Cidade (sempre mostrar, mesmo que vazia)
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 16,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            match.formattedLocation.isNotEmpty 
                                ? match.formattedLocation 
                                : 'Localização não informada',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: match.formattedLocation.isNotEmpty 
                                  ? Colors.grey[600] 
                                  : Colors.grey[400],
                              fontStyle: match.formattedLocation.isEmpty 
                                  ? FontStyle.italic 
                                  : FontStyle.normal,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // Data do match + Dias restantes (discreto)
                      Row(
                        children: [
                          Text(
                            'Match ${match.formattedMatchDate}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                          Text(
                            ' • ',
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                          Icon(
                            Icons.schedule_rounded,
                            size: 12,
                            color: _getStatusColor(match),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getTimeMessage(match),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: _getStatusColor(match),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Badge de mensagens não lidas
                if (match.hasUnreadMessages)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B9D), Color(0xFFFF8FB3)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF6B9D).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.message_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          match.unreadText,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Botões de ação
            Row(
              children: [
                // Botão Ver Perfil
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _viewProfile(match),
                    icon: const Icon(Icons.person_rounded, size: 18),
                    label: Text(
                      'Ver Perfil',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFFFF6B9D),
                      elevation: 0,
                      side: const BorderSide(
                        color: Color(0xFFFF6B9D),
                        width: 2,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Botão Conversar
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: match.chatExpired ? null : () => _openChat(match),
                    icon: const Icon(Icons.chat_bubble_rounded, size: 18),
                    label: Text(
                      'Conversar',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: match.chatExpired 
                          ? Colors.grey[300] 
                          : const Color(0xFFFF6B9D),
                      foregroundColor: Colors.white,
                      elevation: match.chatExpired ? 0 : 4,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      shadowColor: match.chatExpired 
                          ? Colors.transparent 
                          : const Color(0xFFFF6B9D).withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernAvatar(AcceptedMatchModel match) {
    final hasPhoto = match.otherUserPhoto != null && match.otherUserPhoto!.isNotEmpty;

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B9D), Color(0xFFFF8FB3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B9D).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: CircleAvatar(
          radius: 30,
          backgroundColor: Colors.white,
          backgroundImage: hasPhoto ? NetworkImage(match.otherUserPhoto!) : null,
          onBackgroundImageError: hasPhoto
              ? (exception, stackTrace) {
                  debugPrint('Erro ao carregar foto: $exception');
                }
              : null,
          child: !hasPhoto
              ? Text(
                  match.otherUserName.isNotEmpty
                      ? match.otherUserName[0].toUpperCase()
                      : '?',
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFF6B9D),
                  ),
                )
              : null,
        ),
      ),
    );
  }

  Color _getOnlineStatusColor() {
    // TODO: Implementar lógica real de status online
    // Por enquanto, retorna verde (online) aleatoriamente
    return Colors.green; // Verde = online, Amarelo = ausente, Cinza = offline
  }

  List<Color> _getTimeGradient(AcceptedMatchModel match) {
    if (match.chatExpired || match.daysRemaining <= 0) {
      return [const Color(0xFFEF5350), const Color(0xFFE53935)];
    } else if (match.daysRemaining <= 7) {
      return [const Color(0xFFFF9800), const Color(0xFFFB8C00)];
    } else {
      return [const Color(0xFF66BB6A), const Color(0xFF43A047)];
    }
  }

  IconData _getTimeIcon(AcceptedMatchModel match) {
    if (match.chatExpired || match.daysRemaining <= 0) {
      return Icons.error_outline_rounded;
    } else if (match.daysRemaining <= 7) {
      return Icons.warning_amber_rounded;
    } else {
      return Icons.check_circle_outline_rounded;
    }
  }

  String _getTimeMessage(AcceptedMatchModel match) {
    if (match.chatExpired || match.daysRemaining <= 0) {
      return 'Chat expirado';
    } else if (match.daysRemaining == 1) {
      return 'Falta 1 dia para encerrar';
    } else {
      return 'Faltam ${match.daysRemaining} dias para encerrar';
    }
  }

  Color _getTimeTextColor(AcceptedMatchModel match) {
    if (match.chatExpired || match.daysRemaining <= 0) {
      return Colors.red[600]!;
    } else if (match.daysRemaining <= 7) {
      return Colors.orange[600]!;
    } else {
      return Colors.grey[600]!;
    }
  }

  Color _getStatusColor(AcceptedMatchModel match) {
    if (match.chatExpired || match.daysRemaining <= 0) {
      return Colors.red;
    } else if (match.daysRemaining <= 7) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  void _viewProfile(AcceptedMatchModel match) {
    Get.toNamed('/profile-display', arguments: {
      'userId': match.otherUserId,
      'fromRoute': 'accepted-matches',
    });
  }

  void _openChat(AcceptedMatchModel match) {
    if (match.chatExpired) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este chat expirou'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Get.to(
      () => RomanticMatchChatView(
        chatId: match.chatId,
        otherUserId: match.otherUserId,
        otherUserName: match.otherUserName,
        otherUserPhotoUrl: match.otherUserPhoto,
      ),
    );
  }
}
