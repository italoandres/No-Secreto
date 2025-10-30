# Implementação dos Filtros: Filhos, Beber e Fumar

## 📋 Resumo da Implementação

Vou implementar 3 novos filtros seguindo o mesmo padrão dos anteriores:

### 1. Filtro de Filhos
**Opções:**
- Não tenho preferência (padrão)
- Tem filhos
- Não tem filhos

**Cor:** Teal (verde-azulado)
**Ícone:** Icons.child_care

### 2. Filtro de Beber
**Opções:**
- Não tenho preferência (padrão)
- Não bebe
- Bebe socialmente
- Bebe regularmente

**Cor:** Amber (âmbar/dourado)
**Ícone:** Icons.local_bar

### 3. Filtro de Fumar
**Opções:**
- Não tenho preferência (padrão)
- Não fuma
- Fuma ocasionalmente
- Fuma regularmente

**Cor:** Red (vermelho)
**Ícone:** Icons.smoking_rooms

## 🎨 Cores Escolhidas

- **Distância:** Blue (#2196F3)
- **Idade:** Green (#4CAF50)
- **Altura:** Orange (#FF9800)
- **Idiomas:** Blue (#2196F3)
- **Educação:** Purple (#9C27B0)
- **Filhos:** Teal (#009688) ✨ NOVO
- **Beber:** Amber (#FFC107) ✨ NOVO
- **Fumar:** Red (#F44336) ✨ NOVO

## 📁 Arquivos a Criar

Para cada filtro, criarei 2 componentes:
1. `{nome}_filter_card.dart` - Card com seleção
2. `{nome}_preference_toggle_card.dart` - Toggle de preferência

**Total:** 6 novos arquivos

## 🔧 Modificações Necessárias

1. **search_filters_model.dart** - Adicionar 6 novos campos
2. **explore_profiles_controller.dart** - Adicionar 6 variáveis reativas e 6 métodos
3. **explore_profiles_view.dart** - Adicionar 6 componentes e imports

Vou implementar tudo de forma consolidada para economizar tokens.
