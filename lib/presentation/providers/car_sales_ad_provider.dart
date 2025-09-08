import 'dart:io';
import 'package:advertising_app/data/model/car_ad_model.dart';
import 'package:advertising_app/data/model/car_sales_filter_options_model.dart';
import 'package:advertising_app/data/model/best_advertiser_model.dart';
import 'package:advertising_app/data/repository/car_sales_ad_repository.dart';
import 'package:advertising_app/generated/l10n.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CarAdProvider with ChangeNotifier {
  final CarAdRepository _carAdRepository;
  CarAdProvider(this._carAdRepository);
  
  // --- SECTION 1: Ad List State (for Search & Manage Screens) ---
  bool _isLoadingAds = false;
  String? _loadAdsError;
  List<CarAdModel> _carAds = [];
  int _totalAds = 0;
  
  bool get isLoadingAds => _isLoadingAds;
  String? get loadAdsError => _loadAdsError;
  List<CarAdModel> get carAds => _carAds;
  int get totalAds => _totalAds;

  // --- SECTION 2: Ad Details & Editing State ---
  CarAdModel? _adDetails;
  bool _isLoadingDetails = false;
  String? _detailsError;
  bool _isUpdatingAd = false;
  String? _updateAdError;
  
  CarAdModel? get adDetails => _adDetails;
  bool get isLoadingDetails => _isLoadingDetails;
  String? get detailsError => _detailsError;
  bool get isUpdatingAd => _isUpdatingAd;
  String? get updateAdError => _updateAdError;
  
  // --- SECTION 3: Create Ad State ---
  bool _isCreatingAd = false;
  String? _createAdError;
  bool get isCreatingAd => _isCreatingAd;
  String? get createAdError => _createAdError;
  
  // --- SECTION 4: Filter Options State ---
  List<MakeModel> _makes = [];
  List<CarModel> _models = [];
  List<TrimModel> _trims = [];
  bool _isLoadingMakes = false;
  bool _isLoadingModels = false;
  bool _isLoadingTrims = false;

  List<MakeModel> get makes {
    if (_makes.isEmpty) return [];
    return [ MakeModel(id: -1, name: "All"), ..._makes, MakeModel(id: -2, name: "Other")];
  }
  List<CarModel> get models => _models;
  List<TrimModel> get trims => _trims;
  bool get isLoadingMakes => _isLoadingMakes;
  bool get isLoadingModels => _isLoadingModels;
  bool get isLoadingTrims => _isLoadingTrims;
  
  // --- SECTION 5: Selected Filters State ---
  MakeModel? _selectedMake;
  CarModel? _selectedModel;
  List<TrimModel> _selectedTrims = [];
  List<MakeModel> _selectedMakes = [];
  List<CarModel> _selectedModels = [];
  List<String> _selectedYears = [];
  List<String> _years = [];
  String? yearFrom, yearTo, kmFrom, kmTo, priceFrom, priceTo;
  
  MakeModel? get selectedMake => _selectedMake;
  CarModel? get selectedModel => _selectedModel;
  List<TrimModel> get selectedTrims => _selectedTrims;
  List<MakeModel> get selectedMakes => _selectedMakes;
  List<CarModel> get selectedModels => _selectedModels;
  List<String> get selectedYears => _selectedYears;
  List<String> get years => _years.isEmpty ? ['2024', '2023', '2022', '2021', '2020', '2019', '2018', '2017', '2016', '2015'] : _years;


    List<BestAdvertiser> _topDealerAds = [];
  bool _isLoadingTopDealers = false;

   List<BestAdvertiser> get topDealerAds => _topDealerAds;
  bool get isLoadingTopDealers => _isLoadingTopDealers;
  
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

  // تحديث قائمة الإعلانات (للترتيب حسب الموقع)
  void updateCarAds(List<CarAdModel> sortedAds) {
    _carAds = sortedAds;
    safeNotifyListeners();
  }


  // --- All Functions ---

  /// The main function to fetch ads.
  Future<void> fetchCarAds({Map<String, String>? filters}) async {
    _isLoadingAds = true;
    _loadAdsError = null;
    safeNotifyListeners();
    try {
      final token = await const FlutterSecureStorage().read(key: 'auth_token');
      if (token == null) throw Exception('User not authenticated.');
      
      final queryParameters = filters ?? {};
      if (kDebugMode) print("==> FINAL QUERY TO API: $queryParameters");
      
      final response = await _carAdRepository.getCarAds(token: token, query: queryParameters);
      _allFetchedAds = response.ads; // Store all fetched ads for local filtering
      _totalAds = response.totalAds;
      
      // Apply local filters on the fetched data
      _performLocalFilter();
    } catch (e) {
      _loadAdsError = e.toString();
      _carAds = [];
      _allFetchedAds = [];
      if (kDebugMode) print("Error fetching car ads: $e");
    } finally {
      _isLoadingAds = false;
      safeNotifyListeners();
    }
  }
  
  // Store all fetched ads for local filtering
  List<CarAdModel> _allFetchedAds = [];
  
  /// Gathers all filters and triggers the fetch.
  Future<void> applyAndFetchAds({Map<String, String>? initialFilters}) async {
    Map<String, String> finalFilters = {};
    
    if (initialFilters != null) {
      finalFilters.addAll(initialFilters);

      final makeName = initialFilters['make'];
      if(makeName != null && !_makes.any((m) => m.name == makeName) && makes.any((m) => m.name == makeName)) {
        updateSelectedMake(makes.firstWhere((m) => m.name == makeName));
      }

      final modelName = initialFilters['model'];
      if(modelName != null && !_models.any((m) => m.name == modelName) && models.any((m) => m.name == modelName)) {
        updateSelectedModel(models.firstWhere((m) => m.name == modelName));
      }
    }
    
    // Only include API filters for make, model, and trim - year, km, price will be filtered locally
    if (_selectedMake != null) {
        if (_selectedMake!.id == -2) { // Other
            finalFilters['make'] = "Other";
        } else if (_selectedMake!.id > 0) { // Real Make
            finalFilters['make'] = _selectedMake!.name;
        }
        // If "All" is selected (id: -1), we don't add any 'make' filter
    }
    if (_selectedModel != null) finalFilters['model'] = _selectedModel!.name;
    if (_selectedTrims.isNotEmpty) finalFilters['trim'] = _selectedTrims.map((e) => e.name).join(',');
    
    await fetchCarAds(filters: finalFilters);
  }

  void _performLocalFilter() {
    List<CarAdModel> filteredList = List.from(_allFetchedAds);
    
    // Filter by Year
    final fromYear = int.tryParse(yearFrom ?? '');
    final toYear = int.tryParse(yearTo ?? '');
    if (fromYear != null) filteredList.retainWhere((ad) => (int.tryParse(ad.year) ?? 0) >= fromYear);
    if (toYear != null) filteredList.retainWhere((ad) => (int.tryParse(ad.year) ?? 0) <= toYear);
    
    // Filter by Km
    final fromKm = int.tryParse(kmFrom?.replaceAll(',', '') ?? '');
    final toKm = int.tryParse(kmTo?.replaceAll(',', '') ?? '');
    if (fromKm != null) filteredList.retainWhere((ad) => (int.tryParse(ad.km.replaceAll(',', '')) ?? 0) >= fromKm);
    if (toKm != null) filteredList.retainWhere((ad) => (int.tryParse(ad.km.replaceAll(',', '')) ?? 0) <= toKm);
    
    // Filter by Price
    final fromPrice = double.tryParse(priceFrom?.replaceAll(',', '') ?? '');
    final toPrice = double.tryParse(priceTo?.replaceAll(',', '') ?? '');
    if (fromPrice != null) filteredList.retainWhere((ad) => (double.tryParse(ad.price.replaceAll(',', '')) ?? 0) >= fromPrice);
    if (toPrice != null) filteredList.retainWhere((ad) => (double.tryParse(ad.price.replaceAll(',', '')) ?? 0) <= toPrice);
    
    _carAds = filteredList;
    safeNotifyListeners();
  }

  // --- Functions to UPDATE filters & Trigger Local Filtering ---
  void updateYearRange(String? from, String? to) { 
    yearFrom = from; 
    yearTo = to; 
    _performLocalFilter(); 
  }
  void updateKmRange(String? from, String? to) { 
    kmFrom = from; 
    kmTo = to; 
    _performLocalFilter(); 
  }
  void updatePriceRange(String? from, String? to) { 
    priceFrom = from; 
    priceTo = to; 
    _performLocalFilter(); 
  }
  void updateSelectedTrims(List<TrimModel> selection) { 
    _selectedTrims = selection; 
    applyAndFetchAds(); 
  }

  void updateSelectedModel(CarModel? selection) {
    _selectedModel = selection;
    _selectedTrims.clear(); _trims.clear();
    if (_selectedModel != null) {
      fetchTrimsForModel(_selectedModel!);
    }
    applyAndFetchAds(); 
    safeNotifyListeners(); 
  }
  
  void updateSelectedMake(MakeModel? selection) {
    _selectedMake = selection;
    _selectedModel = null; _selectedTrims.clear();
    _models.clear(); _trims.clear();
    if (_selectedMake != null && _selectedMake!.id > 0) {
      fetchModelsForMake(_selectedMake!);
    } else {
       applyAndFetchAds();
    }
    safeNotifyListeners();
  }

  void updateSelectedMakes(List<MakeModel> selection) {
    _selectedMakes = selection;
    _selectedModels.clear(); _selectedTrims.clear();
    _models.clear(); _trims.clear();
    if (_selectedMakes.length == 1) {
      fetchModelsForMake(_selectedMakes.first);
    } else {
      applyAndFetchAds();
    }
    safeNotifyListeners();
  }

  void updateSelectedModels(List<CarModel> selection) {
    _selectedModels = selection;
    _selectedTrims.clear(); _trims.clear();
    if (_selectedModels.length == 1) {
      fetchTrimsForModel(_selectedModels.first);
    } else {
      applyAndFetchAds();
    }
    safeNotifyListeners();
  }

  void updateSelectedYears(List<String> selection) {
    _selectedYears = selection;
    applyAndFetchAds();
    safeNotifyListeners();
  }

  // دالة لمسح جميع الفلاتر
  void clearAllFilters() {
    _selectedMake = null;
    _selectedModel = null;
    _selectedTrims.clear();
    _selectedMakes.clear();
    _selectedModels.clear();
    _selectedYears.clear();
    _models.clear();
    _trims.clear();
    yearFrom = null;
    yearTo = null;
    kmFrom = null;
    kmTo = null;
    priceFrom = null;
    priceTo = null;
    safeNotifyListeners();
  }

  // --- Other Functions ---
  Future<void> fetchAdDetails(int adId) async {
    _isLoadingDetails = true; _detailsError = null; _adDetails = null; safeNotifyListeners();
    try {
      final token = await const FlutterSecureStorage().read(key: 'auth_token');
      if(token == null) throw Exception("Token missing");
      _adDetails = await _carAdRepository.getCarAdDetails(adId: adId, token: token);
    } catch (e) { _detailsError = e.toString(); }
    finally { 
      _isLoadingDetails = false; 
      safeNotifyListeners();
    }
  }

  Future<void> fetchMakes() async {
    if (_makes.isNotEmpty) return;
    _isLoadingMakes = true; notifyListeners();
    try {
       final token = await const FlutterSecureStorage().read(key: 'auth_token');
       if (token == null) throw Exception('Token not found');
       _makes = await _carAdRepository.getMakes(token: token);
    } catch (e) {
      if (kDebugMode) print("Error fetching makes: $e");
    } finally {
      _isLoadingMakes = false; safeNotifyListeners();
    }
  }

  Future<void> fetchModelsForMake(MakeModel make) async {
    _isLoadingModels = true; _models.clear(); safeNotifyListeners();
    try {
      final token = await const FlutterSecureStorage().read(key: 'auth_token');
      if (token == null) throw Exception('Token not found');
      _models = await _carAdRepository.getModels(makeId: make.id, token: token);
    } catch (e) {
      if (kDebugMode) print("Error fetching models: $e");
    } finally {
      _isLoadingModels = false; safeNotifyListeners();
    }
  }
  
  Future<void> fetchTrimsForModel(CarModel model) async {
    _isLoadingTrims = true; _trims.clear(); safeNotifyListeners();
    try {
      final token = await const FlutterSecureStorage().read(key: 'auth_token');
      if (token == null) throw Exception('Token not found');
      _trims = await _carAdRepository.getTrims(modelId: model.id, token: token);
    } catch (e) {
      if (kDebugMode) print("Error fetching trims: $e");
    } finally {
      _isLoadingTrims = false; safeNotifyListeners();
    }
  }

   Future<bool> updateAd({required int adId, required String price, required String description, required String phoneNumber, String? whatsapp, File? mainImage, List<File>? thumbnailImages}) async {
    _isUpdatingAd = true; _updateAdError = null; safeNotifyListeners();
    try {
      final token = await const FlutterSecureStorage().read(key: 'auth_token');
      if(token==null) throw Exception("Token missing");
      await _carAdRepository.updateCarAd(adId: adId, token: token, price: price, description: description, phoneNumber: phoneNumber, whatsapp: whatsapp, mainImage: mainImage, thumbnailImages: thumbnailImages);
      return true;
    } catch (e) {
      _updateAdError = e.toString();
      return false;
    } finally {
      _isUpdatingAd = false;
      safeNotifyListeners();
    }
  }

  Future<bool> submitCarAd({required String title, required String description, required String make, required String model, String? trim, required String year, required String km, required String price, String? specs, String? carType, required String transType, String? fuelType, String? color, String? interiorColor, required bool warranty, String? engineCapacity, String? cylinders, String? horsepower, String? doorsNo, String? seatsNo, String? steeringSide, required String phoneNumber, String? whatsapp, required String emirate, required String area, required String advertiserType, required String advertiserName, required File mainImage, required List<File> thumbnailImages, required String planType, required int planDays, required String planExpiresAt}) async {
    _isCreatingAd = true; _createAdError = null; safeNotifyListeners();
    try {
      final token = await const FlutterSecureStorage().read(key: 'auth_token');
      if(token==null) throw Exception("Token missing");
      
      // طباعة تشخيصية للبيانات المرسلة
      print('=== CAR AD SUBMISSION DEBUG ===');
      print('Title: $title');
      print('Make: $make');
      print('Model: $model');
      print('Year: $year');
      print('Phone: $phoneNumber');
      print('Emirate: $emirate');
      print('Area: $area');
      print('Plan Type: $planType');
      print('Plan Days: $planDays');
      print('Plan Expires At: $planExpiresAt');
      print('Main Image Path: ${mainImage.path}');
      print('Thumbnail Images Count: ${thumbnailImages.length}');
      print('===============================');
      
      await _carAdRepository.createCarAd(title: title, description: description, make: make, model: model, trim: trim, year: year, km: km, price: price, specs: specs, carType: carType, transType: transType, fuelType: fuelType, color: color, interiorColor: interiorColor, warranty: warranty, engineCapacity: engineCapacity, cylinders: cylinders, horsepower: horsepower, doorsNo: doorsNo, seatsNo: seatsNo, steeringSide: steeringSide, advertiserName: advertiserName, phoneNumber: phoneNumber, whatsapp: whatsapp, emirate: emirate, area: area, advertiserType: advertiserType, mainImage: mainImage, thumbnailImages: thumbnailImages, token: token, planType: planType, planDays: planDays, planExpiresAt: planExpiresAt);
      return true;
    } catch (e) {
      print('=== CAR AD SUBMISSION ERROR ===');
      print('Error Type: ${e.runtimeType}');
      print('Error Message: $e');
      print('==============================');
      _createAdError = e.toString();
      return false;
    } finally {
      _isCreatingAd = false;
      safeNotifyListeners();
    }
  }

  //   bool get isSearchEnabled {
  //   if (_selectedMake == null) return false; // يجب اختيار Make على الأقل
    
  //   // إذا اختار "All"، يمكنه البحث مباشرةً
  //   if (_selectedMake!.id == -1) return true;
    
  //   // إذا اختار "Other"، يمكنه البحث مباشرةً
  //   if (_selectedMake!.id == -2) return true;

  //   // إذا اختار Make حقيقيًا
  //   // وكانت قائمة الموديلات التابعة له لا تزال قيد التحميل، عطل الزر مؤقتًا
  //   if (_isLoadingModels) return false;

  //   // إذا كانت هناك موديلات لهذا الـ Make، فيجب اختيار موديل
  //   if (_models.isNotEmpty && _selectedModel == null) return false;
    
  //   // في كل الحالات الأخرى، البحث ممكن
  //   return true;
  // }

 Future<void> fetchTopDealerAds({bool forceRefresh = false}) async {
        if (!forceRefresh && _topDealerAds.isNotEmpty) return;
        _isLoadingTopDealers = true;
        safeNotifyListeners();
        try {
          final token = await const FlutterSecureStorage().read(key: 'auth_token');
          if (token == null) throw Exception('Token not found');
          _topDealerAds = await _carAdRepository.getBestAdvertiserAds(token: token);
        } catch (e) {
          if (kDebugMode) print("Error fetching top dealer ads: $e");
        } finally {
          _isLoadingTopDealers = false;
          safeNotifyListeners();
        }
    }

  bool get isSearchEnabled {
    if (_selectedMake == null) return false;
    if (_selectedMake!.id == -1 || _selectedMake!.id == -2) return true;
    if (_isLoadingModels) return false;
    if (_models.isNotEmpty && _selectedModel == null) return false;
    return true;
  }
  
  String getSearchValidationMessage(S s) {
    if (_selectedMake == null) return "Please select make.";
    if (_selectedMake!.id > 0 && _models.isNotEmpty && _selectedModel == null) return "please_select_model";
    return ""; // No error
  }

   List<CarAdModel> _offerAds = [];
  bool _isLoadingOffers = false;
  String? _offersError;

  List<CarAdModel> get offerAds => _offerAds;
  bool get isLoadingOffers => _isLoadingOffers;
  String? get offersError => _offersError;


  // ... (كل الدوال القديمة)


  List<CarAdModel> _allFetchedOfferAds = []; // القائمة الكاملة للعروض



  // فلاتر خاصة بالعروض
  String? offerYearFrom, offerYearTo, offerKmFrom, offerKmTo, offerPriceFrom, offerPriceTo;

  // +++ أضف هذه الدالة الجديدة +++
  // Future<void> fetchOfferAds() async {
  //   _isLoadingOffers = true;
  //   _offersError = null;
  //   notifyListeners();
  //   try {
  //     final token = await const FlutterSecureStorage().read(key: 'auth_token');
  //     if (token == null) throw Exception('Token not found');
  //     _offerAds = await _carAdRepository.getOfferAds(token: token);
  //   } catch (e) {
  //     _offersError = e.toString();
  //     if (kDebugMode) print("Error fetching offer ads: $e");
  //   } finally {
  //     _isLoadingOffers = false;
  //     notifyListeners();
  //   }
  // }

   Future<void> fetchOfferAds() async {
    _isLoadingOffers = true;
    _offersError = null;
    safeNotifyListeners();
    try {
      final token = await const FlutterSecureStorage().read(key: 'auth_token');
      if (token == null) throw Exception('Token not found');
      
      final ads = await _carAdRepository.getOfferAds(token: token);
      _allFetchedOfferAds = ads;
      
      _performLocalOfferFilter(); // Apply current filters (if any) right away
    
    } catch (e) {
      _offersError = e.toString();
    } finally {
      _isLoadingOffers = false;
      safeNotifyListeners();
    }
  }

  void _performLocalOfferFilter() {
    List<CarAdModel> filteredList = List.from(_allFetchedOfferAds);
    // Filter by Year
    final fromYear = int.tryParse(offerYearFrom ?? '');
    final toYear = int.tryParse(offerYearTo ?? '');
    if (fromYear != null) filteredList.retainWhere((ad) => (int.tryParse(ad.year) ?? 0) >= fromYear);
    if (toYear != null) filteredList.retainWhere((ad) => (int.tryParse(ad.year) ?? 0) <= toYear);
    // Filter by Km
    final fromKm = int.tryParse(offerKmFrom?.replaceAll(',', '') ?? '');
    final toKm = int.tryParse(offerKmTo?.replaceAll(',', '') ?? '');
    if (fromKm != null) filteredList.retainWhere((ad) => (int.tryParse(ad.km.replaceAll(',', '')) ?? 0) >= fromKm);
    if (toKm != null) filteredList.retainWhere((ad) => (int.tryParse(ad.km.replaceAll(',', '')) ?? 0) <= toKm);
    // Filter by Price
    final fromPrice = double.tryParse(offerPriceFrom?.replaceAll(',', '') ?? '');
    final toPrice = double.tryParse(offerPriceTo?.replaceAll(',', '') ?? '');
    if (fromPrice != null) filteredList.retainWhere((ad) => (double.tryParse(ad.price.replaceAll(',', '')) ?? 0) >= fromPrice);
    if (toPrice != null) filteredList.retainWhere((ad) => (double.tryParse(ad.price.replaceAll(',', '')) ?? 0) <= toPrice);
    
    _offerAds = filteredList;
    safeNotifyListeners();
  }

  void updateYearRangeForOffers(String? from, String? to) { 
    offerYearFrom = from; 
    offerYearTo = to;
    _performLocalOfferFilter();
  }
  void updateKmRangeForOffers(String? from, String? to) { 
    offerKmFrom = from; 
    offerKmTo = to;
    _performLocalOfferFilter();
  }
  void updatePriceRangeForOffers(String? from, String? to) { 
    offerPriceFrom = from; 
    offerPriceTo = to;
    _performLocalOfferFilter();
  }
  

}






// import 'dart:io';
// import 'package:advertising_app/data/model/car_ad_model.dart';
// import 'package:advertising_app/data/model/car_sales_filter_options_model.dart';
// import 'package:advertising_app/data/repository/car_sales_ad_repository.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// class CarAdProvider with ChangeNotifier {
//   final CarAdRepository _carAdRepository;
//   CarAdProvider(this._carAdRepository);
  
//   // SECTION 1: Ad List State
//   bool _isLoadingAds = false;
//   String? _loadAdsError;
//   List<CarAdModel> _carAds = [];      // The list displayed to the user
//   List<CarAdModel> _allFetchedAds = []; // The master list from the API
//   int _totalAds = 0;
  
//   bool get isLoadingAds => _isLoadingAds;
//   String? get loadAdsError => _loadAdsError;
//   List<CarAdModel> get carAds => _carAds;
//   int get totalAds => _totalAds;

//   // SECTION 2: Ad Details & Editing State
//   CarAdModel? _adDetails;
//   bool _isLoadingDetails = false;
//   String? _detailsError;
//   bool _isUpdatingAd = false;
//   String? _updateAdError;
  
//   CarAdModel? get adDetails => _adDetails;
//   bool get isLoadingDetails => _isLoadingDetails;
//   String? get detailsError => _detailsError;
//   bool get isUpdatingAd => _isUpdatingAd;
//   String? get updateAdError => _updateAdError;
  
//   // SECTION 3: Create Ad State
//   bool _isCreatingAd = false;
//   String? _createAdError;
//   bool get isCreatingAd => _isCreatingAd;
//   String? get createAdError => _createAdError;

//   // SECTION 4: Filter Options State
//   List<MakeModel> _makes = [];
//   List<CarModel> _models = [];
//   List<TrimModel> _trims = [];
//   bool _isLoadingMakes = false;
//   bool _isLoadingModels = false;
//   bool _isLoadingTrims = false;

//   List<MakeModel> get makes => _makes;
//   List<CarModel> get models => _models;
//   List<TrimModel> get trims => _trims;
//   bool get isLoadingMakes => _isLoadingMakes;
//   bool get isLoadingModels => _isLoadingModels;
//   bool get isLoadingTrims => _isLoadingTrims;
  
//   // SECTION 5: Selected Filters State
//   List<MakeModel> _selectedMakes = [];
//   List<CarModel> _selectedModels = [];
//   List<TrimModel> _selectedTrims = [];
//   String? yearFrom, yearTo, kmFrom, kmTo, priceFrom, priceTo;
  
//   List<MakeModel> get selectedMakes => _selectedMakes;
//   List<CarModel> get selectedModels => _selectedModels;
//   List<TrimModel> get selectedTrims => _selectedTrims;

//   // --- Functions ---
  
//   /// Gathers API-related filters (Make, Model, Trim) and fetches the initial ad list.
//   Future<void> applyAndFetchAds({Map<String, String>? initialFilters}) async {
//     Map<String, String> apiFilters = {};
//     if (initialFilters != null) apiFilters.addAll(initialFilters);

//     if (_selectedMakes.isNotEmpty) apiFilters['make'] = _selectedMakes.first.name;
//     if (_selectedModels.isNotEmpty) apiFilters['model'] = _selectedModels.first.name;
//     if (_selectedTrims.isNotEmpty) apiFilters['trim'] = _selectedTrims.map((e) => e.name).join(',');
    
//     await fetchCarAds(filters: apiFilters);
//   }
  
//   /// Connects to the internet to fetch the ad list based on API filters.
//   Future<void> fetchCarAds({Map<String, String>? filters}) async {
//     _isLoadingAds = true;
//     _loadAdsError = null;
//     notifyListeners();
//     try {
//       final token = await const FlutterSecureStorage().read(key: 'auth_token');
//       if (token == null) throw Exception('User not authenticated.');
//       final response = await _carAdRepository.getCarAds(token: token, query: filters);
      
//       _allFetchedAds = response.ads;
//       _totalAds = response.ads.length; 
      
//       _performLocalFilter();

//     } catch (e) {
//       _loadAdsError = e.toString();
//       _allFetchedAds.clear();
//       _carAds.clear();
//       if (kDebugMode) print("Error fetching car ads: $e");
//     } finally {
//       _isLoadingAds = false;
//       notifyListeners();
//     }
//   }

//   /// Performs local (hard-coded) filtering on the fetched ad list.
//   void _performLocalFilter() {
//     List<CarAdModel> filteredList = List.from(_allFetchedAds);

//     // Filter by Year
//     final fromYear = int.tryParse(yearFrom ?? '');
//     final toYear = int.tryParse(yearTo ?? '');
//     if (fromYear != null) filteredList.retainWhere((ad) => (int.tryParse(ad.year) ?? 0) >= fromYear);
//     if (toYear != null) filteredList.retainWhere((ad) => (int.tryParse(ad.year) ?? 0) <= toYear);

//     // Filter by Km
//     final fromKm = int.tryParse(kmFrom?.replaceAll(',', '') ?? '');
//     final toKm = int.tryParse(kmTo?.replaceAll(',', '') ?? '');
//     if (fromKm != null) filteredList.retainWhere((ad) => (int.tryParse(ad.km.replaceAll(',', '')) ?? 0) >= fromKm);
//     if (toKm != null) filteredList.retainWhere((ad) => (int.tryParse(ad.km.replaceAll(',', '')) ?? 0) <= toKm);

//     // Filter by Price
//     final fromPrice = double.tryParse(priceFrom?.replaceAll(',', '') ?? '');
//     final toPrice = double.tryParse(priceTo?.replaceAll(',', '') ?? '');
//      if (fromPrice != null) filteredList.retainWhere((ad) => (double.tryParse(ad.price.replaceAll(',', '')) ?? 0) >= fromPrice);
//     if (toPrice != null) filteredList.retainWhere((ad) => (double.tryParse(ad.price.replaceAll(',', '')) ?? 0) <= toPrice);
    
//     _carAds = filteredList;
//     notifyListeners();
//   }
  
//   // --- Functions for Updating Filter Selections ---
  
//   void updateSelectedTrims(List<TrimModel> selection) { 
//     _selectedTrims = selection; 
//     applyAndFetchAds();
//   }
  
//   void updateYearRange(String? from, String? to) { 
//     yearFrom = from; 
//     yearTo = to;
//     _performLocalFilter();
//   }

//   void updateKmRange(String? from, String? to) { 
//     kmFrom = from; 
//     kmTo = to;
//     _performLocalFilter();
//   }
  
//   void updatePriceRange(String? from, String? to) { 
//     priceFrom = from; 
//     priceTo = to;
//     _performLocalFilter();
//   }

//   void updateSelectedModels(List<CarModel> selection) {
//     _selectedModels = selection;
//     _selectedTrims.clear(); _trims.clear();
//     if (_selectedModels.length == 1) {
//       fetchTrimsForModel(_selectedModels.first);
//     } else {
//       applyAndFetchAds();
//     }
//     notifyListeners(); 
//   }
  
//   void updateSelectedMakes(List<MakeModel> selection) {
//     _selectedMakes = selection;
//     _selectedModels.clear(); _selectedTrims.clear();
//     _models.clear(); _trims.clear();
//     if (_selectedMakes.length == 1) {
//       fetchModelsForMake(_selectedMakes.first);
//     } else {
//       applyAndFetchAds();
//     }
//     notifyListeners();
//   }
  
//   // --- Other Functions for Fetching Filter Options ---
//   Future<void> fetchMakes() async {
//     if (_makes.isNotEmpty) return;
//     _isLoadingMakes = true; notifyListeners();
//     try {
//        final token = await const FlutterSecureStorage().read(key: 'auth_token');
//        if (token == null) throw Exception('Token not found');
//        _makes = await _carAdRepository.getMakes(token: token);
//     } catch (e) {
//       if (kDebugMode) print("Error fetching makes: $e");
//     } finally {
//       _isLoadingMakes = false; notifyListeners();
//     }
//   }

//   Future<void> fetchModelsForMake(MakeModel make) async {
//     _isLoadingModels = true; _models.clear(); notifyListeners();
//     try {
//       final token = await const FlutterSecureStorage().read(key: 'auth_token');
//       if (token == null) throw Exception('Token not found');
//       _models = await _carAdRepository.getModels(makeId: make.id, token: token);
//     } catch (e) {
//       if (kDebugMode) print("Error fetching models: $e");
//     } finally {
//       _isLoadingModels = false; notifyListeners();
//     }
//   }
  
//   Future<void> fetchTrimsForModel(CarModel model) async {
//     _isLoadingTrims = true; _trims.clear(); notifyListeners();
//     try {
//       final token = await const FlutterSecureStorage().read(key: 'auth_token');
//       if (token == null) throw Exception('Token not found');
//       _trims = await _carAdRepository.getTrims(modelId: model.id, token: token);
//     } catch (e) {
//       if (kDebugMode) print("Error fetching trims: $e");
//     } finally {
//       _isLoadingTrims = false; notifyListeners();
//     }
//   }

//    Future<void> fetchAdDetails(int adId) async {
//     _isLoadingDetails = true; _detailsError = null; _adDetails = null; notifyListeners();
//     try {
//       final token = await const FlutterSecureStorage().read(key: 'auth_token');
//       if(token == null) throw Exception("Token missing");
//       _adDetails = await _carAdRepository.getCarAdDetails(adId: adId, token: token);
//     } catch (e) { _detailsError = e.toString(); }
//     finally { _isLoadingDetails = false; notifyListeners(); }
//   }

//    Future<bool> updateAd({required int adId, required String price, required String description, required String phoneNumber, String? whatsapp, File? mainImage, List<File>? thumbnailImages}) async {
//     _isUpdatingAd = true; _updateAdError = null; notifyListeners();
//     try {
//       final token = await const FlutterSecureStorage().read(key: 'auth_token');
//       if(token==null) throw Exception("Token missing");
//       await _carAdRepository.updateCarAd(adId: adId, token: token, price: price, description: description, phoneNumber: phoneNumber, whatsapp: whatsapp, mainImage: mainImage, thumbnailImages: thumbnailImages);
//       return true;
//     } catch (e) {
//       _updateAdError = e.toString();
//       return false;
//     } finally {
//       _isUpdatingAd = false;
//       notifyListeners();
//     }
//   }

//   Future<bool> submitCarAd({required String title, required String description, required String make, required String model, String? trim, required String year, required String km, required String price, String? specs, String? carType, required String transType, String? fuelType, String? color, String? interiorColor, required bool warranty, String? engineCapacity, String? cylinders, String? horsepower, String? doorsNo, String? seatsNo, String? steeringSide, required String phoneNumber, String? whatsapp, required String emirate, required String area, required String advertiserType, required String advertiserName, required File mainImage, required List<File> thumbnailImages}) async {
//     _isCreatingAd = true; _createAdError = null; notifyListeners();
//     try {
//       final token = await const FlutterSecureStorage().read(key: 'auth_token');
//       if(token==null) throw Exception("Token missing");
//       await _carAdRepository.createCarAd(title: title, description: description, make: make, model: model, trim: trim, year: year, km: km, price: price, specs: specs, carType: carType, transType: transType, fuelType: fuelType, color: color, interiorColor: interiorColor, warranty: warranty, engineCapacity: engineCapacity, cylinders: cylinders, horsepower: horsepower, doorsNo: doorsNo, seatsNo: seatsNo, steeringSide: steeringSide, advertiserName: advertiserName, phoneNumber: phoneNumber, whatsapp: whatsapp, emirate: emirate, area: area, advertiserType: advertiserType, mainImage: mainImage, thumbnailImages: thumbnailImages, token: token);
//       return true;
//     } catch (e) {
//       _createAdError = e.toString();
//       return false;
//     } finally {
//       _isCreatingAd = false;
//       notifyListeners();
//     }
//   }
// }

// // import 'dart:io';
// // import 'package:advertising_app/data/model/car_ad_model.dart';
// // import 'package:advertising_app/data/model/car_sales_filter_options_model.dart';
// // import 'package:advertising_app/data/repository/car_sales_ad_repository.dart';
// // import 'package:flutter/foundation.dart';
// // import 'package:flutter/material.dart';
// // import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// // class CarAdProvider with ChangeNotifier {
// //   final CarAdRepository _carAdRepository;
// //   CarAdProvider(this._carAdRepository);
  
// //   // --- 1. States for Ad List (Search & Manage Screens) ---
// //   bool _isLoadingAds = false;
// //   String? _loadAdsError;
// //   List<CarAdModel> _carAds = [];
// //   int _totalAds = 0;
  
// //   bool get isLoadingAds => _isLoadingAds;
// //   String? get loadAdsError => _loadAdsError;
// //   List<CarAdModel> get carAds => _carAds;
// //   int get totalAds => _totalAds;

// //   // --- 2. States for Ad Details & Editing ---
// //   CarAdModel? _adDetails;
// //   bool _isLoadingDetails = false;
// //   String? _detailsError;
// //   bool _isUpdatingAd = false;
// //   String? _updateAdError;
  
// //   CarAdModel? get adDetails => _adDetails;
// //   bool get isLoadingDetails => _isLoadingDetails;
// //   String? get detailsError => _detailsError;
// //   bool get isUpdatingAd => _isUpdatingAd;
// //   String? get updateAdError => _updateAdError;

// //   // --- 3. States for Creating a New Ad ---
// //   bool _isCreatingAd = false;
// //   String? _createAdError;
// //   bool get isCreatingAd => _isCreatingAd;
// //   String? get createAdError => _createAdError;
  
// //   // --- 4. States for Filter Options (Make, Model, Trim) ---
// //   List<MakeModel> _makes = [];
// //   List<CarModel> _models = [];
// //   List<TrimModel> _trims = [];
// //   bool _isLoadingMakes = false;
// //   bool _isLoadingModels = false;
// //   bool _isLoadingTrims = false;

// //   List<MakeModel> get makes => _makes;
// //   List<CarModel> get models => _models;
// //   List<TrimModel> get trims => _trims;
// //   bool get isLoadingMakes => _isLoadingMakes;
// //   bool get isLoadingModels => _isLoadingModels;
// //   bool get isLoadingTrims => _isLoadingTrims;
  
// //   // --- 5. States for User's Selected Filters ---
// //   List<MakeModel> _selectedMakes = [];
// //   List<CarModel> _selectedModels = [];
// //   List<TrimModel> _selectedTrims = [];
// //   String? yearFrom, yearTo, kmFrom, kmTo, priceFrom, priceTo;
  
// //   List<MakeModel> get selectedMakes => _selectedMakes;
// //   List<CarModel> get selectedModels => _selectedModels;
// //   List<TrimModel> get selectedTrims => _selectedTrims;


// //   // القائمة التي ستُعرض للمستخدم
// //   List<CarAdModel> _allFetchedAds = []; // القائمة الرئيسية من الـ API
  

// //   // --- All Functions ---

// //   /// Fetches car ads based on a map of filters. Used by both HomeScreen and CarSalesScreen.
// //   // Future<void> fetchCarAds({Map<String, String>? filters}) async {
// //   //   _isLoadingAds = true;
// //   //   _loadAdsError = null;
// //   //   _carAds.clear();
// //   //   notifyListeners();
// //   //   try {
// //   //     final token = await const FlutterSecureStorage().read(key: 'auth_token');
// //   //     if (token == null) throw Exception('User not authenticated.');
// //   //     final queryParameters = filters ?? {};
// //   //     final response = await _carAdRepository.getCarAds(token: token, query: queryParameters);
// //   //     _carAds = response.ads;
// //   //     _totalAds = response.totalAds;
// //   //   } catch (e) {
// //   //     _loadAdsError = e.toString();
// //   //     if (kDebugMode) print("Error fetching car ads: $e");
// //   //   } finally {
// //   //     _isLoadingAds = false;
// //   //     notifyListeners();
// //   //   }
// //   // }

// //   // /// Gathers all selected filters and calls fetchCarAds.
// //   // Future<void> applyAndFetchAds({Map<String, String>? initialFilters}) async {
// //   //   Map<String, String> finalFilters = {};
// //   //   if (initialFilters != null) finalFilters.addAll(initialFilters);

// //   //   if (_selectedMakes.isNotEmpty) finalFilters['make'] = _selectedMakes.map((e) => e.name).join(',');
// //   //   if (_selectedModels.isNotEmpty) finalFilters['model'] = _selectedModels.map((e) => e.name).join(',');
// //   //   if (_selectedTrims.isNotEmpty) finalFilters['trim'] = _selectedTrims.map((e) => e.name).join(',');
// //   //   if (yearFrom != null && yearFrom!.isNotEmpty) finalFilters['year_from'] = yearFrom!;
// //   //   if (yearTo != null && yearTo!.isNotEmpty) finalFilters['year_to'] = yearTo!;
// //   //   if (kmFrom != null && kmFrom!.isNotEmpty) finalFilters['km_from'] = kmFrom!;
// //   //   if (kmTo != null && kmTo!.isNotEmpty) finalFilters['km_to'] = kmTo!;
// //   //   if (priceFrom != null && priceFrom!.isNotEmpty) finalFilters['price_from'] = priceFrom!;
// //   //   if (priceTo != null && priceTo!.isNotEmpty) finalFilters['price_to'] = priceTo!;
     
// //   //   await fetchCarAds(filters: finalFilters);
// //   // }


// // // Future<void> applyAndFetchAds({Map<String, String>? initialFilters}) async {
// // //     Map<String, String> finalFilters = {};
    
// // //     // إذا كان هناك فلاتر أولية (عند أول تحميل للصفحة)، قم بمعالجتها
// // //     if (initialFilters != null) {
// // //         // امسح الفلاتر القديمة لتبدأ بحثاً نظيفاً
// // //         _selectedMakes.clear(); _selectedModels.clear(); _selectedTrims.clear();
// // //         _models.clear(); _trims.clear();
// // //         yearFrom = null; yearTo = null; kmFrom = null; kmTo = null; priceFrom = null; priceTo = null;

// // //         // قم بمعالجة الفلاتر الأولية لتحديد الاختيارات
// // //         final makeName = initialFilters['make'];
// // //         if (makeName != null && makes.any((m) => m.name == makeName)) {
// // //             final make = makes.firstWhere((m) => m.name == makeName);
// // //             _selectedMakes = [make];
// // //             await fetchModelsForMake(make);
// // //         }

// // //         final modelName = initialFilters['model'];
// // //         if (modelName != null && _models.any((m) => m.name == modelName)) {
// // //             final model = _models.firstWhere((m) => m.name == modelName);
// // //             _selectedModels = [model];
// // //             await fetchTrimsForModel(model);
// // //         }
// // //     }
     
// // //     // الآن، قم ببناء الفلاتر النهائية من الحالات الحالية في Provider
// // //     if (_selectedMakes.isNotEmpty) finalFilters['make'] = _selectedMakes.first.name;
// // //     if (_selectedModels.isNotEmpty) finalFilters['model'] = _selectedModels.first.name;
// // //     if (_selectedTrims.isNotEmpty) finalFilters['trim'] = _selectedTrims.map((e) => e.name).join(',');
// // //     if (yearFrom != null && yearFrom!.isNotEmpty) finalFilters['year_from'] = yearFrom!;
// // //     if (yearTo != null && yearTo!.isNotEmpty) finalFilters['year_to'] = yearTo!;
// // //     if (kmFrom != null && kmFrom!.isNotEmpty) finalFilters['km_from'] = kmFrom!;
// // //     if (kmTo != null && kmTo!.isNotEmpty) finalFilters['km_to'] = kmTo!;
// // //     if (priceFrom != null && priceFrom!.isNotEmpty) finalFilters['price_from'] = priceFrom!;
// // //     if (priceTo != null && priceTo!.isNotEmpty) finalFilters['price_to'] = priceTo!;
     
// // //     await fetchCarAds(filters: finalFilters);
// // //   } /// Fetches details for a single ad.

// //   Future<void> applyAndFetchAds({Map<String, String>? initialFilters}) async {
// //     Map<String, String> finalFilters = {};
// //     if (initialFilters != null) finalFilters.addAll(initialFilters);

// //     if (_selectedMakes.isNotEmpty) finalFilters['make'] = _selectedMakes.first.name;
// //     if (_selectedModels.isNotEmpty) finalFilters['model'] = _selectedModels.first.name;
// //     if (_selectedTrims.isNotEmpty) finalFilters['trim'] = _selectedTrims.map((e) => e.name).join(',');
// //     if (yearFrom != null && yearFrom!.isNotEmpty) finalFilters['year_from'] = yearFrom!;
// //     if (yearTo != null && yearTo!.isNotEmpty) finalFilters['year_to'] = yearTo!;
// //     if (kmFrom != null && kmFrom!.isNotEmpty) finalFilters['km_from'] = kmFrom!;
// //     if (kmTo != null && kmTo!.isNotEmpty) finalFilters['km_to'] = kmTo!;
// //     if (priceFrom != null && priceFrom!.isNotEmpty) finalFilters['price_from'] = priceFrom!;
// //     if (priceTo != null && priceTo!.isNotEmpty) finalFilters['price_to'] = priceTo!;
     
// //     await fetchCarAds(filters: finalFilters);
// //   }
  
// //   /// الدالة الفعلية التي تتصل بالـ API
// //   Future<void> fetchCarAds({Map<String, String>? filters}) async {
// //     _isLoadingAds = true;
// //     _loadAdsError = null;
// //     notifyListeners(); // أخبر الواجهة بالبدء في التحميل
    
    
// //     try {
// //       final token = await const FlutterSecureStorage().read(key: 'auth_token');
// //       if (token == null) throw Exception('User not authenticated.');
// //         if (kDebugMode) {
// //         print("==> FINAL QUERY TO API: $queryParameters");
// //       }
// //       final response = await _carAdRepository.getCarAds(token: token, query: filters);
      
// //       _carAds = response.ads;
// //       _totalAds = response.totalAds;
// //     } catch (e) {
// //       _loadAdsError = e.toString();
// //     } finally {
// //       _isLoadingAds = false;
// //       notifyListeners(); // أخبر الواجهة بانتهاء التحميل وعرض النتائج أو الخطأ
// //     }
// //   }

// //   // دوال تحديث الفلاتر (الآن كلها تستدعي البحث)
// //   void updateSelectedTrims(List<TrimModel> selection) { _selectedTrims = selection; applyAndFetchAds(); }
// //   void updateYearRange(String? from, String? to) { yearFrom = from; yearTo = to; applyAndFetchAds(); }
// //   void updateKmRange(String? from, String? to) { kmFrom = from; kmTo = to; applyAndFetchAds(); }
// //   void updatePriceRange(String? from, String? to) { priceFrom = from; priceTo = to; applyAndFetchAds(); }
// //   /// دالة الفلترة المحلية (لـ Year, Km, Price)
// //   void _performLocalFilter() {
// //     List<CarAdModel> filteredList = List.from(_allFetchedAds);

// //     final fromYear = int.tryParse(yearFrom ?? '');
// //     final toYear = int.tryParse(yearTo ?? '');
// //     if (fromYear != null) filteredList.retainWhere((ad) => (int.tryParse(ad.year) ?? 0) >= fromYear);
// //     if (toYear != null) filteredList.retainWhere((ad) => (int.tryParse(ad.year) ?? 0) <= toYear);

// //     final fromKm = int.tryParse(kmFrom?.replaceAll(',', '') ?? '');
// //     final toKm = int.tryParse(kmTo?.replaceAll(',', '') ?? '');
// //     if (fromKm != null) filteredList.retainWhere((ad) => (int.tryParse(ad.km.replaceAll(',', '')) ?? 0) >= fromKm);
// //     if (toKm != null) filteredList.retainWhere((ad) => (int.tryParse(ad.km.replaceAll(',', '')) ?? 0) <= toKm);

// //     final fromPrice = double.tryParse(priceFrom?.replaceAll(',', '') ?? '');
// //     final toPrice = double.tryParse(priceTo?.replaceAll(',', '') ?? '');
// //      if (fromPrice != null) filteredList.retainWhere((ad) => (double.tryParse(ad.price.replaceAll(',', '')) ?? 0) >= fromPrice);
// //     if (toPrice != null) filteredList.retainWhere((ad) => (double.tryParse(ad.price.replaceAll(',', '')) ?? 0) <= toPrice);
    
// //     _carAds = filteredList;
// //     notifyListeners();
// //   }



// //   Future<void> fetchAdDetails(int adId) async {
// //     _isLoadingDetails = true; _detailsError = null; _adDetails = null; notifyListeners();
// //     try {
// //       final token = await const FlutterSecureStorage().read(key: 'auth_token');
// //       if(token == null) throw Exception("Token missing");
// //       _adDetails = await _carAdRepository.getCarAdDetails(adId: adId, token: token);
// //     } catch (e) { _detailsError = e.toString(); }
// //     finally { _isLoadingDetails = false; notifyListeners(); }
// //   }
  
// //   /// Fetches all available car makes.
// //   Future<void> fetchMakes() async {
// //     if (_makes.isNotEmpty) return;
// //     _isLoadingMakes = true;
// //     notifyListeners();
// //     try {
// //        final token = await const FlutterSecureStorage().read(key: 'auth_token');
// //        if (token == null) throw Exception('Token not found');
// //        _makes = await _carAdRepository.getMakes(token: token);
// //     } catch (e) {
// //       if (kDebugMode) print("Error fetching makes: $e");
// //     } finally {
// //       _isLoadingMakes = false;
// //       notifyListeners();
// //     }
// //   }

// //   /// Fetches models for a specific make.
// //   Future<void> fetchModelsForMake(MakeModel make) async {
// //     _isLoadingModels = true; _models.clear(); notifyListeners();
// //     try {
// //       final token = await const FlutterSecureStorage().read(key: 'auth_token');
// //       if (token == null) throw Exception('Token not found');
// //       _models = await _carAdRepository.getModels(makeId: make.id, token: token);
// //     } catch (e) {
// //       if (kDebugMode) print("Error fetching models: $e");
// //     } finally {
// //       _isLoadingModels = false;
// //       notifyListeners();
// //     }
// //   }
  
// //   /// Fetches trims for a specific model.
// // Future<void> fetchTrimsForModel(CarModel model) async {
// //     _isLoadingTrims = true; 
// //     _trims.clear(); 
// //     notifyListeners();
// //     try {
// //       final token = await const FlutterSecureStorage().read(key: 'auth_token');
// //       if (token == null) throw Exception('Token not found');
// //       _trims = await _carAdRepository.getTrims(modelId: model.id, token: token);
      
// //       // +++ أضف هذا السطر هنا +++
// //       if (kDebugMode) print('----------- PROVIDER: FETCH & PARSE TRIMS SUCCESS (Found ${_trims.length} trims) -----------');

// //     } catch (e) {
      
// //       // +++ وأضف هذين السطرين هنا +++
// //       if (kDebugMode) {
// //         print('----------- PROVIDER: FETCH OR PARSE TRIMS FAILED -----------');
// //         print(e); // لطباعة الخطأ الفعلي
// //       }
// //     } finally {
// //       _isLoadingTrims = false;
// //       notifyListeners();
// //     }
// //   }
  
// //   /// Updates the selected make and fetches corresponding models.
// //   void updateSelectedMakes(List<MakeModel> selection) {
// //     _selectedMakes = selection;
// //     _selectedModels.clear(); _selectedTrims.clear();
// //     _models.clear(); _trims.clear();
    
// //     if (_selectedMakes.length == 1) fetchModelsForMake(_selectedMakes.first);
// //     notifyListeners();
// //   }
  
// //   /// Updates the selected model and fetches corresponding trims.
// //   void updateSelectedModels(List<CarModel> selection) {
// //     _selectedModels = selection;
// //     _selectedTrims.clear(); _trims.clear();
// //     if (_selectedModels.length == 1) fetchTrimsForModel(_selectedModels.first);
// //     notifyListeners();
// //   }
  
// //   /// Updates the selected trims.
// //   // void updateSelectedTrims(List<TrimModel> selection) {
// //   //   _selectedTrims = selection;
// //   //   notifyListeners();
// //   // }
  
// //   // void updateYearRange(String? from, String? to) { 
// //   //   yearFrom = from; 
// //   //   yearTo = to;
// //   //   applyAndFetchAds(); // ابحث مجددًا بالفلتر الجديد
// //   // }

// //   // void updateKmRange(String? from, String? to) { 
// //   //   kmFrom = from; 
// //   //   kmTo = to;
// //   //   applyAndFetchAds(); // ابحث مجددًا
// //   // }
  
// //   // void updatePriceRange(String? from, String? to) { 
// //   //   priceFrom = from; 
// //   //   priceTo = to;
// //   //   applyAndFetchAds(); // ابحث مجددًا
// //   // }

// // //  void updateSelectedTrims(List<TrimModel> selection) { 
// // //     _selectedTrims = selection; 
// // //      applyAndFetchAds(); 
// // //   }
  
// // //   void updateYearRange(String? from, String? to) { 
// // //     yearFrom = from; 
// // //     yearTo = to; 
// // //     applyAndFetchAds();  // فقط أخبر الواجهة بالتغيير
// // //   }

// // //   void updateKmRange(String? from, String? to) { 
// // //     kmFrom = from; 
// // //     kmTo = to;
// // //      applyAndFetchAds(); 
// // //   }
  
// // //   void updatePriceRange(String? from, String? to) { 
// // //     priceFrom = from; 
// // //     priceTo = to;
// // //      applyAndFetchAds(); 
// // //   }
  
  
// //   //  void updateSelectedTrims(List<TrimModel> selection) { 
// //   //   _selectedTrims = selection; 
// //   //   applyAndFetchAds(initialFilters: {}); // إرسال initialFilters فارغ ليعيد بناء الفلاتر
// //   // }
  
// //   // /// عند اختيار نطاق للسنة، قم بالفلترة محليًا فقط
// //   // void updateYearRange(String? from, String? to) { 
// //   //   yearFrom = from; 
// //   //   yearTo = to;
// //   //   _performLocalFilter();
// //   // }

// //   // /// عند اختيار نطاق للكيلومترات، قم بالفلترة محليًا فقط
// //   // void updateKmRange(String? from, String? to) { 
// //   //   kmFrom = from; 
// //   //   kmTo = to;
// //   //   _performLocalFilter();
// //   // }
  
// //   // /// عند اختيار نطاق للسعر، قم بالفلترة محليًا فقط
// //   // void updatePriceRange(String? from, String? to) { 
// //   //   priceFrom = from; 
// //   //   priceTo = to;
// //   //   _performLocalFilter();
// //   // }

  
// //   Future<bool> updateAd({required int adId, required String price, required String description, required String phoneNumber, String? whatsapp, File? mainImage, List<File>? thumbnailImages,}) async {
// //     _isUpdatingAd = true; _updateAdError = null; notifyListeners();
// //     try {
// //       final token = await const FlutterSecureStorage().read(key: 'auth_token');
// //       if(token==null) throw Exception("Token missing");
// //       await _carAdRepository.updateCarAd(adId: adId, token: token, price: price, description: description, phoneNumber: phoneNumber, whatsapp: whatsapp, mainImage: mainImage, thumbnailImages: thumbnailImages);
// //       return true;
// //     } catch (e) {
// //       _updateAdError = e.toString();
// //       return false;
// //     } finally {
// //       _isUpdatingAd = false;
// //       notifyListeners();
// //     }
// //   }

// //   Future<bool> submitCarAd({required String title, required String description, required String make, required String model, String? trim, required String year, required String km, required String price, String? specs, String? carType, required String transType, String? fuelType, String? color, String? interiorColor, required bool warranty, String? engineCapacity, String? cylinders, String? horsepower, String? doorsNo, String? seatsNo, String? steeringSide, required String phoneNumber, String? whatsapp, required String emirate, required String area, required String advertiserType, required String advertiserName, required File mainImage, required List<File> thumbnailImages}) async {
// //     _isCreatingAd = true; _createAdError = null; notifyListeners();
// //     try {
// //       final token = await const FlutterSecureStorage().read(key: 'auth_token');
// //       if(token==null) throw Exception("Token missing");
// //       await _carAdRepository.createCarAd(title: title, description: description, make: make, model: model, trim: trim, year: year, km: km, price: price, specs: specs, carType: carType, transType: transType, fuelType: fuelType, color: color, interiorColor: interiorColor, warranty: warranty, engineCapacity: engineCapacity, cylinders: cylinders, horsepower: horsepower, doorsNo: doorsNo, seatsNo: seatsNo, steeringSide: steeringSide, advertiserName: advertiserName, phoneNumber: phoneNumber, whatsapp: whatsapp, emirate: emirate, area: area, advertiserType: advertiserType, mainImage: mainImage, thumbnailImages: thumbnailImages, token: token);
// //       return true;
// //     } catch (e) {
// //       _createAdError = e.toString();
// //       return false;
// //     } finally {
// //       _isCreatingAd = false;
// //       notifyListeners();
// //     }
// //   }
// // }








// // // import 'dart:io';

// // // import 'package:advertising_app/data/model/car_ad_model.dart';
// // // import 'package:advertising_app/data/model/car_sales_filter_options_model.dart';
// // // import 'package:advertising_app/data/repository/car_sales_ad_repository.dart';
// // // import 'package:flutter/material.dart';
// // // import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// // // class CarAdProvider with ChangeNotifier {
// // //   final CarAdRepository _carAdRepository;
// // //   CarAdProvider(this._carAdRepository);
  
// // //   // --- متغيرات الحالة الخاصة بـ **إنشاء** إعلان ---
// // //   bool _isCreatingAd = false;
// // //   String? _createAdError;
// // //   bool get isCreatingAd => _isCreatingAd;
// // //   String? get createAdError => _createAdError;
  
// // //   // --- متغيرات الحالة الخاصة بـ **جلب** الإعلانات ---
// // //   bool _isLoadingAds = false;
// // //   String? _loadAdsError;
// // //   List<CarAdModel> _carAds = [];
// // //   int _totalAds = 0;
  
// // //   bool get isLoadingAds => _isLoadingAds;
// // //   String? get loadAdsError => _loadAdsError;
// // //   List<CarAdModel> get carAds => _carAds;
// // //   int get totalAds => _totalAds;


  
// // //   // +++ حالات جديدة لإدارة خيارات الفلترة +++
// // //   List<MakeModel> _makes = [];
// // //   List<CarModel> _models = [];
// // //   bool _isLoadingMakes = false;
// // //   bool _isLoadingModels = false;

// // //   // Getters للواجهة
// // //   List<MakeModel> get makes => _makes;
// // //   List<CarModel> get models => _models;
// // //   bool get isLoadingMakes => _isLoadingMakes;
// // //   bool get isLoadingModels => _isLoadingModels;
  
// // //   // +++ حالات جديدة لحفظ الفلاتر المختارة +++
// // //   List<MakeModel> _selectedMakes = [];
// // //   List<CarModel> _selectedModels = [];
  
// // //   List<MakeModel> get selectedMakes => _selectedMakes;
// // //   List<CarModel> get selectedModels => _selectedModels;

// // //   List<TrimModel> _trims = [];
// // //   bool _isLoadingTrims = false;
// // //   List<TrimModel> _selectedTrims = [];

// // //   List<TrimModel> get trims => _trims;
// // //   bool get isLoadingTrims => _isLoadingTrims;
// // //   List<TrimModel> get selectedTrims => _selectedTrims;



// // //   // دالة إنشاء الإعلان: تستخدم _isCreatingAd و _createAdError
// // //   Future<bool> submitCarAd({
// // //     required String title, required String description, required String make,
// // //     required String model, String? trim, required String year, required String km,
// // //     required String price, String? specs, String? carType, required String transType,
// // //     String? fuelType, String? color, String? interiorColor, required bool warranty,
// // //     String? engineCapacity, String? cylinders, String? horsepower, String? doorsNo,
// // //     String? seatsNo, String? steeringSide, required String phoneNumber, String? whatsapp,
// // //     required String emirate, required String area, required String advertiserType,
// // //     required String advertiserName, required File mainImage,
// // //     required List<File> thumbnailImages,
// // //   }) async {
// // //     _createAdError = null;
// // //     _isCreatingAd = true;
// // //     notifyListeners();

// // //     try {
// // //       final token = await const FlutterSecureStorage().read(key: 'auth_token');
// // //       if (token == null) {
// // //         throw Exception('Authentication token not found. Please log in again.');
// // //       }
      
// // //       await _carAdRepository.createCarAd(
// // //         title: title, description: description, make: make, model: model, trim: trim, year: year, km: km, price: price,
// // //         specs: specs, carType: carType, transType: transType, fuelType: fuelType, color: color, interiorColor: interiorColor,
// // //         warranty: warranty, engineCapacity: engineCapacity, cylinders: cylinders, horsepower: horsepower, doorsNo: doorsNo,
// // //         seatsNo: seatsNo, steeringSide: steeringSide, advertiserName: advertiserName, phoneNumber: phoneNumber,
// // //         whatsapp: whatsapp, emirate: emirate, area: area, advertiserType: advertiserType,
// // //         mainImage: mainImage, thumbnailImages: thumbnailImages, token: token
// // //       );

// // //       _isCreatingAd = false;
// // //       notifyListeners();
// // //       return true;
// // //     } catch (e) {
// // //       print("Error submitting car ad: $e");
// // //       _createAdError = e.toString();
// // //       _isCreatingAd = false;
// // //       notifyListeners();
// // //       return false;
// // //     }
// // //   }
  
// // //   // دالة جلب الإعلانات: تستخدم _isLoadingAds و _loadAdsError
// // //   //  Future<void> fetchCarAds() async {
// // //   //   if (_isLoadingAds && _carAds.isNotEmpty) return; // منع التحديث إذا كان جارياً بالفعل
    
// // //   //   _isLoadingAds = true;
// // //   //   _loadAdsError = null;
// // //   //   notifyListeners();

// // //   //   try {
// // //   //     // 1. قراءة التوكن من التخزين الآمن
// // //   //     final token = await const FlutterSecureStorage().read(key: 'auth_token');
// // //   //     if (token == null) {
// // //   //       throw Exception('User is not authenticated (token is missing).');
// // //   //     }

// // //   //     // 2. استدعاء دالة الـ Repository مع تمرير التوكن
// // //   //     final response = await _carAdRepository.getCarAds(token: token);
      
// // //   //     _carAds = response.ads;
// // //   //     _totalAds = response.totalAds;

// // //   //   } catch (e) {
// // //   //     print("Error fetching car ads: $e");
// // //   //     _loadAdsError = e.toString();
// // //   //   } finally {
// // //   //     _isLoadingAds = false;
// // //   //     notifyListeners();
// // //   //   }
// // //   // }


// // //   Future<void> fetchCarAds({Map<String, String>? filters}) async {
// // //     _isLoadingAds = true;
// // //     _loadAdsError = null;
// // //     _carAds = []; // إفراغ القائمة القديمة عند بدء بحث جديد
// // //     notifyListeners();

// // //     try {
// // //       final token = await const FlutterSecureStorage().read(key: 'auth_token');
// // //       if (token == null) {
// // //         throw Exception('User is not authenticated.');
// // //       }
      
// // //       // هنا نقوم ببناء الـ query parameters بناءً على الفلاتر
// // //       // نستخدم '?? {}' لضمان أنها ليست null
// // //       final queryParameters = filters ?? {};

// // //       // نمرر الـ queryParameters إلى دالة الـ Repository
// // //       final response = await _carAdRepository.getCarAds(token: token, query: queryParameters);
      
// // //       _carAds = response.ads;
// // //       _totalAds = response.totalAds;

// // //     } catch (e) {
// // //       _loadAdsError = e.toString();
// // //       print("Error fetching car ads: $e");
// // //     } finally {
// // //       _isLoadingAds = false;
// // //       notifyListeners();
// // //     }
// // //   }

// // //   // +++ حالات جديدة: خاصة بصفحة التعديل +++
// // //   CarAdModel? _adDetails;
// // //   bool _isLoadingDetails = false;
// // //   String? _detailsError;
// // //   bool _isUpdatingAd = false;
// // //   String? _updateAdError;
  
// // //   CarAdModel? get adDetails => _adDetails;
// // //   bool get isLoadingDetails => _isLoadingDetails;
// // //   String? get detailsError => _detailsError;
// // //   bool get isUpdatingAd => _isUpdatingAd;
// // //   String? get updateAdError => _updateAdError;
  
// // //   // +++ دالة جديدة لجلب تفاصيل الإعلان +++
// // //   Future<void> fetchAdDetails(int adId) async {
// // //     _isLoadingDetails = true;
// // //     _detailsError = null;
// // //     _adDetails = null; // إعادة تعيين البيانات القديمة
// // //     notifyListeners();

// // //     try {
// // //       final token = await const FlutterSecureStorage().read(key: 'auth_token');
// // //       if (token == null) throw Exception('Authentication token not found.');
      
// // //       final carAd = await _carAdRepository.getCarAdDetails(adId: adId, token: token);
// // //       _adDetails = carAd;

// // //     } catch (e) {
// // //       _detailsError = e.toString();
// // //       print("Error fetching ad details: $e");
// // //     } finally {
// // //       _isLoadingDetails = false;
// // //       notifyListeners();
// // //     }
// // //   }
  
// // //   // +++ دالة جديدة لتحديث الإعلان +++
// // //   Future<bool> updateAd({
// // //     required int adId,
// // //     required String price,
// // //     required String description,
// // //     required String phoneNumber,
// // //     String? whatsapp,
// // //     File? mainImage,
// // //     List<File>? thumbnailImages,
// // //   }) async {
// // //     _isUpdatingAd = true;
// // //     _updateAdError = null;
// // //     notifyListeners();

// // //     try {
// // //       final token = await const FlutterSecureStorage().read(key: 'auth_token');
// // //       if (token == null) throw Exception('Authentication token not found.');
      
// // //       await _carAdRepository.updateCarAd(
// // //         adId: adId,
// // //         token: token,
// // //         price: price,
// // //         description: description,
// // //         phoneNumber: phoneNumber,
// // //         whatsapp: whatsapp,
// // //         mainImage: mainImage,
// // //         thumbnailImages: thumbnailImages
// // //       );
// // //       return true; // نجح التحديث
// // //     } catch (e) {
// // //       _updateAdError = e.toString();
// // //       print("Error updating car ad: $e");
// // //       return false; // فشل التحديث
// // //     } finally {
// // //       _isUpdatingAd = false;
// // //       notifyListeners();
// // //     }
// // //   }

 
// // //  // --- +++ دوال جديدة للفلترة +++ ---
  
// // //   // جلب كل الـ Makes
// // //   // Future<void> fetchMakes() async {
// // //   //   if (_makes.isNotEmpty) return; // لا تجلب البيانات إذا كانت موجودة بالفعل
// // //   //   _isLoadingMakes = true;
// // //   //   notifyListeners();
// // //   //   try {
// // //   //      final token = await const FlutterSecureStorage().read(key: 'auth_token');
// // //   //      if (token == null) throw Exception('Token not found');
// // //   //      _makes = await _carAdRepository.getMakes(token: token);
// // //   //   } catch (e) {
// // //   //     print("Error fetching makes: $e");
// // //   //   } finally {
// // //   //     _isLoadingMakes = false;
// // //   //     notifyListeners();
// // //   //   }
// // //   // }

// // //   // // جلب الـ Models بناءً على make واحد مختار
// // //   // Future<void> fetchModelsForMake(MakeModel make) async {
// // //   //   _isLoadingModels = true;
// // //   //   _models.clear(); // مسح الموديلات القديمة
// // //   //   notifyListeners();
// // //   //   try {
// // //   //     final token = await const FlutterSecureStorage().read(key: 'auth_token');
// // //   //     if (token == null) throw Exception('Token not found');
// // //   //     _models = await _carAdRepository.getModels(makeId: make.id, token: token);
// // //   //   } catch (e) {
// // //   //     print("Error fetching models: $e");
// // //   //   } finally {
// // //   //     _isLoadingModels = false;
// // //   //     notifyListeners();
// // //   //   }
// // //   // }

// // //   // // تحديث الـ Makes المختارة (وعليه يتم جلب الـ models)
// // //   // void updateSelectedMakes(List<MakeModel> selection) {
// // //   //   _selectedMakes = selection;
// // //   //   _selectedModels.clear(); // عند تغيير الـ make, يجب مسح الـ model المختار

// // //   //   // حاليًا سنجلب الـ models فقط إذا تم اختيار make واحد. 
// // //   //   // يمكنك تطوير هذا المنطق لاحقًا لدعم اختيار عدة makes
// // //   //   if (_selectedMakes.length == 1) {
// // //   //     fetchModelsForMake(_selectedMakes.first);
// // //   //   } else {
// // //   //     _models.clear(); // إذا لم يتم اختيار make أو تم اختيار أكثر من واحد, نفرغ قائمة الموديلات
// // //   //   }
// // //   //   notifyListeners();
// // //   // }
  
// // //   // void updateSelectedModels(List<CarModel> selection) {
// // //   //   _selectedModels = selection;
// // //   //   notifyListeners();
// // //   // }

// // //   // // +++ تحديث دالة fetchCarAds لتقبل الفلاتر +++
// // //   // Future<void> fetchCarAdsfilter({Map<String, String>? filters}) async {
// // //   //   _isLoadingAds = true;
// // //   //   _loadAdsError = null;
// // //   //   notifyListeners();

// // //   //   try {
// // //   //     final token = await const FlutterSecureStorage().read(key: 'auth_token');
// // //   //     if (token == null) throw Exception('User is not authenticated.');
      
// // //   //     // هنا نقوم ببناء الـ query parameters بناءً على الفلاتر
// // //   //     Map<String, dynamic> queryParameters = {};
// // //   //     if(filters != null) {
// // //   //         queryParameters.addAll(filters);
// // //   //     }
      
// // //   //     // نمرر الـ queryParameters إلى دالة get
// // //   //     final response = await _carAdRepository.getCarAds(token: token, query: queryParameters);
// // //   //     _carAds = response.ads;
// // //   //     _totalAds = response.totalAds;

// // //   //   } catch (e) {
// // //   //     _loadAdsError = e.toString();
// // //   //   } finally {
// // //   //     _isLoadingAds = false;
// // //   //     notifyListeners();
// // //   //   }
// // //   // }




// // //  Future<void> fetchMakes() async {
// // //     if (_makes.isNotEmpty) return;
// // //     _isLoadingMakes = true;
// // //     notifyListeners();
// // //     try {
// // //        final token = await const FlutterSecureStorage().read(key: 'auth_token');
// // //        if (token == null) throw Exception('Token not found');
// // //        _makes = await _carAdRepository.getMakes(token: token);
// // //     } catch (e) {
// // //       print("Error fetching makes: $e");
// // //     } finally {
// // //       _isLoadingMakes = false;
// // //       notifyListeners();
// // //     }
// // //   }

// // //   Future<void> fetchModelsForMake(MakeModel make) async {
// // //     _isLoadingModels = true;
// // //     _models.clear();
// // //     notifyListeners();
// // //     try {
// // //       final token = await const FlutterSecureStorage().read(key: 'auth_token');
// // //       if (token == null) throw Exception('Token not found');
// // //       _models = await _carAdRepository.getModels(makeId: make.id, token: token);
// // //     } catch (e) {
// // //       print("Error fetching models: $e");
// // //     } finally {
// // //       _isLoadingModels = false;
// // //       notifyListeners();
// // //     }
// // //   }

// // // Future<void> fetchTrimsForModel(CarModel model) async {
// // //     _isLoadingTrims = true;
// // //     _trims.clear();
// // //     notifyListeners();
// // //     try {
// // //       final token = await const FlutterSecureStorage().read(key: 'auth_token');
// // //       if (token == null) throw Exception('Token not found');
// // //       _trims = await _carAdRepository.getTrims(modelId: model.id, token: token);
// // //     } catch (e) {
// // //       print("Error fetching trims: $e");
// // //     } finally {
// // //       _isLoadingTrims = false;
// // //       notifyListeners();
// // //     }
// // //   }

// // //   // +++ تحديث دالة updateSelectedModels لتنادي على fetchTrimsForModel +++
// // //   void updateSelectedModels(List<CarModel> selection) {
// // //     _selectedModels = selection;
// // //     _selectedTrims.clear(); // عند تغيير الموديل، امسح اختيار الـ trim

// // //     if (_selectedModels.length == 1) {
// // //       fetchTrimsForModel(_selectedModels.first);
// // //     } else {
// // //       _trims.clear();
// // //     }
// // //     notifyListeners();
// // //   }
  
// // //   // +++ دالة جديدة لتحديث الـ Trims المختارة +++
// // //   void updateSelectedTrims(List<TrimModel> selection) {
// // //     _selectedTrims = selection;
// // //     notifyListeners();
// // //   }

// // //    void updateSelectedMakes(List<MakeModel> selection) {
// // //     _selectedMakes = selection;
// // //     // عند تغيير الشركة المصنعة، نقوم بإعادة تعيين الموديلات والطرازات
// // //     _selectedModels.clear();
// // //     _selectedTrims.clear();
// // //     _models.clear();
// // //     _trims.clear();
    
// // //     // إذا اختار المستخدم شركة واحدة فقط، نقوم بجلب موديلاتها
// // //     if (_selectedMakes.length == 1) {
// // //       fetchModelsForMake(_selectedMakes.first);
// // //     }
// // //     notifyListeners();
// // //   }
  
// // //   // void updateSelectedModels(List<CarModel> selection) {
// // //   //   _selectedModels = selection;
// // //   //   // عند تغيير الموديل، نقوم بإعادة تعيين الطرازات
// // //   //   _selectedTrims.clear();
// // //   //   _trims.clear();

// // //   //   if (_selectedModels.length == 1) {
// // //   //     fetchTrimsForModel(_selectedModels.first);
// // //   //   }
// // //   //   notifyListeners();
// // //   // }
 
// // //   /// Gathers all selected filters and calls fetchCarAds.
// // //   Future<void> applyAndFetchAds({Map<String, String>? initialFilters}) async {
// // //     Map<String, String> finalFilters = {};
    
// // //     // 1. نبدأ بالفلاتر الأولية (إن وجدت) القادمة من HomeScreen
// // //     if (initialFilters != null) finalFilters.addAll(initialFilters);

// // //     // 2. نضيف الفلاتر التي تم اختيارها في HomeScreen
// // //     if (_selectedMakes.isNotEmpty) finalFilters['make'] = _selectedMakes.map((e) => e.name).join(',');
// // //     if (_selectedModels.isNotEmpty) finalFilters['model'] = _selectedModels.map((e) => e.name).join(',');

// // //     // 3. نضيف الفلاتر الداخلية من CarSalesScreen
// // //     if (_selectedTrims.isNotEmpty) finalFilters['trim'] = _selectedTrims.map((e) => e.name).join(',');
// // //     if (yearFrom != null && yearFrom!.isNotEmpty) finalFilters['2020'] = yearFrom!;
// // //     if (yearTo != null && yearTo!.isNotEmpty) finalFilters['2025'] = yearTo!;
// // //     if (kmFrom != null && kmFrom!.isNotEmpty) finalFilters['km_from'] = kmFrom!;
// // //     if (kmTo != null && kmTo!.isNotEmpty) finalFilters['km_to'] = kmTo!;
// // //     if (priceFrom != null && priceFrom!.isNotEmpty) finalFilters['price_from'] = priceFrom!;
// // //     if (priceTo != null && priceTo!.isNotEmpty) finalFilters['price_to'] = priceTo!;
     
// // //     // 4. نستدعي دالة جلب البيانات مع كل الفلاتر المجمعة
// // //     await fetchCarAds(filters: finalFilters);
// // //   }


// // // }