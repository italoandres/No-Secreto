# 🔍 TROUBLESHOOTING: OAuth Client ID

## ✅ BOA NOTÍCIA!

Seu `google-services.json` **TEM** um OAuth Client configurado:

```json
"oauth_client": [
  {
    "client_id": "490614568896-v538glbnlkprgh014r9dtrofavdsj0go.apps.googleusercontent.com",
    "client_type": 1,
    "android_info": {
      "package_name": "com.no.secreto.com.deus.pai",
      "certificate_hash": "18eaf9c12c614827c68ce630bc581724a0e57b53"
    }
  }
]
```

## ⚠️ PROBLEMA IDENTIFICADO

O OAuth Client tem `"client_type": 1` (Web), mas para o Google Sign-In funcionar no Android, precisamos de `"client_type": 3` (Android).

## 🎯 CAUSA

Existem dois cenários possíveis:

### Cenário 1: Você criou OAuth Client ID tipo "Web" em vez de "Android"
- No Google Cloud Console, ao criar o OAuth Client ID
- Você pode ter selecionado "Web application" em vez de "Android"

### Cenário 2: O Firebase ainda não sincronizou o OAuth Client ID Android
- Você criou o OAuth Client ID tipo Android
- Mas o Firebase ainda não atualizou o google-services.json

---

## 🔧 SOLUÇÃO

### PASSO 1: Verificar OAuth Clients no Google Cloud Console

1. Acesse: https://console.cloud.google.com/apis/credentials?project=app-no-secreto-com-o-pai

2. Procure na lista de "OAuth 2.0 Client IDs"

3. Verifique se existe um client com:
   - **Type**: Android
   - **Name**: Algo como "Android client" ou "Android client (Release)"

4. **Se NÃO existir**, vá para o PASSO 2
5. **Se EXISTIR**, vá para o PASSO 3

---

### PASSO 2: Criar OAuth Client ID tipo Android (se não existir)

1. No Google Cloud Console, clique em **"+ CREATE CREDENTIALS"**

2. Selecione **"OAuth client ID"**

3. **IMPORTANTE**: Em "Application type", selecione **"Android"** (NÃO "Web application")

4. Preencha:
   - **Name**: `Android client (Release)`
   - **Package name**: `com.no.secreto.com.deus.pai`
   - **SHA-1 certificate fingerprint**: 
     ```
     18:EA:F9:C1:2C:61:48:27:C6:8C:E6:30:BC:58:17:24:A0:E5:7B:53
     ```

5. Clique em **"CREATE"**

6. Aguarde 5-10 minutos para o Google sincronizar

7. Vá para o PASSO 3

---

### PASSO 3: Forçar Atualização do google-services.json

Mesmo que o OAuth Client ID Android exista, o Firebase pode não ter sincronizado ainda.

#### Opção A: Baixar Novo Arquivo (Recomendado)

1. Acesse: https://console.firebase.google.com/project/app-no-secreto-com-o-pai/settings/general

2. Role até "Your apps" → Android app

3. Clique em **"google-services.json"** para baixar

4. Substitua o arquivo:
   ```powershell
   # Backup
   Copy-Item android\app\google-services.json android\app\google-services.json.old
   
   # Copie o novo arquivo baixado para android\app\google-services.json
   ```

5. Verifique novamente:
   ```powershell
   .\verificar-google-services.ps1
   ```

#### Opção B: Adicionar Manualmente (Temporário)

Se o download ainda não tiver o client_type 3, podemos adicionar manualmente para testar.

Vou criar um script para isso...

---

### PASSO 4: Verificar se Funcionou

Execute:
```powershell
.\verificar-google-services.ps1
```

Deve mostrar:
```
OAUTH CLIENTS CONFIGURADOS:
   Cliente 1:
      Client ID: (algum ID)
      Client Type: 3  <-- IMPORTANTE: deve ser 3 (Android)
```

---

## 🎯 RESUMO

O problema é que você tem um OAuth Client tipo "Web" (client_type: 1), mas precisa de tipo "Android" (client_type: 3).

**Próxima ação**:
1. Verifique no Google Cloud Console se existe OAuth Client ID tipo Android
2. Se não existir, crie um novo
3. Aguarde 5-10 minutos
4. Baixe novo google-services.json do Firebase
5. Teste novamente

---

## 💡 DICA IMPORTANTE

O Google Sign-In no Android precisa de **DOIS** OAuth Client IDs:
1. ✅ **Web** (client_type: 1) - Você já tem
2. ❌ **Android** (client_type: 3) - Precisa criar

Ambos devem aparecer no google-services.json!

---

## 📞 Me Avise

Depois de verificar no Google Cloud Console, me diga:
1. Existe OAuth Client ID tipo "Android"?
2. Se sim, qual é o Client ID?
3. Se não, vou te ajudar a criar um novo
