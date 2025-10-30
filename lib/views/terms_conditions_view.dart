import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TermsConditionsView extends StatelessWidget {
  const TermsConditionsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Termos e Condições'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Termos e Condições do Aplicativo "No Secreto com Deus Pai"',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Última atualização: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 20),
            _buildSection(
              'Bem-vindo',
              'Bem-vindo ao aplicativo "No Secreto com Deus Pai". Estes Termos e Condições ("Termos") regem seu acesso e uso do aplicativo "No Secreto com Deus Pai", incluindo quaisquer funcionalidades, conteúdos e serviços oferecidos em ou através do aplicativo (coletivamente, "Serviço").\n\nAo acessar ou usar o Serviço, você concorda em estar vinculado por estes Termos, todas as leis e regulamentos aplicáveis, e concorda que é responsável pelo cumprimento de quaisquer leis locais aplicáveis. Se você não concorda com algum destes termos, está proibido de usar ou acessar este Serviço.',
            ),
            _buildSection(
              'Direitos Autorais e Marcas Registradas',
              'O conteúdo, organização, gráficos, design, compilação, tradução, conversão digital e outros assuntos relacionados ao Serviço são protegidos sob leis de direitos autorais, marcas registradas e outras propriedades intelectuais aplicáveis (incluindo, mas não limitado a, direitos de propriedade intelectual). A cópia, redistribuição, uso ou publicação por você de qualquer parte do Serviço, exceto conforme permitido por estes Termos, é estritamente proibida.',
            ),
            _buildSection(
              'Uso do Serviço',
              'Você concorda em usar o Serviço apenas para fins permitidos e não engajará em atividades que interfiram com ou interrompam o acesso ou uso do Serviço por outros usuários. Você não deve:\n\n• Copiar, modificar ou distribuir o Serviço para qualquer propósito.\n• Tentar extrair o código-fonte do Serviço.\n• Traduzir o aplicativo ou criar versões derivadas do mesmo.',
            ),
            _buildSection(
              'Alterações e Acessibilidade',
              'Reservamos o direito de modificar ou descontinuar, temporariamente ou permanentemente, o Serviço (ou qualquer parte dele) com ou sem aviso prévio. Não seremos responsáveis perante você ou qualquer terceiro por qualquer modificação, suspensão ou descontinuação do Serviço.',
            ),
            _buildSection(
              'Segurança',
              'Você é responsável por manter a segurança do seu dispositivo e acesso ao Serviço. Recomendamos que não remova as restrições de software impostas pelo sistema operacional do seu dispositivo.',
            ),
            _buildSection(
              'Conexão com a Internet',
              'O Serviço requer uma conexão ativa com a internet. Você é responsável por todas as taxas de conexão ou dados associadas ao uso do Serviço.',
            ),
            _buildSection(
              'Atualizações do Serviço',
              'O Serviço está sujeito a atualizações e mudanças. Você concorda em receber atualizações automaticamente e reconhece que tais atualizações são necessárias para o melhor uso do Serviço.',
            ),
            _buildSection(
              'Conteúdo Gerado pelo Usuário',
              'Você é o único responsável pelo conteúdo que você cria, transmite ou exibe enquanto usa o Serviço e pelas consequências de suas ações.',
            ),
            _buildSection(
              'Elegibilidade',
              'Você só pode usar o Serviço se puder formar um contrato vinculativo com o "No Secreto com Deus Pai" e não estiver impedido de receber serviços sob as leis de sua jurisdição.',
            ),
            _buildSection(
              'Alterações aos Termos',
              'Reservamo-nos o direito de modificar estes Termos a qualquer momento. Sua continuação no uso do Serviço após tais mudanças constitui sua aceitação dos novos Termos.',
            ),
            _buildSection(
              'Contato',
              'Se você tiver alguma dúvida sobre estes Termos, entre em contato conosco: suporte@nosecreto.app',
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            height: 1.5,
          ),
          textAlign: TextAlign.justify,
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
