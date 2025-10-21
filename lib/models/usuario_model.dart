
import 'package:cloud_firestore/cloud_firestore.dart';

class UsuarioModel {
  String? id;
  String? imgUrl;
  String? imgBgUrl;
  String? nome;
  String? email;
  bool? perfilIsComplete;
  Timestamp? dataCadastro;
  bool? isAdmin;
  bool? senhaIsSeted;
  UserSexo? sexo;
  String? username; // Username único com @
  List<String>? usernameHistory; // Histórico de usernames
  Timestamp? usernameChangedAt; // Última mudança de username
  DateTime? lastSyncAt; // Última sincronização com spiritual_profile

  UsuarioModel({
    this.id,
    this.imgUrl,
    this.imgBgUrl,
    this.nome,
    this.email,
    this.perfilIsComplete,
    this.dataCadastro,
    this.isAdmin,
    this.senhaIsSeted,
    this.sexo,
    this.username,
    this.usernameHistory,
    this.usernameChangedAt,
    this.lastSyncAt,
  });

  static UsuarioModel fromJson(Map<String, dynamic> json) {
    return UsuarioModel(
      id: json['id'],
      imgUrl: json['imgUrl'],
      imgBgUrl: json['imgBgUrl'],
      nome: json['nome'] ?? 'Aluno',
      email: json['email'] ?? '--',
      perfilIsComplete: json['perfilIsComplete'] ?? false,
      dataCadastro: json['dataCadastro'],
      isAdmin: json['isAdmin'] ?? false,
      senhaIsSeted: json['senhaIsSeted'] ?? false,
      sexo: json['sexo'] == null ? UserSexo.none : UserSexo.values.byName(json['sexo']),
      username: json['username'],
      usernameHistory: json['usernameHistory'] != null 
          ? List<String>.from(json['usernameHistory']) 
          : null,
      usernameChangedAt: json['usernameChangedAt'],
      lastSyncAt: json['lastSyncAt'] != null 
          ? (json['lastSyncAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imgUrl': imgUrl,
      'imgBgUrl': imgBgUrl,
      'nome': nome,
      'email': email,
      'perfilIsComplete': perfilIsComplete,
      'dataCadastro': dataCadastro,
      'isAdmin': isAdmin,
      'senhaIsSeted': senhaIsSeted,
      'sexo': sexo?.name,
      'username': username,
      'usernameHistory': usernameHistory,
      'usernameChangedAt': usernameChangedAt,
      'lastSyncAt': lastSyncAt != null ? Timestamp.fromDate(lastSyncAt!) : null,
    };
  }
}

enum UserSexo {
  masculino,
  feminino,
  none,
}