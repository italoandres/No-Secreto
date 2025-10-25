import 'package:flutter/material.dart';

/// Seção que exibe informações de educação e carreira do perfil
///
/// Exibe formação acadêmica, universidade, status e profissão
class EducationInfoSection extends StatelessWidget {
  final String? education;
  final String? universityCourse;
  final String? courseStatus;
  final String? university;
  final String? occupation;

  const EducationInfoSection({
    Key? key,
    this.education,
    this.universityCourse,
    this.courseStatus,
    this.university,
    this.occupation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Se não houver nenhuma informação educacional, não renderizar
    if (!_hasEducationInfo()) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🎓 Educação e Carreira',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey[200]!,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Formação Acadêmica
                if (_hasAcademicInfo()) ...[
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.school,
                          color: Colors.blue[600],
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Formação',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (universityCourse?.isNotEmpty == true) ...[
                    Text(
                      universityCourse!,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF333333),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (university?.isNotEmpty == true) ...[
                    Text(
                      university!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (courseStatus?.isNotEmpty == true) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Text(
                        courseStatus!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                  if (occupation?.isNotEmpty == true)
                    const SizedBox(height: 20),
                ],

                // Profissão
                if (occupation?.isNotEmpty == true) ...[
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.purple[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.work,
                          color: Colors.purple[600],
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Profissão',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    occupation!,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF333333),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Verifica se há informações educacionais
  bool _hasEducationInfo() {
    return _hasAcademicInfo() || occupation?.isNotEmpty == true;
  }

  /// Verifica se há informações acadêmicas
  bool _hasAcademicInfo() {
    return education?.isNotEmpty == true ||
        universityCourse?.isNotEmpty == true ||
        university?.isNotEmpty == true ||
        courseStatus?.isNotEmpty == true;
  }
}
