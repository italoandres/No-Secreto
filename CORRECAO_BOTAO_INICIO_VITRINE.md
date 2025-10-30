# Correção do Botão "Início" na VitrineConfirmationView

## Problema Identificado

Ao clicar no botão "Início" na tela de confirmação da vitrine, ocorria o erro:
```
Another exception was thrown: Unexpected null value.
```

### Causa Raiz

No método `navigateToHome()` do `VitrineConfirmationController`, o código estava usando:
```dart
Get.offAllNamed('/home');
```

Esse erro acontecia porque:
1. A rota `/home` pode não estar definida nas rotas nomeadas do GetX
2. O GetX não conseguia encontrar a rota e retornava `null`
3. Isso causava o erro `Unexpected null value`

## Solução Implementada

Modificado o método `navigateToHome()` para usar uma abordagem mais robusta:

```dart
void navigateToHome() {
  EnhancedLogger.info('User chose to go to home', 
    tag: _tag,
    data: {'userId': _userId}
  );

  // Registrar analytics
  _trackUserAction('go_to_home');

  // Ir para home - fechar todas as telas até a home
  try {
    // Tentar usar a rota nomeada primeiro
    if (Get.currentRoute != '/home') {
      Get.until((route) => route.settings.name == '/home' || route.isFirst);
    }
  } catch (e) {
    // Se falhar, apenas voltar para a tela anterior
    EnhancedLogger.warning('Failed to navigate to home, going back instead', 
      tag: _tag,
      error: e,
    );
    Get.back();
  }
}
```

### Como Funciona

1. **Verifica se já está na home**: Se `Get.currentRoute` já é `/home`, não faz nada
2. **Tenta navegar até a home**: Usa `Get.until()` para fechar todas as telas até encontrar:
   - Uma rota com nome `/home`, OU
   - A primeira rota (rota raiz)
3. **Fallback seguro**: Se qualquer erro ocorrer, simplesmente volta para a tela anterior com `Get.back()`
4. **Logs detalhados**: Registra warnings se a navegação falhar

## Benefícios

- ✅ **Não quebra mais**: Tratamento de erro evita crashes
- ✅ **Flexível**: Funciona mesmo se a rota `/home` não estiver definida
- ✅ **Fallback inteligente**: Se não conseguir ir para home, volta para tela anterior
- ✅ **Logs úteis**: Registra quando a navegação falha para debug

## Teste

Para testar:
1. Complete um perfil
2. Veja a tela de confirmação aparecer
3. Clique no botão "Início"
4. Deve navegar para a home sem erros

## Arquivos Modificados

- `lib/controllers/vitrine_confirmation_controller.dart`
  - Método `navigateToHome()` modificado com tratamento de erro

---

**Status**: ✅ CORRIGIDO E PRONTO PARA TESTE
