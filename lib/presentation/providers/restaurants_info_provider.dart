// lib/presentation/providers/restaurants_info_provider.dart

import 'package:flutter/material.dart';
import 'package:advertising_app/data/model/car_service_filter_models.dart'; // إعادة استخدام EmirateModel
import 'package:advertising_app/data/model/restaurant_models.dart';
import 'package:advertising_app/data/model/best_advertiser_model.dart';
import 'package:advertising_app/data/repository/restaurants_repository.dart';
import 'package:advertising_app/data/web_services/api_service.dart';

class RestaurantsInfoProvider extends ChangeNotifier {
  final RestaurantsRepository _repository;
  final ApiService _apiService; // لجلب بيانات الاتصال المشتركة

    RestaurantsInfoProvider()
      : _repository = RestaurantsRepository(ApiService()),
        _apiService = ApiService();

  // --- حالات التحميل والأخطاء ---
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  // --- قوائم البيانات ---
  List<RestaurantCategoryModel> _categories = [];
  List<EmirateModel> _emirates = [];
  final Map<String, List<String>> _emirateToDistrictsMap = {};
  
  // بيانات الاتصال المشتركة
  List<String> _advertiserNames = [];
  List<String> _phoneNumbers = [];
  List<String> _whatsappNumbers = [];
  
  // --- بيانات أفضل المعلنين ---
  bool _isLoadingTopRestaurants = false;
  List<BestAdvertiser> _topRestaurants = [];

  // --- Getters لتوفير البيانات للـ UI ---
  List<String> get categoryDisplayNames => _categories.map((e) => e.name).toList();
  List<String> get emirateDisplayNames => _emirates.map((e) => e.name).toList();
  List<String> getDistrictsForEmirate(String? emirateDisplayName) {
    if (emirateDisplayName == null) return [];
    final emirate = _emirates.firstWhere(
      (e) => e.name == emirateDisplayName,
      orElse: () => EmirateModel(name: '', displayName: '', districts: []),
    );
    return _emirateToDistrictsMap[emirate.name] ?? [];
  }
  
  List<String> get advertiserNames => _advertiserNames;
  List<String> get phoneNumbers => _phoneNumbers;
  List<String> get whatsappNumbers => _whatsappNumbers;
  
  // --- Getters لأفضل المعلنين ---
  bool get isLoadingTopRestaurants => _isLoadingTopRestaurants;
  List<BestAdvertiser> get topRestaurants => _topRestaurants;

  // --- دوال جلب البيانات ---
  Future<List<dynamic>> fetchRestaurants({
    required String token,
    String? emirate,
    String? district,
    String? category,
    String? priceFrom,
    String? priceTo,
  }) async {
    try {
      return await _repository.getRestaurants(
        token: token,
        emirate: emirate,
        district: district,
        category: category,
        priceFrom: priceFrom,
        priceTo: priceTo,
      );
    } catch (e) {
      throw e;
    }
  }

  Future<void> fetchAllData({required String token}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // جلب البيانات الخاصة بقسم المطاعم
      final fetchedCategories = await _repository.getRestaurantCategories(token: token);
      
      final fetchedEmirates = await _repository.getEmirates(token: token); // استخدام نفس الدالة
      
      _categories = fetchedCategories;
      _emirates = fetchedEmirates;
      _buildEmirateDistrictsMap();

      // جلب بيانات الاتصال المشتركة
      await fetchContactInfo(token: token);
      
    } catch (e) {
      _error = "Failed to load data: ${e.toString()}";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // (دالة مكررة ومشتركة)
  Future<void> fetchContactInfo({required String token}) async {
    try {
      final response = await _apiService.get('/api/contact-info', token: token);
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        _advertiserNames = data['advertiser_names'] != null ? List<String>.from(data['advertiser_names']) : [];
        _phoneNumbers = data['phone_numbers'] != null ? List<String>.from(data['phone_numbers']) : [];
        _whatsappNumbers = data['whatsapp_numbers'] != null ? List<String>.from(data['whatsapp_numbers']) : [];
      } else {
        throw Exception('API returned success: false or data is null');
      }
    } catch (e) {
      // Error fetching contact info
    }
  }

  // (دالة مكررة ومشتركة)
  Future<bool> addContactItem(String field, String value, {required String token}) async {
    try {
      final response = await _apiService.post('/api/contact-info/add-item', data: {'field': field, 'value': value}, token: token);
      if (response['success'] == true) {
        await fetchContactInfo(token: token);
        notifyListeners();
        return true;
      } else {
        throw Exception(response['message'] ?? 'API returned success: false');
      }
    } catch (e) {
       _error = e.toString();
       notifyListeners();
       return false;
    }
  }

  // --- دوال مساعدة ---
  void _buildEmirateDistrictsMap() {
    _emirateToDistrictsMap.clear();
    for (final emirate in _emirates) {
      _emirateToDistrictsMap[emirate.name] = emirate.districts;
    }
  }

  String? getCategoryNameFromDisplayName(String? displayName) {
    if (displayName == null) return null;
    try {
      return _categories.firstWhere((e) => e.name == displayName).name;
    } catch (e) {
      return null;
    }
  }

  String? getEmirateNameFromDisplayName(String? displayName) {
     if (displayName == null) return null;
    try {
      return _emirates.firstWhere((e) => e.name == displayName).name;
    } catch (e) {
      return null;
    }
  }
  
  // --- دالة جلب أفضل المعلنين ---
  Future<void> fetchTopRestaurants({required String token, String? category}) async {
    _isLoadingTopRestaurants = true;
    notifyListeners();
    
    try {
      final topRestaurants = await _repository.getTopRestaurants(
        token: token,
        category: null, // جلب جميع الفئات بدلاً من فلترة واحدة فقط
      );
      
      _topRestaurants = topRestaurants;
    } catch (e) {
      _topRestaurants = [];
    } finally {
      _isLoadingTopRestaurants = false;
      notifyListeners();
    }
  }
}