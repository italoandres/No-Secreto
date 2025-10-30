# Sistema Unificado de Notificações 📱

Sistema completo de notificações organizado em 3 categorias horizontais: Stories, Interesse/Match e Sistema.

## 🎯 Características

### 3 Categorias Principais

1. **📖 Stories** - Notificações de interações com stories
   - ❤️ Curtidas
   - 💬 Comentários
   - @ Menções (destacadas)
   - ↩️ Respostas a comentários
   - 👍 Curtidas em comentários

2. **💕 Interesse/Match** - Demonstrações de interesse e matches
   - Notificações de interesse
   - Aceitações de interesse
   - Matches mútuos (destacados)
   - Botões de aceitar/rejeitar

3. **⚙️ Sistema** - Certificação e atualizações
   - 🎉 Certificação aprovada (verde)
   - ⚠️ Certificação reprovada (laranja)
   - 📢 Atualizações do sistema (azul)

## 🚀 Como Usar

### Navegação Básica

```dart
import 'package:whatsapp_chat/utils/unified_notifications_helper.dart';

// Abrir tela de notificações
UnifiedNotificationsHelper.openNotifications();
```

### Navegação Direta

```dart
import 'package:get/get.dart';
import 'package:whatsapp_chat/views/unified_notifications_view.dart';

// Abrir diretamente
Get.to(() => const UnifiedNotificationsView());
```

### Integração com Rotas

```dart
// No seu arquivo de rotas (main.dart ou routes.dart)
GetPage(
  name: '/notifications',
  page: () => const UnifiedNotificationsView(),
),

// Usar
Get.toNamed('/notifications');
```

## 📦 Componentes Criados

### Models
- `NotificationCategory` - Enum com 3 categorias
- `UnifiedNotificationModel` - Wrapper unificado

### Controllers
- `UnifiedNotificationController` - Controller GetX principal

### Widgets
- `NotificationCategoryTab` - Tab de categoria com badge
- `NotificationCategoryContent` - Conteúdo da categoria
- `NotificationItemFactory` - Factory para criar items
- `StoryNotificationItem` - Item de notificação de story
- `InterestNotificationItem` - Item de notificação de interesse
- `SystemNotificationItem` - Item de notificação de sistema

### Views
- `UnifiedNotificationsView` - View principal

## 🎨 Personalização

### Cores por Categoria

```dart
// Stories
Colors.amber.shade700

// Interesse
Colors.pink.shade400

// Sistema
Colors.blue.shade600
```

### Badges

Badges aparecem automaticamente quando há notificações não lidas:
- Contador individual por categoria
- Contador total no AppBar
- Animação ao aparecer/desaparecer
- "99+" quando > 99

## 🔧 Integração com Serviços Existentes

O sistema reutiliza todos os serviços existentes:

```dart
// Stories
NotificationRepository.getUserNotifications(userId)

// Interesse
InterestNotificationRepository.getUserInterestNotifications(userId)

// Sistema
CertificationNotificationService().getAllNotifications(userId)
```

## ✨ Recursos Especiais

### Pull-to-Refresh
Todas as categorias suportam pull-to-refresh para atualizar notificações.

### Estados Inteligentes
- **Vazio**: Mensagem personalizada por categoria
- **Loading**: Indicador de carregamento
- **Erro**: Mensagem de erro com botão "Tentar Novamente"

### Navegação
- **Swipe**: Deslize entre categorias
- **Tap**: Toque nas tabs para trocar
- **Animações**: Transições suaves

### Ações
- **Marcar como lida**: Botão no AppBar
- **Deletar**: Swipe ou botão X
- **Aceitar/Rejeitar**: Botões em interesses pendentes

## 📱 Exemplo de Uso Completo

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:whatsapp_chat/views/unified_notifications_view.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      home: HomeScreen(),
      getPages: [
        GetPage(
          name: '/notifications',
          page: () => const UnifiedNotificationsView(),
        ),
      ],
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () => Get.toNamed('/notifications'),
          ),
        ],
      ),
      body: Center(
        child: Text('Bem-vindo!'),
      ),
    );
  }
}
```

## 🔒 Compatibilidade

✅ **Firebase Firestore**: 4.13.6 (versão atual, sem atualização)
✅ **Firebase Auth**: 4.15.3
✅ **GetX**: Compatível com versão atual
✅ **Flutter**: Compatível com versão atual

## 🐛 Troubleshooting

### Notificações não aparecem
1. Verifique se o usuário está autenticado
2. Verifique as permissões do Firestore
3. Verifique os logs no console

### Badges não atualizam
1. Verifique se o GetX está configurado corretamente
2. Verifique se os streams estão ativos
3. Force um refresh com pull-to-refresh

### Erro ao navegar
1. Verifique se as rotas estão registradas
2. Verifique se o GetX está inicializado
3. Verifique os imports

## 📝 Próximos Passos (Opcional)

- [ ] Adicionar notificações push
- [ ] Implementar filtros e busca
- [ ] Adicionar paginação para listas grandes
- [ ] Implementar cache offline robusto
- [ ] Adicionar analytics

## 🎉 Pronto para Usar!

O sistema está **100% funcional** e pronto para ser usado no seu app!

Para começar, basta navegar para a tela:

```dart
Get.to(() => const UnifiedNotificationsView());
```

---

**Desenvolvido com ❤️ usando Flutter + GetX + Firebase**
