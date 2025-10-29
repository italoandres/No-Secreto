# EXECUTE ESTE COMANDO AGORA

```powershell
.\deploy-firestore-SIMPLES.ps1
```

## O que o script faz

1. Faz backup automatico do firestore.rules atual
2. Aplica as correcoes (adiciona {document=**} nas regras)
3. Faz deploy para o Firebase
4. Mostra instrucoes de teste

## Correcoes Aplicadas

### ANTES
```javascript
match /sistema/{docId} {
  allow read: if request.auth != null;
}
```
Problema: So cobre documentos diretos, NAO subcolecoes

### DEPOIS
```javascript
match /sistema/{document=**} {
  allow read: if request.auth != null;
}
```
Solucao: Cobre documentos E subcolecoes

## Colecoes Corrigidas

- sistema/{document=**}
- stories/{document=**}
- interests/{document=**}
- interest_notifications/{document=**}
- match_chats/{document=**}
- profiles/{document=**}
- spiritual_profiles/{document=**}

## Teste Apos Deploy

1. Fazer login no app
2. Verificar logs:
   - NAO deve ter permission-denied
   - Dados devem carregar normalmente

## Seguranca

- Backup automatico criado
- Nao quebra nada existente
- Apenas AMPLIA permissoes
- Autenticacao continua obrigatoria

---

## EXECUTE AGORA:

```powershell
.\deploy-firestore-SIMPLES.ps1
```

Isso vai resolver os erros de permission-denied!
