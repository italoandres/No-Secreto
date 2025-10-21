
import 'package:flutter/material.dart';
import 'package:whatsapp_chat/views/contato_view.dart';
import 'package:whatsapp_chat/views/vitrine_confirmation_view.dart';
import 'package:whatsapp_chat/views/enhanced_vitrine_display_view.dart';
import 'package:whatsapp_chat/views/sinais_profile_detail_view.dart';
import 'package:whatsapp_chat/views/vitrine_proposito_menu_view.dart';
import 'package:whatsapp_chat/views/search_profile_by_username_view.dart';
import 'package:whatsapp_chat/views/edit_profile_menu_view.dart';
import 'package:whatsapp_chat/views/store_menu_view.dart';

class PageRoutes {
  static const String initialRoute = '/';
  static const String contato = '/contato';
  static const String vitrineConfirmation = '/vitrine-confirmation';
  static const String vitrineDisplay = '/vitrine-display';
  static const String sinaisProfileDetail = '/sinais-profile-detail';
  static const String vitrinePropositoMenu = '/vitrine-proposito-menu';
  static const String searchProfileByUsername = '/search-profile-by-username';
  static const String editProfileMenu = '/edit-profile-menu';
  static const String storeMenu = '/store-menu';

  static Widget getPageFromString(String page) {
    final pages = {
      contato: const ContatoView(),
      vitrineConfirmation: const VitrineConfirmationView(),
      vitrineDisplay: const EnhancedVitrineDisplayView(),
      sinaisProfileDetail: const SinaisProfileDetailView(),
      vitrinePropositoMenu: const VitrinePropositoMenuView(),
      searchProfileByUsername: const SearchProfileByUsernameView(),
      editProfileMenu: const EditProfileMenuView(),
      storeMenu: const StoreMenuView(),
    };

    return (pages[page] ?? Container(
      color: Colors.black,
      child: Center(child: Image.asset('lib/assets/img/icon.png', width: 320))
    ));
  }
}