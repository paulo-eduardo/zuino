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
  final bool fixedSize;

  // New parameters for position-based corner rounding
  final bool roundTopLeft;
  final bool roundTopRight;
  final bool roundBottomLeft;
  final bool roundBottomRight;

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
    this.fixedSize = false,
    this.roundTopLeft = true,
    this.roundTopRight = true,
    this.roundBottomLeft = true,
    this.roundBottomRight = true,
  });

  @override
  Widget build(BuildContext context) {
    // Create a custom border radius based on which corners should be rounded
    final borderRadius = BorderRadius.only(
      topLeft: roundTopLeft ? const Radius.circular(8) : Radius.zero,
      topRight: roundTopRight ? const Radius.circular(8) : Radius.zero,
      bottomLeft: roundBottomLeft ? const Radius.circular(8) : Radius.zero,
      bottomRight: roundBottomRight ? const Radius.circular(8) : Radius.zero,
    );

    final cardContent = Card(
      color: customCardColor ?? Theme.of(context).cardColor,
      elevation: 2,
      margin: const EdgeInsets.all(4),
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Stack(
          children: [
            // Card content
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icon or custom icon
                  if (customIcon != null)
                    customIcon!
                  else
                    Icon(
                      _getCategoryIcon(category),
                      size: 48,
                      color: Colors.blue,
                    ),

                  const SizedBox(height: 8),

                  // Name
                  if (name != null)
                    Text(
                      name!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),

            // Edit mode indicator
            if (isEditMode)
              Positioned(
                right: 8,
                top: 8,
                child: Icon(Icons.edit, color: Colors.blue.shade700, size: 20),
              ),

            // Custom overlay (like quantity indicator)
            if (overlay != null) overlay!,

            // Loading shimmer effect
            if (isLoading)
              _buildShimmerEffect(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: borderRadius,
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    // If fixed size is required, wrap in a SizedBox
    return fixedSize
        ? SizedBox(width: 120, height: 120, child: cardContent)
        : cardContent;
  }

  IconData _getCategoryIcon(String? category) {
    // Your existing icon logic
    return Icons.shopping_bag; // Default icon
  }

  Widget _buildShimmerEffect({required Widget child}) {
    // Your existing shimmer effect
    return child;
  }
}
