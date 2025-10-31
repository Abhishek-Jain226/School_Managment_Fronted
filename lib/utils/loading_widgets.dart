// lib/utils/loading_widgets.dart
import 'package:flutter/material.dart';
import 'constants.dart';

/// Custom loading widgets for consistent UI across the app
class LoadingWidgets {
  /// Standard loading indicator
  static Widget standardLoading({String? message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: AppSizes.paddingMD),
            Text(
              message,
              style: const TextStyle(fontSize: AppSizes.textLG),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  /// Small loading indicator for buttons
  static Widget buttonLoading({double? size, Color? color}) {
    final indicatorSize = size ?? AppSizes.loadingIndicatorSize;
    return SizedBox(
      width: indicatorSize,
      height: indicatorSize,
      child: CircularProgressIndicator(
        strokeWidth: AppSizes.loadingIndicatorStrokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? AppColors.loadingIndicatorColor,
        ),
      ),
    );
  }

  /// Loading overlay for pages
  static Widget pageLoadingOverlay({String? message}) {
    return Container(
      color: AppColors.loadingOverlayBackground.withValues(
        alpha: AppColors.loadingOverlayBackgroundAlpha,
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(AppSizes.loadingOverlayPadding),
          decoration: BoxDecoration(
            color: AppColors.loadingContainerBackground,
            borderRadius: BorderRadius.circular(AppSizes.loadingOverlayRadius),
            boxShadow: [
              BoxShadow(
                color: AppColors.loadingShadowColor.withValues(
                  alpha: AppColors.loadingShadowAlpha,
                ),
                blurRadius: AppSizes.loadingOverlayBlurRadius,
                offset: const Offset(0, AppSizes.loadingOverlayOffset),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              if (message != null) ...[
                const SizedBox(height: AppSizes.paddingMD),
                Text(
                  message,
                  style: const TextStyle(fontSize: AppSizes.textLG),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Skeleton loading for list items
  static Widget skeletonListTile() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMD),
      child: Row(
        children: [
          Container(
            width: AppSizes.skeletonAvatarSize,
            height: AppSizes.skeletonAvatarSize,
            decoration: BoxDecoration(
              color: AppColors.skeletonBaseColor[300],
              borderRadius: BorderRadius.circular(AppSizes.skeletonAvatarRadius),
            ),
          ),
          const SizedBox(width: AppSizes.paddingMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: AppSizes.skeletonTitleHeight,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.skeletonBaseColor[300],
                    borderRadius: BorderRadius.circular(AppSizes.radiusSM),
                  ),
                ),
                const SizedBox(height: AppSizes.spaceSM),
                Container(
                  height: AppSizes.skeletonSubtitleHeight,
                  width: AppSizes.skeletonSubtitleWidth,
                  decoration: BoxDecoration(
                    color: AppColors.skeletonBaseColor[300],
                    borderRadius: BorderRadius.circular(AppSizes.radiusXS),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Skeleton loading for cards
  static Widget skeletonCard() {
    return Container(
      margin: const EdgeInsets.all(AppSizes.marginSM),
      padding: const EdgeInsets.all(AppSizes.paddingMD),
      decoration: BoxDecoration(
        color: AppColors.loadingContainerBackground,
        borderRadius: BorderRadius.circular(AppSizes.radiusMD),
        boxShadow: [
          BoxShadow(
            color: AppColors.skeletonBaseColor.withValues(
              alpha: AppColors.loadingShadowAlpha,
            ),
            blurRadius: AppSizes.skeletonCardBlurRadius,
            offset: const Offset(0, AppSizes.skeletonCardOffset),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: AppSizes.skeletonCardTitleHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.skeletonBaseColor[300],
              borderRadius: BorderRadius.circular(AppSizes.radiusSM),
            ),
          ),
          const SizedBox(height: AppSizes.paddingMD),
          Container(
            height: AppSizes.skeletonTitleHeight,
            width: AppSizes.skeletonCardSubtitle1Width,
            decoration: BoxDecoration(
              color: AppColors.skeletonBaseColor[300],
              borderRadius: BorderRadius.circular(AppSizes.radiusSM),
            ),
          ),
          const SizedBox(height: AppSizes.spaceSM),
          Container(
            height: AppSizes.skeletonTitleHeight,
            width: AppSizes.skeletonCardSubtitle2Width,
            decoration: BoxDecoration(
              color: AppColors.skeletonBaseColor[300],
              borderRadius: BorderRadius.circular(AppSizes.radiusSM),
            ),
          ),
        ],
      ),
    );
  }

  /// Shimmer effect for loading states
  static Widget shimmerEffect({Widget? child}) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE0E0E0), // grey[300]
            Color(0xFFF5F5F5), // grey[100]
            Color(0xFFE0E0E0), // grey[300]
          ],
          stops: [
            AppSizes.shimmerGradientStop1,
            AppSizes.shimmerGradientStop2,
            AppSizes.shimmerGradientStop3,
          ],
        ),
      ),
      child: child,
    );
  }
}

/// Loading state mixin for widgets
mixin LoadingStateMixin on State<StatefulWidget> {
  bool _isLoading = false;
  String? _loadingMessage;

  bool get isLoading => _isLoading;
  String? get loadingMessage => _loadingMessage;

  void setLoading(bool loading, {String? message}) {
    setState(() {
      _isLoading = loading;
      _loadingMessage = message;
    });
  }

  void showLoadingState({String? message}) {
    setLoading(true, message: message);
  }

  void hideLoadingState() {
    setLoading(false);
  }

  /// Execute async operation with loading state
  Future<R> executeWithLoading<R>(
    Future<R> Function() operation, {
    String? loadingMessage,
    bool showLoading = true,
  }) async {
    if (showLoading) {
      showLoadingState(message: loadingMessage);
    }
    
    try {
      final result = await operation();
      return result;
    } finally {
      if (showLoading) {
        hideLoadingState();
      }
    }
  }
}

/// Loading button widget
class LoadingButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;

  const LoadingButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.padding,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  State<LoadingButton> createState() => _LoadingButtonState();
}

class _LoadingButtonState extends State<LoadingButton> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height ?? AppSizes.buttonHeightLG,
      child: ElevatedButton(
        onPressed: widget.isLoading ? null : widget.onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.backgroundColor,
          foregroundColor: widget.textColor,
          padding: widget.padding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusSM),
          ),
        ),
        child: widget.isLoading
            ? LoadingWidgets.buttonLoading()
            : Text(widget.text),
      ),
    );
  }
}

/// Loading overlay widget
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;

  const LoadingOverlay({
    Key? key,
    required this.isLoading,
    required this.child,
    this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          LoadingWidgets.pageLoadingOverlay(message: message),
      ],
    );
  }
}

/// Loading list widget
class LoadingList extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final Widget Function(BuildContext context, int index)? separatorBuilder;

  const LoadingList({
    Key? key,
    this.itemCount = 5,
    required this.itemBuilder,
    this.separatorBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      separatorBuilder: separatorBuilder ?? 
        (context, index) => const SizedBox(height: AppSizes.spaceSM),
    );
  }
}

/// Loading grid widget
class LoadingGrid extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;

  const LoadingGrid({
    super.key,
    this.itemCount = 6,
    required this.itemBuilder,
    this.crossAxisCount = 2,
    this.crossAxisSpacing = AppSizes.spaceSM,
    this.mainAxisSpacing = AppSizes.spaceSM,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
      ),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}
