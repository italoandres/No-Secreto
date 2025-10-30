class EmojiModel {
  String? codes;
  String? char;
  String? name;
  String? category;
  String? group;
  String? subgroup;

  EmojiModel({
    this.codes,
    this.char,
    this.name,
    this.category,
    this.group,
    this.subgroup,
  });

  static EmojiModel fromJson(Map<String, dynamic> json) {
    return EmojiModel(
      codes: json['codes'],
      char: json['char'],
      name: json['name'],
      category: json['category'],
      group: json['group'],
      subgroup: json['subgroup'],
    );
  }
}
