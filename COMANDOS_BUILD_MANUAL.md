# 🚀 Comandos Manuais para Build

## Execute estes comandos um por um:

```powershell
# 1. Matar processos
taskkill /F /IM java.exe
taskkill /F /IM gradle.exe

# 2. Deletar pasta build
Remove-Item -Recurse -Force build

# 3. Flutter clean
flutter clean

# 4. Flutter pub get
flutter pub get

# 5. Build APK (com lint desabilitado)
flutter build apk --release
```

## OU use o script simples:

```powershell
.\fix-build-simples.ps1
```

## Se der erro de execution policy:

```powershell
powershell -ExecutionPolicy Bypass -File .\fix-build-simples.ps1
```

---

**Nota:** O lint já foi desabilitado no `android/app/build.gradle`, então o erro do arquivo bloqueado não deve mais acontecer!
