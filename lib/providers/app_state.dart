import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/nursery.dart';
import '../services/chat_service.dart';

enum ScreenType {
  welcome,
  auth,
  parentDashboard,
  nurseryDashboard,
  nurserySetup,
  search,
  nurseryDetails,
}

class AppState extends ChangeNotifier {
  ScreenType _currentScreen = ScreenType.auth;
  User? _user;
  Nursery? _selectedNursery;
  final ChatService _chatService = ChatService();

  ScreenType get currentScreen => _currentScreen;
  User? get user => _user;
  Nursery? get selectedNursery => _selectedNursery;
  ChatService get chatService => _chatService;

  int get unreadMessagesCount {
    if (_user == null) return 0;
    return _chatService.getTotalMessagesNonLus(_user!.id);
  }

  void setScreen(ScreenType screen) {
    _currentScreen = screen;
    notifyListeners();
  }

  void setUser(User user) {
    _user = user;
    if (user.type == UserType.parent) {
      _currentScreen = ScreenType.parentDashboard;
    } else {
      // Nursery users go to setup screen first
      _currentScreen = ScreenType.nurserySetup;
    }
    notifyListeners();
  }

  void completeNurserySetup() {
    _currentScreen = ScreenType.nurseryDashboard;
    notifyListeners();
  }

  void logout() {
    _user = null;
    _currentScreen = ScreenType.auth;
    notifyListeners();
  }

  void selectNursery(Nursery nursery) {
    _selectedNursery = nursery;
    _currentScreen = ScreenType.nurseryDetails;
    notifyListeners();
  }
}
