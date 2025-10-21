# 🎨 Visual do Filtro de Distância

## 📱 Preview da Interface

### 1. Card de Filtro de Distância

```
╔═══════════════════════════════════════════════════════╗
║  ┌────┐                                               ║
║  │ 📍 │  Distância de Você                           ║
║  └────┘  Até onde você quer buscar?                  ║
║                                                       ║
║                    ┌─────────┐                       ║
║                    │  50 km  │                       ║
║                    └─────────┘                       ║
║                                                       ║
║  ━━━━━━━━━━━━━━●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━   ║
║  5 km                                      400+ km   ║
║                                                       ║
║  ┌─────────────────────────────────────────────┐    ║
║  │ ℹ️  Perfis dentro desta distância da sua   │    ║
║  │     cidade                                  │    ║
║  └─────────────────────────────────────────────┘    ║
╚═══════════════════════════════════════════════════════╝
```

**Características:**
- Borda roxa (`#7B68EE`)
- Sombra suave
- Ícone de localização em destaque
- Valor atual em grande destaque
- Slider com thumb roxo
- Info box azul no rodapé

---

### 2. Card de Toggle de Preferência (Desativado)

```
╔═══════════════════════════════════════════════════════╗
║  ┌────┐                                               ║
║  │ 🤍 │  Tenho mais interesse em pessoas que         ║
║  └────┘  correspondam a essa preferência             ║
║                                          [OFF] ⚪     ║
║                                                       ║
║  ┌─────────────────────────────────────────────┐    ║
║  │ ℹ️  Ative para priorizar perfis dentro da  │    ║
║  │     distância                               │    ║
║  └─────────────────────────────────────────────┘    ║
╚═══════════════════════════════════════════════════════╝
```

**Características:**
- Borda cinza clara
- Ícone de coração cinza
- Switch desativado
- Dica informativa

---

### 3. Card de Toggle de Preferência (Ativado)

```
╔═══════════════════════════════════════════════════════╗
║  ┌────┐                                               ║
║  │ ❤️  │  Tenho mais interesse em pessoas que        ║
║  └────┘  correspondam a essa preferência             ║
║                                          [ON]  🔵     ║
║                                                       ║
║  ┌─────────────────────────────────────────────┐    ║
║  │ 💡 Como funciona?                           │    ║
║  │                                              │    ║
║  │ Com este sinal, podemos saber em quais      │    ║
║  │ tipos de perfil tem mais interesse, mas     │    ║
║  │ ainda sim podem aparecer outros que não     │    ║
║  │ correspondem exatamente.                     │    ║
║  └─────────────────────────────────────────────┘    ║
╚═══════════════════════════════════════════════════════╝
```

**Características:**
- Borda azul (`#4169E1`)
- Ícone de coração vermelho
- Switch ativado (azul)
- Mensagem explicativa expandida
- Animação suave ao expandir

---

### 4. Botão Salvar (Com Alterações)

```
╔═══════════════════════════════════════════════════════╗
║                                                       ║
║  ┌─────────────────────────────────────────────┐    ║
║  │                                              │    ║
║  │         💾  Salvar Filtros                  │    ║
║  │                                              │    ║
║  └─────────────────────────────────────────────┘    ║
║                                                       ║
╚═══════════════════════════════════════════════════════╝
```

**Características:**
- Fundo roxo (`#7B68EE`)
- Texto branco e bold
- Ícone de salvar
- Elevação 4
- Habilitado e clicável

---

### 5. Botão Salvar (Sem Alterações)

```
╔═══════════════════════════════════════════════════════╗
║                                                       ║
║  ┌─────────────────────────────────────────────┐    ║
║  │                                              │    ║
║  │         💾  Filtros Salvos                  │    ║
║  │                                              │    ║
║  └─────────────────────────────────────────────┘    ║
║                                                       ║
╚═══════════════════════════════════════════════════════╝
```

**Características:**
- Fundo cinza
- Texto cinza
- Sem elevação
- Desabilitado

---

### 6. Dialog de Confirmação

```
        ╔═══════════════════════════════════╗
        ║                                   ║
        ║          ┌─────────┐             ║
        ║          │         │             ║
        ║          │   💾    │             ║
        ║          │         │             ║
        ║          └─────────┘             ║
        ║                                   ║
        ║     Salvar alterações?           ║
        ║                                   ║
        ║  Gostaria de salvar as           ║
        ║  alterações no seu filtro        ║
        ║  de busca?                       ║
        ║                                   ║
        ║  ┌──────────┐  ┌──────────┐     ║
        ║  │Descartar │  │  Salvar  │     ║
        ║  └──────────┘  └──────────┘     ║
        ║                                   ║
        ╚═══════════════════════════════════╝
```

**Características:**
- Ícone de salvar em círculo roxo
- Título em negrito
- Mensagem explicativa
- Dois botões:
  - Descartar: Outlined, cinza
  - Salvar: Filled, roxo

---

### 7. Snackbar de Sucesso

```
┌─────────────────────────────────────────────────┐
│ ✅  Filtros de busca salvos                    │
└─────────────────────────────────────────────────┘
```

**Características:**
- Fundo verde claro
- Texto verde escuro
- Ícone de check
- Duração: 2 segundos

---

### 8. Snackbar de Erro

```
┌─────────────────────────────────────────────────┐
│ ❌  Não foi possível salvar os filtros         │
└─────────────────────────────────────────────────┘
```

**Características:**
- Fundo vermelho claro
- Texto vermelho escuro
- Ícone de erro

---

## 🎨 Paleta de Cores

### Cores Principais
```
Primary (Roxo):     #7B68EE  ████████
Secondary (Azul):   #4169E1  ████████
Success (Verde):    #10B981  ████████
Error (Vermelho):   #EF4444  ████████
```

### Cores de Suporte
```
Grey 50:   #FAFAFA  ████████
Grey 100:  #F5F5F5  ████████
Grey 200:  #EEEEEE  ████████
Grey 300:  #E0E0E0  ████████
Grey 400:  #BDBDBD  ████████
Grey 600:  #757575  ████████
Grey 700:  #616161  ████████
Grey 800:  #424242  ████████
```

---

## 📐 Espaçamentos

### Padding
- Cards: `20px`
- Seções: `16px`
- Elementos internos: `12px`
- Pequenos: `8px`

### Margin
- Entre cards: `16px`
- Entre seções: `16px`
- Entre elementos: `12px`

### Border Radius
- Cards: `16px`
- Botões: `12px`
- Info boxes: `10px`
- Badges: `8px`

---

## 🎭 Animações

### 1. Expansão do Toggle
```
Duração: 300ms
Curve: easeInOut
Efeito: AnimatedSize
```

### 2. Slider
```
Feedback: Haptic (mobile)
Transição: Suave
Overlay: 24px radius
```

### 3. Botão Salvar
```
Estado: Enabled ↔ Disabled
Transição: 200ms
Propriedades: cor, elevação
```

### 4. Dialog
```
Entrada: Fade + Scale
Duração: 250ms
Saída: Fade
```

---

## 📱 Responsividade

### Mobile (< 600px)
- Cards: largura total
- Padding: 16px
- Font size: padrão

### Tablet (600-900px)
- Cards: largura total
- Padding: 20px
- Font size: +1

### Desktop (> 900px)
- Cards: max-width 600px
- Padding: 24px
- Font size: +2

---

## ♿ Acessibilidade

### Contraste
✅ Todos os textos têm contraste mínimo de 4.5:1
✅ Elementos interativos têm contraste de 3:1

### Tamanho de Toque
✅ Botões: mínimo 48x48px
✅ Switch: área de toque expandida
✅ Slider: thumb de 24px

### Semântica
✅ Labels descritivos
✅ Hints informativos
✅ Estados claros (enabled/disabled)

---

## 🎯 Estados Visuais

### Slider
- **Normal**: Thumb roxo, track roxo/cinza
- **Dragging**: Overlay roxo, haptic feedback
- **Disabled**: Cinza, sem interação

### Switch
- **OFF**: Thumb cinza, track cinza claro
- **ON**: Thumb azul, track azul claro
- **Disabled**: Cinza, sem interação

### Botão Salvar
- **Enabled**: Roxo, elevação 4, cursor pointer
- **Disabled**: Cinza, sem elevação, cursor default
- **Pressed**: Roxo escuro, elevação 2

### Cards
- **Normal**: Borda colorida, sombra suave
- **Hover** (web): Sombra aumentada
- **Active**: Borda mais grossa

---

## 💡 Dicas de UX

### Feedback Imediato
✅ Slider atualiza valor em tempo real
✅ Toggle mostra/esconde mensagem instantaneamente
✅ Botão muda estado ao detectar alterações

### Prevenção de Erros
✅ Dialog antes de descartar alterações
✅ Botão desabilitado quando não há mudanças
✅ Validação de valores (5-400 km)

### Clareza
✅ Labels descritivos
✅ Mensagens explicativas
✅ Info boxes com contexto
✅ Ícones intuitivos

---

## 🎬 Fluxo Visual

```
1. Usuário abre tela
   ↓
2. Cards aparecem com valores salvos
   ↓
3. Usuário move slider
   ↓
4. Valor atualiza em tempo real
   ↓
5. Botão "Salvar" fica roxo (habilitado)
   ↓
6. Usuário ativa toggle
   ↓
7. Mensagem explicativa expande (animação)
   ↓
8. Usuário clica "Salvar"
   ↓
9. Snackbar verde aparece
   ↓
10. Botão volta para cinza (desabilitado)
```

---

## 🎨 Comparação: Antes vs Depois

### Antes
```
❌ Sem filtro de distância
❌ Sem controle de preferências
❌ Sem persistência de filtros
❌ Sem feedback visual
```

### Depois
```
✅ Filtro de distância completo (5-400 km)
✅ Toggle de preferência com explicação
✅ Persistência no Firestore
✅ Feedback visual em todas as ações
✅ Dialog de confirmação
✅ Snackbars informativos
✅ Design moderno e intuitivo
```

---

**Resultado**: Interface moderna, intuitiva e completa! 🎉
