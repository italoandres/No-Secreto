# 🧪 GUIA DE TESTE - COMUNIDADE VIVA (Etapas 3 e 4)

## 🎯 O QUE TESTAR

Você implementou a nova interface de comentários dos Stories com arquitetura escalável. Vamos testar se tudo está funcionando!

---

## 📱 TESTE 1: Navegação para a Tela de Comunidade

### Passos:
1. Abra o app
2. Vá para qualquer Story (contexto principal ou Sinais)
3. Clique no botão de **Comentários** (ícone de balão de fala)

### ✅ Resultado Esperado:
- A tela deve navegar (não abrir bottomSheet)
- Você deve ver a nova tela "Comunidade" com:
  - Cabeçalho fixo no topo
  - Título do vídeo (se houver)
  - Descrição do vídeo (se houver)
  - Seções "🔥 CHATS EM ALTA" e "🌱 CHATS RECENTES"
  - Campo de texto na parte inferior

---

## 📝 TESTE 2: Enviar Primeiro Comentário

### Passos:
1. Na tela de Comunidade, role até o campo de texto no rodapé
2. Digite: "Que mensagem poderosa! 🙏"
3. Clique no botão **Enviar** (ícone de avião)

### ✅ Resultado Esperado:
- O botão deve mostrar um loading (círculo girando)
- Após 1-2 segundos, deve aparecer um SnackBar verde: "Comentário enviado! 🙏"
- O campo de texto deve ser limpo automaticamente
- O comentário deve aparecer na seção "🌱 CHATS RECENTES"

### 🔍 Verificação no Firestore:
1. Abra o Firebase Console
2. Vá em Firestore Database
3. Procure a coleção `community_comments`
4. Você deve ver um novo documento com:
   ```
   {
     storyId: "...",
     userId: "seu-user-id",
     userName: "Seu Nome",
     userAvatarUrl: "sua-foto-url",
     text: "Que mensagem poderosa! 🙏",
     createdAt: Timestamp,
     parentId: null,
     replyCount: 0,
     reactionCount: 0,
     isCurated: false
   }
   ```

---

## 💬 TESTE 3: Múltiplos Comentários

### Passos:
1. Envie mais 3-4 comentários diferentes:
   - "Amém! Isso tocou meu coração ❤️"
   - "Obrigado por compartilhar essa palavra"
   - "Que o Pai continue te abençoando"

### ✅ Resultado Esperado:
- Todos os comentários devem aparecer em "🌱 CHATS RECENTES"
- Os comentários devem estar ordenados do mais recente para o mais antigo
- Cada card deve mostrar:
  - Sua foto de perfil
  - Seu nome
  - Tempo relativo ("agora mesmo", "há 1 minuto")
  - Texto do comentário
  - "0 respostas · 0 reações"

---

## 🔥 TESTE 4: Seção "Chats em Alta"

### Contexto:
A seção "Chats em Alta" só mostra comentários que têm **pelo menos 1 resposta**.

### Passos:
1. No Firestore, edite manualmente um dos seus comentários
2. Mude o campo `replyCount` de `0` para `3`
3. Volte para o app e puxe para atualizar (ou feche e abra a tela novamente)

### ✅ Resultado Esperado:
- O comentário editado deve aparecer em "🔥 CHATS EM ALTA"
- Ele deve mostrar "3 respostas" no rodapé do card
- Ele ainda deve aparecer em "Chats Recentes" também

---

## 🌟 TESTE 5: Badge "Arauto" (Curado)

### Passos:
1. No Firestore, edite um comentário
2. Mude o campo `isCurated` de `false` para `true`
3. Volte para o app

### ✅ Resultado Esperado:
- O comentário deve mostrar um badge dourado no canto superior direito
- Badge deve ter ícone de estrela ⭐ e texto "Arauto"
- Cor: fundo amarelo claro, texto/ícone amarelo escuro

---

## 📖 TESTE 6: Descrição "Ver Mais / Ver Menos"

### Passos:
1. Certifique-se de que o Story tem uma descrição longa (mais de 2 linhas)
2. Na tela de Comunidade, observe o cabeçalho
3. Clique em "⬇️ Ver mais"
4. Clique em "⬆️ Ver menos"

### ✅ Resultado Esperado:
- Inicialmente, a descrição deve estar truncada (2 linhas com "...")
- Ao clicar "Ver mais", deve expandir e mostrar tudo
- Ao clicar "Ver menos", deve voltar a truncar

---

## ⏱️ TESTE 7: Tempo Relativo (TimeAgo)

### Passos:
1. Envie um comentário
2. Observe o tempo mostrado ("agora mesmo")
3. Aguarde 1 minuto
4. Puxe para atualizar ou feche e abra a tela

### ✅ Resultado Esperado:
- Deve mostrar "há 1 minuto"
- Após 5 minutos: "há 5 minutos"
- Após 1 hora: "há 1 hora"
- Após 1 dia: "há 1 dia"

---

## 🚫 TESTE 8: Validações

### Teste 8.1: Comentário Vazio
1. Tente enviar um comentário sem digitar nada
2. **Esperado**: Nada deve acontecer (botão não responde)

### Teste 8.2: Comentário Só com Espaços
1. Digite apenas espaços: "     "
2. Clique em Enviar
3. **Esperado**: Nada deve acontecer (validação de trim)

### Teste 8.3: Usuário Não Logado
1. Faça logout (se possível)
2. Tente acessar um Story
3. **Esperado**: Deve mostrar erro ou redirecionar para login

---

## 🔄 TESTE 9: Atualização em Tempo Real (Streams)

### Passos:
1. Abra o app em 2 dispositivos/emuladores diferentes
2. No dispositivo 1, envie um comentário
3. Observe o dispositivo 2

### ✅ Resultado Esperado:
- O comentário deve aparecer automaticamente no dispositivo 2
- Não precisa atualizar manualmente
- Isso prova que os Streams estão funcionando!

---

## 🎨 TESTE 10: Visual e UX

### Checklist Visual:
- [ ] Cabeçalho tem sombra sutil
- [ ] Cards têm bordas arredondadas (12px)
- [ ] Cards têm sombra suave
- [ ] Avatares são circulares
- [ ] Emojis aparecem corretamente (🔥, 🌱)
- [ ] Campo de texto tem fundo cinza claro
- [ ] Botão enviar é azul
- [ ] Loading no botão é branco e gira
- [ ] SnackBar aparece na parte inferior

### Checklist UX:
- [ ] Scroll é suave
- [ ] Teclado não cobre o campo de texto
- [ ] Botão voltar funciona
- [ ] Transição de tela é suave
- [ ] Não há lag ao carregar comentários

---

## 🐛 PROBLEMAS COMUNS E SOLUÇÕES

### Problema 1: "Perfil espiritual não encontrado"
**Causa**: Usuário não tem perfil em `spiritual_profiles`
**Solução**: Criar perfil espiritual para o usuário de teste

### Problema 2: Comentários não aparecem
**Causa**: `storyId` pode estar vazio ou null
**Solução**: Verificar se o Story tem um ID válido

### Problema 3: Foto não carrega
**Causa**: URL da foto pode estar vazia ou inválida
**Solução**: Verificar campo `mainPhotoUrl` no Firestore

### Problema 4: Erro ao enviar comentário
**Causa**: Permissões do Firestore podem estar bloqueando
**Solução**: Verificar `firestore.rules` para permitir escrita em `community_comments`

---

## 📊 LOGS PARA VERIFICAR

### No Console do App:
```
✅ COMMUNITY: Comentário raiz criado com ID: abc123
```

### No Firestore Console:
- Coleção `community_comments` deve ter novos documentos
- Cada documento deve ter todos os campos preenchidos
- `createdAt` deve ser um Timestamp válido

---

## 🎉 TESTE FINAL: Experiência Completa

### Cenário:
Você é um usuário assistindo a um Story inspirador sobre relacionamentos.

### Passos:
1. Assista ao Story
2. Clique em Comentários
3. Leia os comentários de outros usuários (se houver)
4. Escreva seu próprio comentário compartilhando o que o Pai falou ao seu coração
5. Envie o comentário
6. Veja ele aparecer na lista
7. Volte para o vídeo
8. Avance para o próximo Story
9. Abra os comentários novamente

### ✅ Resultado Esperado:
- Toda a experiência deve ser fluida e intuitiva
- Você deve sentir que está participando de uma comunidade viva
- Os comentários devem carregar rapidamente
- A navegação deve ser natural

---

## 📝 FEEDBACK PARA O DESENVOLVEDOR

Após testar, anote:

1. **O que funcionou perfeitamente?**
2. **O que precisa de ajustes?**
3. **Algum erro ou crash?**
4. **Sugestões de melhoria?**

---

## ⏭️ PRÓXIMOS PASSOS

Após confirmar que tudo está funcionando:

1. **Etapa 5**: Implementar tela de respostas (quando clicar em um comentário)
2. **Etapa 6**: Sistema de reações (curtidas)
3. **Etapa 7**: Seção "Chats do Pai" (curadoria)
4. **Etapa 8**: Notificações de novas respostas

---

## 🚀 PRONTO PARA TESTAR!

Siga este guia passo a passo e reporte qualquer problema encontrado. A base da "Comunidade Viva" está implementada e pronta para crescer! 🙏✨
