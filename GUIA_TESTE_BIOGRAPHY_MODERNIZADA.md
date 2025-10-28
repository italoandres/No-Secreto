# 🧪 GUIA DE TESTE: ProfileBiographyTaskView Modernizada

## 🎯 O QUE TESTAR

1. ✅ Visual moderno (gradientes, cards, ícones)
2. ✅ Controle de privacidade para virgindade
3. ✅ Funcionalidade de salvamento
4. ✅ Validações de campos

---

## 📱 PASSO A PASSO

### 1. Abrir a Tela

```
1. Fazer login no app
2. Ir para o perfil
3. Clicar em "Completar Perfil" ou "Editar Biografia"
4. Abrir ProfileBiographyTaskView
```

**O que observar:**
- ✅ Gradiente roxo/azul no fundo
- ✅ AppBar customizada com título e subtítulo
- ✅ Cards com sombras elegantes
- ✅ Ícones coloridos em cada seção

---

### 2. Testar Campos Normais

```
1. Preencher "Qual é o seu propósito?"
2. Selecionar "Você faz parte do movimento Deus é Pai?"
3. Selecionar status de relacionamento
4. Preencher outros campos
```

**O que observar:**
- ✅ Campos com bordas arredondadas
- ✅ Ícones com background colorido
- ✅ Focus mostra borda roxa
- ✅ Validação mostra borda vermelha

---

### 3. Testar Controle de Privacidade (PRINCIPAL)

```
1. Rolar até a pergunta "Você é virgem?"
2. Observar o card especial com gradiente
3. Selecionar uma resposta no dropdown:
   - Sim
   - Não
   - Prefiro não responder
4. Observar o switch "Tornar esta informação pública"
5. Estado INICIAL (Privado):
   - Switch DESMARCADO
   - Ícone: 👁️‍🗨️ (visibility_off)
   - Cor: Cinza
   - Texto: "Informação privada"
   - Explicação: "permanecerá privada"
6. Marcar o switch (Tornar Público):
   - Switch MARCADO
   - Ícone: 👁️ (visibility)
   - Cor: Roxo/Azul
   - Texto: "Visível no seu perfil"
   - Explicação: "será exibida em seu perfil público"
7. Desmarcar o switch novamente
8. Observar transições suaves
```

**O que observar:**
- ✅ Card com gradiente especial
- ✅ Dropdown funciona
- ✅ Switch funciona
- ✅ Cores mudam conforme estado
- ✅ Ícone muda conforme estado
- ✅ Texto explicativo muda
- ✅ Animações suaves

---

### 4. Testar Salvamento

```
1. Preencher todos os campos obrigatórios
2. Configurar privacidade da virgindade:
   - Opção A: Deixar PRIVADO (switch desmarcado)
   - Opção B: Tornar PÚBLICO (switch marcado)
3. Clicar em "Salvar Biografia"
4. Observar:
   - Botão mostra loading
   - Snackbar de sucesso aparece
   - Volta para tela anterior
```

**O que observar:**
- ✅ Botão com gradiente roxo/azul
- ✅ Animação de loading
- ✅ Snackbar moderno com ícone
- ✅ Navegação funciona

---

### 5. Verificar no Firestore

#### Opção A: Salvou como PRIVADO

```javascript
// Abrir Firebase Console
// Ir para Firestore Database
// Navegar para: spiritual_profiles/{profileId}

{
  "isVirgin": true, // ou false, ou null
  "isVirginityPublic": false, // ← PRIVADO
  // ... outros campos
}

// Também verificar: usuarios/{userId}
{
  "isVirginityPublic": false, // ← PRIVADO
  // ... outros campos
}
```

#### Opção B: Salvou como PÚBLICO

```javascript
// spiritual_profiles/{profileId}
{
  "isVirgin": true, // ou false, ou null
  "isVirginityPublic": true, // ← PÚBLICO
  // ... outros campos
}

// usuarios/{userId}
{
  "isVirginityPublic": true, // ← PÚBLICO
  // ... outros campos
}
```

---

### 6. Testar Carregamento de Dados

```
1. Fechar e reabrir a tela
2. Verificar que:
   - Todos os campos estão preenchidos
   - Resposta sobre virgindade está correta
   - Switch de privacidade está no estado correto
```

**O que observar:**
- ✅ Dados carregam corretamente
- ✅ Switch reflete o estado salvo
- ✅ Não há erros no console

---

## 🎨 CHECKLIST VISUAL

### Gradiente de Fundo
- [ ] Gradiente roxo/azul visível
- [ ] Transição suave de cores
- [ ] Cobre toda a tela

### AppBar Customizada
- [ ] Botão de voltar com background semi-transparente
- [ ] Título "✍️ Biografia Espiritual"
- [ ] Subtítulo "Compartilhe sua jornada de fé"
- [ ] Texto branco

### Cards Modernos
- [ ] Bordas arredondadas
- [ ] Sombras visíveis
- [ ] Background branco semi-transparente
- [ ] Espaçamento adequado

### Ícones
- [ ] Ícones coloridos em cada card
- [ ] Background colorido nos ícones
- [ ] Tamanho adequado

### Campos de Texto
- [ ] Bordas arredondadas
- [ ] Background cinza claro
- [ ] Focus mostra borda roxa
- [ ] Ícones com background colorido

### Card de Privacidade
- [ ] Gradiente especial (branco → azul claro)
- [ ] Dropdown estilizado
- [ ] Switch funcional
- [ ] Ícone muda conforme estado
- [ ] Cores mudam conforme estado
- [ ] Texto explicativo muda

### Botão de Salvar
- [ ] Gradiente roxo/azul
- [ ] Sombra colorida
- [ ] Ícone de check
- [ ] Animação de loading

---

## 🐛 POSSÍVEIS PROBLEMAS

### Problema 1: Gradiente não aparece
**Solução:** Verificar se o Container com gradient está envolvendo todo o body

### Problema 2: Switch não funciona
**Solução:** Verificar se `setState` está sendo chamado no `onPrivacyChanged`

### Problema 3: Dados não salvam
**Solução:** Verificar logs do console e permissões do Firestore

### Problema 4: Cards não aparecem
**Solução:** Verificar se os imports estão corretos

### Problema 5: Ícones não aparecem
**Solução:** Verificar se os ícones do Material Design estão disponíveis

---

## 📊 CENÁRIOS DE TESTE

### Cenário 1: Usuário Novo (Primeira Vez)
```
1. Abrir tela pela primeira vez
2. Todos os campos vazios
3. Switch de privacidade DESMARCADO (privado por padrão)
4. Preencher e salvar
5. Verificar salvamento correto
```

### Cenário 2: Usuário Editando (Já tem dados)
```
1. Abrir tela com dados existentes
2. Campos preenchidos
3. Switch reflete estado salvo
4. Editar e salvar
5. Verificar atualização correta
```

### Cenário 3: Usuário Muda de Privado para Público
```
1. Abrir tela com virgindade PRIVADA
2. Switch DESMARCADO
3. Marcar switch (tornar público)
4. Salvar
5. Verificar no Firestore: isVirginityPublic = true
```

### Cenário 4: Usuário Muda de Público para Privado
```
1. Abrir tela com virgindade PÚBLICA
2. Switch MARCADO
3. Desmarcar switch (tornar privado)
4. Salvar
5. Verificar no Firestore: isVirginityPublic = false
```

### Cenário 5: Usuário Prefere Não Responder
```
1. Selecionar "Prefiro não responder"
2. Switch fica disponível mas sem efeito prático
3. Salvar
4. Verificar no Firestore: isVirgin = null
```

---

## ✅ CRITÉRIOS DE SUCESSO

### Visual
- [x] Gradiente de fundo presente
- [x] Cards com sombras elegantes
- [x] Ícones coloridos
- [x] Animações suaves
- [x] Botão moderno

### Funcionalidade
- [x] Todos os campos funcionam
- [x] Validações funcionam
- [x] Switch de privacidade funciona
- [x] Salvamento funciona
- [x] Carregamento funciona

### Privacidade
- [x] Padrão é PRIVADO
- [x] Switch muda estado
- [x] Visual reflete estado
- [x] Salva corretamente no Firestore
- [x] Carrega corretamente

---

## 🎯 RESULTADO ESPERADO

Após todos os testes, você deve ter:

1. ✅ Uma tela visualmente moderna e elegante
2. ✅ Controle de privacidade funcionando perfeitamente
3. ✅ Dados salvando corretamente no Firestore
4. ✅ Experiência do usuário fluida e intuitiva

---

## 📸 SCREENSHOTS SUGERIDOS

Tire screenshots de:
1. Tela completa com gradiente
2. Card de privacidade (estado privado)
3. Card de privacidade (estado público)
4. Botão de salvar
5. Snackbar de sucesso
6. Firestore com dados salvos

---

## 🚀 PRÓXIMOS PASSOS APÓS TESTE

Se tudo estiver funcionando:
1. ✅ Marcar task como completa
2. ✅ Documentar qualquer ajuste necessário
3. ✅ Considerar aplicar o mesmo padrão em outras telas
4. ✅ Implementar lógica de exibição baseada em privacidade

Se houver problemas:
1. 🐛 Documentar o problema
2. 🔍 Investigar a causa
3. 🔧 Aplicar correção
4. ✅ Testar novamente

---

## 💡 DICAS

- Use o **Hot Reload** do Flutter para ver mudanças rapidamente
- Verifique o **console** para logs e erros
- Use o **Flutter DevTools** para debug visual
- Teste em **diferentes tamanhos de tela**
- Teste com **dados reais** e **dados vazios**

---

## 🎉 BOA SORTE!

A implementação está completa e pronta para teste.
Qualquer problema, consulte o arquivo `IMPLEMENTACAO_PROFILE_BIOGRAPHY_MODERNIZADA.md` para detalhes técnicos.
