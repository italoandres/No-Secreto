# Design Document

## Overview

Esta implementação reorganiza a interface do usuário movendo o menu de configurações da capa do chat para a página da comunidade, criando uma experiência mais limpa e organizada.

## Architecture

### Componentes Afetados

1. **ChatView** - Remoção do ícone de 3 pontos da capa
2. **CommunityInfoView** - Adição do ícone de engrenagem e botão sair
3. **Menu de Configurações** - Manter funcionalidade existente

## Components and Interfaces

### 1. ChatView Modifications

```dart
// Remover o ícone de 3 pontos da área superior da capa
// Manter a estrutura para futura implementação de notificações

Widget _buildTopIcons() {
  return Row(
    children: [
      // Ícone da câmera (manter)
      _buildCameraIcon(),
      
      // Espaço reservado para futuro ícone de notificações
      // (não implementar agora)
      
      // Remover: ícone de 3 pontos
    ],
  );
}
```

### 2. CommunityInfoView Enhancements

```dart
// Adicionar ícone de engrenagem no topo
// Adicionar botão sair na parte inferior

Widget build(BuildContext context) {
  return Scaffold(
    body: Column(
      children: [
        _buildTopSection(), // Com ícone de engrenagem
        _buildCommunityContent(), // Conteúdo existente
        _buildBottomSection(), // Com botão sair
      ],
    ),
  );
}

Widget _buildTopSection() {
  return Container(
    padding: EdgeInsets.all(16),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(''), // Espaço vazio
        IconButton(
          icon: Icon(Icons.settings),
          onPressed: _showSettingsMenu,
        ),
      ],
    ),
  );
}

Widget _buildBottomSection() {
  return Container(
    padding: EdgeInsets.all(16),
    child: ElevatedButton(
      onPressed: _logout,
      child: Text('Sair'),
    ),
  );
}
```

## Data Models

Não há alterações necessárias nos modelos de dados existentes.

## Error Handling

- Tratar erros de logout graciosamente
- Manter funcionalidade existente do menu de configurações
- Validar navegação entre telas

## Testing Strategy

### Unit Tests
- Testar remoção do ícone de 3 pontos
- Testar adição do ícone de engrenagem
- Testar funcionalidade do botão sair

### Integration Tests
- Testar fluxo completo de logout
- Testar navegação entre telas
- Testar menu de configurações na nova localização

### UI Tests
- Verificar posicionamento correto dos elementos
- Testar responsividade
- Validar design visual