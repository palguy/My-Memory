import 'package:hive/hive.dart';
part 'memory_item.g.dart';

@HiveType(typeId: 0)
class MemoryItem extends HiveObject {
  @HiveField(0)
  String category;

  @HiveField(1)
  String question;

  @HiveField(2)
  String answer;

  @HiveField(3)
  String? imagePath;

  MemoryItem({
    required this.category,
    required this.question,
    required this.answer,
    this.imagePath,
  });
}