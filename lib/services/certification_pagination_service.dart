import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/certification_request_model.dart';

/// Serviço de paginação para certificações
///
/// Gerencia o carregamento paginado de certificações para melhorar
/// a performance e experiência do usuário ao visualizar grandes volumes de dados
class CertificationPaginationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Tamanho padrão da página
  static const int defaultPageSize = 20;

  /// Busca certificações com paginação
  ///
  /// [status] - Status das certificações ('pending', 'approved', 'rejected', ou null para todas)
  /// [pageSize] - Número de itens por página
  /// [lastDocument] - Último documento da página anterior (para paginação)
  /// [filters] - Filtros adicionais (opcional)
  Future<PaginatedCertificationsResult> getCertificationsPaginated({
    String? status,
    int pageSize = defaultPageSize,
    DocumentSnapshot? lastDocument,
    Map<String, dynamic>? filters,
  }) async {
    try {
      Query query = _firestore.collection('spiritual_certifications');

      // Aplicar filtro de status
      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      // Aplicar filtros adicionais
      if (filters != null) {
        // Filtro de data inicial
        if (filters['startDate'] != null) {
          query = query.where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(filters['startDate']),
          );
        }

        // Filtro de data final
        if (filters['endDate'] != null) {
          final endDate =
              (filters['endDate'] as DateTime).add(Duration(days: 1));
          query = query.where(
            'createdAt',
            isLessThan: Timestamp.fromDate(endDate),
          );
        }

        // Filtro de admin (apenas para certificações processadas)
        if (filters['adminEmail'] != null && status != 'pending') {
          query = query.where('processedBy', isEqualTo: filters['adminEmail']);
        }
      }

      // Ordenação
      final orderByField = status == 'pending' ? 'createdAt' : 'processedAt';
      query = query.orderBy(orderByField, descending: true);

      // Aplicar paginação
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      // Buscar uma página extra para saber se há mais dados
      query = query.limit(pageSize + 1);

      final snapshot = await query.get();

      // Verificar se há mais páginas
      final hasMore = snapshot.docs.length > pageSize;

      // Pegar apenas os documentos da página atual
      final docs = hasMore ? snapshot.docs.sublist(0, pageSize) : snapshot.docs;

      // Converter para modelos
      final certifications = docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return CertificationRequestModel.fromMap(data);
      }).toList();

      // Aplicar filtro de busca por texto (no cliente)
      List<CertificationRequestModel> filteredCertifications = certifications;
      if (filters != null && filters['searchText'] != null) {
        final searchLower = (filters['searchText'] as String).toLowerCase();
        filteredCertifications = certifications.where((cert) {
          final userName = (cert.userName ?? '').toLowerCase();
          final userEmail = (cert.userEmail ?? '').toLowerCase();
          final purchaseEmail = (cert.purchaseEmail ?? '').toLowerCase();

          return userName.contains(searchLower) ||
              userEmail.contains(searchLower) ||
              purchaseEmail.contains(searchLower);
        }).toList();
      }

      return PaginatedCertificationsResult(
        certifications: filteredCertifications,
        lastDocument: docs.isNotEmpty ? docs.last : null,
        hasMore: hasMore,
        totalLoaded: filteredCertifications.length,
      );
    } catch (e) {
      print('Erro ao buscar certificações paginadas: $e');
      return PaginatedCertificationsResult(
        certifications: [],
        lastDocument: null,
        hasMore: false,
        totalLoaded: 0,
      );
    }
  }

  /// Busca estatísticas de certificações
  Future<CertificationStats> getCertificationStats() async {
    try {
      final pendingSnapshot = await _firestore
          .collection('spiritual_certifications')
          .where('status', isEqualTo: 'pending')
          .count()
          .get();

      final approvedSnapshot = await _firestore
          .collection('spiritual_certifications')
          .where('status', isEqualTo: 'approved')
          .count()
          .get();

      final rejectedSnapshot = await _firestore
          .collection('spiritual_certifications')
          .where('status', isEqualTo: 'rejected')
          .count()
          .get();

      return CertificationStats(
        pending: pendingSnapshot.count ?? 0,
        approved: approvedSnapshot.count ?? 0,
        rejected: rejectedSnapshot.count ?? 0,
      );
    } catch (e) {
      print('Erro ao buscar estatísticas: $e');
      return CertificationStats(pending: 0, approved: 0, rejected: 0);
    }
  }
}

/// Resultado de uma busca paginada de certificações
class PaginatedCertificationsResult {
  final List<CertificationRequestModel> certifications;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;
  final int totalLoaded;

  PaginatedCertificationsResult({
    required this.certifications,
    required this.lastDocument,
    required this.hasMore,
    required this.totalLoaded,
  });
}

/// Estatísticas de certificações
class CertificationStats {
  final int pending;
  final int approved;
  final int rejected;

  CertificationStats({
    required this.pending,
    required this.approved,
    required this.rejected,
  });

  int get total => pending + approved + rejected;
}
