import 'package:hive/hive.dart';

import '../../domain/entities/transaction.dart';
import 'transaction_line_model.dart';

class TransactionModel extends HiveObject {
  TransactionModel({
    required this.id,
    required this.transactedAtMillis,
    required this.lines,
    required this.grandTotal,
    required this.isDeleted,
    required this.createdAtMillis,
    required this.updatedAtMillis,
  });

  late String id;
  late int transactedAtMillis;
  late List<TransactionLineModel> lines;
  late double grandTotal;
  late bool isDeleted;
  late int createdAtMillis;
  late int updatedAtMillis;

  Transaction toEntity() => Transaction(
        id: id,
        transactedAt: DateTime.fromMillisecondsSinceEpoch(transactedAtMillis),
        lines: lines.map((l) => l.toEntity()).toList(),
        grandTotal: grandTotal,
        isDeleted: isDeleted,
        createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMillis),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAtMillis),
      );

  static TransactionModel fromEntity(Transaction tx) => TransactionModel(
        id: tx.id,
        transactedAtMillis: tx.transactedAt.millisecondsSinceEpoch,
        lines: tx.lines.map(TransactionLineModel.fromEntity).toList(),
        grandTotal: tx.grandTotal,
        isDeleted: tx.isDeleted,
        createdAtMillis: tx.createdAt.millisecondsSinceEpoch,
        updatedAtMillis: tx.updatedAt.millisecondsSinceEpoch,
      );
}

class TransactionModelAdapter extends TypeAdapter<TransactionModel> {
  @override
  final int typeId = 4;

  @override
  TransactionModel read(BinaryReader reader) {
    final id = reader.readString();
    final transactedAtMillis = reader.readInt();
    final lines = reader.readList().cast<TransactionLineModel>();
    final grandTotal = reader.readDouble();
    final isDeleted = reader.readBool();
    final createdAtMillis = reader.readInt();
    final updatedAtMillis = reader.readInt();
    return TransactionModel(
      id: id,
      transactedAtMillis: transactedAtMillis,
      lines: lines,
      grandTotal: grandTotal,
      isDeleted: isDeleted,
      createdAtMillis: createdAtMillis,
      updatedAtMillis: updatedAtMillis,
    );
  }

  @override
  void write(BinaryWriter writer, TransactionModel obj) {
    writer.writeString(obj.id);
    writer.writeInt(obj.transactedAtMillis);
    writer.writeList(obj.lines);
    writer.writeDouble(obj.grandTotal);
    writer.writeBool(obj.isDeleted);
    writer.writeInt(obj.createdAtMillis);
    writer.writeInt(obj.updatedAtMillis);
  }
}
