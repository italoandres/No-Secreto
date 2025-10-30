# Notificações Admin com Filtro de Idioma 🌍

## Mudanças Implementadas

### 1. ✅ Filtro de Idioma Adicionado

O popup de notificações do admin agora tem um novo filtro de idioma que permite enviar notificações para usuários específicos baseado no idioma configurado no app.

**Idiomas Suportados:**
- 🇧🇷 **Português** (pt)
- 🇺🇸 **English** (en)
- 🇪🇸 **Español** (es)

### 2. ✅ Categoria "Sistema" Renomeada para "Outros"

A terceira categoria de notificações foi renomeada de "Sistema" para "Outros" para ser mais abrangente e incluir:
- Certificação espiritual
- Avisos importantes do admin
- Atualizações do app
- Notificações gerais

## Como Usar o Filtro de Idioma

### Acessar o Popup

1. Abra o menu admin (ícone de engrenagem na HomeView)
2. Clique em "Notificações"
3. Popup abre com os campos

### Campos do Popup

```
┌─────────────────────────────────────┐
│ Título: [Digite o título]          │
│ Mensagem: [Digite a mensagem]      │
│                                     │
│ Filtrar por idioma?                 │
│ ○ Não  ○ Sim                       │
│                                     │
│ [Se Sim selecionado]                │
│ Selecione os idiomas:               │
│ ☑ 🇧🇷 Português                     │
│ ☐ 🇺🇸 English                       │
│ ☐ 🇪🇸 Español                       │
│                                     │
│ Tem distinção de sexo?              │
│ ○ Não  ○ Sim                       │
│                                     │
│ [Tabela de substituição se Sim]    │
│                                     │
│ [Botão Enviar]                      │
└─────────────────────────────────────┘
```

### Cenários de Uso

#### 1. Notificação Geral (Sem Filtros)
```
Filtrar por idioma? → Não
Tem distinção de sexo? → Não

Resultado: Envia para TODOS os usuários
Tópico: all
```

#### 2. Notificação por Idioma
```
Filtrar por idioma? → Sim
Idiomas: 🇧🇷 Português, 🇺🇸 English
Tem distinção de sexo? → Não

Resultado: Envia para usuários PT e EN
Tópicos: idioma_pt, idioma_en
```

#### 3. Notificação por Sexo
```
Filtrar por idioma? → Não
Tem distinção de sexo? → Sim
Masculino: "Bem-vindo"
Feminino: "Bem-vinda"

Resultado: Envia versões diferentes por sexo
Tópicos: sexo_m, sexo_f
```

#### 4. Notificação por Idioma E Sexo
```
Filtrar por idioma? → Sim
Idiomas: 🇧🇷 Português
Tem distinção de sexo? → Sim
Masculino: "Bem-vindo"
Feminino: "Bem-vinda"

Resultado: Envia versões diferentes por sexo E idioma
Tópicos: sexo_m_pt, sexo_f_pt
```

## Estrutura de Tópicos FCM

### Tópicos Simples
- `all` - Todos os usuários (padrão)
- `sexo_m` - Apenas homens
- `sexo_f` - Apenas mulheres

### Tópicos de Idioma
- `idioma_pt` - Usuários em português
- `idioma_en` - Usuários em inglês
- `idioma_es` - Usuários em espanhol

### Tópicos Combinados (Sexo + Idioma)
- `sexo_m_pt` - Homens em português
- `sexo_f_pt` - Mulheres em português
- `sexo_m_en` - Homens em inglês
- `sexo_f_en` - Mulheres em inglês
- `sexo_m_es` - Homens em espanhol
- `sexo_f_es` - Mulheres em espanhol

## Onde Aparecem as Notificações

### Categoria "Outros" (antiga "Sistema")

As notificações enviadas pelo admin aparecem na categoria **"Outros"** da NotificationsView:

```
┌─────────────────────────────────────┐
│ Notificações                        │
├─────────────────────────────────────┤
│ [Stories] [Interesse] [Outros]      │
│                          ↑           │
│                    Aqui aparecem!   │
└─────────────────────────────────────┘
```

**Tipos de notificações em "Outros":**
1. ⚙️ Certificação espiritual (aprovada/reprovada)
2. 📢 Avisos importantes do admin
3. 🔔 Atualizações do app
4. 💬 Notificações gerais

## Código Implementado

### Popup com Filtro de Idioma

```dart
// Variáveis observáveis
final temDistincaoDeIdioma = false.obs;
final idiomasSelecionados = <String>[].obs; // pt, en, es

// UI de seleção
FilterChip(
  label: const Text('🇧🇷 Português'),
  selected: idiomasSelecionados.contains('pt'),
  onSelected: (selected) {
    if (selected) {
      idiomasSelecionados.add('pt');
    } else {
      idiomasSelecionados.remove('pt');
    }
  },
),
```

### Lógica de Envio

```dart
if(temDistincaoDeIdioma.value == true) {
  // Com filtro de idioma
  for (var idioma in idiomasSelecionados) {
    if(temDistincaoDeSexo.value == true) {
      // Com filtro de sexo E idioma
      await NotificationController.sendNotificationToTopic(
        titulo: titulo, 
        msg: msg, 
        abrirStories: false, 
        topico: 'sexo_m_${idioma}'
      );
      await NotificationController.sendNotificationToTopic(
        titulo: tituloF, 
        msg: msgF, 
        abrirStories: false, 
        topico: 'sexo_f_${idioma}'
      );
    } else {
      // Apenas filtro de idioma
      await NotificationController.sendNotificationToTopic(
        titulo: titulo, 
        msg: msg, 
        abrirStories: false, 
        topico: 'idioma_${idioma}'
      );
    }
  }
}
```

## Configuração Necessária no App

### 1. Inscrição nos Tópicos FCM

Os usuários precisam se inscrever nos tópicos baseado em suas configurações:

```dart
// No login ou ao mudar idioma
final idioma = AppLanguage.getCurrentLanguage(); // pt, en, es
final sexo = user.sexo; // masculino, feminino

// Inscrever em tópico de idioma
await FirebaseMessaging.instance.subscribeToTopic('idioma_$idioma');

// Inscrever em tópico de sexo
if (sexo == UserSexo.masculino) {
  await FirebaseMessaging.instance.subscribeToTopic('sexo_m');
  await FirebaseMessaging.instance.subscribeToTopic('sexo_m_$idioma');
} else {
  await FirebaseMessaging.instance.subscribeToTopic('sexo_f');
  await FirebaseMessaging.instance.subscribeToTopic('sexo_f_$idioma');
}
```

### 2. Salvar Notificação no Firestore

As notificações do admin devem ser salvas no Firestore para aparecer na categoria "Outros":

```dart
// No NotificationController.sendNotificationToTopic()
// Após enviar via FCM, salvar no Firestore:

await FirebaseFirestore.instance.collection('notifications').add({
  'type': 'admin_announcement', // Novo tipo
  'title': titulo,
  'message': msg,
  'createdAt': FieldValue.serverTimestamp(),
  'read': false,
  'userId': userId, // Para cada usuário do tópico
  'topico': topico,
});
```

## Fluxo Completo

```
Admin abre popup
    ↓
Preenche título e mensagem
    ↓
Seleciona filtros (idioma e/ou sexo)
    ↓
Clica em "Enviar"
    ↓
Sistema envia via FCM para tópicos específicos
    ↓
Sistema salva no Firestore (collection: notifications)
    ↓
UnifiedNotificationController detecta nova notificação
    ↓
Notificação aparece na categoria "Outros"
    ↓
Badge vermelho aumenta (+1)
    ↓
Usuário clica na notificação
    ↓
Notificação é marcada como lida
    ↓
Badge vermelho diminui (-1)
```

## Exemplo de Uso Real

### Cenário: Anunciar nova funcionalidade

**Admin quer anunciar:**
- Apenas para usuários brasileiros
- Com texto diferente para homens e mulheres

**Configuração:**
```
Título: Nova Funcionalidade!
Mensagem: Olá [usuário/usuária], temos novidades!

Filtrar por idioma? → Sim
Idiomas: 🇧🇷 Português

Tem distinção de sexo? → Sim
Masculino: usuário
Feminino: usuária
```

**Resultado:**
- Homens brasileiros recebem: "Olá usuário, temos novidades!"
- Mulheres brasileiras recebem: "Olá usuária, temos novidades!"
- Usuários de outros idiomas NÃO recebem

## Benefícios

✅ **Segmentação precisa** - Envie mensagens relevantes para públicos específicos
✅ **Economia de notificações** - Não spam usuários com mensagens irrelevantes
✅ **Personalização** - Adapte mensagens por idioma e gênero
✅ **Melhor experiência** - Usuários recebem apenas o que é relevante para eles
✅ **Organização** - Todas as notificações admin em uma categoria dedicada

## Próximos Passos

1. ✅ Implementar inscrição automática nos tópicos FCM
2. ✅ Salvar notificações admin no Firestore
3. ✅ Criar tipo `admin_announcement` no sistema
4. ✅ Testar envio para diferentes combinações de filtros
5. ✅ Documentar para outros admins
