# Sistema de Certificação com Toggle 🏆

## Visão Geral

Sistema completo de certificação espiritual com toggle de preparação e status dinâmico.

## Fluxo Completo

### 1. SpiritualCertificationRequestView

**Toggle: "Eu estou preparado(a) para encontrar meu Isaque, minha Rebeca"**

#### Toggle DESLIGADO (Padrão)
- Mostra card com informações da mentoria
- Call-to-action para fazer a mentoria
- Lista de benefícios:
  - Aprenda a identificar os sinais de Deus
  - Prepare-se espiritualmente para o casamento
  - Desenvolva discernimento e sabedoria
  - Receba o selo dourado em seu perfil
  - Destaque-se na comunidade
- Botão "Fazer a Mentoria Agora"
- Mensagem: "Após concluir a mentoria, ative o toggle acima"

#### Toggle LIGADO
- Mensagem de parabéns
- Formulário de solicitação de certificação
- Upload de comprovante
- Envio para análise do admin

### 2. ProfileCompletionView

**Status da Certificação Espiritual:**

#### Status: "Destaque seu Perfil"
- Quando toggle está desligado
- Quando não solicitou certificação
- Cor: Amarelo/Âmbar
- Indica que pode destacar o perfil fazendo a mentoria

#### Status: "Aprovado"
- Quando admin aprovou a certificação
- Cor: Verde
- Selo dourado aparece no perfil

### 3. Verificação Segura

**CertificationStatusHelper** - Evita erro INTERNAL ASSERTION FAILED

```dart
// Query simples e segura
final snapshot = await _firestore
    .collection('certification_requests')
    .where('userId', isEqualTo: userId)
    .where('status', isEqualTo: 'approved')
    .limit(1)
    .get();

return snapshot.docs.isNotEmpty;
```

**Por que é seguro:**
- Query simples com apenas 2 where clauses
- Limit de 1 documento
- Try-catch para capturar erros
- Retorna false em caso de erro (fail-safe)
- Não usa queries complexas que causam INTERNAL ASSERTION FAILED

## Estrutura de Dados

### certification_requests (Firestore)

```json
{
  "id": "abc123",
  "userId": "user_id",
  "userName": "Nome do Usuário",
  "userEmail": "email@example.com",
  "purchaseEmail": "email_compra@example.com",
  "proofFileUrl": "https://...",
  "proofFileName": "comprovante.pdf",
  "status": "pending|approved|rejected",
  "requestedAt": Timestamp,
  "reviewedAt": Timestamp,
  "rejectionReason": "motivo (se rejeitado)"
}
```

## Fluxo de Dados

```
Usuário abre SpiritualCertificationRequestView
    ↓
Toggle DESLIGADO (padrão)
    ↓
Vê call-to-action para fazer mentoria
    ↓
Faz a mentoria (externo)
    ↓
Volta e LIGA o toggle
    ↓
Formulário de certificação aparece
    ↓
Preenche e envia comprovante
    ↓
Status: "pending" no Firestore
    ↓
Admin analisa no painel
    ↓
Admin APROVA
    ↓
Status: "approved" no Firestore
    ↓
Notificação enviada ao usuário
    ↓
ProfileCompletionView mostra "Aprovado"
    ↓
Selo dourado aparece no perfil
```

## Componentes

### 1. SpiritualCertificationRequestView
- **Localização:** `lib/views/spiritual_certification_request_view.dart`
- **Responsabilidade:** Gerenciar toggle e exibir formulário ou CTA
- **Estado:** `_isReady` (RxBool do GetX)

### 2. ProfileCompletionView
- **Localização:** `lib/views/profile_completion_view.dart`
- **Responsabilidade:** Exibir status da certificação
- **Método especial:** `_buildCertificationTaskCard()`

### 3. CertificationStatusHelper
- **Localização:** `lib/utils/certification_status_helper.dart`
- **Responsabilidade:** Verificar status de forma segura
- **Métodos:**
  - `hasApprovedCertification(userId)` → bool
  - `getCertificationDisplayStatus(userId)` → String
  - `hasPendingCertification(userId)` → bool

## UI/UX

### SpiritualCertificationRequestView

#### Header
- Título: "Certificação Espiritual"
- Subtítulo: "Destaque seu Perfil"
- Ícone: 🏆 (workspace_premium)
- Cor: Âmbar/Dourado

#### Card de Informações
- Ícone grande: ✓ (verified)
- Título: "Selo de Certificação"
- Descrição: "Destaque seu perfil com o selo dourado"

#### Toggle
- Texto: "Eu estou preparado(a) para encontrar meu Isaque, minha Rebeca"
- Subtexto: "Ative se você já fez a mentoria"
- Cor ativa: Verde
- Cor inativa: Cinza
- Border muda de cor quando ativo

#### Call-to-Action (Toggle OFF)
- Gradiente: Roxo → Rosa
- Ícone: 🎓 (school)
- Título: "Faça a Mentoria"
- Subtítulo: "Sinais de meu Isaque e de minha Rebeca"
- Lista de benefícios com checkmarks verdes
- Botão roxo: "Fazer a Mentoria Agora"

#### Formulário (Toggle ON)
- Mensagem de sucesso verde
- Formulário de solicitação
- Upload de comprovante
- Botão de envio

### ProfileCompletionView

#### Card de Certificação

**Status: "Destaque seu Perfil"**
```
┌─────────────────────────────────────┐
│ 🏆  Certificação Espiritual         │
│     Adicione seu selo...            │
│                                     │
│              [Destaque seu Perfil] →│
└─────────────────────────────────────┘
```
- Cor do badge: Âmbar
- Ícone: 🏆 (verified)

**Status: "Aprovado"**
```
┌─────────────────────────────────────┐
│ ✓  Certificação Espiritual          │
│     Adicione seu selo...            │
│                                     │
│                      [Aprovado] →   │
└─────────────────────────────────────┘
```
- Cor do badge: Verde
- Ícone: ✓ (check_circle)

## Vantagens da Solução

### ✅ Segurança
- Query simples evita erro INTERNAL ASSERTION FAILED
- Try-catch em todas as operações
- Fail-safe: retorna false em caso de erro

### ✅ UX Intuitiva
- Toggle claro e objetivo
- Call-to-action motivacional
- Status descritivo ("Destaque seu Perfil" vs "Aprovado")

### ✅ Flexibilidade
- Usuário controla quando solicitar
- Pode ver benefícios antes de decidir
- Não força a certificação

### ✅ Performance
- FutureBuilder carrega status apenas quando necessário
- Query com limit(1) é rápida
- Cache do Firestore ajuda

## Testando

### 1. Testar Toggle

```dart
// Abrir SpiritualCertificationRequestView
Get.to(() => const SpiritualCertificationRequestView());

// Toggle deve estar DESLIGADO por padrão
// Deve mostrar call-to-action

// Ligar toggle
// Deve mostrar formulário
```

### 2. Testar Status

```dart
// Usuário SEM certificação aprovada
// ProfileCompletionView deve mostrar "Destaque seu Perfil"

// Admin aprova certificação
// ProfileCompletionView deve mostrar "Aprovado"
```

### 3. Testar Segurança

```dart
// Simular erro no Firestore
// Sistema deve retornar false e não crashar
// Status deve ser "Destaque seu Perfil" (fail-safe)
```

## Troubleshooting

### Erro: INTERNAL ASSERTION FAILED

**Causa:** Query complexa no Firestore

**Solução:** Usar CertificationStatusHelper que tem query simples

### Status não atualiza

**Causa:** Cache do FutureBuilder

**Solução:** Forçar rebuild com setState ou usar StreamBuilder

### Toggle não salva estado

**Causa:** Estado local não persiste

**Solução:** Salvar no Firestore se necessário (futuro)

## Melhorias Futuras

1. **Persistir estado do toggle** no Firestore
2. **Link real** para a mentoria
3. **Progress tracking** da mentoria
4. **Certificado digital** para download
5. **Compartilhamento** do selo nas redes sociais
6. **Ranking** de certificados
7. **Badges** adicionais por conquistas

## Conclusão

Sistema completo e seguro que:
- ✅ Evita erro INTERNAL ASSERTION FAILED
- ✅ Mostra status correto ("Destaque seu Perfil" ou "Aprovado")
- ✅ Tem toggle intuitivo
- ✅ Motiva usuários a fazer a mentoria
- ✅ Funciona de forma fail-safe
