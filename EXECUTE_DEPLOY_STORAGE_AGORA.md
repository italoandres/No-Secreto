# 🚀 EXECUTE AGORA - Deploy Storage Rules

## Comando para Executar

```powershell
.\deploy-storage-rules.ps1
```

## O que o script faz

1. Verifica o projeto ativo do Firebase
2. Faz deploy das regras do Storage
3. Mostra instrucoes de teste

## Regras Aplicadas

### Stories
- Leitura: Qualquer usuario autenticado
- Escrita: Apenas o proprio usuario (valida UID no nome do arquivo)

### Profile Photos
- Leitura: Qualquer usuario autenticado
- Escrita: Apenas o proprio usuario

### Outras Pastas
- Leitura e Escrita: Qualquer usuario autenticado

## Teste Apos Deploy

1. Abrir o app
2. Tentar publicar um story
3. Verificar logs:
   - NAO deve ter: `storage/unknown`
   - DEVE ter: `Upload concluido com sucesso`

## Verificar no Console

1. Firebase Console: https://console.firebase.google.com
2. Selecionar projeto: deusepaimovement
3. Storage > Files
4. Deve aparecer:
   - Pasta `stories_files/`
   - Arquivo com seu UID no nome

## Se Storage Nao Estiver Habilitado

1. Firebase Console > Storage
2. Clicar em "Get Started"
3. Escolher localizacao: southamerica-east1 (Sao Paulo)
4. Executar o script novamente

---

## EXECUTE AGORA:

```powershell
.\deploy-storage-rules.ps1
```

Isso vai resolver o erro de upload de stories! 🎯
