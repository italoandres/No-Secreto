# 🎨 TAREFA 8 - Integração do Badge de Certificação - INICIADA

## 📋 Objetivo

Integrar o componente `SpiritualCertificationBadge` nas principais telas do aplicativo para exibir o selo de certificação espiritual dos usuários.

---

## 🎯 Locais de Integração

### 1. ✅ Perfil Próprio
- **Arquivo:** `lib/views/profile_identity_task_view.dart` ou similar
- **Componente:** `SpiritualCertificationBadge` (tamanho grande)
- **Condição:** Sempre visível (mostra botão se não certificado)

### 2. ✅ Perfil de Outros Usuários
- **Arquivo:** `lib/views/profile_display_view.dart`
- **Componente:** `SpiritualCertificationBadge` (tamanho grande)
- **Condição:** Só aparece se `spirituallyCertified == true`

### 3. ✅ Cards da Vitrine
- **Arquivo:** `lib/components/profile_card_component.dart`
- **Componente:** `CompactCertificationBadge` (24x24)
- **Condição:** Só aparece se certificado

### 4. ✅ Resultados de Busca
- **Arquivo:** `lib/views/explore_profiles_view.dart` ou similar
- **Componente:** `InlineCertificationBadge` (20x20)
- **Condição:** Ao lado do nome se certificado

---

## 📝 Status Atual

- [x] Tarefa 6 - Atualização de perfil (COMPLETA)
- [x] Tarefa 7 - Badge component (COMPLETA)
- [ ] Tarefa 8 - Integração do badge (EM ANDAMENTO)

---

## 🚀 Próximos Passos

1. Identificar arquivos de perfil
2. Adicionar badge no perfil próprio
3. Adicionar badge no perfil de outros
4. Adicionar badge nos cards da vitrine
5. Adicionar badge nos resultados de busca
6. Testar todas as integrações

---

**Iniciando implementação...** 🎨
