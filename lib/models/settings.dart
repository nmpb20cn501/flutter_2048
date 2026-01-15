import 'package:hive/hive.dart';

@HiveType(typeId: 1)
class Settings extends HiveObject {
  @HiveField(0)
  final bool isDarkMode;

  @HiveField(1)
  final bool isSoundEnabled;

  @HiveField(2)
  final int gridSize; // 3, 4, 5, 6

  Settings({
    this.isDarkMode = false,
    this.isSoundEnabled = true,
    this.gridSize = 4,
  });

  Settings copyWith({
    bool? isDarkMode,
    bool? isSoundEnabled,
    int? gridSize,
  }) {
    return Settings(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      isSoundEnabled: isSoundEnabled ?? this.isSoundEnabled,
      gridSize: gridSize ?? this.gridSize,
    );
  }
}
