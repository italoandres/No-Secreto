
import 'package:cloud_firestore/cloud_firestore.dart';

class StorieVistoModel {
  String? id;
  String? idStore;
  String? idUser;
  Timestamp? data;
  String? contexto; // 'principal', 'sinais_isaque', etc.

  StorieVistoModel({
    this.id,
    this.idStore,
    this.idUser,
    this.data,
    this.contexto,
  });

  static StorieVistoModel fromJson(Map<String, dynamic> json) {

    return StorieVistoModel(
      idStore: json['idStore'] ?? '',
      idUser: json['idUser'],
      data: json['data'],
      contexto: json['contexto'] ?? 'principal', // Default para contexto principal
    );
  }

  static Map<String, dynamic> toJson(StorieVistoModel item) {
    return {
      'idStore': item.idStore,
      'idUser': item.idUser,
      'data': item.data,
      'contexto': item.contexto ?? 'principal',
    };
  }
}