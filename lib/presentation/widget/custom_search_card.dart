import 'package:advertising_app/constant/string.dart';
import 'package:advertising_app/generated/l10n.dart';
import 'package:advertising_app/data/model/ad_priority.dart';
import 'package:advertising_app/data/model/favorite_item_interface_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SearchCard extends StatefulWidget {
  final FavoriteItemInterface item;
  final VoidCallback onDelete;
  final bool showDelete;
  final VoidCallback? onAddToFavorite;
  final bool showLine1;
  final TextSpan? customLine1Span;
   final List<Widget>? customActionButtons;

  const SearchCard({
    super.key,
    required this.item,
    required this.onDelete,
    this.showDelete = true,
    this.onAddToFavorite,
    this.showLine1 = true,
    this.customLine1Span,
     this.customActionButtons,
  });

  @override
  State<SearchCard> createState() => _SearchCardState();
}

class _SearchCardState extends State<SearchCard> {
  late PageController _pageController;
  int _currentPage = 0;

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

  Widget _buildImageWidget(String imagePath) {
    // Check if it's a network URL or local asset
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: imagePath,
        fit: BoxFit.cover,
        width: double.infinity,
        placeholder: (context, url) => Container(
          color: Colors.grey[300],
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: (context, url, error) {
          // طباعة الخطأ في الـ debugging بدلاً من عرض صورة افتراضية
          debugPrint('خطأ في تحميل الصورة من API: $error');
          debugPrint('مسار الصورة: $url');
          return Container(
            color: Colors.grey[300],
            child: const Center(
              child: Icon(
                Icons.broken_image,
                color: Colors.grey,
                size: 50,
              ),
            ),
          );
        },
      );
    } else {
      // Local asset
      return Image.asset(
        imagePath,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          // طباعة الخطأ في الـ debugging بدلاً من عرض صورة افتراضية
          debugPrint('خطأ في تحميل الصورة المحلية: $error');
          debugPrint('مسار الصورة: $imagePath');
          return Container(
            color: Colors.grey[300],
            child: const Center(
              child: Icon(
                Icons.broken_image,
                color: Colors.grey,
                size: 50,
              ),
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Card(
      color: Colors.white,
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              SizedBox(
                height: 200,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: item.images.length > 0 ? item.images.length : 1, // Handle empty images
                  onPageChanged: (index) =>
                      setState(() => _currentPage = index),
                  itemBuilder: (context, index) => ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: item.images.isEmpty 
                          ? Container(
                              color: Colors.grey[300],
                              child: const Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey,
                                  size: 50,
                                ),
                              ),
                            )
                          : _buildImageWidget(item.images[index]),
                        ),
                      ),
              ),
              if (item.images.length > 1) ...[
                Positioned(
                  bottom: 8, left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(8)),
                    child: Text("${_currentPage + 1}/${item.images.length}", style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ),
                 Positioned(
                  bottom: 8, left: 0, right: 0,
                  child: Align(
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(item.images.length, (index) => 
                         Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          width: 7, height: 7,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: _currentPage == index ? Colors.white : Colors.grey.shade400),
                        )
                      ),
                    ),
                  ),
                ),
              ],
              Positioned(
                top: 8,
                left: 8,
                child: _buildPriorityLabel(item.priority),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: _buildTopRightIcon(),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SvgPicture.asset('assets/icons/priceicon.svg', width: 22.w, height: 18.h),
                    SizedBox(width: 8.w),
                    Text(item.price, style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700, fontSize: 16.sp)),
                    const Spacer(),
                    Text(item.date, style: TextStyle(color: Colors.grey, fontSize: 12.sp, fontWeight: FontWeight.w400)),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  item.title,
                  maxLines: 1, // تحديد سطرين كحد أقصى للعنوان
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: KTextColor, fontWeight: FontWeight.w600, fontSize: 16.sp, height: 1.2),
                ),
                if (widget.showLine1 && item.line1.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  // السطر الأول من التفاصيل كما كان
                  RichText(
                    maxLines: 1, // تحديد سطر واحد
                    overflow: TextOverflow.ellipsis, // وضع نقاط عند التجاوز
                    text: widget.customLine1Span ??
                        TextSpan(
                          children: item.line1.split(' ').map((word) {
                            final parts = word.split(':');
                            if (parts.length == 2) {
                              return TextSpan(
                                text: '${parts[0]}:',
                                style: TextStyle(fontWeight: FontWeight.w600, color: KTextColor, fontSize: 14.sp),
                                children: [
                                  TextSpan(
                                    text: '${parts[1]} ',
                                    style: TextStyle(fontWeight: FontWeight.w600, color: KTextColor, fontSize: 16.sp),
                                  ),
                                ],
                              );
                            } else {
                              return TextSpan(text: '$word ', style: const TextStyle(color: KTextColor, fontSize: 16));
                            }
                          }).toList(),
                        ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  item.details,
                  maxLines: 1, // تحديد سطرين
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14.sp, color: KTextColor, fontWeight: FontWeight.w600, height: 1.2),
                ),
                SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, color: KTextColor, size: 20.sp),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14.sp, color: KTextColor, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        item.contact,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp, color: KTextColor),
                      ),
                    ),

                    // الشرط الجديد: إذا كانت هناك أزرار مخصصة، اعرضها
                    if(widget.customActionButtons != null)
                       Row(mainAxisSize: MainAxisSize.min, children: widget.customActionButtons!)
                    
                    // وإلا، اعرض الأزرار الافتراضية
                    else ...[
                      _buildActionIcon(FontAwesomeIcons.whatsapp),
                      const SizedBox(width: 5),
                      _buildActionIcon(Icons.phone),
                    ]
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionIcon(IconData icon) {
    return Container(
      height: 35.h,
      width: 62.w,
      decoration: BoxDecoration(color: const Color(0xFF01547E), borderRadius: BorderRadius.circular(8)),
      child: Center(
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _buildPriorityLabel(AdPriority priority) {
    String text;
    Icon? icon;
    switch (priority) {
      case AdPriority.PremiumStar: text = 'Premium'; icon = const Icon(Icons.star, color: Colors.amber, size: 18); break;
      case AdPriority.premium: text = 'Premium'; break;
      case AdPriority.featured: text = 'Featured'; break;
      
     // case AdPriority.free: return const SizedBox.shrink();
      case AdPriority.free:   text = 'Free';break;
    }
    return Container(height: 20.h, padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 0), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFC9F8FE), Color(0xFF08C2C9)], begin: Alignment.topCenter, end: Alignment.bottomCenter), borderRadius: BorderRadius.circular(4)), child: Row(mainAxisSize: MainAxisSize.min, children: [ Text(text, style: const TextStyle(color: KTextColor, fontSize: 12, fontWeight: FontWeight.w400)), if (icon != null) ...[const SizedBox(width: 3), icon]]));
  }

  Widget _buildTopRightIcon() {
    if (widget.onAddToFavorite != null) {
      return IconButton(icon: const Icon(Icons.favorite_border, color: Colors.grey), onPressed: _handleAddToFavorite);
    } else if (widget.showDelete) {
      return IconButton(icon: const Icon(Icons.favorite, color: Colors.red), onPressed: widget.onDelete);
    } else {
      return const SizedBox.shrink();
    }
  }

  void _handleAddToFavorite() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.of(context).add_to_favorite, style: const TextStyle(color: KTextColor, fontSize: 16)),
        content: Text(S.of(context).confirm_add_to_favorite, style: const TextStyle(color: KTextColor, fontSize: 18)),
        actions: [
          TextButton(
            child: Text(S.of(context).cancel, style: const TextStyle(color: KTextColor, fontSize: 20)),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text(S.of(context).yes, style: const TextStyle(color: KTextColor, fontSize: 20)),
            onPressed: () {
              Navigator.pop(context);
              widget.onAddToFavorite?.call();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.of(context).added_to_favorite)));
            },
          ),
        ],
      ),
    );
  }
}