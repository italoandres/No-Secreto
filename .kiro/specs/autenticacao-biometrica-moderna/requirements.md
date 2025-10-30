# Requirements Document

## Introduction

Este documento define os requisitos para modernizar o sistema de autenticação do aplicativo, implementando suporte a autenticação biométrica (impressão digital, reconhecimento facial, íris) e melhorando a experiência de segurança do usuário. O sistema atual usa apenas senha simples, e queremos priorizar os métodos de autenticação nativos do dispositivo do usuário.

## Glossary

- **Sistema de Autenticação**: Módulo responsável por verificar a identidade do usuário ao abrir o aplicativo
- **Biometria**: Métodos de autenticação baseados em características físicas do usuário (impressão digital, face, íris)
- **Local Authentication**: API do Flutter para acessar métodos de autenticação nativos do dispositivo
- **Fallback**: Método alternativo de autenticação quando o método principal falha
- **App Lock**: Proteção que exige autenticação ao abrir o aplicativo

## Requirements

### Requirement 1

**User Story:** Como usuário do aplicativo, quero usar a biometria do meu dispositivo (impressão digital, reconhecimento facial, etc.) para desbloquear o app, para que eu tenha uma experiência de segurança moderna e conveniente.

#### Acceptance Criteria

1. WHEN o usuário ativa a proteção do app, THE Sistema de Autenticação SHALL detectar automaticamente os métodos biométricos disponíveis no dispositivo
2. WHEN métodos biométricos estão disponíveis, THE Sistema de Autenticação SHALL priorizar biometria sobre senha numérica
3. WHEN o usuário abre o aplicativo com proteção ativada, THE Sistema de Autenticação SHALL solicitar autenticação biométrica
4. IF a autenticação biométrica falhar após 3 tentativas, THEN THE Sistema de Autenticação SHALL oferecer fallback para senha numérica
5. WHEN o dispositivo não possui biometria configurada, THE Sistema de Autenticação SHALL usar apenas senha numérica como método de autenticação

### Requirement 2

**User Story:** Como usuário, quero configurar facilmente a proteção do aplicativo nas configurações, para que eu possa escolher entre biometria, senha ou desativar a proteção.

#### Acceptance Criteria

1. THE Sistema de Autenticação SHALL exibir na tela de configurações os métodos de autenticação disponíveis no dispositivo
2. WHEN o usuário ativa a proteção, THE Sistema de Autenticação SHALL mostrar claramente qual método será usado (biometria + fallback ou apenas senha)
3. WHEN biometria está disponível, THE Sistema de Autenticação SHALL permitir ao usuário escolher entre "Biometria + Senha" ou "Apenas Senha"
4. THE Sistema de Autenticação SHALL permitir ao usuário desativar completamente a proteção do app
5. WHEN o usuário configura uma senha, THE Sistema de Autenticação SHALL validar que a senha tem no mínimo 4 caracteres

### Requirement 3

**User Story:** Como usuário, quero que o app me mostre informações claras sobre qual tipo de biometria meu dispositivo suporta, para que eu entenda como a proteção funcionará.

#### Acceptance Criteria

1. THE Sistema de Autenticação SHALL detectar e exibir o tipo específico de biometria disponível (impressão digital, Face ID, reconhecimento facial, íris)
2. WHEN o dispositivo suporta múltiplos métodos biométricos, THE Sistema de Autenticação SHALL listar todos os métodos disponíveis
3. THE Sistema de Autenticação SHALL exibir ícones apropriados para cada tipo de biometria (🔐 para senha, 👆 para impressão digital, 👤 para face, 👁️ para íris)
4. WHEN biometria não está configurada no dispositivo, THE Sistema de Autenticação SHALL exibir mensagem orientando o usuário a configurar nas configurações do sistema
5. THE Sistema de Autenticação SHALL mostrar status claro: "Protegido com [método]" ou "Sem proteção"

### Requirement 4

**User Story:** Como usuário, quero que a autenticação seja solicitada apenas quando necessário, para que eu não seja interrompido desnecessariamente durante o uso normal do app.

#### Acceptance Criteria

1. WHEN o usuário abre o aplicativo pela primeira vez após fechá-lo completamente, THE Sistema de Autenticação SHALL solicitar autenticação
2. WHEN o aplicativo está em segundo plano por menos de 2 minutos, THE Sistema de Autenticação SHALL NOT solicitar nova autenticação
3. WHEN o aplicativo está em segundo plano por mais de 2 minutos, THE Sistema de Autenticação SHALL solicitar nova autenticação ao retornar
4. THE Sistema de Autenticação SHALL permitir configurar o tempo de timeout (1, 2, 5, 10 minutos ou imediato)
5. WHEN o usuário está autenticado, THE Sistema de Autenticação SHALL manter a sessão ativa até o timeout configurado

### Requirement 5

**User Story:** Como desenvolvedor, quero que o sistema de autenticação seja robusto e trate erros adequadamente, para que o usuário nunca fique bloqueado fora do aplicativo.

#### Acceptance Criteria

1. IF a biometria falhar por erro do sistema, THEN THE Sistema de Autenticação SHALL oferecer imediatamente o fallback de senha
2. IF o usuário esquecer a senha, THEN THE Sistema de Autenticação SHALL oferecer opção de recuperação via email/reautenticação
3. THE Sistema de Autenticação SHALL registrar tentativas de autenticação falhadas para segurança
4. WHEN ocorrer erro crítico de autenticação, THE Sistema de Autenticação SHALL permitir bypass temporário com reautenticação do Firebase
5. THE Sistema de Autenticação SHALL funcionar offline, usando credenciais armazenadas localmente de forma segura

### Requirement 6

**User Story:** Como usuário, quero que minhas configurações de segurança sejam salvas de forma segura, para que elas persistam entre sessões e reinstalações do app.

#### Acceptance Criteria

1. THE Sistema de Autenticação SHALL armazenar configurações de segurança usando flutter_secure_storage
2. WHEN o usuário desinstala e reinstala o app, THE Sistema de Autenticação SHALL solicitar reconfiguração da proteção
3. THE Sistema de Autenticação SHALL NOT armazenar senhas em texto plano
4. THE Sistema de Autenticação SHALL usar hash seguro (bcrypt ou similar) para armazenar senhas localmente
5. WHEN o usuário faz logout, THE Sistema de Autenticação SHALL limpar todas as credenciais armazenadas localmente
