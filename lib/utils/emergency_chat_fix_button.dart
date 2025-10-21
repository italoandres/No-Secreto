import 'package:flutter/material.dart';
import 'fix_timestamp_chat_errors.dart';

/// Botão de emergência para correção de chat
class EmergencyChatFixButton extends StatefulWidget {
  @override
  _EmergencyChatFixButtonState createState() => _EmergencyChatFixButtonState();
}

class _EmergencyChatFixButtonState extends State<EmergencyChatFixButton> {
  bool _isFixing = false;
  String _status = 'Pronto para corrigir';

  Future<void> _runEmergencyFix() async {
    setState(() {
      _isFixing = true;
      _status = 'Corrigindo timestamps...';
    });

    try {
      // Executar correção de timestamps
      await TimestampChatErrorsFixer.fixAllTimestampErrors();
      
      setState(() {
        _status = 'Testando sistema...';
      });
      
      // Testar após correção
      await TimestampChatErrorsFixer.testAfterFix();
      
      setState(() {
        _status = '✅ Correção concluída!';
      });
      
      // Mostrar sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 Sistema de chat corrigido com sucesso!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
      
    } catch (e) {
      setState(() {
        _status = '❌ Erro: $e';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erro na correção: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }

    setState(() {
      _isFixing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Botão de emergência
          ElevatedButton.icon(
            onPressed: _isFixing ? null : _runEmergencyFix,
            icon: _isFixing
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(Icons.healing, color: Colors.white),
            label: Text(
              _isFixing ? 'Corrigindo...' : 'CORRIGIR CHAT AGORA',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          
          SizedBox(height: 8),
          
          // Status
          Text(
            _status,
            style: TextStyle(
              fontSize: 12,
              color: _status.contains('✅') 
                  ? Colors.green 
                  : _status.contains('❌') 
                      ? Colors.red 
                      : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Widget flutuante para correção de emergência
class FloatingEmergencyFixButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 80,
      right: 16,
      child: FloatingActionButton.extended(
        onPressed: () async {
          // Mostrar dialog de confirmação
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('🚨 Correção de Emergência'),
              content: Text(
                'Isso irá corrigir os erros de timestamp do chat.\n\n'
                'Continuar?'
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text('Corrigir'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
          
          if (confirm == true) {
            // Mostrar bottom sheet com o botão de correção
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (context) => Container(
                padding: EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '🔧 Correção de Chat',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    EmergencyChatFixButton(),
                    SizedBox(height: 16),
                  ],
                ),
              ),
            );
          }
        },
        icon: Icon(Icons.healing),
        label: Text('FIX CHAT'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
    );
  }
}