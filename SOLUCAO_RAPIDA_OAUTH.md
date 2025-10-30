# ⚡ SOLUÇÃO RÁPIDA: OAuth Client Android

## 🎯 SITUAÇÃO ATUAL

Seu `google-services.json` tem:
- ✅ OAuth Client tipo **Web** (client_type: 1)
- ❌ OAuth Client tipo **Android** (client_type: 3) - **FALTANDO**

Para o Google Sign-In funcionar no APK release, você precisa dos DOIS tipos!

---

## 🚀 SOLUÇÃO EM 3 PASSOS (10 minutos)

### PASSO 1: Verificar no Google Cloud Console (2 min)

1. Abra: https://console.cloud.google.com/apis/credentials?project=app-no-secreto-com-o-pai

2. Procure na lista "OAuth 2.0 Client IDs"

3. Verifique se existe um client com **Type: Android**

**Resultado**:
- ✅ **Se EXISTIR**: Anote o Client ID e vá para PASSO 2
- ❌ **Se NÃO EXISTIR**: Crie um novo:

#### Como Criar OAuth Client ID Android:

1. Clique em **"+ CREATE CREDENTIALS"** → **"OAuth client ID"**

2. **Application type**: Selecione **"Android"** ⚠️ (NÃO "Web application")

3. Preencha:
   - **Name**: `Android client (Release)`
   - **Package name**: `com.no.secreto.com.deus.pai`
   - **SHA-1**: `18:EA:F9:C1:2C:61:48:27:C6:8C:E6:30:BC:58:17:24:A0:E5:7B:53`

4. Clique **"CREATE"**

5. Copie o **Client ID** que aparece (algo como: `490614568896-xxxxx.apps.googleusercontent.com`)

---

### PASSO 2: Adicionar ao google-services.json (3 min)

Você tem duas opções:

#### Opção A: Baixar Novo Arquivo do Firebase (Recomendado)

1. Acesse: https://console.firebase.google.com/project/app-no-secreto-com-o-pai/settings/general

2. Role até "Your apps" → Android app

3. Clique em **"google-services.json"** para baixar

4. Substitua:
   ```powershell
   Copy-Item android\app\google-services.json android\app\google-services.json.old
   # Copie o novo arquivo para android\app\google-services.json
   ```

5. Verifique:
   ```powershell
   .\verificar-google-services.ps1
   ```

#### Opção B: Adicionar Manualmente com Script (Mais Rápido)

Se o Firebase ainda não sincronizou, use o script:

```powershell
.\adicionar-oauth-android.ps1
```

O script vai:
1. Fazer backup do arquivo atual
2. Pedir o Client ID do OAuth Client Android
3. Adicionar ao google-services.json
4. Salvar o arquivo atualizado

---

### PASSO 3: Rebuild e Testar (5 min)

```powershell
# Limpar
cd android
.\gradlew clean
cd ..

# Build
flutter build apk --release

# Localizar APK
explorer build\app\outputs\flutter-apk\
```

Instale no celular e teste o login!

---

## 📊 CHECKLIST

- [ ] 1. Verificar se existe OAuth Client ID tipo Android no Google Cloud Console
- [ ] 2. Se não existir, criar um novo (Type: Android)
- [ ] 3. Copiar o Client ID
- [ ] 4. Adicionar ao google-services.json (Opção A ou B)
- [ ] 5. Verificar com `.\verificar-google-services.ps1`
- [ ] 6. Rebuild do APK
- [ ] 7. Testar no celular

---

## 🎯 O QUE ESPERAR

Após adicionar o OAuth Client Android, o script `verificar-google-services.ps1` deve mostrar:

```
OAUTH CLIENTS CONFIGURADOS:
   Cliente 1:
      Client ID: (Web client)
      Client Type: 1
   
   Cliente 2:
      Client ID: (Android client)
      Client Type: 3  <-- ESTE É O IMPORTANTE!

STATUS: Configuracao parece OK
```

---

## 💡 DICA

O timeout de 30 segundos acontece porque o app está tentando usar o Google Sign-In, mas não encontra o OAuth Client Android configurado. Após adicionar, o login deve funcionar imediatamente!

---

## 📞 PRÓXIMA AÇÃO

1. Acesse o Google Cloud Console
2. Verifique se existe OAuth Client ID tipo Android
3. Me avise o que encontrou!
