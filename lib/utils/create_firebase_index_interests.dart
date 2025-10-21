import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/enhanced_logger.dart';

class CreateFirebaseIndexInterests {
  static final EnhancedLogger _logger = EnhancedLogger('CreateFirebaseIndexInterests');

  /// URL para criar índice composto no Firebase Console
  static const String _firebaseIndexUrl = 
      'https://console.firebase.google.com/project/_/firestore/indexes?create_composite=Interests:to,timestamp';

  /// Abre o Firebase Console para criar o índice necessário
  static Future<void> openFirebaseIndexCreation(BuildContext context) async {
    try {
      _logger.info('🔗 Abrindo Firebase Console para criar índice');
      
      final Uri url = Uri.parse(_firebaseIndexUrl);
      
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        _logger.success('✅ Firebase Console aberto');
        
        // Mostra instruções
        _showIndexInstructions(context);
      } else {
        _logger.error('❌ Não foi possível abrir o Firebase Console');
        _showManualInstructions(context);
      }
    } catch (e) {
      _logger.error('❌ Erro ao abrir Firebase Console', error: e);
      _showManualInstructions(context);
    }
  }

  /// Mostra instruções para criar o índice
  static void _showIndexInstructions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('📋 Instruções para Criar Índice'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'O Firebase Console foi aberto. Siga estes passos:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text('1. 📁 Selecione a coleção: interests'),
              SizedBox(height: 8),
              Text('2. ➕ Clique em "Create Index"'),
              SizedBox(height: 8),
              Text('3. 🔧 Configure os campos:'),
              SizedBox(height: 4),
              Padding(
                padding: EdgeInsets.only(left: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• Campo 1: to (Ascending)'),
                    Text('• Campo 2: timestamp (Descending)'),
                  ],
                ),
              ),
              SizedBox(height: 8),
              Text('4. ✅ Clique em "Create"'),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💡 Dica:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'O índice pode levar alguns minutos para ser criado. '
                      'Você receberá um email quando estiver pronto.',
                      style: TextStyle(color: Colors.blue.shade700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Entendi'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _copyIndexCommand(context);
            },
            child: Text('Copiar Comando CLI'),
          ),
        ],
      ),
    );
  }

  /// Mostra instruções manuais caso não consiga abrir o link
  static void _showManualInstructions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('📋 Instruções Manuais'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Acesse manualmente o Firebase Console:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text('1. 🌐 Acesse: console.firebase.google.com'),
              SizedBox(height: 8),
              Text('2. 📁 Selecione seu projeto'),
              SizedBox(height: 8),
              Text('3. 🗃️ Vá em Firestore Database > Indexes'),
              SizedBox(height: 8),
              Text('4. ➕ Clique em "Create Index"'),
              SizedBox(height: 8),
              Text('5. 🔧 Configure:'),
              SizedBox(height: 4),
              Padding(
                padding: EdgeInsets.only(left: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• Collection: interests'),
                    Text('• Campo 1: to (Ascending)'),
                    Text('• Campo 2: timestamp (Descending)'),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _firebaseIndexUrl,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Entendi'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _copyIndexCommand(context);
            },
            child: Text('Copiar Comando CLI'),
          ),
        ],
      ),
    );
  }

  /// Copia comando CLI para criar o índice
  static void _copyIndexCommand(BuildContext context) {
    const String cliCommand = '''
firebase firestore:indexes

# Adicione este índice ao seu firestore.indexes.json:
{
  "indexes": [
    {
      "collectionGroup": "interests",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "to",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "timestamp",
          "order": "DESCENDING"
        }
      ]
    }
  ]
}

# Depois execute:
firebase deploy --only firestore:indexes
''';

    // Aqui você pode implementar a cópia para clipboard
    // Por exemplo, usando o package flutter/services
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('📋 Comando CLI'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Copie e execute este comando:'),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  cliCommand,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Widget para incluir na UI
  static Widget buildIndexCreationWidget(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Índice Firebase Necessário',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              'Para que as notificações de interesse funcionem corretamente, '
              'é necessário criar um índice composto no Firebase.',
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => openFirebaseIndexCreation(context),
                icon: Icon(Icons.open_in_new),
                label: Text('Criar Índice no Firebase'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Verifica se o índice provavelmente existe (teste básico)
  static Future<bool> checkIndexExists() async {
    try {
      _logger.info('🔍 Verificando se índice existe...');
      
      // Aqui você pode implementar uma verificação mais robusta
      // Por exemplo, tentando fazer uma query que requer o índice
      
      // Por enquanto, retorna false para sempre mostrar o aviso
      return false;
    } catch (e) {
      _logger.error('❌ Erro ao verificar índice', error: e);
      return false;
    }
  }
}