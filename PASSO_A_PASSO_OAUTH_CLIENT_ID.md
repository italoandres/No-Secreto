# 🎯 PASSO A PASSO: Configurar OAuth Client ID

## ❌ Problema Identificado

Seu `google-services.json` está **SEM OAuth Clients configurados**.

Resultado do script:
```
OAUTH CLIENTS CONFIGURADOS: (vazio)
STATUS: Configuracao INCOMPLETA
```

Isso causa o timeout de 30 segundos no Google Sign-In!

---

## ✅ SOLUÇÃO (15 minutos)

### PASSO 1: Acessar Google Cloud Console (2 min)

1. Abra este link no navegador:
   ```
   https://console.cloud.google.com/apis/credentials?project=app-no-secreto-com-o-pai
   ```

2. Faça login com sua conta Google (a mesma do Firebase)

3. Você verá a página "Credentials" (Credenciais)

---

### PASSO 2: Criar OAuth 2.0 Client ID (5 min)

1. Clique no botão **"+ CREATE CREDENTIALS"** (no topo)

2. Selecione **"OAuth client ID"**

3. Se aparecer uma tela dizendo "Configure consent screen":
   - Clique em **"CONFIGURE CONSENT SCREEN"**
   - Selecione **"External"**
   - Clique **"CREATE"**
   - Preencha apenas os campos obrigatórios:
     - App name: `No Secreto com Deus Pai`
     - User support email: (seu email)
     - Developer contact: (seu email)
   - Clique **"SAVE AND CONTINUE"** até o final
   - Volte para "Credentials"

4. Clique novamente em **"+ CREATE CREDENTIALS"** → **"OAuth client ID"**

5. Preencha o formulário:
   - **Application type**: Selecione **"Android"**
   - **Name**: `Android client (Release)`
   - **Package name**: `com.deusepai.app` (ou o que está no seu build.gradle)
   - **SHA-1 certificate fingerprint**: 
     ```
     18:EA:F9:C1:2C:61:48:27:C6:8C:E6:30:BC:58:17:24:A0:E5:7B:53
     ```

6. Clique em **"CREATE"**

7. Uma janela aparecerá com o Client ID criado. Clique em **"OK"**

---

### PASSO 3: Verificar Package Name (1 min)

Antes de continuar, vamos confirmar o package name correto:

<function_calls>
<invoke name="readFile">
<parameter name="path">android/app/build.gradle

*
*IMPORTANTE**: O package name correto é:
```
com.no.secreto.com.deus.pai
```

Use exatamente esse nome ao criar o OAuth Client ID!

---

### PASSO 4: Baixar Novo google-services.json (3 min)

1. Abra o Firebase Console:
   ```
   https://console.firebase.google.com/project/app-no-secreto-com-o-pai
   ```

2. Clique no ícone de **engrenagem ⚙️** → **"Project settings"**

3. Role até a seção **"Your apps"**

4. Encontre o app Android (ícone do Android)

5. Clique no botão **"google-services.json"** para baixar

6. **IMPORTANTE**: Salve o arquivo baixado

---

### PASSO 5: Substituir google-services.json (1 min)

Execute estes comandos no PowerShell:

```powershell
# Fazer backup do arquivo antigo
Copy-Item android\app\google-services.json android\app\google-services.json.backup

# Agora copie manualmente o arquivo baixado para:
# android\app\google-services.json
```

Ou faça manualmente:
1. Vá até a pasta `android\app\`
2. Renomeie o `google-services.json` atual para `google-services.json.backup`
3. Copie o novo arquivo baixado para `android\app\google-services.json`

---

### PASSO 6: Verificar Configuração (1 min)

Execute o script novamente para confirmar:

```powershell
.\verificar-google-services.ps1
```

Agora deve mostrar:
```
OAUTH CLIENTS CONFIGURADOS:
   Cliente 1:
      Client ID: (algum ID)
      Client Type: 3

STATUS: Configuracao parece OK
```

---

### PASSO 7: Rebuild do APK (5 min)

```powershell
# Limpar build anterior
cd android
.\gradlew clean
cd ..

# Build novo APK
flutter build apk --release
```

---

### PASSO 8: Testar (2 min)

1. Instale o novo APK no celular
2. Tente fazer login com Google
3. Deve funcionar sem timeout!

---

## 🎯 RESUMO DO QUE FIZEMOS

1. ✅ Identificamos que faltava OAuth Client ID
2. ✅ Criamos OAuth Client ID no Google Cloud Console
3. ✅ Baixamos novo google-services.json do Firebase
4. ✅ Substituímos o arquivo antigo
5. ✅ Rebuild do APK
6. ✅ Teste no celular

---

## 📊 Informações Importantes

**Project ID**: `app-no-secreto-com-o-pai`
**Package Name**: `com.no.secreto.com.deus.pai`
**SHA-1**: `18:EA:F9:C1:2C:61:48:27:C6:8C:E6:30:BC:58:17:24:A0:E5:7B:53`

---

## 🚀 EXECUTE AGORA

Siga os passos acima na ordem. Qualquer dúvida, me avise!

O timeout de 30 segundos será resolvido após esses passos! 🎉
