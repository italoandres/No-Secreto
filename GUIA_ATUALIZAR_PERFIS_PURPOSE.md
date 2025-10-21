# Guia: Atualizar Perfis com Campo Propósito

## Problema
Os perfis de teste criados anteriormente não têm o campo `purpose`, então a seção "💫 Propósito" não aparece nos cards.

## Solução Rápida

### Opção 1: Atualizar Perfis Existentes (RECOMENDADO)

1. **Abrir a tela de debug**:
   - Na aba Sinais, clique no ícone de bug (🐛) no canto superior direito

2. **Clicar no botão verde "Atualizar Perfis (Adicionar Propósito)"**
   - Isso adiciona o campo `purpose` aos 6 perfis existentes
   - Não perde os interesses e matches já criados
   - Mais rápido e seguro

3. **Recarregar a aba Sinais**:
   - Volte para a aba Sinais
   - Puxe para baixo para atualizar (pull to refresh)
   - Agora você verá a seção "💫 Propósito" nos cards!

### Opção 2: Recriar Tudo do Zero

1. **Abrir a tela de debug**
2. **Clicar em "Remover Tudo"** (botão vermelho)
3. **Clicar em "Criar Tudo"** (botão azul)
4. **Recarregar a aba Sinais**

## O que foi Implementado

### 1. Novo Utilitário
**Arquivo:** `lib/utils/update_test_profiles_purpose.dart`

Script que atualiza os 6 perfis de teste adicionando o campo `purpose`:

```dart
await UpdateTestProfilesPurpose.updateProfiles();
```

### 2. Botão na Tela de Debug
**Arquivo:** `lib/views/debug_test_profiles_view.dart`

Adicionado botão verde "Atualizar Perfis (Adicionar Propósito)" que:
- Atualiza perfis existentes
- Adiciona o campo `purpose` a cada perfil
- Mantém todos os outros dados intactos

### 3. Valores de Propósito Adicionados

| Perfil | Propósito |
|--------|-----------|
| Maria Silva | Relacionamento sério com propósito de casamento |
| Ana Costa | Namoro cristão com intenção de casamento |
| Juliana Santos | Conhecer pessoas com os mesmos valores para relacionamento sério |
| Beatriz Oliveira | Relacionamento sério que leve ao casamento |
| Carolina Ferreira | Encontrar um parceiro para construir uma família cristã |
| Fernanda Lima | Namoro sério |

## Resultado Visual

Após atualizar, você verá nos cards:

```
┌─────────────────────────────────────┐
│         FOTO DO PERFIL              │
└─────────────────────────────────────┘
┌─────────────────────────────────────┐
│  Maria Silva, 28                    │
│  São Paulo, SP • 5.2km              │
│  ⭐ 95% de compatibilidade          │
│                                     │
│  💫 Propósito                       │
│  ┌─────────────────────────────┐   │
│  │ Busco                       │   │
│  │ Relacionamento sério com    │   │
│  │ propósito de casamento      │   │
│  └─────────────────────────────┘   │
│                                     │
│  ✨ Valores Espirituais             │
│  • Certificação Espiritual          │
│  • Membro do Movimento              │
│  • Virgindade: Preservando...       │
│                                     │
│  👤 Informações Pessoais            │
│  • Educação: Ensino Superior        │
│  • Idiomas: Português, Inglês       │
│  • Filhos: Não tenho                │
│                                     │
│  [Ver Perfil Completo]              │
│                                     │
│  [Passar] [Tenho Interesse]         │
└─────────────────────────────────────┘
```

## Verificação

Para confirmar que funcionou:

1. ✅ Seção "💫 Propósito" aparece no topo do card
2. ✅ Texto do propósito está visível e legível
3. ✅ Design com gradiente azul e ícone de coração
4. ✅ Botão "Ver Perfil Completo" está visível
5. ✅ Todas as outras seções continuam funcionando

## Troubleshooting

### Problema: Seção não aparece após atualizar

**Solução:**
1. Force o reload do app (hot restart)
2. Ou use a Opção 2 (recriar tudo do zero)

### Problema: Erro ao atualizar

**Solução:**
1. Verifique se os perfis existem no Firestore
2. Verifique as permissões do Firestore
3. Tente recriar os perfis do zero

## Código Completo

Todos os arquivos foram atualizados:
- ✅ `lib/models/scored_profile.dart` - Getter `purpose`
- ✅ `lib/components/value_highlight_chips.dart` - Seção de propósito
- ✅ `lib/utils/create_test_profiles_sinais.dart` - Campo nos novos perfis
- ✅ `lib/utils/update_test_profiles_purpose.dart` - Script de atualização (NOVO)
- ✅ `lib/views/debug_test_profiles_view.dart` - Botão de atualização (NOVO)

Tudo pronto para funcionar! 🎉
