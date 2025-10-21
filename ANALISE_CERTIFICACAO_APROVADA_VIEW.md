# 🔍 Análise - Reconhecimento de Certificação Aprovada na View

## 🎯 Objetivo

Modificar `SpiritualCertificationRequestView` para:
1. Detectar se usuário já tem certificação aprovada
2. Mostrar card especial "Certificação Aprovada" em vez do formulário
3. Manter toggle permanentemente habilitado (sem poder desabilitar)

## 📊 Comportamentos Necessários

### Caso 1: Usuário SEM certificação
- Toggle: Pode ligar/desligar normalmente
- Conteúdo: Formulário de solicitação OU call-to-action da mentoria

### Caso 2: Usuário COM certificação PENDENTE
- Toggle: Permanentemente habilitado (não pode desabilitar)
- Conteúdo: Card informando "Solicitação em Análise"

### Caso 3: Usuário COM certificação APROVADA
- Toggle: Permanentemente habilitado (não pode desabilitar)
- Conteúdo: Card especial "Certificação Aprovada" com selo dourado

### Caso 4: Usuário COM certificação REJEITADA
- Toggle: Pode ligar/desligar normalmente
- Conteúdo: Card informando motivo da rejeição + formulário para nova solicitação

## 🔧 Mudanças Necessárias

### 1. Adicionar verificação de status
```dart
// No initState ou didChangeDependencies
Future<void> _checkCertificationStatus() async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return;
  
  // Verificar se tem certificação aprovada
  final hasApproved = await CertificationStatusHelper.hasApprovedCertification(userId);
  
  // Verificar se tem certificação pendente
  final hasPending = await CertificationStatusHelper.hasPendingCertification(userId);
  
  // Buscar última certificação (para pegar detalhes se rejeitada)
  final latestCert = await _repository.getLatestRequest(userId);
  
  setState(() {
    _hasApprovedCertification = hasApproved;
    _hasPendingCertification = hasPending;
    _latestCertification = latestCert;
    
    // Se tem aprovada ou pendente, toggle fica ligado
    if (hasApproved || hasPending) {
      _isReady.value = true;
    }
  });
}
```

### 2. Modificar o Toggle
```dart
Widget _buildReadyToggle() {
  // Se tem certificação aprovada ou pendente, não pode desabilitar
  final canToggle = !_hasApprovedCertification && !_hasPendingCertification;
  
  return Container(
    // ... mesmo design
    child: Row(
      children: [
        Expanded(
          child: Column(
            // ... mesmo conteúdo
            children: [
              if (!canToggle)
                Text(
                  '✓ Certificação ativa',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
        Switch(
          value: _isReady.value,
          onChanged: canToggle ? (value) {
            _isReady.value = value;
          } : null, // null = desabilitado
          activeColor: Colors.green.shade600,
        ),
      ],
    ),
  );
}
```

### 3. Criar Card de Certificação Aprovada
```dart
Widget _buildApprovedCertificationCard() {
  return Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.amber.shade50,
          Colors.yellow.shade50,
        ],
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: Colors.amber.shade300,
        width: 2,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.amber.shade200.withOpacity(0.5),
          blurRadius: 15,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: Column(
      children: [
        // Ícone grande dourado
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.amber.shade700,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.amber.shade300,
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Icon(
            Icons.workspace_premium,
            size: 64,
            color: Colors.white,
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Título
        Text(
          '🎉 Certificação Aprovada!',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.amber.shade900,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 12),
        
        // Mensagem
        Text(
          'Seu perfil agora possui o selo dourado de certificação espiritual',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade700,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 24),
        
        // Benefícios ativos
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade600),
                  const SizedBox(width: 8),
                  Text(
                    'Benefícios Ativos:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildBenefit('Selo dourado visível em seu perfil'),
              _buildBenefit('Destaque na comunidade'),
              _buildBenefit('Maior credibilidade'),
              _buildBenefit('Prioridade em matches'),
            ],
          ),
        ),
      ],
    ),
  );
}
```

### 4. Criar Card de Certificação Pendente
```dart
Widget _buildPendingCertificationCard() {
  return Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.blue.shade50,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.blue.shade200),
    ),
    child: Column(
      children: [
        Icon(Icons.hourglass_empty, size: 64, color: Colors.blue.shade600),
        const SizedBox(height: 16),
        Text(
          'Solicitação em Análise',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade900,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Sua solicitação está sendo analisada. Você será notificado em breve!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    ),
  );
}
```

### 5. Modificar lógica de exibição
```dart
// No build, dentro do Obx
if (_isReady.value) {
  if (_hasApprovedCertification) {
    _buildApprovedCertificationCard()
  } else if (_hasPendingCertification) {
    _buildPendingCertificationCard()
  } else {
    _buildCertificationForm()
  }
} else {
  _buildMentoriaCallToAction()
}
```

## ⚠️ Cuidados

1. **Não quebrar funcionalidade existente** - Manter formulário funcionando para novos usuários
2. **Loading state** - Mostrar loading enquanto verifica status
3. **Refresh** - Permitir pull-to-refresh para atualizar status
4. **Navegação** - Ao voltar da tela, atualizar status

## 📝 Arquivos a Modificar

1. `lib/views/spiritual_certification_request_view.dart` - Adicionar lógica de verificação e novos cards
2. `lib/utils/certification_status_helper.dart` - Já existe e funciona ✅
3. `lib/repositories/spiritual_certification_repository.dart` - Já tem método `getLatestRequest` ✅

## ✅ Checklist de Implementação

- [ ] Adicionar variáveis de estado para certificação
- [ ] Adicionar método `_checkCertificationStatus()`
- [ ] Modificar toggle para desabilitar quando necessário
- [ ] Criar `_buildApprovedCertificationCard()`
- [ ] Criar `_buildPendingCertificationCard()`
- [ ] Modificar lógica de exibição condicional
- [ ] Adicionar loading state
- [ ] Testar todos os cenários
