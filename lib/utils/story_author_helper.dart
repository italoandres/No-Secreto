import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StoryAuthorHelper {
  // Adicionar campo de autor a um story existente
  static Future<void> addAuthorToStory(String storyId, String authorId) async {
    try {
      // Tentar atualizar em stories_files primeiro
      try {
        await FirebaseFirestore.instance
            .collection('stories_files')
            .doc(storyId)
            .update({'authorId': authorId});
        print('Autor adicionado ao story $storyId em stories_files');
        return;
      } catch (e) {
        // Se não encontrar em stories_files, tentar em outras coleções
      }
      
      // Tentar em stories_sinais_isaque
      try {
        await FirebaseFirestore.instance
            .collection('stories_sinais_isaque')
            .doc(storyId)
            .update({'authorId': authorId});
        print('Autor adicionado ao story $storyId em stories_sinais_isaque');
        return;
      } catch (e) {
        // Se não encontrar, tentar próxima coleção
      }
      
      // Tentar em stories_sinais_rebeca
      try {
        await FirebaseFirestore.instance
            .collection('stories_sinais_rebeca')
            .doc(storyId)
            .update({'authorId': authorId});
        print('Autor adicionado ao story $storyId em stories_sinais_rebeca');
        return;
      } catch (e) {
        print('Story $storyId não encontrado em nenhuma coleção');
      }
    } catch (e) {
      print('Erro ao adicionar autor ao story: $e');
    }
  }
  
  // Obter ID do autor de um story
  static Future<String?> getStoryAuthorId(String storyId) async {
    try {
      // Tentar buscar em stories_files primeiro
      try {
        final doc = await FirebaseFirestore.instance
            .collection('stories_files')
            .doc(storyId)
            .get();
        
        if (doc.exists && doc.data()?['authorId'] != null) {
          return doc.data()!['authorId'] as String;
        }
      } catch (e) {
        // Continuar para próxima coleção
      }
      
      // Tentar em stories_sinais_isaque
      try {
        final doc = await FirebaseFirestore.instance
            .collection('stories_sinais_isaque')
            .doc(storyId)
            .get();
        
        if (doc.exists && doc.data()?['authorId'] != null) {
          return doc.data()!['authorId'] as String;
        }
      } catch (e) {
        // Continuar para próxima coleção
      }
      
      // Tentar em stories_sinais_rebeca
      try {
        final doc = await FirebaseFirestore.instance
            .collection('stories_sinais_rebeca')
            .doc(storyId)
            .get();
        
        if (doc.exists && doc.data()?['authorId'] != null) {
          return doc.data()!['authorId'] as String;
        }
      } catch (e) {
        // Story não encontrado
      }
      
      return null;
    } catch (e) {
      print('Erro ao buscar autor do story: $e');
      return null;
    }
  }
  
  // Marcar story atual como criado pelo usuário logado
  static Future<void> markCurrentUserAsAuthor(String storyId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      await addAuthorToStory(storyId, currentUser.uid);
    }
  }
}