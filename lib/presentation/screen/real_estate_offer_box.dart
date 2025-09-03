import 'package:advertising_app/data/real_estate_dummy_data.dart';
import 'package:advertising_app/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

// تعريف الثوابت المستخدمة في الألوان
const Color KTextColor = Color.fromRGBO(0, 30, 91, 1);
const Color KPrimaryColor = Color.fromRGBO(1, 84, 126, 1);
final Color borderColor = Color.fromRGBO(8, 194, 201, 1);


class RealEstateOfeerBOX extends StatefulWidget {
  const RealEstateOfeerBOX({super.key});

  @override
  State<RealEstateOfeerBOX> createState() => _RealEstateOfeerBOXState();
}

class _RealEstateOfeerBOXState extends State<RealEstateOfeerBOX> {

  // +++ تم تحديث المتغيرات لتناسب الأنواع الجديدة للحقول +++
  List<String> _selectedTypes = [];
  List<String> _selectedDistricts = [];
  List<String> _selectedContracts = [];
  String? _priceFrom, _priceTo;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final screenWidth = MediaQuery.of(context).size.width;
    final cardSize = getCardSize(screenWidth);

    return Directionality(
        textDirection: locale == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          extendBodyBehindAppBar: true,
          backgroundColor: Colors.white,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 10.h),

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

                  SizedBox(height: 7.h),

                  Center(
                    child: Text(
                      "Offers Box",
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 24.sp,
                        color: KTextColor,
                      ),
                    ),
                  ),

                  SizedBox(height: 10.h),
                  
                  // +++ صف الفلاتر المحدث +++
                  Padding(
                    padding: EdgeInsetsDirectional.symmetric(horizontal: 8.w),
                    child: Container(
                      height: 35.h,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            'assets/icons/filter.svg',
                            width: 25.w,
                            height: 25.h,
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildMultiSelectField(
                                    context, S.of(context).type, _selectedTypes, 
                                    const ["Apartment", "Villa", "Land", "Building"], 
                                    (selection) => setState(() => _selectedTypes = selection), isFilter: true),
                                ),
                                SizedBox(width: 5.w),
                                Expanded(
                                  child: _buildMultiSelectField(
                                    context, S.of(context).district, _selectedDistricts, 
                                    const ["Riyadh", "Jeddah", "Dammam"],
                                    (selection) => setState(() => _selectedDistricts = selection), isFilter: true),
                                ),
                                SizedBox(width: 5.w),
                                Expanded(
                                  child: _buildMultiSelectField(
                                    context, S.of(context).contract, _selectedContracts, 
                                    const ["Sale", "Rent"], 
                                    (selection) => setState(() => _selectedContracts = selection), isFilter: true),
                                ),
                                SizedBox(width: 5.w),
                                Expanded(
                                  child: _buildRangePickerField(
                                    context, title: S.of(context).price, fromValue: _priceFrom, toValue: _priceTo, unit: "AED", isFilter: true,
                                    onTap: () async {
                                      final result = await _showRangePicker(context, title: S.of(context).price, initialFrom: _priceFrom, initialTo: _priceTo, unit: "AED");
                                      if (result != null) {
                                        setState(() { _priceFrom = result['from']; _priceTo = result['to']; });
                                      }
                                    }
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 6.h),

                  Padding(
                    padding: EdgeInsetsDirectional.symmetric(horizontal: 8.w),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        bool isSmallScreen =
                            MediaQuery.of(context).size.width <= 370;

                        return Row(
                          children: [
                            Text(
                              '${S.of(context).ad} 1000',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: KTextColor,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            SizedBox(width: 40.w),
                            Expanded(
                              child: Container(
                                height: 37.h,
                                padding: EdgeInsetsDirectional.symmetric(horizontal: 8.w),
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0xFF08C2C9)),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Row(
                                  children: [
                                    SvgPicture.asset('assets/icons/locationicon.svg', width: 18.w, height: 18.h),
                                    SizedBox(width: 12.w),
                                    Expanded(
                                      child: Text(
                                        S.of(context).sort,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: KTextColor,
                                          fontSize: 12.sp,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 1.w),
                                    SizedBox(
                                      width: 35.w,
                                      child: Transform.scale(
                                        scale: 0.8,
                                        child: Switch(
                                          value: true, onChanged: (val) {},
                                          activeColor: Colors.white,
                                          activeTrackColor: const Color.fromRGBO(8, 194, 201, 1),
                                          inactiveThumbColor: Colors.white,
                                          inactiveTrackColor: Colors.grey[300],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 5.h),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: RealEstateDummyData.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 6,
                        childAspectRatio: .89,
                      ),
                      itemBuilder: (context, index) {
                        final ad = RealEstateDummyData[index];

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Container(
                            width: cardSize.width.w,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4.r),
                              border: Border.all(color: Colors.grey.shade300),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.15),
                                  blurRadius: 5.r,
                                  offset: Offset(0, 2.h),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Stack(children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4.r),
                                    child: Image.asset(
                                      ad.image,
                                      height: (cardSize.height * 0.6).h,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Icon(Icons.favorite_border,
                                        color: Colors.grey.shade300),
                                  ),
                                ]),
                                Expanded(
                                  child: Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 6.w),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Text(ad.price, style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 12.sp)),
                                        Text(ad.details, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.sp, color: KTextColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        Text(ad.contact, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.sp, color: KTextColor)),
                                        Row(
                                          children: [
                                            SvgPicture.asset( 'assets/icons/Vector.svg', width: 10.5.w, height: 13.5.h),
                                            SizedBox(width: 5),
                                            Expanded(
                                              child: Text(ad.location,
                                                style: TextStyle(fontSize: 12.sp, color: Color.fromRGBO(0, 30, 91, .75), fontWeight: FontWeight.w600),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
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
                  SizedBox(
                    height: 20,
                  )
                ],
              ),
            ),
          ),
        ));
  }
}

Size getCardSize(double screenWidth) {
  if (screenWidth <= 320) {
    return const Size(120, 140);
  } else if (screenWidth <= 375) {
    return const Size(135, 150);
  } else if (screenWidth <= 430) {
    return const Size(150, 160);
  } else {
    return const Size(165, 175);
  }
}

// ... (باقي الكود ودوال المساعدة واللوحات السفلية تبقى كما هي)

Widget _buildMultiSelectField(BuildContext context, String title, List<String> selectedValues, List<String> allItems, Function(List<String>) onConfirm, {bool isFilter = false}) {
    final s = S.of(context);
    String displayText = selectedValues.isEmpty ? title : selectedValues.join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         if(!isFilter) Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: KTextColor, fontSize: 14)),
         if(!isFilter) const SizedBox(height: 4),
        GestureDetector(
          onTap: () async {
            final result = await showModalBottomSheet<List<String>>(
              context: context, backgroundColor: Colors.white, isScrollControlled: true, shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
              builder: (context) => _MultiSelectBottomSheet(title: title, items: allItems, initialSelection: selectedValues),
            );
            if (result != null) { onConfirm(result); }
          },
          child: Container(
            height: isFilter ? 35 : 48,
            width: double.infinity, 
            padding: const EdgeInsets.symmetric(horizontal: 8), 
            alignment: Alignment.center, 
            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: borderColor), borderRadius: BorderRadius.circular(8)),
            child: Text(
              displayText,
              style: TextStyle(
                fontWeight: selectedValues.isEmpty ? FontWeight.w500 : FontWeight.w500,
                color: selectedValues.isEmpty ? KTextColor : KTextColor,
                fontSize: 9.5
              ),
              overflow: TextOverflow.ellipsis, maxLines: 1,
            ),
          ),
        ),
      ],
    );
}

Widget _buildRangePickerField(BuildContext context, {required String title, String? fromValue, String? toValue, required String unit, required VoidCallback onTap, bool isFilter = false}) {
    final s = S.of(context);
    String displayText;
      displayText = (fromValue == null || fromValue.isEmpty) && (toValue == null || toValue.isEmpty) 
          ? title
          : '${fromValue ?? s.from} - ${toValue ?? s.to} ${unit}'.trim();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if(!isFilter) Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: KTextColor, fontSize: 14)),
        if(!isFilter) const SizedBox(height: 4),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: isFilter ? 35 : 48, 
            width: double.infinity, 
            padding: const EdgeInsets.symmetric(horizontal: 8), 
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: borderColor), borderRadius: BorderRadius.circular(8)),
            child: Text(displayText, style: TextStyle(
              fontWeight: (fromValue == null || fromValue.isEmpty) && (toValue == null || toValue.isEmpty) ? FontWeight.w500 : FontWeight.w500,
              color: (fromValue == null || fromValue.isEmpty) && (toValue == null || toValue.isEmpty) ? KTextColor : KTextColor,
              fontSize: 9.5), 
              overflow: TextOverflow.ellipsis, maxLines: 1),
          ),
        ),
      ],
    );
  }

Future<Map<String, String?>?> _showRangePicker(BuildContext context, {required String title, String? initialFrom, String? initialTo, required String unit}) {
    return showModalBottomSheet<Map<String, String?>>(
      context: context, backgroundColor: Colors.white, isScrollControlled: true, shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _RangeSelectionBottomSheet(title: title, initialFrom: initialFrom, initialTo: initialTo, unit: unit),
    );
}

class _MultiSelectBottomSheet extends StatefulWidget {
  final String title; final List<String> items; final List<String> initialSelection;
  const _MultiSelectBottomSheet({Key? key, required this.title, required this.items, required this.initialSelection}) : super(key: key);
  @override
  _MultiSelectBottomSheetState createState() => _MultiSelectBottomSheetState();
}
class _MultiSelectBottomSheetState extends State<_MultiSelectBottomSheet> {
  late final List<String> _selectedItems;
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredItems = [];
  @override
  void initState() {
    super.initState();
    _selectedItems = List.from(widget.initialSelection);
    _filteredItems = List.from(widget.items);
    _searchController.addListener(_filterItems);
  }
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  void _filterItems() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems = widget.items.where((item) => item.toLowerCase().contains(query)).toList();
    });
  }
  void _onItemTapped(String item) {
    setState(() {
      if (_selectedItems.contains(item)) { _selectedItems.remove(item); } 
      else { _selectedItems.add(item); }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    
    return Theme(
      data: Theme.of(context).copyWith(
        checkboxTheme: CheckboxThemeData(
          side: MaterialStateBorderSide.resolveWith(
            (_) => BorderSide(width: 1.0, color: borderColor),
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp, color: KTextColor)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _searchController,
                  style: TextStyle(color: KTextColor), 
                  decoration: InputDecoration(
                    hintText: s.search, prefixIcon: Icon(Icons.search, color: KTextColor),
                    hintStyle: TextStyle(color: KTextColor.withOpacity(0.5)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: KPrimaryColor, width: 2)),
                  ),
                ),
                const SizedBox(height: 8), const Divider(),
                Expanded(
                  child: _filteredItems.isEmpty 
                    ? Center(child: Text(s.noResultsFound, style: TextStyle(color: KTextColor)))
                    : ListView.builder(
                        itemCount: _filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = _filteredItems[index];
                          return CheckboxListTile(
                            title: Text(item, style: TextStyle(color: KTextColor)),
                            value: _selectedItems.contains(item),
                            activeColor: KPrimaryColor,
                            checkColor: Colors.white,
                            controlAffinity: ListTileControlAffinity.leading,
                            onChanged: (_) => _onItemTapped(item),
                          );
                        },
                      ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, _selectedItems),
                    child: Text(s.apply),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: KPrimaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
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

class _RangeSelectionBottomSheet extends StatefulWidget {
  final String title; final String? initialFrom; final String? initialTo; final String unit;
  const _RangeSelectionBottomSheet({Key? key, required this.title, this.initialFrom, this.initialTo, required this.unit}) : super(key: key);
  @override
  __RangeSelectionBottomSheetState createState() => __RangeSelectionBottomSheetState();
}
class __RangeSelectionBottomSheetState extends State<_RangeSelectionBottomSheet> {
  late TextEditingController _fromController;
  late TextEditingController _toController;
  @override
  void initState() {
    super.initState();
    _fromController = TextEditingController(text: widget.initialFrom);
    _toController = TextEditingController(text: widget.initialTo);
  }
  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    
    Widget buildTextField(String hint, String suffix, TextEditingController controller) {
      return Expanded(
        child: TextFormField(
          controller: controller, keyboardType: TextInputType.number, style: TextStyle(fontWeight: FontWeight.w500, color: KTextColor, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint, hintStyle: TextStyle(color: Colors.grey.shade400),
            suffixIcon: suffix.isNotEmpty 
                ? Padding(padding: const EdgeInsets.symmetric(horizontal: 8.0), child: Text(suffix, style: TextStyle(color: KTextColor, fontWeight: FontWeight.bold, fontSize: 12)))
                : null,
            suffixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: KPrimaryColor, width: 2)),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            fillColor: Colors.white, filled: true,
          ),
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(widget.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp, color: KTextColor)),
            TextButton(
              onPressed: () { _fromController.clear(); _toController.clear(); setState(() {}); }, 
              child: Text(s.reset, style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14.sp))),
          ]),
          SizedBox(height: 16.h),
          Row(children: [
            buildTextField(s.from, widget.unit, _fromController),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 8.0), child: Text(s.to, style: TextStyle(fontWeight: FontWeight.w600, color: KTextColor, fontSize: 14))),
            buildTextField(s.to, widget.unit, _toController),
          ]),
          SizedBox(height: 24.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, {'from': _fromController.text, 'to': _toController.text}),
              child: Text(s.apply, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: KPrimaryColor, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            ),
          ),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }
}