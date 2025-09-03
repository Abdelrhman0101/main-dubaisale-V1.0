import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:advertising_app/generated/l10n.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/svg.dart';

// تعريف الثوابت المستخدمة في الألوان
const Color KTextColor = Color.fromRGBO(0, 30, 91, 1);
const Color KPrimaryColor = Color.fromRGBO(1, 84, 126, 1);

class JobsAdScreen extends StatefulWidget {
  final Function(Locale) onLanguageChange;

  const JobsAdScreen({Key? key, required this.onLanguageChange}) : super(key: key);

  @override
  State<JobsAdScreen> createState() => _JobsAdScreenState();
}

class _JobsAdScreenState extends State<JobsAdScreen> {
  // --- Controllers لحقول الإدخال النصية ---
  final TextEditingController _jobNameController = TextEditingController();
  final TextEditingController _salaryController = TextEditingController();

  // --- متغيرات الحالة لحفظ الاختيارات ---
  String? selectedEmirate;
  String? selectedDistrict;
  String? selectedCategoryType;
  String? selectedSectionType;
  String? selectedAdvertiserName;
  String? selectedPhoneNumber;
  String? selectedWhatsAppNumber;

  @override
  void dispose() {
    _jobNameController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final currentLocale = Localizations.localeOf(context).languageCode;
    final Color borderColor = Color.fromRGBO(8, 194, 201, 1);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 25.h),
              GestureDetector(
                onTap: () => context.pop(),
                child: Row(
                  children: [
                    SizedBox(width: 5.w),
                    Icon(Icons.arrow_back_ios, color: KTextColor, size: 20.sp),
                    Transform.translate(
                      offset: Offset(-3.w, 0),
                      child: Text(s.back, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500, color: KTextColor)),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 7.h),

              Center(
                child: Text(s.jobsAds, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 24.sp, color: KTextColor)),
              ),
              SizedBox(height: 10.h),
              
              // +++ بداية التعديلات على حقول النموذج +++
              _buildFormRow([
                _buildSingleSelectField(context, s.emirate, selectedEmirate, ['Dubai', 'Abu Dhabi'], (selection) => setState(() => selectedEmirate = selection)),
                _buildSingleSelectField(context, s.district, selectedDistrict, ['Satwa', 'Al Barsha'], (selection) => setState(() => selectedDistrict = selection)),
              ]),
              const SizedBox(height: 7),

              _buildFormRow([
                _buildSingleSelectField(context, s.categoryType, selectedCategoryType, ['Job Offer', 'Job Seeker'], (selection) => setState(() => selectedCategoryType = selection)),
                _buildSingleSelectField(context, s.sectionType, selectedSectionType, ['Cleaning Services', 'IT', 'Engineering'], (selection) => setState(() => selectedSectionType = selection)),
              ]),
              const SizedBox(height: 7),
              
              _buildFormRow([
                 _buildTitledTextFormField(s.jobName, 'Cleaner', _jobNameController, borderColor, currentLocale),
                 _buildTitledTextFormField(s.salary, '2000', _salaryController, borderColor, currentLocale, isNumber: true),
              ]),
              const SizedBox(height: 7),
              
              _buildTitleBox(context, s.title, 'Hiring A Cleaner With Experience', borderColor, currentLocale),
              const SizedBox(height: 7),

              TitledSelectOrAddField(
                title: s.advertiserName, 
                value: selectedAdvertiserName,
                items: ['Al Modiyen Company', 'Future Group'],
                onChanged: (newValue) => setState(() => selectedAdvertiserName = newValue),
              ),
              const SizedBox(height: 7),

              // ++ تم إعادة تفعيل الحقول لتكتمل الشاشة ++
              _buildFormRow([
                 TitledSelectOrAddField(
                   title: s.phoneNumber, 
                   value: selectedPhoneNumber,
                   items: ['00971501234567', '00971507654321'],
                   onChanged: (newValue) => setState(() => selectedPhoneNumber = newValue), 
                   isNumeric: true
                 ),
                 TitledSelectOrAddField(
                   title: s.whatsApp, 
                   value: selectedWhatsAppNumber,
                   items: ['00971501234567', '00971507654321'],
                   onChanged: (newValue) => setState(() => selectedWhatsAppNumber = newValue), 
                   isNumeric: true
                 ),
              ]),
              const SizedBox(height: 7),

              // --- نهاية التعديلات ---

              TitledDescriptionBox(title: s.description, initialValue: 'We Hiring Cleaner With Experience Job With One Duty Shift One Day Off', borderColor: borderColor, maxLength: 15000),
              const SizedBox(height: 10),
              
              _buildImageButton(s.addMainImage, Icons.add_a_photo_outlined, borderColor),
              const SizedBox(height: 7),
              
              Text(s.location, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16.sp, color: KTextColor)),
              SizedBox(height: 4.h),
              
              Directionality(
                 textDirection: TextDirection.ltr,
                 child: Row(
                  children: [
                    SvgPicture.asset('assets/icons/locationicon.svg', width: 20.w, height: 20.h),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text('Dubai Satwa', style: TextStyle(fontSize: 14.sp, color: KTextColor, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ),
               SizedBox(height: 8.h),
              _buildMapSection(context),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.push('/placeAnAd'),
                  child: Text(s.next, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KPrimaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- دوال المساعدة الموحدة ---
  Widget _buildFormRow(List<Widget> children) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: children.map((child) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4.0), child: child))).toList());
  }
  Widget _buildTitledTextFormField(String title, String hintText, TextEditingController controller, Color borderColor, String currentLocale, {bool isNumber = false}) {
     return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: KTextColor, fontSize: 14.sp)), const SizedBox(height: 4),
      SizedBox(
        height: 48,
        child: TextFormField(
            controller: controller,
            style: TextStyle(fontWeight: FontWeight.w500, color: KTextColor, fontSize: 12.sp),
            textAlign: currentLocale == 'ar' ? TextAlign.right : TextAlign.left,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
              hintText: hintText, hintStyle: TextStyle(color: Colors.grey.shade400),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: KPrimaryColor, width: 2)),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              fillColor: Colors.white, filled: true
            ),
        ),
      )
    ]);
  }
  Widget _buildSingleSelectField(BuildContext context, String title, String? selectedValue, List<String> allItems, Function(String?) onConfirm, {double? titleFontSize}) {
    final s = S.of(context);
    String displayText = selectedValue ?? s.chooseAnOption;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: KTextColor, fontSize: titleFontSize ?? 14.sp)), const SizedBox(height: 4),
        GestureDetector(
          onTap: () async {
            final result = await _showSingleSelectPicker(context, title: title, items: allItems);
            onConfirm(result);
          },
          child: Container(
            height: 48, width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16), alignment: Alignment.centerLeft,
            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Color.fromRGBO(8, 194, 201, 1)), borderRadius: BorderRadius.circular(8)),
            child: Text(
              displayText, style: TextStyle(fontWeight: selectedValue == null ? FontWeight.normal : FontWeight.w500, color: selectedValue == null ? Colors.grey.shade500 : KTextColor, fontSize: 12.sp),
              overflow: TextOverflow.ellipsis, maxLines: 1,
            ),
          ),
        ),
      ],
    );
  }
  Future<String?> _showSingleSelectPicker(BuildContext context, { required String title, required List<String> items}) {
    return showModalBottomSheet<String>(
      context: context, backgroundColor: Colors.white, isScrollControlled: true, shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _SingleSelectBottomSheet(title: title, items: items),
    );
  }
  Widget _buildTitleBox(BuildContext context, String title, String initialValue, Color borderColor, String currentLocale) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: KTextColor, fontSize: 14.sp)), const SizedBox(height: 4),
        TextFormField(
          initialValue: initialValue, maxLines: null, style: TextStyle(fontWeight: FontWeight.w500, color: KTextColor, fontSize: 14.sp),
          textAlign: currentLocale == 'ar' ? TextAlign.right : TextAlign.left,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: KPrimaryColor, width: 2)),
            contentPadding: EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }
  Widget _buildImageButton(String title, IconData icon, Color borderColor) {
    return SizedBox(width: double.infinity, child: OutlinedButton.icon(icon: Icon(icon, color: KTextColor), label: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: KTextColor, fontSize: 16.sp)), onPressed: () {}, style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: BorderSide(color: borderColor), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)))));
  }
  Widget _buildMapSection(BuildContext context) {
    final s = S.of(context);
    return SizedBox(
        height: 220.h, width: double.infinity,
        child: Stack(
          children: [
            Positioned.fill(child: ClipRRect(borderRadius: BorderRadius.circular(8.0), child: Image.asset('assets/images/map.png', fit: BoxFit.cover))),
            Positioned(top: 80.h, left: 0, right: 0, child: Icon(Icons.location_pin, color: Colors.red, size: 40.sp)),
            Positioned(
              bottom: 10, left: 10, right: 10,
              child: SizedBox(
                width: 150.w,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.location_on_outlined, color: Colors.white, size: 24.sp),
                  label: Text(s.locateMe, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 16.sp)),
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KPrimaryColor,
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ),
          ],
        ));
  }
}

// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// ++++        الودجت المساعدة المنقولة من الشاشات الأخرى    ++++
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
class TitledSelectOrAddField extends StatelessWidget {
  final String title; final String? value; final List<String> items; final Function(String) onChanged; final bool isNumeric;
  const TitledSelectOrAddField({ Key? key, required this.title, required this.value, required this.items, required this.onChanged, this.isNumeric = false}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final borderColor = Color.fromRGBO(8, 194, 201, 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: KTextColor, fontSize: 14.sp)), const SizedBox(height: 4),
        GestureDetector(
          onTap: () async {
            final result = await showModalBottomSheet<String>(
              context: context, backgroundColor: Colors.white, isScrollControlled: true, shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
              builder: (_) => _SearchableSelectOrAddBottomSheet(title: title, items: items, isNumeric: isNumeric),
            );
            if(result != null && result.isNotEmpty){ onChanged(result); }
          },
          child: Container(
            height: 48, padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: borderColor), borderRadius: BorderRadius.circular(8)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [ Expanded(child: Text( value ?? s.chooseAnOption, style: TextStyle(fontWeight: value == null ? FontWeight.normal : FontWeight.w500, color: value == null ? Colors.grey.shade500 : KTextColor, fontSize: 12.sp))),],),),
        )
      ],
    );
  }
}
class _SearchableSelectOrAddBottomSheet extends StatefulWidget {
  final String title; final List<String> items; final bool isNumeric;
  const _SearchableSelectOrAddBottomSheet({Key? key, required this.title, required this.items, this.isNumeric = false}) : super(key: key);
  @override
  _SearchableSelectOrAddBottomSheetState createState() => _SearchableSelectOrAddBottomSheetState();
}
class _SearchableSelectOrAddBottomSheetState extends State<_SearchableSelectOrAddBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _addController = TextEditingController();
  List<String> _filteredItems = [];
  @override
  void initState() {
    super.initState();
    _filteredItems = List.from(widget.items);
    _searchController.addListener(_filterItems);
  }
  @override
  void dispose() {
    _searchController.dispose();
    _addController.dispose();
    super.dispose();
  }
  void _filterItems() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems = widget.items.where((item) => item.toLowerCase().contains(query)).toList();
    });
  }
  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final borderColor = Color.fromRGBO(8, 194, 201, 1);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 16, left: 16, right: 16),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp, color: KTextColor)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _searchController,
              style: TextStyle(color: KTextColor),
              decoration: InputDecoration(
                hintText: s.search, prefixIcon: Icon(Icons.search, color: KTextColor), hintStyle: TextStyle(color: KTextColor.withOpacity(0.5)),
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
                        return ListTile(title: Text(item, style: TextStyle(color: KTextColor)), onTap: () => Navigator.pop(context, item));
                      },
                    ),
            ),
            const Divider(), const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _addController, keyboardType: widget.isNumeric ? TextInputType.number : TextInputType.text,
                    style: TextStyle(fontWeight: FontWeight.w500, color: KTextColor, fontSize: 12.sp),
                    decoration: InputDecoration(
                      hintText: s.addNew,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: KPrimaryColor, width: 2)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () { if (_addController.text.isNotEmpty) { Navigator.pop(context, _addController.text); } },
                  child: Text(s.add, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KPrimaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
class _SingleSelectBottomSheet extends StatefulWidget {
  final String title; final List<String> items;
  const _SingleSelectBottomSheet({Key? key, required this.title, required this.items}) : super(key: key);
  @override
  _SingleSelectBottomSheetState createState() => _SingleSelectBottomSheetState();
}
class _SingleSelectBottomSheetState extends State<_SingleSelectBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredItems = [];
  @override
  void initState() {
    super.initState();
    _filteredItems = List.from(widget.items);
    _searchController.addListener(_filterItems);
  }
  @override
  void dispose() { _searchController.dispose(); super.dispose(); }
  void _filterItems() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems = widget.items.where((item) => item.toLowerCase().contains(query)).toList();
    });
  }
  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final borderColor = Color.fromRGBO(8, 194, 201, 1);
    
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(child: Text(widget.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp, color: KTextColor))),
              const SizedBox(height: 16),
              TextFormField(
                controller: _searchController, style: TextStyle(color: KTextColor), 
                decoration: InputDecoration(
                  hintText: s.search, prefixIcon: Icon(Icons.search, color: KTextColor), hintStyle: TextStyle(color: KTextColor.withOpacity(0.5)),
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
                        return ListTile(title: Text(item, style: TextStyle(color: KTextColor)), onTap: () => Navigator.pop(context, item));
                      },
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class TitledDescriptionBox extends StatefulWidget {
  final String title; final String initialValue; final Color borderColor; final int maxLength;
  const TitledDescriptionBox({Key? key, required this.title, required this.initialValue, required this.borderColor, this.maxLength = 5000}) : super(key: key);
  @override
  State<TitledDescriptionBox> createState() => _TitledDescriptionBoxState();
}
class _TitledDescriptionBoxState extends State<TitledDescriptionBox> {
  late TextEditingController _controller;
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _controller.addListener(() { setState(() {}); });
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.title, style: TextStyle(fontWeight: FontWeight.w600, color: KTextColor, fontSize: 14.sp)),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: widget.borderColor)),
          child: Column(
            children: [
              TextFormField(
                controller: _controller, maxLines: null, maxLength: widget.maxLength,
                style: TextStyle(fontWeight: FontWeight.w500, color: KTextColor, fontSize: 14.sp),
                decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.all(12), counterText: ""),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
                child: Align(
                    alignment: Alignment.bottomRight,
                    child: Text('${_controller.text.length}/${widget.maxLength}', style: TextStyle(color: Colors.grey, fontSize: 12), textDirection: TextDirection.ltr)),
              )
            ],
          ),
        ),
      ],
    );
  }
}