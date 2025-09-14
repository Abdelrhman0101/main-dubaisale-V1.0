import 'package:advertising_app/data/model/user_model.dart';
import 'package:advertising_app/data/repository/auth_repository.dart';
import 'package:flutter/material.dart';
// <-- تأكد 100% من وجود هذا الـ import
import 'package:flutter_secure_storage/flutter_secure_storage.dart';


class AuthProvider with ChangeNotifier {
  final AuthRepository _authRepository;

  // إنشاء نسخة واحدة وثابتة من الـ storage لاستخدامها في كل الدوال
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  AuthProvider(this._authRepository);

  // دالة للتحقق من وجود جلسة مخزنة
  Future<bool> checkStoredSession() async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token != null && token.isNotEmpty) {
        // إذا وُجد token، نحاول جلب بيانات المستخدم للتأكد من صحة الجلسة
        await fetchUserProfile();
        return true;
      }
      return false;
    } catch (e) {
      // إذا فشل في جلب البيانات، نحذف الـ token المعطوب
      await _storage.delete(key: 'auth_token');
      return false;
    }
  }

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  UserModel? _user;
  UserModel? get user => _user;

  bool _isLoadingProfile = false;
  bool get isLoadingProfile => _isLoadingProfile;

  String? _profileError;
  String? get profileError => _profileError;

   bool _isUpdating = false;
  String? _updateError;
  bool get isUpdating => _isUpdating;
  String? get updateError => _updateError;

  

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
  }
  
    Future<bool> login({required String identifier, required String password}) async {
    _setError(null);
    _setLoading(true);
    try {
      final response = await _authRepository.login(identifier: identifier, password: password);
      final token = response['access_token']; 
      await _storage.write(key: 'auth_token', value: token);
      print("Token stored successfully!");
      _setLoading(false);
      return true; 
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }
   
   
   Future<bool> signUp({
    required String username,
    required String email,
    required String password,
    required String phone,
    required String role,
  }) async {
    _setError(null);
    _setLoading(true);
    try {
      await _authRepository.signUp(
        username: username,
        email: email,
        password: password,
        phone: phone,
        whatsapp: phone,
        role: role,
      );
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

 Future<bool> logout() async {
    _setError(null);
    // يمكنك اختيار عرض مؤشر تحميل أو لا. سأقوم بتفعيله.
    _setLoading(true);

    try {
      // 1. قراءة التوكن المخزن حاليًا
      final token = await _storage.read(key: 'auth_token');
      if (token == null) {
        // إذا لم يكن هناك توكن، فالمستخدم مسجل خروجه بالفعل
        _setLoading(false);
        return true;
      }
      
      // 2. استدعاء API تسجيل الخروج عبر الـ Repository
      await _authRepository.logout(token: token);
      
      // 3. (الأهم) حذف التوكن من التخزين المحلي بعد نجاح الطلب
      await _storage.delete(key: 'auth_token');
      print("Token deleted. Logout successful!");

      _setLoading(false);
      return true; // إرجاع true علامة على النجاح
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      // كإجراء احترازي، قم بحذف التوكن المحلي حتى لو فشل الاتصال بالسيرفر
      // هذا يضمن أن المستخدم لن يبقى عالقًا في حالة تسجيل دخول خاطئة
      await _storage.delete(key: 'auth_token');
      return false; // إرجاع false علامة على الفشل
    }
  }

  Future<void> fetchUserProfile() async {
    _isLoadingProfile = true;
    _profileError = null;
    notifyListeners();
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) throw Exception('User not authenticated.');

      // --- هذا هو الإصلاح: تمرير التوكن إلى الـ Repository ---
      final userProfile = await _authRepository.getUserProfile(token: token);
      _user = userProfile;

    } catch (e) {
      _profileError = e.toString();
      print("Error fetching profile: $e");
    } finally {
      _isLoadingProfile = false;
      notifyListeners();
    }
  }


  Future<bool> updateUserProfile({
    required String username, required String email, required String phone,
    String? whatsapp, String? advertiserName, String? advertiserType,
    double? latitude, double? longitude, String? address, String? advertiserLocation,
  }) async {
    _isUpdating = true; 
    _updateError = null;
    notifyListeners();
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) throw Exception('Not authenticated.');
      final updatedUser = await _authRepository.updateProfile(
          token: token, username: username, email: email, phone: phone,
          whatsapp: whatsapp, advertiserName: advertiserName, advertiserType: advertiserType,
          latitude: latitude, longitude: longitude, address: address, advertiserLocation: advertiserLocation
      );
      _user = updatedUser;
      
      // Refresh user profile from server to ensure we have latest data
      await fetchUserProfile();
      
      return true;
    } catch (e) {
      _updateError = e.toString();
      return false;
    } finally {
      _isUpdating = false; notifyListeners();
    }
  }

  // --- دالة تحديث كلمة المرور المعدلة ---
  Future<bool> updateUserPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _isUpdating = true;
    _updateError = null;
    notifyListeners();
    try {
       final token = await _storage.read(key: 'auth_token');
       if (token == null) throw Exception('Not authenticated.');
       await _authRepository.updatePassword(token: token, currentPassword: currentPassword, newPassword: newPassword);
       return true;
    } catch(e) {
      _updateError = e.toString();
      return false;
    } finally {
       _isUpdating = false; notifyListeners();
    }
  }

  Future<bool> uploadLogo(String logoPath) async {
    _isUpdating = true;
    _updateError = null;
    notifyListeners();
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) throw Exception('Not authenticated.');
      
      final updatedUser = await _authRepository.uploadLogo(
        token: token,
        logoPath: logoPath,
      );
      
      _user = updatedUser;
      return true;
    } catch (e) {
      _updateError = e.toString();
      return false;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  Future<bool> deleteLogo() async {
    _isUpdating = true;
    _updateError = null;
    notifyListeners();
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) throw Exception('Not authenticated.');
      
      final updatedUser = await _authRepository.deleteLogo(token: token);
      _user = updatedUser;
      return true;
    } catch (e) {
      _updateError = e.toString();
      return false;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }
   
   
   
   
   
   
   
   
   }
