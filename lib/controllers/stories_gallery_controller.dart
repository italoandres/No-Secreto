import 'package:get/get.dart';

class StoriesGalleryController extends GetxController {
  static StoriesGalleryController get instance => Get.find<StoriesGalleryController>();
  
  // Observable para forçar refresh da galeria
  final RxBool _refreshTrigger = false.obs;
  
  bool get refreshTrigger => _refreshTrigger.value;
  
  // Notificar que um novo story foi adicionado
  void notifyStoryAdded(String contexto) {
    _refreshTrigger.toggle();
    
    // Log para debug
    print('StoriesGalleryController: Story adicionado no contexto $contexto');
  }
  
  // Notificar que um story foi deletado
  void notifyStoryDeleted(String contexto) {
    _refreshTrigger.toggle();
    
    // Log para debug
    print('StoriesGalleryController: Story deletado no contexto $contexto');
  }
  
  // Forçar refresh manual
  void forceRefresh() {
    _refreshTrigger.toggle();
  }
}