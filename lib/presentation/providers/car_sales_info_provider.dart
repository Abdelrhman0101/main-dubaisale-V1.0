import 'package:flutter/material.dart';

class CarSalesInfoProvider extends ChangeNotifier {
  // Makes data
  final List<String> _makes = [
    'BMW',
    'Honda',
    'Toyota',
  ];

  // Models data
  final List<String> _models = [
    'Corolla',
    '3 Series',
    'X3',
    'X5',
    'Accord',
    'Civic',
    'CR-V',
  ];

  // Trims data
  final List<String> _trims = [
    'LE',
    'L',
    'LE',
    'XLE',
  ];

  // Fake data for other fields
  final List<String> _years = [
    '2024',
    '2023',
    '2022',
    '2021',
    '2020',
    '2019',
    '2018',
    '2017',
    '2016',
    '2015',
  ];

  final List<String> _specs = [
    'GCC',
    'Japanese',
    'American',
    'European',
    'Korean',
  ];

  final List<String> _carTypes = [
    'SUV',
    'Sedan',
    'Hatchback',
    'Coupe',
    'Convertible',
    'Wagon',
    'Pickup',
    'Van',
  ];

  final List<String> _transmissionTypes = [
    'Automatic',
    'Manual',
    'CVT',
    'Semi-Automatic',
  ];

  final List<String> _fuelTypes = [
    'Petrol',
    'Diesel',
    'Electric',
    'Hybrid',
    'Plug-in Hybrid',
  ];

  final List<String> _colors = [
    'White',
    'Black',
    'Silver',
    'Gray',
    'Blue',
    'Red',
    'Green',
    'Brown',
    'Gold',
    'Orange',
  ];

  final List<String> _interiorColors = [
    'Beige',
    'Black',
    'Red',
    'Brown',
    'Gray',
    'White',
    'Tan',
  ];

  final List<String> _engineCapacities = [
    '1000',
    '1200',
    '1400',
    '1600',
    '1800',
    '2000',
    '2500',
    '3000',
    '3500',
    '4000',
    '5000',
    '6000',
  ];

  final List<String> _cylinders = [
    '3',
    '4',
    '5',
    '6',
    '8',
    '10',
    '12',
  ];

  final List<String> _horsePowers = [
    '100',
    '120',
    '150',
    '178',
    '200',
    '250',
    '300',
    '350',
    '400',
    '450',
    '500',
    '600',
  ];

  final List<String> _doorsNumbers = [
    '2',
    '3',
    '4',
    '5',
  ];

  final List<String> _seatsNumbers = [
    '2',
    '4',
    '5',
    '7',
    '8',
    '9',
  ];

  final List<String> _steeringSides = [
    'Left',
    'Right',
  ];

  final List<String> _advertiserNames = [
    'Ahmed Ali',
    'CarDealer UAE',
    'Dubai Motors',
    'Al Futtaim Motors',
    'Arabian Automobiles',
    'Premier Motors',
    'Gargash Motors',
    'Auto Mall',
  ];

  final List<String> _phoneNumbers = [
    '+971501234567',
    '+971521234567',
    '+971551234567',
    '+971561234567',
    '+971581234567',
  ];

  final List<String> _emirates = [
    'Dubai',
    'Abu Dhabi',
    'Sharjah',
    'Ajman',
    'Ras Al Khaimah',
    'Fujairah',
    'Umm Al Quwain',
  ];

  final List<String> _advertiserTypes = [
    'Individual',
    'Dealer',
    'Company',
  ];

  final List<String> _warrantyOptions = [
    'Yes',
    'No',
  ];

  // Getters
  List<String> get makes => _makes;
  List<String> get models => _models;
  List<String> get trims => _trims;
  List<String> get years => _years;
  List<String> get specs => _specs;
  List<String> get carTypes => _carTypes;
  List<String> get transmissionTypes => _transmissionTypes;
  List<String> get fuelTypes => _fuelTypes;
  List<String> get colors => _colors;
  List<String> get interiorColors => _interiorColors;
  List<String> get engineCapacities => _engineCapacities;
  List<String> get cylinders => _cylinders;
  List<String> get horsePowers => _horsePowers;
  List<String> get doorsNumbers => _doorsNumbers;
  List<String> get seatsNumbers => _seatsNumbers;
  List<String> get steeringSides => _steeringSides;
  List<String> get advertiserNames => _advertiserNames;
  List<String> get phoneNumbers => _phoneNumbers;
  List<String> get emirates => _emirates;
  List<String> get advertiserTypes => _advertiserTypes;
  List<String> get warrantyOptions => _warrantyOptions;

  // Methods to get models based on selected make
  List<String> getModelsForMake(String make) {
    switch (make) {
      case 'BMW':
        return ['3 Series', 'X3', 'X5'];
      case 'Honda':
        return ['Accord', 'Civic', 'CR-V'];
      case 'Toyota':
        return ['Corolla'];
      default:
        return _models;
    }
  }

  // Methods to get trims based on selected model
  List<String> getTrimsForModel(String model) {
    switch (model) {
      case 'Corolla':
        return ['LE', 'L', 'XLE'];
      case '3 Series':
      case 'X3':
      case 'X5':
        return ['LE', 'L'];
      case 'Accord':
      case 'Civic':
      case 'CR-V':
        return ['LE', 'XLE'];
      default:
        return _trims;
    }
  }
}