# 🧪 Guia de Testes: Filtro de Distância

## 📋 Checklist de Testes

### ✅ Testes Funcionais

#### 1. Carregamento Inicial
- [ ] Abrir tela Explore Profiles
- [ ] Verificar se filtros são carregados automaticamente
- [ ] Confirmar valores padrão (50 km, toggle OFF) se for primeira vez
- [ ] Confirmar valores salvos se já existirem

#### 2. Slider de Distância
- [ ] Mover slider para a esquerda (mínimo 5 km)
- [ ] Mover slider para a direita (máximo 400 km)
- [ ] Verificar se valor atualiza em tempo real
- [ ] Confirmar incrementos de 5 km
- [ ] Testar valores intermediários (25, 50, 100, 200 km)
- [ ] Verificar formatação "400+ km" no máximo

#### 3. Toggle de Preferência
- [ ] Clicar no switch para ativar
- [ ] Verificar se mensagem explicativa aparece (animação suave)
- [ ] Clicar novamente para desativar
- [ ] Verificar se mensagem desaparece
- [ ] Confirmar mudança de cor do ícone (cinza → vermelho)
- [ ] Verificar mudança de cor da borda (cinza → azul)

#### 4. Botão Salvar
- [ ] Verificar estado inicial (cinza, "Filtros Salvos")
- [ ] Fazer alteração no slider
- [ ] Confirmar que botão fica roxo e habilitado
- [ ] Texto muda para "Salvar Filtros"
- [ ] Clicar em "Salvar"
- [ ] Verificar snackbar verde de sucesso
- [ ] Confirmar que botão volta para cinza

#### 5. Persistência
- [ ] Fazer alterações e salvar
- [ ] Fechar o app completamente
- [ ] Reabrir o app
- [ ] Navegar para Explore Profiles
- [ ] Verificar se valores salvos foram carregados

#### 6. Dialog de Confirmação
- [ ] Fazer alterações sem salvar
- [ ] Clicar no botão voltar (back)
- [ ] Verificar se dialog aparece
- [ ] Testar botão "Descartar"
  - [ ] Confirmar que volta sem salvar
  - [ ] Verificar que alterações foram descartadas
- [ ] Fazer alterações novamente
- [ ] Clicar voltar
- [ ] Testar botão "Salvar"
  - [ ] Confirmar que salva e volta
  - [ ] Verificar snackbar de sucesso
- [ ] Fazer alterações novamente
- [ ] Clicar voltar
- [ ] Fechar dialog (X ou fora)
  - [ ] Confirmar que permanece na tela

---

### ✅ Testes de UI/UX

#### 1. Visual
- [ ] Verificar alinhamento dos cards
- [ ] Confirmar espaçamento consistente (16px entre cards)
- [ ] Verificar bordas arredondadas (16px)
- [ ] Confirmar sombras suaves
- [ ] Verificar cores corretas:
  - [ ] Roxo (#7B68EE) no card de distância
  - [ ] Azul (#4169E1) no toggle ativado
  - [ ] Cinza no toggle desativado
  - [ ] Verde no snackbar de sucesso

#### 2. Animações
- [ ] Verificar animação suave do toggle (300ms)
- [ ] Confirmar transição do botão salvar
- [ ] Testar animação do dialog (fade + scale)
- [ ] Verificar feedback visual do slider

#### 3. Responsividade
- [ ] Testar em mobile (< 600px)
- [ ] Testar em tablet (600-900px)
- [ ] Testar em desktop (> 900px)
- [ ] Verificar se cards se adaptam
- [ ] Confirmar que textos são legíveis

#### 4. Acessibilidade
- [ ] Verificar contraste de cores
- [ ] Testar tamanho de toque (mínimo 48x48px)
- [ ] Confirmar labels descritivos
- [ ] Verificar navegação por teclado (web)
- [ ] Testar com leitor de tela

---

### ✅ Testes de Erro

#### 1. Sem Autenticação
- [ ] Fazer logout
- [ ] Tentar salvar filtros
- [ ] Verificar mensagem de erro apropriada

#### 2. Erro de Conexão
- [ ] Desabilitar internet
- [ ] Tentar salvar filtros
- [ ] Verificar mensagem de erro
- [ ] Reabilitar internet
- [ ] Tentar novamente
- [ ] Confirmar sucesso

#### 3. Perfil Não Encontrado
- [ ] Simular perfil inexistente
- [ ] Verificar tratamento de erro
- [ ] Confirmar que app não quebra

#### 4. Valores Inválidos
- [ ] Tentar valores fora do range (< 5 ou > 400)
- [ ] Verificar se são corrigidos automaticamente
- [ ] Confirmar que não quebra o app

---

### ✅ Testes de Performance

#### 1. Carregamento
- [ ] Medir tempo de carregamento inicial
- [ ] Verificar se é < 1 segundo
- [ ] Confirmar que não trava a UI

#### 2. Interação
- [ ] Mover slider rapidamente
- [ ] Verificar se não há lag
- [ ] Confirmar atualização suave

#### 3. Salvamento
- [ ] Medir tempo de salvamento
- [ ] Verificar se é < 2 segundos
- [ ] Confirmar feedback imediato

---

### ✅ Testes de Integração

#### 1. Com Sistema de Localização
- [ ] Verificar se localização principal é exibida
- [ ] Confirmar que localizações adicionais aparecem
- [ ] Testar fluxo completo: localização + distância

#### 2. Com Explore Profiles
- [ ] Verificar se filtros afetam busca (futuro)
- [ ] Confirmar que não quebra funcionalidades existentes
- [ ] Testar navegação entre tabs

#### 3. Com Perfil do Usuário
- [ ] Verificar se dados são salvos no perfil correto
- [ ] Confirmar sincronização com Firestore
- [ ] Testar com múltiplos usuários

---

## 🎯 Cenários de Teste

### Cenário 1: Primeiro Uso
```
1. Usuário novo abre Explore Profiles
2. Vê valores padrão (50 km, toggle OFF)
3. Ajusta para 100 km
4. Ativa toggle
5. Clica em "Salvar"
6. Vê snackbar de sucesso
7. Fecha app
8. Reabre app
9. Valores estão salvos (100 km, toggle ON)
```

**Resultado Esperado**: ✅ Valores persistidos corretamente

---

### Cenário 2: Alteração e Descarte
```
1. Usuário com filtros salvos (50 km, OFF)
2. Ajusta para 200 km
3. Ativa toggle
4. Clica em voltar
5. Dialog aparece
6. Clica em "Descartar"
7. Volta para tela anterior
8. Reabre Explore Profiles
9. Valores originais estão mantidos (50 km, OFF)
```

**Resultado Esperado**: ✅ Alterações descartadas corretamente

---

### Cenário 3: Alteração e Salvamento via Dialog
```
1. Usuário com filtros salvos (50 km, OFF)
2. Ajusta para 150 km
3. Ativa toggle
4. Clica em voltar
5. Dialog aparece
6. Clica em "Salvar"
7. Vê snackbar de sucesso
8. Volta para tela anterior
9. Reabre Explore Profiles
10. Novos valores estão salvos (150 km, ON)
```

**Resultado Esperado**: ✅ Alterações salvas via dialog

---

### Cenário 4: Múltiplas Alterações
```
1. Usuário ajusta slider para 75 km
2. Ativa toggle
3. Salva
4. Ajusta para 125 km
5. Desativa toggle
6. Salva
7. Ajusta para 200 km
8. Ativa toggle
9. Salva
10. Verifica histórico no Firestore
```

**Resultado Esperado**: ✅ Todas as alterações registradas com timestamp

---

### Cenário 5: Erro de Conexão
```
1. Usuário ajusta filtros
2. Desabilita internet
3. Clica em "Salvar"
4. Vê mensagem de erro
5. Reabilita internet
6. Clica em "Salvar" novamente
7. Vê snackbar de sucesso
```

**Resultado Esperado**: ✅ Erro tratado graciosamente

---

## 📊 Métricas de Sucesso

### Performance
- ⏱️ Carregamento inicial: < 1s
- ⏱️ Salvamento: < 2s
- ⏱️ Atualização de UI: < 100ms

### Usabilidade
- 👍 Taxa de conclusão: > 95%
- 👍 Erros do usuário: < 5%
- 👍 Satisfação: > 4.5/5

### Confiabilidade
- 🔒 Taxa de sucesso de salvamento: > 99%
- 🔒 Persistência de dados: 100%
- 🔒 Recuperação de erros: 100%

---

## 🐛 Bugs Conhecidos

### Nenhum bug conhecido no momento! 🎉

Se encontrar algum bug durante os testes, documente aqui:

```
Bug #1:
- Descrição:
- Passos para reproduzir:
- Resultado esperado:
- Resultado atual:
- Severidade: (Crítico/Alto/Médio/Baixo)
- Screenshots:
```

---

## ✅ Checklist de Aprovação

Antes de considerar a feature pronta para produção:

### Funcionalidade
- [ ] Todos os testes funcionais passaram
- [ ] Persistência funcionando 100%
- [ ] Dialog de confirmação funcionando
- [ ] Snackbars aparecendo corretamente

### UI/UX
- [ ] Design aprovado
- [ ] Animações suaves
- [ ] Responsivo em todos os tamanhos
- [ ] Acessível

### Performance
- [ ] Carregamento rápido
- [ ] Sem lag na interação
- [ ] Salvamento eficiente

### Qualidade
- [ ] Zero erros de compilação
- [ ] Código limpo e documentado
- [ ] Logs implementados
- [ ] Tratamento de erros robusto

### Integração
- [ ] Não quebra funcionalidades existentes
- [ ] Integrado com sistema de localização
- [ ] Compatível com Firestore

---

## 🎓 Dicas para Testers

### 1. Teste em Dispositivos Reais
- Não confie apenas em emuladores
- Teste em diferentes tamanhos de tela
- Verifique performance em dispositivos antigos

### 2. Teste Casos Extremos
- Valores mínimos e máximos
- Conexão lenta
- Múltiplas alterações rápidas
- Interrupções (chamadas, notificações)

### 3. Teste Fluxos Completos
- Do início ao fim
- Com diferentes estados iniciais
- Com diferentes perfis de usuário

### 4. Documente Tudo
- Screenshots de bugs
- Logs de erro
- Passos para reproduzir
- Ambiente de teste

---

## 📝 Relatório de Teste

### Template

```markdown
# Relatório de Teste - Filtro de Distância

**Data**: [data]
**Testador**: [nome]
**Ambiente**: [Web/iOS/Android]
**Versão**: 1.0.0

## Resumo
- Testes executados: X
- Testes passados: Y
- Testes falhados: Z
- Taxa de sucesso: Y/X %

## Detalhes

### Testes Funcionais
- [✅/❌] Carregamento inicial
- [✅/❌] Slider de distância
- [✅/❌] Toggle de preferência
- [✅/❌] Botão salvar
- [✅/❌] Persistência
- [✅/❌] Dialog de confirmação

### Testes de UI/UX
- [✅/❌] Visual
- [✅/❌] Animações
- [✅/❌] Responsividade
- [✅/❌] Acessibilidade

### Testes de Erro
- [✅/❌] Sem autenticação
- [✅/❌] Erro de conexão
- [✅/❌] Perfil não encontrado
- [✅/❌] Valores inválidos

### Bugs Encontrados
1. [Descrição do bug 1]
2. [Descrição do bug 2]

### Recomendações
- [Recomendação 1]
- [Recomendação 2]

### Conclusão
[Aprovado/Reprovado/Aprovado com ressalvas]
```

---

## 🚀 Próximos Passos Após Testes

1. **Se todos os testes passarem**:
   - ✅ Marcar feature como pronta
   - ✅ Fazer merge para branch principal
   - ✅ Preparar para deploy
   - ✅ Atualizar documentação

2. **Se houver bugs críticos**:
   - 🐛 Documentar bugs
   - 🐛 Priorizar correções
   - 🐛 Corrigir e testar novamente
   - 🐛 Repetir ciclo de testes

3. **Se houver bugs menores**:
   - 📝 Criar issues no backlog
   - 📝 Planejar correções futuras
   - 📝 Considerar deploy com ressalvas

---

**Status Atual**: ✅ Pronto para Testes
**Próximo Passo**: Executar testes manuais
**Responsável**: [Nome do tester]

---

**Boa sorte com os testes! 🎉**
