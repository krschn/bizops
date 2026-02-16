import 'package:hive/hive.dart';

import '../../domain/entities/product.dart';

class ProductModel extends HiveObject {
  ProductModel({
    required this.id,
    required this.name,
    required this.price,
    required this.unit,
    required this.isDeleted,
    required this.createdAtMillis,
    required this.updatedAtMillis,
  });

  late String id;
  late String name;
  late double price;
  late String unit;
  late bool isDeleted;
  late int createdAtMillis;
  late int updatedAtMillis;

  Product toEntity() => Product(
        id: id,
        name: name,
        price: price,
        unit: unit,
        isDeleted: isDeleted,
        createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMillis),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAtMillis),
      );

  static ProductModel fromEntity(Product product) => ProductModel(
        id: product.id,
        name: product.name,
        price: product.price,
        unit: product.unit,
        isDeleted: product.isDeleted,
        createdAtMillis: product.createdAt.millisecondsSinceEpoch,
        updatedAtMillis: product.updatedAt.millisecondsSinceEpoch,
      );
}

class ProductModelAdapter extends TypeAdapter<ProductModel> {
  @override
  final int typeId = 1;

  @override
  ProductModel read(BinaryReader reader) {
    final id = reader.readString();
    final name = reader.readString();
    final price = reader.readDouble();
    final unit = reader.readString();
    final isDeleted = reader.readBool();
    final createdAtMillis = reader.readInt();
    final updatedAtMillis = reader.readInt();
    return ProductModel(
      id: id,
      name: name,
      price: price,
      unit: unit,
      isDeleted: isDeleted,
      createdAtMillis: createdAtMillis,
      updatedAtMillis: updatedAtMillis,
    );
  }

  @override
  void write(BinaryWriter writer, ProductModel obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeDouble(obj.price);
    writer.writeString(obj.unit);
    writer.writeBool(obj.isDeleted);
    writer.writeInt(obj.createdAtMillis);
    writer.writeInt(obj.updatedAtMillis);
  }
}
