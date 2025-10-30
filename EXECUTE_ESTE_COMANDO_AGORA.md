# 🚀 EXECUTE ESTE COMANDO AGORA

## Comando para Corrigir Permission Denied

```powershell
.\deploy-firestore-rules-corrigidas-AGORA.ps1
```

## O que o script faz

1. ✅ Faz backup automático do `firestore.rules` atual
2. ✅ Aplica as correções (adiciona `{document=**}` nas regras)
3. ✅ Faz deploy para o Firebase
4. ✅ Mostra instruções de teste

## Correções Aplicadas

### ANTES ❌
```javascript
match /sistema/{docId} {
  allow read: if request.auth != null;
}
```
**Problema**: Só cobre documentos diretos, NÃO subcoleções

### DEPOIS ✅
```javascript
match /sistema/{document=**} {
  allow read: if request.auth != null;
}
```
**Solução**: Cobre documentos E subcoleções

## Coleções Corrigidas

- ✅ `sistema/{document=**}`
- ✅ `stories/{document=**}`
- ✅ `interests/{document=**}`
- ✅ `interest_notifications/{document=**}`
- ✅ `match_chats/{document=**}`
- ✅ `profiles/{document=**}`
- ✅ `spiritual_profiles/{document=**}`

## Teste Após Deploy

1. Fazer login no app
2. Verificar logs:
   - ❌ NÃO deve ter `permission-denied`
   - ✅ Dados devem carregar normalmente

## Segurança

✅ Backup automático criado
✅ Não quebra nada existente
✅ Apenas AMPLIA permissões
✅ Autenticação continua obrigatória

---

## 🎯 EXECUTE AGORA:

```powershell
.\deploy-firestore-rules-corrigidas-AGORA.ps1
```

Isso vai resolver os erros de `permission-denied`! 🚀
