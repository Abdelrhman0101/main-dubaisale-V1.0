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
    required List<File> thumbnailImages,
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
    await _apiService.postFormData(
      '/api/car-services-ads',
      data: textData,
      mainImage: mainImage,
      thumbnailImages: thumbnailImages,
      token: token,
    );
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


Future<List<BestAdvertiser>> getTopGarages({required String token}) async {
  // نفترض أن الـ Endpoint مشابه لقسم السيارات
  final response = await _apiService.get('/api/best-advertisers/car_services', token: token);
  
  if (response is List) {
    return response.map((json) => BestAdvertiser.fromJson(json)).toList();
  } 
  else if (response is Map<String, dynamic> && response['data'] is List) {
    return (response['data'] as List).map((json) => BestAdvertiser.fromJson(json)).toList();
  }
  
  throw Exception('Failed to parse Top Garages list from API response.');
}





}