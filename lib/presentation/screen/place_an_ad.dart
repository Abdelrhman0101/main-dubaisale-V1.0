import 'package:advertising_app/constant/string.dart';
import 'package:advertising_app/generated/l10n.dart';
import 'package:advertising_app/presentation/widget/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class PlaceAnAd extends StatelessWidget {
  int selectedOption = 0;

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final s = S.of(context);

    final List<AdOption> adOptions = [
      AdOption(
        title: '${s.premium} ⭐',
        price: '70',
        labelColor: KTextColor,
        features: [
          s.appearance_top,
          s.appearance_nearest,
          s.daily_refresh,
        ],
      ),
      AdOption(
        title: s.premium,
        price: '50',
        labelColor: Color.fromRGBO(1, 84, 126, 1),
        features: [
           '${s.appearance_after_star} ⭐',
          s.appearance_nearest,
          s.daily_refresh,
        ],
      ),
      AdOption(
        title: s.featured,
        price: '40',
        labelColor: Color.fromRGBO(8, 194, 201, 1),
        features: [
          s.appearance_after_premium,
          s.appearance_nearest,
          s.daily_refresh,
        ],
      ),
      AdOption(
        title: s.free,
        price: '0',
        labelColor: Colors.grey,
        features: [
          s.appearance_after_featured,
          s.daily_refresh,
        ],
      ),
    ];

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
                          child: Row(
                            children: [
                              SizedBox(
                                height: 2,
                                child: Radio<int>(
                                  value: index,
                                  groupValue: selectedOption,
                                  activeColor: Color.fromRGBO(245, 247, 250, 1),
                                  focusColor: option.labelColor,
                                  onChanged: (val) => setState(() {
                                    selectedOption = val!;
                                  }),
                                ),
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
                                '${s.cost} [${option.price}] AED ${s.for_days("30")}',
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
                  CustomButton(
                    ontap: () => context.push("/payment"),
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
  
  setState(Null Function() param0) {}
}

class AdOption {
  final String title;
  final String price;
  final List<String> features;
  final Color labelColor;

  AdOption({
    required this.title,
    required this.price,
    required this.features,
    required this.labelColor,
  });
}
