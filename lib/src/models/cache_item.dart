import 'package:hive/hive.dart';

part 'cache_item.g.dart';

@HiveType(typeId: 1)
class CacheItem extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String key;

  @HiveField(2)
  late String value;

  @HiveField(3)
  late DateTime timestamp;

  CacheItem({
    required this.id,
    required this.key,
    required this.value,
    required this.timestamp,
  });

  CacheItem.create({
    required this.key,
    required this.value,
  }) {
    id = DateTime.now().millisecondsSinceEpoch.toString();
    timestamp = DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'key': key,
      'value': value,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory CacheItem.fromJson(Map<String, dynamic> json) {
    return CacheItem(
      id: json['id'],
      key: json['key'],
      value: json['value'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}