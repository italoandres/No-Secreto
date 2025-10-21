import 'package:flutter/material.dart';
import '../utils/fix_existing_chat_system.dart';
import '../utils/fix_specific_missing_chat.dart';
import '../utils/fix_timestamp_chat_errors.dart';
import '../services/chat_system_integrator.dart';

/// Tela de teste completa para o sistema de chat
class ChatSystemTestView extends StatefulWidget {
  @override
  _ChatSystemTestViewState createState() => _ChatSystemTestViewState();
}

class _ChatSystemTestViewState extends State<ChatSystemTestView> {
  bool _isRunning = false;
  List<String> _logs = [];
  String _currentStep = '';

  Future<void> _runCompleteTest() async {
    setState(() {
      _isRunning = true;
      _logs.clear();
      _currentStep = 'Iniciando...';
    });

    try {
      // Passo 1: Correção de timestamps (NOVO - mais importante)
      _updateStep('Passo 1: Correção de timestamps');
      _addLog('🔧 Corrigindo erros de timestamp...');
      await TimestampChatErrorsFixer.fixAllTimestampErrors();
      _addLog('✅ Timestamps corrigidos');

      // Passo 2: Correção geral do sistema
      _updateStep('Passo 2: Correção geral do sistema');
      _addLog('🚀 Iniciando correção geral...');
      await ExistingChatSystemFixer.fixExistingSystem();
      _addLog('✅ Correção geral concluída');

      // Passo 3: Correção específica do chat problemático
      _updateStep('Passo 3: Correção do chat específico');
      _addLog('🔧 Corrigindo chat específico...');
      await SpecificMissingChatFixer.fixMissingChat();
      _addLog('✅ Chat específico corrigido');

      // Passo 4: Teste do sistema integrado
      _updateStep('Passo 4: Teste do sistema integrado');
      _addLog('🧪 Testando sistema integrado...');
      await ChatSystemIntegrator.testIntegratedSystem();
      _addLog('✅ Sistema integrado testado');

      // Passo 5: Teste final
      _updateStep('Passo 5: Teste final');
      _addLog('🎯 Executando teste final...');
      await TimestampChatErrorsFixer.testAfterFix();
      await ExistingChatSystemFixer.testFixedSystem();
      await SpecificMissingChatFixer.testSpecificChat();
      _addLog('✅ Teste final concluído');

      _updateStep('✅ Concluído com sucesso!');
      _addLog('🎉 SISTEMA COMPLETAMENTE CORRIGIDO!');

    } catch (e) {
      _addLog('❌ Erro: $e');
      _updateStep('❌ Erro na execução');
    }

    setState(() {
      _isRunning = false;
    });
  }

  void _updateStep(String step) {
    setState(() {
      _currentStep = step;
    });
  }

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toString().substring(11, 19)} - $message');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sistema de Chat - Teste Completo'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status atual
            Card(
              color: _isRunning ? Colors.blue[50] : Colors.green[50],
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status Atual:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        if (_isRunning)
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        if (_isRunning) SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _currentStep,
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Problemas identificados
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Problemas Identificados:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text('❌ TypeError: null is not a subtype of type \'Timestamp\''),
                    Text('❌ Chat não encontrado: match_St2kw3cgX2MMPxlLRmBDjYm2nO22_dLHuF1kUDTNe7PgdBLbmynrdpft1'),
                    Text('❌ Notificação já respondida'),
                    Text('❌ Índice Firebase faltando para interest_notifications'),
                    Text('❌ Erro ao inicializar chat'),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Correções que serão aplicadas
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Correções que serão aplicadas:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text('✅ Corrigir todos os timestamps null'),
                    Text('✅ Criar chats faltando automaticamente'),
                    Text('✅ Corrigir notificações duplicadas'),
                    Text('✅ Integrar sistema robusto'),
                    Text('✅ Sanitizar dados de timestamp'),
                    Text('✅ Criar fallbacks para índices faltando'),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Botão principal
            ElevatedButton.icon(
              onPressed: _isRunning ? null : _runCompleteTest,
              icon: _isRunning
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.play_arrow),
              label: Text(_isRunning ? 'Executando Correções...' : 'Executar Correção Completa'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            SizedBox(height: 16),

            // Botões individuais
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isRunning ? null : () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => TimestampFixerWidget()),
                    ),
                    child: Text('Timestamps'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 4),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isRunning ? null : () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ChatSystemFixerWidget()),
                    ),
                    child: Text('Geral'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 4),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isRunning ? null : () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SpecificChatFixerWidget()),
                    ),
                    child: Text('Específico'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            // Logs
            if (_logs.isNotEmpty) ...[
              Text(
                'Logs da Execução:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: ListView.builder(
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      final log = _logs[index];
                      Color? textColor;
                      
                      if (log.contains('❌')) {
                        textColor = Colors.red;
                      } else if (log.contains('✅')) {
                        textColor = Colors.green;
                      } else if (log.contains('🎉')) {
                        textColor = Colors.blue;
                      }
                      
                      return Text(
                        log,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: textColor,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}