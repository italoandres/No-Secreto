import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../views/privacy_policy_view.dart';
import '../views/terms_conditions_view.dart';

class TermsAcceptanceWidget extends StatelessWidget {
  final RxBool termsAccepted;
  final RxBool privacyAccepted;

  const TermsAcceptanceWidget({
    Key? key,
    required this.termsAccepted,
    required this.privacyAccepted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          // Título
          Row(
            children: [
              Icon(Icons.security, color: Colors.blue[600], size: 20),
              const SizedBox(width: 8),
              Text(
                'Aceite os termos para continuar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Checkbox Termos e Condições
          Obx(() => InkWell(
            onTap: () => termsAccepted.value = !termsAccepted.value,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: termsAccepted.value,
                      onChanged: (value) => termsAccepted.value = value ?? false,
                      activeColor: Colors.green[600],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.4,
                        ),
                        children: [
                          const TextSpan(text: 'Eu li e aceito os '),
                          WidgetSpan(
                            child: GestureDetector(
                              onTap: () => Get.to(() => const TermsConditionsView()),
                              child: Text(
                                'Termos e Condições',
                                style: TextStyle(
                                  color: Colors.blue[600],
                                  fontWeight: FontWeight.w500,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                          const TextSpan(text: ' do aplicativo.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )),
          
          const SizedBox(height: 8),
          
          // Checkbox Política de Privacidade
          Obx(() => InkWell(
            onTap: () => privacyAccepted.value = !privacyAccepted.value,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: privacyAccepted.value,
                      onChanged: (value) => privacyAccepted.value = value ?? false,
                      activeColor: Colors.green[600],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.4,
                        ),
                        children: [
                          const TextSpan(text: 'Eu li e aceito a '),
                          WidgetSpan(
                            child: GestureDetector(
                              onTap: () => Get.to(() => const PrivacyPolicyView()),
                              child: Text(
                                'Política de Privacidade',
                                style: TextStyle(
                                  color: Colors.blue[600],
                                  fontWeight: FontWeight.w500,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                          const TextSpan(text: ' do aplicativo.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )),
          
          const SizedBox(height: 12),
          
          // Status de validação
          Obx(() {
            bool allAccepted = termsAccepted.value && privacyAccepted.value;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: allAccepted ? Colors.green[50] : Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: allAccepted ? Colors.green[200]! : Colors.orange[200]!,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    allAccepted ? Icons.check_circle : Icons.info,
                    color: allAccepted ? Colors.green[600] : Colors.orange[600],
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      allAccepted 
                        ? 'Termos aceitos! Você pode prosseguir com o cadastro.'
                        : 'É necessário aceitar ambos os termos para continuar.',
                      style: TextStyle(
                        fontSize: 12,
                        color: allAccepted ? Colors.green[700] : Colors.orange[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}