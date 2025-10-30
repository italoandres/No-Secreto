# 🔍 Teste de Debug dos Favoritos

## Como executar o debug

### 1. Adicione temporariamente no seu código:

No arquivo `lib/main.dart` ou em qualquer lugar que seja executado, adicione:

```dart
import 'lib/utils/debug_favorites.dart';

// Para ver TODOS os favoritos:
DebugFavorites.showAllFavorites();

// Para ver favoritos de um contexto específico:
DebugFavorites.showFavoritesByContext('sinais_rebeca');
DebugFavorites.showFavoritesByContext('principal');

// Para monitorar mudanças em tempo real:
DebugFavorites.monitorFavorites();
```

### 2. Ou execute no console do Flutter:

Quando o app estiver rodando, cole no console:

```dart
import 'package:whatsapp_chat/utils/debug_favorites.dart';

// Ver todos os favoritos
DebugFavorites.showAllFavorites();

// Ver favoritos do Sinais Rebeca
DebugFavorites.showFavoritesByContext('sinais_rebeca');

// Ver favoritos do Principal
DebugFavorites.showFavoritesByContext('principal');
```

## O que o debug vai mostrar:

1. **Todos os favoritos** do usuário atual
2. **Contexto de cada favorito** (principal, sinais_rebeca, etc.)
3. **ID do story** e **ID do documento**
4. **Data de criação** de cada favorito
5. **Resumo por contexto**

## Teste passo a passo:

### Passo 1: Ver situação atual
```dart
DebugFavorites.showAllFavorites();
```

### Passo 2: Adicionar um favorito no Sinais Rebeca
1. Vá para "Sinais de Minha Rebeca"
2. Abra um story
3. Clique no coração para favoritar
4. Execute novamente:
```dart
DebugFavorites.showAllFavorites();
```

### Passo 3: Verificar se foi salvo no contexto correto
```dart
DebugFavorites.showFavoritesByContext('sinais_rebeca');
```

### Passo 4: Verificar se não vazou para o principal
```dart
DebugFavorites.showFavoritesByContext('principal');
```

## Resultado esperado:

- Favoritos do "Sinais Rebeca" devem ter `contexto: "sinais_rebeca"`
- Favoritos do "Principal" devem ter `contexto: "principal"`
- Não deve haver mistura entre contextos

## Se encontrar problemas:

Execute a limpeza automática:
```dart
DebugFavorites.cleanupFavorites();
```

---

**Execute o debug e me mande o resultado!** Assim posso ver exatamente o que está acontecendo com os favoritos.