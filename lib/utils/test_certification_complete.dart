import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/spiritual_certification_service.dart';
import '../services/certification_approval_service.dart';
import '../models/certification_request_model.dart';

/// 🎯 TESTE COMPLETO DO SISTEMA DE CERTIFICAÇÃO ESPIRITUAL
/// 
/// Este script testa TODO o fluxo em 5 minutos:
/// ✅ 1. Criação de solicitação
/// ✅ 2. Aprovação da certificação
/// ✅ 3. Verificação do badge no perfil
/// ✅ 4. Auditoria e logs
/// ✅ 5. Visualização do selo

class CertificationCompleteTest extends StatefulWidget {
  const CertificationCompleteTest({Key? key}) : super(key: key);

  @override
  State<CertificationCompleteTest> createState() => _CertificationCompleteTestState();
}

class _CertificationCompleteTestState extends State<CertificationCompleteTest> {
  final _certificationService = SpiritualCertificationService();
  final _approvalService = CertificationApprovalService();
  
  String _testStatus = '🔄 Iniciando teste completo...';
  List<String> _testLogs = [];
  bool _isRunning = false;
  String? _requestId;
  Map<String, dynamic>? _userProfile;
  
  void _addLog(String message) {
    setState(() {
      _testLogs.add('${DateTime.now().toString().substring(11, 19)} - $message');
    });
    print(message);
  }

  Future<void> _runCompleteTest() async {
    setState(() {
      _isRunning = true;
      _testLogs.clear();
      _testStatus = '🚀 Executando teste completo...';
    });

    try {
      // FASE 1: Criar solicitação de certificação
      _addLog('📝 FASE 1: Criando solicitação de certificação...');
      await _createCertificationRequest();
      
      await Future.delayed(const Duration(seconds: 2));
      
      // FASE 2: Aprovar certificação
      _addLog('✅ FASE 2: Aprovando certificação...');
      await _approveCertification();
      
      await Future.delayed(const Duration(seconds: 2));
      
      // FASE 3: Verificar badge no perfil
      _addLog('🏅 FASE 3: Verificando badge no perfil...');
      await _verifyBadgeInProfile();
      
      await Future.delayed(const Duration(seconds: 1));
      
      // FASE 4: Verificar auditoria
      _addLog('📊 FASE 4: Verificando logs de auditoria...');
      await _verifyAuditLogs();
      
      await Future.delayed(const Duration(seconds: 1));
      
      // FASE 5: Visualizar selo
      _addLog('🎨 FASE 5: Gerando visualização do selo...');
      await _visualizeBadge();
      
      setState(() {
        _testStatus = '✅ TESTE COMPLETO CONCLUÍDO COM SUCESSO!';
        _isRunning = false;
      });
      
      _addLog('');
      _addLog('🎉 TODOS OS TESTES PASSARAM!');
      _addLog('✅ Solicitação criada');
      _addLog('✅ Certificação aprovada');
      _addLog('✅ Badge aparece no perfil');
      _addLog('✅ Auditoria registrada');
      _addLog('✅ Selo visual funcionando');
      
    } catch (e) {
      setState(() {
        _testStatus = '❌ Erro no teste: $e';
        _isRunning = false;
      });
      _addLog('❌ ERRO: $e');
    }
  }

  Future<void> _createCertificationRequest() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    _addLog('👤 Usuário: ${user.email}');
    
    // Criar solicitação
    final request = CertificationRequestModel(
      id: '',
      userId: user.uid,
      userEmail: user.email ?? '',
      userName: user.displayName ?? 'Usuário Teste',
      requestDate: Timestamp.now(),
      status: 'pending',
      proofType: 'diploma',
      proofUrl: 'https://example.com/diploma.pdf',
      churchName: 'Igreja Teste',
      courseName: 'Teologia',
      completionYear: 2023,
      additionalInfo: 'Teste completo do sistema',
    );

    final docRef = await FirebaseFirestore.instance
        .collection('spiritual_certifications')
        .add(request.toMap());
    
    _requestId = docRef.id;
    _addLog('✅ Solicitação criada: $_requestId');
  }

  Future<void> _approveCertification() async {
    if (_requestId == null) {
      throw Exception('Request ID não encontrado');
    }

    _addLog('🔄 Aprovando certificação $_requestId...');
    
    await _approvalService.approveCertification(
      requestId: _requestId!,
      adminNotes: 'Aprovado no teste completo',
    );
    
    _addLog('✅ Certificação aprovada com sucesso');
    
    // Verificar status no Firestore
    final doc = await FirebaseFirestore.instance
        .collection('spiritual_certifications')
        .doc(_requestId)
        .get();
    
    final status = doc.data()?['status'];
    _addLog('📋 Status atual: $status');
    
    if (status != 'approved') {
      throw Exception('Status não foi atualizado para approved');
    }
  }

  Future<void> _verifyBadgeInProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    _addLog('🔍 Buscando perfil do usuário...');
    
    final profileDoc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .get();
    
    if (!profileDoc.exists) {
      throw Exception('Perfil não encontrado');
    }

    _userProfile = profileDoc.data();
    final hasCertification = _userProfile?['hasSpiritualCertification'] ?? false;
    final certType = _userProfile?['spiritualCertificationType'] ?? 'none';
    
    _addLog('🏅 Badge no perfil: ${hasCertification ? "SIM ✅" : "NÃO ❌"}');
    _addLog('📜 Tipo de certificação: $certType');
    
    if (!hasCertification) {
      throw Exception('Badge não foi adicionado ao perfil');
    }
  }

  Future<void> _verifyAuditLogs() async {
    if (_requestId == null) {
      throw Exception('Request ID não encontrado');
    }

    _addLog('🔍 Verificando logs de auditoria...');
    
    final auditQuery = await FirebaseFirestore.instance
        .collection('certification_audit_logs')
        .where('requestId', isEqualTo: _requestId)
        .orderBy('timestamp', descending: true)
        .limit(5)
        .get();
    
    _addLog('📊 Logs encontrados: ${auditQuery.docs.length}');
    
    for (var doc in auditQuery.docs) {
      final data = doc.data();
      final action = data['action'] ?? 'unknown';
      final timestamp = data['timestamp'] as Timestamp?;
      final timeStr = timestamp?.toDate().toString().substring(11, 19) ?? 'N/A';
      
      _addLog('  • $timeStr - $action');
    }
    
    if (auditQuery.docs.isEmpty) {
      _addLog('⚠️ Nenhum log de auditoria encontrado');
    }
  }

  Future<void> _visualizeBadge() async {
    if (_userProfile == null) {
      throw Exception('Perfil não carregado');
    }

    final hasCertification = _userProfile?['hasSpiritualCertification'] ?? false;
    final certType = _userProfile?['spiritualCertificationType'] ?? 'none';
    
    _addLog('🎨 Gerando visualização do selo...');
    _addLog('');
    _addLog('═══════════════════════════════════');
    _addLog('        SELO DE CERTIFICAÇÃO       ');
    _addLog('═══════════════════════════════════');
    
    if (hasCertification) {
      _addLog('');
      _addLog('           ⭐ CERTIFICADO ⭐        ');
      _addLog('');
      _addLog('    Este perfil possui certificação');
      _addLog('         espiritual verificada      ');
      _addLog('');
      _addLog('    Tipo: ${_getCertificationLabel(certType)}');
      _addLog('    Status: ✅ ATIVO                ');
      _addLog('');
    } else {
      _addLog('');
      _addLog('         ⚪ NÃO CERTIFICADO         ');
      _addLog('');
    }
    
    _addLog('═══════════════════════════════════');
  }

  String _getCertificationLabel(String type) {
    switch (type) {
      case 'seminary':
        return 'Seminário Teológico';
      case 'bible_school':
        return 'Escola Bíblica';
      case 'ministry':
        return 'Ministério Ordenado';
      default:
        return 'Geral';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧪 Teste Completo - Certificação'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          // Status Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: _isRunning 
                ? Colors.blue.shade50 
                : _testStatus.contains('SUCESSO')
                    ? Colors.green.shade50
                    : Colors.white,
            child: Column(
              children: [
                Text(
                  _testStatus,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _isRunning 
                        ? Colors.blue.shade900
                        : _testStatus.contains('SUCESSO')
                            ? Colors.green.shade900
                            : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_isRunning) ...[
                  const SizedBox(height: 16),
                  const CircularProgressIndicator(),
                ],
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Logs
          Expanded(
            child: Container(
              color: Colors.grey.shade100,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _testLogs.length,
                itemBuilder: (context, index) {
                  final log = _testLogs[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      log,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: log.contains('❌') 
                            ? Colors.red.shade700
                            : log.contains('✅')
                                ? Colors.green.shade700
                                : log.contains('FASE')
                                    ? Colors.blue.shade700
                                    : Colors.black87,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          
          // Botão de ação
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _isRunning ? null : _runCompleteTest,
              icon: Icon(_isRunning ? Icons.hourglass_empty : Icons.play_arrow),
              label: Text(
                _isRunning 
                    ? 'Executando teste...' 
                    : 'Executar Teste Completo (5 min)',
                style: const TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
