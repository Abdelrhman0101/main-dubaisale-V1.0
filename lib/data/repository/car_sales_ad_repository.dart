import 'dart:io';

import 'package:advertising_app/data/model/car_ad_model.dart';
import 'package:advertising_app/data/model/car_sales_filter_options_model.dart';
import 'package:advertising_app/data/model/best_advertiser_model.dart';
import 'package:advertising_app/data/web_services/api_service.dart';
import 'package:flutter/foundation.dart';


class CarAdRepository {
  final ApiService _apiService;
  CarAdRepository(this._apiService);

  // --- تم تحديث نوع الإرجاع (Return Type) للدالة ---
 Future<CarAdResponse> getCarAds({required String token, Map<String, dynamic>? query}) async {
    // طباعة تشخيصية فقط في وضع التطوير
    if (kDebugMode) {
      print("Fetching Car Ads with query: $query");
    }

    final response = await _apiService.get('/api/car-sales-ads', token: token, query: query);
    
    if (response is Map<String, dynamic>) {
      return CarAdResponse.fromJson(response);
    }
    
    throw Exception('API response format is not as expected for CarAdResponse.');
  }
  
  // دالة إنشاء الإعلان تبقى كما هي
  Future<void> createCarAd({
    required String title, required String description, required String make,
    required String model, String? trim, required String year, required String km,
    required String price, String? specs, String? carType, required String transType,
    String? fuelType, String? color, String? interiorColor, required bool warranty,
    String? engineCapacity, String? cylinders, String? horsepower, String? doorsNo,
    String? seatsNo, String? steeringSide, required String phoneNumber, String? whatsapp,
    required String emirate, required String area, required String advertiserType,
    required String advertiserName, required File mainImage,
    required List<File> thumbnailImages, required String token,
  }) async {
    final String warrantyValue = warranty ? '1' : '0';
    
    final Map<String, dynamic> textData = {
      'title': title, 'description': description, 'make': make, 'model': model,
      'trim': trim, 'year': year, 'km': km, 'price': price, 'specs': specs,
      'car_type': carType, 'trans_type': transType, 'fuel_type': fuelType,
      'color': color, 'interior_color': interiorColor, 
      'warranty': warrantyValue,
      'engine_capacity': engineCapacity, 'cylinders': cylinders, 'horsepower': horsepower,
      'doors_no': doorsNo, 'seats_no': seatsNo, 'steering_side': steeringSide,
      'advertiser_name': advertiserName, 'phone_number': phoneNumber, 'whatsapp': whatsapp,
      'emirate': emirate, 'area': area, 'advertiser_type': advertiserType,
    };

    await _apiService.postFormData(
      '/api/car-sales-ads',
      data: textData,
      mainImage: mainImage,
      thumbnailImages: thumbnailImages,
      token: token,
    );
  }

   // في ملف: data/repository/car_sales_ad_repository.dart

  // --- استبدل الدالة القديمة بهذه الدالة المحدثة ---
  Future<CarAdModel> getCarAdDetails({required int adId, required String token}) async {
    final response = await _apiService.get('/api/car-sales-ads/$adId', token: token);
    
    // هذا السطر مهم جدًا لنرى بنية الرد في الـ Console
    print('----------- RAW API RESPONSE FOR AD DETAILS -----------');
    print(response);

    // نتأكد أن الرد هو من نوع Map
    if (response is Map<String, dynamic>) {
      
      // الحالة الأولى: إذا كان الـ API يرسل الرد داخل مفتاح "data"
      // مثال: {"data": { ...ad details... }}
      if (response.containsKey('data') && response['data'] is Map<String, dynamic>) {
        print('API Response is wrapped in "data" key. Parsing from "data"...');
        return CarAdModel.fromJson(response['data']);
      }
      
      // الحالة الثانية: إذا كان الـ API يرسل تفاصيل الإعلان مباشرة
      // مثال: { ...ad details... }
      else {
        print('API Response is a direct object. Parsing directly...');
        return CarAdModel.fromJson(response);
      }
    }
    
    // إذا لم تكن أي من الحالات السابقة، إذن هناك خطأ في شكل الرد من الأساس
    throw Exception('API response is not a valid Map object for CarAdModel.');
  }
  // --- دالة جديدة لتحديث الإعلان ---
  Future<void> updateCarAd({
    required int adId,
    required String token,
    // الحقول القابلة للتعديل فقط
    required String price,
    required String description,
    required String phoneNumber,
    String? whatsapp,
    File? mainImage, // قد تكون null إذا لم يغيرها المستخدم
    List<File>? thumbnailImages, // قد تكون null
  }) async {
    
    final Map<String, dynamic> textData = {
      'price': price,
      'description': description,
      'phone_number': phoneNumber,
      'whatsapp': whatsapp,
    };

    // نستخدم الدالة الجديدة التي أضفناها في ApiService
    await _apiService.putFormData(
      '/api/car-sales-ads/$adId',
      data: textData,
      mainImage: mainImage,
      thumbnailImages: thumbnailImages,
      token: token,
    );
  }



  Future<List<MakeModel>> getMakes({required String token}) async {
    final response = await _apiService.get('/api/filters/car-sale/makes', token: token);
    
    if (response is List) {
      return response.map((make) => MakeModel.fromJson(make)).toList();
    }
    // في حال كانت البيانات داخل مفتاح 'data'
    else if (response is Map<String, dynamic> && response['data'] is List) {
       return (response['data'] as List).map((make) => MakeModel.fromJson(make)).toList();
    }
    
    throw Exception('Failed to parse Makes list.');
  }
  
  // +++ دالة جديدة لجلب كل الـ Models التابعة لـ make معين +++
  //  Future<List<CarModel>> getModels({required int makeId, required String token}) async {
  //   // استخدمنا الرابط الديناميكي الصحيح
  //   final response = await _apiService.get('/api/filters/car-sale/makes/$makeId/models', token: token);
    
  //   if (response is List) {
  //     return response.map((model) => CarModel.fromJson(model)).toList();
  //   }
  //   else if (response is Map<String, dynamic> && response['data'] is List) {
  //      return (response['data'] as List).map((model) => CarModel.fromJson(model)).toList();
  //   }
    
  //   throw Exception('Failed to parse Models list from API.');
  // }



   Future<List<TrimModel>> getTrims({required int modelId, required String token}) async {
    final response = await _apiService.get('/api/filters/car-sale/models/$modelId/trims', token: token);
    
    if (kDebugMode) print('RAW API RESPONSE FOR TRIMS (Model ID: $modelId): $response');
    
    // الحالة الأولى: إذا كان الرد قائمة مباشرة
    if (response is List) {
       return response.map((trim) => TrimModel.fromJson(trim)).toList();
    }
    // الحالة الثانية: إذا كان الرد مغلفًا بـ "data"
    else if (response is Map<String, dynamic> && response['data'] is List) {
       return (response['data'] as List).map((trim) => TrimModel.fromJson(trim)).toList();
    }
    
    throw Exception('Failed to parse Trims list. API response is in an unexpected format.');
  }
  
  // --- +++ دالة getModels المعدلة كإجراء وقائي بنفس المنطق +++ ---
  Future<List<CarModel>> getModels({required int makeId, required String token}) async {
    final response = await _apiService.get('/api/filters/car-sale/makes/$makeId/models', token: token);
    
    if (kDebugMode) print('RAW API RESPONSE FOR MODELS (Make ID: $makeId): $response');
    
    // الحالة الأولى: إذا كان الرد قائمة مباشرة
    if (response is List) {
      return response.map((model) => CarModel.fromJson(model)).toList();
    }
    // الحالة الثانية: إذا كان الرد مغلفًا بـ "data"
    else if (response is Map<String, dynamic> && response['data'] is List) {
       return (response['data'] as List).map((model) => CarModel.fromJson(model)).toList();
    }
    
    throw Exception('Failed to parse Models list. API response is in an unexpected format.');
  }


  Future<List<BestAdvertiser>> getBestAdvertiserAds({required String token}) async {
    final response = await _apiService.get('/api/best-advertisers', token: token);
    
    // الرد هو قائمة مباشرة
    if (response is List) {
      return response.map((advertiserJson) => BestAdvertiser.fromJson(advertiserJson)).toList();
    }
    
    throw Exception('Failed to parse Best Advertiser Ads: Expected a List.');
}

Future<List<CarAdModel>> getOfferAds({required String token}) async {
    final response = await _apiService.get('/api/offers-box/car_sales', token: token);
    
    // API العروض غالبًا ما يرسل قائمة مباشرة
    if (response is List) {
      return response.map((adJson) => CarAdModel.fromJson(adJson)).toList();
    }
    // حالة احتياطية إذا كانت مغلفة بـ "data"
    else if (response is Map<String, dynamic> && response['data'] is List) {
       return (response['data'] as List).map((adJson) => CarAdModel.fromJson(adJson)).toList();
    }
    
    throw Exception('Failed to parse Offer Ads list.');
  }


}
