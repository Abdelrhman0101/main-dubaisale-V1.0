// في ملف: data/model/best_advertiser_model.dart

class BestAdvertiserAd {
  final int id;
  final String make;
  final String model;
  final String? trim;
  final String year;
  final String km;
  final String price;
  final String mainImage;
  final String advertiserName;
  // Car service specific fields
  final String? serviceType;
  final String? serviceName;
  final String? district;
  // Restaurant specific fields
  final String? title;
  final String? priceRange;
  final String? emirate;
  final String? area;
  final List<String> images;
  final String? category;

  BestAdvertiserAd({
    required this.id,
    required this.make,
    required this.model,
    this.trim,
    required this.year,
    required this.km,
    required this.price,
    required this.mainImage,
    required this.advertiserName,
    this.serviceType,
    this.serviceName,
    this.district,
    this.title,
    this.priceRange,
    this.emirate,
    this.area,
    this.images = const [],
    this.category,
  });

  // Factory constructor that needs additional data (advertiser ID and name)
  factory BestAdvertiserAd.fromJson(Map<String, dynamic> json, {required int advertiserId, required String advertiserName}) {
    // Parse images list
    List<String> imagesList = [];
    if (json['images'] is List) {
      imagesList = (json['images'] as List).map((img) => img.toString()).toList();
    } else if (json['main_image'] != null) {
      imagesList = [json['main_image'].toString()];
    }
    
    return BestAdvertiserAd(
      id: json['id'] ?? advertiserId,
      make: json['make']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      trim: json['trim']?.toString(),
      year: json['year']?.toString() ?? 'N/A',
      km: json['km']?.toString() ?? 'N/A',
      price: json['price']?.toString() ?? '0',
      mainImage: json['main_image'] ?? '',
      advertiserName: advertiserName,
      serviceType: json['service_type']?.toString(),
      serviceName: json['service_name']?.toString(),
      district: json['district']?.toString(),
      title: json['title']?.toString() ?? json['name']?.toString(),
      priceRange: json['price_range']?.toString() ?? json['price']?.toString(),
      emirate: json['emirate']?.toString(),
      area: json['area']?.toString(),
      images: imagesList,
      category: json['category']?.toString(),
    );
  }
}

class BestAdvertiser {
  final int id;
  final String name;
  final List<BestAdvertiserAd> ads;

  BestAdvertiser({
    required this.id,
    required this.name,
    required this.ads,
  });

  factory BestAdvertiser.fromJson(Map<String, dynamic> json, {String? filterByCategory}) {
    String advertiserName = json['advertiser_name']?.toString() ?? 'Top Dealer'; // Use a default name if null
    int advertiserId = json['id'] ?? 0;
    List<BestAdvertiserAd> parsedAds = [];

    if (json['featured_in'] is List && (json['featured_in'] as List).isNotEmpty) {
      // إذا تم تحديد category للفلترة، نبحث عن الـ category المطلوب
      if (filterByCategory != null) {
        final featuredList = json['featured_in'] as List;
        final matchingCategory = featuredList.firstWhere(
          (item) => item['category'] == filterByCategory,
          orElse: () => null,
        );
        
        if (matchingCategory != null && matchingCategory['latest_ads'] is List) {
          parsedAds = (matchingCategory['latest_ads'] as List)
            .map((adJson) => BestAdvertiserAd.fromJson(adJson, advertiserId: advertiserId, advertiserName: advertiserName))
            .toList();
        }
      } else {
        // إذا لم يتم تحديد category، نأخذ أول عنصر كما كان من قبل
        final featuredData = (json['featured_in'] as List).first;
        if (featuredData['latest_ads'] is List) {
          parsedAds = (featuredData['latest_ads'] as List)
            .map((adJson) => BestAdvertiserAd.fromJson(adJson, advertiserId: advertiserId, advertiserName: advertiserName))
            .toList();
        }
      }
    }

    return BestAdvertiser(
      id: advertiserId,
      name: advertiserName,
      ads: parsedAds,
    );
  }
}