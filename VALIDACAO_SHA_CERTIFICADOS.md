# ✅ VALIDAÇÃO: Certificados SHA Cadastrados

## 📋 CHAVES FORNECIDAS

Você informou que tem estas chaves cadastradas no Firebase:

### SHA-1:
```
18:ea:f9:c1:2c:61:48:27:c6:8c:e6:30:bc:58:17:24:a0:e5:7b:53
```

### SHA-256:
```
82:7a:fa:18:96:d4:b2:92:ee:1e:1f:5b:c7:96:2a:e5:15:66:d2:13:1d:9d:e1:61:de:85:b3:8e:9d:4e:06:03
```

---

## 🔍 VERIFICAÇÃO

### ✅ Formato Correto
- SHA-1: 20 bytes (40 caracteres hex) = 20 pares separados por `:` ✅
- SHA-256: 32 bytes (64 caracteres hex) = 32 pares separados por `:` ✅

### ⚠️  IMPORTANTE: De Qual Keystore?

Essas chaves podem ser de **3 fontes diferentes**:

1. **Debug Keystore** (`~/.android/debug.keystore`)
   - Usado quando você roda `flutter run` no emulador
   - Funciona no emulador mas NÃO no APK release

2. **Release Keystore** (`android/release-key.jks` ou similar)
   - Usado quando você gera `flutter build apk --release`
   - É o que você precisa para o celular real

3. **Google Play Signing** (se usar App Signing do Google Play)
   - Chaves gerenciadas pelo Google Play Console
   - Diferentes das suas chaves locais

---

## 🎯 COMO VERIFICAR SE SÃO AS CORRETAS

### Passo 1: Verificar qual keystore você está usando

Abra o arquivo:
```
android/app/build.gradle
```

Procure por:
```gradle
signingConfigs {
    release {
        keyAlias 'seu-alias'
        keyPassword 'sua-senha'
        storeFile file('../release-key.jks')  // ← ESTE É O ARQUIVO
        storePassword 'sua-senha'
    }
}
```

### Passo 2: Extrair SHA da sua release keystore

Execute este comando (substitua os valores):

```powershell
keytool -list -v -keystore android\release-key.jks -alias seu-alias
```

**Exemplo de saída:**
```
Certificate fingerprints:
     SHA1: 18:EA:F9:C1:2C:61:48:27:C6:8C:E6:30:BC:58:17:24:A0:E5:7B:53
     SHA256: 82:7A:FA:18:96:D4:B2:92:EE:1E:1F:5B:C7:96:2A:E5:15:66:D2:13:1D:9D:E1:61:DE:85:B3:8E:9D:4E:06:03
```

### Passo 3: Comparar

Compare as chaves que o keytool mostrou com as que você cadastrou no Firebase.

**Devem ser EXATAMENTE iguais!**

---

## 🚨 PROBLEMA COMUM

### Se as chaves NÃO batem:

Você pode ter cadastrado as chaves do **debug keystore** em vez do **release keystore**.

**Solução:**
1. Extrair as chaves corretas do release keystore (comando acima)
2. Cadastrar no Firebase Console
3. Gerar novo APK
4. Testar

---

## 📝 CHECKLIST DE VERIFICAÇÃO

- [ ] Identifiquei qual keystore está no `build.gradle`
- [ ] Executei o keytool no arquivo correto
- [ ] Comparei SHA-1 (deve bater exatamente)
- [ ] Comparei SHA-256 (deve bater exatamente)
- [ ] Cadastrei no Firebase Console
- [ ] Gerei novo APK após cadastrar
- [ ] Testei no celular real

---

## 🎯 COMANDO COMPLETO PARA COPIAR

Substitua `SEU_ALIAS` pelo alias da sua chave:

```powershell
# Listar informações do certificado
keytool -list -v -keystore android\release-key.jks -alias SEU_ALIAS

# Ou se não souber o alias:
keytool -list -v -keystore android\release-key.jks
```

**Senha:** Você será solicitado a digitar a senha do keystore

---

## ✅ SE AS CHAVES BATEM

Se as chaves que você extraiu do keytool são **exatamente iguais** às que você me mostrou, então:

1. ✅ As chaves estão corretas
2. ✅ Estão cadastradas no Firebase
3. ⏳ Aguarde alguns minutos (pode levar até 5 minutos para propagar)
4. 🔄 Gere um novo APK
5. 📱 Teste no celular

---

## ❌ SE AS CHAVES NÃO BATEM

Se as chaves são diferentes:

1. ❌ Você cadastrou as chaves erradas no Firebase
2. 🔧 Extraia as chaves corretas do release keystore
3. ➕ Cadastre as novas chaves no Firebase Console
4. 🔄 Gere novo APK
5. 📱 Teste no celular

---

## 🔗 ONDE CADASTRAR NO FIREBASE

1. Acesse: https://console.firebase.google.com
2. Selecione seu projeto: `app-no-secreto-com-o-pai`
3. Vá em: **Configurações do Projeto** (ícone de engrenagem)
4. Aba: **Geral**
5. Role até: **Seus apps**
6. Clique no app Android
7. Role até: **Impressões digitais do certificado SHA**
8. Clique em: **Adicionar impressão digital**
9. Cole a SHA-1
10. Repita para SHA-256

---

## 💡 DICA PRO

Se você não tem certeza qual keystore está usando, procure no projeto:

```powershell
# Procurar arquivos .jks
Get-ChildItem -Path . -Filter *.jks -Recurse

# Procurar arquivos .keystore
Get-ChildItem -Path . -Filter *.keystore -Recurse
```

---

## 🎯 PRÓXIMO PASSO

**Execute o comando keytool e me mostre a saída!**

Assim posso confirmar se as chaves que você cadastrou são as corretas.

```powershell
keytool -list -v -keystore android\release-key.jks
```

Cole aqui a parte que mostra:
```
Certificate fingerprints:
     SHA1: ...
     SHA256: ...
```

---

**Status:** ⏳ Aguardando verificação
**Ação:** Execute o keytool e compare as chaves
