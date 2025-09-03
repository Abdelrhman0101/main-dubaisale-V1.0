class OfferBoxModel {
  final String image;
  final String price;
  final String title;
  final String location;
  final String contact;
  final String? year;
  final String? km;


  OfferBoxModel({
    this.km,
    this.year, 
    required this.image,
    required this.price,
    required this.title,
    required this.location,
    required this.contact
  });
}
