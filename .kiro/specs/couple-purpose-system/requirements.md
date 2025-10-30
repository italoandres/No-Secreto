# Sistema de Parceiro(a) no Propósito - Requisitos

## Introdução

Este sistema permite que usuários adicionem seus parceiros(as) ao chat "Nosso Propósito", criando um ambiente de conversa tripla entre o casal e Deus. O sistema inclui funcionalidades de convites, menções específicas e compartilhamento de stories.

## Requisitos

### Requisito 1: Menu de Adição de Parceiro(a)

**User Story:** Como usuário do chat "Nosso Propósito", eu quero ter uma opção no menu de 3 pontos para adicionar meu(minha) parceiro(a), para que possamos conversar juntos com Deus.

#### Acceptance Criteria

1. QUANDO o usuário acessar o menu de 3 pontos no chat "Nosso Propósito" ENTÃO o sistema SHALL exibir a opção "Add Parceiro(a) ao Propósito"
2. QUANDO o usuário clicar em "Add Parceiro(a) ao Propósito" ENTÃO o sistema SHALL abrir uma tela de busca de usuários
3. QUANDO o usuário selecionar um parceiro(a) ENTÃO o sistema SHALL enviar um convite para o usuário selecionado
4. QUANDO o convite for enviado ENTÃO o sistema SHALL exibir uma mensagem de confirmação "Convite enviado para [nome]"

### Requisito 2: Sistema de Convites para Parceiro(a)

**User Story:** Como usuário que recebeu um convite para ser parceiro(a) no Propósito, eu quero poder aceitar ou recusar o convite, para que eu possa decidir se quero participar da conversa.

#### Acceptance Criteria

1. QUANDO um usuário receber um convite de parceiro(a) ENTÃO o sistema SHALL enviar uma notificação push
2. QUANDO o usuário abrir o app após receber convite ENTÃO o sistema SHALL exibir um modal com o convite
3. QUANDO o usuário visualizar o convite ENTÃO o sistema SHALL mostrar "Aceitar" e "Recusar" como opções
4. QUANDO o usuário aceitar o convite ENTÃO o sistema SHALL criar a conexão de parceiros e notificar ambos
5. QUANDO o usuário recusar o convite ENTÃO o sistema SHALL notificar o remetente sobre a recusa

### Requisito 3: Chat Triplo com Posicionamento Específico

**User Story:** Como casal conectado no Propósito, nós queremos que nossas mensagens apareçam do lado esquerdo e as mensagens de Deus do lado direito, para que tenhamos uma experiência visual clara da conversa tripla.

#### Acceptance Criteria

1. QUANDO um dos parceiros enviar uma mensagem ENTÃO o sistema SHALL posicionar a mensagem do lado esquerdo
2. QUANDO Deus (admin) enviar uma mensagem ENTÃO o sistema SHALL posicionar a mensagem do lado direito
3. QUANDO ambos os parceiros estiverem online ENTÃO o sistema SHALL mostrar indicadores de presença
4. QUANDO uma mensagem for enviada ENTÃO o sistema SHALL notificar ambos os parceiros
5. QUANDO um parceiro visualizar uma mensagem ENTÃO o sistema SHALL marcar como lida para ambos

### Requisito 4: Sistema de @Menções com Convites

**User Story:** Como usuário do Propósito, eu quero poder mencionar (@) qualquer usuário em mensagens específicas, para que ele(a) receba um convite personalizado para participar do mesmo chat.

#### Acceptance Criteria

1. QUANDO o usuário digitar @ no campo de mensagem ENTÃO o sistema SHALL sugerir nomes de usuários disponíveis
2. QUANDO o usuário selecionar um usuário na menção ENTÃO o sistema SHALL destacar a menção na mensagem
3. QUANDO a mensagem com menção for enviada ENTÃO o sistema SHALL enviar um convite personalizado ao usuário mencionado
4. QUANDO o usuário mencionado receber o convite ENTÃO o sistema SHALL mostrar "@[nome_usuario] escreveu essa mensagem para você como forma de te chamar para o propósito"
5. QUANDO o usuário mencionado aceitar o convite ENTÃO o sistema SHALL adicionar ele(a) ao mesmo chat compartilhado
6. QUANDO o convite for aceito ENTÃO ambos os usuários SHALL participar do mesmo chat a partir daquele momento

### Requisito 5: Stories Compartilhados para Ambos os Sexos

**User Story:** Como usuário do sistema de Propósito, eu quero que os stories sejam visíveis para ambos os sexos (homem e mulher), para que o casal possa ver o mesmo conteúdo espiritual.

#### Acceptance Criteria

1. QUANDO stories forem publicados no contexto "nosso_proposito" ENTÃO o sistema SHALL torná-los visíveis para ambos os sexos
2. QUANDO um usuário visualizar stories no Propósito ENTÃO o sistema SHALL mostrar stories para homens e mulheres
3. QUANDO o casal estiver conectado ENTÃO o sistema SHALL sincronizar a visualização de stories entre os parceiros
4. QUANDO um story for marcado como visto por um parceiro ENTÃO o sistema SHALL manter controle individual de visualização

### Requisito 6: Gerenciamento de Conexão de Parceiros

**User Story:** Como usuário conectado a um parceiro(a), eu quero poder gerenciar nossa conexão, para que eu possa desconectar se necessário.

#### Acceptance Criteria

1. QUANDO o usuário acessar configurações do Propósito ENTÃO o sistema SHALL mostrar status da conexão atual
2. QUANDO houver um parceiro(a) conectado ENTÃO o sistema SHALL exibir opção "Desconectar Parceiro(a)"
3. QUANDO o usuário desconectar o parceiro(a) ENTÃO o sistema SHALL notificar ambos sobre a desconexão
4. QUANDO a desconexão ocorrer ENTÃO o sistema SHALL manter o histórico de conversas mas impedir novas interações
5. QUANDO não houver parceiro(a) conectado ENTÃO o sistema SHALL funcionar como chat individual com Deus

### Requisito 7: Notificações e Sincronização

**User Story:** Como usuário do sistema de Propósito, eu quero receber notificações adequadas sobre atividades do meu parceiro(a), para que eu esteja sempre informado sobre nossa conversa com Deus.

#### Acceptance Criteria

1. QUANDO o parceiro(a) enviar uma mensagem ENTÃO o sistema SHALL notificar o outro parceiro
2. QUANDO Deus responder no chat do casal ENTÃO o sistema SHALL notificar ambos os parceiros
3. QUANDO um convite de menção for enviado ENTÃO o sistema SHALL enviar notificação push específica
4. QUANDO o status de conexão mudar ENTÃO o sistema SHALL notificar ambos os usuários
5. QUANDO stories novos forem publicados ENTÃO o sistema SHALL notificar o casal conectado