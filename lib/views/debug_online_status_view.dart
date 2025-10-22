import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:whatsapp_chat/utils/add_last_seen_to_users.dart';
import 'package:whatsapp_chat/services/online_status_service.dart';

class DebugOnlineStatusView extends StatefulWidget {
  const DebugOnlineStatusView({super.key});

  @override
  State<DebugOnlineStatusView> createState() => _DebugOnlineStatusViewState();
}

class _DebugOnlineStatusViewState extends State<DebugOnlineStatusView> {
  bool _isLoading = false;
  String _status = 'Pronto para executar';
  final List<String> _logs = [];

  void _addLog(String log) {
    setState(() {
      _logs.add(log);
      _status = log;
    });
  }

  Future<void> _addLastSeenToAllUsers() async {
    setState(() {
      _isLoading = true;
      _logs.clear();
    });
    
    _addLog('🔄 Iniciando atualização...');

    try {
      await AddLastSeenToUsers.addLastSeenToUsersBatch();
      _addLog('✅ Sucesso! Campo lastSeen adicionado a todos os usuários.');
    } catch (e) {
      _addLog('❌ Erro: $e');
      print('Erro detalhado: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateMyLastSeen() async {
    setState(() {
      _isLoading = true;
      _logs.clear();
    });
    
    _addLog('🔄 Atualizando meu lastSeen...');

    try {
      await OnlineStatusService.updateLastSeen();
      _addLog('✅ Sucesso! Seu lastSeen foi atualizado.');
    } catch (e) {
      _addLog('❌ Erro: $e');
      print('Erro detalhado: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Debug - Status Online',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status Online - Configuração',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Execute estas ações para configurar o sistema de status online:',
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Botão para adicionar lastSeen
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _addLastSeenToAllUsers,
              icon: const Icon(Icons.group_add),
              label: Text(
                'Adicionar lastSeen a Todos os Usuários',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF39b9ff),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Botão para testar atualização
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _updateMyLastSeen,
              icon: const Icon(Icons.refresh),
              label: Text(
                'Testar - Atualizar Meu LastSeen',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFfc6aeb),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Status e Logs
            Card(
              color: Colors.grey[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isLoading ? Icons.hourglass_empty : Icons.info,
                          color: _isLoading ? Colors.orange : Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Status:',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _status,
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                    if (_isLoading) ...[
                      const SizedBox(height: 12),
                      const LinearProgressIndicator(),
                    ],
                    if (_logs.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        'Logs:',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _logs.map((log) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                log,
                                style: GoogleFonts.robotoMono(fontSize: 11),
                              ),
                            )).toList(),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Instruções
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lightbulb, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Como usar:',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '1. Execute "Adicionar lastSeen" uma vez para configurar todos os usuários\n'
                      '2. Teste com "Atualizar Meu LastSeen"\n'
                      '3. Abra um chat para ver o status online funcionando\n'
                      '4. O status é atualizado automaticamente quando o usuário usa o app',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
