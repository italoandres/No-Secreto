import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TestOnboardingView extends StatelessWidget {
  const TestOnboardingView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Teste Onboarding Assets')),
      body: Column(
        children: [
          const Text('Testando GIFs do Onboarding:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          
          // Teste slide1.gif
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(border: Border.all()),
              child: Column(
                children: [
                  const Text('slide1.gif'),
                  Expanded(
                    child: Image.asset(
                      'lib/assets/onboarding/slide1.gif',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.red[100],
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error, color: Colors.red),
                                Text('ERRO: $error'),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Teste slide2.gif
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(border: Border.all()),
              child: Column(
                children: [
                  const Text('slide2.gif'),
                  Expanded(
                    child: Image.asset(
                      'lib/assets/onboarding/slide2.gif',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.red[100],
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error, color: Colors.red),
                                Text('ERRO: $error'),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Botão para testar se assets existem
          ElevatedButton(
            onPressed: () async {
              try {
                await rootBundle.load('lib/assets/onboarding/slide1.gif');
                print('✅ slide1.gif encontrado');
              } catch (e) {
                print('❌ slide1.gif NÃO encontrado: $e');
              }
              
              try {
                await rootBundle.load('lib/assets/onboarding/slide2.gif');
                print('✅ slide2.gif encontrado');
              } catch (e) {
                print('❌ slide2.gif NÃO encontrado: $e');
              }
            },
            child: const Text('Testar Assets'),
          ),
        ],
      ),
    );
  }
}