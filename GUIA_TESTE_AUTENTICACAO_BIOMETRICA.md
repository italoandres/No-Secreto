# Guia de Teste - Autenticação Biométrica

## ✅ STATUS: IMPLEMENTAÇÃO 100% COMPLETA

Todas as funcionalidades foram implementadas e integradas ao app!

---

## 🎯 Como Testar a Nova Funcionalidade

### Passo 1: Instalar Dependências

```bash
flutter pub get
```

**Nota:** As dependências já estão configuradas no pubspec.yaml:
- `local_auth: ^2.1.7`
- `flutter_secure_storage: ^9.0.0`
- `bcrypt: ^1.1.3`

### Passo 2: Acessar Configurações de Segurança

1. Abra o aplicativo
2. Vá para o menu de configurações (UsernameSettingsView)
3. Role até a seção "Segurança" (ícone vermelho 🔐)

### Passo 3: Ativar Proteção

#### Opção A: Com Biometria (se disponível)

1. Toque no switch "Proteção do Aplicativo"
2. Você verá um dialog com opções:
   - **"Biometria + Senha"** (recomendado) - Usa biometria com senha como fallback
   - **"Apenas Senha"** - Usa apenas senha numérica

3. Escolha "Biometria + Senha"
4. Digite uma senha (mínimo 4 caracteres)
5. Confirme a senha
6. Toque em "Salvar"

#### Opção B: Apenas Senha

1. Toque no switch "Proteção do Aplicativo"
2. Escolha "Apenas Senha"
3. Digite uma senha (mínimo 4 caracteres)
4. Confirme a senha
5. Toque em "Salvar"

### Passo 4: Testar Autenticação

1. **Feche o aplicativo completamente** (não apenas minimize)
2. Abra o aplicativo novamente
3. Você deverá ver a tela de bloqueio azul com:
   - Logo do app
   - Ícone de biometria (se configurado) ou senha
   - Botão para autenticar

#### Se configurou Biometria:
- Toque no botão "Autenticar"
- Use sua impressão digital/face
- Se falhar 3 vezes, será oferecida a opção de usar senha

#### Se configurou Apenas Senha:
- Digite sua senha
- Toque em "Entrar"

### Passo 5: Testar Timeout (Background/Foreground)

**Nota:** O timeout padrão é 2 minutos. Isso significa que se você colocar o app em background por menos de 2 minutos, não precisará autenticar novamente.

1. Com o app aberto, pressione o botão Home (minimize o app)
2. Aguarde mais de 2 minutos
3. Volte para o app
4. Você deverá ver a tela de autenticação novamente

### Passo 6: Alterar Senha

1. Vá para Configurações > Segurança
2. Toque em "Alterar Senha"
3. Digite a nova senha
4. Confirme a nova senha
5. Toque em "Alterar"

### Passo 7: Desativar Proteção

1. Vá para Configurações > Segurança
2. Toque no switch "Proteção do Aplicativo" para desligar
3. Confirme a desativação
4. O app não pedirá mais autenticação

## 📱 Tipos de Biometria Suportados

### Android
- ✅ Impressão Digital
- ✅ Reconhecimento Facial
- ✅ Reconhecimento de Íris
- ✅ Biometria Forte/Fraca

### iOS
- ✅ Touch ID (Impressão Digital)
- ✅ Face ID (Reconhecimento Facial)

## 🎨 Visual Esperado

### Tela de Configurações
```
┌─────────────────────────────┐
│ 🔐 Segurança                │
├─────────────────────────────┤
│                             │
│ Proteção do Aplicativo [ON] │
│ Protegido com biometria     │
│ e senha como fallback       │
│                             │
├─────────────────────────────┤
│                             │
│ 👆 Disponível: impressão    │
│    digital                  │
│                             │
├─────────────────────────────┤
│                             │
│ [Alterar Senha]             │
│                             │
└─────────────────────────────┘
```

### Tela de Bloqueio (Biometria)
```
┌─────────────────────────────┐
│                             │
│      [Logo do App]          │
│                             │
│   🔒 App Protegido          │
│                             │
│      [👆 Ícone]             │
│                             │
│  Toque para autenticar      │
│  com impressão digital      │
│                             │
│   [Botão Autenticar]        │
│                             │
│   [Usar Senha]              │
│                             │
└─────────────────────────────┘
```

### Tela de Bloqueio (Senha)
```
┌─────────────────────────────┐
│                             │
│      [Logo do App]          │
│                             │
│   🔒 App Protegido          │
│                             │
│      [🔐 Ícone]             │
│                             │
│   Digite sua senha          │
│                             │
│   [Campo de Senha]          │
│                             │
│   [Botão Entrar]            │
│                             │
│   [Usar Biometria]          │
│                             │
└─────────────────────────────┘
```

## ✅ Checklist de Testes

### Funcionalidades Básicas
- [ ] Ativar proteção com biometria
- [ ] Ativar proteção apenas com senha
- [ ] Autenticar com biometria com sucesso
- [ ] Autenticar com senha com sucesso
- [ ] Desativar proteção

### Fallback e Erros
- [ ] Falhar biometria 3 vezes → deve oferecer senha
- [ ] Digitar senha incorreta → deve mostrar erro
- [ ] Alternar entre biometria e senha na tela de bloqueio

### Lifecycle
- [ ] App em background < 2 min → não pede autenticação
- [ ] App em background > 2 min → pede autenticação
- [ ] Fechar e reabrir app → pede autenticação

### Configurações
- [ ] Alterar senha com sucesso
- [ ] Desativar e reativar proteção
- [ ] Status visual correto (protegido/sem proteção)

### Dispositivos Sem Biometria
- [ ] Mostrar apenas opção "Apenas Senha"
- [ ] Não mostrar informações de biometria
- [ ] Funcionar normalmente com senha

## 🐛 Problemas Conhecidos

Nenhum no momento.

## 📝 Notas Importantes

1. **Primeira Vez:** Na primeira vez que ativar a proteção, você DEVE configurar uma senha, mesmo se escolher biometria. A senha serve como fallback.

2. **Timeout:** O timeout padrão é 2 minutos. Isso pode ser configurado no futuro (1, 5, 10 minutos ou imediato).

3. **Segurança:** As senhas são armazenadas com hash bcrypt e nunca em texto plano. A biometria é processada localmente no dispositivo.

4. **Logout:** Ao fazer logout do app, as configurações de proteção são mantidas, mas a sessão é invalidada.

5. **Reinstalação:** Se desinstalar e reinstalar o app, precisará configurar a proteção novamente.

## 🆘 Troubleshooting

### "Biometria não disponível"
- Verifique se seu dispositivo tem sensor biométrico
- Verifique se configurou biometria nas configurações do sistema
- Use a opção "Apenas Senha" como alternativa

### "Erro ao configurar senha"
- Certifique-se de que a senha tem pelo menos 4 caracteres
- Verifique se as senhas coincidem
- Tente novamente

### "App não pede autenticação"
- Verifique se a proteção está ativada (switch ON)
- Feche o app completamente (não apenas minimize)
- Aguarde mais de 2 minutos se testando timeout

### "Esqueci minha senha"
- Por enquanto, será necessário desinstalar e reinstalar o app
- Em versão futura, haverá opção de recuperação via Firebase

## 📞 Suporte

Se encontrar problemas, verifique:
1. Logs do console para mensagens de erro
2. Permissões de biometria no AndroidManifest.xml / Info.plist
3. Versão do Flutter e dependências atualizadas
