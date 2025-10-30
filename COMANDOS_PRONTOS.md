# ⚡ COMANDOS PRONTOS - COPIE E COLE

## 🔍 Verificações

### Verificar google-services.json atual
```powershell
.\verificar-google-services.ps1
```

### Verificar chaves SHA (já feito - estão corretas)
```powershell
.\verificar-sha-release.ps1
```

---

## 🔧 Após Baixar Novo google-services.json

### Fazer backup do arquivo antigo
```powershell
Copy-Item android\app\google-services.json android\app\google-services.json.backup
```

### Verificar se o novo arquivo está correto
```powershell
.\verificar-google-services.ps1
```

---

## 🏗️ Rebuild do APK

### Limpar build anterior
```powershell
cd android
.\gradlew clean
cd ..
```

### Build novo APK Release
```powershell
flutter build apk --release
```

### Localizar APK gerado
```powershell
explorer build\app\outputs\flutter-apk\
```

---

## 🔥 Deploy Firestore Rules

### Fazer deploy das regras corrigidas
```powershell
.\deploy-rules-corrigidas.ps1
```

---

## 📊 Verificação Final

### Verificar se tudo está OK
```powershell
# 1. Verificar google-services.json
.\verificar-google-services.ps1

# 2. Verificar chaves SHA
.\verificar-sha-release.ps1

# 3. Listar APK gerado
dir build\app\outputs\flutter-apk\*.apk
```

---

## 🌐 Links Importantes

### Google Cloud Console (Criar OAuth Client ID)
```
https://console.cloud.google.com/apis/credentials?project=app-no-secreto-com-o-pai
```

### Firebase Console (Baixar google-services.json)
```
https://console.firebase.google.com/project/app-no-secreto-com-o-pai/settings/general
```

### Firebase Console (Deploy Rules)
```
https://console.firebase.google.com/project/app-no-secreto-com-o-pai/firestore/rules
```

---

## 📝 Dados para OAuth Client ID

**Application type**: Android

**Name**: Android client (Release)

**Package name**:
```
com.no.secreto.com.deus.pai
```

**SHA-1 certificate fingerprint**:
```
18:EA:F9:C1:2C:61:48:27:C6:8C:E6:30:BC:58:17:24:A0:E5:7B:53
```

---

## ✅ Checklist Rápido

```
[ ] 1. Criar OAuth Client ID no Google Cloud Console
[ ] 2. Baixar novo google-services.json do Firebase
[ ] 3. Fazer backup do antigo: Copy-Item android\app\google-services.json android\app\google-services.json.backup
[ ] 4. Copiar novo arquivo para android\app\google-services.json
[ ] 5. Verificar: .\verificar-google-services.ps1
[ ] 6. Limpar: cd android; .\gradlew clean; cd ..
[ ] 7. Build: flutter build apk --release
[ ] 8. Testar APK no celular
[ ] 9. Deploy rules: .\deploy-rules-corrigidas.ps1
```

---

## 🎯 Ordem de Execução

1. Criar OAuth Client ID (navegador)
2. Baixar google-services.json (navegador)
3. Substituir arquivo (Windows Explorer ou comando)
4. Verificar (PowerShell)
5. Rebuild (PowerShell)
6. Testar (celular)
7. Deploy rules (PowerShell)

---

Copie e cole os comandos conforme necessário! 🚀
