import 'package:cloud_firestore/cloud_firestore.dart';

class UserData {
  final String userId;
  final String name;
  final String? displayName;
  final String? username;
  final String? photoUrl;
  final String? email;
  final DateTime? lastUpdated;
  final bool isActive;

  UserData({
    required this.userId,
    required this.name,
    this.displayName,
    this.username,
    this.photoUrl,
    this.email,
    this.lastUpdated,
    this.isActive = true,
  });

  factory UserData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserData(
      userId: doc.id,
      name: data['nome'] ?? data['name'] ?? '',
      displayName: data['displayName'] ?? data['nome'] ?? data['name'],
      username: data['username'],
      photoUrl: data['photoUrl'] ?? data['foto'],
      email: data['email'],
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate(),
      isActive: data['isActive'] ?? true,
    );
  }

  factory UserData.fallback(String userId) {
    return UserData(
      userId: userId,
      name: 'Usuário',
      displayName: 'Usuário',
      isActive: false,
    );
  }

  String getDisplayName() {
    if (displayName != null && displayName!.isNotEmpty) {
      return displayName!;
    }
    if (name.isNotEmpty) {
      return name;
    }
    if (username != null && username!.isNotEmpty) {
      return '@${username!}';
    }
    return 'Usuário';
  }

  String? getPhotoUrl() {
    return photoUrl;
  }

  bool hasValidData() {
    return name.isNotEmpty || (displayName != null && displayName!.isNotEmpty);
  }

  bool isExpired({Duration maxAge = const Duration(hours: 1)}) {
    if (lastUpdated == null) return true;
    return DateTime.now().difference(lastUpdated!) > maxAge;
  }

  UserData copyWith({
    String? userId,
    String? name,
    String? displayName,
    String? username,
    String? photoUrl,
    String? email,
    DateTime? lastUpdated,
    bool? isActive,
  }) {
    return UserData(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      photoUrl: photoUrl ?? this.photoUrl,
      email: email ?? this.email,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'UserData(userId: $userId, name: $name, displayName: $displayName)';
  }
}

/// Classe de compatibilidade para NotificationSyncManager
class UserDataModel {
  final String userId;
  final String displayName;
  final String? photoURL;
  final String? bio;
  final int? age;
  final String? city;

  UserDataModel({
    required this.userId,
    required this.displayName,
    this.photoURL,
    this.bio,
    this.age,
    this.city,
  });

  factory UserDataModel.fromUserData(UserData userData) {
    return UserDataModel(
      userId: userData.userId,
      displayName: userData.getDisplayName(),
      photoURL: userData.getPhotoUrl(),
    );
  }

  factory UserDataModel.fromFirestore(
      String userId, Map<String, dynamic> data) {
    return UserDataModel(
      userId: userId,
      displayName: data['displayName'] ?? data['nome'] ?? 'Usuário',
      photoURL: data['photoURL'] ?? data['foto'],
      bio: data['bio'],
      age: data['age'],
      city: data['city'],
    );
  }
}
