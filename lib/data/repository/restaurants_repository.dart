// lib/data/repository/restaurants_repository.dart

import 'dart:io';
import 'package:advertising_app/data/model/car_service_filter_models.dart'; // لإعادة استخدام EmirateModel
import 'package:advertising_app/data/model/restaurant_ad_model.dart';
import 'package:advertising_app/data/model/restaurant_models.dart';
import 'package:advertising_app/data/model/best_advertiser_model.dart';
import 'package:advertising_app/data/web_services/api_service.dart';

class RestaurantsRepository {
  final ApiService _apiService;
  RestaurantsRepository(this._apiService);

  // دالة لجلب فئات المطاعم من الـ API
  Future<List<RestaurantCategoryModel>> getRestaurantCategories({required String token}) async {
    final response = await _apiService.get('/api/restaurant-categories', token: token);

    // نفترض أن الـ API يرجع قائمة مباشرة أو داخل مفتاح "data" أو "categories"
    List<dynamic> categoriesJson = [];
    if (response is List) {
      categoriesJson = response;
    } else if (response is Map<String, dynamic>) {
      // تحقق من المفاتيح الشائعة
      if (response.containsKey('data')) categoriesJson = response['data'];
      else if (response.containsKey('categories')) categoriesJson = response['categories'];
      else throw Exception('Cannot find categories list in API response');
    }
    
    return categoriesJson.map((json) => RestaurantCategoryModel.fromJson(json)).toList();
  }

  // دالة لجلب الإمارات (مُعادة الاستخدام من الأقسام الأخرى)
  Future<List<EmirateModel>> getEmirates({required String token}) async {
    final response = await _apiService.get('/api/locations/emirates', token: token);
    if (response is Map<String, dynamic> && response.containsKey('emirates')) {
      final List<dynamic> emiratesJson = response['emirates'];
      return emiratesJson.map((json) => EmirateModel.fromJson(json)).toList();
    }
    throw Exception('Failed to parse emirates from API response.');
  }

  // دالة لجلب المطاعم مع الفلاتر
  Future<List<dynamic>> getRestaurants({
    required String token,
    String? emirate,
    String? district,
    String? category,
    String? priceFrom,
    String? priceTo,
  }) async {
    // بناء query parameters
    Map<String, String> queryParams = {};
    
    if (emirate != null && emirate != 'All') {
      queryParams['emirate'] = emirate;
    }
    if (district != null && district != 'All') {
      queryParams['district'] = district;
    }
    if (category != null && category != 'All') {
      queryParams['category'] = category;
    }
    if (priceFrom != null && priceFrom.isNotEmpty) {
      queryParams['price_from'] = priceFrom;
    }
    if (priceTo != null && priceTo.isNotEmpty) {
      queryParams['price_to'] = priceTo;
    }
    
    // بناء URL مع query parameters
    String url = '/api/restaurants';
    if (queryParams.isNotEmpty) {
      final queryString = queryParams.entries
          .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
      url += '?$queryString';
    }
    
    final response = await _apiService.get(url, token: token);
    
    // معالجة الاستجابة
    if (response is Map<String, dynamic>) {
      if (response.containsKey('data')) {
        return response['data'] as List<dynamic>;
      } else if (response.containsKey('restaurants')) {
        return response['restaurants'] as List<dynamic>;
      }
    } else if (response is List<dynamic>) {
      return response;
    }
    
    return [];
  }

  // دالة لإنشاء إعلان مطعم جديد
  Future<void> createRestaurantAd({
    required String token,
    required String title,
    required String description,
    required String emirate,
    required String district,
    required String area,
    required String priceRange, // انتبه: الاسم هنا مطابق للـ API
    required String category,
    required String advertiserName,
    required String phoneNumber,
    String? whatsappNumber,
    required String address,
    File? mainImage,
    required List<File> thumbnailImages,
    // بيانات الخطة
    required String planType,
    required int planDays,
    required String planExpiresAt,
  }) async {
    // التحقق من وجود الصورة الرئيسية
    if (mainImage == null) {
      throw Exception('الصورة الرئيسية مطلوبة لإنشاء إعلان المطعم');
    }

    final Map<String, dynamic> textData = {
      'title': title,
      'description': description,
      'emirate': emirate,
      'district': district,
      'area': area,
      'price_range': priceRange, // استخدام المفتاح الصحيح
      'category': category,
      'advertiser_name': advertiserName,
      'phone_number': phoneNumber,
      'whatsapp_number': whatsappNumber,
      'address': address,
      'plan_type': planType,
      'plan_days': planDays,
      'plan_expires_at': planExpiresAt,
    };
    
    await _apiService.postFormData(
      '/api/restaurants',
      data: textData,
      mainImage: mainImage,
      thumbnailImages: thumbnailImages,
      token: token,
    );
  }

  Future<RestaurantAdModel> getRestaurantAdDetails({required int adId, required String token}) async {
    final response = await _apiService.get('/api/restaurants/$adId', token: token);
    
    if (response is Map<String, dynamic>) {
      // الـ API قد يغلف البيانات داخل مفتاح "data"
      if (response.containsKey('data') && response['data'] is Map<String, dynamic>) {
        return RestaurantAdModel.fromJson(response['data']);
      }
      // أو قد يرسلها مباشرة
      return RestaurantAdModel.fromJson(response);
    }
    
    throw Exception('API response format is not as expected for RestaurantAdModel.');
  }

  // دالة لجلب أفضل المعلنين للمطاعم
  Future<List<BestAdvertiser>> getTopRestaurants({required String token, String? category}) async {
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
    
    throw Exception('Failed to parse Top Restaurants list from API response.');
  }
}








