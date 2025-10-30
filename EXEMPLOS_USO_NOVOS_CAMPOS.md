# 💡 Exemplos de Uso - Novos Campos do Perfil

## 🎯 Como Usar os Novos Campos em Outras Partes do App

---

## 1. 🎨 Usar Cores por Gênero

### Em Qualquer Widget

```dart
import '../utils/gender_colors.dart';
import '../models/spiritual_profile_model.dart';

class MeuWidget extends StatelessWidget {
  final SpiritualProfileModel profile;
  
  @override
  Widget build(BuildContext context) {
    // Obter cor primária
    final primaryColor = GenderColors.getPrimaryColor(profile.gender);
    
    return Container(
      decoration: BoxDecoration(
        color: GenderColors.getBackgroundColor(profile.gender),
        border: Border.all(
          color: GenderColors.getBorderColor(profile.gender),
        ),
      ),
      child: Text(
        'Olá!',
        style: TextStyle(color: primaryColor),
      ),
    );
  }
}
```

### Em AppBar

```dart
AppBar(
  title: Text('Meu Perfil'),
  backgroundColor: GenderColors.getPrimaryColor(profile.gender),
)
```

### Em Botões

```dart
ElevatedButton(
  onPressed: () {},
  style: ElevatedButton.styleFrom(
    backgroundColor: GenderColors.getPrimaryColor(profile.gender),
  ),
  child: Text('Clique Aqui'),
)
```

---

## 2. 📍 Exibir Localização

### Mostrar Localização Completa

```dart
Text(
  profile.fullLocation ?? 'Localização não informada',
  style: TextStyle(fontSize: 16),
)
// Resultado: "Birigui - São Paulo"
```

### Mostrar Apenas Cidade

```dart
Text(
  profile.city ?? 'Cidade não informada',
  style: TextStyle(fontSize: 16),
)
// Resultado: "Birigui"
```

### Mostrar com Ícone

```dart
Row(
  children: [
    Icon(Icons.location_on, color: Colors.grey),
    SizedBox(width: 4),
    Text(profile.fullLocation ?? 'Não informado'),
  ],
)
```

### Card de Localização

```dart
Card(
  child: ListTile(
    leading: Icon(
      Icons.location_city,
      color: GenderColors.getPrimaryColor(profile.gender),
    ),
    title: Text('Localização'),
    subtitle: Text(profile.fullLocation ?? 'Não informada'),
  ),
)
```

---

## 3. 🌍 Exibir Idiomas

### Lista Simples

```dart
if (profile.languages != null && profile.languages!.isNotEmpty) {
  Text(
    'Idiomas: ${profile.languages!.join(", ")}',
    style: TextStyle(fontSize: 14),
  )
} else {
  Text('Nenhum idioma informado')
}
// Resultado: "Idiomas: Português, Inglês, Espanhol"
```

### Com Bandeiras

```dart
import '../utils/languages_data.dart';

Widget buildLanguagesWithFlags() {
  if (profile.languages == null || profile.languages!.isEmpty) {
    return Text('Nenhum idioma');
  }
  
  return Wrap(
    spacing: 8,
    children: profile.languages!.map((langName) {
      // Encontrar código do idioma
      final lang = LanguagesData.languages.firstWhere(
        (l) => l['name'] == langName,
        orElse: () => {'flag': '🌐', 'name': langName},
      );
      
      return Chip(
        avatar: Text(lang['flag']!),
        label: Text(lang['name']!),
      );
    }).toList(),
  );
}
```

### Card de Idiomas

```dart
Card(
  child: Padding(
    padding: EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.language, color: GenderColors.getPrimaryColor(profile.gender)),
            SizedBox(width: 8),
            Text(
              'Idiomas Falados',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        buildLanguagesWithFlags(),
      ],
    ),
  ),
)
```

---

## 4. 🔍 Filtrar Perfis por Localização

### Buscar por Estado

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

Future<List<SpiritualProfileModel>> buscarPorEstado(String estado) async {
  final snapshot = await FirebaseFirestore.instance
      .collection('spiritual_profiles')
      .where('state', isEqualTo: estado)
      .get();
  
  return snapshot.docs
      .map((doc) => SpiritualProfileModel.fromJson(doc.data()))
      .toList();
}

// Uso:
final perfis = await buscarPorEstado('São Paulo');
```

### Buscar por Cidade

```dart
Future<List<SpiritualProfileModel>> buscarPorCidade(String cidade) async {
  final snapshot = await FirebaseFirestore.instance
      .collection('spiritual_profiles')
      .where('city', isEqualTo: cidade)
      .get();
  
  return snapshot.docs
      .map((doc) => SpiritualProfileModel.fromJson(doc.data()))
      .toList();
}

// Uso:
final perfis = await buscarPorCidade('Birigui');
```

### Buscar por Estado E Cidade

```dart
Future<List<SpiritualProfileModel>> buscarPorEstadoECidade(
  String estado,
  String cidade,
) async {
  final snapshot = await FirebaseFirestore.instance
      .collection('spiritual_profiles')
      .where('state', isEqualTo: estado)
      .where('city', isEqualTo: cidade)
      .get();
  
  return snapshot.docs
      .map((doc) => SpiritualProfileModel.fromJson(doc.data()))
      .toList();
}
```

---

## 5. 🌍 Filtrar por Idiomas

### Buscar Quem Fala um Idioma Específico

```dart
Future<List<SpiritualProfileModel>> buscarPorIdioma(String idioma) async {
  final snapshot = await FirebaseFirestore.instance
      .collection('spiritual_profiles')
      .where('languages', arrayContains: idioma)
      .get();
  
  return snapshot.docs
      .map((doc) => SpiritualProfileModel.fromJson(doc.data()))
      .toList();
}

// Uso:
final perfis = await buscarPorIdioma('Inglês');
```

### Buscar Quem Fala Múltiplos Idiomas

```dart
Future<List<SpiritualProfileModel>> buscarPorMultiplosIdiomas(
  List<String> idiomas,
) async {
  final snapshot = await FirebaseFirestore.instance
      .collection('spiritual_profiles')
      .where('languages', arrayContainsAny: idiomas)
      .get();
  
  return snapshot.docs
      .map((doc) => SpiritualProfileModel.fromJson(doc.data()))
      .toList();
}

// Uso:
final perfis = await buscarPorMultiplosIdiomas(['Inglês', 'Espanhol']);
```

---

## 6. 📊 Estatísticas

### Contar Usuários por Estado

```dart
Future<Map<String, int>> contarUsuariosPorEstado() async {
  final snapshot = await FirebaseFirestore.instance
      .collection('spiritual_profiles')
      .get();
  
  final Map<String, int> contagem = {};
  
  for (var doc in snapshot.docs) {
    final profile = SpiritualProfileModel.fromJson(doc.data());
    final estado = profile.state ?? 'Não informado';
    contagem[estado] = (contagem[estado] ?? 0) + 1;
  }
  
  return contagem;
}

// Uso:
final stats = await contarUsuariosPorEstado();
// Resultado: {'São Paulo': 150, 'Rio de Janeiro': 80, ...}
```

### Idiomas Mais Falados

```dart
Future<Map<String, int>> idiomasMaisFalados() async {
  final snapshot = await FirebaseFirestore.instance
      .collection('spiritual_profiles')
      .get();
  
  final Map<String, int> contagem = {};
  
  for (var doc in snapshot.docs) {
    final profile = SpiritualProfileModel.fromJson(doc.data());
    if (profile.languages != null) {
      for (var idioma in profile.languages!) {
        contagem[idioma] = (contagem[idioma] ?? 0) + 1;
      }
    }
  }
  
  return contagem;
}

// Uso:
final stats = await idiomasMaisFalados();
// Resultado: {'Português': 500, 'Inglês': 200, 'Espanhol': 150, ...}
```

---

## 7. 🎯 Sugestões de Match

### Sugerir Perfis da Mesma Cidade

```dart
Future<List<SpiritualProfileModel>> sugerirPerfisMesmaCidade(
  SpiritualProfileModel meuPerfil,
) async {
  if (meuPerfil.city == null) return [];
  
  final snapshot = await FirebaseFirestore.instance
      .collection('spiritual_profiles')
      .where('city', isEqualTo: meuPerfil.city)
      .where('gender', isNotEqualTo: meuPerfil.gender) // Gênero oposto
      .limit(10)
      .get();
  
  return snapshot.docs
      .map((doc) => SpiritualProfileModel.fromJson(doc.data()))
      .where((p) => p.id != meuPerfil.id) // Excluir próprio perfil
      .toList();
}
```

### Sugerir Perfis com Idiomas em Comum

```dart
Future<List<SpiritualProfileModel>> sugerirPerfisIdiomasComum(
  SpiritualProfileModel meuPerfil,
) async {
  if (meuPerfil.languages == null || meuPerfil.languages!.isEmpty) {
    return [];
  }
  
  final snapshot = await FirebaseFirestore.instance
      .collection('spiritual_profiles')
      .where('languages', arrayContainsAny: meuPerfil.languages)
      .limit(20)
      .get();
  
  return snapshot.docs
      .map((doc) => SpiritualProfileModel.fromJson(doc.data()))
      .where((p) => p.id != meuPerfil.id)
      .toList();
}
```

---

## 8. 🎨 Componente de Perfil Completo

### Card de Perfil com Todos os Campos

```dart
import 'package:flutter/material.dart';
import '../models/spiritual_profile_model.dart';
import '../utils/gender_colors.dart';
import '../utils/languages_data.dart';

class ProfileInfoCard extends StatelessWidget {
  final SpiritualProfileModel profile;
  
  const ProfileInfoCard({required this.profile});
  
  @override
  Widget build(BuildContext context) {
    final primaryColor = GenderColors.getPrimaryColor(profile.gender);
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: GenderColors.getBorderColor(profile.gender),
          width: 2,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nome
            Text(
              profile.displayName ?? 'Usuário',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            
            SizedBox(height: 16),
            
            // Idade
            Row(
              children: [
                Icon(Icons.cake, color: primaryColor, size: 20),
                SizedBox(width: 8),
                Text('${profile.age ?? "?"} anos'),
              ],
            ),
            
            SizedBox(height: 8),
            
            // Localização
            Row(
              children: [
                Icon(Icons.location_on, color: primaryColor, size: 20),
                SizedBox(width: 8),
                Text(profile.fullLocation ?? 'Não informado'),
              ],
            ),
            
            SizedBox(height: 16),
            
            // Idiomas
            if (profile.languages != null && profile.languages!.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.language, color: primaryColor, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Idiomas',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: profile.languages!.map((langName) {
                  final lang = LanguagesData.languages.firstWhere(
                    (l) => l['name'] == langName,
                    orElse: () => {'flag': '🌐', 'name': langName},
                  );
                  
                  return Chip(
                    avatar: Text(lang['flag']!),
                    label: Text(lang['name']!),
                    backgroundColor: GenderColors.getBackgroundColor(profile.gender),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Uso:
ProfileInfoCard(profile: meuPerfil)
```

---

## 9. 🔧 Validações Úteis

### Verificar se Perfil Está Completo

```dart
bool perfilEstaCompleto(SpiritualProfileModel profile) {
  return profile.country != null &&
         profile.state != null &&
         profile.city != null &&
         profile.languages != null &&
         profile.languages!.isNotEmpty &&
         profile.age != null;
}
```

### Calcular Porcentagem de Preenchimento

```dart
double calcularPorcentagemPreenchimento(SpiritualProfileModel profile) {
  int camposPreenchidos = 0;
  int totalCampos = 5;
  
  if (profile.country != null) camposPreenchidos++;
  if (profile.state != null) camposPreenchidos++;
  if (profile.city != null) camposPreenchidos++;
  if (profile.languages != null && profile.languages!.isNotEmpty) camposPreenchidos++;
  if (profile.age != null) camposPreenchidos++;
  
  return (camposPreenchidos / totalCampos) * 100;
}

// Uso:
final porcentagem = calcularPorcentagemPreenchimento(profile);
// Resultado: 80.0 (se 4 de 5 campos preenchidos)
```

---

## 10. 📱 Tela de Visualização de Perfil

### Exemplo Completo

```dart
import 'package:flutter/material.dart';
import '../models/spiritual_profile_model.dart';
import '../utils/gender_colors.dart';
import '../utils/languages_data.dart';

class ProfileViewScreen extends StatelessWidget {
  final SpiritualProfileModel profile;
  
  const ProfileViewScreen({required this.profile});
  
  @override
  Widget build(BuildContext context) {
    final primaryColor = GenderColors.getPrimaryColor(profile.gender);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Perfil'),
        backgroundColor: primaryColor,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Foto e Nome
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: primaryColor,
                    backgroundImage: profile.mainPhotoUrl != null
                        ? NetworkImage(profile.mainPhotoUrl!)
                        : null,
                    child: profile.mainPhotoUrl == null
                        ? Icon(Icons.person, size: 60, color: Colors.white)
                        : null,
                  ),
                  SizedBox(height: 16),
                  Text(
                    profile.displayName ?? 'Usuário',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 32),
            
            // Informações Básicas
            _buildSection(
              'Informações Básicas',
              primaryColor,
              [
                _buildInfoRow(Icons.cake, 'Idade', '${profile.age ?? "?"} anos'),
                _buildInfoRow(Icons.location_on, 'Localização', profile.fullLocation ?? 'Não informado'),
              ],
            ),
            
            SizedBox(height: 24),
            
            // Idiomas
            if (profile.languages != null && profile.languages!.isNotEmpty)
              _buildSection(
                'Idiomas Falados',
                primaryColor,
                [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: profile.languages!.map((langName) {
                      final lang = LanguagesData.languages.firstWhere(
                        (l) => l['name'] == langName,
                        orElse: () => {'flag': '🌐', 'name': langName},
                      );
                      
                      return Chip(
                        avatar: Text(lang['flag']!),
                        label: Text(lang['name']!),
                        backgroundColor: GenderColors.getBackgroundColor(profile.gender),
                      );
                    }).toList(),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSection(String title, Color color, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 12),
        ...children,
      ],
    );
  }
  
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## 🎉 Pronto!

Agora você tem exemplos práticos de como usar todos os novos campos em diferentes partes do seu app!

