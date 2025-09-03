import 'dart:math';

import 'package:advertising_app/data/car_rent_dummy_data.dart';
import 'package:advertising_app/generated/l10n.dart';
import 'package:advertising_app/data/model/ad_priority.dart';
import 'package:advertising_app/data/model/car_rent_model.dart';
import 'package:advertising_app/presentation/widget/custom_search_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

// تعريف الثوابت المستخدمة في الألوان
const Color KTextColor = Color.fromRGBO(0, 30, 91, 1);
const Color KPrimaryColor = Color.fromRGBO(1, 84, 126, 1);
final Color borderColor = Color.fromRGBO(8, 194, 201, 1);

class _CarRentState {
  static double scrollPosition = 0;
  static bool shouldShowOverlay = false;
  static bool keepOverlayVisible = false;
}

class CarRentSearchScreen extends StatefulWidget {
  const CarRentSearchScreen({super.key});

  @override
  State<CarRentSearchScreen> createState() => _CarRentSearchScreenState();
}

class _CarRentSearchScreenState extends State<CarRentSearchScreen>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  bool _showOverlayBar = false;
  double _lastOffset = 0;
  OverlayEntry? _overlayEntry;
  bool _isScreenActive = true;

  String? _yearFrom, _yearTo;
  String? _priceFrom, _priceTo;


  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_CarRentState.scrollPosition > 0 && _scrollController.hasClients) {
        _scrollController.jumpTo(_CarRentState.scrollPosition);
      }
      if (_CarRentState.shouldShowOverlay) {
        _showOverlayBar = true;
        _showFloatingOverlayBar();
      }
    });
  }

  void _handleScroll() {
    if (!_isScreenActive || !mounted) return;
    final currentOffset = _scrollController.offset;
    final scrollDelta = currentOffset - _lastOffset;
    _CarRentState.scrollPosition = currentOffset;
    if (currentOffset <= 100) {
      if (_showOverlayBar) {
        setState(() => _showOverlayBar = false);
        _CarRentState.shouldShowOverlay = false;
        _CarRentState.keepOverlayVisible = false;
        _removeFloatingOverlayBar();
      }
      return;
    }
    if (_CarRentState.keepOverlayVisible) {
      _CarRentState.keepOverlayVisible = false;
      return;
    }
    if (scrollDelta < -5 && !_showOverlayBar) {
      setState(() => _showOverlayBar = true);
      _CarRentState.shouldShowOverlay = true;
      _showFloatingOverlayBar();
    } else if (scrollDelta > 5 && _showOverlayBar) {
      setState(() => _showOverlayBar = false);
      _CarRentState.shouldShowOverlay = false;
      _removeFloatingOverlayBar();
    }
    _lastOffset = currentOffset;
  }
  
  // +++ تم إرجاع الدالة لتصميمها الأصلي الأفقي +++
  Widget _buildFiltersRow(Function(void Function()) setInnerState) {
    return Container(
      height: 35.h,
      child: Row(
        children: [
          SvgPicture.asset('assets/icons/filter.svg',
              width: 25.w, height: 25.h),
          SizedBox(width: 12.w),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildRangePickerField(
                    context, 
                    title: S.of(context).year,
                    fromValue: _yearFrom, 
                    toValue: _yearTo,
                    unit: "",
                    isFilter: true, // +++ تصميم خاص بالفلاتر
                    onTap: () async {
                       final result = await _showRangePicker(context, title: S.of(context).year, initialFrom: _yearFrom, initialTo: _yearTo, unit: "");
                       if(result != null) {
                         setState((){_yearFrom = result['from']; _yearTo = result['to'];});
                         setInnerState((){});
                       }
                    }
                  ),
                ),
                SizedBox(width: 7.w),
                Expanded(
                  child: _buildRangePickerField(
                    context, 
                    title: S.of(context).price,
                    fromValue: _priceFrom, 
                    toValue: _priceTo,
                    unit: "AED",
                    isFilter: true, // +++ تصميم خاص بالفلاتر
                     onTap: () async {
                       final result = await _showRangePicker(context, title: S.of(context).price, initialFrom: _priceFrom, initialTo: _priceTo, unit: "AED");
                       if(result != null) {
                         setState((){_priceFrom = result['from']; _priceTo = result['to'];});
                         setInnerState((){});
                       }
                    }
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFloatingOverlayBar() {
    if (!_isScreenActive || !mounted || _overlayEntry != null) return;
    _overlayEntry = OverlayEntry(
      builder: (context) => StatefulBuilder(
        builder: (context, setOverlayState) {
          return Positioned(
            top: MediaQuery.of(context).padding.top, left: 0, right: 0,
            child: Material(
              elevation: 6, color: Colors.white,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                decoration: BoxDecoration( border: Border(bottom: BorderSide(color: Colors.grey.shade300))),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        _removeFloatingOverlayBar();
                        _resetState();
                        context.pop();
                      },
                      child: Row(
                        children: [
                          Icon(Icons.arrow_back_ios, color: KTextColor, size: 17.sp),
                          Transform.translate(
                            offset: Offset(-3.w, 0),
                            child: Text(S.of(context).back, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500, color: KTextColor)),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 5.h),
                    _buildFiltersRow(setOverlayState), 
                    SizedBox(height:4.h),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        bool isSmallScreen = MediaQuery.of(context).size.width <= 370;
                        return Row(
                          children: [
                            Text('${S.of(context).ad} 1000', style: TextStyle(fontSize: 12.sp, color: KTextColor, fontWeight: FontWeight.w400)),
                            SizedBox(width: isSmallScreen ? 35.w : 30.w),
                            Expanded(
                              child: Container(
                                height: 37.h,
                                padding: EdgeInsetsDirectional.symmetric(horizontal: isSmallScreen ? 8.w : 12.w),
                                decoration: BoxDecoration(border: Border.all(color: const Color(0xFF08C2C9)), borderRadius: BorderRadius.circular(8.r)),
                                child: Row(
                                  children: [
                                    SvgPicture.asset('assets/icons/locationicon.svg', width: 18.w, height: 18.h),
                                    SizedBox(width: isSmallScreen ? 12.w : 15.w),
                                    Expanded(
                                      child: Text( S.of(context).sort, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w600, color: KTextColor, fontSize: 12.sp)),
                                    ),
                                    SizedBox(
                                      width: isSmallScreen ? 35.w : 32.w,
                                      child: Transform.scale(
                                        scale: isSmallScreen ? 0.8 : .9,
                                        child: Switch(
                                          value: true, onChanged: (val) {}, activeColor: Colors.white, activeTrackColor: const Color(0xFF08C2C9),
                                          inactiveThumbColor: isSmallScreen ? Colors.white : Colors.grey, inactiveTrackColor: Colors.grey[300],
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
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
    if (mounted) { Overlay.of(context).insert(_overlayEntry!); }
  }

  void _removeFloatingOverlayBar() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _resetState() {
    _CarRentState.scrollPosition = 0;
    _CarRentState.shouldShowOverlay = false;
    _CarRentState.keepOverlayVisible = false;
  }

  @override
  void dispose() {
    _isScreenActive = false;
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _removeFloatingOverlayBar();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: KTextColor),
      ),
    );
  }

  Widget _buildCard(CarRentModel item) {
    return GestureDetector(
      onTap: () {
        _CarRentState.scrollPosition = _scrollController.offset;
        _CarRentState.shouldShowOverlay = _showOverlayBar;
        _CarRentState.keepOverlayVisible = _showOverlayBar;
        _removeFloatingOverlayBar();
        context.push('/car-rent-details', extra: item).then((_) {
          if (_CarRentState.keepOverlayVisible && mounted) {
            _showOverlayBar = true;
            _showFloatingOverlayBar();
          }
        });
      },
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: SearchCard(
          showLine1: true,
          customLine1Span: TextSpan(
            children: [
              WidgetSpan(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildLabelWithValue("Day Rent", item.day_rent),
                    const SizedBox(width: 16),
                    _buildLabelWithValue("Month Rent", item.month_rent),
                  ],
                ),
              ),
            ],
          ),
          item: item, showDelete: false, onAddToFavorite: () {},
          onDelete: () { setState(() { CarRentDummyData.remove(item); }); },
        ),
      ),
    );
  }

  Widget _buildLabelWithValue(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text( "$label ", style: TextStyle(fontWeight: FontWeight.w600, color: const Color.fromRGBO(0, 30, 90, 1), fontSize: 14)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
          child: Text(value, style: TextStyle(fontWeight: FontWeight.w500, color: const Color.fromRGBO(0, 30, 90, 1), fontSize: 14)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final locale = Localizations.localeOf(context).languageCode;
    final premiumStarCars = CarRentDummyData.where((c) => c.priority == AdPriority.PremiumStar).toList();
    final premiumCars = CarRentDummyData.where((c) => c.priority == AdPriority.premium).toList();
    final featuredCars = CarRentDummyData.where((c) => c.priority == AdPriority.featured).toList();
    final freeCars = CarRentDummyData.where((c) => c.priority == AdPriority.free).toList();

    return Directionality(
      textDirection: locale == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollUpdateNotification) {
                _handleScroll();
              }
              return false;
            },
            child: SingleChildScrollView(
              key: const PageStorageKey('car_rent_scroll'),
              controller: _scrollController,
              padding: const EdgeInsets.all(4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 10.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () {
                            _removeFloatingOverlayBar();
                            _resetState();
                            context.pop();
                          },
                          child: Row(
                            children: [
                              Icon(Icons.arrow_back_ios, color: KTextColor, size: 17.sp),
                              Transform.translate(
                                offset: Offset(-3.w, 0),
                                child: Text(S.of(context).back, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500, color: KTextColor)),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 3.h),
                        Center(
                          child: Text(S.of(context).carrent, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 24.sp, color: KTextColor)),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18.w),
                    child: _buildFiltersRow(setState), 
                  ),
                  SizedBox(height: 4.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18.w),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        bool isSmallScreen = MediaQuery.of(context).size.width <= 370;
                        return Row(
                          children: [
                            Text( '${S.of(context).ad} 1000', style: TextStyle(fontSize: 12.sp, color: KTextColor, fontWeight: FontWeight.w400)),
                            SizedBox(width: isSmallScreen ? 35.w : 30.w),
                            Expanded(
                              child: Container(
                                height: 37.h,
                                padding: EdgeInsetsDirectional.symmetric(horizontal: isSmallScreen ? 8.w : 12.w),
                                decoration: BoxDecoration(border: Border.all(color: const Color(0xFF08C2C9)), borderRadius: BorderRadius.circular(8.r)),
                                child: Row(
                                  children: [
                                    SvgPicture.asset('assets/icons/locationicon.svg', width: 18.w, height: 18.h),
                                    SizedBox(width: isSmallScreen ? 12.w : 15.w),
                                    Expanded(
                                      child: Text(S.of(context).sort, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w600, color: KTextColor, fontSize: 12.sp)),
                                    ),
                                    SizedBox(
                                      width: isSmallScreen ? 35.w : 32.w,
                                      child: Transform.scale(
                                        scale: isSmallScreen ? 0.8 : .9,
                                        child: Switch(
                                          value: true, onChanged: (val) {}, activeColor: Colors.white, activeTrackColor: const Color(0xFF08C2C9),
                                          inactiveThumbColor: isSmallScreen ? Colors.white : Colors.grey, inactiveTrackColor: Colors.grey[300],
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
                  if (premiumStarCars.isNotEmpty) ...[
                    _buildSectionTitle(S.of(context).priority_first_premium), ...premiumStarCars.map(_buildCard).toList(),
                  ],
                  if (premiumCars.isNotEmpty) ...[
                    _buildSectionTitle(S.of(context).priority_premium), ...premiumCars.map(_buildCard).toList(),
                  ],
                  if (featuredCars.isNotEmpty) ...[
                    _buildSectionTitle(S.of(context).priority_featured), ...featuredCars.map(_buildCard).toList(),
                  ],
                  if (freeCars.isNotEmpty) ...[
                    _buildSectionTitle(S.of(context).priority_free), ...freeCars.map(_buildCard).toList(),
                  ],
                ],
              ),
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
              fontSize: 11), 
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

// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// ++++                اللوحات السفلية (Bottom Sheets)         ++++
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
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