import 'package:flutter/material.dart';
import 'package:advertising_app/data/model/favorite_item_interface_model.dart';
import 'package:advertising_app/data/model/ad_priority.dart';
import 'package:advertising_app/presentation/providers/restaurants_info_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class RestaurantAdProvider with ChangeNotifier {
  final RestaurantsInfoProvider _restaurantsInfoProvider;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  RestaurantAdProvider(this._restaurantsInfoProvider);
  
  // --- حالات التحميل والأخطاء ---
  bool _isLoadingAds = false;
  String? _loadAdsError;
  List<FavoriteItemInterface> _restaurantAds = [];
  List<dynamic> _rawRestaurantData = [];
  
  bool get isLoadingAds => _isLoadingAds;
  String? get loadAdsError => _loadAdsError;
  List<FavoriteItemInterface> get restaurantAds => _restaurantAds;
  
  // --- الفلاتر المحددة ---
  List<String> _selectedDistricts = [];
  List<String> _selectedCategories = [];
  String? _priceFrom, _priceTo;
  RangeValues? priceRange;
  
  // Price filter properties
  String? get priceFrom => _priceFrom;
  String? get priceTo => _priceTo;
  
  List<String> get selectedDistricts => _selectedDistricts;
  List<String> get selectedCategories => _selectedCategories;
 
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
  
  // --- دالة جلب البيانات من API ---
  Future<void> applyAndFetchAds({Map<String, String>? initialFilters}) async {
    _isLoadingAds = true;
    _loadAdsError = null;
    safeNotifyListeners();
    
    try {
      final token = await _storage.read(key: 'auth_token') ?? '';
      
      // جلب البيانات من API
      final restaurants = await _restaurantsInfoProvider.fetchRestaurants(
        token: token,
        emirate: 'All',
        district: _selectedDistricts.isEmpty ? 'All' : _selectedDistricts.first,
        category: _selectedCategories.isEmpty ? 'All' : _selectedCategories.first,
        priceFrom: _priceFrom,
        priceTo: _priceTo,
      );
      
      _rawRestaurantData = restaurants;
      
      // Debug: طباعة بيانات المطاعم الخام
      print('=== DEBUG: بيانات المطاعم الخام ===');
      print('عدد المطاعم المستلمة: ${restaurants.length}');
      for (int i = 0; i < restaurants.length && i < 3; i++) {
        final restaurant = restaurants[i];
        print('--- مطعم ${i + 1} ---');
        print('ID: ${restaurant['id']}');
        print('Title: ${restaurant['title']}');
        print('Main Image: ${restaurant['main_image']}');
        print('Emirate: ${restaurant['emirate']}');
        print('District: ${restaurant['district']}');
        print('Category: ${restaurant['category']}');
        print('Price Range: ${restaurant['price_range']}');
        print('Phone: ${restaurant['phone_number']}');
        print('Plan Type: ${restaurant['plan_type']}');
        print('Status: ${restaurant['add_status']}');
        print('Created At: ${restaurant['created_at']}');
        print('Raw Data: $restaurant');
        print('---');
      }
      print('=== نهاية DEBUG ===');
      
      // تحويل البيانات إلى FavoriteItemInterface
      _restaurantAds = _convertApiDataToFavoriteItems(restaurants);
      
      // Debug: طباعة البيانات المحولة
      print('=== DEBUG: البيانات المحولة ===');
      print('عدد المطاعم المحولة: ${_restaurantAds.length}');
      for (int i = 0; i < _restaurantAds.length && i < 3; i++) {
        final item = _restaurantAds[i];
        print('--- مطعم محول ${i + 1} ---');
        print('Title: ${item.title}');
        print('Images: ${item.images}');
        print('Location: ${item.location}');
        print('Price: ${item.price}');
        print('Details: ${item.details}');
        print('Contact: ${item.contact}');
        print('Is Premium: ${item.isPremium}');
        print('---');
      }
      print('=== نهاية DEBUG المحولة ===');
      
    } catch (e) {
      _loadAdsError = e.toString();
      _restaurantAds = [];
    } finally {
      _isLoadingAds = false;
      safeNotifyListeners();
    }
  }
  
  // --- تحويل البيانات من API إلى FavoriteItemInterface ---
  List<FavoriteItemInterface> _convertApiDataToFavoriteItems(List<dynamic> apiData) {
    const String baseUrl = 'https://dubaisale.app/storage/';
    
    return apiData.map((restaurant) {
      final planType = _nullToString(restaurant['plan_type']);
      
      // بناء رابط الصورة الرئيسية - إضافة timestamp لتجنب الكاش
      String mainImageUrl = 'nullnow';
      if (restaurant['main_image'] != null && restaurant['main_image'].toString().isNotEmpty) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        mainImageUrl = baseUrl + restaurant['main_image'].toString() + '?t=$timestamp';
      }
      
      // بناء قائمة الصور المصغرة - إضافة timestamp لتجنب الكاش
      List<String> thumbnailImages = ['nullnow'];
      if (restaurant['thumbnail_images'] != null && restaurant['thumbnail_images'] is List) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        thumbnailImages = (restaurant['thumbnail_images'] as List)
            .where((img) => img != null && img.toString().isNotEmpty)
            .map((img) => baseUrl + img.toString() + '?t=$timestamp')
            .toList();
        if (thumbnailImages.isEmpty) thumbnailImages = ['nullnow'];
      }
      
      // بناء نص الموقع من emirate/district/area
      String locationText = '';
      final emirate = restaurant['emirate']?.toString() ?? '';
      final district = restaurant['district']?.toString() ?? '';
      final area = restaurant['area']?.toString() ?? '';
      
      List<String> locationParts = [];
      if (emirate.isNotEmpty && emirate != 'null') locationParts.add(emirate);
      if (district.isNotEmpty && district != 'null') locationParts.add(district);
      if (area.isNotEmpty && area != 'null') locationParts.add(area);
      
      locationText = locationParts.isNotEmpty ? locationParts.join('/') : 'nullnow';
      
      return RestaurantAdItem(
        id: _nullToString(restaurant['id']),
        title: _nullToString(restaurant['title']),
        description: _nullToString(restaurant['description']),
        price: _nullToString(restaurant['price_range']),
        imageUrl: mainImageUrl,
        location: locationText,
        phoneNumber: _nullToString(restaurant['phone_number']),
        whatsapp: _nullToString(restaurant['whatsapp']),
        priority: _getPriorityFromPlanType(planType),
        createdAt: _nullToString(restaurant['created_at']),
        category: _nullToString(restaurant['category']),
        emirate: emirate.isNotEmpty ? emirate : 'nullnow',
        district: district.isNotEmpty ? district : 'nullnow',
        // الخصائص الإضافية المطلوبة
        contact: _nullToString(restaurant['advertiser_name']),
        date: _formatDateOnly(restaurant['created_at']),
        details: _nullToString(restaurant['category']),
        images: [mainImageUrl, ...thumbnailImages],
        isPremium: planType.toLowerCase().contains('premium'),
        line1: _nullToString(restaurant['title']),
      );
    }).toList();
  }
  
  // --- تحويل null إلى "nullnow" ---
  String _nullToString(dynamic value) {
    if (value == null) return 'nullnow';
    return value.toString();
  }
  
  // --- تنسيق التاريخ بدون الوقت ---
  String _formatDateOnly(dynamic dateValue) {
    if (dateValue == null) return 'nullnow';
    try {
      final dateTime = DateTime.parse(dateValue.toString());
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateValue.toString().split(' ').first; // fallback: أخذ الجزء الأول قبل المسافة
    }
  }
  
  // --- تحديد الأولوية من نوع الخطة ---
  AdPriority _getPriorityFromPlanType(String planType) {
    switch (planType.toLowerCase()) {
      case 'premium_star':
        return AdPriority.PremiumStar;
      case 'premium':
        return AdPriority.premium;
      case 'featured':
        return AdPriority.featured;
      default:
        return AdPriority.free;
    }
  }
  
  // --- تحديث الفلاتر ---
  void updateSelectedDistricts(List<String> districts) {
    _selectedDistricts = districts;
    safeNotifyListeners();
    // Apply filters immediately when districts change
    applyFilters(
      selectedDistricts: districts,
      selectedCategories: selectedCategories,
    );
  }
  
  void updateSelectedCategories(List<String> categories) {
    _selectedCategories = categories;
    safeNotifyListeners();
    // Apply filters immediately when categories change
    applyFilters(
      selectedDistricts: selectedDistricts,
      selectedCategories: categories,
    );
  }
  
  void updatePriceRange(String? from, String? to) {
    _priceFrom = from;
    _priceTo = to;
    safeNotifyListeners();
    // Apply filters immediately when price range changes
    applyFilters(
      selectedDistricts: selectedDistricts,
      selectedCategories: selectedCategories,
    );
  }
  
  // --- تطبيق الفلاتر ---
  Future<void> applyFilters({
    List<String>? selectedDistricts,
    List<String>? selectedCategories, String? district, String? category, String? emirate,
  }) async {
    _isLoadingAds = true;
    _loadAdsError = null;
    safeNotifyListeners();
    
    try {
      final token = await _storage.read(key: 'auth_token') ?? '';
      
      // تحديد القيم للفلاتر
      String districtValue = district ?? 'All';
      String categoryValue = category ?? 'All';
      String emirateValue = emirate ?? 'All';
      
      // إذا لم يتم تمرير المعاملات المباشرة، استخدم القوائم
      if (district == null && selectedDistricts != null && selectedDistricts.isNotEmpty && !selectedDistricts.contains('All')) {
        districtValue = selectedDistricts.first;
      }
      
      if (category == null && selectedCategories != null && selectedCategories.isNotEmpty && !selectedCategories.contains('All')) {
        categoryValue = selectedCategories.first;
      }
      
      // جلب البيانات من API مع الفلاتر
      final restaurants = await _restaurantsInfoProvider.fetchRestaurants(
        token: token,
        emirate: emirateValue,
        district: districtValue,
        category: categoryValue,
        priceFrom: _priceFrom,
        priceTo: _priceTo,
      );
      
      _rawRestaurantData = restaurants;
      
      // تحويل البيانات إلى FavoriteItemInterface
      _restaurantAds = _convertApiDataToFavoriteItems(restaurants);
      
    } catch (e) {
      _loadAdsError = e.toString();
      _restaurantAds = [];
    } finally {
      _isLoadingAds = false;
      safeNotifyListeners();
    }
  }

  // --- مسح جميع الفلاتر ---
  void clearAllFilters() {
    _selectedDistricts.clear();
    _selectedCategories.clear();
    priceRange = null;
    _priceFrom = null;
    _priceTo = null;
    safeNotifyListeners();
  }
}

// --- كلاس لتمثيل بيانات المطعم ---
class RestaurantAdItem implements FavoriteItemInterface {
  @override
  final String id;
  @override
  final String title;
  @override
  final String description;
  @override
  final String price;
  @override
  final String imageUrl;
  @override
  final String location;
  @override
  final String phoneNumber;
  @override
  final String whatsapp;
  @override
  final AdPriority priority;
  @override
  final String createdAt;
  
  // إضافة الخصائص المطلوبة من FavoriteItemInterface
  @override
  final String contact;
  @override
  final String date;
  @override
  final String details;
  @override
  final List<String> images;
  @override
  final bool isPremium;
  @override
  final String line1;
  
  final String category;
  final String emirate;
  final String district;
  
  RestaurantAdItem({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.location,
    required this.phoneNumber,
    required this.whatsapp,
    required this.priority,
    required this.createdAt,
    required this.category,
    required this.emirate,
    required this.district,
    required this.contact,
    required this.date,
    required this.details,
    required this.images,
    required this.isPremium,
    required this.line1,
  });
}