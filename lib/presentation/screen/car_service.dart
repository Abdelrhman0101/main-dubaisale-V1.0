// lib/presentation/screens/car_service.dart

import 'package:advertising_app/presentation/providers/car_services_info_provider.dart';
import 'package:advertising_app/data/model/best_advertiser_model.dart';
import 'package:advertising_app/utils/number_formatter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:advertising_app/presentation/widget/custom_bottom_nav.dart';
import 'package:advertising_app/presentation/widget/custom_category.dart';
import 'package:flutter/material.dart';
import 'package:advertising_app/generated/l10n.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:advertising_app/constant/image_url_helper.dart';
import 'package:cached_network_image/cached_network_image.dart';


// تعريف الثوابت المستخدمة في الألوان
const Color KTextColor = Color.fromRGBO(0, 30, 91, 1);
const Color KPrimaryColor = Color.fromRGBO(1, 84, 126, 1);
final Color borderColor = Color.fromRGBO(8, 194, 201, 1);

class CarService extends StatefulWidget {
  const CarService({super.key});

  @override
  State<CarService> createState() => _CarServiceState();
}

class _CarServiceState extends State<CarService> {
  int _selectedIndex = 5;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final token = await const FlutterSecureStorage().read(key: 'auth_token');
      if (token != null && mounted) {
        // مسح الفلاتر القديمة عند الدخول للصفحة لضمان بداية جديدة
        final provider = context.read<CarServicesInfoProvider>();
        provider.clearFilters();
        provider.fetchLandingPageData(token: token);
      }
    });
  }

  List<String> get categories => [ S.of(context).carsales, S.of(context).realestate, S.of(context).electronics, S.of(context).jobs, S.of(context).carrent, S.of(context).carservices, S.of(context).restaurants, S.of(context).otherservices ];
  Map<String, String> get categoryRoutes => { S.of(context).carsales: "/home", S.of(context).realestate: "/realEstate", S.of(context).electronics: "/electronics", S.of(context).jobs: "/jobs", S.of(context).carrent: "/car_rent", S.of(context).carservices: "/carServices", S.of(context).restaurants: "/restaurants", S.of(context).otherservices: "/otherServices" };

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final s = S.of(context);
    
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarColor: Colors.white, statusBarIconBrightness: Brightness.dark));

    return Directionality(
      textDirection: locale == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.white,
          bottomNavigationBar: CustomBottomNav(currentIndex: 0),
          body: Consumer<CarServicesInfoProvider>(
            builder: (context, provider, child) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 8.h),
                    Padding(
                      padding: EdgeInsetsDirectional.symmetric(horizontal: 12.w),
                      child: Row(children: [
                        Expanded(child: SizedBox(height: 35.h, child: TextField(decoration: InputDecoration(hintText: s.smart_search, hintStyle: TextStyle(color: const Color.fromRGBO(129, 126, 126, 1), fontSize: 14.sp, fontWeight: FontWeight.w500), prefixIcon: Icon(Icons.search, color: borderColor, size: 25.sp), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: BorderSide(color: borderColor)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: BorderSide(color: borderColor, width: 1.5)), filled: true, fillColor: Colors.white, isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 0.h))))),
                        IconButton(icon: Icon(Icons.notifications_none, color: borderColor, size: 35.sp), onPressed: () {}),
                      ]),
                    ),
                    Padding(padding: EdgeInsetsDirectional.symmetric(horizontal: 10.w), child: CustomCategoryGrid(categories: categories, selectedIndex: _selectedIndex, onTap: (index) { setState(() { _selectedIndex = index; }); }, onCategoryPressed: (selectedCategory) { final route = categoryRoutes[selectedCategory]; if (route != null) context.push(route); })),
                    SizedBox(height: 2.h),
                    Padding(
                      padding: EdgeInsetsDirectional.symmetric(horizontal: 8.w),
                      child: Column(
                        children: [
                          Row(children: [ Icon(Icons.star, color: Colors.amber, size: 20.sp), SizedBox(width: 6.w), Text(s.discover_car_service, textAlign: TextAlign.start, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp, color: KTextColor))]),
                          SizedBox(height: 4.h),
                          _buildSingleSelectField(context, s.emirate, provider.selectedEmirate, provider.emirateDisplayNames, (selection) => provider.updateSelectedEmirate(selection), isLoading: provider.isLoadingFilters),
                          SizedBox(height: 3.h),
                          _buildSingleSelectField(context, s.serviceType, provider.selectedServiceType, provider.serviceTypeDisplayNames, (selection) => provider.updateSelectedServiceType(selection), isLoading: provider.isLoadingFilters),
                          SizedBox(height: 4.h),
                          Padding(
                            padding: EdgeInsetsDirectional.symmetric(horizontal: 8.w),
                            child: GestureDetector(
                              onTap: () {
                                // التحقق من اختيار الإمارة ونوع الخدمة
                                if (provider.selectedEmirate == null || provider.selectedEmirate!.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Please select an emirate'),
                                      backgroundColor: Colors.red,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                  return;
                                }
                                if (provider.selectedServiceType == null || provider.selectedServiceType!.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Please select a service type'),
                                      backgroundColor: Colors.red,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                  return;
                                }
                                
                                final filters = provider.getFormattedFilters();
                               
                                // إرسال الفلاتر إلى صفحة البحث
                                context.push('/car_service_search', extra: filters);
                              },
                              child: Container(decoration: BoxDecoration(color: KPrimaryColor, borderRadius: BorderRadius.circular(8)), height: 43, width: double.infinity, child: Center(child: Text(s.search, style: const TextStyle(color: Colors.white, fontSize: 16)))),
                            ),
                          ),
                          SizedBox(height: 7.h),
                          Padding(
                            padding: EdgeInsetsDirectional.symmetric(horizontal: 8.w),
                            child: GestureDetector(onTap: () => context.push('/carservicetofferbox'), child: Container(padding: EdgeInsetsDirectional.symmetric(horizontal: 8.w), height: 68.h, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFE4F8F6), Color(0xFFC9F8FE)]), borderRadius: BorderRadius.circular(8.r)), child: Row(children: [ SvgPicture.asset('assets/icons/cardolar.svg', height: 25.sp, width: 24.sp), SizedBox(width: 16.w), Expanded(child: Text(s.click_for_deals_car_service, textAlign: TextAlign.start, style: TextStyle(fontSize: 13.sp, color: KTextColor, fontWeight: FontWeight.w500))), SizedBox(width: 12.w), Icon(Icons.arrow_forward_ios, size: 22.sp, color: KTextColor)]))),
                          ),
                          SizedBox(height: 5.h),
                          Row(children: [SizedBox(width: 4.w), Icon(Icons.star, color: Colors.amber, size: 20.sp), SizedBox(width: 4.w), Text(s.top_premium_dealers, textAlign: TextAlign.start, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16.sp, color: KTextColor))]),
                          SizedBox(height: 1.h),
                          _buildTopDealersSection(provider),
                          SizedBox(height: 16.h),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

   Widget _buildTopDealersSection(CarServicesInfoProvider provider) {
    if (provider.isLoadingTopGarages && provider.topGarages.isEmpty) {
      return const Center(heightFactor: 5, child: CircularProgressIndicator());
    }
    if (provider.topGaragesError != null) {
      return Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(provider.topGaragesError!)));
    }

    final garagesWithAds = provider.topGarages.where((g) => g.ads.isNotEmpty).toList();
    if (garagesWithAds.isEmpty) return const SizedBox.shrink();

    return Column(
      children: garagesWithAds.map((garage) {
        return Column(
          children: [
            Padding(
              padding: EdgeInsetsDirectional.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Row(children: [
                Text(garage.name, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: KTextColor)),
                const Spacer(),
                InkWell(onTap: () {}, child: Text(S.of(context).see_all_ads, style: TextStyle(fontSize: 14.sp, decoration: TextDecoration.underline, decorationColor: borderColor, color: borderColor, fontWeight: FontWeight.w500))),
              ]),
            ),
            SizedBox(
              height: 170,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: garage.ads.length,
                padding: EdgeInsetsDirectional.symmetric(horizontal: 8.w),
                itemBuilder: (context, index) {
                  final ad = garage.ads[index];
                  return GestureDetector(
                    onTap: () {/* Future: context.push('/car-service-details/${ad.id}');*/},
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(end: 4),
                      child: Container(
                        width: 145,
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4.r), border: Border.all(color: Colors.grey.shade300), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.15), blurRadius: 5.r, offset: Offset(0, 2.h))]),
                        child: Column(children: [
                          ClipRRect(borderRadius: BorderRadius.circular(4.r), child: CachedNetworkImage(imageUrl: ImageUrlHelper.getMainImageUrl(ad.mainImage ?? ''), height: 94.h, width: double.infinity, fit: BoxFit.cover, placeholder: (context, url) => Container(color: Colors.grey[300], child: Center(child: CircularProgressIndicator(strokeWidth: 2))), errorWidget: (context, url, error) => Image.asset('assets/images/car.jpg', fit: BoxFit.cover))),
                          Expanded(child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Text("${NumberFormatter.formatPrice(ad.price)}", style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 11.5.sp)),
                                  Text(ad.serviceName ?? '', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11.5.sp, color: KTextColor), maxLines: 2, overflow: TextOverflow.ellipsis),
                                 
                                      Text("${ad.emirate ?? ''} ${ad.district ?? ''}", style: TextStyle(fontSize: 11.5.sp, color: const Color.fromRGBO(165, 164, 162, 1), fontWeight: FontWeight.w600)),
                                   
                                ],
                              ),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

// +++ ودجتس بناء الحقول المعاد استخدامها +++
Widget _buildSingleSelectField(BuildContext context, String title, String? selectedValue, List<String> allItems, Function(String?) onConfirm, {bool isLoading = false}) {
    String displayText = isLoading ? 'Loading...' : (selectedValue?.isEmpty ?? true ? title : selectedValue!);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      child: GestureDetector(
        onTap: isLoading || allItems.isEmpty ? null : () async {
          final result = await showModalBottomSheet<String>(context: context, backgroundColor: Colors.white, isScrollControlled: true, shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            builder: (context) => _SingleSelectBottomSheet(title: title, items: allItems, initialSelection: selectedValue),
          );
          onConfirm(result);
        },
        child: Container(
          height: 48, width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16), alignment: Alignment.centerLeft,
          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: borderColor), borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
              Expanded(child: Text(displayText, style: TextStyle(fontWeight: FontWeight.w500, color: (selectedValue?.isEmpty ?? true) && !isLoading ? Colors.grey.shade500 : KTextColor, fontSize: 12.sp), overflow: TextOverflow.ellipsis)),
              if (isLoading) const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ),
        ),
      ),
    );
}

// ... كلاس _MultiSelectBottomSheet يبقى كما هو ...
class _SingleSelectBottomSheet extends StatefulWidget {
  final String title; final List<String> items; final String? initialSelection;
  const _SingleSelectBottomSheet({required this.title, required this.items, required this.initialSelection});
  @override _SingleSelectBottomSheetState createState() => _SingleSelectBottomSheetState();
}
class _SingleSelectBottomSheetState extends State<_SingleSelectBottomSheet> {
  String? _selectedItem; final TextEditingController _searchController = TextEditingController(); List<String> _filteredItems = [];
  @override void initState() { super.initState(); _selectedItem = widget.initialSelection; _filteredItems = List.from(widget.items); _searchController.addListener(_filterItems); }
  @override void dispose() { _searchController.dispose(); super.dispose(); }
  void _filterItems() { final query = _searchController.text.toLowerCase(); setState(() { _filteredItems = widget.items.where((item) => item.toLowerCase().contains(query)).toList(); });}
  void _onItemTapped(String item) { setState(() { _selectedItem = item; });}
  @override Widget build(BuildContext context) {
    final s = S.of(context);
    return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 16, left: 16, right: 16),
        child: ConstrainedBox(constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(widget.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp, color: KTextColor)), const SizedBox(height: 16),
              TextFormField(controller: _searchController, style: const TextStyle(color: KTextColor), decoration: InputDecoration(hintText: s.search, prefixIcon: const Icon(Icons.search, color: KTextColor), hintStyle: TextStyle(color: KTextColor.withOpacity(0.5)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: KPrimaryColor, width: 2)))),
              const SizedBox(height: 8), const Divider(),
              Expanded(child: _filteredItems.isEmpty ? Center(child: Text(s.noResultsFound, style: const TextStyle(color: KTextColor))) : ListView.builder(itemCount: _filteredItems.length, itemBuilder: (context, index) { final item = _filteredItems[index]; return RadioListTile<String>(title: Text(item, style: const TextStyle(color: KTextColor)), value: item, groupValue: _selectedItem, activeColor: KPrimaryColor, controlAffinity: ListTileControlAffinity.leading, onChanged: (value) => _onItemTapped(value!));})),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(context, _selectedItem), child: Text(s.apply, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: KPrimaryColor, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))))),
              const SizedBox(height: 16)
            ]),
        ),
      );
  }
}