// في ملف: data/model/filter_options_model.dart

class MakeModel {
  final int id;
  final String name;

  MakeModel({required this.id, required this.name});

  factory MakeModel.fromJson(Map<String, dynamic> json) {
    return MakeModel(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? 'Unknown Make',
    );
  }
}

class CarModel {
  final int id;
  final String name;
  final int makeId; // سيبقى اسمه هكذا داخل التطبيق

  CarModel({required this.id, required this.name, required this.makeId});

  factory CarModel.fromJson(Map<String, dynamic> json) {
    return CarModel(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? 'Unknown Model',
      // +++ التصحيح: اقرأ من الحقل الصحيح car_make_id +++
      makeId: json['car_make_id'] ?? 0,
    );
  }
}

class TrimModel {
  final int id;
  final String name;
  // +++ إضافة الحقل المفقود للربط +++
  final int modelId; 

  TrimModel({required this.id, required this.name, required this.modelId});

  factory TrimModel.fromJson(Map<String, dynamic> json) {
    return TrimModel(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? 'Unknown Trim',
      // +++ التصحيح: اقرأ من الحقل الصحيح car_model_id +++
      modelId: json['car_model_id'] ?? 0,
    );
  }
}