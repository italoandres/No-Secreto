# 🔐 Guia de Deploy das Regras do Firestore

## ✅ Regras Adicionadas

Adicionei as seguintes regras de segurança para o sistema de Sinais:

### 1. **Perfis Públicos** (`/profiles/{profileId}`)
- ✅ Qualquer usuário autenticado pode ler perfis
- ✅ Usuário pode criar/atualizar seu próprio perfil
- ✅ Usuário pode deletar seu próprio perfil

### 2. **Recomendações Semanais** (`/weeklyRecommendations/{docId}`)
- ✅ Usuário pode ler suas próprias recomendações
- ✅ Sistema pode criar/atualizar recomendações
- ✅ Formato do docId: `userId_weekKey`

### 3. **Interesses** (`/interests/{interestId}`)
- ✅ Usuário pode ler interesses onde é participante
- ✅ Usuário pode demonstrar interesse em alguém
- ✅ Sistema pode atualizar status quando vira match

### 4. **Matches** (`/matches/{matchId}`)
- ✅ Usuário pode ler matches onde é participante
- ✅ Sistema pode criar match quando há interesse mútuo
- ✅ Participantes podem atualizar match

### 5. **Filtros de Busca** (`/searchFilters/{userId}`)
- ✅ Usuário pode gerenciar seus próprios filtros

---

## 🚀 Como Fazer o Deploy

### Opção 1: Via Firebase Console (Mais Fácil)

1. **Acesse o Firebase Console:**
   - Vá para: https://console.firebase.google.com/
   - Selecione seu projeto

2. **Navegue até Firestore:**
   - No menu lateral, clique em **"Firestore Database"**
   - Clique na aba **"Regras"** (Rules)

3. **Cole as Novas Regras:**
   - Copie todo o conteúdo do arquivo `firestore.rules`
   - Cole no editor do Firebase Console
   - Clique em **"Publicar"** (Publish)

4. **Aguarde a Confirmação:**
   - Você verá uma mensagem de sucesso
   - As regras estarão ativas em alguns segundos

---

### Opção 2: Via Firebase CLI (Linha de Comando)

1. **Instale o Firebase CLI** (se ainda não tiver):
```bash
npm install -g firebase-tools
```

2. **Faça Login:**
```bash
firebase login
```

3. **Inicialize o Projeto** (se ainda não fez):
```bash
firebase init
```
- Selecione **"Firestore"**
- Escolha seu projeto
- Use o arquivo `firestore.rules` existente

4. **Faça o Deploy:**
```bash
firebase deploy --only firestore:rules
```

5. **Aguarde a Confirmação:**
```
✔  Deploy complete!
```

---

## 🧪 Testando as Regras

Após o deploy, teste criando os perfis:

1. **Abra o app no navegador**
2. **Clique no botão azul com estrela** ✨ (Nova Aba Sinais)
3. **Clique no ícone de bug** 🐛 no AppBar
4. **Clique em "Criar 6 Perfis de Teste"**
5. **Aguarde a mensagem de sucesso**
6. **Volte para a aba "Hoje"** para ver os perfis

---

## 🔗 Links Úteis

- **Firebase Console:** https://console.firebase.google.com/
- **Documentação de Regras:** https://firebase.google.com/docs/firestore/security/get-started
- **Testador de Regras:** https://firebase.google.com/docs/rules/simulator

---

## ⚠️ Importante

- As regras são **seguras** e permitem apenas operações autorizadas
- Cada usuário só pode acessar seus próprios dados
- Perfis públicos são visíveis para todos (necessário para o sistema de matches)
- Interesses e matches são privados entre os participantes

---

## 🆘 Problemas?

Se ainda der erro de permissão após o deploy:

1. **Verifique se o deploy foi bem-sucedido**
2. **Aguarde 1-2 minutos** (propagação das regras)
3. **Faça logout e login novamente** no app
4. **Limpe o cache do navegador** (Ctrl+Shift+Delete)
5. **Tente novamente**

Se o problema persistir, me avise que ajudo a investigar! 🚀
