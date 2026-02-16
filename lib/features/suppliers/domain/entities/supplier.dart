import 'package:equatable/equatable.dart';

class Supplier extends Equatable {
  const Supplier({
    required this.id,
    required this.name,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  Supplier copyWith({
    String? id,
    String? name,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Supplier(
        id: id ?? this.id,
        name: name ?? this.name,
        isDeleted: isDeleted ?? this.isDeleted,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  List<Object?> get props => [id, name, isDeleted, createdAt, updatedAt];
}
