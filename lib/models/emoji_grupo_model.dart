class EmojiGrupoModel {
  String? en;
  String? pt;
  String? imgAssets;

  EmojiGrupoModel({
    this.en,
    this.pt,
    this.imgAssets,
  });

  static EmojiGrupoModel fromJson(Map<String, dynamic> json) {
    return EmojiGrupoModel(
      en: json['en'],
      pt: json['pt'],
      imgAssets: json['img_assets'],
    );
  }
}
