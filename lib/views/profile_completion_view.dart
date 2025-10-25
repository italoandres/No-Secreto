import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/profile_completion_controller.dart';
import '../models/spiritual_profile_model.dart';
import '../models/usuario_model.dart';
import '../repositories/usuario_repository.dart';
import '../components/username_editor_component.dart';
import '../components/sync_status_indicator.dart';
import '../services/ui_state_manager.dart';
// REMOVIDO: import '../utils/test_profile_completion.dart'; (arquivo deletado)
import '../utils/enhanced_logger.dart';
import '../utils/vitrine_navigation_helper.dart';
import '../utils/certification_status_helper.dart';
import '../locale/language.dart';

class ProfileCompletionView extends StatelessWidget {
  const ProfileCompletionView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProfileCompletionController());

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          '✨ Vitrine de Propósito',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[700],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Carregando seu perfil...'),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeHeader(controller),
              const SizedBox(height: 24),
              _buildUserProfileSection(controller),
              const SizedBox(height: 24),
              _buildProgressSection(controller),
              const SizedBox(height: 32),
              _buildTasksList(controller),
              // Seção condicional baseado no status do perfil
              Obx(() {
                final isComplete = controller.profile.value?.isProfileComplete == true;
                if (isComplete) {
                  // Seção para perfis completos
                  return Column(
                    children: [
                      const SizedBox(height: 16),
                      _buildCompletedProfileSection(controller),
                    ],
                  );
                }
                // Se não estiver completo, não mostra nada
                return const SizedBox.shrink();
              }),
              const SizedBox(height: 32),
              _buildSpiritualGuidance(),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildWelcomeHeader(ProfileCompletionController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[700]!, Colors.blue[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info section
          FutureBuilder<UsuarioModel?>(
            future: UsuarioRepository.getUser().first,
            builder: (context, snapshot) {
              final user = snapshot.data;
              debugPrint('🔍 DEBUG: User data - Nome: ${user?.nome}, Username: ${user?.username}');
              
              return Row(
                children: [
                  // User photo or default avatar
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    backgroundImage: (controller.profile.value?.mainPhotoUrl?.isNotEmpty ?? false)
                        ? NetworkImage(controller.profile.value!.mainPhotoUrl!)
                        : (user?.imgUrl?.isNotEmpty ?? false)
                            ? NetworkImage(user!.imgUrl!)
                            : null,
                    child: (controller.profile.value?.mainPhotoUrl?.isEmpty ?? true) && 
                           (user?.imgUrl?.isEmpty ?? true)
                        ? const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 32,
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.nome ?? 'Usuário',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (user?.username != null && user!.username!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            '@${user.username}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          'Complete seu perfil espiritual para conexões autênticas',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Sync button
                  IconButton(
                    onPressed: () => controller.syncUserData(),
                    icon: const Icon(
                      Icons.sync,
                      color: Colors.white,
                      size: 24,
                    ),
                    tooltip: 'Sincronizar dados do perfil',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(ProfileCompletionController controller) {
    final progress = controller.profile.value?.completionPercentage ?? 0.0;
    final isComplete = controller.profile.value?.isProfileComplete ?? false;
    final userId = controller.profile.value?.userId;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'Progresso de Conclusão',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // Ícone de verificação - Dourado se aprovado, cinza se não
                  const SizedBox(width: 8),
                  if (userId != null)
                    FutureBuilder<bool>(
                      future: CertificationStatusHelper.hasApprovedCertification(userId),
                      builder: (context, snapshot) {
                        final hasApproved = snapshot.data ?? false;
                        return Tooltip(
                          message: hasApproved 
                              ? 'Certificação Espiritual Aprovada' 
                              : 'Certificação Espiritual (Opcional)',
                          child: Icon(
                            Icons.verified,
                            color: hasApproved 
                                ? Colors.amber[700]  // 🟡 Dourado quando aprovado
                                : Colors.grey[400],   // ⚪ Cinza quando não aprovado
                            size: 24,
                          ),
                        );
                      },
                    ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isComplete ? Colors.green[100] : Colors.orange[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isComplete ? 'Completo' : '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    color: isComplete ? Colors.green[700] : Colors.orange[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              isComplete ? Colors.green : Colors.blue,
            ),
            minHeight: 8,
          ),
          const SizedBox(height: 12),
          if (isComplete)
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Perfil completo! Outros usuários podem ver sua vitrine.',
                  style: TextStyle(
                    color: Colors.green[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            )
          else
            Text(
              'Complete todas as tarefas para ativar sua vitrine pública',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTasksList(ProfileCompletionController controller) {
    final tasks = [
      {
        'key': 'photos',
        'title': '📸 Fotos do Perfil',
        'subtitle': 'Adicione sua foto principal (obrigatória) e até 2 secundárias',
        'icon': Icons.photo_camera,
        'color': Colors.purple,
      },
      {
        'key': 'identity',
        'title': '🏠 Identidade Espiritual',
        'subtitle': 'Informe sua cidade e idade',
        'icon': Icons.location_on,
        'color': Colors.blue,
      },
      {
        'key': 'biography',
        'title': '✍️ Biografia Espiritual',
        'subtitle': 'Responda perguntas sobre sua fé e propósito',
        'icon': Icons.edit_note,
        'color': Colors.green,
      },
      {
        'key': 'preferences',
        'title': '⚙️ Preferências de Interação',
        'subtitle': 'Configure como outros podem interagir com você',
        'icon': Icons.settings,
        'color': Colors.orange,
      },
      {
        'key': 'certification',
        'title': '🏆 Certificação Espiritual',
        'subtitle': 'Adicione seu selo "Preparado(a) para os Sinais" (opcional)',
        'icon': Icons.verified,
        'color': Colors.amber,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tarefas de Conclusão',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...tasks.map((task) {
          final taskKey = task['key'] as String;
          // Tratamento especial para certificação
          if (taskKey == 'certification') {
            return _buildCertificationTaskCard(
              controller,
              task['title'] as String,
              task['subtitle'] as String,
              task['icon'] as IconData,
              task['color'] as Color,
            );
          }
          return _buildTaskCard(
            controller,
            taskKey,
            task['title'] as String,
            task['subtitle'] as String,
            task['icon'] as IconData,
            task['color'] as Color,
          );
        }),
      ],
    );
  }

  /// Card especial para certificação com status dinâmico
  Widget _buildCertificationTaskCard(
    ProfileCompletionController controller,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    final userId = controller.profile.value?.userId;
    
    if (userId == null) {
      return _buildTaskCard(controller, 'certification', title, subtitle, icon, color);
    }

    return FutureBuilder<String>(
      future: CertificationStatusHelper.getCertificationDisplayStatus(userId),
      builder: (context, snapshot) {
        final status = snapshot.data ?? 'Destaque seu Perfil';
        final isApproved = status == 'Aprovado';
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            elevation: 2,
            shadowColor: Colors.grey.withOpacity(0.1),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => controller.openTask('certification'),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isApproved ? Colors.green[100] : color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isApproved ? Icons.check_circle : icon,
                        color: isApproved ? Colors.green[600] : color,
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
                              color: isApproved ? Colors.green[700] : Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isApproved ? Colors.green[100] : Colors.amber[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: isApproved ? Colors.green[700] : Colors.amber[700],
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.grey[400],
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTaskCard(
    ProfileCompletionController controller,
    String taskKey,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    final isCompleted = controller.profile.value?.completionTasks[taskKey] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: Colors.grey.withOpacity(0.1),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => controller.openTask(taskKey),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isCompleted ? Colors.green[100] : color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isCompleted ? Icons.check_circle : icon,
                    color: isCompleted ? Colors.green[600] : color,
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
                          color: isCompleted ? Colors.green[700] : Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isCompleted ? Colors.green[100] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isCompleted ? 'Concluído' : 'Pendente',
                    style: TextStyle(
                      color: isCompleted ? Colors.green[700] : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[400],
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpiritualGuidance() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber[100]!, Colors.orange[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: Colors.amber[700],
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Orientação Espiritual',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '• Mantenha suas fotos com "olhar de propósito", não sensualidade\n'
            '• Seja autêntico em suas respostas sobre fé e valores\n'
            '• Lembre-se: este é um terreno sagrado para conexões espirituais\n'
            '• Seu perfil será uma vitrine do seu coração para Deus',
            style: TextStyle(
              fontSize: 14,
              color: Colors.amber[800],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfileSection(ProfileCompletionController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_outline,
                color: Colors.blue[700],
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Informações do Perfil',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (controller.profile.value?.userId != null)
                SyncStatusIndicator(
                  status: SyncStatus.success,
                  isLoading: false,
                  showText: true,
                ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Username Editor
          FutureBuilder<UsuarioModel?>(
            future: controller.getCurrentUserData(),
            builder: (context, snapshot) {
              final user = snapshot.data;
              
              if (user == null) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.hourglass_empty, color: Colors.grey),
                      SizedBox(width: 12),
                      Text('Carregando informações do usuário...'),
                    ],
                  ),
                );
              }
              
              return UsernameEditorComponent(
                userId: user.id!,
                currentUsername: user.username,
                onUsernameChanged: (newUsername) {
                  // Refresh profile after username change
                  controller.refreshProfile();
                },
                showSuggestions: true,
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          // Display Name (read-only, synced from "Editar Perfil")
          FutureBuilder<UsuarioModel?>(
            future: controller.getCurrentUserData(),
            builder: (context, snapshot) {
              final user = snapshot.data;
              
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.badge_outlined,
                      color: Colors.grey[600],
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Nome de Exibição',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.nome ?? 'Nome não definido',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Text(
                        'Sincronizado',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          
          const SizedBox(height: 12),
          
          // Info about sync
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.blue[600],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Seu nome e foto são sincronizados automaticamente com "Editar Perfil"',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
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

  /// Seção para perfis completos
  Widget _buildCompletedProfileSection(ProfileCompletionController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.celebration, color: Colors.green[600], size: 24),
              const SizedBox(width: 8),
              Text(
                'Perfil Completo!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Parabéns! Seu perfil está 100% completo e sua vitrine de propósito está ativa. Outros usuários já podem conhecer você através da sua vitrine.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.green[700],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _forceShowVitrineConfirmation(controller),
              icon: const Icon(Icons.visibility),
              label: const Text('Ver Minha Vitrine de Propósito'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }



  /// Força a exibição da confirmação da vitrine
  Future<void> _forceShowVitrineConfirmation(ProfileCompletionController controller) async {
    // Usar o método do controller para navegar diretamente
    await controller.forceNavigateToVitrine();
  }
}