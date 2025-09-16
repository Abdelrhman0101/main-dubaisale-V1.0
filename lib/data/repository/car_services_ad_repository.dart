// lib/data/repository/car_services_ad_repository.dart

import 'dart:io';
import 'package:advertising_app/data/model/best_advertiser_model.dart';
import 'package:advertising_app/data/model/car_service_ad_model.dart';
import 'package:advertising_app/data/model/car_service_filter_models.dart';
import 'package:advertising_app/data/web_services/api_service.dart';

class CarServicesAdRepository {
  final ApiService _apiService;
  CarServicesAdRepository(this._apiService);

  // دالة لجلب أنواع الخدمات من الـ API
  Future<List<ServiceTypeModel>> getServiceTypes({required String token}) async {
    final response = await _apiService.get('/api/car-services/filters', token: token);

    // الـ API يرسل الأنواع داخل مفتاح "service_types"
    if (response is Map<String, dynamic> && response.containsKey('service_types')) {
      final List<dynamic> serviceTypesJson = response['service_types'];
      return serviceTypesJson.map((json) => ServiceTypeModel.fromJson(json)).toList();
    }
    
    throw Exception('Failed to parse service types from API response.');
  }

  // دالة لجلب الإمارات والمناطق التابعة لها
  Future<List<EmirateModel>> getEmirates({required String token}) async {
    final response = await _apiService.get('/api/locations/emirates', token: token);

    // الـ API يرسل الإمارات داخل مفتاح "emirates"
    if (response is Map<String, dynamic> && response.containsKey('emirates')) {
      final List<dynamic> emiratesJson = response['emirates'];
      return emiratesJson.map((json) => EmirateModel.fromJson(json)).toList();
    }
    
    throw Exception('Failed to parse emirates from API response.');
  }

  // دالة لإنشاء إعلان خدمات سيارات جديد
  Future<void> createCarServiceAd({
    required String token,
    required String title,
    required String description,
    required String emirate,
    required String district,
    required String area,
    required String serviceName,
    required String serviceType,
    required String price,
    required String advertiserName,
    required String phoneNumber,
    String? whatsapp,
    String? location, // يمكن أن يكون اختياري
    required File mainImage,
    List<File>? thumbnailImages, // جعلها اختيارية
    // بيانات خطة الإعلان التي ستأتي من الصفحة التالية
    required String planType, 
    required int planDays, 
    required String planExpiresAt,
  }) async {
    final Map<String, dynamic> textData = {
      'title': title,
      'description': description,
      'emirate': emirate,
      'district': district,
      'area': area,
      'service_name': serviceName,
      'service_type': serviceType,
      'price': price,
      'advertiser_name': advertiserName,
      'phone_number': phoneNumber,
      'whatsapp': whatsapp,
      'location': location,
      'plan_type': planType,
      'plan_days': planDays,
      'plan_expires_at': planExpiresAt,
    };
    
    // ملاحظة مهمة: في وصف الـ API الذي أرسلته، كان اسم حقل الصور المصغرة هو
    // 'thumbnail_images_urls[]'. ولكن بما أننا نرفع ملفات، يجب أن يكون
    // 'thumbnail_images[]' كما في قسم السيارات. سأعتمد هذه الصيغة.
    try {
      await _apiService.postFormData(
        '/api/car-services-ads',
        data: textData,
        mainImage: mainImage,
        thumbnailImages: thumbnailImages,
        token: token,
      );
    } catch (e) {
      // إعادة رمي الخطأ مع رسالة أوضح
      if (e.toString().contains('500')) {
        throw Exception('حدث خطأ في الخادم، يرجى المحاولة مرة أخرى لاحقاً');
      } else if (e.toString().contains('401') || e.toString().contains('403')) {
        throw Exception('انتهت صلاحية جلسة الدخول، يرجى تسجيل الدخول مرة أخرى');
      } else if (e.toString().contains('400')) {
        throw Exception('بيانات الإعلان غير صحيحة، يرجى التحقق من جميع الحقول');
      } else {
        throw Exception('فشل في إنشاء الإعلان: ${e.toString()}');
      }
    }
  }

 Future<CarServiceAdResponse> getCarServiceAds({
    required String token,
    Map<String, dynamic>? query, // سيستخدم للفلترة لاحقًا
  }) async {
     final endpoint = (query != null && query.isNotEmpty) ? '/api/car-services/search' : '/api/car-services';

  final response = await _apiService.get(endpoint, token: token, query: query);


   
   
    if (response is Map<String, dynamic>) {
      return CarServiceAdResponse.fromJson(response);
    }
    
    throw Exception('API response format is not as expected for CarServiceAdResponse.');
  }


Future<List<BestAdvertiser>> getTopGarages({required String token, String? category}) async {
  // استخدام الـ category كـ query parameter بدلاً من جزء من الـ endpoint
  String endpoint = '/api/best-advertisers';
  Map<String, dynamic>? query;
  if (category != null) {
    query = {'category': category};
  }
  
  final response = await _apiService.get(endpoint, token: token, query: query);
  
  if (response is List) {
    // استخدام الـ filterByCategory في الـ fromJson مباشرة
    List<BestAdvertiser> advertisers = response
        .map((json) => BestAdvertiser.fromJson(json, filterByCategory: category))
        .where((advertiser) => advertiser.ads.isNotEmpty) // فقط الـ advertisers الذين لديهم إعلانات
        .toList();
    return advertisers;
  } 
  else if (response is Map<String, dynamic> && response['data'] is List) {
    List<BestAdvertiser> advertisers = (response['data'] as List)
        .map((json) => BestAdvertiser.fromJson(json, filterByCategory: category))
        .where((advertiser) => advertiser.ads.isNotEmpty) // فقط الـ advertisers الذين لديهم إعلانات
        .toList();
    return advertisers;
  }
  
  throw Exception('Failed to parse Top Garages list from API response.');
}

// جلب إعلانات صندوق العروض مع فلاتر اختيارية
Future<List<CarServiceModel>> getOfferAds({required String token, Map<String, String>? filters}) async {
  try {
    String endpoint = '/api/car-services/offers-box/ads';
    
    // إضافة الفلاتر كـ query parameters
    Map<String, dynamic>? queryParams;
    if (filters != null && filters.isNotEmpty) {
      queryParams = Map<String, dynamic>.from(filters);
    }
    
    final response = await _apiService.get(endpoint, token: token, query: queryParams);
    
    if (response is List) {
      return response.map((json) => CarServiceModel.fromJson(json)).toList();
    } else if (response is Map<String, dynamic> && response['data'] is List) {
      return (response['data'] as List).map((json) => CarServiceModel.fromJson(json)).toList();
    } else {
      throw Exception('Unexpected response format for offer ads');
    }
  } catch (e) {
    throw Exception('Failed to fetch offer ads: $e');
  }
}





}