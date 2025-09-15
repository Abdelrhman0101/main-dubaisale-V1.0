import 'dart:math';
import 'package:advertising_app/data/restaurant_data_dummy.dart';
import 'package:advertising_app/presentation/widget/custom_bottom_nav.dart';
import 'package:advertising_app/presentation/widget/custom_category.dart';
import 'package:flutter/material.dart';
import 'package:advertising_app/generated/l10n.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:advertising_app/presentation/providers/restaurants_info_provider.dart';

// تعريف الثوابت المستخدمة في الألوان
const Color KTextColor = Color.fromRGBO(0, 30, 91, 1);
const Color KPrimaryColor = Color.fromRGBO(1, 84, 126, 1);
final Color borderColor = Color.fromRGBO(8, 194, 201, 1);

class RestaurantsScreen extends StatefulWidget {
  const RestaurantsScreen({super.key});

  @override
  State<RestaurantsScreen> createState() => _RestaurantsScreenState();
}

class _RestaurantsScreenState extends State<RestaurantsScreen> {
  int _selectedIndex = 6;
  
  // متغيرات الاختيار الواحد
  String? _selectedEmirate;
  String? _selectedDistrict;
  String? _selectedCategory;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }
  
  Future<void> _loadData() async {
    final provider = Provider.of<RestaurantsInfoProvider>(context, listen: false);
    final token = 'your_token_here'; // يجب الحصول على التوكن من التخزين الآمن
    await provider.fetchAllData(token: token);
  }

  List<String> get categories => [
        S.of(context).carsales,
        S.of(context).realestate,
        S.of(context).electronics,
        S.of(context).jobs,
        S.of(context).carrent,
        S.of(context).carservices,
        S.of(context).restaurants,
        S.of(context).otherservices,
      ];

  Map<String, String> get categoryRoutes => {
        S.of(context).carsales: "/home",
        S.of(context).realestate: "/realEstate",
        S.of(context).electronics: "/electronics",
        S.of(context).jobs: "/jobs",
        S.of(context).carrent: "/car_rent",
        S.of(context).carservices: "/carServices",
        S.of(context).restaurants: "/restaurants",
        S.of(context).otherservices: "/otherServices",
      };

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final s = S.of(context);

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));

    return Directionality(
      textDirection: locale == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.white,
          bottomNavigationBar: CustomBottomNav(currentIndex: 0),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 8.h),
                Padding(
                  padding: EdgeInsetsDirectional.symmetric(horizontal: 12.w),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 35.h,
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: s.smart_search,
                              hintStyle: TextStyle(
                                  color: const Color.fromRGBO(129, 126, 126, 1),
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500),
                              prefixIcon: Icon(
                                Icons.search,
                                color: borderColor,
                                size: 25.sp,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.r),
                                borderSide: BorderSide(
                                  color: borderColor,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.r),
                                borderSide: BorderSide(
                                  color: borderColor,
                                  width: 1.5,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 0.h,
                              ),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.notifications_none,
                          color: borderColor,
                          size: 35.sp,
                        ),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 2.h),
                Padding(
                  padding: EdgeInsetsDirectional.symmetric(horizontal: 10.w),
                  child: CustomCategoryGrid(
                    categories: categories,
                    selectedIndex: _selectedIndex,
                    onTap: (index) {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                    onCategoryPressed: (selectedCategory) {
                      final route = categoryRoutes[selectedCategory];
                      if (route != null) {
                        context.push(route);
                      } else {
                        print('Route not found for $selectedCategory');
                      }
                    },
                  ),
                ),
                SizedBox(height: 2.h),
                Padding(
                  padding: EdgeInsetsDirectional.symmetric(horizontal: 8.w),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 20.sp),
                          SizedBox(width: 6.w),
                          Text(
                            s.discover_restaurants_offers,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14.sp,
                              color: KTextColor,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      
                      Consumer<RestaurantsInfoProvider>(
                        builder: (context, provider, child) {
                          return Column(
                            children: [
                              _buildSingleSelectField(
                                context, 
                                s.emirate, 
                                _selectedEmirate, 
                                ['All', ...provider.emirateDisplayNames, 'Other'], 
                                (selection) => setState(() {
                                  _selectedEmirate = selection;
                                  _selectedDistrict = null; // إعادة تعيين المنطقة عند تغيير الإمارة
                                }),
                                isLoading: provider.isLoading
                              ),
                              
                              SizedBox(height: 3.h),
                              
                              _buildSingleSelectField(
                                context, 
                                s.district_choose, 
                                _selectedDistrict, 
                                _selectedEmirate == null || _selectedEmirate == 'All' || _selectedEmirate == 'Other'
                                  ? ['All', 'Other']
                                  : ['All', ...provider.getDistrictsForEmirate(_selectedEmirate), 'Other'], 
                                (selection) => setState(() => _selectedDistrict = selection),
                                isLoading: provider.isLoading
                              ),
                              
                              SizedBox(height: 3.h),
                              
                              _buildSingleSelectField(
                                context, 
                                s.category_type, 
                                _selectedCategory, 
                                ['All', ...provider.categoryDisplayNames, 'Other'], 
                                (selection) => setState(() => _selectedCategory = selection),
                                isLoading: provider.isLoading
                              ),
                            ],
                          );
                        },
                      ),

                      SizedBox(height: 4.h),
                      Padding(
                        padding:
                            EdgeInsetsDirectional.symmetric(horizontal: 8.w),
                        child: GestureDetector(
                          onTap: () {
                            // التحقق من صحة البيانات قبل البحث - السماح بـ All لعرض جميع البيانات
                            if (_selectedEmirate == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Please Select Emirate."),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            
                            if (_selectedDistrict == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Please Select District."),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            
                            if (_selectedCategory == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Please Select Category."),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            
                            // تمرير الفلاتر إلى صفحة البحث
                            final filters = {
                              'emirate': _selectedEmirate,
                              'district': _selectedDistrict,
                              'category': _selectedCategory,
                            };
                            context.push('/restaurant_search', extra: filters);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: KPrimaryColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            height: 43,
                            width: double.infinity,
                            child: Center(
                              child: Text(
                                s.search,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 7.h),
                      Padding(
                        padding:
                            EdgeInsetsDirectional.symmetric(horizontal: 8.w),
                        child: GestureDetector(
                          onTap: () => context.push('/restaurant_offerbox'),
                          child: Container(
                            padding: EdgeInsetsDirectional.symmetric(
                                horizontal: 8.w),
                            height: 68.h,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFE4F8F6), Color(0xFFC9F8FE)],
                              ),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    s.click_daily_offers,
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      color: KTextColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 10.w),
                                Icon(Icons.arrow_forward_ios,
                                    size: 22.sp, color: KTextColor),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 5.h),
                      Consumer<RestaurantsInfoProvider>(
                        builder: (context, provider, child) {
                          return Column(
                            children: [
                              Row(
                                children: [
                                  SizedBox(width: 4.w),
                                  Icon(Icons.star, color: Colors.amber, size: 20.sp),
                                  SizedBox(width: 4.w),
                                  Text(
                                    s.top_premium_dealers,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16.sp,
                                      color: KTextColor,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 1.h),
                              if (provider.isLoading)
                                Container(
                                  height: 200.h,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: KPrimaryColor,
                                    ),
                                  ),
                                )
                              else if (provider.categoryDisplayNames.isEmpty)
                                Container(
                                  height: 200.h,
                                  child: Center(
                                    child: Text(
                                      'لا توجد مطاعم متاحة حالياً',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14.sp,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                Column(
                                  children: List.generate(
                                    min(provider.categoryDisplayNames.length, 3),
                                    (sectionIndex) {
                                      final categoryName = provider.categoryDisplayNames[sectionIndex];
                                      return Column(
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8.w,
                                              vertical: 8.h,
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                   categoryName ?? "مطعم مميز",
                                                   style: TextStyle(
                                                     fontSize: 14.sp,
                                                     fontWeight: FontWeight.w600,
                                                     color: KTextColor,
                                                   ),
                                                 ),
                                                const Spacer(),
                                                InkWell(
                                                  onTap: () {
                                                    context.push('/AllAddsRestaurant');
                                                  },
                                                  child: Text(
                                                    s.see_all_ads,
                                                    style: TextStyle(
                                                      fontSize: 14.sp,
                                                      decoration: TextDecoration.underline,
                                                      decorationColor: borderColor,
                                                      color: borderColor,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(
                                            height: 175,
                                            width: double.infinity,
                                            child: ListView.builder(
                                              scrollDirection: Axis.horizontal,
                                              itemCount: min(RestaurantDataDammy.length, 20),
                                              padding:
                                                  EdgeInsets.symmetric(horizontal: 5.w),
                                              itemBuilder: (context, index) {
                                                final ad = RestaurantDataDammy[index];
                                                return Padding(
                                                  padding: EdgeInsetsDirectional.only(
                                                    end: index == RestaurantDataDammy.length - 1 ? 0 : 4.w,
                                                  ),
                                                  child: Container(
                                                    width: 145,
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius:
                                                          BorderRadius.circular(4.r),
                                                      border: Border.all(
                                                          color: Colors.grey.shade300),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color:
                                                              Colors.grey.withOpacity(0.15),
                                                          blurRadius: 5.r,
                                                          offset: Offset(0, 2.h),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment.start,
                                                      children: [
                                                        Stack(
                                                          children: [
                                                            ClipRRect(
                                                              borderRadius:
                                                                  BorderRadius.circular(4.r),
                                                              child: Image.asset(
                                                                ad.image,
                                                                height: 94.h,
                                                                width: double.infinity,
                                                                fit: BoxFit.cover,
                                                              ),
                                                            ),
                                                            Positioned(
                                                              top: 8,
                                                              right: 8,
                                                              child: Icon(
                                                                  Icons.favorite_border,
                                                                  color:
                                                                      Colors.grey.shade300),
                                                            ),
                                                          ],
                                                        ),
                                                        Expanded(
                                                          child: Padding(
                                                            padding: EdgeInsets.symmetric(
                                                                horizontal: 6.w),
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment.start,
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .spaceEvenly,
                                                              children: [
                                                                Text(
                                                                  ad.price,
                                                                  style: TextStyle(
                                                                    color: Colors.red,
                                                                    fontWeight:
                                                                        FontWeight.w600,
                                                                    fontSize: 11.5.sp,
                                                                  ),
                                                                ),
                                                                Text(
                                                                  ad.title,
                                                                  maxLines: 1,
                                                                  overflow:
                                                                      TextOverflow.ellipsis,
                                                                  style: TextStyle(
                                                                    fontWeight:
                                                                        FontWeight.w600,
                                                                    fontSize: 11.5.sp,
                                                                    color: KTextColor,
                                                                  ),
                                                                ),
                                                                Text(
                                                                  ad.location,
                                                                  style: TextStyle(
                                                                    fontSize: 11.5.sp,
                                                                    color:
                                                                        const Color.fromRGBO(
                                                                            165, 164, 162, 1),
                                                                    fontWeight:
                                                                        FontWeight.w600,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      SizedBox(height: 16.h),
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
}

// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// ++++         ودجت بناء الحقول المعاد استخدامها             ++++
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
Widget _buildSingleSelectField(BuildContext context, String title, String? selectedValue, List<String> allItems, Function(String?) onConfirm, {bool isLoading = false}) {
  final s = S.of(context);
  String displayText = isLoading
      ? "Loading..."
      : selectedValue == null
          ? title
          : selectedValue!;
  
  return Padding(
    padding: EdgeInsets.symmetric(horizontal: 8.w),
    child: GestureDetector(
      onTap: isLoading
          ? null
          : () async {
              final result = await showModalBottomSheet<String>(
                context: context,
                backgroundColor: Colors.white,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20))),
                builder: (context) => _SingleSelectBottomSheet(
                    title: title,
                    items: allItems,
                    initialSelection: selectedValue),
              );
              onConfirm(result);
            },
      child: Container(
        height: 48,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            Expanded(
              child: Text(displayText,
                  style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: selectedValue == null || isLoading
                          ? Colors.grey.shade500
                          : KTextColor,
                      fontSize: 12.sp),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1),
            ),
            if (isLoading)
              const SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(strokeWidth: 2)),
          ],
        ),
      ),
    ),
  );
}

// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// ++++                اللوحات السفلية (Bottom Sheets)         ++++
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
class _SingleSelectBottomSheet extends StatefulWidget {
  final String title;
  final List<String> items;
  final String? initialSelection;

  const _SingleSelectBottomSheet({
    required this.title,
    required this.items,
    this.initialSelection,
  });

  @override
  _SingleSelectBottomSheetState createState() => _SingleSelectBottomSheetState();
}

class _SingleSelectBottomSheetState extends State<_SingleSelectBottomSheet> {
  String? _selectedItem;
  late TextEditingController _searchController;
  late List<String> _filteredItems;

  @override
  void initState() {
    super.initState();
    _selectedItem = widget.initialSelection;
    _searchController = TextEditingController();
    _filteredItems = List.from(widget.items);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterItems(String query) {
    setState(() {
      _filteredItems = widget.items
          .where((item) => item.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            widget.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            onChanged: _filterItems,
            decoration: InputDecoration(
              hintText: s.search,
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredItems.length,
              itemBuilder: (context, index) {
                final item = _filteredItems[index];
                final isSelected = _selectedItem == item;
                return RadioListTile<String>(
                  title: Text(item),
                  value: item,
                  groupValue: _selectedItem,
                  onChanged: (String? value) {
                    setState(() {
                      _selectedItem = value;
                    });
                    Navigator.of(context).pop(value);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}