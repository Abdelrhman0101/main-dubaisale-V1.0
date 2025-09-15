import 'package:advertising_app/data/model/my_ad_model.dart';
import 'package:advertising_app/data/web_services/api_service.dart';

class ManageAdsRepository {
  final ApiService _apiService;
  ManageAdsRepository(this._apiService);

  Future<MyAdsResponse> getMyAds({required String token}) async {
    // يمكن إضافة query parameters هنا إذا احتجت للـ pagination
    // مثال: final response = await _apiService.get('/api/my-ads', token: token, query: {'page': 1});
    final response = await _apiService.get('/api/my-ads', token: token);

    if (response is Map<String, dynamic>) {
      return MyAdsResponse.fromJson(response);
    }
    
    throw Exception('Failed to parse MyAdsResponse');
  }


  Future<void> activateOffer({
    required String token,
    required int adId,
    required String categorySlug,
    required int days,
  }) async {
    final body = {
      'ad_id': adId,
      'category_slug': categorySlug,
      'days': days,
    };
    
    print('=== REPOSITORY ACTIVATE OFFER ===');
    print('Endpoint: /api/offers-box/activate');
    print('Body: $body');
    print('Token: ${token.substring(0, 20)}...');
    print('================================');
    
    try {
      // استخدم دالة 'post' الموجودة في ApiService
      final response = await _apiService.post('/api/offers-box/activate', data: body, token: token);
      
      print('=== REPOSITORY SUCCESS ===');
      print('Response: $response');
      print('=========================');
    } catch (e) {
      print('=== REPOSITORY ERROR ===');
      print('Error: $e');
      print('=======================');
      rethrow;
    }
  }
}