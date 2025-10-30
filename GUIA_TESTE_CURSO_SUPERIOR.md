# 🧪 Guia de Teste - Curso Superior

## ⚠️ IMPORTANTE: Reinicie o App!

Os novos campos **NÃO aparecerão com Hot Reload**. Você precisa fazer um **Hot Restart** ou **Reiniciar o App completamente**.

---

## 🔄 Como Reiniciar o App

### Opção 1: Hot Restart (Recomendado)
1. No terminal onde o app está rodando, pressione: **`R`** (maiúsculo)
2. Ou no VS Code/Android Studio: Clique no ícone de **"Hot Restart"** (🔄)

### Opção 2: Parar e Iniciar Novamente
1. Pare o app (Ctrl+C no terminal)
2. Execute novamente: `flutter run`

---

## 📝 Passo a Passo do Teste

### 1. **Acesse a Tela**
- Vá para: **Perfil** → **Completar Perfil** → **Identidade Espiritual**

### 2. **Selecione o Nível Educacional**
- Role até a seção **"Nível Educacional"**
- Selecione: **"Superior Completo"** ou **"Superior Incompleto"**

### 3. **Verifique se Aparece a Seção "Formação Superior"**

Após selecionar Superior, você deve ver:

```
┌─────────────────────────────────────┐
│ 📚 Formação Superior                │
│                                     │
│ Em qual instituição?                │
│ [Digite o nome da universidade...]  │
│                                     │
│ Qual curso você fez/está fazendo?   │
│ [Digite para buscar seu curso...]   │
│                                     │
│ Status do curso:                    │
│ [🎓 Se formando] [🎓 Formado(a)]    │
└─────────────────────────────────────┘
```

### 4. **Teste o Campo de Busca de Curso**
- Clique no campo **"Qual curso você fez/está fazendo?"**
- Digite: **"dir"**
- Deve aparecer: **"Direito"** na lista
- Digite: **"psi"**
- Deve aparecer: **"Psicologia"** na lista

### 5. **Teste os Botões de Status**
- Clique em **"Se formando"** → deve ficar azul
- Clique em **"Formado(a)"** → deve ficar azul

### 6. **Salve e Verifique**
- Preencha todos os campos obrigatórios
- Clique em **"Salvar Identidade"**
- Volte para a tela
- Verifique se os dados foram salvos

---

## 🐛 Problemas Comuns

### ❌ "Não aparece a seção de Formação Superior"

**Solução:**
1. Certifique-se de ter selecionado **"Superior Completo"** ou **"Superior Incompleto"**
2. Faça um **Hot Restart** (pressione `R` no terminal)
3. Se ainda não funcionar, **pare e inicie o app novamente**

### ❌ "O dropdown de cursos não abre"

**Solução:**
1. Clique diretamente no campo de texto
2. Comece a digitar (ex: "dir")
3. O dropdown deve abrir automaticamente

### ❌ "Erro de compilação"

**Solução:**
1. Execute: `flutter clean`
2. Execute: `flutter pub get`
3. Execute: `flutter run`

---

## ✅ Checklist de Verificação

- [ ] Reiniciei o app (Hot Restart ou flutter run)
- [ ] Selecionei "Superior Completo" ou "Superior Incompleto"
- [ ] A seção "Formação Superior" apareceu
- [ ] Consigo digitar no campo de instituição
- [ ] Consigo buscar cursos (ex: "direito", "psicologia")
- [ ] O dropdown de cursos aparece com sugestões
- [ ] Consigo selecionar um curso da lista
- [ ] Consigo clicar em "Se formando" ou "Formado(a)"
- [ ] Os botões mudam de cor ao clicar
- [ ] Consigo salvar os dados
- [ ] Os dados aparecem quando volto para a tela

---

## 📱 Comandos Úteis

### Reiniciar o App
```bash
# Pressione R (maiúsculo) no terminal onde o app está rodando
R
```

### Limpar e Reconstruir
```bash
flutter clean
flutter pub get
flutter run
```

### Ver Logs
```bash
flutter logs
```

---

## 🎯 Cursos Disponíveis para Teste

Digite qualquer uma dessas palavras para testar a busca:

- **"dir"** → Direito
- **"psi"** → Psicologia
- **"adm"** → Administração
- **"eng"** → Engenharias (várias)
- **"med"** → Medicina
- **"enf"** → Enfermagem
- **"arq"** → Arquitetura
- **"des"** → Design
- **"comp"** → Ciência da Computação
- **"bio"** → Biologia

---

## 📊 Dados Salvos no Firebase

Após salvar, os dados devem aparecer assim no Firebase:

```json
{
  "education": "Superior Completo",
  "university": "Universidade Federal do Rio de Janeiro",
  "universityCourse": "Direito",
  "courseStatus": "Formado(a)"
}
```

---

## 🆘 Ainda Não Funciona?

Se após seguir todos os passos ainda não funcionar:

1. **Verifique se os arquivos foram criados:**
   - `lib/utils/university_courses_complete_data.dart`
   - `lib/components/university_course_complete_selector_component.dart`

2. **Verifique se não há erros de compilação:**
   ```bash
   flutter analyze
   ```

3. **Tente uma reconstrução completa:**
   ```bash
   flutter clean
   flutter pub get
   flutter run --no-sound-null-safety
   ```

4. **Verifique os logs em tempo real:**
   ```bash
   flutter logs
   ```

---

## ✅ Sucesso!

Se você conseguiu:
- ✅ Ver a seção "Formação Superior"
- ✅ Buscar e selecionar um curso
- ✅ Escolher o status (Se formando/Formado)
- ✅ Salvar os dados

**Parabéns! A implementação está funcionando perfeitamente!** 🎉
