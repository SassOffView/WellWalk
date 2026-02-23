import 'package:equatable/equatable.dart';

class RoutineItem extends Equatable {
  const RoutineItem({
    required this.id,
    required this.title,
    required this.createdAt,
    this.isCompleted = false,
    this.order = 0,
  });

  final String id;
  final String title;
  final DateTime createdAt;
  final bool isCompleted;
  final int order;

  RoutineItem copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    bool? isCompleted,
    int? order,
  }) {
    return RoutineItem(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      isCompleted: isCompleted ?? this.isCompleted,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'createdAt': createdAt.toIso8601String(),
    'isCompleted': isCompleted,
    'order': order,
  };

  factory RoutineItem.fromJson(Map<String, dynamic> json) => RoutineItem(
    id: json['id'] as String,
    title: json['title'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    isCompleted: json['isCompleted'] as bool? ?? false,
    order: json['order'] as int? ?? 0,
  );

  @override
  List<Object?> get props => [id, title, createdAt, isCompleted, order];
}
