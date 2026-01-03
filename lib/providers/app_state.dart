import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/user.dart';
import '../models/nursery.dart';
import '../models/child.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';
import '../services/user_service_web.dart';
import '../services/nursery_service.dart';
import '../services/nursery_service_web.dart';
import '../services/child_service.dart';
import '../services/child_service_web.dart';

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
  List<Child> _children = [];
  List<Nursery> _nurseries = [];
  bool _isLoading = false;
  String? _errorMessage;

  final ChatService _chatService = ChatService();
  final UserService _userService = UserService();
  final UserServiceWeb _userServiceWeb = UserServiceWeb();
  final NurseryService _nurseryService = NurseryService();
  final NurseryServiceWeb _nurseryServiceWeb = NurseryServiceWeb();
  final ChildService _childService = ChildService();
  final ChildServiceWeb _childServiceWeb = ChildServiceWeb();

  ScreenType get currentScreen => _currentScreen;
  User? get user => _user;
  Nursery? get selectedNursery => _selectedNursery;
  List<Child> get children => _children;
  List<Nursery> get nurseries => _nurseries;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ChatService get chatService => _chatService;

  // Use web service for web platform, regular service for desktop/mobile
  dynamic get userService => kIsWeb ? _userServiceWeb : _userService;
  dynamic get nurseryService => kIsWeb ? _nurseryServiceWeb : _nurseryService;
  dynamic get childService => kIsWeb ? _childServiceWeb : _childService;

  int get unreadMessagesCount {
    if (_user == null) return 0;
    return _chatService.getTotalMessagesNonLus(_user!.id);
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  void setScreen(ScreenType screen) {
    _currentScreen = screen;
    notifyListeners();
  }

  Future<void> setUser(User user) async {
    _user = user;
    _errorMessage = null;

    // Load user data based on type
    if (user.type == UserType.parent) {
      _currentScreen = ScreenType.parentDashboard;
      await loadParentData();
    } else {
      // Check if nursery owner has nurseries
      try {
        print('🔍 Checking nurseries for owner: ${user.id}');
        final nurseries = await nurseryService.getNurseriesByOwner(user.id);
        print('📊 Found ${nurseries.length} nurseries');

        if (nurseries.isEmpty) {
          print('⚠️ No nurseries found, redirecting to setup');
          _currentScreen = ScreenType.nurserySetup;
        } else {
          print('✅ Nurseries found, redirecting to dashboard');
          _nurseries = nurseries;
          _currentScreen = ScreenType.nurseryDashboard;
        }
      } catch (e) {
        print('❌ Error checking nurseries: $e');
        // On error, assume no nurseries and go to setup
        _currentScreen = ScreenType.nurserySetup;
      }
    }
    notifyListeners();
  }

  Future<void> loadParentData() async {
    if (_user == null || _user!.type != UserType.parent) return;

    try {
      setLoading(true);
      _children = await _childService.getChildrenByParent(_user!.id);
      notifyListeners();
    } catch (e) {
      setError('Erreur lors du chargement des données: $e');
    } finally {
      setLoading(false);
    }
  }

  Future<void> loadNurseryData() async {
    if (_user == null || _user!.type != UserType.nursery) return;

    try {
      setLoading(true);
      _nurseries = await nurseryService.getNurseriesByOwner(_user!.id);
      notifyListeners();
    } catch (e) {
      setError('Erreur lors du chargement des garderies: $e');
    } finally {
      setLoading(false);
    }
  }

  Future<List<Nursery>> searchNurseries({
    String? city,
    double? maxPrice,
    int? minAvailableSpots,
    double? minRating,
  }) async {
    try {
      setLoading(true);
      setError(null);
      final results = await nurseryService.searchNurseries(
        city: city,
        maxPrice: maxPrice,
        minAvailableSpots: minAvailableSpots,
        minRating: minRating,
      );
      _nurseries = results;
      notifyListeners();
      return results;
    } catch (e) {
      setError('Erreur lors de la recherche: $e');
      return [];
    } finally {
      setLoading(false);
    }
  }

  Future<void> addChild(Child child) async {
    _children.add(child);
    notifyListeners();
  }

  void completeNurserySetup() {
    _currentScreen = ScreenType.nurseryDashboard;
    notifyListeners();
  }

  void logout() {
    _user = null;
    _children = [];
    _nurseries = [];
    _selectedNursery = null;
    _currentScreen = ScreenType.auth;
    notifyListeners();
  }

  void selectNursery(Nursery nursery) {
    _selectedNursery = nursery;
    _currentScreen = ScreenType.nurseryDetails;
    notifyListeners();
  }
}
