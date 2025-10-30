# 📚 Guia Completo - Sistema de Certificação Espiritual

## 📖 Índice

1. [Visão Geral](#visão-geral)
2. [Para Usuários](#para-usuários)
3. [Para Administradores](#para-administradores)
4. [Estrutura de Dados](#estrutura-de-dados)
5. [FAQ](#faq)
6. [Troubleshooting](#troubleshooting)

---

## 🎯 Visão Geral

O Sistema de Certificação Espiritual permite que usuários que concluíram o curso "No Secreto com o Pai" solicitem um selo dourado de certificação em seu perfil.

### Fluxo Completo

```
Usuário → Solicita Certificação → Admin Analisa → Aprovado/Rejeitado → Notificação → Selo no Perfil
```

### Benefícios

- ✅ Validação oficial do curso
- ✅ Selo dourado visível no perfil
- ✅ Destaque na comunidade
- ✅ Credibilidade aumentada

---

## 👤 Para Usuários

### Como Solicitar Certificação

#### Passo 1: Acessar a Tela de Certificação

**Opção A: Pelo Perfil**
1. Acesse seu perfil
2. Clique no botão "Solicitar Certificação"

**Opção B: Pelo Menu Vitrine de Propósito**
1. Abra o menu "Vitrine de Propósito"
2. Selecione "Certificação Espiritual"

#### Passo 2: Preencher o Formulário

1. **Email da Compra**: Digite o email usado na compra do curso
2. **Email do App**: Seu email será preenchido automaticamente
3. **Comprovante**: Faça upload do comprovante de compra

#### Passo 3: Enviar Comprovante

**Formatos Aceitos:**
- PDF (.pdf)
- Imagens (.jpg, .jpeg, .png)

**Tamanho Máximo:**
- 5 MB

**Dicas:**
- ✅ Certifique-se que o comprovante está legível
- ✅ Inclua todas as informações da compra
- ✅ Verifique se o email está correto

#### Passo 4: Aguardar Análise

- ⏱️ Tempo médio: 24-48 horas
- 📧 Você receberá um email quando houver resposta
- 🔔 Uma notificação aparecerá no app

### Acompanhar Status

#### Ver Histórico de Solicitações

1. Acesse a tela de Certificação
2. Role até a seção "Histórico"
3. Veja todas suas solicitações com status:
   - ⏱️ **Pendente**: Em análise
   - ✅ **Aprovada**: Certificação concedida
   - ❌ **Rejeitada**: Solicitação negada

#### Reenviar Solicitação

Se sua solicitação foi rejeitada:

1. Leia o motivo da rejeição
2. Corrija o problema
3. Clique em "Reenviar"
4. Envie um novo comprovante

### Após Aprovação

Quando sua certificação for aprovada:

1. ✅ Você receberá uma notificação
2. 🏆 O selo dourado aparecerá em seu perfil
3. ⭐ Outros usuários verão seu selo
4. 📱 O selo aparece em:
   - Seu perfil
   - Lista de perfis
   - Vitrine de Propósito
   - Resultados de busca

---

## 👨‍💼 Para Administradores

### Acessar Painel Admin

1. Faça login com conta admin
2. Acesse o menu admin
3. Selecione "Certificações Espirituais"

### Analisar Solicitações

#### Visualizar Solicitações Pendentes

O painel possui 3 abas:
- **Pendentes**: Solicitações aguardando análise
- **Aprovadas**: Certificações concedidas
- **Rejeitadas**: Solicitações negadas

#### Analisar uma Solicitação

Para cada solicitação você verá:
- 👤 Nome e email do usuário
- 📧 Email da compra
- 📅 Data da solicitação
- 📎 Comprovante anexado

#### Ver Comprovante

1. Clique em "Ver Comprovante"
2. O arquivo será aberto:
   - **Imagens**: Visualização com zoom
   - **PDF**: Abre em app externo
3. Você pode:
   - 🔍 Ampliar/reduzir
   - 📥 Baixar o arquivo
   - 📤 Compartilhar

#### Aprovar Certificação

1. Clique em "Aprovar"
2. Confirme a ação
3. Sistema automaticamente:
   - ✅ Atualiza status para "aprovado"
   - 🏆 Adiciona selo no perfil do usuário
   - 🔔 Envia notificação ao usuário
   - 📧 Envia email de confirmação

#### Rejeitar Certificação

1. Clique em "Rejeitar"
2. (Opcional) Informe o motivo da rejeição
3. Confirme a ação
4. Sistema automaticamente:
   - ❌ Atualiza status para "rejeitado"
   - 🔔 Envia notificação ao usuário
   - 📧 Envia email com motivo (se informado)

### Boas Práticas para Análise

#### ✅ Aprovar quando:
- Comprovante legível e completo
- Email corresponde ao da compra
- Informações consistentes
- Curso "No Secreto com o Pai" confirmado

#### ❌ Rejeitar quando:
- Comprovante ilegível
- Email não corresponde
- Comprovante de outro curso
- Informações incompletas
- Suspeita de fraude

#### 💡 Dicas:
- Sempre informe o motivo da rejeição
- Seja claro e educado
- Verifique todos os detalhes
- Em caso de dúvida, peça mais informações

---

## 🗄️ Estrutura de Dados

### Modelo de Certificação

```dart
class CertificationRequestModel {
  String id;                    // ID único
  String userId;                // ID do usuário
  String userName;              // Nome do usuário
  String userEmail;             // Email do app
  String purchaseEmail;         // Email da compra
  String proofFileUrl;          // URL do comprovante
  String proofFileName;         // Nome do arquivo
  CertificationStatus status;   // pending/approved/rejected
  DateTime requestedAt;         // Data da solicitação
  DateTime? processedAt;        // Data do processamento
  String? rejectionReason;      // Motivo da rejeição
}
```

### Status Possíveis

```dart
enum CertificationStatus {
  pending,   // ⏱️ Aguardando análise
  approved,  // ✅ Aprovada
  rejected,  // ❌ Rejeitada
}
```

### Coleções do Firebase

#### spiritual_certifications
```
/spiritual_certifications/{certificationId}
  - userId: string
  - userName: string
  - userEmail: string
  - purchaseEmail: string
  - proofFileUrl: string
  - proofFileName: string
  - status: string
  - requestedAt: timestamp
  - processedAt: timestamp (opcional)
  - rejectionReason: string (opcional)
```

#### usuarios (campo adicional)
```
/usuarios/{userId}
  - isSpiritualCertified: boolean
```

#### Storage
```
/certifications/{userId}/{timestamp}_{filename}
```

---

## ❓ FAQ

### Para Usuários

**Q: Quanto tempo leva a análise?**
A: Geralmente 24-48 horas úteis.

**Q: Posso enviar mais de uma solicitação?**
A: Sim, mas apenas uma por vez. Aguarde a resposta antes de enviar outra.

**Q: O que fazer se minha solicitação foi rejeitada?**
A: Leia o motivo, corrija o problema e envie uma nova solicitação.

**Q: Posso usar qualquer email na compra?**
A: Sim, mas deve ser o mesmo email usado na compra do curso.

**Q: Quais formatos de arquivo são aceitos?**
A: PDF, JPG, JPEG e PNG (máximo 5MB).

**Q: O selo é permanente?**
A: Sim, uma vez aprovado, o selo permanece em seu perfil.

**Q: Outros usuários veem meu selo?**
A: Sim, o selo é visível para todos os usuários.

### Para Administradores

**Q: Como sei se um comprovante é válido?**
A: Verifique se contém informações da compra do curso "No Secreto com o Pai".

**Q: Devo sempre informar motivo da rejeição?**
A: É recomendado, ajuda o usuário a corrigir e reenviar.

**Q: Posso reverter uma aprovação?**
A: Não diretamente pelo painel. Entre em contato com suporte técnico.

**Q: Quantas solicitações posso analisar por dia?**
A: Não há limite, analise conforme sua disponibilidade.

---

## 🔧 Troubleshooting

### Problemas Comuns - Usuários

#### Erro ao fazer upload
**Problema**: "Erro ao fazer upload do arquivo"
**Soluções**:
- Verifique o tamanho do arquivo (máx 5MB)
- Verifique o formato (PDF, JPG, JPEG, PNG)
- Verifique sua conexão com internet
- Tente novamente

#### Não recebo notificação
**Problema**: Não recebi notificação da resposta
**Soluções**:
- Verifique a aba de notificações no app
- Verifique seu email (incluindo spam)
- Verifique o histórico na tela de certificação

#### Selo não aparece
**Problema**: Fui aprovado mas o selo não aparece
**Soluções**:
- Faça logout e login novamente
- Limpe o cache do app
- Aguarde alguns minutos
- Entre em contato com suporte

### Problemas Comuns - Administradores

#### Não consigo ver comprovante
**Problema**: Erro ao abrir comprovante
**Soluções**:
- Verifique sua conexão
- Tente baixar o arquivo
- Verifique se o arquivo ainda existe no Storage

#### Erro ao aprovar/rejeitar
**Problema**: Erro ao processar solicitação
**Soluções**:
- Verifique sua conexão
- Recarregue a página
- Tente novamente
- Verifique permissões admin

---

## 📞 Suporte

### Contato

- **Email**: sinais.app@gmail.com
- **Suporte Técnico**: Através do app

### Reportar Problemas

Ao reportar um problema, inclua:
- Descrição detalhada
- Passos para reproduzir
- Screenshots (se possível)
- Seu email/ID de usuário

---

## 📝 Notas de Versão

### v1.0.0 - Sistema Inicial
- ✅ Solicitação de certificação
- ✅ Upload de comprovantes
- ✅ Painel administrativo
- ✅ Sistema de notificações
- ✅ Selo dourado no perfil
- ✅ Histórico de solicitações

---

**Última atualização**: Dezembro 2024
**Versão do documento**: 1.0.0
