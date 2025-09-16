import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:advertising_app/data/model/restaurant_ad_model.dart';
import 'package:advertising_app/data/web_services/api_service.dart';

class RestaurantOffersProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // حالات العروض
  List<RestaurantAdModel> _offerAds = [];
  List<RestaurantAdModel> _allFetchedOfferAds = [];
  bool _isLoadingOffers = false;
  String? _offersError;

  // Getters
  List<RestaurantAdModel> get offerAds => _offerAds;
  bool get isLoadingOffers => _isLoadingOffers;
  String? get offersError => _offersError;

  // فلاتر العروض
  String? offerPriceFrom, offerPriceTo;
  List<String> _selectedCategories = [];
  List<String> _selectedDistricts = [];

  List<String> get selectedCategories => _selectedCategories;
  List<String> get selectedDistricts => _selectedDistricts;

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void safeNotifyListeners() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  // جلب عروض المطاعم من API
  Future<void> fetchOfferAds() async {
    _isLoadingOffers = true;
    _offersError = null;
    safeNotifyListeners();
    
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) throw Exception('Token not found');
      
      print('=== DEBUG: Fetching restaurant offers ===');
      print('Token: ${token?.substring(0, 20)}...');
      
      final response = await _apiService.get(
        '/api/offers-box/restaurant',
        token: token,
      );
      
      print('=== DEBUG: API Response ===');
      print('Response type: ${response.runtimeType}');
      
      // التعامل مع الاستجابة بناءً على نوعها
      List<dynamic> adsData;
      if (response is List) {
        // API يعيد List مباشرة
        adsData = response;
        print('Response is List with ${adsData.length} items');
      } else if (response is Map<String, dynamic>) {
        // API يعيد Map مع مفتاح data
        print('Response keys: ${response.keys.toList()}');
        print('Success: ${response['success']}');
        print('Data type: ${response['data']?.runtimeType}');
        
        if (response['success'] == true && response['data'] != null) {
          adsData = response['data'];
        } else {
          throw Exception(response['message'] ?? 'Failed to fetch offers');
        }
      } else {
        throw Exception('Unexpected response format: ${response.runtimeType}');
      }
      
      print('=== DEBUG: Processing ${adsData.length} ads ===');
      
      _allFetchedOfferAds = adsData
          .map((json) => RestaurantAdModel.fromJson(json))
          .toList();
      
      print('=== DEBUG: Parsed ${_allFetchedOfferAds.length} ads successfully ===');
      for (int i = 0; i < _allFetchedOfferAds.length && i < 3; i++) {
        final ad = _allFetchedOfferAds[i];
        print('Ad ${i + 1}: ID=${ad.id}, Title=${ad.title}, Category=${ad.category}, District=${ad.district}');
      }
      
      _performLocalOfferFilter();
    } catch (e) {
      print('=== DEBUG: Error fetching offers ===');
      print('Error: $e');
      _offersError = e.toString();
    } finally {
      _isLoadingOffers = false;
      safeNotifyListeners();
    }
  }

  // تطبيق الفلاتر المحلية
  void _performLocalOfferFilter() {
    print('=== DEBUG: Applying local filters ===');
    print('All fetched ads: ${_allFetchedOfferAds.length}');
    print('Selected categories: $_selectedCategories');
    print('Selected districts: $_selectedDistricts');
    print('Price from: $offerPriceFrom, to: $offerPriceTo');
    
    List<RestaurantAdModel> filteredList = List.from(_allFetchedOfferAds);
    print('Initial filtered list: ${filteredList.length}');
    
    // فلتر السعر
    final fromPrice = double.tryParse(offerPriceFrom?.replaceAll(',', '') ?? '');
    final toPrice = double.tryParse(offerPriceTo?.replaceAll(',', '') ?? '');
    if (fromPrice != null) {
      final beforeCount = filteredList.length;
      filteredList.retainWhere((ad) => 
          (double.tryParse(ad.priceRange.replaceAll(',', '')) ?? 0) >= fromPrice);
      print('After price from filter: ${filteredList.length} (was $beforeCount)');
    }
    if (toPrice != null) {
      final beforeCount = filteredList.length;
      filteredList.retainWhere((ad) => 
          (double.tryParse(ad.priceRange.replaceAll(',', '')) ?? 0) <= toPrice);
      print('After price to filter: ${filteredList.length} (was $beforeCount)');
    }
    
    // فلتر الفئات
    if (_selectedCategories.isNotEmpty) {
      final beforeCount = filteredList.length;
      filteredList.retainWhere((ad) => 
          _selectedCategories.contains(ad.category));
      print('After categories filter: ${filteredList.length} (was $beforeCount)');
    }
    
    // فلتر المناطق
    if (_selectedDistricts.isNotEmpty) {
      final beforeCount = filteredList.length;
      filteredList.retainWhere((ad) => 
          _selectedDistricts.contains(ad.district));
      print('After districts filter: ${filteredList.length} (was $beforeCount)');
    }
    
    _offerAds = filteredList;
    print('=== DEBUG: Final filtered ads: ${_offerAds.length} ===');
    safeNotifyListeners();
  }

  // تحديث فلتر السعر
  void updatePriceRangeForOffers(String? from, String? to) {
    offerPriceFrom = from;
    offerPriceTo = to;
    _performLocalOfferFilter();
  }

  // تحديث فلتر الفئات
  void updateCategoriesFilter(List<String> categories) {
    _selectedCategories = categories;
    _performLocalOfferFilter();
  }

  // تحديث فلتر المناطق
  void updateDistrictsFilter(List<String> districts) {
    _selectedDistricts = districts;
    _performLocalOfferFilter();
  }

  // إعادة تعيين الفلاتر
  void resetFilters() {
    offerPriceFrom = null;
    offerPriceTo = null;
    _selectedCategories.clear();
    _selectedDistricts.clear();
    _performLocalOfferFilter();
  }
}