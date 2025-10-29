# 📱 Como Ver os Logs da Biometria

## ⚠️ Problema: Logs não aparecem em APK Release

Em builds **release** (APK), o Flutter remove os `print()` automaticamente para otimização.

## ✅ Soluções:

### Solução 1: Ver Logs na Tela (MAIS FÁCIL)

Adicionei um `Get.rawSnackbar()` que mostra mensagens na tela do app:

```
Quando você clicar no botão "Usar Biometria":
→ Aparecerá uma mensagem azul na tela: "👆 Botão clicado! Iniciando biometria..."
```

**Se essa mensagem NÃO aparecer:** O botão não está respondendo ao clique.

**Se a mensagem aparecer MAS a janela de biometria não abrir:** O problema está no serviço de autenticação.

---

### Solução 2: Usar Flutter Run (COM LOGS)

Em vez de instalar o APK, rode o app diretamente do Flutter:

```bash
# 1. Conecte o celular via USB
# 2. Ative a depuração USB
# 3. Execute:
flutter run --release

# Os logs aparecerão no terminal automaticamente
```

**Vantagem:** Você verá TODOS os logs em tempo real no terminal.

---

### Solução 3: Usar o Script PowerShell

Criei um script que facilita ver os logs:

```powershell
# Execute este comando:
.\ver-logs-biometria.ps1

# Depois clique no botão "Usar Biometria" no app
# Os logs aparecerão no terminal
```

---

### Solução 4: Logcat Manual (Seu Comando)

Seu comando está quase certo, mas precisa de um ajuste:

```powershell
# ANTES (não funciona bem):
.\adb.exe logcat | findstr "flutter I/flutter E/flutter"

# DEPOIS (funciona melhor):
.\adb.exe logcat -s flutter:V

# Ou para limpar logs antigos primeiro:
.\adb.exe logcat -c
.\adb.exe logcat -s flutter:V
```

---

## 🧪 Teste Rápido (SEM LOGS):

Se você não conseguir ver os logs, faça este teste simples:

### 1. Compile e instale o APK:
```bash
flutter build apk --split-per-abi
# Instale no celular
```

### 2. Abra o app e vá até a tela de bloqueio

### 3. Clique no botão "Usar Biometria"

### 4. Observe:

#### ✅ Se aparecer mensagem azul "👆 Botão clicado!":
- **Botão está funcionando**
- **Problema está no serviço de autenticação**

#### ❌ Se NÃO aparecer nenhuma mensagem:
- **Botão não está respondendo**
- **Pode estar desabilitado ou coberto**

#### ✅ Se a janela de biometria abrir:
- **Tudo está funcionando!**
- **Problema pode ser na configuração inicial**

---

## 🎯 Recomendação:

**Use a Solução 2 (Flutter Run)** para ter logs completos:

```bash
# 1. Conecte o celular via USB
# 2. Execute:
flutter run --release

# 3. Aguarde o app abrir no celular
# 4. Clique no botão "Usar Biometria"
# 5. Veja os logs no terminal
```

Isso vai mostrar TODOS os logs, incluindo:
- `👆 BOTÃO "Usar Biometria" CLICADO!`
- `🔐 === INICIANDO AUTENTICAÇÃO BIOMÉTRICA ===`
- `🔒 canCheckBiometrics() = true/false`
- `🔒 Biometrias disponíveis: [...]`
- E todos os outros logs detalhados

---

## 💡 Alternativa Rápida:

Se não conseguir usar `flutter run`, me diga:

1. **A mensagem azul aparece na tela quando clica no botão?**
2. **A janela de biometria abre?**
3. **Qual erro aparece (se houver)?**

Com essas 3 informações, já consigo identificar o problema! 🎯
