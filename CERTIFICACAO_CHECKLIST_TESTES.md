# ✅ Checklist de Testes - Sistema de Certificação Espiritual

## 📋 Visão Geral

Este documento contém todos os testes necessários para validar o Sistema de Certificação Espiritual.

---

## 🧪 Testes Funcionais

### 1. Solicitação de Certificação

#### ✅ Teste 1.1: Acessar Tela de Certificação
- [ ] Usuário consegue acessar pelo perfil
- [ ] Usuário consegue acessar pelo menu Vitrine
- [ ] Tela carrega corretamente
- [ ] Design âmbar/dourado está aplicado

#### ✅ Teste 1.2: Preencher Formulário
- [ ] Campo "Email da Compra" aceita email válido
- [ ] Campo "Email do App" vem preenchido automaticamente
- [ ] Validação de email funciona
- [ ] Mensagens de erro aparecem corretamente

#### ✅ Teste 1.3: Upload de Comprovante
- [ ] Botão de seleção de arquivo funciona
- [ ] Preview do arquivo aparece
- [ ] Aceita PDF
- [ ] Aceita JPG/JPEG
- [ ] Aceita PNG
- [ ] Rejeita arquivos > 5MB
- [ ] Rejeita formatos inválidos
- [ ] Barra de progresso funciona

#### ✅ Teste 1.4: Enviar Solicitação
- [ ] Botão "Enviar" só habilita quando válido
- [ ] Upload é realizado com sucesso
- [ ] Solicitação é salva no Firestore
- [ ] Mensagem de sucesso aparece
- [ ] Email é enviado para admin

#### ✅ Teste 1.5: Validações
- [ ] Não permite enviar sem email
- [ ] Não permite enviar sem arquivo
- [ ] Não permite múltiplas solicitações pendentes
- [ ] Mostra erro se upload falhar

---

### 2. Histórico de Solicitações

#### ✅ Teste 2.1: Visualizar Histórico
- [ ] Histórico aparece na tela
- [ ] Solicitações ordenadas por data (mais recente primeiro)
- [ ] Status correto para cada solicitação:
  - [ ] ⏱️ Pendente
  - [ ] ✅ Aprovada
  - [ ] ❌ Rejeitada
- [ ] Data formatada corretamente

#### ✅ Teste 2.2: Solicitação Pendente
- [ ] Formulário fica oculto se há pendente
- [ ] Mensagem informativa aparece
- [ ] Não permite nova solicitação

#### ✅ Teste 2.3: Solicitação Rejeitada
- [ ] Motivo da rejeição aparece (se houver)
- [ ] Botão "Reenviar" funciona
- [ ] Permite fazer nova solicitação

#### ✅ Teste 2.4: Solicitação Aprovada
- [ ] Mensagem de parabéns aparece
- [ ] Selo aparece no perfil
- [ ] Não permite nova solicitação

---

### 3. Painel Administrativo

#### ✅ Teste 3.1: Acessar Painel
- [ ] Admin consegue acessar painel
- [ ] Usuário comum NÃO consegue acessar
- [ ] Design âmbar/dourado está aplicado
- [ ] 3 abas aparecem (Pendentes, Aprovadas, Rejeitadas)

#### ✅ Teste 3.2: Visualizar Solicitações
- [ ] Aba "Pendentes" mostra solicitações pendentes
- [ ] Aba "Aprovadas" mostra aprovadas
- [ ] Aba "Rejeitadas" mostra rejeitadas
- [ ] Lista atualiza em tempo real (Stream)
- [ ] Cards mostram todas as informações

#### ✅ Teste 3.3: Ver Comprovante
- [ ] Botão "Ver Comprovante" funciona
- [ ] Imagens abrem com zoom
- [ ] PDFs abrem em app externo
- [ ] Botão de download funciona
- [ ] Botão de compartilhar funciona

#### ✅ Teste 3.4: Aprovar Certificação
- [ ] Botão "Aprovar" funciona
- [ ] Diálogo de confirmação aparece
- [ ] Status atualiza para "approved"
- [ ] Campo `isSpiritualCertified` atualiza no usuário
- [ ] Notificação é criada
- [ ] Email é enviado ao usuário
- [ ] Card move para aba "Aprovadas"

#### ✅ Teste 3.5: Rejeitar Certificação
- [ ] Botão "Rejeitar" funciona
- [ ] Diálogo com campo de motivo aparece
- [ ] Pode rejeitar sem motivo
- [ ] Pode rejeitar com motivo
- [ ] Status atualiza para "rejected"
- [ ] Notificação é criada
- [ ] Email é enviado com motivo
- [ ] Card move para aba "Rejeitadas"

---

### 4. Sistema de Notificações

#### ✅ Teste 4.1: Notificação de Aprovação
- [ ] Notificação é criada quando aprovado
- [ ] Título correto: "🎉 Certificação Aprovada!"
- [ ] Mensagem correta
- [ ] Aparece na lista de notificações
- [ ] Marca como não lida inicialmente
- [ ] Ao clicar, navega para perfil

#### ✅ Teste 4.2: Notificação de Rejeição
- [ ] Notificação é criada quando rejeitado
- [ ] Título correto: "❌ Certificação Rejeitada"
- [ ] Mensagem inclui motivo (se houver)
- [ ] Aparece na lista de notificações
- [ ] Ao clicar, navega para tela de certificação

#### ✅ Teste 4.3: Notificação para Admin
- [ ] Admin recebe notificação de nova solicitação
- [ ] Título correto: "📋 Nova Solicitação"
- [ ] Mensagem inclui nome e email do usuário
- [ ] Ao clicar, navega para painel admin

#### ✅ Teste 4.4: Interações
- [ ] Pode marcar como lida
- [ ] Pode deletar (swipe)
- [ ] Contador de não lidas funciona

---

### 5. Exibição do Selo

#### ✅ Teste 5.1: Próprio Perfil
- [ ] Selo dourado aparece quando certificado
- [ ] Texto "Certificado ✓" aparece
- [ ] Botão "Solicitar" aparece quando não certificado
- [ ] Animação/brilho do selo funciona

#### ✅ Teste 5.2: Perfil de Outros
- [ ] Selo aparece em perfis certificados
- [ ] Selo NÃO aparece em perfis não certificados
- [ ] Badge compacto funciona em listas

#### ✅ Teste 5.3: Outros Locais
- [ ] Selo aparece na Vitrine de Propósito
- [ ] Selo aparece em resultados de busca
- [ ] Selo aparece em cards de perfil
- [ ] Badge inline funciona ao lado do nome

---

### 6. Navegação

#### ✅ Teste 6.1: Navegação do Usuário
- [ ] Botão no perfil navega corretamente
- [ ] Menu Vitrine navega corretamente
- [ ] Notificação navega corretamente
- [ ] Voltar funciona em todas as telas

#### ✅ Teste 6.2: Navegação do Admin
- [ ] Menu admin navega para painel
- [ ] Notificação navega para painel
- [ ] Voltar funciona no painel

---

### 7. Emails

#### ✅ Teste 7.1: Email para Admin (Nova Solicitação)
- [ ] Email é enviado quando usuário solicita
- [ ] Destinatário: sinais.app@gmail.com
- [ ] Assunto correto
- [ ] Template HTML renderiza corretamente
- [ ] Contém nome e email do usuário
- [ ] Link para painel funciona
- [ ] Link para comprovante funciona

#### ✅ Teste 7.2: Email de Aprovação
- [ ] Email é enviado quando aprovado
- [ ] Destinatário correto (email do usuário)
- [ ] Assunto correto
- [ ] Template HTML renderiza
- [ ] Mensagem de parabéns
- [ ] Link para perfil funciona

#### ✅ Teste 7.3: Email de Rejeição
- [ ] Email é enviado quando rejeitado
- [ ] Destinatário correto
- [ ] Assunto correto
- [ ] Inclui motivo (se houver)
- [ ] Link para nova solicitação funciona

---

## 🔒 Testes de Segurança

### 8. Regras do Firestore

#### ✅ Teste 8.1: Leitura
- [ ] ✅ Usuário pode ler suas próprias solicitações
- [ ] ❌ Usuário NÃO pode ler solicitações de outros
- [ ] ✅ Admin pode ler todas as solicitações

#### ✅ Teste 8.2: Criação
- [ ] ✅ Usuário pode criar sua própria solicitação
- [ ] ❌ Usuário NÃO pode criar para outro usuário
- [ ] ❌ Usuário NÃO pode criar com status diferente de "pending"

#### ✅ Teste 8.3: Atualização
- [ ] ❌ Usuário NÃO pode atualizar status
- [ ] ✅ Admin pode atualizar status
- [ ] ❌ Admin NÃO pode mudar userId
- [ ] ❌ Admin NÃO pode mudar proofFileUrl

#### ✅ Teste 8.4: Deleção
- [ ] ❌ Usuário NÃO pode deletar
- [ ] ✅ Admin pode deletar

---

### 9. Regras do Storage

#### ✅ Teste 9.1: Upload
- [ ] ✅ Usuário pode fazer upload em sua pasta
- [ ] ❌ Usuário NÃO pode fazer upload em pasta de outro
- [ ] ✅ Aceita imagens (JPG, PNG)
- [ ] ✅ Aceita PDF
- [ ] ❌ Rejeita arquivos > 5MB
- [ ] ❌ Rejeita formatos inválidos

#### ✅ Teste 9.2: Leitura
- [ ] ✅ Usuário pode ler seus próprios arquivos
- [ ] ❌ Usuário NÃO pode ler arquivos de outros
- [ ] ✅ Admin pode ler todos os arquivos

#### ✅ Teste 9.3: Deleção
- [ ] ✅ Usuário pode deletar seus próprios arquivos
- [ ] ❌ Usuário NÃO pode deletar arquivos de outros
- [ ] ✅ Admin pode deletar qualquer arquivo

---

## 📱 Testes de UI/UX

### 10. Interface do Usuário

#### ✅ Teste 10.1: Design
- [ ] Cores âmbar/dourado aplicadas
- [ ] Ícones corretos
- [ ] Espaçamentos consistentes
- [ ] Fontes legíveis
- [ ] Contraste adequado

#### ✅ Teste 10.2: Responsividade
- [ ] Funciona em telas pequenas
- [ ] Funciona em telas grandes
- [ ] Funciona em tablets
- [ ] Orientação portrait
- [ ] Orientação landscape

#### ✅ Teste 10.3: Feedback Visual
- [ ] Loading indicators aparecem
- [ ] Mensagens de erro são claras
- [ ] Mensagens de sucesso são claras
- [ ] Animações são suaves
- [ ] Transições funcionam

---

## 🚀 Testes de Performance

### 11. Performance

#### ✅ Teste 11.1: Upload
- [ ] Upload de 1MB é rápido
- [ ] Upload de 5MB funciona
- [ ] Progresso é preciso
- [ ] Não trava a interface

#### ✅ Teste 11.2: Listagem
- [ ] Lista carrega rapidamente
- [ ] Stream atualiza em tempo real
- [ ] Scroll é suave
- [ ] Não há lag

#### ✅ Teste 11.3: Imagens
- [ ] Imagens carregam rapidamente
- [ ] Cache funciona
- [ ] Zoom é suave
- [ ] Não há memory leaks

---

## 🔄 Testes de Integração

### 12. Fluxo Completo

#### ✅ Teste 12.1: Fluxo de Sucesso
1. [ ] Usuário acessa tela de certificação
2. [ ] Preenche formulário
3. [ ] Faz upload do comprovante
4. [ ] Envia solicitação
5. [ ] Recebe confirmação
6. [ ] Admin recebe email
7. [ ] Admin acessa painel
8. [ ] Admin visualiza comprovante
9. [ ] Admin aprova
10. [ ] Usuário recebe notificação
11. [ ] Usuário recebe email
12. [ ] Selo aparece no perfil

#### ✅ Teste 12.2: Fluxo de Rejeição
1. [ ] Usuário envia solicitação
2. [ ] Admin rejeita com motivo
3. [ ] Usuário recebe notificação
4. [ ] Usuário vê motivo
5. [ ] Usuário reenvia
6. [ ] Admin aprova
7. [ ] Selo aparece

---

## 📊 Relatório de Testes

### Status Geral

- **Total de Testes**: 150+
- **Testes Passados**: ___
- **Testes Falhados**: ___
- **Cobertura**: ___%

### Problemas Encontrados

| ID | Descrição | Severidade | Status |
|----|-----------|------------|--------|
| 1  |           |            |        |
| 2  |           |            |        |

### Notas

- Testar em diferentes dispositivos
- Testar com diferentes tamanhos de arquivo
- Testar com conexão lenta
- Testar offline/online

---

**Data do Teste**: ___/___/______
**Testador**: ________________
**Versão**: 1.0.0
