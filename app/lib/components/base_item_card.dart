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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Calculate responsive spacing based on available height
                  final availableHeight = constraints.maxHeight;
                  final iconSize =
                      availableHeight * 0.6; // 45% of available height
                  final spacingSize =
                      availableHeight * 0.08; // 8% of available height
                  final textSize =
                      availableHeight * 0.2; // 20% of available height

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Icon or custom icon
                      SizedBox(
                        height: iconSize,
                        child: Center(
                          child:
                              customIcon ??
                              Icon(
                                _getCategoryIcon(category),
                                size: iconSize,
                                color: Colors.blue,
                              ),
                        ),
                      ),

                      // Responsive spacing
                      SizedBox(height: spacingSize),

                      // Name
                      SizedBox(
                        height: textSize,
                        child: Center(
                          child:
                              name != null
                                  ? Container(
                                    constraints: BoxConstraints(
                                      maxWidth: constraints.maxWidth * 0.9,
                                    ),
                                    child: Text(
                                      name!,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  )
                                  : const SizedBox.shrink(),
                        ),
                      ),
                    ],
                  );
                },
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
                    color: Colors.white.withAlpha(
                      77,
                    ), // 0.3 opacity is roughly 77 in alpha
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
    if (category == null) return Icons.shopping_bag; // Default icon

    switch (category.toLowerCase()) {
      case 'essenciais':
        return Icons.restaurant; // Better icon for essentials like rice, beans
      case 'hortifruti':
        return Icons.eco; // Better icon for fruits and vegetables
      case 'limpeza e higiene':
        return Icons.wash; // Better icon for cleaning and hygiene products
      case 'guloseimas':
        return Icons.cookie; // Better icon for sweets and treats
      case 'bazar':
        return Icons.construction; // Better icon for household items
      case 'bebidas':
        return Icons.liquor; // Better icon for drinks
      default:
        return Icons
            .help_outline; // Subtle question mark for uncategorized items
    }
  }

  Widget _buildShimmerEffect({required Widget child}) {
    return ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (bounds) {
        return LinearGradient(
          colors: [
            Colors.grey.shade300,
            Colors.grey.shade100,
            Colors.grey.shade300,
          ],
          stops: const [0.1, 0.5, 0.9],
          begin: const Alignment(-1.0, -0.5),
          end: const Alignment(1.0, 0.5),
          tileMode: TileMode.clamp,
        ).createShader(bounds);
      },
      child: child,
    );
  }
}
