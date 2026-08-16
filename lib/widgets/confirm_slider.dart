import 'package:flutter/material.dart';
import 'package:onam_pass/utils/constants.dart';

/// A custom swipe-to-confirm slider.
///
/// The user drags the thumb from left to right.
/// When the thumb reaches [threshold] (0.0–1.0 fraction of track width),
/// [onConfirmed] is called.
class ConfirmSlider extends StatefulWidget {
  final VoidCallback onConfirmed;
  final bool isLoading;
  final bool enabled;
  final String label;

  const ConfirmSlider({
    super.key,
    required this.onConfirmed,
    this.isLoading = false,
    this.enabled = true,
    this.label = 'Slide to Confirm',
  });

  @override
  State<ConfirmSlider> createState() => _ConfirmSliderState();
}

class _ConfirmSliderState extends State<ConfirmSlider>
    with SingleTickerProviderStateMixin {
  static const double _thumbSize = 60.0;
  static const double _trackHeight = 64.0;
  static const double _confirmThreshold = 0.85;

  double _dragFraction = 0.0; // 0.0 → 1.0
  bool _confirmed = false;

  late final AnimationController _snapBack;
  late final Animation<double> _snapAnimation;

  @override
  void initState() {
    super.initState();
    _snapBack = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _snapAnimation = CurvedAnimation(
      parent: _snapBack,
      curve: Curves.elasticOut,
    );
    _snapBack.addListener(() {
      setState(() {
        _dragFraction = _snapAnimation.value * 0; // snap to 0
      });
    });
  }

  @override
  void dispose() {
    _snapBack.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details, double trackWidth) {
    if (!widget.enabled || widget.isLoading || _confirmed) return;
    final maxX = trackWidth - _thumbSize;
    final newFraction = (_dragFraction + details.delta.dx / maxX).clamp(0.0, 1.0);
    setState(() => _dragFraction = newFraction);

    if (_dragFraction >= _confirmThreshold) {
      setState(() {
        _dragFraction = 1.0;
        _confirmed = true;
      });
      widget.onConfirmed();
    }
  }

  void _onDragEnd(DragEndDetails _) {
    if (_confirmed) return;
    // Spring back
    setState(() => _dragFraction = 0.0);
  }

  @override
  void didUpdateWidget(ConfirmSlider old) {
    super.didUpdateWidget(old);
    // If loading ended without confirmation (e.g. error), reset slider
    if (!widget.isLoading && old.isLoading && !_confirmed) {
      setState(() => _dragFraction = 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth = constraints.maxWidth;
        final thumbOffset = _dragFraction * (trackWidth - _thumbSize);

        return GestureDetector(
          onHorizontalDragUpdate: (d) => _onDragUpdate(d, trackWidth),
          onHorizontalDragEnd: _onDragEnd,
          child: Container(
            height: _trackHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_trackHeight / 2),
              color: OnamColors.green.withOpacity(0.12),
              border: Border.all(
                color: OnamColors.green.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            clipBehavior: Clip.hardEdge,
            child: Stack(
              children: [
                // Filled track (progress indicator)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 50),
                  width: thumbOffset + _thumbSize,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        OnamColors.green.withOpacity(0.25),
                        OnamColors.greenLight.withOpacity(0.15),
                      ],
                    ),
                  ),
                ),

                // Label (fades as slider progresses)
                Center(
                  child: Opacity(
                    opacity: (1 - _dragFraction * 1.5).clamp(0.0, 1.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chevron_right,
                          color: OnamColors.green.withOpacity(0.5),
                          size: 20,
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: OnamColors.green.withOpacity(0.7),
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.label,
                          style: TextStyle(
                            color: OnamColors.green,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Draggable thumb
                Positioned(
                  left: thumbOffset,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: _thumbSize,
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [OnamColors.gold, OnamColors.goldDark],
                      ),
                      borderRadius: BorderRadius.circular((_trackHeight - 8) / 2),
                      boxShadow: [
                        BoxShadow(
                          color: OnamColors.gold.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: widget.isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
