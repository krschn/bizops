import 'package:hive/hive.dart';

import '../../domain/entities/supplier.dart';

class SupplierModel extends HiveObject {
  SupplierModel({
    required this.id,
    required this.name,
    required this.isDeleted,
    required this.createdAtMillis,
    required this.updatedAtMillis,
  });

  late String id;
  late String name;
  late bool isDeleted;
  late int createdAtMillis;
  late int updatedAtMillis;

  Supplier toEntity() => Supplier(
        id: id,
        name: name,
        isDeleted: isDeleted,
        createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMillis),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAtMillis),
      );

  static SupplierModel fromEntity(Supplier supplier) => SupplierModel(
        id: supplier.id,
        name: supplier.name,
        isDeleted: supplier.isDeleted,
        createdAtMillis: supplier.createdAt.millisecondsSinceEpoch,
        updatedAtMillis: supplier.updatedAt.millisecondsSinceEpoch,
      );
}

class SupplierModelAdapter extends TypeAdapter<SupplierModel> {
  @override
  final int typeId = 2;

  @override
  SupplierModel read(BinaryReader reader) {
    final id = reader.readString();
    final name = reader.readString();
    final isDeleted = reader.readBool();
    final createdAtMillis = reader.readInt();
    final updatedAtMillis = reader.readInt();
    return SupplierModel(
      id: id,
      name: name,
      isDeleted: isDeleted,
      createdAtMillis: createdAtMillis,
      updatedAtMillis: updatedAtMillis,
    );
  }

  @override
  void write(BinaryWriter writer, SupplierModel obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeBool(obj.isDeleted);
    writer.writeInt(obj.createdAtMillis);
    writer.writeInt(obj.updatedAtMillis);
  }
}
