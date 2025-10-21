
class ProgressModel {
  String id;
  double progress;

  ProgressModel({
    required this.id,
    required this.progress,
  });

  static ProgressModel fromJson(Map<String, dynamic> json) {

    return ProgressModel(
      id: json['id'] ?? '',
      progress: double.parse('${json['progress']}'),
    );
  }
}