import 'package:advertising_app/data/model/my_ad_model.dart';
import 'package:advertising_app/presentation/providers/manage_ads_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:advertising_app/constant/string.dart';
import 'package:advertising_app/generated/l10n.dart';
import 'package:advertising_app/presentation/widget/custom_bottom_nav.dart';

class ManageScreen extends StatefulWidget {
  final Function(Locale) onLanguageChange;
  const ManageScreen({Key? key, required this.onLanguageChange})
      : super(key: key);
  @override
  State<ManageScreen> createState() => _ManageScreenState();
}

class _ManageScreenState extends State<ManageScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MyAdsProvider>(context, listen: false).fetchMyAds();
    });
  }

  @override
  void dispose() {
    Provider.of<MyAdsProvider>(context, listen: false).stopAutoRefresh();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final primaryColor = Color.fromRGBO(1, 84, 126, 1);
    ;
    final myAdsProvider = context.watch<MyAdsProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: CustomBottomNav(currentIndex: 3),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              SizedBox(height: 40.h),
              Center(
                  child: Text(s.manageAds,
                      style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 24.sp,
                          color: KTextColor))),
              SizedBox(height: 5.h),
              _buildFilterButtons(s, primaryColor, myAdsProvider),
              SizedBox(height: 6.h),
              _buildBalanceTable(s, primaryColor),
               SizedBox(height: 6.h),
              _buildAdsContent(myAdsProvider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButtons(S s, Color primaryColor, MyAdsProvider provider) {
    final filters = {
      s.all: "All",
      s.valid: "Valid",
      s.pending: "Pending",
      s.expired: "Expired",
      s.rejected: "Rejected"
    };
    return Row(
      children: filters.entries.map((entry) {
        final isSelected = provider.selectedStatus == entry.value;
        Widget buttonChild = ElevatedButton(
          onPressed: () => provider.filterAdsByStatus(entry.value),
          style: ElevatedButton.styleFrom(
              backgroundColor: isSelected ? primaryColor : Colors.transparent,
              shadowColor: Colors.transparent,
              elevation: 0,
              padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 2.w),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8))),
          child: Text(entry.key,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: isSelected ? Colors.white : primaryColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 12.sp)),
        );
        return Expanded(
            child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 2.w),
                child: isSelected
                    ? buttonChild
                    : Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: const LinearGradient(
                                colors: [Color(0xFFE4F8F6), Color(0xFFC9F8FE)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter)),
                        child: buttonChild)));
      }).toList(),
    );
  }

  Widget _buildAdsContent(MyAdsProvider provider) {
    if (provider.isLoading && provider.displayedAds.isEmpty)
      return 
      const Center(child: CircularProgressIndicator());
    if (provider.error != null)
      return Center(child: Text('Error: ${provider.error}'));
    if (provider.displayedAds.isEmpty)
      return Center(
          child: Text('No ads in this category.',
              style: TextStyle(fontSize: 16.sp, color: Colors.grey.shade700)));
    return ListView.builder(
      itemCount: provider.displayedAds.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero, // إزالة المسافة الرأسية الافتراضية
      cacheExtent: 500.0, // تحسين التخزين المؤقت
      itemBuilder: (context, index) {
        final ad = provider.displayedAds[index];
        return _AdCardWidget(key: ValueKey(ad.id), ad: ad);
      },
    );
  }

  Widget _buildBalanceTable(S s, Color primaryColor) {
    Widget buildCell(Widget child,
            {bool isHeader = false, Alignment alignment = Alignment.center}) =>
        Container(
            padding: EdgeInsets.all(8.h),
            alignment: alignment,
            child: DefaultTextStyle(
                style: TextStyle(
                    color: KTextColor,
                    fontSize: 12.sp,
                    fontWeight: isHeader ? FontWeight.w600 : FontWeight.w500),
                child: child));
    return Container(
      decoration: BoxDecoration(
          border: Border.all(color: Color.fromRGBO(8, 194, 201, 1)),
          borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Table(
            border: TableBorder(
                horizontalInside:
                    BorderSide(color: Color.fromRGBO(8, 194, 201, 1), width: 1),
                verticalInside:
                    BorderSide(color: Colors.grey.shade300, width: 1)),
            columnWidths: const {
              0: FlexColumnWidth(1.5),
              1: FlexColumnWidth(1.2),
              2: FlexColumnWidth(1),
              3: FlexColumnWidth(1)
            },
            children: [
              TableRow(children: [
                buildCell(Text(s.adsType),
                    isHeader: true, alignment: Alignment.centerLeft),
                buildCell(
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(s.premium,
                          style: TextStyle(
                              fontSize: 12.sp, fontWeight: FontWeight.w600)),
                      SizedBox(width: 2.w),
                      Icon(Icons.star, color: Color(0xFFF7C325), size: 11.5.sp)
                    ]),
                    isHeader: true),
                buildCell(Text(s.premium), isHeader: true),
                buildCell(Text(s.featured), isHeader: true)
              ]),
              TableRow(
                  decoration: BoxDecoration(color: Color(0xFFF9FAFB)),
                  children: [
                    buildCell(Text(s.totalAds),
                        alignment: Alignment.centerLeft),
                    buildCell(Text("100")),
                    buildCell(Text("50")),
                    buildCell(Text("50"))
                  ]),
              TableRow(children: [
                buildCell(Text(s.balance), alignment: Alignment.centerLeft),
                buildCell(Text("60")),
                buildCell(Text("30")),
                buildCell(Text("20"))
              ])
            ],
          ),
          Divider(height: 1, color: Color.fromRGBO(8, 194, 201, 1)),
          Padding(
              padding: EdgeInsets.all(10.h),
              child: Text('${s.contractExpire}:00/00/0000',
                  style: TextStyle(
                      color: KTextColor,
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w500)))
        ],
      ),
    );
  }
}

class _AdCardWidget extends StatefulWidget {
  final MyAdModel ad;
  const _AdCardWidget({super.key, required this.ad});
  @override
  State<_AdCardWidget> createState() => __AdCardWidgetState();
}

class __AdCardWidgetState extends State<_AdCardWidget> {
  String? _selectedAction;
  late final TextEditingController _daysController;
  final TextEditingController _amountController =
      TextEditingController(text: "100");

  @override
  void initState() {
    super.initState();
    _daysController = TextEditingController(text: "20",);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _selectedAction = S.of(context).upgrade);
    });
  }

  @override
  void dispose() {
    _daysController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final primaryColor = Color.fromRGBO(1, 84, 126, 1);
    final borderColor = const Color.fromRGBO(8, 194, 201, 1);
    final ad = widget.ad;
    final statusColor = _getStatusColor(ad.status);
    final statusText = _getStatusText(ad.status, s);

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 2,
                blurRadius: 5,
                offset: Offset(0, 3))
          ]),
      child: Column(
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start,
           children: [
            SizedBox(
              width: 140.w,
              height: 95.h,
              child: GestureDetector(
                onTap: () {
                  if (ad.categorySlug == 'car-sales')
                    context.push('/car-details/${ad.id}');
                },
                child: Stack(
                  children: [
                  ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                          imageUrl: ad.mainImageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          placeholder: (context, url) =>
                              const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) => Image.asset(
                              'assets/images/car.jpg',
                              fit: BoxFit.cover))),
                  Positioned(
                      bottom: 4.h,
                      left: 4.w,
                      child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                              color: Color.fromRGBO(255, 255, 255, .49),
                              borderRadius: BorderRadius.circular(4)),
                          child: Text("${ad.price} AED",
                              style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.bold)))),
                ]),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          
                          children: [
                        Text(_getAdTitle(ad),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: KTextColor)),
                        SizedBox(height: 25.h),
                        Text(statusText,
                            style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w500,
                                fontSize: 14.sp)),
                        SizedBox(height: 4.h),
                        Text('${s.postDate}: ${ad.createdAt.split('T').first}',
                            style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w400)),
                        SizedBox(height: 2.h),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text('${s.expiresIn} 10 Days',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w400)),
                            ),
                            //SizedBox(width: 4.w),
                          
                          ],
                        )
                      ])),

                 ]


                )
                ),
      
 
               SizedBox(
                width: 20,
             
                 child: IconButton(
                                onPressed: () {}, 
                                icon: SvgPicture.asset('assets/icons/deleted.svg', 
                                    width: 20.w, height: 22.h),
                                padding: EdgeInsets.zero,
                                constraints: BoxConstraints(),
                                iconSize: 20.w,
                              ),
               )           
                  
          ]
          ),


          
          SizedBox(height: 3.h),
          Row(children: [
            Icon(Icons.visibility_outlined,
                color: Color.fromRGBO(8, 194, 201, 1), size: 16.sp),
            SizedBox(width: 4.w),
            Row(
              children: [
                Text('${s.views}',
                    style: TextStyle(
                        color: Color.fromRGBO(8, 194, 201, 1),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w400)),
                        Text(' 20',
                    style: TextStyle(
                        color: primaryColor,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500)),
              ],
            )
          ]),
          SizedBox(height: 1.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildActionButton(s.refresh, primaryColor, borderColor, s, ad),
              _buildActionButton(s.edit, primaryColor, borderColor, s, ad),
              _buildActionButton(s.renew, primaryColor, borderColor, s, ad),
              _buildActionButton(s.upgrade, primaryColor, borderColor, s, ad),
            ],
          ),
          SizedBox(height: 1.h),
          _buildPaymentRow(s, primaryColor, borderColor, ad),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Valid':
        return Color.fromRGBO(36, 150, 17, 1);
      case 'Pending':
        return Colors.orange;
      case 'Rejected':
        return Colors.red;
      case 'Expired':
        return Colors.grey.shade600;
      default:
        return Colors.black;
    }
  }

  String _getStatusText(String status, S s) {
    switch (status) {
      case 'Valid':
        return s.valid;
      case 'Pending':
        return s.pending;
      case 'Rejected':
        return s.rejected;
      case 'Expired':
        return s.expired;
      default:
        return status;
    }
  }

  String _getAdTitle(MyAdModel ad) {
    switch (ad.category) {
      case 'Cars Sales':
        // للسيارات: استخدم Make Model Trim Year
        List<String> carParts = [];
        if (ad.make != null && ad.make!.isNotEmpty) carParts.add(ad.make!);
        if (ad.model != null && ad.model!.isNotEmpty) carParts.add(ad.model!);
        if (ad.trim != null && ad.trim!.isNotEmpty) carParts.add(ad.trim!);
        if (ad.year != null && ad.year!.isNotEmpty) carParts.add(ad.year!);
        return carParts.isNotEmpty ? carParts.join(' ') : ad.title;
        
      case 'Car Services':
        // لخدمات السيارات: استخدم العنوان مع نوع الخدمة
        if (ad.serviceType != null && ad.serviceType!.isNotEmpty) {
          return '${ad.title} (${ad.serviceType})';
        }
        return ad.title;
        
      case 'Restaurants':
        // للمطاعم: استخدم العنوان مع المنطقة
        if (ad.area != null && ad.area!.isNotEmpty) {
          return '${ad.title} - ${ad.area}';
        }
        return ad.title;
        
      default:
        return ad.title;
    }
  }

  Widget _buildActionButton(
      String label, Color primaryColor, Color borderColor, S s, MyAdModel ad) {
    final bool isSelected = _selectedAction == label;
    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 3.w),
        child: ElevatedButton(
          onPressed: () async {
            setState(() {
              _selectedAction = label;
            });
            if (label == s.edit && ad.categorySlug == 'car-sales') {
              await context.push('/car_sales_save_ads/${ad.id}');
              if (mounted)
                Provider.of<MyAdsProvider>(context, listen: false).fetchMyAds();
            }
          },
          style: ElevatedButton.styleFrom(
              backgroundColor: isSelected ? primaryColor : Colors.white,
              side: BorderSide(color: isSelected ? primaryColor : borderColor),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              padding: EdgeInsets.symmetric(vertical:8.h),
              elevation: 0),
          child: Text(label,
              style: TextStyle(
                  color: isSelected ? Colors.white : primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.sp)),
        ),
      ),
    );
  }

  Widget _buildPaymentRow(
      S s, Color primaryColor, Color borderColor, MyAdModel ad) {
    final labelStyle = TextStyle(
        color: KTextColor, fontSize: 11.sp, fontWeight: FontWeight.w500);
    final provider = context.watch<MyAdsProvider>();

    return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Expanded(
          flex: 3,
          child: Container(
            height: 40,
            child: ElevatedButton(
                onPressed: () {},
                child: Text(s.activeOffersBox,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding:
                        EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.h))),
          )),
      SizedBox(width: 2.w),
      Expanded(
          flex: 1,
          child: 
          Column(
            children: [
            Text(s.days, style: labelStyle),
            SizedBox(height: 2.h),
            Container(
                padding: EdgeInsets.symmetric(vertical:10.h),
                height: 36.h,
                decoration: BoxDecoration(
                    border: Border.all(color: borderColor),
                    borderRadius: BorderRadius.circular(8)),
                child: Center(
                    child: TextFormField(
                        controller: _daysController,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        style: TextStyle(
                            color: KTextColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 14.sp),
                        decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero)))),
          ])),
      SizedBox(width: 2.w),
      Expanded(
          flex: 1,
          child: Column(children: [
            Text(s.amount, style: labelStyle),
            SizedBox(height: 2.h),
            Container(
                height: 36.h,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    border: Border.all(color: borderColor),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(_amountController.text,
                    style: TextStyle(
                        color: KTextColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14.sp)))
          ])),
      SizedBox(width: 4.w),
      Expanded(
          flex: 2,
          child: SizedBox(
            height: 36.h,
            child: ElevatedButton(
                onPressed: (provider.isActivatingOffer &&
                        provider.activatingAdId == ad.id)
                    ? null
                    : () {
                        // +++ هذا هو الشرط الجديد +++
                        if (ad.status.toLowerCase() != 'valid') {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(
                                "Action Not Allowed",
                                style: TextStyle(color: KTextColor),
                              ),
                              content: Text(
                                "This ad must be 'Valid' to be activated in the offers box.",
                                style: TextStyle(color: KTextColor),
                              ),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text("OK"))
                              ],
                            ),
                          );
                          return; // أوقف التنفيذ
                        }

                        final days = int.tryParse(_daysController.text);
                        if (days == null || days <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      "Please enter a valid number of days.")));
                          return;
                        }

                        // استخدام categorySlug من الخادم مباشرة
                        String categorySlug = ad.categorySlug.isNotEmpty 
                            ? ad.categorySlug 
                            : 'car_sales'; // قيمة افتراضية في حالة عدم وجود categorySlug

                        print('=== BUTTON CLICK DEBUG ===');
                        print('Ad ID: ${ad.id}');
                        print('Ad Category: ${ad.category}');
                        print('Ad CategorySlug from API: "${ad.categorySlug}"');
                        print('CategorySlug isEmpty: ${ad.categorySlug.isEmpty}');
                        print('Final CategorySlug: "$categorySlug"');
                        print('Days: $days');
                        print('Ad Status: ${ad.status}');
                        print('Valid category slugs: car_sales, car_services, restaurant');
                        print('========================');

                        context
                            .read<MyAdsProvider>()
                            .activateOffer(
                                adId: ad.id,
                                categorySlug: categorySlug,
                                days: days)
                            .then((success) {
                          if (!mounted) return;
                          if (success) {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(
                                  "Success",
                                  style: TextStyle(color: Colors.green),
                                ),
                                content: Text(
                                  "The ad has been successfully added to the offers box!",
                                  style: TextStyle(color: Colors.green),
                                ),
                                actions: [
                                  TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text(
                                        "Great!",
                                        style: TextStyle(color: Colors.green),
                                      ))
                                ],
                              ),
                            );
                          } else {
                            // إظهار رسالة الخطأ
                            final errorMessage = provider.activationError ?? 'Unknown error occurred';
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(
                                  "Error",
                                  style: TextStyle(color: Colors.red),
                                ),
                                content: Text(
                                  errorMessage,
                                  style: TextStyle(color: Colors.red),
                                ),
                                actions: [
                                  TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text(
                                        "OK",
                                        style: TextStyle(color: Colors.red),
                                      ))
                                ],
                              ),
                            );
                          }
                        });
                      },
                style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: EdgeInsets.symmetric(vertical: 11.h)),
                child: (provider.isActivatingOffer &&
                        provider.activatingAdId == ad.id)
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 3))
                    : Text(s.pay,
                        style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white))),
          ))
    ]);
  }
}
