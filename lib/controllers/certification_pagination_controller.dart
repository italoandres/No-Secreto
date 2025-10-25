import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/certification_pagination_service.dart';
import '../models/certification_request_model.dart';

/// Controller para gerenciar paginação de certificações
///
/// Gerencia o estado de carregamento, dados carregados e navegação entre páginas
class CertificationPaginationController extends ChangeNotifier {
  final CertificationPaginationService _paginationService =
      CertificationPaginationService();

  // Estado
  List<CertificationRequestModel> _certifications = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  String? _error;

  // Filtros
  String? _status;
  Map<String, dynamic>? _filters;
  int _pageSize = CertificationPaginationService.defaultPageSize;

  // Getters
  List<CertificationRequestModel> get certifications => _certifications;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;
  int get totalLoaded => _certifications.length;

  /// Inicializa o controller com filtros
  void initialize({
    String? status,
    Map<String, dynamic>? filters,
    int? pageSize,
  }) {
    _status = status;
    _filters = filters;
    if (pageSize != null) {
      _pageSize = pageSize;
    }
    loadFirstPage();
  }

  /// Carrega a primeira página
  Future<void> loadFirstPage() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    _certifications = [];
    _lastDocument = null;
    _hasMore = true;
    notifyListeners();

    try {
      final result = await _paginationService.getCertificationsPaginated(
        status: _status,
        pageSize: _pageSize,
        filters: _filters,
      );

      _certifications = result.certifications;
      _lastDocument = result.lastDocument;
      _hasMore = result.hasMore;
      _error = null;
    } catch (e) {
      _error = 'Erro ao carregar certificações: $e';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carrega a próxima página
  Future<void> loadNextPage() async {
    if (_isLoadingMore || !_hasMore || _lastDocument == null) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final result = await _paginationService.getCertificationsPaginated(
        status: _status,
        pageSize: _pageSize,
        lastDocument: _lastDocument,
        filters: _filters,
      );

      _certifications.addAll(result.certifications);
      _lastDocument = result.lastDocument;
      _hasMore = result.hasMore;
      _error = null;
    } catch (e) {
      _error = 'Erro ao carregar mais certificações: $e';
      print(_error);
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Atualiza os filtros e recarrega
  void updateFilters({
    String? status,
    Map<String, dynamic>? filters,
  }) {
    _status = status;
    _filters = filters;
    loadFirstPage();
  }

  /// Recarrega a página atual
  Future<void> refresh() async {
    await loadFirstPage();
  }

  /// Remove uma certificação da lista (após processamento)
  void removeCertification(String certificationId) {
    _certifications.removeWhere((cert) => cert.id == certificationId);
    notifyListeners();
  }

  /// Atualiza uma certificação na lista
  void updateCertification(CertificationRequestModel updatedCert) {
    final index =
        _certifications.indexWhere((cert) => cert.id == updatedCert.id);
    if (index != -1) {
      _certifications[index] = updatedCert;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _certifications.clear();
    super.dispose();
  }
}
