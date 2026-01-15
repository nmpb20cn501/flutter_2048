import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../const/colors.dart';
import '../const/colors_dark.dart';
import '../managers/board.dart';
import '../managers/settings.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsManager);
    final isDark = settings.isDarkMode;
    final bgColor = isDark ? backgroundColorDark : backgroundColor;
    final txtColor = isDark ? textColorDark : textColor;
    final tileColor = isDark ? boardColorDark : boardColor;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: tileColor,
        title: Text(
          'Settings',
          style: TextStyle(
            color: txtColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.close, color: txtColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Dark Mode
          _buildSettingCard(
            isDark: isDark,
            child: SwitchListTile(
              title: Text(
                'Dark Mode',
                style: TextStyle(
                  color: txtColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                isDark ? 'Dark theme enabled' : 'Light theme enabled',
                style: TextStyle(color: txtColor.withOpacity(0.7)),
              ),
              value: settings.isDarkMode,
              activeThumbColor: color2048,
              onChanged: (value) {
                ref.read(settingsManager.notifier).toggleDarkMode();
              },
            ),
          ),
          const SizedBox(height: 16),

          // Sound
          _buildSettingCard(
            isDark: isDark,
            child: SwitchListTile(
              title: Text(
                'Sound',
                style: TextStyle(
                  color: txtColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                settings.isSoundEnabled
                    ? 'Sound effects enabled'
                    : 'Sound effects disabled',
                style: TextStyle(color: txtColor.withOpacity(0.7)),
              ),
              value: settings.isSoundEnabled,
              activeThumbColor: color2048,
              onChanged: (value) {
                ref.read(settingsManager.notifier).toggleSound();
              },
            ),
          ),
          const SizedBox(height: 16),

          // Grid Size
          _buildSettingCard(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Grid Size',
                        style: TextStyle(
                          color: txtColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Current: ${settings.gridSize}x${settings.gridSize}',
                        style: TextStyle(color: txtColor.withOpacity(0.7)),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [3, 4, 5, 6].map((size) {
                      final isSelected = settings.gridSize == size;
                      return InkWell(
                        onTap: () {
                          ref.read(settingsManager.notifier).setGridSize(size);
                          // Reset game when grid size changes
                          ref.read(boardManager.notifier).newGame();
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color2048
                                : (isDark
                                    ? emptyTileColorDark
                                    : emptyTileColor),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color:
                                  isSelected ? color2048 : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '${size}x$size',
                              style: TextStyle(
                                color: isSelected ? textColorWhite : txtColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Note
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (isDark ? emptyTileColorDark : emptyTileColor)
                  .withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    color: txtColor.withOpacity(0.7), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Changing grid size will start a new game',
                    style: TextStyle(
                      color: txtColor.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard({required bool isDark, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? emptyTileColorDark : emptyTileColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
