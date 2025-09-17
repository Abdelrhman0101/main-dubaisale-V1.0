import 'package:advertising_app/generated/l10n.dart';
import 'package:advertising_app/data/model/restaurant_ad_model.dart';
import 'package:advertising_app/presentation/providers/restaurant_details_provider.dart';
import 'package:advertising_app/utils/number_formatter.dart';
import 'package:flutter/material.dart';
import 'package:advertising_app/constant/string.dart';
import 'package:advertising_app/constant/image_url_helper.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:readmore/readmore.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RestaurantDetailsScreen extends StatefulWidget {
  final int adId;
  const RestaurantDetailsScreen({super.key, required this.adId});

  @override
  State<RestaurantDetailsScreen> createState() =>
      _RestaurantDetailsScreenState();
}

class _RestaurantDetailsScreenState extends State<RestaurantDetailsScreen> {
  int _currentPage = 0;
  late PageController _pageController;

  int _getImageCount(RestaurantAdModel restaurant) {
    if (restaurant.thumbnailImagesUrls.isNotEmpty) {
      return restaurant.thumbnailImagesUrls.length;
    } else if (restaurant.thumbnailImages.isNotEmpty) {
      return restaurant.thumbnailImages.length;
    } else if ((restaurant.mainImageUrl != null && restaurant.mainImageUrl!.isNotEmpty) ||
               (restaurant.mainImage != null && restaurant.mainImage!.isNotEmpty)) {
      return 1;
    }
    return 0;
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<RestaurantDetailsProvider>(context, listen: false);
      provider.fetchAdDetails(widget.adId);
    });
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
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Consumer<RestaurantDetailsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (provider.error != null) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Error'),
              leading: IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
            ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(provider.error!, textAlign: TextAlign.center),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => provider.fetchAdDetails(widget.adId),
                child: Text('Retry'),
              ),
            ],
          ),
        ),
          );
        }

        if (provider.adDetails == null) {
          return Scaffold(
            body: Center(
              child: Text('Restaurant not found'),
            ),
          );
        }

        final restaurant = provider.adDetails!;

        // Debug prints for image sources
        print('RD> mainImageUrl: ${restaurant.mainImageUrl}');
        print('RD> mainImage (relative): ${restaurant.mainImage}');
        print('RD> thumbnailImagesUrls (absolute): ${restaurant.thumbnailImagesUrls}');
        print('RD> thumbnailImages (relative): ${restaurant.thumbnailImages}');

        // جمع الصور بنفس منهجية صفحة السيرش + توحيد الروابط عبر ImageUrlHelper
        final List<String> sliderImages = (() {
          final imgs = <String>[];
          // الصورة الرئيسية أولاً
          if (restaurant.mainImageUrl != null && restaurant.mainImageUrl!.isNotEmpty) {
            imgs.add(ImageUrlHelper.getFullImageUrl(restaurant.mainImageUrl!));
          } else if (restaurant.mainImage != null && restaurant.mainImage!.isNotEmpty) {
            imgs.add(ImageUrlHelper.getFullImageUrl(restaurant.mainImage!));
          }
          // الصور المصغرة
          if (restaurant.thumbnailImagesUrls.isNotEmpty) {
            imgs.addAll(ImageUrlHelper.getFullImageUrls(restaurant.thumbnailImagesUrls));
          } else if (restaurant.thumbnailImages.isNotEmpty) {
            imgs.addAll(ImageUrlHelper.getThumbnailImageUrls(restaurant.thumbnailImages));
          }
          return imgs.where((e) => e.isNotEmpty).toList();
        })();

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
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: sliderImages.length,
                        onPageChanged: (index) =>
                            setState(() => _currentPage = index),
                        itemBuilder: (context, index) {
                          if (sliderImages.isEmpty) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.image_not_supported,
                                size: 50,
                                color: Colors.grey,
                              ),
                            );
                          }
                          final imageUrl = sliderImages[index];

                          // Debug print for the resolved image URL used in the slider
                          print('RD> resolved image[' + index.toString() + ']: ' + imageUrl);
                          
                          return CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[200],
                              child: Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                            errorWidget: (context, url, error) {
                              // Debug print when image loading fails
                              print('RD> error loading ' + url + ': ' + error.toString());
                              return Container(
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.image_not_supported,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          );
                        },
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
                    // Page indicator dots
                    Positioned(
                      bottom: 12.h,
                      left: MediaQuery.of(context).size.width / 2 -
                            ((sliderImages.length) * 10.w / 2),
                      child: Row(
                        children:
                            List.generate(sliderImages.length, (index) {
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
                    // Image counter
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
                          sliderImages.isEmpty
                              ? '0/0'
                              : '${_currentPage + 1}/${sliderImages.length}',
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
                                  '${NumberFormatter.formatPrice(restaurant.priceRange ?? 0)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.sp,
                                    color: Colors.red,
                                  ),
                                ),
                                Spacer(),
                               Text(
                                  restaurant.createdAt?.split('T').first ?? '',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 10.sp),
                                ),
                              ],
                            ),
                            SizedBox(height: 4.h),
                            // Row(
                            //   children: [
                            //     Icon(Icons.access_time, size: 14.sp, color: Colors.grey),
                            //     SizedBox(width: 4.w),
                                
                            //     Spacer(),
                            //     Container(
                            //       padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                            //       decoration: BoxDecoration(
                            //         color: Colors.green.shade100,
                            //         borderRadius: BorderRadius.circular(8.r),
                            //       ),
                            //       child: Text(
                            //         restaurant.category,
                            //         style: TextStyle(
                            //           color: Colors.green.shade700,
                            //           fontSize: 10.sp,
                            //           fontWeight: FontWeight.w500,
                            //         ),
                            //       ),
                            //     ),
                            //   ],
                            // ),
                           
                            SizedBox(height: 6.h),
                            Text(
                              restaurant.title,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: KTextColor,
                              ),
                            ),
                            // SizedBox(height: 6.h),
                            // RichText(
                            //   text: TextSpan(
                            //     children:  restaurant.line1.split(' ').map((word) {
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
                              restaurant.category,
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: KTextColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            // SizedBox(height: 6.h),
                            // Row(
                            //   children: [
                            //     SvgPicture.asset(
                            //       'assets/icons/locationicon.svg',
                            //       width: 20.w,
                            //       height: 18.h,
                            //     ),
                            //     SizedBox(width: 6.w),
                            //     Expanded(
                            //       child: Text(
                            //         restaurant.area != null && restaurant.area!.isNotEmpty
                            //             ? '${restaurant.emirate}, ${restaurant.district}, ${restaurant.area}'
                            //             : '${restaurant.emirate}, ${restaurant.district}',
                            //         style: TextStyle(
                            //           fontSize: 14.sp,
                            //           color: KTextColor,
                            //           fontWeight: FontWeight.w500,
                            //         ),
                            //       ),
                            //     ),
                            //   ],
                            // ),
                            // SizedBox(height: 8.h),
                            // معلومات المعلن
                            // Container(
                            //   padding: EdgeInsets.all(12.w),
                            //   decoration: BoxDecoration(
                            //     color: Colors.grey.shade50,
                            //     borderRadius: BorderRadius.circular(8.r),
                            //     border: Border.all(color: Colors.grey.shade200),
                            //   ),
                            //   child: Row(
                            //     children: [
                            //       Icon(Icons.person, color: Colors.grey.shade600, size: 20.sp),
                            //       SizedBox(width: 8.w),
                            //       Expanded(
                            //         child: Column(
                            //           crossAxisAlignment: CrossAxisAlignment.start,
                            //           children: [
                            //             Text(
                            //               'المعلن',
                            //               style: TextStyle(
                            //                 fontSize: 12.sp,
                            //                 color: Colors.grey.shade600,
                            //                 fontWeight: FontWeight.w500,
                            //               ),
                            //             ),
                            //             Text(
                            //               restaurant.advertiserName,
                            //               style: TextStyle(
                            //                 fontSize: 14.sp,
                            //                 color: KTextColor,
                            //                 fontWeight: FontWeight.w600,
                            //               ),
                            //             ),
                            //           ],
                            //         ),
                            //       ),
                            //       if (restaurant.views > 0) ...[
                            //         Icon(Icons.visibility, color: Colors.grey.shade600, size: 16.sp),
                            //         SizedBox(width: 4.w),
                            //         Text(
                            //           '${restaurant.views}',
                            //           style: TextStyle(
                            //             fontSize: 12.sp,
                            //             color: Colors.grey.shade600,
                            //           ),
                            //         ),
                            //       ],
                            //     ],
                            //   ),
                            // ),
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
                      //         S.of(context).car_type, widget.restaurant.carType),
                      //     _buildDetailBox(
                      //         S.of(context).trans_type, widget.restaurant.transType),
                      //     _buildDetailBox(
                      //         S.of(context).color, widget.restaurant.color),
                      //     _buildDetailBox(S.of(context).interior_color,
                      //         widget.restaurant.interiorColor),
                      //     _buildDetailBox(
                      //         S.of(context).fuel_type, widget.restaurant.fuelType),
                      //     _buildDetailBox(
                      //         S.of(context).warranty, widget.restaurant.warranty),
                      //     _buildDetailBox(S.of(context).doors_no,
                      //         widget.restaurant.doors.toString()),
                      //     _buildDetailBox(S.of(context).seats_no,
                      //         widget.restaurant.seats.toString()),
                      //     _buildDetailBox(S.of(context).engine_capacity,
                      //         widget.restaurant.engineCapacity),
                      //     _buildDetailBox(S.of(context).cylinders,
                      //         widget.restaurant.cylinders.toString()),
                      //     _buildDetailBox(
                      //         S.of(context).horse_power, widget.restaurant.horsePower),
                      //     _buildDetailBox(S.of(context).steering_side,
                      //         widget.restaurant.steeringSide),
                      //   ],
                      // ),
                      // SizedBox(height: 1.h),
                      Divider(color: Color(0xFFB5A9B1), thickness: 1.h),
                       Text(S.of(context).description, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: KTextColor)),
                SizedBox(height: 20.h),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(
                    children: [
                      Expanded(
                        child: ReadMoreText(
                          restaurant.description,
                          trimLines: 5,
                          colorClickableText: Color.fromARGB(255, 9, 37, 108),
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
                                '${restaurant.emirate}, ${restaurant.district}',
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
                      Container(
                        height: 188.h,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.r),
                          child: GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: LatLng(25.2048, 55.2708), // Dubai coordinates as default
                              zoom: 14.0,
                            ),
                            markers: {
                              Marker(
                                markerId: MarkerId('restaurant_location'),
                                position: LatLng(25.2048, 55.2708),
                                infoWindow: InfoWindow(
                                  title: restaurant.title,
                                  snippet: '${restaurant.emirate}, ${restaurant.district}',
                                ),
                              ),
                            },
                            zoomControlsEnabled: false,
                            mapToolbarEnabled: false,
                            myLocationButtonEnabled: false,
                          ),
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
                                  restaurant.advertiserName,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: KTextColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 3.h),
                                GestureDetector(
                                  onTap: () {
                                   // context.push('/AllAddsRestaurant');
                                  },
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
      },
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
