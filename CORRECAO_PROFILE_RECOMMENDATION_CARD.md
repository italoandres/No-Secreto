# Correção ProfileRecommendationCard - Campo Propósito

## Problema Identificado
O `ProfileRecommendationCard` não estava mostrando o campo **Propósito** dos perfis, mesmo que o botão "Ver Perfil Completo" já estivesse implementado.

## Solução Implementada

### 1. Adicionado Campo `purpose` ao Modelo
**Arquivo:** `lib/models/scored_profile.dart`

```dart
/// Propósito (o que busca no app)
String? get purpose => profileData['purpose'] as String?;
```

### 2. Criada Seção de Propósito no ValueHighlightChips
**Arquivo:** `lib/components/value_highlight_chips.dart`

Adicionada nova seção que aparece **PRIMEIRO** no card, antes dos valores espirituais:

```dart
// Seção: Propósito
if (_hasPurpose())
  _buildSection(
    title: '💫 Propósito',
    children: _buildPurpose(),
  ),
```

**Design da Seção:**
- Card com gradiente azul suave
- Ícone de coração
- Título "Busco"
- Texto do propósito com formatação clara
- Destaque visual para chamar atenção

### 3. Atualizado Utilitário de Perfis de Teste
**Arquivo:** `lib/utils/create_test_profiles_sinais.dart`

Adicionado campo `purpose` a todos os 6 perfis de teste:

1. **Maria Silva**: "Relacionamento sério com propósito de casamento"
2. **Ana Costa**: "Namoro cristão com intenção de casamento"
3. **Juliana Santos**: "Conhecer pessoas com os mesmos valores para relacionamento sério"
4. **Beatriz Oliveira**: "Relacionamento sério que leve ao casamento"
5. **Carolina Ferreira**: "Encontrar um parceiro para construir uma família cristã"
6. **Fernanda Lima**: "Namoro sério"

## Estrutura Visual do Card (Ordem)

```
┌─────────────────────────────────────┐
│         FOTO (50% altura)           │
│  - Navegação entre fotos            │
│  - Badge certificação               │
└─────────────────────────────────────┘
┌─────────────────────────────────────┐
│    INFORMAÇÕES (50% altura)         │
│                                     │
│  Nome, Idade, Localização           │
│  Match Score Badge                  │
│                                     │
│  💫 Propósito (NOVO!)               │
│  ✨ Valores Espirituais             │
│  👤 Informações Pessoais            │
│  🎯 Interesses em Comum             │
│                                     │
│  [Ver Perfil Completo]              │
│                                     │
│  [Passar] [Tenho Interesse]         │
└─────────────────────────────────────┘
```

## Como Testar

1. **Recriar perfis de teste** (para adicionar o campo purpose):
   ```dart
   // Na tela de debug
   await CreateTestProfilesSinais.deleteTestProfiles();
   await CreateTestProfilesSinais.createTestProfiles();
   ```

2. **Verificar na aba Sinais**:
   - Abrir aba "Sinais"
   - Ver os cards de recomendação
   - Verificar se a seção "💫 Propósito" aparece no topo
   - Verificar se o botão "Ver Perfil Completo" está visível
   - Testar navegação entre fotos (swipe)

## Componentes Atualizados

✅ `lib/models/scored_profile.dart` - Adicionado getter `purpose`
✅ `lib/components/value_highlight_chips.dart` - Adicionada seção de propósito
✅ `lib/utils/create_test_profiles_sinais.dart` - Adicionado campo aos perfis de teste
✅ `lib/components/profile_recommendation_card.dart` - Já estava completo

## Resultado Final

Agora o `ProfileRecommendationCard` mostra:
- ✅ Foto do perfil com navegação
- ✅ Nome, idade e localização
- ✅ Match score visual
- ✅ **Propósito destacado** (NOVO!)
- ✅ Valores espirituais
- ✅ Informações pessoais
- ✅ Interesses em comum
- ✅ Botão "Ver Perfil Completo"
- ✅ Botões de ação (Passar/Interesse)

Tudo funcionando sem depender de dados do Firestore - o código está completo! 🎉
