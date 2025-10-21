import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../components/match_chat_card.dart';
import '../models/accepted_match_model.dart';
import '../repositories/simple_accepted_matches_repository.dart';
import '../services/match_navigation_service.dart';
import '../services/match_error_handler.dart';
import '../services/match_loading_manager.dart';
import '../services/match_retry_service.dart';
import '../utils/debug_accepted_matches.dart';

class AcceptedMatchesView extends StatefulWidget {
  const AcceptedMatchesView({super.key});

  @override
  State<AcceptedMatchesView> createState() => _AcceptedMatchesViewState();
}

class _AcceptedMatchesViewState extends State<AcceptedMatchesView> {
  final SimpleAcceptedMatchesRepository _repository = SimpleAcceptedMatchesRepository();
  List<AcceptedMatchModel> _matches = [];
  String? _error;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Garantir que o MatchLoadingManager está inicializado
    if (!Get.isRegistered<MatchLoadingManager>()) {
      Get.put(MatchLoadingManager());
    }
    _loadMatches();
  }

  /// Carregar matches com retry automático e tratamento de erros
  Future<void> _loadMatches() async {
    final matches = await MatchRetryService.executeWithRetryAndErrorHandling<List<AcceptedMatchModel>>(
      () async {
        // Obter userId do usuário logado
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
          throw Exception('Usuário não está logado');
        }
        return await _repository.getAcceptedMatches(currentUser.uid);
      },
      config: RetryConfig.network,
      operationName: 'load_accepted_matches',
      loadingType: LoadingType.loadingMatches,
      context: 'Carregando matches aceitos',
      showErrorSnackbar: true,
    );

    if (mounted && matches != null) {
      setState(() {
        _matches = matches;
        _error = null;
      });
    }
  }

  /// Refresh com loading específico
  Future<void> _onRefresh() async {
    await MatchRetryService.executeWithRetryAndErrorHandling<List<AcceptedMatchModel>>(
      () async {
        // Obter userId do usuário logado
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
          throw Exception('Usuário não está logado');
        }
        return await _repository.getAcceptedMatches(currentUser.uid);
      },
      config: RetryConfig.fast,
      operationName: 'refresh_accepted_matches',
      loadingType: LoadingType.refreshing,
      context: 'Atualizando matches',
      showErrorSnackbar: true,
    ).then((matches) {
      if (mounted && matches != null) {
        setState(() {
          _matches = matches;
          _error = null;
        });
      }
    });
  }

  void _navigateToChat(AcceptedMatchModel match) {
    MatchNavigationService.navigateToMatchChatFromModel(match);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Matches Aceitos',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFFFF6B9D),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _onRefresh,
          ),
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () => DebugAcceptedMatches.showDebugDialog(context),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return GetBuilder<MatchLoadingManager>(
      builder: (loadingManager) {
        final isLoadingMatches = loadingManager.isLoading(LoadingType.loadingMatches);
        final isRefreshing = loadingManager.isLoading(LoadingType.refreshing);

        if (isLoadingMatches && _matches.isEmpty) {
          return _buildLoadingState();
        }

        if (_error != null && _matches.isEmpty) {
          return _buildErrorState();
        }

        if (_matches.isEmpty && !isLoadingMatches) {
          return _buildEmptyState();
        }

        return _buildMatchesList(isRefreshing: isRefreshing);
      },
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: Column(
            children: [
              const SizedBox(height: 40),
              const MatchLoadingWidget(
                type: LoadingType.loadingMatches,
                size: 32,
                showMessage: true,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: 5, // Skeleton items
                  itemBuilder: (context, index) {
                    return const MatchChatCardSkeleton(
                      margin: EdgeInsets.only(bottom: 12),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ops! Algo deu errado',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error ?? 'Erro desconhecido',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _loadMatches(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tentar Novamente'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B9D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B9D), Color(0xFFFFA8A8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF6B9D).withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.favorite_border,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Nenhum match aceito ainda',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Quando alguém aceitar seu interesse,\nvocês poderão conversar aqui!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.explore),
                    label: const Text('Explorar Perfis'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B9D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMatchesList({bool isRefreshing = false}) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _onRefresh,
            color: const Color(0xFFFF6B9D),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _matches.length,
              itemBuilder: (context, index) {
                final match = _matches[index];
                return MatchChatCard(
                  match: match,
                  onTap: () => _navigateToChat(match),
                  margin: const EdgeInsets.only(bottom: 12),
                  showOnlineStatus: true,
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final totalMatches = _matches.length;
    final unreadCount = _matches.where((m) => m.unreadMessages > 0).length;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B9D), Color(0xFFFFA8A8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B9D).withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.favorite,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Seus Matches',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (!_isLoading) ...[
                        const SizedBox(height: 4),
                        Text(
                          totalMatches == 0
                              ? 'Nenhum match ainda'
                              : totalMatches == 1
                                  ? '1 match ativo'
                                  : '$totalMatches matches ativos',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (unreadCount > 0 && !_isLoading)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      unreadCount == 1
                          ? '1 nova mensagem'
                          : '$unreadCount novas mensagens',
                      style: const TextStyle(
                        color: Color(0xFFFF6B9D),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
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
}