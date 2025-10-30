import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../components/admin_certifications_menu_item.dart';

/// Exemplos de integração do menu de certificações
///
/// Este arquivo mostra diferentes formas de integrar
/// os componentes de menu de certificações no app

// ============================================
// EXEMPLO 1: Menu de Configurações
// ============================================

class SettingsViewWithCertifications extends StatelessWidget {
  final bool isAdmin;

  const SettingsViewWithCertifications({
    Key? key,
    required this.isAdmin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
      ),
      body: ListView(
        children: [
          // Seção de Perfil
          const ListTile(
            leading: Icon(Icons.person),
            title: Text('Editar Perfil'),
            trailing: Icon(Icons.chevron_right),
          ),
          const ListTile(
            leading: Icon(Icons.lock),
            title: Text('Privacidade'),
            trailing: Icon(Icons.chevron_right),
          ),

          const Divider(),

          // Seção Admin (só aparece se for admin)
          if (isAdmin) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'ADMINISTRAÇÃO',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
            ),

            // Item de Certificações com contador
            AdminCertificationsMenuItem(isAdmin: isAdmin),

            const ListTile(
              leading: Icon(Icons.people),
              title: Text('Gerenciar Usuários'),
              trailing: Icon(Icons.chevron_right),
            ),

            const Divider(),
          ],

          // Outras opções
          const ListTile(
            leading: Icon(Icons.help),
            title: Text('Ajuda'),
            trailing: Icon(Icons.chevron_right),
          ),
          const ListTile(
            leading: Icon(Icons.info),
            title: Text('Sobre'),
            trailing: Icon(Icons.chevron_right),
          ),
          const ListTile(
            leading: Icon(Icons.exit_to_app, color: Colors.red),
            title: Text('Sair', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ============================================
// EXEMPLO 2: Drawer Lateral
// ============================================

class AppDrawerWithCertifications extends StatelessWidget {
  final bool isAdmin;
  final String userName;
  final String userEmail;

  const AppDrawerWithCertifications({
    Key? key,
    required this.isAdmin,
    required this.userName,
    required this.userEmail,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header do Drawer
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple, Colors.deepPurple],
              ),
            ),
            accountName: Text(userName),
            accountEmail: Text(userEmail),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 40, color: Colors.purple),
            ),
          ),

          // Menu Principal
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Início'),
            onTap: () => Get.back(),
          ),
          ListTile(
            leading: const Icon(Icons.favorite),
            title: const Text('Favoritos'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.chat),
            title: const Text('Conversas'),
            onTap: () {},
          ),

          const Divider(),

          // Seção Admin (versão compacta)
          if (isAdmin) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                'ADMINISTRAÇÃO',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
            ),
            CompactAdminCertificationsMenuItem(isAdmin: isAdmin),
            const SizedBox(height: 8),
          ],

          // Configurações
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Configurações'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

// ============================================
// EXEMPLO 3: Tela Principal Admin
// ============================================

class AdminDashboardView extends StatelessWidget {
  const AdminDashboardView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel Administrativo'),
        actions: [
          // Badge no AppBar
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                const Text('Pendentes: '),
                const SizedBox(width: 8),
                CertificationPendingBadge(isAdmin: true),
              ],
            ),
          ),
        ],
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          _buildDashboardCard(
            icon: Icons.people,
            title: 'Usuários',
            subtitle: '1.234 ativos',
            color: Colors.blue,
            onTap: () {},
          ),
          _buildDashboardCard(
            icon: Icons.verified_user,
            title: 'Certificações',
            subtitle: 'Ver pendentes',
            color: Colors.orange,
            onTap: () {
              // Navega para certificações
            },
            badge: CertificationPendingBadge(isAdmin: true),
          ),
          _buildDashboardCard(
            icon: Icons.report,
            title: 'Denúncias',
            subtitle: '5 novas',
            color: Colors.red,
            onTap: () {},
          ),
          _buildDashboardCard(
            icon: Icons.analytics,
            title: 'Estatísticas',
            subtitle: 'Ver relatórios',
            color: Colors.green,
            onTap: () {},
          ),
        ],
      ),
      // Botão flutuante de acesso rápido
      floatingActionButton: QuickAccessCertificationButton(isAdmin: true),
    );
  }

  Widget _buildDashboardCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    Widget? badge,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 40, color: color),
                  ),
                  if (badge != null)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: badge,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================
// EXEMPLO 4: Bottom Navigation com Badge
// ============================================

class MainAppWithBottomNav extends StatefulWidget {
  final bool isAdmin;

  const MainAppWithBottomNav({
    Key? key,
    required this.isAdmin,
  }) : super(key: key);

  @override
  State<MainAppWithBottomNav> createState() => _MainAppWithBottomNavState();
}

class _MainAppWithBottomNavState extends State<MainAppWithBottomNav> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Início',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: 'Explorar',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Conversas',
          ),
          if (widget.isAdmin)
            BottomNavigationBarItem(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.verified_user),
                  Positioned(
                    right: -8,
                    top: -8,
                    child: CertificationPendingBadge(isAdmin: true),
                  ),
                ],
              ),
              label: 'Certificações',
            ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  Widget _getBody() {
    switch (_currentIndex) {
      case 0:
        return const Center(child: Text('Início'));
      case 1:
        return const Center(child: Text('Explorar'));
      case 2:
        return const Center(child: Text('Conversas'));
      case 3:
        if (widget.isAdmin) {
          return const AdminDashboardView();
        }
        return const Center(child: Text('Perfil'));
      case 4:
        return const Center(child: Text('Perfil'));
      default:
        return const Center(child: Text('Início'));
    }
  }
}

// ============================================
// EXEMPLO 5: AppBar com Badge
// ============================================

class HomeViewWithCertificationBadge extends StatelessWidget {
  final bool isAdmin;

  const HomeViewWithCertificationBadge({
    Key? key,
    required this.isAdmin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Início'),
        actions: [
          if (isAdmin) ...[
            IconButton(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.verified_user),
                  Positioned(
                    right: -4,
                    top: -4,
                    child: CertificationPendingBadge(isAdmin: true),
                  ),
                ],
              ),
              onPressed: () {
                Get.to(() => const CertificationApprovalPanelView());
              },
              tooltip: 'Certificações Pendentes',
            ),
          ],
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {},
          ),
        ],
      ),
      body: const Center(
        child: Text('Conteúdo da Home'),
      ),
    );
  }
}

// ============================================
// EXEMPLO 6: Lista de Opções Admin
// ============================================

class AdminOptionsListView extends StatelessWidget {
  const AdminOptionsListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Opções de Administrador'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Card de Certificações (destaque)
          CompactAdminCertificationsMenuItem(isAdmin: true),

          const SizedBox(height: 16),

          // Outras opções
          _buildOptionCard(
            icon: Icons.people,
            title: 'Gerenciar Usuários',
            subtitle: 'Visualizar e editar usuários',
            color: Colors.blue,
            onTap: () {},
          ),

          const SizedBox(height: 12),

          _buildOptionCard(
            icon: Icons.report,
            title: 'Denúncias',
            subtitle: 'Revisar denúncias de usuários',
            color: Colors.red,
            onTap: () {},
          ),

          const SizedBox(height: 12),

          _buildOptionCard(
            icon: Icons.analytics,
            title: 'Estatísticas',
            subtitle: 'Ver métricas e relatórios',
            color: Colors.green,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
