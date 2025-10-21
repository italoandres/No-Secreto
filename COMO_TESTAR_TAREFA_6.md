# 🧪 COMO TESTAR - Tarefa 6: Atualização de Perfil com Certificação

## 📋 Guia Completo de Testes

Este guia mostra como testar a funcionalidade de atualização automática do perfil quando uma certificação é aprovada.

---

## 🎯 O Que Vamos Testar

- ✅ Perfil do usuário é atualizado automaticamente
- ✅ Campo `spirituallyCertified` é adicionado
- ✅ Campo `certifiedAt` é adicionado com timestamp correto
- ✅ Badge aparece no perfil do usuário
- ✅ Logs são gerados corretamente

---

## 🚀 Teste 1: Aprovação via Email

### Passo 1: Criar Solicitação de Certificação

1. Abra o app Flutter
2. Faça login com um usuário de teste
3. Navegue para a tela de certificação espiritual
4. Preencha o formulário:
   - Email de compra
   - Upload do comprovante
5. Envie a solicitação
6. **Anote o userId do usuário**

### Passo 2: Verificar Email Recebido

1. Abra o email `sinais.aplicativo@gmail.com`
2. Procure por email com assunto: "🏆 Nova Solicitação de Certificação Espiritual"
3. Verifique que o email contém:
   - ✅ Informações do usuário
   - ✅ Botão "Aprovar Certificação" (verde)
   - ✅ Botão "Reprovar Certificação" (vermelho)

### Passo 3: Aprovar via Link do Email

1. Clique no botão **"Aprovar Certificação"**
2. Aguarde a página carregar
3. Verifique que aparece:
   - ✅ Página de sucesso
   - ✅ Mensagem: "Certificação Aprovada com Sucesso! ✅"
   - ✅ Lista de próximos passos

### Passo 4: Verificar Atualização no Firestore

1. Abra o **Firebase Console**
2. Vá para **Firestore Database**
3. Navegue para `usuarios/{userId}` (use o userId anotado)
4. Verifique que os campos foram adicionados:

```javascript
{
  uid: "abc123",
  displayName: "João Silva",
  email: "joao@example.com",
  // ... outros campos ...
  
  // ✅ NOVOS CAMPOS ADICIONADOS
  spirituallyCertified: true,
  certifiedAt: Timestamp(2025-01-15 10:30:00)
}
```

### Passo 5: Verificar Badge no App

1. Abra o app Flutter
2. Faça login com o usuário certificado
3. Vá para o perfil do usuário
4. Verifique que o badge aparece:
   - ✅ Badge dourado com ícone de verificação
   - ✅ Texto "Certificado ✓"
   - ✅ Efeito de sombra e gradiente

### Passo 6: Verificar Logs

1. Abra o **Firebase Console**
2. Vá para **Functions > Logs**
3. Procure pelos logs da função `sendCertificationApprovalEmail`
4. Verifique que os logs aparecem na ordem correta:

```
✅ Certificação aprovada, processando...
🔄 Atualizando perfil do usuário: abc123
✅ Perfil do usuário atualizado com selo de certificação
📧 Enviando email de aprovação...
✅ Email de aprovação enviado para: joao@example.com
```

---

## 🎮 Teste 2: Aprovação via Painel Admin (Futuro)

> **Nota:** Este teste será possível após implementar as Tarefas 9 e 10

### Passo 1: Abrir Painel Admin

1. Abra o app Flutter
2. Faça login com usuário admin
3. Navegue para o painel de certificações

### Passo 2: Aprovar Certificação

1. Veja a lista de certificações pendentes
2. Clique em "Aprovar" em uma solicitação
3. Confirme a aprovação

### Passo 3: Verificar Atualização

1. Verifique no Firestore que o perfil foi atualizado
2. Verifique no app que o badge aparece
3. Verifique os logs no Firebase Console

---

## 🔍 Teste 3: Verificar Tratamento de Erros

### Cenário 1: Usuário Não Existe

1. No Firebase Console, crie uma certificação com `userId` inválido
2. Aprove a certificação
3. Verifique os logs:

```
✅ Certificação aprovada, processando...
🔄 Atualizando perfil do usuário: invalid_user_id
❌ Erro ao atualizar perfil do usuário: [erro]
❌ Erro ao atualizar perfil, mas continuando com email: [erro]
📧 Enviando email de aprovação...
✅ Email de aprovação enviado para: user@example.com
```

4. Verifique que:
   - ✅ Erro foi registrado nos logs
   - ✅ Email foi enviado mesmo com erro
   - ✅ Sistema não travou

### Cenário 2: Permissões Insuficientes

1. Modifique as regras do Firestore temporariamente
2. Tente aprovar uma certificação
3. Verifique que o erro é tratado corretamente
4. Restaure as regras originais

---

## 📊 Teste 4: Verificar Consistência de Dados

### Passo 1: Criar Múltiplas Solicitações

1. Crie 3 solicitações de certificação com usuários diferentes
2. Anote os `userId` de cada um

### Passo 2: Aprovar Todas

1. Aprove todas as 3 certificações via email
2. Aguarde alguns segundos

### Passo 3: Verificar Consistência

1. No Firestore, verifique que TODOS os perfis foram atualizados:

```javascript
// usuarios/user1
{ spirituallyCertified: true, certifiedAt: Timestamp }

// usuarios/user2
{ spirituallyCertified: true, certifiedAt: Timestamp }

// usuarios/user3
{ spirituallyCertified: true, certifiedAt: Timestamp }
```

2. Verifique que os timestamps são diferentes (cada um tem seu próprio)

---

## 🎨 Teste 5: Verificar Badge em Diferentes Contextos

### Contexto 1: Perfil Próprio

1. Faça login com usuário certificado
2. Vá para "Meu Perfil"
3. Verifique que o badge aparece:
   - ✅ Badge grande (80x80)
   - ✅ Com label "Certificado ✓"
   - ✅ Efeito visual (sombra, gradiente)

### Contexto 2: Perfil de Outro Usuário

1. Faça login com usuário não certificado
2. Busque e visualize perfil de usuário certificado
3. Verifique que o badge aparece:
   - ✅ Badge grande (80x80)
   - ✅ Com label "Certificado ✓"
   - ✅ Sem botão de "Solicitar Certificação"

### Contexto 3: Cards da Vitrine

1. Navegue para a vitrine de perfis
2. Procure por usuários certificados
3. Verifique que o badge compacto aparece:
   - ✅ Badge pequeno (24x24)
   - ✅ Ícone de verificação
   - ✅ Cor dourada

### Contexto 4: Resultados de Busca

1. Use a busca para encontrar usuários
2. Verifique que usuários certificados têm:
   - ✅ Badge inline ao lado do nome
   - ✅ Ícone de verificação (20x20)
   - ✅ Cor dourada

---

## 🔄 Teste 6: Verificar Atualização em Tempo Real

### Passo 1: Preparar Dois Dispositivos

1. **Dispositivo 1:** Abra o app com usuário certificado
2. **Dispositivo 2:** Abra o Firebase Console

### Passo 2: Remover Certificação

1. No Firebase Console, remova os campos:
   - `spirituallyCertified`
   - `certifiedAt`
2. Salve as alterações

### Passo 3: Verificar no App

1. No Dispositivo 1, recarregue o perfil
2. Verifique que o badge **desapareceu**

### Passo 4: Aprovar Novamente

1. Crie nova solicitação de certificação
2. Aprove via email
3. No Dispositivo 1, recarregue o perfil
4. Verifique que o badge **reapareceu**

---

## 📝 Checklist de Testes

Use este checklist para garantir que tudo foi testado:

### Funcionalidade Básica
- [ ] Perfil é atualizado ao aprovar certificação
- [ ] Campo `spirituallyCertified` é adicionado
- [ ] Campo `certifiedAt` é adicionado
- [ ] Badge aparece no perfil
- [ ] Email de aprovação é enviado

### Tratamento de Erros
- [ ] Erro ao atualizar perfil não bloqueia email
- [ ] Logs de erro são gerados corretamente
- [ ] Sistema continua funcionando após erro

### Consistência de Dados
- [ ] Múltiplas aprovações funcionam corretamente
- [ ] Timestamps são únicos para cada aprovação
- [ ] Dados ficam sincronizados

### Interface do Usuário
- [ ] Badge aparece no perfil próprio
- [ ] Badge aparece no perfil de outros
- [ ] Badge aparece nos cards da vitrine
- [ ] Badge aparece nos resultados de busca

### Logs e Monitoramento
- [ ] Logs são gerados na ordem correta
- [ ] Logs contêm informações úteis
- [ ] Logs de erro são claros

---

## 🐛 Problemas Comuns e Soluções

### Problema 1: Badge Não Aparece

**Sintomas:**
- Certificação aprovada
- Perfil atualizado no Firestore
- Badge não aparece no app

**Solução:**
1. Verifique se o app está lendo o campo correto:
   ```dart
   userData.spirituallyCertified ?? false
   ```
2. Force um reload do perfil
3. Verifique os logs do app

### Problema 2: Perfil Não Atualiza

**Sintomas:**
- Certificação aprovada
- Email enviado
- Perfil não atualizado no Firestore

**Solução:**
1. Verifique os logs da Cloud Function
2. Procure por erros de permissão
3. Verifique as regras do Firestore
4. Confirme que o `userId` está correto

### Problema 3: Erro de Permissão

**Sintomas:**
- Logs mostram erro de permissão
- Perfil não é atualizado

**Solução:**
1. Verifique as regras do Firestore:
   ```javascript
   match /usuarios/{userId} {
     allow write: if request.auth != null;
   }
   ```
2. Confirme que a Cloud Function tem permissões de admin

---

## 📊 Resultados Esperados

Após todos os testes, você deve ter:

✅ **100% de aprovações funcionando**
- Perfil atualizado automaticamente
- Badge aparecendo corretamente
- Emails sendo enviados

✅ **0 erros críticos**
- Sistema robusto
- Tratamento de erros funcionando
- Logs claros e úteis

✅ **Experiência perfeita**
- Badge aparece imediatamente
- Usuário não precisa fazer nada
- Interface bonita e profissional

---

## 🎉 Conclusão

Se todos os testes passaram, a Tarefa 6 está funcionando perfeitamente! 🏆

**Próximos passos:**
1. ✅ Tarefa 7 - Badge de certificação (já implementado!)
2. ⏭️ Tarefa 8 - Integrar badge nas telas
3. ⏭️ Tarefa 9 - Serviço de aprovação
4. ⏭️ Tarefa 10 - Painel administrativo

---

**Bons testes! 🚀**
