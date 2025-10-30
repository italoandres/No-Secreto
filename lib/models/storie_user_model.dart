class StorieUserModel {
  String? id;
  String? idStore;
  String? idUser;

  StorieUserModel({
    this.id,
    this.idStore,
    this.idUser,
  });

  static StorieUserModel fromJson(Map<String, dynamic> json) {
    return StorieUserModel(
      idStore: json['idStore'] ?? '',
      idUser: json['idUser'],
    );
  }

  static Map<String, dynamic> toJson(StorieUserModel item) {
    return {
      'idStore': item.idStore,
      'idUser': item.idUser,
    };
  }
}
