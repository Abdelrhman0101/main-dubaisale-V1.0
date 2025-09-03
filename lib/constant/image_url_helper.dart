class ImageUrlHelper {
  // الحصول على baseUrl (يجب أن يتطابق مع ApiService)
  static const String _baseUrl = 'https://dubaisale.app';

  /// تحويل مسار الصورة النسبي إلى URL كامل
  /// مثال: "cars/main/image.jpg" -> "http://192.168.1.7:8000/storage/cars/main/image.jpg"
  static String getFullImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return '';
    }
    
    // إذا كان المسار يحتوي بالفعل على http أو https، فهو URL كامل
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }
    
    // إضافة baseUrl + /storage/ + مسار الصورة
    return '$_baseUrl/storage/$imagePath';
  }

  /// تحويل قائمة من مسارات الصور إلى URLs كاملة
  static List<String> getFullImageUrls(List<String>? imagePaths) {
    if (imagePaths == null || imagePaths.isEmpty) {
      return [];
    }
    
    return imagePaths.map((path) => getFullImageUrl(path)).toList();
  }

  /// الحصول على URL الصورة الرئيسية
  static String getMainImageUrl(String? mainImagePath) {
    return getFullImageUrl(mainImagePath);
  }

  /// الحصول على URLs الصور المصغرة
  static List<String> getThumbnailImageUrls(List<String>? thumbnailPaths) {
    return getFullImageUrls(thumbnailPaths);
  }
}