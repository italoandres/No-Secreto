
import 'package:cloud_firestore/cloud_firestore.dart';
import 'storie_file_model.dart';

class StorieModel {
  String? id;
  String? titulo;
  List<StorieFileModel>? listFiles;
  bool? isPublic;
  String? imgCapa;
  Timestamp? dataCadastro;

  StorieModel({
    this.id,
    this.titulo,
    this.listFiles,
    this.isPublic,
    this.imgCapa,
    this.dataCadastro,
  });

  static StorieModel fromJson(Map<String, dynamic> json) {

    List<StorieFileModel> all = [];

    if(json['listFiles'] != null) {
      for (var element in json['listFiles']) {
        all.add(StorieFileModel.fromJson(element));
      }
    }

    return StorieModel(
      id: json['id'],
      titulo: json['titulo'],
      listFiles: all,
      isPublic: json['status'],
      imgCapa: json['imgCapa'] ?? '',
      dataCadastro: json['dataCadastro'],
    );
  }
}