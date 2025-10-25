import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:whatsapp_chat/views/login_view.dart';
import 'package:whatsapp_chat/views/username_settings_view.dart';
import 'package:whatsapp_chat/views/profile_completion_view.dart';
import 'package:whatsapp_chat/views/vitrine_proposito_menu_view.dart';
import 'package:whatsapp_chat/views/edit_profile_menu_view.dart';
import 'package:whatsapp_chat/views/store_menu_view.dart';
import 'package:whatsapp_chat/models/usuario_model.dart';
import 'package:whatsapp_chat/repositories/usuario_repository.dart';
import '../components/matches_button_with_notifications.dart';

class CommunityInfoView extends StatefulWidget {
  const CommunityInfoView({Key? key}) : super(key: key);

  @override
  State<CommunityInfoView> createState() => _CommunityInfoViewState();
}

class _CommunityInfoViewState extends State<CommunityInfoView> {
  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final Map<String, bool> _expandedSections = {
    'missao': false,
    'sinais': false,
    'proposito': false,
    'faca_parte': false,
  };

  // Sistema de abas
  int _selectedTabIndex = 3; // Comunidade fica aberta por padrão
  final List<String> _tabTitles = [
    'Editar Perfil',
    'Vitrine de Propósito',
    'Loja',
    'Nossa Comunidade'
  ];

  void _toggleSection(String key) {
    setState(() {
      _expandedSections[key] = !(_expandedSections[key] ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          // Header personalizado
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              right: 16,
              bottom: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.arrow_back),
                  color: Colors.grey.shade700,
                ),
                const Expanded(
                  child: Text(
                    'Comunidade',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                // Botão de configurações removido - funcionalidade movida para aba "Editar Perfil"
                const SizedBox(width: 48), // Espaço para manter centralização
              ],
            ),
          ),

          // Sistema de abas verticais
          Container(
            color: Colors.white,
            child: Column(
              children: List.generate(_tabTitles.length, (index) {
                final isSelected = _selectedTabIndex == index;
                Color tabColor;
                IconData tabIcon;

                // Definir cor e ícone para cada aba
                switch (index) {
                  case 0: // Editar Perfil
                    tabColor = Colors.green.shade600;
                    tabIcon = Icons.settings;
                    break;
                  case 1: // Vitrine de Propósito
                    tabColor = Colors.purple.shade600;
                    tabIcon = Icons.person_search;
                    break;
                  case 2: // Loja
                    tabColor = Colors.orange.shade600;
                    tabIcon = Icons.store;
                    break;
                  case 3: // Nossa Comunidade
                    tabColor = Colors.amber.shade600;
                    tabIcon = Icons.people;
                    break;
                  default:
                    tabColor = Colors.blue.shade600;
                    tabIcon = Icons.tab;
                }

                return GestureDetector(
                  onTap: () {
                    // Apenas "Nossa Comunidade" (index 3) fica no CommunityInfoView
                    // Outras abas vão direto para páginas dedicadas
                    if (index == 0) {
                      // Editar Perfil - vai direto para página dedicada
                      Get.to(() => const EditProfileMenuView());
                    } else if (index == 1) {
                      // Vitrine de Propósito - vai direto para página dedicada
                      Get.to(() => const VitrinePropositoMenuView());
                    } else if (index == 2) {
                      // Loja - vai direto para página dedicada
                      Get.to(() => const StoreMenuView());
                    }
                    // Nossa Comunidade (index 3) não faz nada, já está ativa
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    margin:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      // Gradiente especial para Vitrine de Propósito
                      gradient: isSelected && index == 1
                          ? LinearGradient(
                              colors: [
                                Colors.blue.shade600,
                                Colors.pink.shade400
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isSelected && index != 1
                          ? tabColor
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? tabColor : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          tabIcon,
                          color: isSelected ? Colors.white : tabColor,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _tabTitles[index],
                            style: TextStyle(
                              color: isSelected ? Colors.white : tabColor,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white,
                            size: 16,
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),

          // Conteúdo sempre de "Nossa Comunidade"
          // Outras abas vão direto para páginas dedicadas
          Expanded(
            child: _buildNossaComunidadeContent(),
          ),
        ],
      ),
    );
  }

  // Métodos removidos - abas agora vão direto para páginas dedicadas

  Widget _buildNossaComunidadeContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header com ícone da comunidade
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber.shade700, Colors.amber.shade500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Ícone da comunidade
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.people,
                    size: 40,
                    color: Colors.amber.shade700,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'COMUNIDADE DEUS É PAI',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Um lugar de relacionamento verdadeiro com o Pai',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Seção 1: Missão
          _buildExpandableSection(
            'missao',
            'MISSÃO NO SECRETO COM O PAI',
            '''Este aplicativo foi um plano divino entregue a um órfão de pai biológico que, em 2020, criou um chat no WhatsApp com o nome 'Deus como Pai' para ter um Pai com quem conversar e não se sentir mais sozinho, já que também sofria de rejeição. O objetivo era apenas preencher esse vazio afetivo causado pela orfandade paterna biológica, sem imaginar que, três anos depois, Deus me daria um projeto para criar um aplicativo e levar esse meio de se relacionar com Ele para outros filhos.

Hoje, próximo à data de lançamento deste aplicativo, somam-se quatro anos de experiências reais com o Pai, e o bacana é que tudo fica registrado para quando você quiser recordar. Em um tempo em que o número de orfandade paterna chega próximo a 90% da população e onde está cada vez mais difícil ter contatos leais para conversar, eu, e agora você, encontramos um que é leal e o único de que precisamos: nosso verdadeiro Pai.

Já imaginou você poder conversar com Deus como Pai? Sim, oração não é só de joelho; oração são palavras. Foi com palavras que Davi conversava com Deus. Historiadores contam que Davi tinha uma pilha de cartas ou pergaminhos escritos para Deus. Cartas eram o meio de comunicação à distância que existia entre os homens naquela época, prova disso é que dos 150 salmos, ele escreveu metade, 73, tudo em secreto com Deus Pai, e não por coincidência, também foi o único a ser chamado 'o homem segundo o meu coração'.

Mateus 6:5-6 diz: 'E quando vocês orarem, não sejam como os hipócritas. Eles gostam de ficar orando em pé nas sinagogas e nas esquinas, a fim de serem vistos pelos outros. Eu asseguro que eles já receberam sua plena recompensa. Mas, quando você orar, vá para seu quarto, feche a porta e ore a seu Pai, que está em secreto. Então seu Pai, que vê em secreto, o recompensará.'

Essa é a mensagem mantra de nossa missão: viver um relacionamento de filho no secreto, na prática, com o Pai.''',
            Icons.favorite,
            Colors.red,
          ),

          const SizedBox(height: 16),

          // Seção 2: Sinais
          _buildExpandableSection(
            'sinais',
            'SINAIS DE MEU ISAQUE E SINAIS DE MINHA REBECA',
            '''Esse projeto também foi um plano divino que Deus entregou para alguém que acredita no amor e que acredita nas escolhas de Deus para ele. Existe uma metáfora que diz que quando Adão e Eva tinha relacionamento com Deus no Éden, eles eram como criança e Deus como Pai, o que quer dizer que toda criança segue e faz aquilo que seu Pai decide e escolhe para eles, só que Adão e Eva quiseram crescer quiseram ser adulto e fazer suas próprias escolhas ao comer o fruto proibido, isso afetou toda humanidade e que vivem querendo fazer suas escolhas, acontece que o ser humano não sabe escolher e Deus não deixou de ser Pai e não deixou de ter um plano para nós.

Com tudo isso quero dizer que sim temos o livre arbítrio mas de escolher viver os nossos planos ou os planos de Deus, isso aconteceu com Jeremias. Jeremias por tradição de genealogia estava se preparando para ser sacerdote porque o seu pai era sacerdote, é função que não precisa falar mas ao ele ter relacionamento com Deus, Deus disse a ele olha antes que te formasse no ventre de sua mãe te conheci e te preparei para ser profeta. Jeremias quis dar desculpas porque não sabia falar mas esse era o plano de Deus para Jeremias e ele obedeceu e sua missão se perpetuou por todas as próximas gerações.

E isso não é diferente quando falamos de relacionamento amoroso. A maior prova disso é a história de Isaque e Rebeca e sim se teve sinal teve Deus escolhendo e não apenas essa história mas Deus precisou que muitos relacionamentos que Ele escolheu da genealogia de Jesus acontecesse para que o filho dEle viesse a terra. Como exemplo Ruth sendo moabita perdeu o marido para se casar com a pessoa certa de Belém de Judá porque era deles que viria Davi e genealogia de Jesus filho de Davi.

A nossa mensagem mantra nesse projeto é: escolha viver as escolhas de Deus Pai para sua vida.''',
            Icons.favorite_border,
            Colors.pink,
          ),

          const SizedBox(height: 16),

          // Seção 3: Propósito
          _buildExpandableSection(
            'proposito',
            'NOSSO PROPÓSITO',
            '''Nós acreditamos que maior do que o amor romântico é o amor por Jesus e por uma missão de vida a dois por Jesus ou seja cumprir o propósito, a vida das duas pessoas que Deus uniu existe uma missão aqui na terra uma única missão e não a esposa ter um propósito e o marido ter outro.

Esse espaço não é apenas para os dois mas para os 3: o Casal e o Pai. Um espaço onde o casal vai aperfeiçoar o seu chamado é o casal dizendo eis me aqui Pai para viver a sua vontade, esse tipo de interação com Pai nesse propósito não vai te deixar esquecer um dia de seu chamado de seu propósito onde vocês irão pedir confirmações, trazer ideias compartilhar resultados experiências colocar metas em busca de deixar um legado.''',
            Icons.star,
            Colors.orange,
          ),

          const SizedBox(height: 32),

          // Seção "Faça Parte Dessa Verdade"
          _buildJoinCommunitySection(),

          const SizedBox(height: 24),

          // Footer
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  Icons.people,
                  size: 32,
                  color: Colors.amber.shade700,
                ),
                const SizedBox(height: 8),
                Text(
                  'Bem-vindo à nossa comunidade!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Juntos no relacionamento com o Pai',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinCommunitySection() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade600, Colors.purple.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header - não clicável para "faca_parte"
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.diamond,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'FAÇA PARTE DESSA MISSÃO',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Uma causa de verdadeiros irmãos na prática.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Conteúdo sempre visível
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Divider(color: Colors.white.withOpacity(0.3)),
                const SizedBox(height: 16),

                // Seção Divulgação com Influencers
                _buildSubSection(
                  '📣 Divulgação com Influencers',
                  'Estamos unindo pessoas reais, que vivem a verdade e inspiram outras com autenticidade.\nAjudando a divulgar esse movimento, você leva essa luz mais longe.',
                ),

                const SizedBox(height: 20),

                // Contador de usuários
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.people,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Usuários que já fazem parte:',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '12.357',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade300,
                            ),
                          ),
                          const Text(
                            ' / 100.000',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: 12357 / 100000,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.amber.shade300),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Primeiro botão CTA
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      _showJoinDialog('divulgacao');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade400,
                      foregroundColor: Colors.purple.shade800,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      'FAREI PARTE',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Seção Divulgação + Manutenção
                _buildSubSection(
                  '💰 Divulgação + Manutenção',
                  'Este app é gratuito e sem anúncios. Toda ajuda mantém a missão viva — e garante as melhorias constantes.',
                ),

                const SizedBox(height: 12),

                // Custo por usuário
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.monetization_on,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      const Text(
                        'Custo médio por usuário: ',
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                      Text(
                        'R\$ 0,07 por mês',
                        style: TextStyle(
                          color: Colors.amber.shade300,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Por que temos custos
                _buildSubSection(
                  '📦 Por que temos custos?',
                  '• Armazenamento de dados em nuvem\n• Infraestrutura de IA e segurança\n• Suporte técnico e melhorias contínuas\n\n✨ Mesmo uma ajuda simbólica já faz a diferença.',
                ),

                const SizedBox(height: 20),

                // Segundo botão CTA
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      _showJoinDialog('manutencao');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade400,
                      foregroundColor: Colors.purple.shade800,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      'FAREI PARTE',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  void _showJoinDialog(String type) {
    String title =
        type == 'divulgacao' ? 'Divulgar a Comunidade' : 'Apoiar a Manutenção';

    String message = type == 'divulgacao'
        ? 'Obrigado por querer fazer parte! Em breve teremos mais informações sobre como você pode ajudar a divulgar nossa comunidade.'
        : 'Obrigado por querer contribuir! Em breve teremos informações sobre como apoiar a manutenção do aplicativo.';

    Get.defaultDialog(
      title: title,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.favorite,
            color: Colors.purple.shade600,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Get.back(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple.shade600,
          ),
          child: const Text(
            'Entendi',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildExpandableSection(
    String key,
    String title,
    String content,
    IconData icon,
    Color color,
  ) {
    final isExpanded = _expandedSections[key] ?? false;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header clicável
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _toggleSection(key),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Conteúdo expansível
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: isExpanded ? null : 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: isExpanded ? 1.0 : 0.0,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Divider(color: Colors.grey.shade200),
                    const SizedBox(height: 12),
                    Text(
                      content,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: Colors.grey.shade700,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget para opções do perfil
  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey.shade400,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget para opções da vitrine (mesmo modelo do perfil)
  Widget _buildVitrineOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey.shade400,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget para features da vitrine (informativo)
  Widget _buildVitrineFeature({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Método para mostrar diálogo de logout
  void _showLogoutDialog() {
    Get.defaultDialog(
      title: 'Sair da Conta',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.logout,
            color: Colors.red.shade600,
            size: 48,
          ),
          const SizedBox(height: 16),
          const Text(
            'Tem certeza que deseja sair da sua conta?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            Get.back();
            _logout();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade600,
          ),
          child: const Text(
            'Sair',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  // Método removido - Vitrine de Propósito agora vai direto para página dedicada

  void _navigateToVitrineProfile() {
    // Navegar para o perfil de vitrine (ProfileCompletionView)
    Get.to(() => const ProfileCompletionView());
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Get.offAll(() => const LoginView());
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao fazer logout: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
