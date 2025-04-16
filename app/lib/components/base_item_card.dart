import 'package:flutter/material.dart';

class BaseItemCard extends StatelessWidget {
  final String? name;
  final String? category;
  final bool isEditMode;
  final bool isLoading;
  final Widget? customIcon;
  final Widget? overlay;
  final Color? customCardColor;
  final VoidCallback? onTap;

  const BaseItemCard({
    super.key,
    this.name,
    this.category,
    this.isEditMode = false,
    this.isLoading = false,
    this.customIcon,
    this.overlay,
    this.customCardColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Get the theme colors
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Define colors based on theme and edit mode
    final cardColor =
        customCardColor ??
        (isDarkMode
            ? (isEditMode ? Colors.grey[800] : Colors.grey[850])
            : (isEditMode ? Colors.blue[50] : Colors.white));

    final iconColor = isDarkMode ? Colors.blue[300] : Colors.blue[700];
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final placeholderColor = isDarkMode ? Colors.grey[700] : Colors.grey[300];

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Card(
            elevation: 2.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
              side:
                  isEditMode
                      ? BorderSide(color: Colors.blue[400]!, width: 1.0)
                      : BorderSide.none,
            ),
            color: cardColor,
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon
                  Expanded(
                    flex: 3,
                    child:
                        isLoading
                            ? _buildShimmerEffect(
                              child: CircleAvatar(
                                backgroundColor: placeholderColor,
                                radius: 18,
                              ),
                            )
                            : customIcon ??
                                Icon(
                                  _getCategoryIcon(category),
                                  size: 60.0,
                                  color: iconColor,
                                ),
                  ),

                  // Item name
                  Expanded(
                    flex: 1,
                    child:
                        isLoading
                            ? _buildShimmerEffect(
                              child: Container(
                                height: 10,
                                width: 60,
                                decoration: BoxDecoration(
                                  color: placeholderColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            )
                            : Text(
                              name ?? '',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11.0,
                                fontWeight: FontWeight.w500,
                                color: textColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                  ),
                ],
              ),
            ),
          ),
          if (overlay != null) overlay!,
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String? category) {
    if (category == null) return Icons.inventory_2;

    switch (category.toLowerCase()) {
      case 'food':
      case 'groceries':
        return Icons.restaurant;
      case 'drinks':
      case 'beverages':
        return Icons.local_drink;
      case 'electronics':
        return Icons.devices;
      case 'clothing':
        return Icons.checkroom;
      case 'health':
      case 'medicine':
        return Icons.medical_services;
      case 'household':
        return Icons.home;
      case 'personal care':
        return Icons.spa;
      default:
        return Icons.inventory_2;
    }
  }

  Widget _buildShimmerEffect({required Widget child}) {
    return ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (bounds) {
        return LinearGradient(
          colors: [
            Colors.grey.withOpacity(0.5),
            Colors.grey.withOpacity(0.3),
            Colors.grey.withOpacity(0.5),
          ],
          stops: const [0.1, 0.5, 0.9],
          begin: const Alignment(-1.0, -0.3),
          end: const Alignment(1.0, 0.3),
          tileMode: TileMode.clamp,
        ).createShader(bounds);
      },
      child: child,
    );
  }
}
