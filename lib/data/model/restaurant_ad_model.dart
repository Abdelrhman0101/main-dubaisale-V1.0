// lib/data/model/restaurant_ad_model.dart
import 'dart:convert';

class RestaurantAdModel {
  final int id;
  final String title;
  final String description;
  final String emirate;
  final String district;
  final String? area;
  final String priceRange;
  final String category;
  final String advertiserName;
  final String phoneNumber;
  final String? whatsappNumber;
  final String? address;
  final String? mainImage;
  final List<String> thumbnailImages;
  final String? createdAt;
  final String? planType;

  RestaurantAdModel({
    required this.id,
    required this.title,
    required this.description,
    required this.emirate,
    required this.district,
    this.area,
    required this.priceRange,
    required this.category,
    required this.advertiserName,
    required this.phoneNumber,
    this.whatsappNumber,
    this.address,
    this.mainImage,
    required this.thumbnailImages,
    this.createdAt,
    this.planType,
  });

  factory RestaurantAdModel.fromJson(Map<String, dynamic> json) {
    // معالجة الصور المصغرة
    List<String> thumbs = [];
    final rawThumbs = json['thumbnail_images_urls'] ?? json['thumbnail_images'];
    
    if (rawThumbs is List) {
      thumbs = rawThumbs.map((e) => e.toString()).toList();
    } else if (rawThumbs is String && rawThumbs.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawThumbs);
        if (decoded is List) {
          thumbs = decoded.map((e) => e.toString()).toList();
        }
      } catch (e) {
        // Handle json parsing error if string is not valid json
      }
    }
    
    return RestaurantAdModel(
      id: json['id'],
      title: json['title'] ?? 'No Title',
      description: json['description'] ?? '',
      emirate: json['emirate'] ?? '',
      district: json['district'] ?? '',
      area: json['area'],
      priceRange: json['price_range'] ?? 'N/A',
      category: json['category'] ?? '',
      advertiserName: json['advertiser_name'] ?? 'N/A',
      phoneNumber: json['phone_number'] ?? 'N/A',
      whatsappNumber: json['whatsapp_number'],
      address: json['address'] ?? json['location'],
      mainImage: json['main_image_url'] ?? json['main_image'],
      thumbnailImages: thumbs,
      createdAt: json['created_at'],
      planType: json['plan_type'],
    );
  }
}