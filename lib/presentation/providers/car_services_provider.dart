// lib/presentation/providers/car_services_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:advertising_app/data/model/car_service_ad_model.dart';
import 'package:advertising_app/data/repository/car_services_ad_repository.dart';
import 'package:advertising_app/data/web_services/api_service.dart';

class CarServicesProvider extends ChangeNotifier {
  final CarServicesAdRepository _repository;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  CarServicesProvider() : _repository = CarServicesAdRepository(ApiService());

  List<CarServiceModel> _ads = [];
  bool _isLoading = false;
  String? _error;

  List<CarServiceModel> get ads => _ads;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Future<void> fetchAds({Map<String, String>? filters}) async {
  //   _isLoading = true;
  //   _error = null;
  //   notifyListeners();

  //   try {
  //     final token = await _storage.read(key: 'auth_token');
  //     if (token == null) {
  //       throw Exception('Authentication token not found');
  //     }

  //     final response = await _repository.getCarServiceAds(token: token);
  //     _ads = response.ads;

  //   } catch (e) {
  //     _error = e.toString();
  //   } finally {
  //     _isLoading = false;
  //     notifyListeners();
  //   }
  // }


Future<void> fetchAds({Map<String, String>? filters}) async { // ++ أضف filters هنا
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) throw Exception('Authentication token not found');

      // ++ تمرير الفلاتر إلى Repository
      final response = await _repository.getCarServiceAds(token: token, query: filters);
      _ads = response.ads;

    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }





}}