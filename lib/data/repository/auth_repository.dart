import 'package:advertising_app/data/model/user_model.dart';
import 'package:advertising_app/data/web_services/api_service.dart';

class AuthRepository {
  // 1. هنا نستخدم Composition: الـ AuthRepository "يمتلك" ApiService
  final ApiService _apiService;

  // 2. نقوم بحقن (Inject) الـ ApiService من خلال الـ constructor
  // ده بيخلي الكود قابل للاختبار بسهولة
  AuthRepository(this._apiService);

  // 3. دالة تسجيل الدخول: هي اللي تعرف الـ endpoint وتجهز البيانات
   Future<Map<String, dynamic>> login({
    required String identifier, // يستقبل إما إيميل أو هاتف
    required String password,
  }) async {
    final Map<String, dynamic> loginData = {
      'identifier': identifier,
      'password': password,
    };
    
    // تأكد من أن '/api/login' هو الـ URL الصحيح لكلا الحالتين
    final response = await _apiService.post('/api/login', data: loginData);

    if (response is Map<String, dynamic> && response.containsKey('access_token')) {
      return response;
    } else {
      throw Exception('Login response is not valid or access_token is missing.');
    }
  }

  
  
  // 4. دالة إنشاء حساب جديد بنفس الطريقة

    Future<void> signUp({
    required String username,
    required String email,
    required String password,
    required String phone,
    required String whatsapp,
    required String role,
  }) async {
     final Map<String, dynamic> signUpData = {
      'username': username,
      'email': email,
      'password': password,
      'phone': phone,
      'whatsapp': whatsapp,
      'role': role,
     };
    
    await _apiService.post('/api/signup', data: signUpData);
  }

   Future<void> logout({required String token}) async {
    // استدعاء endpoint تسجيل الخروج باستخدام POST وإرسال التوكن في الـ Header
    // ApiService سيقوم بإضافة "Bearer " تلقائيًا
    await _apiService.post(
      '/api/logout',
      data: {}, // غالبًا ما يكون الـ Body فارغًا
      token: token,
    );
  }

  
   Future<UserModel> getUserProfile({required String token}) async {
    // استخدمنا GET لأننا نجلب بيانات
    final response = await _apiService.get('/api/user', token: token);
    
    if (response is Map<String, dynamic>) {
      return UserModel.fromJson(response);
    }
    throw Exception('Failed to parse user profile.');
  }


  Future<UserModel> updateProfile({
    required String token,
    required String username,
    required String email,
    required String phone,
    String? whatsapp,
    String? advertiserName,
    String? advertiserType,
    String? advertiserLogo,
    double? latitude,
    double? longitude,
    String? address,
  }) async {
    final Map<String, dynamic> data = {
      'username': username,
      'email': email,
      'phone': phone,
      'whatsapp': whatsapp,
      'advertiser_name': advertiserName,
      'advertiser_type': advertiserType,
      'advertiser_logo': advertiserLogo,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
    };

    final response = await _apiService.post(
      '/api/profile',
      data: data,
      token: token
    );

    // الـ API يرجع بيانات المستخدم المحدثة
    if (response is Map<String, dynamic>) {
      return UserModel.fromJson(response);
    }
    throw Exception('Failed to parse updated user profile.');
  }

  Future<UserModel> uploadLogo({
    required String token,
    required String logoPath,
  }) async {
    final response = await _apiService.uploadFile(
      '/api/profile/logo',
      filePath: logoPath,
      fieldName: 'advertiser_logo',
      token: token,
    );

    if (response is Map<String, dynamic>) {
      return UserModel.fromJson(response);
    }
    throw Exception('Failed to upload logo.');
  }

  Future<UserModel> deleteLogo({
    required String token,
  }) async {
    final response = await _apiService.post(
      '/api/profile/logo/delete',
      data: {},
      token: token,
    );

    if (response is Map<String, dynamic>) {
      return UserModel.fromJson(response);
    }
    throw Exception('Failed to delete logo.');
  }
  
  // --- الدالة الجديدة لتحديث كلمة المرور ---
  Future<void> updatePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async {
    final Map<String, dynamic> data = {
      'current_password': currentPassword,
      'new_password': newPassword,
      'new_password_confirmation': newPassword,
    };
    
    await _apiService.post(
      '/api/profile/password',
      data: data,
      token: token,
    );
  }

}