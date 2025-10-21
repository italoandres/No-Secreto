class OnboardingModel {
  final String title;
  final String description;
  final String assetPath;
  final bool isVideo;

  OnboardingModel({
    required this.title,
    required this.description,
    required this.assetPath,
    this.isVideo = false,
  });
}