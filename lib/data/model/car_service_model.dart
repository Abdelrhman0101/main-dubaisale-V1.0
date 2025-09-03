import 'package:advertising_app/data/model/favorite_item_interface_model.dart';
import 'ad_priority.dart';

class CarServiceModel implements FavoriteItemInterface {
  final String title;
  final String price;
  final String image;
  final String details;
  final String contact;
  final String location;
  final String date;
  final bool isPremium;
  final List<String> _images;
  final AdPriority priority;
  final String requirment;

  CarServiceModel({
    required this.title,
    required this.contact,
    required this.price,
    required this.image,
    required this.location,
    required this.date,
    required this.details,
    required this.isPremium,
    required List<String> images,
    required this.priority,
    required this.requirment,
  }) : _images = images;

  @override
  String get line1 => requirment;

  @override
  List<String> get images => _images;
}
