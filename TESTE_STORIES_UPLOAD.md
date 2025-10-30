# Procedimentos de Teste - Stories Upload Fix

## Objetivo
Validar se as correções implementadas resolveram o problema de upload e exibição de stories.

## Pré-requisitos
- App rodando em modo debug
- Console do Flutter aberto para visualizar logs
- Acesso de administrador no app
- Imagens de teste disponíveis (PNG, JPG)

## Teste 1: Upload de Story para Contexto Principal

### Passos:
1. Abrir o app
2. Navegar para a tela de stories principal
3. Clicar no botão "+" (FloatingActionButton)
4. Selecionar uma imagem do dispositivo
5. No dropdown "Selecionar contexto", escolher "Chat Principal"
6. Preencher campos opcionais se desejar
7. Clicar em "Salvar"

### Resultados Esperados:
- ✅ Logs de debug aparecem no console mostrando cada etapa
- ✅ Dialog de progresso aparece com mensagens informativas
- ✅ Mensagem de sucesso "Story salvo com sucesso!" aparece
- ✅ Story aparece imediatamente na galeria de stories principal
- ✅ Story é salvo na coleção 'stories_files' no Firestore

### Logs Esperados:
```
STORIES_DEBUG [INFO] [StoriesController] getFile_start
STORIES_DEBUG [DEBUG] [StoriesController] file_picker_init
STORIES_DEBUG [DEBUG] [StoriesController] file_details
STORIES_DEBUG [INFO] [StoriesRepository] addImg_start
STORIES_DEBUG [DEBUG] [StoriesRepository] image_upload_start
STORIES_DEBUG [SUCCESS] [StoriesRepository] image_upload_complete
STORIES_DEBUG [SUCCESS] [StoriesRepository] firestore_save_complete
STORIES_DEBUG [SUCCESS] [StoriesRepository] addImg_complete
```

## Teste 2: Upload de Story para Contexto "Sinais de Meu Isaque"

### Passos:
1. Navegar para a view "Sinais de Meu Isaque"
2. Clicar no botão de admin (ícone de configurações)
3. Clicar em "Stories - Sinais de Meu Isaque"
4. Clicar no botão "+" (FloatingActionButton)
5. Selecionar uma imagem do dispositivo
6. No dropdown "Selecionar contexto", escolher "Sinais de Meu Isaque"
7. Clicar em "Salvar"

### Resultados Esperados:
- ✅ Story aparece na galeria "Stories - Sinais de Meu Isaque"
- ✅ Story é salvo na coleção 'stories_sinais_isaque' no Firestore
- ✅ Campo 'publicoAlvo' é definido como 'feminino'
- ✅ Campo 'contexto' é definido como 'sinais_isaque'

## Teste 3: Validação de Arquivos

### Teste 3.1: Arquivo Muito Grande
1. Tentar fazer upload de arquivo > 16MB (usuário não-admin)
2. **Esperado**: Mensagem de erro sobre tamanho máximo

### Teste 3.2: Formato Não Suportado
1. Tentar fazer upload de arquivo .txt ou .pdf
2. **Esperado**: Mensagem listando formatos aceitos

### Teste 3.3: Arquivo Corrompido
1. Tentar fazer upload de arquivo com extensão .jpg mas conteúdo inválido
2. **Esperado**: Mensagem de erro sobre arquivo corrompido

## Teste 4: Tratamento de Erros

### Teste 4.1: Erro de Conexão
1. Desconectar internet
2. Tentar fazer upload
3. **Esperado**: Mensagem de erro de conexão

### Teste 4.2: Erro do Firebase
1. Configurar Firebase com permissões inválidas (se possível)
2. Tentar fazer upload
3. **Esperado**: Mensagem de erro do servidor

## Teste 5: Atualização Automática da Galeria

### Passos:
1. Abrir galeria de stories
2. Em outra aba/janela, fazer upload de novo story
3. Voltar para a galeria

### Resultados Esperados:
- ✅ Novo story aparece automaticamente na galeria
- ✅ Contador de stories é atualizado
- ✅ Não é necessário recarregar a página

## Teste 6: Exclusão de Stories

### Passos:
1. Na galeria de stories, clicar em "Deletar" em um story
2. Confirmar exclusão

### Resultados Esperados:
- ✅ Dialog de confirmação aparece
- ✅ Story é removido da galeria imediatamente
- ✅ Mensagem de sucesso aparece
- ✅ Story é removido do Firestore

## Teste 7: Estados de Loading e Feedback

### Validações:
- ✅ Dialog de progresso aparece durante upload
- ✅ Mensagens de progresso são atualizadas ("Fazendo upload...", "Salvando...")
- ✅ Indicadores de loading aparecem ao carregar galeria
- ✅ Estados de erro são tratados adequadamente
- ✅ Estados vazios mostram mensagem apropriada

## Teste 8: Logs de Debug

### Verificar se os logs contêm:
- ✅ Timestamp de cada operação
- ✅ Detalhes do arquivo selecionado
- ✅ Progresso do upload
- ✅ IDs dos documentos criados
- ✅ Detalhes de erros quando ocorrem
- ✅ Stack traces em caso de exceções

## Checklist de Validação Final

### Funcionalidade Básica:
- [ ] Upload de imagem funciona
- [ ] Upload de vídeo funciona (se implementado)
- [ ] Stories aparecem na galeria correta
- [ ] Exclusão de stories funciona
- [ ] Contextos são respeitados (principal vs sinais_isaque)

### Tratamento de Erros:
- [ ] Arquivos grandes são rejeitados
- [ ] Formatos inválidos são rejeitados
- [ ] Erros de rede são tratados
- [ ] Erros do Firebase são tratados
- [ ] Mensagens de erro são user-friendly

### Performance e UX:
- [ ] Upload é rápido e responsivo
- [ ] Feedback visual é adequado
- [ ] Galeria atualiza automaticamente
- [ ] Estados de loading são informativos
- [ ] Não há travamentos ou crashes

### Logs e Debug:
- [ ] Logs são informativos e estruturados
- [ ] Erros são logados com detalhes
- [ ] Performance é monitorada
- [ ] Operações são rastreáveis

## Problemas Conhecidos e Soluções

### Problema: "Formato de arquivo não suportado"
**Causa**: Validação de extensão muito restritiva ou arquivo corrompido
**Solução**: Verificar logs para ver extensão detectada e validar arquivo

### Problema: Story não aparece na galeria
**Causa**: Contexto incorreto ou erro no Firestore
**Solução**: Verificar logs do Firestore e contexto selecionado

### Problema: Upload muito lento
**Causa**: Arquivo muito grande ou conexão lenta
**Solução**: Implementar compressão de imagem ou mostrar progresso

### Problema: Erro de permissão
**Causa**: Usuário não é admin ou configuração do Firebase
**Solução**: Verificar status de admin e regras do Firestore

## Comandos Úteis para Debug

### Ver logs do Flutter:
```bash
flutter logs
```

### Executar com logs detalhados:
```bash
flutter run -d chrome --web-port=8080 --verbose
```

### Limpar cache se necessário:
```bash
flutter clean
flutter pub get
```

## Critérios de Sucesso

O teste é considerado bem-sucedido quando:

1. **Upload funciona**: Stories são salvos corretamente no Firestore
2. **Exibição funciona**: Stories aparecem na galeria apropriada
3. **Contextos funcionam**: Stories do contexto correto são exibidos
4. **Erros são tratados**: Mensagens claras para diferentes tipos de erro
5. **Performance adequada**: Upload e exibição são rápidos
6. **Logs informativos**: Debug é possível através dos logs
7. **UX satisfatória**: Feedback visual adequado para o usuário

Se todos esses critérios forem atendidos, o problema original foi resolvido com sucesso.