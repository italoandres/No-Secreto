import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../repositories/simple_accepted_matches_repository.dart';
import '../views/simple_accepted_matches_view.dart';

/// Botão de matches aceitos com contador de mensagens não lidas
class MatchesButtonWithCounter extends StatefulWidget {
  const MatchesButtonWithCounter({super.key});

  @override
  State<MatchesButtonWithCounter> createState() => _MatchesButtonWithCounterState();
}

class _MatchesButtonWithCounterState extends State<MatchesButtonWithCounter> {
  int _unreadCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() {
          _isLoading = false;
          _unreadCount = 0;
        });
        return;
      }

      // Buscar matches aceitos usando repositório simplificado
      final repository = SimpleAcceptedMatchesRepository();
      final matches = await repository.getAcceptedMatches(currentUser.uid);
      int totalUnread = 0;
      
      for (final match in matches) {
        totalUnread += match.unreadMessages;
      }

      if (mounted) {
        setState(() {
          _unreadCount = totalUnread;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erro ao carregar contador de mensagens não lidas: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _unreadCount = 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50, 
      height: 50,
      margin: const EdgeInsets.only(left: 8),
      child: Stack(
        children: [
          // Botão principal
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(0),
              backgroundColor: const Color(0xFFFF6B9D).withOpacity(0.9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Get.to(() => const SimpleAcceptedMatchesView())?.then((_) {
                // Recarregar contador quando voltar da tela
                _loadUnreadCount();
              });
            },
            child: const Icon(
              Icons.favorite,
              color: Colors.white,
              size: 24,
            ),
          ),
          
          // Badge de contador (apenas se houver mensagens não lidas)
          if (!_isLoading && _unreadCount > 0)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                constraints: const BoxConstraints(
                  minWidth: 20,
                  minHeight: 20,
                ),
                child: Text(
                  _unreadCount > 99 ? '99+' : _unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          
          // Indicador de carregamento
          if (_isLoading)
            Positioned(
              top: 2,
              right: 2,
              child: Container(
                width: 12,
                height: 12,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}