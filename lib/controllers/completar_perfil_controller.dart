import 'dart:typed_data';

import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class CompletarPerfilController {
  static final imgPath = ''.obs;
  static Uint8List? imgData;
  static final imgBgPath = ''.obs;
  static Uint8List? imgBgData;

  static changeImg() async {
    final ImagePicker picker = ImagePicker();
    
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 300
    );
    if(image != null) {
      imgData = await image.readAsBytes();
      imgPath.value = image.path;
    }
  }

  static changeImgBg() async {
    final ImagePicker picker = ImagePicker();
    
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024
    );
    if(image != null) {
      imgBgData = await image.readAsBytes();
      imgBgPath.value = image.path;
    }
  }
}