# 🔄 Diagrama de Fluxo - Implementação Completa

## 📊 Visão Geral do Sistema

```
┌─────────────────────────────────────────────────────────────┐
│                    SISTEMA DE PERFIL                        │
│                   IDENTIDADE ESPIRITUAL                     │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
        ┌─────────────────────────────────────────┐
        │         USUÁRIO ABRE A TELA             │
        └─────────────────────────────────────────┘
                              │
                              ▼
        ┌─────────────────────────────────────────┐
        │    SISTEMA DETECTA GÊNERO DO PERFIL     │
        └─────────────────────────────────────────┘
                              │
                ┌─────────────┴─────────────┐
                │                           │
                ▼                           ▼
    ┌───────────────────┐       ┌───────────────────┐
    │   MASCULINO       │       │    FEMININO       │
    │   Cores AZUIS     │       │   Cores ROSAS     │
    │   #39b9ff         │       │   #fc6aeb         │
    └───────────────────┘       └───────────────────┘
                │                           │
                └─────────────┬─────────────┘
                              │
                              ▼
        ┌─────────────────────────────────────────┐
        │      INTERFACE CARREGA COM CORES        │
        │         PERSONALIZADAS                  │
        └─────────────────────────────────────────┘
```

---

## 🎨 Fluxo de Cores

```
INÍCIO
  │
  ▼
┌─────────────────┐
│ Perfil Carregado│
└─────────────────┘
  │
  ▼
┌─────────────────────────────────┐
│ GenderColors.getPrimaryColor()  │
│ Recebe: profile.gender          │
└─────────────────────────────────┘
  │
  ├─── Se "Masculino" ──→ Retorna #39b9ff (Azul)
  │
  └─── Se "Feminino" ───→ Retorna #fc6aeb (Rosa)
  │
  ▼
┌─────────────────────────────────┐
│ Cor Aplicada em:                │
│ • AppBar                        │
│ • Bordas de campos              │
│ • Botões                        │
│ • Cards informativos            │
│ • Chips de idiomas              │
└─────────────────────────────────┘
```

---

## 📍 Fluxo de Localização

```
INÍCIO
  │
  ▼
┌─────────────────────────────────┐
│ Dropdown de PAÍS                │
│ Valor: "Brasil"                 │
└─────────────────────────────────┘
  │
  ▼
┌─────────────────────────────────┐
│ Usuário Seleciona PAÍS          │
└─────────────────────────────────┘
  │
  ▼
┌─────────────────────────────────┐
│ Dropdown de ESTADO              │
│ Carrega: 27 estados brasileiros │
└─────────────────────────────────┘
  │
  ▼
┌─────────────────────────────────┐
│ Usuário Seleciona ESTADO        │
│ Ex: "São Paulo"                 │
└─────────────────────────────────┘
  │
  ▼
┌─────────────────────────────────┐
│ Dropdown de CIDADE              │
│ Carrega: Cidades do estado      │
│ Fonte: BrazilLocationsData      │
└─────────────────────────────────┘
  │
  ▼
┌─────────────────────────────────┐
│ Usuário Seleciona CIDADE        │
│ Ex: "Birigui"                   │
└─────────────────────────────────┘
  │
  ▼
┌─────────────────────────────────┐
│ Sistema Cria fullLocation       │
│ "Birigui - São Paulo"           │
└─────────────────────────────────┘
```

---

## 🌍 Fluxo de Idiomas

```
INÍCIO
  │
  ▼
┌─────────────────────────────────┐
│ Carrega Lista de Idiomas        │
│ Fonte: LanguagesData            │
│ Total: 10 idiomas               │
└─────────────────────────────────┘
  │
  ▼
┌─────────────────────────────────┐
│ Exibe Chips Clicáveis           │
│ • 🇧🇷 Português                 │
│ • 🇬🇧 Inglês                    │
│ • 🇪🇸 Espanhol                  │
│ • ... (7 mais)                  │
└─────────────────────────────────┘
  │
  ▼
┌─────────────────────────────────┐
│ Usuário Clica em Chip           │
└─────────────────────────────────┘
  │
  ├─── Se NÃO selecionado ──→ Adiciona à lista
  │                            Muda cor da borda
  │                            Mostra checkmark
  │
  └─── Se JÁ selecionado ───→ Remove da lista
                               Volta cor normal
                               Remove checkmark
  │
  ▼
┌─────────────────────────────────┐
│ Lista Atualizada                │
│ Ex: ["Português", "Inglês"]     │
└─────────────────────────────────┘
```

---

## 💾 Fluxo de Salvamento

```
INÍCIO
  │
  ▼
┌─────────────────────────────────┐
│ Usuário Clica em "Salvar"       │
└─────────────────────────────────┘
  │
  ▼
┌─────────────────────────────────┐
│ Validação de Formulário         │
└─────────────────────────────────┘
  │
  ├─── País preenchido? ──→ NÃO ──→ Mostra erro
  ├─── Estado preenchido? ─→ NÃO ──→ Mostra erro
  ├─── Cidade preenchida? ─→ NÃO ──→ Mostra erro
  ├─── Idiomas selecionados? → NÃO ──→ Mostra erro
  └─── Idade válida (18-100)? → NÃO ──→ Mostra erro
  │
  │ (Se TODOS válidos)
  ▼
┌─────────────────────────────────┐
│ Monta Objeto de Atualização     │
│ {                               │
│   country: "Brasil",            │
│   state: "São Paulo",           │
│   city: "Birigui",              │
│   fullLocation: "Birigui - SP", │
│   languages: ["Português",...], │
│   age: 25                       │
│ }                               │
└─────────────────────────────────┘
  │
  ▼
┌─────────────────────────────────┐
│ Mostra Loading                  │
│ "⏳ Salvando..."                │
└─────────────────────────────────┘
  │
  ▼
┌─────────────────────────────────┐
│ Envia para Firebase             │
│ SpiritualProfileRepository      │
│ .updateProfile()                │
└─────────────────────────────────┘
  │
  ├─── SUCESSO ──→ Marca tarefa completa
  │                Mostra snackbar verde
  │                Volta para tela anterior
  │
  └─── ERRO ─────→ Mostra snackbar vermelho
                   Permite tentar novamente
```

---

## 🔄 Fluxo de Carregamento de Dados

```
INÍCIO
  │
  ▼
┌─────────────────────────────────┐
│ Tela Abre                       │
│ initState() chamado             │
└─────────────────────────────────┘
  │
  ▼
┌─────────────────────────────────┐
│ _loadExistingData()             │
└─────────────────────────────────┘
  │
  ▼
┌─────────────────────────────────┐
│ Carrega dados do profile        │
│ (passado como parâmetro)        │
└─────────────────────────────────┘
  │
  ▼
┌─────────────────────────────────┐
│ Preenche Campos                 │
│ • _selectedCountry = country    │
│ • _selectedState = state        │
│ • _selectedCity = city          │
│ • _selectedLanguages = languages│
│ • _ageController.text = age     │
└─────────────────────────────────┘
  │
  ▼
┌─────────────────────────────────┐
│ Interface Atualizada            │
│ Campos preenchidos              │
└─────────────────────────────────┘
```

---

## 🎯 Fluxo Completo de Uso

```
┌─────────────────────────────────────────────────────────────┐
│                    FLUXO COMPLETO                           │
└─────────────────────────────────────────────────────────────┘

1. ABERTURA
   ↓
   Usuário abre tela
   ↓
   Sistema detecta gênero
   ↓
   Aplica cores (azul/rosa)
   ↓
   Carrega dados existentes

2. PREENCHIMENTO
   ↓
   Seleciona País (Brasil)
   ↓
   Seleciona Estado (São Paulo)
   ↓
   Seleciona Cidade (Birigui)
   ↓
   Seleciona Idiomas (Português, Inglês)
   ↓
   Digita Idade (25)

3. VALIDAÇÃO
   ↓
   Clica em "Salvar"
   ↓
   Sistema valida campos
   ↓
   Todos válidos? → SIM

4. SALVAMENTO
   ↓
   Mostra loading
   ↓
   Envia para Firebase
   ↓
   Sucesso!
   ↓
   Mostra mensagem
   ↓
   Volta para tela anterior

5. RESULTADO
   ↓
   Dados salvos no Firebase:
   {
     country: "Brasil",
     state: "São Paulo",
     city: "Birigui",
     fullLocation: "Birigui - São Paulo",
     languages: ["Português", "Inglês"],
     age: 25
   }
```

---

## 🏗️ Arquitetura de Componentes

```
┌─────────────────────────────────────────────────────────────┐
│              ProfileIdentityTaskViewEnhanced                │
│                    (View Principal)                         │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ usa
                              ▼
        ┌─────────────────────────────────────────┐
        │           UTILITÁRIOS                   │
        └─────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ▼                     ▼                     ▼
┌───────────────┐   ┌───────────────┐   ┌───────────────┐
│ GenderColors  │   │ LanguagesData │   │BrazilLocations│
│               │   │               │   │     Data      │
│ • getPrimary  │   │ • languages   │   │ • states      │
│ • getBackground│   │ • getNames    │   │ • cities      │
│ • getBorder   │   │ • getFlag     │   │ • getCities   │
└───────────────┘   └───────────────┘   └───────────────┘
        │                     │                     │
        └─────────────────────┼─────────────────────┘
                              │
                              ▼
        ┌─────────────────────────────────────────┐
        │         SpiritualProfileModel           │
        │              (Modelo)                   │
        └─────────────────────────────────────────┘
                              │
                              │ salva via
                              ▼
        ┌─────────────────────────────────────────┐
        │    SpiritualProfileRepository           │
        │           (Repository)                  │
        └─────────────────────────────────────────┘
                              │
                              │ persiste em
                              ▼
        ┌─────────────────────────────────────────┐
        │          Firebase Firestore             │
        │    Collection: spiritual_profiles       │
        └─────────────────────────────────────────┘
```

---

## 📊 Fluxo de Dados

```
┌─────────────┐
│   USUÁRIO   │
└─────────────┘
       │
       │ interage
       ▼
┌─────────────┐
│    VIEW     │ ←──────┐
│  (Interface)│        │
└─────────────┘        │
       │               │
       │ chama         │ atualiza
       ▼               │
┌─────────────┐        │
│ CONTROLLER  │        │
│  (Lógica)   │        │
└─────────────┘        │
       │               │
       │ usa           │
       ▼               │
┌─────────────┐        │
│  UTILITIES  │        │
│  (Helpers)  │        │
└─────────────┘        │
       │               │
       │ manipula      │
       ▼               │
┌─────────────┐        │
│    MODEL    │        │
│   (Dados)   │        │
└─────────────┘        │
       │               │
       │ salva via     │
       ▼               │
┌─────────────┐        │
│ REPOSITORY  │        │
│  (Acesso)   │        │
└─────────────┘        │
       │               │
       │ persiste      │
       ▼               │
┌─────────────┐        │
│  FIREBASE   │        │
│  (Backend)  │ ───────┘
└─────────────┘
```

---

## 🎉 Resultado Final

```
┌─────────────────────────────────────────────────────────────┐
│                    ANTES                                    │
├─────────────────────────────────────────────────────────────┤
│ • Cores sempre rosas                                        │
│ • Campo de cidade texto livre                               │
│ • Sem campo de idiomas                                      │
│ • Dados não padronizados                                    │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ TRANSFORMAÇÃO
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    DEPOIS                                   │
├─────────────────────────────────────────────────────────────┤
│ ✅ Cores dinâmicas (azul/rosa)                              │
│ ✅ Localização estruturada (dropdowns)                      │
│ ✅ Campo de idiomas (seleção múltipla)                      │
│ ✅ Dados padronizados                                       │
│ ✅ Validações robustas                                      │
│ ✅ Interface moderna                                        │
└─────────────────────────────────────────────────────────────┘
```

---

**Implementado em:** 13/10/2025
**Status:** ✅ COMPLETO

