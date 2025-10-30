# 🧪 Teste Rápido - Autenticação no APK

## 🚀 Passo a Passo

### 1. Compilar APK
```bash
flutter build apk --split-per-abi
```

### 2. Instalar no Celular
O APK estará em: `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk`

### 3. Testar Funcionalidade

#### Teste A: Ativar Proteção
```
1. Abra o app
2. Faça login (se necessário)
3. Vá em: Menu → Configurações → Segurança
4. Ative o switch "Proteção do Aplicativo"
5. Escolha "Apenas Senha" (ou "Biometria + Senha" se tiver)
6. Digite uma senha (ex: 1234)
7. Confirme a senha
8. Toque em "Salvar"
9. ✅ Deve mostrar: "Proteção ativada com sucesso!"
```

#### Teste B: Reabrir App
```
1. Feche o app completamente (swipe up e feche)
2. Reabra o app
3. ✅ Deve mostrar tela de bloqueio azul
4. Digite a senha
5. Toque em "Entrar"
6. ✅ Deve desbloquear e ir para HomeView
```

#### Teste C: Background/Foreground
```
1. Com app aberto
2. Pressione botão Home (minimize)
3. Aguarde 2-3 minutos
4. Volte ao app
5. ✅ Deve mostrar tela de bloqueio
6. Autentique novamente
```

#### Teste D: Desativar Proteção
```
1. Vá em: Menu → Configurações → Segurança
2. Desative o switch "Proteção do Aplicativo"
3. Confirme
4. Feche e reabra o app
5. ✅ Não deve pedir autenticação
```

## ✅ Checklist de Validação

- [ ] Consegui ativar a proteção
- [ ] Ao reabrir app, pediu autenticação
- [ ] Senha correta desbloqueou
- [ ] Senha incorreta mostrou erro
- [ ] Após timeout, pediu autenticação
- [ ] Desativar proteção funcionou
- [ ] Sem proteção, não pede autenticação

## 🐛 Se Algo Não Funcionar

### Problema: Não pede autenticação ao reabrir
**Solução:** Verifique se a proteção está realmente ativada em Configurações → Segurança

### Problema: Erro ao ativar proteção
**Solução:** Certifique-se de que as senhas coincidem e têm pelo menos 4 caracteres

### Problema: Biometria não funciona
**Solução:** 
1. Verifique se seu celular tem sensor biométrico
2. Configure biometria nas configurações do Android
3. Tente usar "Apenas Senha" como alternativa

### Problema: App trava na tela de bloqueio
**Solução:** 
1. Force close do app
2. Reabra
3. Se persistir, desinstale e reinstale

## 📱 Dispositivos Testados

Funciona em:
- ✅ Android 8.0+
- ✅ Dispositivos com/sem biometria
- ✅ Emuladores (sem biometria)

## 🎯 Resultado Esperado

Após todos os testes, você deve ter:
- ✅ Proteção ativando corretamente
- ✅ Autenticação pedida ao reabrir
- ✅ Autenticação pedida após timeout
- ✅ Senha funcionando
- ✅ Biometria funcionando (se disponível)

**Tudo funcionando = Implementação completa!** 🎉
