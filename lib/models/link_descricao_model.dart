class LinkDescricaoModel {
  String titulo;
  String descricao;
  String? imgUrl;
  String? link;

  LinkDescricaoModel({
    required this.titulo,
    required this.descricao,
    this.imgUrl,
    this.link,
  });

  static LinkDescricaoModel fromJson(Map<String, dynamic> json) {
    return LinkDescricaoModel(
      titulo: json['titulo'],
      descricao: json['descricao'],
      imgUrl: json['imgUrl'],
      link: json['link'],
    );
  }

  static Map<String, dynamic> toJson(LinkDescricaoModel item) {
    return {
      'titulo': item.titulo,
      'descricao': item.descricao,
      'imgUrl': item.imgUrl,
      'link': item.link,
    };
  }
}
