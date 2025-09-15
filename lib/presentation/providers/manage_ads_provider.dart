import 'dart:async';
import 'package:advertising_app/data/model/my_ad_model.dart';
import 'package:advertising_app/data/repository/manage_ads_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';


class MyAdsProvider with ChangeNotifier {
  final ManageAdsRepository _myAdsRepository;
  MyAdsProvider(this._myAdsRepository);

  // --- حالات Provider ---
  bool _isLoading = false;
  String? _error;
  
  List<MyAdModel> _allAds = []; // قائمة تحتوي على كل الإعلانات الأصلية
  List<MyAdModel> _filteredAds = []; // القائمة التي ستعرض على الشاشة
  String _selectedStatus = 'All'; // الفلتر المختار حالياً
  
  // --- متغيرات التحديث التلقائي ---
  Timer? _autoRefreshTimer;
  bool _isAutoRefreshEnabled = false;
  bool _disposed = false;

  // --- Getters ---
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<MyAdModel> get displayedAds => _filteredAds; // الشاشة ستستخدم هذه القائمة
  String get selectedStatus => _selectedStatus;

  // --- دوال رئيسية ---
  
  // دالة لجلب البيانات من الـ API
  Future<void> fetchMyAds({bool showLoading = true}) async {
    if (showLoading) {
      _isLoading = true;
      _error = null;
      safeNotifyListeners();
    }

    try {
      final token = await const FlutterSecureStorage().read(key: 'auth_token');
      if (token == null) {
        throw Exception('User is not authenticated.');
      }
      
      final response = await _myAdsRepository.getMyAds(token: token);
      _allAds = response.ads;
      
      // إعادة تطبيق الفلتر الحالي
      filterAdsByStatus(_selectedStatus);
      
    } catch (e) {
      _error = e.toString();
      print("Error fetching my ads: $e");
    } finally {
      if (showLoading) {
        _isLoading = false;
      }
      safeNotifyListeners();
    }
  }
  
  // دالة لبدء التحديث التلقائي
  void startAutoRefresh() {
    if (_isAutoRefreshEnabled) return;
    
    _isAutoRefreshEnabled = true;
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      fetchMyAds(showLoading: false); // تحديث بدون إظهار مؤشر التحميل
    });
  }
  
  // دالة لإيقاف التحديث التلقائي
  void stopAutoRefresh() {
    _isAutoRefreshEnabled = false;
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }
  
  @override
  void dispose() {
    _disposed = true;
    stopAutoRefresh();
    super.dispose();
  }

  void safeNotifyListeners() {
    if (!_disposed) {
      notifyListeners();
    }
  }
  
  // دالة لفلترة الإعلانات بناءً على الحالة
  void filterAdsByStatus(String status) {
    _selectedStatus = status;
    
    if (status == 'All') {
      _filteredAds = _allAds;
    } else {
      // قم بتصفية القائمة الأصلية
      _filteredAds = _allAds.where((ad) => ad.status == status).toList();
    }
    
    safeNotifyListeners(); // لإعلام الواجهة بالتغييرات
  }
  
  // دالة لتنسيق السعر بفواصل كل 3 أرقام وإضافة فاصلتين عشريتين
  String formatPrice(String price) {
    // إزالة أي أحرف غير رقمية
    String cleanPrice = price.replaceAll(RegExp(r'[^0-9.]'), '');
    if (cleanPrice.isEmpty) return price;
    
    try {
      // تحويل السعر إلى رقم عشري
      double priceValue = double.parse(cleanPrice);
      
      // إذا كان الرقم كبير جداً (مثل 200000 بدلاً من 2000)، قسّمه على 100
      // هذا قد يحدث إذا كان السعر يأتي بالسنتات أو بصيغة خاطئة
      if (priceValue > 100000 && priceValue % 100 == 0) {
        priceValue = priceValue / 100;
      }
      
      // تنسيق الرقم بفواصل كل 3 أرقام وفاصلتين عشريتين
      NumberFormat formatter = NumberFormat('#,##0.00', 'en_US');
      return formatter.format(priceValue);
    } catch (e) {
      // في حالة حدوث خطأ، إرجاع السعر الأصلي
      return price;
    }
  }
  
  // دالة لإنشاء عنوان الإعلان بصيغة Make - Model - Trim
  String createAdTitle(MyAdModel ad) {
    List<String> titleParts = [];
    
    if (ad.make != null && ad.make!.isNotEmpty) {
      titleParts.add(ad.make!);
    }
    
    if (ad.model != null && ad.model!.isNotEmpty) {
      titleParts.add(ad.model!);
    }
    
    if (ad.trim != null && ad.trim!.isNotEmpty) {
      titleParts.add(ad.trim!);
    }
    
    // إذا لم تكن هناك بيانات Make/Model/Trim، استخدم العنوان الأصلي بعد تنقيته من السنة
    if (titleParts.isEmpty) {
      // إزالة السنة (أي رقم من 4 خانات) من العنوان الأصلي
      String cleanedTitle = ad.title.replaceAll(RegExp(r'\b\d{4}\b'), '').trim();
      // إزالة أي مسافات أو شرطات متتالية
      cleanedTitle = cleanedTitle.replaceAll(RegExp(r'[\s\-]+'), ' ').trim();
      return cleanedTitle.isEmpty ? ad.title : cleanedTitle;
    }
    
    return titleParts.join(' - ');
  }


    // +++ أضف هذه الحالات الجديدة +++
  bool _isActivatingOffer = false;
  String? _activationError;
  int? _activatingAdId; // لتحديد أي إعلان يتم تفعيله

  bool get isActivatingOffer => _isActivatingOffer;
  String? get activationError => _activationError;
  int? get activatingAdId => _activatingAdId;


  // ... (بقية الدوال تبقى كما هي)


  // +++ أضف هذه الدالة الجديدة +++
  Future<bool> activateOffer({
    required int adId,
    required String categorySlug,
    required int days,
  }) async {
    _isActivatingOffer = true;
    _activationError = null;
    _activatingAdId = adId; // حدد الإعلان الحالي
    notifyListeners();

    try {
      final token = await const FlutterSecureStorage().read(key: 'auth_token');
      if (token == null) {
        _activationError = 'Authentication token not found. Please login again.';
        return false;
      }
      
      print('=== ACTIVATING OFFER DEBUG ===');
      print('Ad ID: $adId');
      print('Category Slug: $categorySlug');
      print('Days: $days');
      print('Token: ${token.substring(0, 20)}...');
      print('=============================');
      
      await _myAdsRepository.activateOffer(
        token: token,
        adId: adId,
        categorySlug: categorySlug,
        days: days,
      );
      
      print('=== OFFER ACTIVATION SUCCESS ===');
      print('Ad $adId activated successfully');
      print('===============================');
      
      // بعد النجاح، يمكنك إعادة تحميل الإعلانات لتحديث حالتها
      await fetchMyAds();
      return true;

    } catch (e) {
      _activationError = e.toString();
      print('=== OFFER ACTIVATION ERROR ===');
      print('Error: $e');
      print('=============================');
      return false;
    } finally {
      _isActivatingOffer = false;
      _activatingAdId = null; // أعد تعيين ID الإعلان
      notifyListeners();
    }
  }
}