# 📋 Lista de Arquivos para Corrigir print() → safePrint()

## 🎯 OBJETIVO
Substituir todos os `print()` por `safePrint()` para eliminar logs em release mode e acelerar o app.

## 📊 TOTAL: 12 arquivos com ~66 ocorrências de print()

### ✅ GRUPO 1 (2 arquivos) - PRIORIDADE ALTA
1. **lib/controllers/audio_controller.dart** - 1 print
2. **lib/controllers/certification_pagination_controller.dart** - 2 prints

### ✅ GRUPO 2 (2 arquivos) - PRIORIDADE ALTA  
3. **lib/services/admin_confirmation_email_service.dart** - 16 prints
4. **lib/services/automatic_message_service.dart** - 3 prints

### ✅ GRUPO 3 (2 arquivos) - PRIORIDADE MÉDIA
5. **lib/repositories/chat_repository.dart** - 2 prints
6. **lib/utils/add_last_seen_to_users.dart** - 15 prints

### ✅ GRUPO 4 (2 arquivos) - PRIORIDADE MÉDIA
7. **lib/views/app_wrapper.dart** - 4 prints
8. **lib/views/certification_approval_panel_paginated_view.dart** - 1 print

### ✅ GRUPO 5 (2 arquivos) - PRIORIDADE BAIXA (DEBUG)
9. **lib/views/chat_view.dart** - 5 prints (debug)
10. **lib/views/enhanced_stories_viewer_view.dart** - 15 prints (debug)

### ✅ GRUPO 6 (2 arquivos) - PRIORIDADE BAIXA (DEBUG)
11. **lib/views/home_view.dart** - 4 prints (debug)
12. **lib/views/interest_dashboard_view.dart** - 6 prints (debug)

### ⚠️ ARQUIVO ESPECIAL (não corrigir)
- **lib/test_onboarding.dart** - 4 prints (arquivo de teste, pode manter)

---

## 🚀 PLANO DE EXECUÇÃO

Vou corrigir **2 arquivos por vez**, começando pelos de PRIORIDADE ALTA.

**Após cada grupo corrigido:**
- ✅ Verifico erros de compilação
- ✅ Confirmo que está tudo OK
- ✅ Você testa se quiser
- ✅ Passamos para o próximo grupo

---

## 📈 RESULTADO ESPERADO

**ANTES:**
- 🐌 Login: 60s+ (timeout)
- 📊 Logs: ~5.000 linhas
- ❌ App travando

**DEPOIS:**
- ⚡ Login: 3-5 segundos
- 📊 Logs: ~10 linhas (só essenciais)
- ✅ App super rápido!
