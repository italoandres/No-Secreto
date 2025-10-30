# 🧪 Guia de Teste: Países Mundiais

## 🎯 Como Testar a Nova Funcionalidade

### Pré-requisitos
1. Aplicativo rodando no emulador/dispositivo
2. Usuário logado
3. Acesso à tela de "Identidade Espiritual"

---

## 📱 Cenários de Teste

### ✅ Teste 1: Usuário Brasileiro

**Passos:**
1. Abra a tela de Identidade Espiritual
2. No campo **"País"**, selecione **"Brasil"**
3. Verifique que o campo **"Estado"** aparece
4. Selecione um estado (ex: **"São Paulo"**)
5. Verifique que o campo **"Cidade"** aparece com cidades do estado
6. Selecione uma cidade (ex: **"Campinas"**)
7. Preencha os outros campos (idiomas, idade)
8. Clique em **"Salvar Identidade"**

**Resultado Esperado:**
- ✅ Todos os campos aparecem corretamente
- ✅ Cidades são filtradas por estado
- ✅ Salvamento bem-sucedido
- ✅ `fullLocation` salvo como: "Campinas - SP"

---

### ✅ Teste 2: Usuário de Outro País

**Passos:**
1. Abra a tela de Identidade Espiritual
2. No campo **"País"**, selecione **"França"** (ou qualquer outro país)
3. Verifique que o campo **"Estado"** NÃO aparece
4. Verifique que aparece um campo de **texto** para cidade
5. Digite uma cidade (ex: **"Paris"**)
6. Preencha os outros campos (idiomas, idade)
7. Clique em **"Salvar Identidade"**

**Resultado Esperado:**
- ✅ Campo de estado não aparece
- ✅ Campo de texto para cidade funciona
- ✅ Salvamento bem-sucedido
- ✅ `fullLocation` salvo como: "Paris, França"

---

### ✅ Teste 3: Mudança de País

**Passos:**
1. Selecione **"Brasil"** como país
2. Selecione **"São Paulo"** como estado
3. Selecione **"Campinas"** como cidade
4. Agora mude o país para **"Portugal"**
5. Verifique o que acontece com estado e cidade

**Resultado Esperado:**
- ✅ Ao mudar o país, estado e cidade são **resetados**
- ✅ Campo de estado desaparece
- ✅ Campo de cidade vira texto livre
- ✅ Usuário pode digitar nova cidade

---

### ✅ Teste 4: Validações

**Teste 4.1: Campos Obrigatórios**
1. Tente salvar sem selecionar país
2. Tente salvar sem selecionar estado (Brasil)
3. Tente salvar sem selecionar/digitar cidade

**Resultado Esperado:**
- ✅ Mensagens de erro aparecem
- ✅ Salvamento é bloqueado

**Teste 4.2: Validação de Idade**
1. Digite idade menor que 18
2. Digite idade maior que 100
3. Digite texto ao invés de número

**Resultado Esperado:**
- ✅ Mensagens de erro apropriadas
- ✅ Salvamento é bloqueado

---

### ✅ Teste 5: Lista de Países

**Passos:**
1. Abra o dropdown de países
2. Role a lista
3. Verifique se encontra países de diferentes continentes

**Países para Verificar:**
- ✅ África: Angola, África do Sul, Egito
- ✅ América: Brasil, Estados Unidos, Argentina, Canadá
- ✅ Ásia: Japão, China, Índia, Coreia do Sul
- ✅ Europa: França, Alemanha, Portugal, Itália
- ✅ Oceania: Austrália, Nova Zelândia

**Resultado Esperado:**
- ✅ Lista completa com 195 países
- ✅ Países em português
- ✅ Ordem alfabética

---

## 🔍 Verificação no Firebase

### Após Salvar, Verifique no Firestore:

**Para Usuário Brasileiro:**
```javascript
{
  country: "Brasil",
  state: "São Paulo",
  city: "Campinas",
  fullLocation: "Campinas - SP",
  languages: ["Português"],
  age: 28
}
```

**Para Usuário Internacional:**
```javascript
{
  country: "França",
  state: null,
  city: "Paris",
  fullLocation: "Paris, França",
  languages: ["Português", "Francês"],
  age: 30
}
```

---

## 🐛 Problemas Comuns e Soluções

### Problema 1: Dropdown de países não aparece
**Solução:** Verifique se o arquivo `world_locations_data.dart` está importado corretamente

### Problema 2: Cidades não aparecem ao selecionar estado
**Solução:** Verifique se o estado selecionado existe no `BrazilLocationsData`

### Problema 3: Erro ao salvar
**Solução:** Verifique as permissões do Firebase e se o usuário está autenticado

---

## ✅ Checklist de Validação

Marque cada item após testar:

- [ ] Dropdown de países funciona
- [ ] Lista tem 195 países
- [ ] Seleção de Brasil mostra estados
- [ ] Seleção de estado mostra cidades
- [ ] Seleção de outro país mostra campo de texto
- [ ] Mudança de país reseta estado e cidade
- [ ] Validações funcionam corretamente
- [ ] Salvamento funciona para Brasil
- [ ] Salvamento funciona para outros países
- [ ] Dados aparecem corretamente no Firebase
- [ ] Interface é responsiva e bonita
- [ ] Não há erros no console

---

## 📊 Teste de Performance

### Teste de Carga
1. Abra o dropdown de países
2. Role rapidamente pela lista
3. Selecione diferentes países várias vezes

**Resultado Esperado:**
- ✅ Interface permanece fluida
- ✅ Sem travamentos
- ✅ Transições suaves

---

## 🎉 Teste Completo!

Se todos os testes passaram, a implementação está **100% funcional** e pronta para produção!

---

**Dica:** Teste com diferentes dispositivos e tamanhos de tela para garantir que a interface se adapta bem.
