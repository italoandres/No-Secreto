# 🔑 SOLUÇÃO - Configurar SHA-1/SHA-256 para Release no Firebase

## 🎯 PROBLEMA IDENTIFICADO

O app funciona no emulador (usa debug keystore) mas fecha no celular real (usa release keystore).

**Causa:** SHA-1 e SHA-256 da chave **release** não estão registrados no Firebase.

---

## 🔧 SOLUÇÃO COMPLETA - PASSO A PASSO

### PASSO 1: Obter SHA-1 e SHA-256 da Chave Release

#### Opção A: Se você tem um keystore próprio

```bash
cd android/app

keytool -list -v -keystore seu-keystore.jks -alias seu-alias
```

Quando pedir senha, digite a senha do seu keystore.

#### Opção B: Se usa a chave debug (para testar)

```bash
cd android

# Windows:
.\gradlew signingReport

# Ou diretamente:
keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android
```

#### Opção C: Gerar nova chave release (se não tiver)

```bash
keytool -genkey -v -keystore android/app/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

**Anote a senha que você criar!**

---

### PASSO 2: Copiar os Hashes

Você verá algo assim:

```
Certificate fingerprints:
     SHA1: AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD
     SHA256: 11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF:00
```

**Copie ambos os valores!**

---

### PASSO 3: Adicionar no Firebase Console

1. Acesse: https://console.firebase.google.com
2. Selecione seu projeto
3. Vá em **Configurações do Projeto** (ícone de engrenagem)
4. Role até **Seus apps**
5. Clique no app Android
6. Role até **Impressões digitais do certificado SHA**
7. Clique em **Adicionar impressão digital**
8. Cole o **SHA-1** e clique em Salvar
9. Clique em **Adicionar impressão digital** novamente
10. Cole o **SHA-256** e clique em Salvar

---

### PASSO 4: Baixar novo google-services.json

1. No Firebase Console, ainda na página do app
2. Clique em **Baixar google-services.json**
3. Substitua o arquivo em: `android/app/google-services.json`

---

### PASSO 5: Rebuild e Testar

```bash
# Limpar tudo
flutter clean

# Rebuild
flutter build apk --release

# Instalar no celular
flutter install
```

---

## 📋 CHECKLIST COMPLETO

- [ ] Obter SHA-1 da chave release
- [ ] Obter SHA-256 da chave release
- [ ] Adicionar SHA-1 no Firebase Console
- [ ] Adicionar SHA-256 no Firebase Console
- [ ] Baixar novo google-services.json
- [ ] Substituir android/app/google-services.json
- [ ] flutter clean
- [ ] flutter build apk --release
- [ ] Desinstalar app do celular
- [ ] flutter install
- [ ] Testar no celular

---

## 🎯 COMANDOS RÁPIDOS

### 1. Obter SHA-1 e SHA-256:

```bash
cd android
.\gradlew signingReport
```

Procure por:
- `Variant: release`
- `SHA1:` e `SHA256:`

### 2. Após adicionar no Firebase:

```bash
# Voltar para raiz do projeto
cd ..

# Limpar e rebuild
flutter clean
flutter build apk --release

# Desinstalar do celular
adb uninstall <seu.pacote>

# Instalar
flutter install
```

---

## ⚠️ IMPORTANTE: Configurar Assinatura Release

Se você ainda não configurou a assinatura release, crie o arquivo:

**android/key.properties:**
```properties
storePassword=sua_senha_aqui
keyPassword=sua_senha_aqui
keyAlias=upload
storeFile=upload-keystore.jks
```

**android/app/build.gradle:**

Verifique se tem isso:

```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    ...
    
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

---

## 🎊 RESULTADO ESPERADO

Após seguir esses passos:

- ✅ App abre no celular real
- ✅ Firebase funciona corretamente
- ✅ Sem erros de permission-denied
- ✅ Login instantâneo
- ✅ Logs limpos

---

## 💡 DICA EXTRA

Se você usa Google Sign-In, os SHA também são necessários para isso funcionar em release!

---

## 🚀 EXECUTE AGORA

1. Rode: `cd android && .\gradlew signingReport`
2. Copie SHA-1 e SHA-256 da seção **release**
3. Adicione no Firebase Console
4. Baixe novo google-services.json
5. Substitua o arquivo
6. Rebuild: `flutter clean && flutter build apk --release`
7. Teste no celular!

**Vai funcionar perfeitamente!** 💪
