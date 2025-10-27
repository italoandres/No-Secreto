# 🎯 SOLUÇÃO DEFINITIVA: OAuth Client Android

## ❌ O QUE ACONTECEU

Você tentou usar o Client ID existente (`490614568896-v538glbnlkprgh014r9dtrofavdsj0go...`), mas esse é o Client ID tipo **Web**.

Você precisa criar um **NOVO** Client ID tipo **Android**.

---

## ✅ SOLUÇÃO EM 5 PASSOS (10 minutos)

### PASSO 1: Acessar Google Cloud Console (1 min)

Abra este link:
```
https://console.cloud.google.com/apis/credentials?project=app-no-secreto-com-o-pai
```

---

### PASSO 2: Verificar OAuth Clients Existentes (1 min)

Na página "Credentials", procure a seção **"OAuth 2.0 Client IDs"**.

Você deve ver algo assim:
```
Name                          Type        Client ID
Web client (auto created)     Web         490614568896-v538glbnlkprgh014r9dtrofavdsj0go...
```

**Pergunta**: Existe algum client com **Type: Android**?

- ❌ **NÃO**: Vá para PASSO 3 (criar novo)
- ✅ **SIM**: Anote o Client ID e vá para PASSO 4

---

### PASSO 3: Criar NOVO OAuth Client ID tipo Android (3 min)

1. Clique no botão **"+ CREATE CREDENTIALS"** (no topo da página)

2. Selecione **"OAuth client ID"**

3. **MUITO IMPORTANTE**: 
   - Em "Application type", selecione **"Android"**
   - **NÃO** selecione "Web application"!

4. Preencha o formulário:
   - **Name**: `Android client (Release)`
   - **Package name**: 
     ```
     com.no.secreto.com.deus.pai
     ```
   - **SHA-1 certificate fingerprint**:
     ```
     18:EA:F9:C1:2C:61:48:27:C6:8C:E6:30:BC:58:17:24:A0:E5:7B:53
     ```

5. Clique em **"CREATE"**

6. Uma janela aparecerá mostrando o **Client ID** criado. 
   - **COPIE** esse Client ID (será diferente do que você já tem)
   - Exemplo: `490614568896-XXXXXXX.apps.googleusercontent.com`

7. Clique em **"OK"**

---

### PASSO 4: Adicionar ao google-services.json Manualmente (3 min)

Agora vamos editar o arquivo manualmente.

1. Abra o arquivo no editor:
   ```
   android\app\google-services.json
   ```

2. Procure pela seção `"oauth_client"`:
   ```json
   "oauth_client": [
     {
       "client_id": "490614568896-v538glbnlkprgh014r9dtrofavdsj0go.apps.googleusercontent.com",
       "client_type": 1,
       ...
     }
   ]
   ```

3. Adicione o novo client Android **DEPOIS** do existente:
   ```json
   "oauth_client": [
     {
       "client_id": "490614568896-v538glbnlkprgh014r9dtrofavdsj0go.apps.googleusercontent.com",
       "client_type": 1,
       "android_info": {
         "package_name": "com.no.secreto.com.deus.pai",
         "certificate_hash": "18eaf9c12c614827c68ce630bc581724a0e57b53"
       }
     },
     {
       "client_id": "SEU_NOVO_CLIENT_ID_AQUI.apps.googleusercontent.com",
       "client_type": 3,
       "android_info": {
         "package_name": "com.no.secreto.com.deus.pai",
         "certificate_hash": "18eaf9c12c614827c68ce630bc581724a0e57b53"
       }
     }
   ]
   ```

4. **IMPORTANTE**: Substitua `SEU_NOVO_CLIENT_ID_AQUI` pelo Client ID que você copiou no PASSO 3

5. Salve o arquivo

---

### PASSO 5: Verificar e Testar (2 min)

1. Verifique se está correto:
   ```powershell
   .\verificar-google-services.ps1
   ```

   Deve mostrar:
   ```
   OAUTH CLIENTS CONFIGURADOS:
      Cliente 1:
         Client ID: (Web)
         Client Type: 1
      
      Cliente 2:
         Client ID: (Android)
         Client Type: 3  <-- IMPORTANTE!
   
   STATUS: Configuracao parece OK
   ```

2. Se estiver OK, rebuild:
   ```powershell
   cd android
   .\gradlew clean
   cd ..
   flutter build apk --release
   ```

3. Teste no celular!

---

## 📊 RESUMO

O problema é que você precisa de **DOIS** OAuth Client IDs:

1. ✅ **Web** (client_type: 1) - Você já tem
2. ❌ **Android** (client_type: 3) - Precisa criar NOVO

Não pode usar o mesmo Client ID para ambos!

---

## 💡 DICA VISUAL

No Google Cloud Console, após criar, você deve ver:

```
OAuth 2.0 Client IDs:
┌─────────────────────────────────┬──────────┬────────────────────┐
│ Name                            │ Type     │ Client ID          │
├─────────────────────────────────┼──────────┼────────────────────┤
│ Web client (auto created)       │ Web      │ 490614568896-v5... │
│ Android client (Release)        │ Android  │ 490614568896-XX... │ <- NOVO!
└─────────────────────────────────┴──────────┴────────────────────┘
```

---

## 🚀 PRÓXIMA AÇÃO

1. Acesse o Google Cloud Console
2. Crie NOVO OAuth Client ID tipo Android
3. Copie o Client ID
4. Me avise qual é o novo Client ID
5. Eu te ajudo a adicionar no google-services.json

Ou siga o PASSO 4 acima para adicionar manualmente!
