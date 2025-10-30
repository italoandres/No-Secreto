# Design Document

## Overview

Este design implementa melhorias visuais nas páginas de login incorporando a identidade da marca (amarelo) no fundo, aplicando gradientes consistentes nos textos e adicionando uma mensagem inspiradora com gradiente azul/rosa.

## Architecture

### Componentes Afetados
- `LoginComEmailView`: Página principal de login/cadastro
- `LoginView`: Página inicial de login (se existir)

### Estrutura Visual
```
Container (Gradiente Amarelo/Branco)
├── SafeArea
    ├── Header (Logo + Mensagem Inspiradora)
    ├── Cards de Login/Cadastro (Branco)
    └── Links de Navegação (Gradiente Azul/Rosa)
```

## Components and Interfaces

### 1. Background Gradient (Amarelo)
```dart
decoration: BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFFF9C4), // Amarelo claro
      Color(0xFFFFF59D), // Amarelo médio
      Colors.white,      // Branco
    ],
    stops: [0.0, 0.3, 1.0],
  ),
)
```

### 2. Text Gradient (Azul/Rosa)
```dart
foreground: Paint()
  ..shader = LinearGradient(
    colors: [
      Color(0xFF38b6ff), // Azul
      Color(0xFFf76cec), // Rosa
    ],
  ).createShader(Rect.fromLTWH(0.0, 0.0, 200.0, 70.0))
```

### 3. Mensagem Inspiradora
- Texto: "Conecte-se com Deus Pai e encontre seu propósito"
- Posição: Abaixo do logo, antes dos cards
- Estilo: Gradiente azul/rosa, fonte Poppins, tamanho 18px

## Data Models

Não há alterações nos modelos de dados.

## Error Handling

- Manter tratamento de erros existente
- Garantir que gradientes não afetem a legibilidade dos textos
- Fallback para cores sólidas se gradientes falharem

## Testing Strategy

### Testes Visuais
1. Verificar gradiente de fundo em diferentes tamanhos de tela
2. Confirmar legibilidade dos textos com gradientes
3. Testar navegação entre páginas mantendo consistência visual
4. Validar posicionamento da mensagem inspiradora

### Testes de Responsividade
1. Testar em dispositivos móveis
2. Verificar em tablets
3. Confirmar funcionamento em web

### Testes de Acessibilidade
1. Verificar contraste dos textos
2. Confirmar legibilidade em diferentes condições de luz
3. Testar com leitores de tela