import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Política de Privacidade'),
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
              'Política de Privacidade do Aplicativo "No Secreto com Deus Pai"',
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
              'Introdução',
              'O aplicativo "No Secreto com Deus Pai" (doravante referido como "o aplicativo") é comprometido com a proteção da privacidade e dados de seus usuários. Esta política de privacidade estabelece como coletamos, usamos, processamos e protegemos as informações dos usuários do aplicativo.',
            ),
            
            _buildSection(
              'Coleta de Informações',
              'O aplicativo coleta o seguinte tipo de informação:\n\nE-mail: Usado exclusivamente para identificação do usuário no banco de dados do aplicativo, recuperação de backups de conversas e comunicação essencial.',
            ),
            
            _buildSection(
              'Uso de Informações',
              'As informações coletadas são utilizadas para:\n\n• Fornecer, operar e manter o aplicativo.\n• Melhorar, personalizar e expandir o aplicativo.\n• Entender e analisar como os usuários utilizam o aplicativo.\n• Desenvolver novos produtos, serviços, funcionalidades e funcionalidades.\n• Comunicar-se com os usuários, diretamente ou através de um dos nossos parceiros, incluindo para atendimento ao cliente, para fornecer atualizações e outras informações relacionadas ao aplicativo, e para fins de marketing e promoção.',
            ),
            
            _buildSection(
              'Compartilhamento de Informações',
              'O aplicativo não compartilha informações pessoais dos usuários com terceiros, exceto quando necessário para fornecer os serviços do aplicativo ou se exigido por lei.',
            ),
            
            _buildSection(
              'Segurança',
              'O aplicativo implementa medidas de segurança para proteger contra o acesso, alteração, divulgação ou destruição não autorizada das informações dos usuários. No entanto, nenhum método de transmissão pela Internet ou método de armazenamento eletrônico é 100% seguro, e não podemos garantir sua segurança absoluta.',
            ),
            
            _buildSection(
              'Senhas',
              'Os usuários são responsáveis por manter a confidencialidade de suas senhas. Recomendamos o uso de senhas fortes, que incluam uma combinação de letras maiúsculas, minúsculas, números e símbolos. O aplicativo não pode ser responsabilizado por perdas ou danos resultantes do não cumprimento desta recomendação.',
            ),
            
            _buildSection(
              'Privacidade Infantil',
              'O aplicativo não coleta intencionalmente informações pessoais de crianças com menos de 13 anos. Se tomarmos conhecimento de que coletamos informações pessoais de uma criança com menos de 13 anos, tomaremos medidas para excluir essas informações o mais rápido possível.',
            ),
            
            _buildSection(
              'Alterações à Política de Privacidade',
              'Reservamo-nos o direito de modificar esta política de privacidade a qualquer momento, então, por favor, revise-a frequentemente. Alterações e esclarecimentos entrarão em vigor imediatamente após sua publicação no aplicativo.',
            ),
            
            _buildSection(
              'Conteúdo Gerado pelo Usuário',
              'O aplicativo não está ligado a nenhuma religião específica e é aberto a todos os usuários, independentemente de sua fé. O objetivo é promover um relacionamento pessoal e íntimo com Deus como Pai.',
            ),
            
            _buildSection(
              'Contato',
              'Em caso de dúvidas ou sugestões sobre esta política de privacidade, entre em contato conosco: suporte@nosecreto.app',
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