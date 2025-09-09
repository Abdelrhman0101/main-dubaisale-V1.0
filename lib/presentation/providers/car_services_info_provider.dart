// lib/presentation/providers/car_services_info_provider.dart

import 'package:advertising_app/data/model/best_advertiser_model.dart';
import 'package:flutter/material.dart';
import 'package:advertising_app/data/model/car_service_filter_models.dart';
import 'package:advertising_app/data/repository/car_services_ad_repository.dart';
import 'package:advertising_app/data/web_services/api_service.dart';

class CarServicesInfoProvider extends ChangeNotifier {
  final CarServicesAdRepository _repository;
  final ApiService _apiService; // لجلب بيانات الاتصال المشتركة

  CarServicesInfoProvider()
      : _repository = CarServicesAdRepository(ApiService()),
        _apiService = ApiService();

  // --- حالات التحميل والأخطاء ---
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  // --- قوائم البيانات ---
  List<ServiceTypeModel> _serviceTypes = [];
  List<EmirateModel> _emirates = [];
  final Map<String, List<String>> _emirateToDistrictsMap = {};
  
  // بيانات الاتصال المشتركة
  List<String> _advertiserNames = [];
  List<String> _phoneNumbers = [];
  List<String> _whatsappNumbers = [];

  // --- Getters لتوفير البيانات للـ UI ---

  // يرجع قائمة بأسماء الخدمات للعرض
  List<String> get serviceTypeNames => _serviceTypes.map((e) => e.displayName).toList();
  
  // يرجع قائمة بأسماء الإمارات للعرض
  List<String> get emirateNames => _emirates.map((e) => e.displayName).toList();
  
  // يرجع قائمة بالمناطق لإمارة محددة
  List<String> getDistrictsForEmirate(String? emirateDisplayName) {
    if (emirateDisplayName == null) return [];
    
    // البحث عن الإمارة باستخدام displayName للعثور على الاسم الحقيقي
    final emirate = _emirates.firstWhere(
      (e) => e.displayName == emirateDisplayName,
      orElse: () => EmirateModel(name: '', displayName: '', districts: []),
    );

    return _emirateToDistrictsMap[emirate.name] ?? [];
  }

  List<String> get advertiserNames => _advertiserNames;
  List<String> get phoneNumbers => _phoneNumbers;
  List<String> get whatsappNumbers => _whatsappNumbers;


  // --- دوال جلب البيانات من الـ API ---

  // دالة مجمعة لجلب كل البيانات اللازمة للشاشة
  Future<void> fetchAllData({required String token}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // جلب الفلاتر الخاصة بخدمات السيارات
      final fetchedServiceTypes = await _repository.getServiceTypes(token: token);
      final fetchedEmirates = await _repository.getEmirates(token: token);

      _serviceTypes = fetchedServiceTypes;
      _emirates = fetchedEmirates;
      _buildEmirateDistrictsMap();

      // جلب بيانات الاتصال المشتركة
      await fetchContactInfo(token: token);
      
    } catch (e) {
      _error = "Failed to load data: ${e.toString()}";
      // يمكنك هنا استدعاء دالة لتحميل قيم افتراضية إذا أردت
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // هذه الدالة تم نسخها كما هي من CarSalesInfoProvider لأنها مشتركة
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
      // لا نغير حالة الخطأ العامة هنا، لأنه خطأ ثانوي
      print("Could not fetch contact info: $e");
    }
    // لا حاجة لـ notifyListeners هنا لأن fetchAllData ستقوم بذلك
  }
  
  // هذه الدالة أيضًا مشتركة ومنسوخة
  Future<bool> addContactItem(String field, String value, {required String token}) async {
     // لا داعي لتغيير حالة التحميل هنا لجعل التجربة أفضل
    try {
      final response = await _apiService.post(
        '/api/contact-info/add-item',
        data: {'field': field, 'value': value},
        token: token,
      );
      
      if (response['success'] == true) {
        // أضف العنصر محليًا وجدد البيانات من الـ API لضمان التوافق
        await fetchContactInfo(token: token);
        notifyListeners();
        return true;
      } else {
        throw Exception(response['message'] ?? 'API returned success: false');
      }
    } catch (e) {
       _error = e.toString(); // يمكن عرض خطأ الإضافة
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

  // دالة لتحويل displayName (مثل "دبي") إلى name (مثل "Dubai") لإرساله للـ API
  String? getServiceNameFromDisplayName(String? displayName) {
    if (displayName == null) return null;
    return _serviceTypes.firstWhere((e) => e.displayName == displayName, orElse: () => ServiceTypeModel(name: '', displayName: '')).name;
  }
  
  String? getEmirateNameFromDisplayName(String? displayName) {
     if (displayName == null) return null;
    return _emirates.firstWhere((e) => e.displayName == displayName, orElse: () => EmirateModel(name: '', displayName: '', districts: [])).name;
  }


 bool _isLoadingFilters = false;
  String? _filtersError;
  bool _isLoadingTopGarages = false;
  String? _topGaragesError;

  bool get isLoadingFilters => _isLoadingFilters;
  String? get filtersError => _filtersError;
  bool get isLoadingTopGarages => _isLoadingTopGarages;
  String? get topGaragesError => _topGaragesError;
  bool get isPageLoading => _isLoadingFilters || _isLoadingTopGarages;

  // --- قوائم البيانات ---
  List<BestAdvertiser> _topGarages = [];

  // +++ متغيرات لحفظ الفلاتر المختارة +++
  List<EmirateModel> _selectedEmirates = [];
  List<ServiceTypeModel> _selectedServiceTypes = [];

  // --- Getters لتوفير البيانات للـ UI ---
  List<String> get serviceTypeDisplayNames => _serviceTypes.map((e) => e.displayName).toList();
  List<String> get emirateDisplayNames => _emirates.map((e) => e.displayName).toList();
  List<BestAdvertiser> get topGarages => _topGarages;

  List<String> get selectedEmirateNames => _selectedEmirates.map((e) => e.displayName).toList();
  List<String> get selectedServiceTypeNames => _selectedServiceTypes.map((e) => e.displayName).toList();


  // --- دوال تحديث الفلاتر ---
  void updateSelectedEmirates(List<String> selectedNames) {
    _selectedEmirates = _emirates.where((e) => selectedNames.contains(e.displayName)).toList();
    notifyListeners();
  }

  void updateSelectedServiceTypes(List<String> selectedNames) {
    _selectedServiceTypes = _serviceTypes.where((st) => selectedNames.contains(st.displayName)).toList();
    notifyListeners();
  }
  
  // +++ دالة لتجهيز الفلاتر للـ API +++
  Map<String, String> getFormattedFilters() {
    final Map<String, String> filters = {};
    if (_selectedEmirates.isNotEmpty) {
      filters['emirate'] = _selectedEmirates.map((e) => e.name).join(',');
    }
    if (_selectedServiceTypes.isNotEmpty) {
      filters['service_type'] = _selectedServiceTypes.map((st) => st.name).join(',');
    }
    return filters;
  }
  
  void clearFilters() {
    _selectedEmirates.clear();
    _selectedServiceTypes.clear();
    notifyListeners();
  }

  // --- دوال جلب البيانات ---
  Future<void> fetchLandingPageData({required String token}) async {
    _isLoadingFilters = true;
    _isLoadingTopGarages = true;
    notifyListeners();

    try {
      // جلب الفلاتر
      final fetchedServiceTypes = await _repository.getServiceTypes(token: token);
      final fetchedEmirates = await _repository.getEmirates(token: token);
      _serviceTypes = fetchedServiceTypes;
      _emirates = fetchedEmirates;
      _filtersError = null;
    } catch (e) {
      _filtersError = e.toString();
    } finally {
      _isLoadingFilters = false;
      notifyListeners();
    }

    try {
      // جلب أفضل الكراجات
      _topGarages = await _repository.getTopGarages(token: token);
      _topGaragesError = null;
    } catch (e) {
      _topGaragesError = e.toString();
    } finally {
      _isLoadingTopGarages = false;
      notifyListeners();
    }
  }
}






