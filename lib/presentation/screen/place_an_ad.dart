import 'package:advertising_app/constant/string.dart';
import 'package:advertising_app/generated/l10n.dart';
import 'package:advertising_app/presentation/providers/car_services_ad_provider.dart';
import 'package:advertising_app/presentation/widget/custom_button.dart';
import 'package:advertising_app/presentation/providers/car_sales_ad_provider.dart';
import 'package:advertising_app/presentation/providers/restaurants_ad_provider.dart';
import 'package:advertising_app/presentation/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class PlaceAnAd extends StatefulWidget {
  final Map<String, dynamic>? adData;
  
  const PlaceAnAd({Key? key, this.adData}) : super(key: key);
  
  @override
  State<PlaceAnAd> createState() => _PlaceAnAdState();
}

class _PlaceAnAdState extends State<PlaceAnAd> {
  int selectedOption = 0;
  bool _isSubmitting = false;
  bool _isLoadingSettings = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final settingsProvider = context.read<SettingsProvider>();
      await settingsProvider.fetchSystemSettings();
      if (mounted) {
        setState(() {
          _isLoadingSettings = false;
        });
      }
    });
  }


  Future<void> _submitAdWithType() async {
    if (widget.adData == null || widget.adData!['adType'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('بيانات الإعلان غير كاملة'), backgroundColor: Colors.red));
      return;
    }

    setState(() { _isSubmitting = true; });

    try {
      // 1. تجهيز بيانات الخطة
      final adOptions = _getAdOptions();
      final selectedAdOption = adOptions[selectedOption];
      final expiresAt = DateTime.now().add(Duration(days: selectedAdOption.duration));
      String planType;
      if (selectedAdOption.title.contains('⭐')) { planType = 'premium_star'; } 
      else if (selectedAdOption.title.toLowerCase().contains('premium')) { planType = 'premium'; }
      else if (selectedAdOption.title.toLowerCase().contains('featured')) { planType = 'featured'; }
      else { planType = 'free'; }

      // إضافة بيانات الخطة إلى بيانات الإعلان
      widget.adData!['planType'] = planType;
      widget.adData!['planDays'] = selectedAdOption.duration;
      widget.adData!['planExpiresAt'] = expiresAt.toIso8601String();

      // 2. تحديد نوع الإعلان واستدعاء الـ Provider الصحيح
      final String adType = widget.adData!['adType'];
      bool success = false;
      String? submissionError;

      if (adType == 'car_sale') {
        final provider = context.read<CarAdProvider>();
        success = await provider.submitCarAd(
          widget.adData!, // المعامل الأول المطلوب
          // نمرر البيانات من الـ map هنا
          title: widget.adData!['title'], description: widget.adData!['description'], make: widget.adData!['make'], model: widget.adData!['model'],
          trim: widget.adData!['trim'], year: widget.adData!['year'], km: widget.adData!['km'], price: widget.adData!['price'],
          specs: widget.adData!['specs'], carType: widget.adData!['carType'], transType: widget.adData!['transType'], fuelType: widget.adData!['fuelType'],
          color: widget.adData!['color'], interiorColor: widget.adData!['interiorColor'], warranty: widget.adData!['warranty'],
          engineCapacity: widget.adData!['engineCapacity'], cylinders: widget.adData!['cylinders'], horsepower: widget.adData!['horsepower'],
          doorsNo: widget.adData!['doorsNo'], seatsNo: widget.adData!['seatsNo'], steeringSide: widget.adData!['steeringSide'],
          advertiserName: widget.adData!['advertiserName'], phoneNumber: widget.adData!['phoneNumber'], whatsapp: widget.adData!['whatsapp'],
          emirate: widget.adData!['emirate'], area: widget.adData!['area'], advertiserType: widget.adData!['advertiverType'],
          mainImage: widget.adData!['mainImage'], thumbnailImages: widget.adData!['thumbnailImages'],
          // تمرير بيانات الخطة
          planType: widget.adData!['planType'], planDays: widget.adData!['planDays'], planExpiresAt: widget.adData!['planExpiresAt'],
        );
        submissionError = provider.createAdError;

      } else if (adType == 'car_service') {
        final provider = context.read<CarServicesAdProvider>();
        success = await provider.submitCarServiceAd(widget.adData!);
        submissionError = provider.error;
      } else if (adType == 'restaurant') {
        final provider = context.read<RestaurantsAdProvider>();
        success = await provider.submitRestaurantAd(widget.adData!);
        submissionError = provider.error;
      }

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نشر الإعلان بنجاح!'), backgroundColor: Colors.green));
        context.go('/home'); // أو العودة للصفحة الرئيسية
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(submissionError ?? 'فشل في نشر الإعلان'), backgroundColor: Colors.red));
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() { _isSubmitting = false; });
      }
    }
}

  // دالة إرسال الإعلان مع نوع الإعلان المحدد
  // Future<void> _submitAdWithType() async {
  //   if (widget.adData == null) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('لا توجد بيانات إعلان لإرسالها'),
  //         backgroundColor: Colors.red,
  //       ),
  //     );
  //     return;
  //   }

  //   setState(() {
  //     _isSubmitting = true;
  //   });

  //   try {
  //     final provider = context.read<CarAdProvider>();
  //     final adOptions = _getAdOptions();
  //     final selectedAdOption = adOptions[selectedOption];
      
  //     // حساب تاريخ انتهاء الباقة
  //     final now = DateTime.now();
  //     final expiresAt = now.add(Duration(days: selectedAdOption.duration));
  //     final planExpiresAtString = expiresAt.toIso8601String();
      
  //     // تحديد نوع الباقة بناءً على العنوان
  //     String planType;
  //     if (selectedAdOption.title.contains('⭐')) {
  //       planType = 'premium_star';
  //     } else if (selectedAdOption.title.toLowerCase().contains('premium')) {
  //       planType = 'premium';
  //     } else if (selectedAdOption.title.toLowerCase().contains('featured')) {
  //       planType = 'featured';
  //     } else {
  //       planType = 'free';
  //     }
      
  //     final success = await provider.submitCarAd(
  //       title: widget.adData!['title'],
  //       description: widget.adData!['description'],
  //       make: widget.adData!['make'],
  //       model: widget.adData!['model'],
  //       trim: widget.adData!['trim'],
  //       year: widget.adData!['year'],
  //       km: widget.adData!['km'],
  //       price: widget.adData!['price'],
  //       specs: widget.adData!['specs'],
  //       carType: widget.adData!['carType'],
  //       transType: widget.adData!['transType'],
  //       fuelType: widget.adData!['fuelType'],
  //       color: widget.adData!['color'],
  //       interiorColor: widget.adData!['interiorColor'],
  //       warranty: widget.adData!['warranty'],
  //       engineCapacity: widget.adData!['engineCapacity'],
  //       cylinders: widget.adData!['cylinders'],
  //       horsepower: widget.adData!['horsepower'],
  //       doorsNo: widget.adData!['doorsNo'],
  //       seatsNo: widget.adData!['seatsNo'],
  //       steeringSide: widget.adData!['steeringSide'],
  //       advertiserName: widget.adData!['advertiserName'],
  //       phoneNumber: widget.adData!['phoneNumber'],
  //       whatsapp: widget.adData!['whatsapp'],
  //       emirate: widget.adData!['emirate'],
  //       area: widget.adData!['area'],
  //       advertiserType: widget.adData!['advertiserType'],
  //       mainImage: widget.adData!['mainImage'],
  //       thumbnailImages: widget.adData!['thumbnailImages'],
  //       planType: planType,
  //       planDays: selectedAdOption.duration,
  //       planExpiresAt: planExpiresAtString,
  //     );

  //     if (!mounted) return;
      
  //     if (success) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //           content: Text('تم نشر الإعلان بنجاح!'),
  //           backgroundColor: Colors.green,
  //         ),
  //       );
  //       // العودة إلى الصفحة الرئيسية مع إرسال إشارة النجاح
  //       context.pop('success');
  //     } else {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text(provider.createAdError ?? 'فشل في نشر الإعلان'),
  //           backgroundColor: Colors.red,
  //         ),
  //       );
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('حدث خطأ: $e'),
  //           backgroundColor: Colors.red,
  //         ),
  //       );
  //     }
  //   } finally {
  //     if (mounted) {
  //       setState(() {
  //         _isSubmitting = false;
  //       });
  //     }
  //   }
  // }

  List<AdOption> _getAdOptions() {
    final s = S.of(context);
    final settingsProvider = context.read<SettingsProvider>();
    
    // Check if free ad is eligible based on car price
    final carPrice = double.tryParse(widget.adData?['price']?.toString() ?? '0') ?? 0;
    final isFreeAdEligible = settingsProvider.canPostFreeAd(carPrice);
    
    List<AdOption> options = [
      AdOption(
        title: '${s.premium} ⭐',
        price: settingsProvider.getPlanPrice('premium_star').toStringAsFixed(0),
        duration: settingsProvider.getPlanDuration('premium_star'),
        labelColor: KTextColor,
        features: [
          s.appearance_top,
          s.appearance_nearest,
          s.daily_refresh,
        ],
      ),
      AdOption(
        title: s.premium,
        price: settingsProvider.getPlanPrice('premium').toStringAsFixed(0),
        duration: settingsProvider.getPlanDuration('premium'),
        labelColor: Color.fromRGBO(1, 84, 126, 1),
        features: [
          '${s.appearance_after_star} ⭐',
          s.appearance_nearest,
          s.daily_refresh,
        ],
      ),
      AdOption(
        title: s.featured,
        price: settingsProvider.getPlanPrice('featured').toStringAsFixed(0),
        duration: settingsProvider.getPlanDuration('featured'),
        labelColor: Color.fromRGBO(8, 194, 201, 1),
        features: [
          s.appearance_after_premium,
          s.appearance_nearest,
          s.daily_refresh,
        ],
      ),
    ];
    
    // Add free option only if eligible
    if (isFreeAdEligible) {
      options.add(
        AdOption(
          title: s.free,
          price: '0',
          duration: settingsProvider.getFreeAdCycleDays(),
          labelColor: Colors.grey,
          features: [
            s.appearance_after_featured,
            s.daily_refresh,
          ],
        ),
      );
    }
    
    return options;
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final s = S.of(context);

    // Show loading while fetching settings
    if (_isLoadingSettings) {
      return Directionality(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(KTextColor),
                ),
                SizedBox(height: 16),
                Text(
                  isArabic ? 'جاري تحميل الإعدادات...' : 'Loading settings...',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: KTextColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final List<AdOption> adOptions = _getAdOptions();
    
    // Check if free ad is not available and show message
    final settingsProvider = context.read<SettingsProvider>();
    final carPrice = double.tryParse(widget.adData?['price']?.toString() ?? '0') ?? 0;
    final isFreeAdEligible = settingsProvider.canPostFreeAd(carPrice);
    final maxFreePrice = settingsProvider.systemSettings?.maxPriceFreeAdCarsSales ?? 120000;

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            SizedBox(height: 50.h),
            GestureDetector(
              onTap: () => context.pop(),
              child: Row(
                children: [
                  const SizedBox(width: 18),
                  Icon(Icons.arrow_back_ios, color: KTextColor, size: 17.sp),
                  Transform.translate(
                    offset: Offset(-3.w, 0),
                    child: Text(
                      S.of(context).back,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: KTextColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 5.h),
            Center(
              child: Text(
                s.post,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 24.sp,
                  color: KTextColor,
                ),
              ),
            ),
            SizedBox(height: 5.h),
            // Show message if free ad is not eligible
            if (!isFreeAdEligible && maxFreePrice > 0)
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  border: Border.all(color: Colors.orange.shade300),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange.shade700,
                      size: 20.sp,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        isArabic
                            ? 'الإعلان المجاني متاح فقط للسيارات بسعر أقل من ${maxFreePrice.toStringAsFixed(0)} درهم'
                            : 'Free ads are only available for cars priced under ${maxFreePrice.toStringAsFixed(0)} AED',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemCount: adOptions.length,
                separatorBuilder: (_, __) => SizedBox(height: 5),
                itemBuilder: (context, index) {
                  final option = adOptions[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                          color: Color.fromRGBO(181, 179, 177, 0.98)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    // padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Container الملون اللي في أول السطر
                        Container(
                          height: 40.h,
                          width: double.infinity,
                          padding:
                              EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8)),
                            color: index == 3 ? null : option.labelColor,
                            gradient: index == 3
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFFE4F8F6),
                                      Color(0xFFC9F8FE)
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  )
                                : null,
                          ),
                          child: GestureDetector(
                            onTap: () => setState(() {
                              selectedOption = index;
                            }),
                            child: Row(
                              children: [
                                Radio<int>(
                                  value: index,
                                  groupValue: selectedOption,
                                  activeColor: index == 3 ? KTextColor : Color.fromRGBO(245, 247, 250, 1),
                                  focusColor: option.labelColor,
                                  onChanged: (val) => setState(() {
                                    selectedOption = val!;
                                  }),
                                ),
                                Text(
                                  option.title,
                                  style: TextStyle(
                                    color: index == 3
                                        ? KTextColor
                                        : Color.fromRGBO(245, 247, 250, 1),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        ...option.features.map(
                          (f) => Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('• ',
                                    style: TextStyle(
                                        fontSize: 16,
                                        color: Color.fromRGBO(0, 30, 90, 1))),
                                Expanded(
                                  child: Text(
                                    f,
                                    style: TextStyle(
                                      color: Color.fromRGBO(0, 30, 90, 1),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          child: Row(
                            children: [
                              Text('• ',
                                  style: TextStyle(
                                      fontSize: 16,
                                      color: Color.fromRGBO(0, 30, 90, 1))),
                              Text(
                                '${s.cost} [${option.price}] AED ${s.for_days(option.duration.toString())}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color.fromRGBO(0, 30, 90, 1),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 18),
              child: Column(
                children: [
                  _isSubmitting
                      ? const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(KTextColor),
                          ),
                        )
                      : CustomButton(
                          ontap: _submitAdWithType,
                          text: s.submit,
                        ),
                  // SizedBox(height: 8),
                  // Text(
                  //   s.top_of_day_note,
                  //   style: TextStyle(
                  //       fontSize: 14,
                  //       fontWeight: FontWeight.w500,
                  //       color: Color.fromRGBO(129, 126, 126, 1)),
                  // ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  

}

class AdOption {
  final String title;
  final String price;
  final int duration;
  final List<String> features;
  final Color labelColor;

  AdOption({
    required this.title,
    required this.price,
    required this.duration,
    required this.features,
    required this.labelColor,
  });
}
