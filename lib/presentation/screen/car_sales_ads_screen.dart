import 'dart:io';
import 'package:advertising_app/presentation/providers/car_sales_ad_provider.dart';
import 'package:advertising_app/presentation/providers/car_sales_info_provider.dart';
import 'package:advertising_app/presentation/providers/google_maps_provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:advertising_app/generated/l10n.dart';
import 'package:advertising_app/utils/phone_number_formatter.dart';
import 'package:advertising_app/presentation/widget/custom_phone_field.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

// الثوابت
const Color KTextColor = Color.fromRGBO(0, 30, 91, 1);
const Color KPrimaryColor = Color.fromRGBO(1, 84, 126, 1);
final Color borderColor = const Color.fromRGBO(8, 194, 201, 1);

class CarSalesAdScreen extends StatefulWidget {
  final Function(Locale) onLanguageChange;
  const CarSalesAdScreen({Key? key, required this.onLanguageChange})
      : super(key: key);

  @override
  State<CarSalesAdScreen> createState() => _CarSalesAdScreenState();
}

class _CarSalesAdScreenState extends State<CarSalesAdScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _kilometersController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();

  String? selectedMake, selectedModel, selectedTrim, selectedYear;
  String? selectedSpec, selectedCarType, selectedTransType;
  String? selectedFuelType, selectedColor, selectedInteriorColor;
  String? selectedWarrantyValue;
  String? selectedEngineCap, selectedCylinder, selectedHorsePower;
  String? selectedDoor, selectedSeat, selectedSteeringSide;
  String? selectedEmirate, selectedAdvertiserType;
  String? selectedAdvertiserName;
  String? selectedPhoneNumber, selectedWhatsAppNumber;
  String selectedLocation = ''; // العنوان المحدد من الخريطة
  LatLng? selectedLatLng; // الإحداثيات المحددة

  File? _mainImage;
  final List<File> _thumbnailImages = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _kilometersController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  Future<void> _pickMainImage() async {
    final XFile? image =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image != null) setState(() => _mainImage = File(image.path));
  }

  Future<void> _pickThumbnailImages() async {
    const int maxImages = 14;
    final int remainingSlots = maxImages - _thumbnailImages.length;
    if (remainingSlots <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('You have already added the maximum of 14 images.')));
      return;
    }
    final List<XFile> pickedImages =
        await _picker.pickMultiImage(imageQuality: 85);
    if (pickedImages.isNotEmpty) {
      int addedCount = 0;
      for (var img in pickedImages) {
        if (_thumbnailImages.length < maxImages) {
          _thumbnailImages.add(File(img.path));
          addedCount++;
        }
      }
      setState(() {});
      if (addedCount < pickedImages.length) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Image limit reached. Only ${addedCount} of ${pickedImages.length} images were added.')));
      }
    }
  }

  Future<void> _submitAd() async {
    final s = S.of(context);
    List<String> validationErrors = [];
    if (_titleController.text.trim().isEmpty) validationErrors.add(s.title);
    if (selectedMake == null) validationErrors.add(s.make);
    if (selectedModel == null) validationErrors.add(s.model);
    if (selectedYear == null) validationErrors.add(s.year);
    if (_kilometersController.text.trim().isEmpty) validationErrors.add(s.km);
    if (_priceController.text.trim().isEmpty) validationErrors.add(s.price);
    if (selectedTransType == null) validationErrors.add(s.transType);
    if (selectedPhoneNumber == null || selectedPhoneNumber!.trim().isEmpty)
      validationErrors.add(s.phoneNumber);
    if (selectedEmirate == null) validationErrors.add(s.emirate);
    if (_areaController.text.trim().isEmpty) validationErrors.add(s.area);
    if (selectedLocation == 'Dubai souq alharaj') validationErrors.add(s.location);
    if (selectedAdvertiserName == null) validationErrors.add(s.advertiserName);
    if (selectedAdvertiserType == null) validationErrors.add(s.advertiserType);
    if (_mainImage == null) validationErrors.add("Main Image");

    if (validationErrors.isNotEmpty) {
      String errorMessage =
          "${"please_fill_required_fields"}: ${validationErrors.join(', ')}.";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(errorMessage), backgroundColor: Colors.orange));
      return;
    }

    // التحقق من صحة رقم الهاتف
    if (!PhoneNumberFormatter.isValidPhoneNumber(selectedPhoneNumber!)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              "Please enter a valid phone number with correct country code (e.g., +971 5X XXX XXXX or 05X XXX XXXX)."),
          backgroundColor: Colors.red));
      return;
    }

    String formattedPhone =
        PhoneNumberFormatter.formatForApi(selectedPhoneNumber!);

    String? formattedWhatsApp;
    if (selectedWhatsAppNumber != null && selectedWhatsAppNumber!.isNotEmpty) {
      if (!PhoneNumberFormatter.isValidPhoneNumber(selectedWhatsAppNumber!)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                "Please enter a valid WhatsApp number with correct country code."),
            backgroundColor: Colors.red));
        return;
      }
      formattedWhatsApp =
          PhoneNumberFormatter.formatForApi(selectedWhatsAppNumber!);
    }

    final provider = context.read<CarAdProvider>();
    final bool warrantyToSend = selectedWarrantyValue == 'Yes';

    final success = await provider.submitCarAd(
      title: _titleController.text,
      description: _descriptionController.text,
      make: selectedMake!,
      model: selectedModel!,
      trim: selectedTrim,
      year: selectedYear!,
      km: _kilometersController.text,
      price: _priceController.text,
      specs: selectedSpec,
      carType: selectedCarType,
      transType: selectedTransType!,
      fuelType: selectedFuelType,
      color: selectedColor,
      interiorColor: selectedInteriorColor,
      warranty: warrantyToSend,
      engineCapacity: selectedEngineCap,
      cylinders: selectedCylinder,
      horsepower: selectedHorsePower,
      doorsNo: selectedDoor,
      seatsNo: selectedSeat,
      steeringSide: selectedSteeringSide,
      advertiserName: selectedAdvertiserName!,
      phoneNumber: formattedPhone,
      whatsapp: formattedWhatsApp,
      emirate: selectedEmirate!,
      area: selectedLocation.isNotEmpty ? selectedLocation : _areaController.text,
      advertiserType: selectedAdvertiserType!,
      mainImage: _mainImage!,
      thumbnailImages: _thumbnailImages,
    );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Ad posted successfully!"),
          backgroundColor: Colors.green));
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(provider.createAdError ?? "Failed to post ad."),
          backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final currentLocale = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 25.h),
            GestureDetector(
              onTap: () => context.pop(),
              child: Row(children: [
                const SizedBox(width: 5),
                Icon(Icons.arrow_back_ios, color: KTextColor, size: 20.sp),
                Transform.translate(
                    offset: Offset(-3.w, 0),
                    child: Text(s.back,
                        style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                            color: KTextColor)))
              ]),
            ),
            SizedBox(height: 7.h),
            Center(
                child: Text(s.appTitle,
                    style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 24.sp,
                        color: KTextColor))),
            SizedBox(height: 5.h),
          
            Consumer<CarSalesInfoProvider>(
                builder: (context, infoProvider, child) =>
                    _buildSingleSelectField(
                        context,
                        s.make,
                        selectedMake,
                        infoProvider.makes,
                        (v) => setState(() {
                              selectedMake = v;
                              selectedModel = null;
                              selectedTrim = null;
                            }))),
            const SizedBox(height: 7),
            _buildFormRow([
              Consumer<CarSalesInfoProvider>(
                  builder: (context, infoProvider, child) {
                List<String> availableModels = selectedMake != null
                    ? infoProvider.getModelsForMake(selectedMake!)
                    : [];
                return _buildSingleSelectField(
                    context,
                    s.model,
                    selectedModel,
                    availableModels,
                    (v) => setState(() {
                          selectedModel = v;
                          selectedTrim = null;
                        }));
              }),
              Consumer<CarSalesInfoProvider>(
                  builder: (context, infoProvider, child) {
                List<String> availableTrims = selectedModel != null
                    ? infoProvider.getTrimsForModel(selectedModel!)
                    : [];
                return _buildSingleSelectField(context, s.trim, selectedTrim,
                    availableTrims, (v) => setState(() => selectedTrim = v));
              }),
            ]),
            const SizedBox(height: 7),
            _buildFormRow([
              Consumer<CarSalesInfoProvider>(
                  builder: (context, infoProvider, child) =>
                      _buildSingleSelectField(
                          context,
                          s.year,
                          selectedYear,
                          infoProvider.years,
                          (v) => setState(() => selectedYear = v))),
              _buildTitledTextFormField(
                  s.km, _kilometersController, borderColor, currentLocale,
                  isNumber: true, hintText: "50000"),
            ]),
            const SizedBox(height: 7),
            _buildFormRow([
              _buildTitledTextFormField(
                  s.price, _priceController, borderColor, currentLocale,
                  isNumber: true, hintText: "120000"),
              Consumer<CarSalesInfoProvider>(
                  builder: (context, infoProvider, child) =>
                      _buildSingleSelectField(
                          context,
                          s.specs,
                          selectedSpec,
                          infoProvider.specs,
                          (v) => setState(() => selectedSpec = v))),
            ]),
            const SizedBox(height: 7),
              _buildTitledTextFormField(
                s.title, _titleController, borderColor, currentLocale,
                minLines: 2, maxLines: 2),
            const SizedBox(height: 7),
            _buildFormRow([
              Consumer<CarSalesInfoProvider>(
                  builder: (context, infoProvider, child) =>
                      _buildSingleSelectField(
                          context,
                          s.carType,
                          selectedCarType,
                          infoProvider.carTypes,
                          (v) => setState(() => selectedCarType = v))),
              Consumer<CarSalesInfoProvider>(
                  builder: (context, infoProvider, child) =>
                      _buildSingleSelectField(
                          context,
                          s.transType,
                          selectedTransType,
                          infoProvider.transmissionTypes,
                          (v) => setState(() => selectedTransType = v))),
              Consumer<CarSalesInfoProvider>(
                  builder: (context, infoProvider, child) =>
                      _buildSingleSelectField(
                          context,
                          s.fuelType,
                          selectedFuelType,
                          infoProvider.fuelTypes,
                          (v) => setState(() => selectedFuelType = v))),
            ]),
            const SizedBox(height: 7),
            _buildFormRow([
              Consumer<CarSalesInfoProvider>(
                  builder: (context, infoProvider, child) =>
                      _buildSingleSelectField(
                          context,
                          s.color,
                          selectedColor,
                          infoProvider.colors,
                          (v) => setState(() => selectedColor = v))),
              Consumer<CarSalesInfoProvider>(
                  builder: (context, infoProvider, child) =>
                      _buildSingleSelectField(
                          context,
                          s.interiorColor,
                          selectedInteriorColor,
                          infoProvider.interiorColors,
                          (v) => setState(() => selectedInteriorColor = v))),
              Consumer<CarSalesInfoProvider>(
                  builder: (context, infoProvider, child) =>
                      _buildSingleSelectField(
                          context,
                          s.warranty,
                          selectedWarrantyValue,
                          infoProvider.warrantyOptions,
                          (selection) => setState(
                              () => selectedWarrantyValue = selection))),
            ]),
            const SizedBox(height: 15),
            _buildFormRow([
              Consumer<CarSalesInfoProvider>(
                  builder: (context, infoProvider, child) =>
                      _buildSingleSelectField(
                          context,
                          s.engineCapacity,
                          selectedEngineCap,
                          infoProvider.engineCapacities,
                          (v) => setState(() => selectedEngineCap = v),
                          titleFontSize: 12.5)),
              Consumer<CarSalesInfoProvider>(
                  builder: (context, infoProvider, child) =>
                      _buildSingleSelectField(
                          context,
                          s.cylinders,
                          selectedCylinder,
                          infoProvider.cylinders,
                          (v) => setState(() => selectedCylinder = v))),
              Consumer<CarSalesInfoProvider>(
                  builder: (context, infoProvider, child) =>
                      _buildSingleSelectField(
                          context,
                          s.horse_power,
                          selectedHorsePower,
                          infoProvider.horsePowers,
                          (v) => setState(() => selectedHorsePower = v))),
            ]),
            const SizedBox(height: 7),
            _buildFormRow([
              Consumer<CarSalesInfoProvider>(
                  builder: (context, infoProvider, child) =>
                      _buildSingleSelectField(
                          context,
                          s.doorsNo,
                          selectedDoor,
                          infoProvider.doorsNumbers,
                          (v) => setState(() => selectedDoor = v))),
              Consumer<CarSalesInfoProvider>(
                  builder: (context, infoProvider, child) =>
                      _buildSingleSelectField(
                          context,
                          s.seatsNo,
                          selectedSeat,
                          infoProvider.seatsNumbers,
                          (v) => setState(() => selectedSeat = v))),
              Consumer<CarSalesInfoProvider>(
                  builder: (context, infoProvider, child) =>
                      _buildSingleSelectField(
                          context,
                          s.steeringSide,
                          selectedSteeringSide,
                          infoProvider.steeringSides,
                          (v) => setState(() => selectedSteeringSide = v))),
            ]),
            const SizedBox(height: 7),
            Consumer<CarSalesInfoProvider>(
                builder: (context, infoProvider, child) =>
                    TitledSelectOrAddField(
                        title: s.advertiserName,
                        value: selectedAdvertiserName,
                        items: infoProvider.advertiserNames,
                        onChanged: (v) =>
                            setState(() => selectedAdvertiserName = v))),
            const SizedBox(height: 7),
            _buildFormRow([
              Consumer<CarSalesInfoProvider>(
                  builder: (context, infoProvider, child) =>
                      TitledSelectOrAddField(
                          title: s.phoneNumber,
                          value: selectedPhoneNumber,
                          isNumeric: true,
                          items: infoProvider.phoneNumbers,
                          onChanged: (v) =>
                              setState(() => selectedPhoneNumber = v))),
              Consumer<CarSalesInfoProvider>(
                  builder: (context, infoProvider, child) =>
                      TitledSelectOrAddField(
                          title: s.whatsApp,
                          value: selectedWhatsAppNumber,
                          isNumeric: true,
                          items: infoProvider.phoneNumbers,
                          onChanged: (v) =>
                              setState(() => selectedWhatsAppNumber = v))),
            ]),
            const SizedBox(height: 7),
            _buildFormRow([
              Consumer<CarSalesInfoProvider>(
                  builder: (context, infoProvider, child) =>
                      _buildSingleSelectField(
                          context,
                          s.emirate,
                          selectedEmirate,
                          infoProvider.emirates,
                          (v) => setState(() => selectedEmirate = v))),
              Consumer<CarSalesInfoProvider>(
                  builder: (context, infoProvider, child) =>
                      _buildSingleSelectField(
                          context,
                          s.advertiserType,
                          selectedAdvertiserType,
                          infoProvider.advertiserTypes,
                          (v) => setState(() => selectedAdvertiserType = v))),
            ]),
            const SizedBox(height: 7),
            _buildTitledTextFormField(
                s.area, _areaController, borderColor, currentLocale,
                hintText: "Deira"),
            const SizedBox(height: 7),
            TitledDescriptionBox(
                title: s.describeYourCar,
                controller: _descriptionController,
                borderColor: borderColor),
            const SizedBox(height: 10),
            _buildImageButton(
                s.addMainImage, Icons.add_a_photo_outlined, borderColor,
                onPressed: _pickMainImage),
            if (_mainImage != null)
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Center(
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(_mainImage!,
                              height: 150, fit: BoxFit.cover)))),
            const SizedBox(height: 7),
            _buildImageButton(
                '${s.add14Images} (${_thumbnailImages.length}/14)',
                Icons.add_photo_alternate_outlined,
                borderColor,
                onPressed: _pickThumbnailImages),
            if (_thumbnailImages.isNotEmpty)
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _thumbnailImages
                          .map((img) => ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(img,
                                  width: 80, height: 80, fit: BoxFit.cover)))
                          .toList())),
            const SizedBox(height: 10),
            Text(s.location,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16.sp,
                    color: KTextColor)),
            SizedBox(height: 4.h),
            Directionality(
                textDirection: TextDirection.ltr,
                child: Row(children: [
                  SvgPicture.asset('assets/icons/locationicon.svg',
                      width: 20.w, height: 20.h),
                  SizedBox(width: 8.w),
                  Expanded(
                      child: Text(selectedLocation,
                          style: TextStyle(
                              fontSize: 14.sp,
                              color: KTextColor,
                              fontWeight: FontWeight.w500)))
                ])),
            SizedBox(height: 8.h),
            _buildMapSection(context),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: Consumer<CarAdProvider>(
                builder: (context, provider, child) {
                  return provider.isCreatingAd
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _submitAd,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: KPrimaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8))),
                          child: Text(s.next,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        );
                },
              ),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  // --- دوال المساعدة للواجهة ---
  Widget _buildFormRow(List<Widget> children) {
    return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children
            .map((child) => Expanded(
                child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: child)))
            .toList());
  }

  Widget _buildTitledTextFormField(String title,
      TextEditingController controller, Color borderColor, String currentLocale,
      {bool isNumber = false,
      String? hintText,
      int minLines = 1,
      int maxLines = 1}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title,
          style: const TextStyle(
              fontWeight: FontWeight.w600, color: KTextColor, fontSize: 14)),
      const SizedBox(height: 4),
      TextFormField(
        controller: controller,
        minLines: minLines,
        maxLines: maxLines,
        maxLength: maxLines > 1 ? 70 : null,
        style: const TextStyle(
            fontWeight: FontWeight.w500, color: KTextColor, fontSize: 12),
        textAlign: currentLocale == 'ar' ? TextAlign.right : TextAlign.left,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            counterText: "",
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: borderColor)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: borderColor)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: KPrimaryColor, width: 2)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            fillColor: Colors.white,
            filled: true),
      ),
    ]);
  }

  Widget _buildSingleSelectField(BuildContext context, String title,
      String? selectedValue, List<String> allItems, Function(String?) onConfirm,
      {double? titleFontSize}) {
    final s = S.of(context);
    String displayText = selectedValue ?? s.chooseAnOption;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                color: KTextColor,
                fontSize: titleFontSize ?? 14)),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () async {
            final result = await _showSingleSelectPicker(context,
                title: title, items: allItems);
            onConfirm(
                result); // Pass null if nothing is selected or if picker is dismissed
          },
          child: Container(
            height: 48,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color.fromRGBO(8, 194, 201, 1)),
                borderRadius: BorderRadius.circular(8)),
            child: Text(
              displayText,
              style: TextStyle(
                  fontWeight: selectedValue == null
                      ? FontWeight.normal
                      : FontWeight.w500,
                  color:
                      selectedValue == null ? Colors.grey.shade500 : KTextColor,
                  fontSize: 12),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ),
      ],
    );
  }

  Future<String?> _showSingleSelectPicker(BuildContext context,
      {required String title, required List<String> items}) {
    return showModalBottomSheet<String>(
        context: context,
        backgroundColor: Colors.white,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (context) =>
            _SingleSelectBottomSheet(title: title, items: items));
  }

  Widget _buildImageButton(String title, IconData icon, Color borderColor,
      {required VoidCallback onPressed}) {
    return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
            icon: Icon(icon, color: KTextColor),
            label: Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: KTextColor,
                    fontSize: 16)),
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: borderColor),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0)))));
  }

  Widget _buildMapSection(BuildContext context) {
    final s = S.of(context);
    return Consumer<GoogleMapsProvider>(
      builder: (context, mapsProvider, child) {
        return Container(
          height: 320,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Stack(children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: selectedLatLng ?? const LatLng(25.2048, 55.2708), // Dubai coordinates
                    zoom: 14.0,
                  ),
                  onMapCreated: (GoogleMapController controller) {
                    print('Google Map created successfully');
                    mapsProvider.onMapCreated(controller);
                  },
                  mapType: MapType.normal,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: true,
                  compassEnabled: true,
                  // إعدادات التفاعل مع الخريطة - محسنة للتحكم السلس
                  zoomGesturesEnabled: true,
                  scrollGesturesEnabled: true,
                  tiltGesturesEnabled: true,
                  rotateGesturesEnabled: true,
                  // إعدادات إضافية لتحسين الأداء والتفاعل
                  mapToolbarEnabled: true,
                  indoorViewEnabled: true,
                  trafficEnabled: false,
                  buildingsEnabled: true,
                  // تحسين حدود التكبير
                  minMaxZoomPreference: const MinMaxZoomPreference(10.0, 20.0),
                  // تحسين حدود الكاميرا
                  cameraTargetBounds: CameraTargetBounds.unbounded,
                  // إعدادات الإيماءات المتقدمة لتحسين الاستجابة
                  gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                    Factory<OneSequenceGestureRecognizer>(
                      () => EagerGestureRecognizer(),
                    ),
                  },
                  // إضافة وظائف التفاعل المتقدمة
                  onCameraMove: (CameraPosition position) {
                    // يمكن إضافة منطق إضافي هنا عند تحريك الكاميرا
                  },
                  onCameraIdle: () {
                    // يتم استدعاؤها عند توقف حركة الكاميرا
                    print('Camera movement stopped');
                  },
                  onTap: (LatLng position) async {
                    setState(() {
                      selectedLatLng = position;
                    });
                    // تحويل الإحداثيات إلى عنوان
                    final address = await mapsProvider.getAddressFromCoordinates(position.latitude, position.longitude);
                    if (address != null) {
                      setState(() {
                        selectedLocation = address;
                      });
                    }
                  },
                  markers: selectedLatLng != null
                      ? {
                          Marker(
                            markerId: const MarkerId('selected_location'),
                            position: selectedLatLng!,
                            draggable: true,
                            onDragEnd: (LatLng position) async {
                              setState(() {
                                selectedLatLng = position;
                              });
                              // تحويل الإحداثيات إلى عنوان
                              final address = await mapsProvider.getAddressFromCoordinates(position.latitude, position.longitude);
                              if (address != null) {
                                setState(() {
                                  selectedLocation = address;
                                });
                              }
                            },
                          ),
                        }
                      : {},
                ),
              ),
            ),
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.location_on_outlined,
                    color: Colors.white, size: 26),
                label: Text(s.locateMe,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 16)),
                onPressed: () async {
                  print('Locate Me button pressed');
                  try {
                    // إظهار مؤشر التحميل
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('جاري تحديد الموقع...'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    
                    await mapsProvider.getCurrentLocation();
                    print('Current position: ${mapsProvider.currentPosition}');
                    
                    if (mapsProvider.currentPosition != null) {
                      final position = mapsProvider.currentPosition!;
                      setState(() {
                        selectedLatLng = LatLng(position.latitude, position.longitude);
                      });
                      
                      // تحريك الكاميرا إلى الموقع الحالي مع تكبير أكبر
                      await mapsProvider.moveCameraToLocation(position.latitude, position.longitude, zoom: 16.0);
                      
                      // تحويل الإحداثيات إلى عنوان
                      final address = await mapsProvider.getAddressFromCoordinates(position.latitude, position.longitude);
                      if (address != null) {
                        setState(() {
                          selectedLocation = address;
                        });
                        print('Address found: $address');
                      }
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تم تحديد الموقع بنجاح'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      throw Exception('لم يتم العثور على الموقع');
                    }
                  } catch (e) {
                    print('Location error: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('فشل في تحديد الموقع: $e'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: KPrimaryColor,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ]),
        );
      },
    );
  }
}

class TitledDescriptionBox extends StatefulWidget {
  final String title;
  final TextEditingController controller;
  final Color borderColor;
  const TitledDescriptionBox(
      {Key? key,
      required this.title,
      required this.controller,
      required this.borderColor})
      : super(key: key);
  @override
  State<TitledDescriptionBox> createState() => _TitledDescriptionBoxState();
}

class _TitledDescriptionBoxState extends State<TitledDescriptionBox> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.title,
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: KTextColor, fontSize: 14)),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: widget.borderColor)),
          child: Column(
            children: [
              TextFormField(
                controller: widget.controller,
                maxLines: 5,
                minLines: 3,
                maxLength: 5000,
                style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: KTextColor,
                    fontSize: 14),
                decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(12),
                    counterText: ""),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: ListenableBuilder(
                    listenable: widget.controller,
                    builder: (context, child) => Text(
                        '${widget.controller.text.length}/5000',
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12),
                        textDirection: TextDirection.ltr),
                  ),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
}

class TitledSelectOrAddField extends StatelessWidget {
  final String title;
  final String? value;
  final List<String> items;
  final Function(String) onChanged;
  final bool isNumeric;
  const TitledSelectOrAddField(
      {Key? key,
      required this.title,
      required this.value,
      required this.items,
      required this.onChanged,
      this.isNumeric = false})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final borderColor = const Color.fromRGBO(8, 194, 201, 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: KTextColor, fontSize: 14)),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () async {
            final result = await showModalBottomSheet<String>(
              context: context,
              backgroundColor: Colors.white,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(20))),
              builder: (_) => _SearchableSelectOrAddBottomSheet(
                  title: title, items: items, isNumeric: isNumeric),
            );
            if (result != null && result.isNotEmpty) {
              onChanged(result);
            }
          },
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: borderColor),
                borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                    child: Text(value ?? s.chooseAnOption,
                        style: TextStyle(
                            fontWeight: value == null
                                ? FontWeight.normal
                                : FontWeight.w500,
                            color: value == null
                                ? Colors.grey.shade500
                                : KTextColor,
                            fontSize: 12),
                        overflow: TextOverflow.ellipsis))
              ],
            ),
          ),
        )
      ],
    );
  }
}

class _SearchableSelectOrAddBottomSheet extends StatefulWidget {
  final String title;
  final List<String> items;
  final bool isNumeric;
  const _SearchableSelectOrAddBottomSheet(
      {required this.title, required this.items, this.isNumeric = false});
  @override
  _SearchableSelectOrAddBottomSheetState createState() =>
      _SearchableSelectOrAddBottomSheetState();
}

class _SearchableSelectOrAddBottomSheetState
    extends State<_SearchableSelectOrAddBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _addController = TextEditingController();
  List<String> _filteredItems = [];
  String _selectedCountryCode = '+971';

  final Map<String, String> _countryCodes = PhoneNumberFormatter.countryCodes;

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
    setState(() => _filteredItems =
        widget.items.where((i) => i.toLowerCase().contains(query)).toList());
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final borderColor = const Color.fromRGBO(8, 194, 201, 1);
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 16,
          left: 16,
          right: 16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.title,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18.sp,
                    color: KTextColor)),
            const SizedBox(height: 16),
            TextFormField(
                controller: _searchController,
                style: const TextStyle(color: KTextColor),
                decoration: InputDecoration(
                    hintText: s.search,
                    prefixIcon: const Icon(Icons.search, color: KTextColor),
                    hintStyle: TextStyle(color: KTextColor.withOpacity(0.5)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: borderColor)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: KPrimaryColor, width: 2)))),
            const SizedBox(height: 8),
            const Divider(),
            Expanded(
              child: _filteredItems.isEmpty
                  ? Center(
                      child: Text(s.noResultsFound,
                          style: const TextStyle(color: KTextColor)))
                  : ListView.builder(
                      itemCount: _filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = _filteredItems[index];
                        return ListTile(
                            title: Text(item,
                                style: const TextStyle(color: KTextColor)),
                            onTap: () => Navigator.pop(context, item));
                      },
                    ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.isNumeric) ...[
                  Container(
                    width: 90,
                    child: DropdownButtonFormField<String>(
                      value: _selectedCountryCode,
                      items: _countryCodes.entries.map((entry) {
                        return DropdownMenuItem<String>(
                          value: entry.value,
                          child: Text(entry.value,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: KTextColor,
                                  fontSize: 12)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCountryCode = value!;
                        });
                      },
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 12),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: borderColor)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: borderColor)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: KPrimaryColor, width: 2)),
                      ),
                      isDense: true,
                      isExpanded: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: TextFormField(
                    controller: _addController,
                    keyboardType: widget.isNumeric ? TextInputType.number : TextInputType.text,
                    style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: KTextColor,
                        fontSize: 12),
                    decoration: InputDecoration(
                        hintText: widget.isNumeric ? s.phoneNumber : s.addNew,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: borderColor)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: borderColor)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: KPrimaryColor, width: 2)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    String result = _addController.text;
                    if (widget.isNumeric && result.isNotEmpty) {
                      result = '$_selectedCountryCode$result';
                    }
                    if (result.isNotEmpty) Navigator.pop(context, result);
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: KPrimaryColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      minimumSize: const Size(60, 48)),
                  child: Text(s.add,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12))),
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
  final String title;
  final List<String> items;
  const _SingleSelectBottomSheet({required this.title, required this.items});
  @override
  _SingleSelectBottomSheetState createState() =>
      _SingleSelectBottomSheetState();
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterItems() {
    final query = _searchController.text.toLowerCase();
    setState(() => _filteredItems = widget.items
        .where((item) => item.toLowerCase().contains(query))
        .toList());
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final borderColor = const Color.fromRGBO(8, 194, 201, 1);

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 16,
          left: 16,
          right: 16),
      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.title,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18.sp,
                    color: KTextColor)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _searchController,
              style: const TextStyle(color: KTextColor),
              decoration: InputDecoration(
                hintText: s.search,
                prefixIcon: const Icon(Icons.search, color: KTextColor),
                hintStyle: TextStyle(color: KTextColor.withOpacity(0.5)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: borderColor)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: KPrimaryColor, width: 2)),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(),
            Expanded(
              child: _filteredItems.isEmpty
                  ? Center(
                      child: Text(s.noResultsFound,
                          style: const TextStyle(color: KTextColor)))
                  : ListView.builder(
                      itemCount: _filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = _filteredItems[index];
                        return ListTile(
                            title: Text(item,
                                style: const TextStyle(color: KTextColor)),
                            onTap: () => Navigator.pop(context, item));
                      },
                    ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
