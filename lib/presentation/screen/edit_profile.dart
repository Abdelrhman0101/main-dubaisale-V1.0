import 'dart:io';
import 'package:advertising_app/presentation/providers/auth_repository.dart';
import 'package:advertising_app/presentation/providers/google_maps_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:advertising_app/data/model/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:advertising_app/constant/string.dart';
import 'package:advertising_app/generated/l10n.dart';
import 'package:advertising_app/presentation/widget/custom_bottom_nav.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  // Controllers to display user data
  final _userNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsAppController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  final _advertiserNameController = TextEditingController();
  final _advertiserTypeController = TextEditingController();

  // State variables for image handling
  final ImagePicker _picker = ImagePicker();
  File? _logoImageFile;

  // Location-related state variables
  LatLng? _userLocation;
  String? _userAddress;
  bool _isLoadingLocation = false;
  
  // FlutterSecureStorage instance for saving location data
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.user == null) {
        authProvider.fetchUserProfile();
      }
      // Load saved location data when the screen initializes
      _loadSavedLocation();
    });
  }

  // Save location data to FlutterSecureStorage
  Future<void> _saveLocationToStorage() async {
    if (_userLocation != null && _userAddress != null) {
      try {
        await _storage.write(key: 'user_latitude', value: _userLocation!.latitude.toString());
        await _storage.write(key: 'user_longitude', value: _userLocation!.longitude.toString());
        await _storage.write(key: 'user_address', value: _userAddress!);
        print('Location saved to secure storage successfully');
      } catch (e) {
        print('Error saving location to storage: $e');
      }
    }
  }

  // Load location data from FlutterSecureStorage
  Future<void> _loadSavedLocation() async {
    try {
      final latitude = await _storage.read(key: 'user_latitude');
      final longitude = await _storage.read(key: 'user_longitude');
      final address = await _storage.read(key: 'user_address');
      
      if (latitude != null && longitude != null && address != null) {
        setState(() {
          _userLocation = LatLng(double.parse(latitude), double.parse(longitude));
          _userAddress = address;
        });
        print('Location loaded from secure storage: $address');
      }
    } catch (e) {
      print('Error loading location from storage: $e');
    }
  }

  // Initialize user location automatically
  Future<void> _initializeUserLocation() async {
    if (_userLocation != null) return; // Already initialized
    
    setState(() {
      _isLoadingLocation = true;
    });
    
    try {
      final mapsProvider = context.read<GoogleMapsProvider>();
      await mapsProvider.getCurrentLocation();
      
      if (mapsProvider.currentLocationData != null) {
        final locationData = mapsProvider.currentLocationData!;
        final address = await mapsProvider.getAddressFromCoordinates(
          locationData.latitude!, 
          locationData.longitude!
        );
        
        setState(() {
          _userLocation = LatLng(locationData.latitude!, locationData.longitude!);
          _userAddress = address ?? 'Unknown location';
        });
      }
    } catch (e) {
      print('Error initializing location: $e');
      // Set default Dubai location if current location fails
      setState(() {
        _userLocation = const LatLng(25.2048, 55.2708);
        _userAddress = 'Dubai, UAE';
      });
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  // Fills the text fields with data from the user model
  void _updateTextFields(UserModel? user) {
    if (user != null) {
      _userNameController.text = user.username;
      _emailController.text = user.email;
      _phoneController.text = user.phone;
      _whatsAppController.text = user.whatsapp ?? '';
      _advertiserNameController.text = user.advertiserName ?? '';
      _advertiserTypeController.text = user.advertiserType ?? '';
      _passwordController.text = "••••••••"; // Placeholder for password
      if (user.advertiserLogo != null && user.advertiserLogo!.isNotEmpty) {
        _logoImageFile = File(user.advertiserLogo!);
      }
      
      // Update location data from user model if available
      if (user.latitude != null && user.longitude != null) {
        setState(() {
          _userLocation = LatLng(user.latitude!, user.longitude!);
          _userAddress = user.address ?? 'Unknown location';
        });
      }
    }
  }

  // Opens the image gallery to pick a logo and upload it
  Future<void> _pickLogoImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final authProvider = context.read<AuthProvider>();
      final newLogoFile = File(pickedFile.path);
      
      final success = await authProvider.uploadLogo(newLogoFile.path);
      if (success) {
        setState(() {
          _logoImageFile = newLogoFile;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logo uploaded successfully!'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authProvider.updateError ?? 'Failed to upload logo'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Deletes the currently selected logo image
  Future<void> _deleteLogoImage() async {
    final authProvider = context.read<AuthProvider>();
    
    final success = await authProvider.deleteLogo();
    if (success) {
      setState(() {
        _logoImageFile = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logo deleted successfully!'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.updateError ?? 'Failed to delete logo'), backgroundColor: Colors.red),
      );
    }
  }

  // Save location data to user profile
  Future<void> _saveLocationData() async {
    if (_userLocation == null) return;
    
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;
    
    if (user == null) return;
    
    final success = await authProvider.updateUserProfile(
      username: user.username,
      email: user.email,
      phone: user.phone,
      whatsapp: user.whatsapp,
      advertiserName: user.advertiserName,
      advertiserType: user.advertiserType,
      latitude: _userLocation!.latitude,
      longitude: _userLocation!.longitude,
      address: _userAddress,
    );
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.updateError ?? 'Failed to update location'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Get current location method with improved efficiency
  Future<void> _getCurrentLocation() async {
    if (_isLoadingLocation) return; // Prevent multiple simultaneous calls
    
    print('Locate Me button pressed');
    setState(() {
      _isLoadingLocation = true;
    });
    
    try {
      // Show loading snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('جاري تحديد موقعك...'),
          backgroundColor: Color(0xFF01547E),
          duration: Duration(seconds: 2),
        ),
      );

      final mapsProvider = context.read<GoogleMapsProvider>();
      await mapsProvider.getCurrentLocation();

      if (mapsProvider.currentLocationData != null) {
        final locationData = mapsProvider.currentLocationData!;
        
        // Convert coordinates to address first
        final address = await mapsProvider.getAddressFromCoordinates(
            locationData.latitude!, locationData.longitude!);
        
        setState(() {
          _userLocation = LatLng(
              locationData.latitude!, locationData.longitude!);
          _userAddress = address ?? 'موقع غير معروف';
        });

        // Move camera to current location with higher zoom
        await mapsProvider.moveCameraToLocation(
            locationData.latitude!, locationData.longitude!,
            zoom: 16.0);

        print('Address found: ${_userAddress}');

        // Save location data automatically to database and secure storage
        await _saveLocationData();
        await _saveLocationToStorage();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديث الموقع بنجاح!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        throw Exception('فشل في الحصول على الموقع');
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
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  // Open Google Maps method
  Future<void> _openGoogleMaps() async {
    try {
      // Get current location if available, otherwise use Dubai coordinates
      double lat = _userLocation?.latitude ?? 25.2048;
      double lng = _userLocation?.longitude ?? 55.2708;
      
      // Create Google Maps URL
      final String googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
      final Uri url = Uri.parse(googleMapsUrl);
      
      // Try to launch Google Maps
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        // Fallback to web version
        final String webUrl = 'https://maps.google.com/?q=$lat,$lng';
        final Uri webUri = Uri.parse(webUrl);
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Opening Google Maps...'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to open Google Maps: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Navigate to location picker screen
  Future<void> _navigateToLocationPicker() async {
    try {
      // Prepare initial location and address for the picker
      double? initialLat = _userLocation?.latitude;
      double? initialLng = _userLocation?.longitude;
      String? initialAddress = _userAddress;
      
      // Build the route with query parameters
      String route = '/location_picker';
      if (initialLat != null && initialLng != null) {
        route += '?lat=$initialLat&lng=$initialLng';
        if (initialAddress != null && initialAddress.isNotEmpty) {
          route += '&address=${Uri.encodeComponent(initialAddress)}';
        }
      }
      
      // Navigate to location picker and wait for result
      final result = await context.push(route);
      
      // Handle the returned location data
      if (result != null && result is Map<String, dynamic>) {
        final LatLng? location = result['location'] as LatLng?;
        final String? address = result['address'] as String?;
        
        if (location != null) {
          setState(() {
            _userLocation = location;
            if (address != null && address.isNotEmpty) {
              _userAddress = address;
            }
          });
          
          // Save the new location data to database and secure storage
          await _saveLocationData();
          await _saveLocationToStorage();
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم تحديث الموقع بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في اختيار الموقع: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _userNameController.dispose();
    _phoneController.dispose();
    _whatsAppController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _advertiserNameController.dispose();
    _advertiserTypeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Update text fields whenever the user data changes
        _updateTextFields(authProvider.user);

        return Scaffold(
          backgroundColor: Colors.white,
          bottomNavigationBar: const CustomBottomNav(currentIndex: 4),
          body: SafeArea(
            child: authProvider.isLoadingProfile && authProvider.user == null
                ? const Center(child: CircularProgressIndicator())
                : authProvider.profileError != null && authProvider.user == null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Error: ${authProvider.profileError}", style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: () => authProvider.fetchUserProfile(),
                              child: const Text("Try Again"),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 15),
                            GestureDetector(
                              onTap: () => context.pop(),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.arrow_back_ios, color: KTextColor, size: 17.sp),
                                  Transform.translate(
                                    offset: Offset(-3.w, 0),
                                    child: Text(
                                      S.of(context).back,
                                      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500, color: KTextColor),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Center(
                              child: Text(
                                S.of(context).myProfile,
                                style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.w500, color: KTextColor),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Display-only fields
                            _buildLabel(S.of(context).userName),
                            _buildEditableField(_userNameController, () => context.push('/profile')),
                            
                            _buildLabel(S.of(context).phone),
                            _buildPhoneField(_phoneController, () => context.push('/profile')),
                            
                            _buildLabel(S.of(context).whatsApp),
                            _buildPhoneField(_whatsAppController, () => context.push('/profile')),
                            
                            _buildLabel(S.of(context).password),
                            _buildEditableField(_passwordController, () => context.push('/profile'), isPassword: true),
                            
                            _buildLabel(S.of(context).email),
                            _buildEditableField(_emailController, () => context.push('/profile')),
                            
                            _buildLabel(S.of(context).advertiserName),
                            _buildEditableField(_advertiserNameController, () => context.push('/profile')),
                            
                            _buildLabel(S.of(context).advertiserType),
                            _buildEditableField(_advertiserTypeController, () => context.push('/profile')),
                            
                            // Interactive Logo Section
                            _buildLabel(S.of(context).advertiserLogo),
                            if (_logoImageFile == null)
                              // If no image is selected, show the "Upload" button
                              _buildUploadButton()
                            else
                              // If an image is selected, show it with Edit/Delete buttons
                              _buildImagePreview(),
                            
                            const SizedBox(height: 10),
                            
                            Text(S.of(context).advertiserLocation, style: TextStyle(color: KTextColor, fontSize: 16.sp, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 5),
                            Text(_userAddress ?? S.of(context).address, style: TextStyle(color: KTextColor, fontSize: 16.sp, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 5),
                            
                            _buildMapSection(context),
                            
                            const SizedBox(height: 10),
                            
                            // Go to Edit Page button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => context.push('/profile'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF01547E),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                                ),
                                child: Text(S.of(context).editprof4), // "Go to Edit Page"
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Go to Car Sales Ads button
                            // SizedBox(
                            //   width: double.infinity,
                            //   child: ElevatedButton(
                            //     onPressed: () {
                            //       // تمرير بيانات الموقع إلى car_sales_ads_screen
                            //       String route = '/car_sales_ads';
                            //       if (_userAddress != null && _userLocation != null) {
                            //         route += '?location=${Uri.encodeComponent(_userAddress!)}&lat=${_userLocation!.latitude}&lng=${_userLocation!.longitude}';
                            //       }
                            //       context.push(route);
                            //     },
                            //     style: ElevatedButton.styleFrom(
                            //       backgroundColor: const Color.fromRGBO(8, 194, 201, 1),
                            //       foregroundColor: Colors.white,
                            //       padding: const EdgeInsets.symmetric(vertical: 12),
                            //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            //       textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                            //     ),
                            //     child: const Text('Go to Car Sales Ads'),
                            //   ),
                            // ),
                           
                           
                           
                          ],
                        ),
                      ),
          ),
        );
      },
    );
  }

  // --- Helper Widgets ---

  /// Builds the "Upload Your Logo" button.
  Widget _buildUploadButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color.fromRGBO(8, 194, 201, 1)),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[50],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.camera_alt, color: KTextColor),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              S.of(context).uploadYourLogo,
              style: const TextStyle(color: KTextColor, fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the image preview with overlay buttons (Edit/Delete).
  Widget _buildImagePreview() {
    final user = context.watch<AuthProvider>().user;
    
    return SizedBox(
      height: 200.h,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // The selected image or network image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _logoImageFile != null
                ? Image.file(_logoImageFile!, fit: BoxFit.cover)
                : (user?.advertiserLogo != null && user!.advertiserLogo!.isNotEmpty
                    ? Image.network(user.advertiserLogo!, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) {
                        return const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey));
                      })
                    : const Center(child: Icon(Icons.person, size: 50, color: Colors.grey))),
          ),
          // A semi-transparent overlay to make buttons more visible
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.black.withOpacity(0.4),
            ),
          ),
          // The action buttons (Edit, Delete) in the center
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageActionButton(
                  icon: Icons.edit,
                  label: S.of(context).edit, // "Edit"
                  onTap: _pickLogoImage,
                  color: Colors.white,
                ),
                _buildImageActionButton(
                  icon: Icons.delete,
                  label: "delete", // "Delete"
                  onTap: _deleteLogoImage,
                  color: Colors.red.shade300,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a single action button for the image preview.
  Widget _buildImageActionButton({required IconData icon, required String label, required VoidCallback onTap, required Color color}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28.sp),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14.sp),
          ),
        ],
      ),
    );
  }

  /// Builds a generic label for text fields.
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Text(text, style: TextStyle(color: KTextColor, fontWeight: FontWeight.w500, fontSize: 16.sp)),
    );
  }

  /// Builds a read-only text field that shows the edit popup on tap.
  Widget _buildEditableField(TextEditingController controller, VoidCallback onEdit, {bool isPassword = false}) {
    return GestureDetector(
     onTap: () => _showEditPopup(onEdit),
      child: AbsorbPointer(
        child: TextFormField(
          controller: controller,
          readOnly: true,
          obscureText: isPassword,
          style: TextStyle(color: KTextColor, fontSize: 14.sp, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color.fromRGBO(8, 194, 201, 1))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color.fromRGBO(8, 194, 201, 1))),
          ),
        ),
      ),
    );
  }

  /// Builds a read-only phone field that shows the edit popup on tap.
  Widget _buildPhoneField(TextEditingController controller, VoidCallback onEdit) {
    return GestureDetector(
      onTap: () => _showEditPopup(onEdit),
      child: AbsorbPointer(
        child: TextFormField(
          controller: controller,
          readOnly: true,
          style: TextStyle(color: KTextColor, fontSize: 14.sp, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 7),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color.fromRGBO(8, 194, 201, 1))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color.fromRGBO(8, 194, 201, 1))),
          ),
        ),
      ),
    );
  }

  /// Shows the popup dialog asking the user to navigate to the edit page.
  void _showEditPopup(VoidCallback onEdit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            const Icon(Icons.edit, color: Color(0xFF01547E)),
            const SizedBox(width: 8),
            Text(S.of(context).editing1, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Color(0xFF01547E))),
          ],
        ),
        content: Text(S.of(context).editit2, style: TextStyle(fontSize: 16.sp, color: KTextColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(S.of(context).cancel, style: TextStyle(color: Colors.grey[700], fontSize: 14)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onEdit();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF01547E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(S.of(context).edit3),
          ),
        ],
      ),
    );
  }

  /// Builds the interactive map section for location display and editing.
  Widget _buildMapSection(BuildContext context) {
    final s = S.of(context);
    return Consumer<GoogleMapsProvider>(
      builder: (context, mapsProvider, child) {
        return Container(
          height: 200.h,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color.fromRGBO(8, 194, 201, 1)),
          ),
          child: _isLoadingLocation
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF01547E),
                  ),
                )
              : _userLocation == null
                  ? Stack(
                      children: [
                        // Background placeholder
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              color: Colors.grey[100],
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.location_off,
                                      size: 48,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Press "Locate Me" to set your location',
                                      style: TextStyle(color: Colors.grey, fontSize: 14),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Buttons at the bottom
                        Positioned(
                          bottom: 2,
                          left: 16,
                          right: 16,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  // Locate Me button
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      icon: _isLoadingLocation 
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : const Icon(Icons.location_on_outlined, color: Colors.white, size: 20),
                                      label: Text(
                                        _isLoadingLocation ? 'جاري التحديد...' : s.locateMe,
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14),
                                      ),
                                      onPressed: _isLoadingLocation ? null : () async {
                                        await _getCurrentLocation();
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _isLoadingLocation ? Colors.grey : const Color(0xFF01547E),
                                        minimumSize: const Size(0, 40),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Open Google Map button
                                  Expanded(
                                    child: 
                                    ElevatedButton.icon(
                                  icon: const Icon(Icons.location_on_outlined, color: Colors.white, size: 20),
                                  label: const Text(
                                    "Open Google Map",
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 12),
                                  ),
                                  onPressed: () async {
                                    await _navigateToLocationPicker();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF01547E),
                                    minimumSize: const Size(0, 40),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                            ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Location Picker button
                              // SizedBox(
                              //   width: double.infinity,
                              //   child: 
                              //   ElevatedButton.icon(
                              //     icon: const Icon(Icons.place, color: Colors.white, size: 20),
                              //     label: const Text(
                              //       'اختيار الموقع من الخريطة',
                              //       style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14),
                              //     ),
                              //     onPressed: () async {
                              //       await _navigateToLocationPicker();
                              //     },
                              //     style: ElevatedButton.styleFrom(
                              //       backgroundColor: const Color(0xFF4CAF50),
                              //       minimumSize: const Size(0, 40),
                              //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              //     ),
                              //   ),
                              // ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Stack(
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: _userLocation!,
                                zoom: 15.0,
                              ),
                              onMapCreated: (GoogleMapController controller) {
                                mapsProvider.onMapCreated(controller);
                              },
                              mapType: MapType.normal,
                              myLocationEnabled: false,
                              myLocationButtonEnabled: false,
                              zoomControlsEnabled: true,
                              compassEnabled: true,
                              zoomGesturesEnabled: true,
                              scrollGesturesEnabled: true,
                              tiltGesturesEnabled: true,
                              rotateGesturesEnabled: true,
                              onTap: (LatLng position) async {
                                 // Update user location when tapping on map
                                 setState(() {
                                   _userLocation = position;
                                 });
                                 
                                 // Get address for the new location
                                 final address = await mapsProvider.getAddressFromCoordinates(
                                   position.latitude,
                                   position.longitude,
                                 );
                                 
                                 if (address != null) {
                                   setState(() {
                                     _userAddress = address;
                                   });
                                 }
                                 
                                 // Save location data automatically
                                 await _saveLocationData();
                               },
                              markers: _userLocation != null
                                  ? {
                                      Marker(
                                        markerId: const MarkerId('user_location'),
                                        position: _userLocation!,
                                        draggable: true,
                                        onDragEnd: (LatLng position) async {
                                           setState(() {
                                             _userLocation = position;
                                           });
                                           
                                           // Get address for the new location
                                           final address = await mapsProvider.getAddressFromCoordinates(
                                             position.latitude,
                                             position.longitude,
                                           );
                                           
                                           if (address != null) {
                                             setState(() {
                                               _userAddress = address;
                                             });
                                           }
                                           
                                           // Save location data automatically
                                           await _saveLocationData();
                                         },
                                      ),
                                    }
                                  : {},
                            ),
                          ),
                        ),
                        // Buttons at the bottom when map is visible
                        Positioned(
                          bottom: 16,
                          left: 16,
                          right: 16,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  // Locate Me button
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      icon: const Icon(Icons.location_on_outlined, color: Colors.white, size: 20),
                                      label: Text(
                                        s.locateMe,
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14),
                                      ),
                                      onPressed: () async {
                                        await _getCurrentLocation();
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF01547E),
                                        minimumSize: const Size(0, 40),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Open Google Map button
                                  Expanded(
                                    child:
                                   

                                     ElevatedButton.icon(
                                  icon: const Icon(Icons.location_on_outlined, color: Colors.white, size: 20),
                                  label: const Text(
                                    "Open Google Map",
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 12),
                                  ),
                                  onPressed: () async {
                                    await _navigateToLocationPicker();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF01547E),
                                    minimumSize: const Size(0, 40),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Location Picker button
                              // SizedBox(
                              //   width: double.infinity,
                              //   child: ElevatedButton.icon(
                              //     icon: const Icon(Icons.place, color: Colors.white, size: 20),
                              //     label: const Text(
                              //       'اختيار الموقع من الخريطة',
                              //       style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14),
                              //     ),
                              //     onPressed: () async {
                              //       await _navigateToLocationPicker();
                              //     },
                              //     style: ElevatedButton.styleFrom(
                              //       backgroundColor: const Color(0xFF4CAF50),
                              //       minimumSize: const Size(0, 40),
                              //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              //     ),
                              //   ),
                              // ),
                           
                           
                            ],
                          ),
                        ),
                      ],
                    ),
        );
      },
    );
  }
}