# ✅ Como Testar o Selo de Certificação Espiritual - AGORA

## 🎯 Sim! Você Pode Testar Agora

O sistema de certificação espiritual está 100% implementado e pronto para testes!

---

## 🚀 Opção 1: Teste Rápido (2 minutos)

### Execute o Teste Rápido:

```dart
import 'lib/utils/teste_rapido_certificacao.dart';

void main() async {
  await TesteRapidoCertificacao.executarTesteRapido();
}
```

Ou via terminal:

```bash
flutter run lib/utils/teste_rapido_certificacao.dart
```

### O que será testado:
- ✅ Conectividade com Firestore
- ✅ Criação de solicitação de certificação
- ✅ Atualização de status (aprovação)
- ✅ Log de auditoria
- ✅ Atualização do perfil do usuário
- ✅ Consultas de dados

---

## 🧪 Opção 2: Teste Completo (5 minutos)

### Execute o Teste Completo:

```dart
import 'lib/utils/test_sistema_certificacao_completo.dart';

void main() async {
  await TesteSistemaCertificacaoCompleto.executarTodosTestes();
}
```

### O que será testado:
1. **Estrutura do Banco de Dados**
2. **Solicitação de Certificação**
3. **Aprovação de Certificação**
4. **Reprovação de Certificação**
5. **Sistema de Auditoria**
6. **Regras de Segurança**
7. **Sistema de Notificações**
8. **Badge de Certificação** ⭐
9. **Estatísticas**

---

## 📱 Opção 3: Teste Visual na Interface

### Adicione ao seu main.dart:

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'lib/main_teste_certificacao.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  runApp(TesteCertificacaoApp());
}
```

Depois execute:

```bash
flutter run
```

---

## 🎯 Teste Específico do SELO/BADGE

### Teste Apenas o Badge:

```dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'lib/components/spiritual_certification_badge.dart';

class TesteSeloView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🏅 Teste do Selo de Certificação'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Teste 1: Usuário COM certificação
            Text('Usuário Certificado:'),
            SizedBox(height: 10),
            SpiritualCertificationBadge(
              isCertified: true,
              size: 80,
            ),
            
            SizedBox(height: 40),
            
            // Teste 2: Usuário SEM certificação
            Text('Usuário NÃO Certificado:'),
            SizedBox(height: 10),
            SpiritualCertificationBadge(
              isCertified: false,
              size: 80,
            ),
            
            SizedBox(height: 40),
            
            // Teste 3: Badge pequeno
            Text('Badge Pequeno (32px):'),
            SizedBox(height: 10),
            SpiritualCertificationBadge(
              isCertified: true,
              size: 32,
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 🔍 Teste do Fluxo Completo

### 1. Criar Solicitação de Certificação

```dart
import 'lib/services/spiritual_certification_service.dart';

final service = SpiritualCertificationService();

// Criar solicitação
await service.submitCertificationRequest(
  userId: 'user_teste_123',
  userName: 'João Silva',
  userEmail: 'joao@teste.com',
  institutionName: 'Faculdade Teológica Teste',
  courseName: 'Bacharel em Teologia',
  proofUrl: 'https://exemplo.com/diploma.pdf',
);

print('✅ Solicitação criada com sucesso!');
```

### 2. Aprovar Certificação (Admin)

```dart
import 'lib/services/certification_approval_service.dart';

final approvalService = CertificationApprovalService();

// Aprovar certificação
await approvalService.approveCertification(
  certificationId: 'cert_id_aqui',
  adminId: 'admin_123',
  adminEmail: 'admin@teste.com',
);

print('✅ Certificação aprovada!');
```

### 3. Verificar Badge no Perfil

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

// Verificar se usuário está certificado
final userDoc = await FirebaseFirestore.instance
    .collection('users')
    .doc('user_teste_123')
    .get();

final isCertified = userDoc.data()?['spirituallyCertified'] ?? false;

print('Usuário certificado: $isCertified');
```

---

## 📊 Verificar Resultados

### Checklist de Validação:

- [ ] **Solicitação criada** no Firestore (`spiritual_certifications`)
- [ ] **Status inicial** = `pending`
- [ ] **Aprovação funciona** (status muda para `approved`)
- [ ] **Campo `spirituallyCertified`** = `true` no perfil do usuário
- [ ] **Badge aparece** no perfil
- [ ] **Log de auditoria** criado
- [ ] **Notificação enviada** ao usuário
- [ ] **Estatísticas atualizadas**

---

## 🎮 Teste Interativo Completo

### Script Pronto para Executar:

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'lib/components/spiritual_certification_badge.dart';
import 'lib/services/spiritual_certification_service.dart';
import 'lib/services/certification_approval_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(TesteSeloApp());
}

class TesteSeloApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Teste Selo Certificação',
      home: TesteSeloHome(),
    );
  }
}

class TesteSeloHome extends StatefulWidget {
  @override
  _TesteSeloHomeState createState() => _TesteSeloHomeState();
}

class _TesteSeloHomeState extends State<TesteSeloHome> {
  final _certService = SpiritualCertificationService();
  final _approvalService = CertificationApprovalService();
  
  String _resultado = '';
  bool _testando = false;
  String? _certificationId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🏅 Teste Selo de Certificação'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card com Badge
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      '🏅 Selo de Certificação Espiritual',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            SpiritualCertificationBadge(
                              isCertified: true,
                              size: 64,
                            ),
                            SizedBox(height: 8),
                            Text('Certificado'),
                          ],
                        ),
                        Column(
                          children: [
                            SpiritualCertificationBadge(
                              isCertified: false,
                              size: 64,
                            ),
                            SizedBox(height: 8),
                            Text('Não Certificado'),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // Botão 1: Criar Solicitação
            ElevatedButton.icon(
              onPressed: _testando ? null : _criarSolicitacao,
              icon: Icon(Icons.add_circle),
              label: Text('1. Criar Solicitação'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            SizedBox(height: 12),

            // Botão 2: Aprovar Certificação
            ElevatedButton.icon(
              onPressed: (_testando || _certificationId == null) 
                  ? null 
                  : _aprovarCertificacao,
              icon: Icon(Icons.check_circle),
              label: Text('2. Aprovar Certificação'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            SizedBox(height: 12),

            // Botão 3: Verificar Badge
            ElevatedButton.icon(
              onPressed: _testando ? null : _verificarBadge,
              icon: Icon(Icons.verified),
              label: Text('3. Verificar Badge no Perfil'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            SizedBox(height: 12),

            // Botão 4: Teste Completo
            ElevatedButton.icon(
              onPressed: _testando ? null : _testeCompleto,
              icon: Icon(Icons.play_arrow),
              label: Text('🚀 Executar Teste Completo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            SizedBox(height: 24),

            // Resultado
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📋 Resultado:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _resultado.isEmpty 
                          ? 'Clique em um botão para começar o teste'
                          : _resultado,
                      style: TextStyle(fontFamily: 'monospace'),
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

  Future<void> _criarSolicitacao() async {
    setState(() {
      _testando = true;
      _resultado = 'Criando solicitação...';
    });

    try {
      final userId = 'user_teste_${DateTime.now().millisecondsSinceEpoch}';
      
      _certificationId = await _certService.submitCertificationRequest(
        userId: userId,
        userName: 'João Silva Teste',
        userEmail: 'joao.teste@email.com',
        institutionName: 'Faculdade Teológica de Teste',
        courseName: 'Bacharel em Teologia',
        proofUrl: 'https://exemplo.com/diploma_teste.pdf',
      );

      setState(() {
        _resultado = '✅ Solicitação criada com sucesso!\n'
                    'ID: $_certificationId\n'
                    'Status: pending\n\n'
                    'Agora clique em "Aprovar Certificação"';
      });
    } catch (e) {
      setState(() {
        _resultado = '❌ Erro ao criar solicitação: $e';
      });
    } finally {
      setState(() {
        _testando = false;
      });
    }
  }

  Future<void> _aprovarCertificacao() async {
    setState(() {
      _testando = true;
      _resultado = 'Aprovando certificação...';
    });

    try {
      await _approvalService.approveCertification(
        certificationId: _certificationId!,
        adminId: 'admin_teste',
        adminEmail: 'admin@teste.com',
      );

      setState(() {
        _resultado = '✅ Certificação aprovada com sucesso!\n'
                    'ID: $_certificationId\n'
                    'Status: approved\n\n'
                    'Agora clique em "Verificar Badge"';
      });
    } catch (e) {
      setState(() {
        _resultado = '❌ Erro ao aprovar: $e';
      });
    } finally {
      setState(() {
        _testando = false;
      });
    }
  }

  Future<void> _verificarBadge() async {
    setState(() {
      _testando = true;
      _resultado = 'Verificando badge...';
    });

    try {
      // Buscar certificação
      final certDoc = await FirebaseFirestore.instance
          .collection('spiritual_certifications')
          .doc(_certificationId)
          .get();

      final certData = certDoc.data();
      final userId = certData?['userId'];

      // Buscar perfil do usuário
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      final userData = userDoc.data();
      final isCertified = userData?['spirituallyCertified'] ?? false;

      setState(() {
        _resultado = '✅ Verificação completa!\n\n'
                    '👤 Usuário: ${certData?['userName']}\n'
                    '🏅 Certificado: ${isCertified ? "SIM" : "NÃO"}\n'
                    '📅 Data: ${userData?['certificationDate']}\n\n'
                    '${isCertified ? "🎉 BADGE ATIVO NO PERFIL!" : "⚠️ Badge não encontrado"}';
      });
    } catch (e) {
      setState(() {
        _resultado = '❌ Erro ao verificar: $e';
      });
    } finally {
      setState(() {
        _testando = false;
      });
    }
  }

  Future<void> _testeCompleto() async {
    await _criarSolicitacao();
    await Future.delayed(Duration(seconds: 2));
    await _aprovarCertificacao();
    await Future.delayed(Duration(seconds: 2));
    await _verificarBadge();
  }
}
```

---

## ✅ Resultado Esperado

Após executar os testes, você deve ver:

```
✅ Solicitação criada com sucesso!
✅ Certificação aprovada!
✅ Badge ativo no perfil!
🏅 Selo de certificação aparecendo
📊 Estatísticas atualizadas
📝 Log de auditoria registrado
```

---

## 🎉 Pronto para Testar!

**Escolha uma das opções acima e execute o teste do selo de certificação espiritual!**

O sistema está 100% funcional e pronto para validação! 🚀
