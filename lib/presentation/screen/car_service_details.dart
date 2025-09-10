import 'package:advertising_app/generated/l10n.dart';
import 'package:advertising_app/data/model/car_service_ad_model.dart';
import 'package:flutter/material.dart';
import 'package:advertising_app/constant/string.dart';
import 'package:advertising_app/constant/image_url_helper.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:readmore/readmore.dart';

class CarServiceDetails extends StatefulWidget {
  final CarServiceModel car_service;
  const CarServiceDetails({super.key, required this.car_service});

  @override
  State<CarServiceDetails> createState() => _CarServiceDetailsState();
}

class _CarServiceDetailsState extends State<CarServiceDetails> {
  int _currentPage = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));
    final car_service = widget.car_service;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: SafeArea(
        top: false,
        child: Scaffold(
          extendBodyBehindAppBar: true, // يخلي الخلفية ورا الستاتس بار

          backgroundColor: Colors.white, // اجعل خلفية الـ Scaffold شفافة

          body: SingleChildScrollView(
            child: Column(
              children: [
                Stack(
                  children: [
                    SizedBox(
                      height: 238.h,
                      width: double.infinity,
                      child: car_service.thumbnailImages.isNotEmpty
                          ? PageView.builder(
                              controller: _pageController,
                              itemCount: car_service.thumbnailImages.length,
                              onPageChanged: (index) =>
                                  setState(() => _currentPage = index),
                              itemBuilder: (context, index) => Image.network(
                                ImageUrlHelper.getFullImageUrl(car_service.thumbnailImages[index]),
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.image_not_supported,
                                      size: 50,
                                      color: Colors.grey,
                                    ),
                                  );
                                },
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                              loadingProgress.expectedTotalBytes!
                                          : null,
                                    ),
                                  );
                                },
                              )
                            )
                          : car_service.mainImage != null
                              ? Image.network(
                                  ImageUrlHelper.getFullImageUrl(car_service.mainImage!),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[300],
                                      child: const Icon(
                                        Icons.image_not_supported,
                                        size: 50,
                                        color: Colors.grey,
                                      ),
                                    );
                                  },
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded /
                                                loadingProgress.expectedTotalBytes!
                                            : null,
                                      ),
                                    );
                                  },
                                )
                              : Container(
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                ),
                    ),
                    // Back button
                    Positioned(
                      top: 40.h,
                      left: isArabic ? null : 15.w,
                      right: isArabic ? 15.w : null,
                      child: GestureDetector(
                        onTap: () => context.pop(),
                        child: GestureDetector(
                          onTap: () => context.pop(),
                          child: Row(
                            children: [
                              const SizedBox(width: 2),
                              SizedBox(
                                width: 15,
                                child: const Icon(
                                  Icons.arrow_back_ios,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              Text(
                                S.of(context).back,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Favorite icon
                    Positioned(
                      top: 40.h,
                      left: isArabic ? 16.w : null,
                      right: isArabic ? null : 16.w,
                      child: Icon(
                        Icons.favorite_border,
                        color: Colors.white,
                        size: 30.sp,
                      ),
                    ),

                    Positioned(
                      top: 80.h,
                      left: isArabic ? 16.w : null,
                      right: isArabic ? null : 16.w,
                      child: Icon(
                        Icons.share,
                        color: Colors.white,
                        size: 30.sp,
                      ),
                    ),
                    // Page indicator dots - only show if there are multiple thumbnail images
                    if (car_service.thumbnailImages.length > 1)
                      Positioned(
                        bottom: 12.h,
                        left: MediaQuery.of(context).size.width / 2 -
                            (car_service.thumbnailImages.length * 10.w / 2),
                        child: Row(
                          children: List.generate(car_service.thumbnailImages.length, (index) {
                            return Container(
                              margin: EdgeInsets.symmetric(horizontal: 2.w),
                              width: 7.w,
                              height: 7.h,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentPage == index
                                    ? Colors.white
                                    : Colors.white54,
                              ),
                            );
                          }),
                        ),
                      ),
                    // Image counter - only show if there are multiple thumbnail images
                    if (car_service.thumbnailImages.length > 1)
                      Positioned(
                        bottom: 12.h,
                        right: isArabic ? 16.w : null,
                        left: isArabic ? null : 16.w,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            '${_currentPage + 1}/${car_service.thumbnailImages.length}',
                            style:
                                TextStyle(color: Colors.white, fontSize: 12.sp),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 10.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                SvgPicture.asset(
                                  'assets/icons/priceicon.svg',
                                  width: 24.w,
                                  height: 19.h,
                                ),
                                SizedBox(width: 6.w),
                                Text(
                                  widget.car_service.price,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.sp,
                                    color: Colors.red,
                                  ),
                                ),
                                Spacer(),
                                Text(
                                  widget.car_service.createdAt ?? 'N/A',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 10.sp),
                                ),
                              ],
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              widget.car_service.title,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: KTextColor,
                              ),
                            ),
                            // SizedBox(height: 6.h),
                            // RichText(
                            //   text: TextSpan(
                            //     children:  car_service.line1.split(' ').map((word) {
                            //       final parts = word.split(':');
                            //       if (parts.length == 2) {
                            //         return TextSpan(
                            //           text: '${parts[0]}:',
                            //           style: TextStyle(
                            //             fontWeight: FontWeight.w600,
                            //             color: KTextColor,
                            //             fontSize: 14.sp,
                            //           ),
                            //           children: [
                            //             TextSpan(
                            //               text: '${parts[1]}',
                            //               style: TextStyle(
                            //                 fontWeight: FontWeight.w600,
                            //                 color: KTextColor,
                            //                 fontSize: 16.sp,
                            //               ),
                            //             ),
                            //           ],
                            //         );
                            //       } else {
                            //         return TextSpan(
                            //           text: '$word ',
                            //           style: const TextStyle(
                            //             color: KTextColor,
                            //             fontSize: 16,
                            //           ),
                            //         );
                            //       }
                            //     }).toList(),
                            //   ),
                            // ),
                            SizedBox(height: 6.h),
                            Text(
                              widget.car_service.serviceName,
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: KTextColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              widget.car_service.description,
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: KTextColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            Row(
                              children: [
                                SvgPicture.asset(
                                  'assets/icons/locationicon.svg',
                                  width: 20.w,
                                  height: 18.h,
                                ),
                                SizedBox(width: 6.w),
                                Expanded(
                                  child: Text(
                                    widget.car_service.location ?? '',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: KTextColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 5.h),
                          ],
                        ),
                      ),
                      // Divider(color: Color(0xFFB5A9B1), thickness: 1.h),
                      // Text(
                      //   S.of(context).car_details,
                      //   style: TextStyle(
                      //     fontSize: 16.sp,
                      //     fontWeight: FontWeight.w600,
                      //     color: KTextColor,
                      //   ),
                      // ),
                      // SizedBox(height: 5.h),
                      // GridView(
                      //   shrinkWrap: true,
                      //   physics: NeverScrollableScrollPhysics(),
                      //   padding: EdgeInsets.zero,
                      //   gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      //     crossAxisCount: 2,
                      //     mainAxisExtent:
                      //         MediaQuery.of(context).size.height * 0.1,
                      //     crossAxisSpacing: 30.w,
                      //   ),
                      //   children: [
                      //     _buildDetailBox(
                      //         S.of(context).car_type, widget.car_service.carType),
                      //     _buildDetailBox(
                      //         S.of(context).trans_type, widget.car_service.transType),
                      //     _buildDetailBox(
                      //         S.of(context).color, widget.car_service.color),
                      //     _buildDetailBox(S.of(context).interior_color,
                      //         widget.car_service.interiorColor),
                      //     _buildDetailBox(
                      //         S.of(context).fuel_type, widget.car_service.fuelType),
                      //     _buildDetailBox(
                      //         S.of(context).warranty, widget.car_service.warranty),
                      //     _buildDetailBox(S.of(context).doors_no,
                      //         widget.car_service.doors.toString()),
                      //     _buildDetailBox(S.of(context).seats_no,
                      //         widget.car_service.seats.toString()),
                      //     _buildDetailBox(S.of(context).engine_capacity,
                      //         widget.car_service.engineCapacity),
                      //     _buildDetailBox(S.of(context).cylinders,
                      //         widget.car_service.cylinders.toString()),
                      //     _buildDetailBox(
                      //         S.of(context).horse_power, widget.car_service.horsePower),
                      //     _buildDetailBox(S.of(context).steering_side,
                      //         widget.car_service.steeringSide),
                      //   ],
                      // ),
                      // SizedBox(height: 1.h),
                      Divider(color: Color(0xFFB5A9B1), thickness: 1.h),
                      Text(
                        S.of(context).description,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: KTextColor,
                        ),
                      ),
                      SizedBox(height: 20.h),
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Row(
                          children: [
                            Expanded(
                              child: ReadMoreText(
                                "Very specifically garage with smart engineering equipment",
                                trimLines: 2,
                                colorClickableText:
                                    Color.fromARGB(255, 9, 37, 108),
                                trimMode: TrimMode.Line,
                                trimCollapsedText: 'Read more',
                                lessStyle: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Color.fromARGB(255, 9, 37, 108),
                                ),
                                trimExpandedText: '  Show less',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                  color: KTextColor,
                                ),
                                moreStyle: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Color.fromARGB(255, 9, 37, 108),
                                ),
                              ),
                            )
                            // Text(
                            //   "20 % Down Payment With Insurance\n Registration And Delivery To \n Client Without Fees",
                            //   textAlign: TextAlign.start,
                            //   style:
                            // TextStyle(
                            //     fontSize: 14.sp,
                            //     fontWeight: FontWeight.w500,
                            //     color: KTextColor,
                            //   ),
                            // ),
                          ],
                        ),
                      ),
                      SizedBox(height: 50.h),
                      Divider(color: Color(0xFFB5A9B1), thickness: 1.h),
                      Text(
                        S.of(context).location,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16.sp,
                          color: KTextColor,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Row(
                          children: [
                            SvgPicture.asset(
                              'assets/icons/locationicon.svg',
                              width: 20.w,
                              height: 20.h,
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                widget.car_service.location ?? '',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: KTextColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 8.h),
                      SizedBox(
                        height: 188.h,
                        width: double.infinity,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Image.asset(
                                'assets/images/map.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 100.h,
                              left: 30.w,
                              right: 30.w,
                              child: Icon(
                                Icons.location_pin,
                                color: Colors.red,
                                size: 40.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Divider(color: Color(0xFFB5A9B1), thickness: 1.h),
                      Row(
                        //crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(top: 10.h),
                            child: Container(
                              height: 63.h,
                              width: 78.w,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                            ),
                          ),
                          SizedBox(width: 15.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Agent",
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                    color: KTextColor,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  car_service.phoneNumber,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: KTextColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 3.h),
                                GestureDetector(
                                  onTap: () => context.push('/AllAddsCarService'),
                                  child: Text(
                                    S.of(context).view_all_ads,
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF08C2C9),
                                      decoration: TextDecoration.underline,
                                      decorationColor: Color(0xFF08C2C9),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 10.h),
                            child: Column(
                              children: [
                                _buildActionIcon(FontAwesomeIcons.whatsapp),
                                SizedBox(height: 5.h),
                                _buildActionIcon(Icons.phone),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10.h),
                      Divider(color: Color(0xFFB5A9B1), thickness: 1.h),
                      SizedBox(height: 7.h),
                      Center(
                        child: Text(
                          S.of(context).report_this_ad,
                          style: TextStyle(
                            color: KTextColor,
                            fontSize: 16.sp,
                            decoration: TextDecoration.underline,
                            decorationColor: KTextColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Container(
                        width: double.infinity,
                        height: 110.h,
                        padding: EdgeInsets.symmetric(
                            vertical: 20.h, horizontal: 15.w),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Color(0xFFE4F8F6),
                              Color(0xFFC9F8FE),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Center(
                          child: Text(
                            S.of(context).use_this_space_for_ads,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              color: KTextColor,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 50.h),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailBox(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14.sp,
            color: KTextColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 3.5.h),
        Container(
          padding: EdgeInsets.all(8.w),
          width: double.infinity,
          height: 38.h,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: Color(0xFF08C2C9)),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13.sp,
              color: KTextColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionIcon(IconData icon) {
    return Container(
      height: 40.h,
      width: 63.w,
      decoration: BoxDecoration(
        color: Color(0xFF01547E),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Center(
        child: Icon(icon, color: Colors.white, size: 20.sp),
      ),
    );
  }
}
