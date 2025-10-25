import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:whatsapp_chat/constants.dart';
import 'package:whatsapp_chat/locale/language.dart';

class ContatoView extends StatelessWidget {
  const ContatoView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        width: Get.width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset('lib/assets/img/logo.png', width: 170),
            const SizedBox(height: 32),
            Text(AppLanguage.lang('contatos'),
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const Text(Constants.appName,
                style: TextStyle(fontWeight: FontWeight.normal, fontSize: 13)),
            const SizedBox(height: 32),
            Container(
              width: Get.width * 0.9,
              constraints: const BoxConstraints(maxWidth: 320),
              margin: const EdgeInsets.only(bottom: 16),
              child: OutlinedButton(
                onPressed: () {
                  launchUrl(
                      Uri.parse(
                          'https://api.whatsapp.com/send?phone=5518996969640'),
                      mode: LaunchMode.externalApplication);
                },
                child: const ListTile(
                  title: Text('Whatsapp'),
                  trailing: Icon(Icons.keyboard_arrow_right),
                ),
              ),
            ),
            Container(
              width: Get.width * 0.9,
              constraints: const BoxConstraints(maxWidth: 320),
              margin: const EdgeInsets.only(bottom: 16),
              child: OutlinedButton(
                onPressed: () {
                  launchUrl(
                      Uri.parse(
                          'https://www.facebook.com/profile.php?id=100008297476709'),
                      mode: LaunchMode.externalApplication);
                },
                child: const ListTile(
                  title: Text('Facebook'),
                  trailing: Icon(Icons.keyboard_arrow_right),
                ),
              ),
            ),
            Container(
              width: Get.width * 0.9,
              constraints: const BoxConstraints(maxWidth: 320),
              margin: const EdgeInsets.only(bottom: 16),
              child: OutlinedButton(
                onPressed: () {
                  launchUrl(
                      Uri.parse('mailto:i.andressolucoesdigitais@gmail.com'),
                      mode: LaunchMode.externalApplication);
                },
                child: const ListTile(
                  title: Text('Email'),
                  trailing: Icon(Icons.keyboard_arrow_right),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
