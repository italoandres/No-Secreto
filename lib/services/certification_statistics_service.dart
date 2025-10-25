import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/certification_request_model.dart';

/// Serviço de estatísticas para certificações
class CertificationStatisticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Obtém estatísticas gerais do sistema
  Future<CertificationOverallStats> getOverallStats() async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startOfDay = DateTime(now.year, now.month, now.day);

      // ✅ CORRIGIDO: Adicionado orderBy e limit(1000)
      final allCertifications = await _firestore
          .collection('spiritual_certifications')
          .orderBy('createdAt', descending: true)
          .limit(1000)
          .get();

      final certifications = allCertifications.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return CertificationRequestModel.fromMap(data);
      }).toList();

      final total = certifications.length;
      final pending = certifications
          .where((c) => c.status == CertificationStatus.pending)
          .length;
      final approved = certifications
          .where((c) => c.status == CertificationStatus.approved)
          .length;
      final rejected = certifications
          .where((c) => c.status == CertificationStatus.rejected)
          .length;

      final thisMonth = certifications
          .where((c) => c.requestedAt.isAfter(startOfMonth))
          .length;
      final thisWeek = certifications
          .where((c) => c.requestedAt.isAfter(startOfWeek))
          .length;
      final today =
          certifications.where((c) => c.requestedAt.isAfter(startOfDay)).length;

      final processedCertifications =
          certifications.where((c) => c.reviewedAt != null).toList();

      double avgProcessingTime = 0;
      if (processedCertifications.isNotEmpty) {
        final totalProcessingTime = processedCertifications
            .map((c) => c.reviewedAt!.difference(c.requestedAt).inHours)
            .reduce((a, b) => a + b);
        avgProcessingTime =
            totalProcessingTime / processedCertifications.length;
      }

      return CertificationOverallStats(
        total: total,
        pending: pending,
        approved: approved,
        rejected: rejected,
        thisMonth: thisMonth,
        thisWeek: thisWeek,
        today: today,
        avgProcessingTimeHours: avgProcessingTime,
        approvalRate: total > 0 ? (approved / total) * 100 : 0,
        rejectionRate: total > 0 ? (rejected / total) * 100 : 0,
      );
    } catch (e) {
      print('Erro ao obter estatísticas gerais: $e');
      return CertificationOverallStats.empty();
    }
  }

  /// Obtém estatísticas por período (últimos N dias)
  Future<List<DailyStats>> getDailyStats(int days) async {
    try {
      final now = DateTime.now();
      final startDate = now.subtract(Duration(days: days));

      // ✅ CORRIGIDO: Adicionado limit(500)
      final snapshot = await _firestore
          .collection('spiritual_certifications')
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .orderBy('createdAt')
          .limit(500)
          .get();

      final certifications = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return CertificationRequestModel.fromMap(data);
      }).toList();

      final Map<String, DailyStats> dailyMap = {};

      for (int i = 0; i < days; i++) {
        final date = now.subtract(Duration(days: i));
        final dateKey =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        dailyMap[dateKey] = DailyStats(
          date: date,
          requests: 0,
          approvals: 0,
          rejections: 0,
        );
      }

      for (final cert in certifications) {
        final dateKey =
            '${cert.requestedAt.year}-${cert.requestedAt.month.toString().padLeft(2, '0')}-${cert.requestedAt.day.toString().padLeft(2, '0')}';

        if (dailyMap.containsKey(dateKey)) {
          dailyMap[dateKey] = dailyMap[dateKey]!.copyWith(
            requests: dailyMap[dateKey]!.requests + 1,
          );
        }
      }

      for (final cert in certifications) {
        if (cert.reviewedAt != null) {
          final dateKey =
              '${cert.reviewedAt!.year}-${cert.reviewedAt!.month.toString().padLeft(2, '0')}-${cert.reviewedAt!.day.toString().padLeft(2, '0')}';

          if (dailyMap.containsKey(dateKey)) {
            if (cert.status == CertificationStatus.approved) {
              dailyMap[dateKey] = dailyMap[dateKey]!.copyWith(
                approvals: dailyMap[dateKey]!.approvals + 1,
              );
            } else if (cert.status == CertificationStatus.rejected) {
              dailyMap[dateKey] = dailyMap[dateKey]!.copyWith(
                rejections: dailyMap[dateKey]!.rejections + 1,
              );
            }
          }
        }
      }

      return dailyMap.values.toList()..sort((a, b) => a.date.compareTo(b.date));
    } catch (e) {
      print('Erro ao obter estatísticas diárias: $e');
      return [];
    }
  }
}

/// Estatísticas gerais do sistema
class CertificationOverallStats {
  final int total;
  final int pending;
  final int approved;
  final int rejected;
  final int thisMonth;
  final int thisWeek;
  final int today;
  final double avgProcessingTimeHours;
  final double approvalRate;
  final double rejectionRate;

  CertificationOverallStats({
    required this.total,
    required this.pending,
    required this.approved,
    required this.rejected,
    required this.thisMonth,
    required this.thisWeek,
    required this.today,
    required this.avgProcessingTimeHours,
    required this.approvalRate,
    required this.rejectionRate,
  });

  factory CertificationOverallStats.empty() {
    return CertificationOverallStats(
      total: 0,
      pending: 0,
      approved: 0,
      rejected: 0,
      thisMonth: 0,
      thisWeek: 0,
      today: 0,
      avgProcessingTimeHours: 0,
      approvalRate: 0,
      rejectionRate: 0,
    );
  }
}

/// Estatísticas diárias
class DailyStats {
  final DateTime date;
  final int requests;
  final int approvals;
  final int rejections;

  DailyStats({
    required this.date,
    required this.requests,
    required this.approvals,
    required this.rejections,
  });

  DailyStats copyWith({
    DateTime? date,
    int? requests,
    int? approvals,
    int? rejections,
  }) {
    return DailyStats(
      date: date ?? this.date,
      requests: requests ?? this.requests,
      approvals: approvals ?? this.approvals,
      rejections: rejections ?? this.rejections,
    );
  }
}