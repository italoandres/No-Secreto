# 🔍 COLEÇÕES FALTANDO NO FIRESTORE.RULES

## ❌ COLEÇÕES IDENTIFICADAS QUE FALTAM

### 1. `stores_visto` ⚠️ CRÍTICO
- **Usado em**: stories_repository.dart (linhas 818, 832, 1029, 1035)
- **Propósito**: Rastrear stories visualizados pelo usuário
- **Status**: ❌ NÃO EXISTE no firestore.rules

### 2. `stories_files` ⚠️ CRÍTICO  
- **Usado em**: story_author_helper.dart (linhas 11, 54)
- **Propósito**: Armazenar arquivos de stories
- **Status**: ❌ NÃO EXISTE no firestore.rules

### 3. `stories_sinais_isaque` ⚠️ CRÍTICO
- **Usado em**: story_author_helper.dart (linhas 23, 68)
- **Propósito**: Stories do sistema Sinais (Isaque)
- **Status**: ❌ NÃO EXISTE no firestore.rules

### 4. `stories_sinais_rebeca` ⚠️ CRÍTICO
- **Usado em**: story_author_helper.dart (linhas 35, 82)
- **Propósito**: Stories do sistema Sinais (Rebeca)
- **Status**: ❌ NÃO EXISTE no firestore.rules

### 5. `app_logs`
- **Usado em**: enhanced_logger.dart (linhas 161, 180, 199)
- **Propósito**: Logs da aplicação
- **Status**: ❌ NÃO EXISTE no firestore.rules

### 6. `certifications`
- **Usado em**: certification_badge_helper.dart (linha 356)
- **Propósito**: Certificações espirituais
- **Status**: ❌ NÃO EXISTE no firestore.rules (existe `certification_requests` mas não `certifications`)

## ✅ COLEÇÕES QUE JÁ EXISTEM

- `usuarios` ✅
- `users` ✅
- `spiritual_profiles` ✅
- `profiles` ✅
- `chats` ✅
- `match_chats` ✅
- `interest_notifications` ✅
- `interests` ✅
- `spiritual_certifications` ✅
- `blocked_users` ✅

## 🎯 PLANO DE CORREÇÃO

Vou adicionar as regras para TODAS as coleções faltantes, uma por vez, com máxima atenção.
