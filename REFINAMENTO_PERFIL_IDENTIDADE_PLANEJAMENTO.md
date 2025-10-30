# 📋 Planejamento: Refinamento do Perfil - Identidade Espiritual

## 🎯 Objetivo
Melhorar os campos de cadastro do perfil para otimizar filtros de busca e experiência do usuário.

---

## 🔧 Melhorias Solicitadas

### 1. ✅ Adicionar Campo "Idiomas Falados"
**Localização:** Informações do Perfil > Identidade Espiritual (junto com cidade e idade)

**10 Idiomas Mais Falados do Mundo:**
1. 🇨🇳 Chinês (Mandarim)
2. 🇪🇸 Espanhol
3. 🇬🇧 Inglês
4. 🇮🇳 Hindi
5. 🇧🇷 Português
6. 🇧🇩 Bengali
7. 🇷🇺 Russo
8. 🇯🇵 Japonês
9. 🇩🇪 Alemão
10. 🇫🇷 Francês

**Implementação:**
- Checkboxes (múltipla seleção)
- Permitir selecionar vários idiomas
- Salvar como lista no Firebase
- Usar para filtro de busca

---

### 2. ✅ Corrigir Campo "Cidade"
**Problema Atual:** Campo de texto livre "birigui - SP"
- ❌ Usuário pode digitar errado
- ❌ Dificulta busca por filtro
- ❌ Inconsistência nos dados

**Solução:**
- **País:** Dropdown (começar com Brasil, expandir depois)
- **Estado:** Dropdown (27 estados brasileiros)
- **Cidade:** Dropdown (cidades do estado selecionado)

**Benefícios:**
- ✅ Dados padronizados
- ✅ Busca por filtro precisa
- ✅ Sem erros de digitação
- ✅ Melhor UX

---

### 3. ✅ Corrigir Cores por Gênero
**Problema:** Linhas/bordas rosa em perfil masculino

**Solução:**
- **Masculino:** Azul (#39b9ff)
- **Feminino:** Rosa (#fc6aeb)

**Aplicar em:**
- Bordas de campos
- Linhas decorativas
- Underlines de inputs
- Destaques visuais

---

## 📁 Arquivos a Modificar

### 1. Model (Dados)
- `lib/models/spiritual_profile_model.dart`
  - Adicionar campo `List<String> languages`
  - Adicionar campos `country`, `state`, `city`
  - Remover campo antigo de cidade

### 2. View (Interface)
- `lib/views/profile_identity_task_view.dart`
  - Adicionar seção de idiomas com checkboxes
  - Substituir campo cidade por 3 dropdowns
  - Implementar lógica de cores por gênero

### 3. Repository (Firebase)
- `lib/repositories/spiritual_profile_repository.dart`
  - Atualizar métodos de save/load
  - Adicionar novos campos

### 4. Dados Auxiliares
- Criar arquivo com lista de estados brasileiros
- Criar arquivo com cidades por estado
- Lista de idiomas

---

## 🎨 Design das Cores por Gênero

```dart
Color getPrimaryColor(String? gender) {
  if (gender == 'Masculino') {
    return Color(0xFF39b9ff); // Azul
  } else {
    return Color(0xFFfc6aeb); // Rosa
  }
}
```

---

## 📊 Estrutura de Dados

### Idiomas (Firebase)
```json
{
  "languages": ["Português", "Inglês", "Espanhol"]
}
```

### Localização (Firebase)
```json
{
  "country": "Brasil",
  "state": "São Paulo",
  "city": "Birigui"
}
```

---

## ✅ Checklist de Implementação

### Fase 1: Idiomas
- [ ] Criar lista dos 10 idiomas
- [ ] Adicionar campo no model
- [ ] Criar UI com checkboxes
- [ ] Implementar seleção múltipla
- [ ] Salvar no Firebase
- [ ] Testar

### Fase 2: Localização
- [ ] Criar lista de estados brasileiros
- [ ] Criar mapa de cidades por estado
- [ ] Adicionar campos no model
- [ ] Criar 3 dropdowns (País, Estado, Cidade)
- [ ] Implementar lógica de dependência
- [ ] Salvar no Firebase
- [ ] Testar

### Fase 3: Cores por Gênero
- [ ] Identificar todos os lugares com cor rosa
- [ ] Criar função getPrimaryColor()
- [ ] Aplicar cores dinâmicas
- [ ] Testar com perfil masculino
- [ ] Testar com perfil feminino

---

## 🚀 Prioridade de Implementação

1. **Alta:** Cores por gênero (rápido e impactante)
2. **Alta:** Campo de idiomas (melhora busca)
3. **Média:** Localização estruturada (mais complexo)

---

**Status:** 📝 Planejamento Completo
**Próximo Passo:** Iniciar implementação
