import 'package:flutter/material.dart';

/// Animated microphone button with glowing, pulsing expanding rings when listening.
/// Designed for high visibility and instant feedback for low-literacy farmers.
class MicButton extends StatefulWidget {
  final VoidCallback? onTap;
  final bool isListening;
  final double radius;
  final IconData? icon;
  final String? tooltip;

  const MicButton({
    super.key,
    required this.onTap,
    this.isListening = false,
    this.radius = 45.0, // Default 90px diameter
    this.icon,
    this.tooltip,
  });

  @override
  State<MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<MicButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _waveAnimation = Tween<double>(begin: 1.0, end: 1.6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutQuad),
    );

    if (widget.isListening) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant MicButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening != oldWidget.isListening) {
      if (widget.isListening) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF2E7D32);
    final pulseColor = widget.isListening ? const Color(0xFFF9A825) : primaryColor;
    final diameter = widget.radius * 2;

    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return SizedBox(
            width: diameter * 1.7,
            height: diameter * 1.7,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer expanding ripple wave when listening
                if (widget.isListening) ...[
                  Transform.scale(
                    scale: _waveAnimation.value,
                    child: Container(
                      width: diameter,
                      height: diameter,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: pulseColor.withOpacity((1.0 - (_controller.value * 0.6)).clamp(0.0, 0.4)),
                        border: Border.all(
                          color: pulseColor.withOpacity(0.5),
                          width: 2.0,
                        ),
                      ),
                    ),
                  ),
                  Transform.scale(
                    scale: _pulseAnimation.value * 1.25,
                    child: Container(
                      width: diameter,
                      height: diameter,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: pulseColor.withOpacity(0.2),
                      ),
                    ),
                  ),
                ],

                // Main Button Container
                Transform.scale(
                  scale: widget.isListening ? _pulseAnimation.value : 1.0,
                  child: Container(
                    width: diameter,
                    height: diameter,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: widget.isListening
                            ? [const Color(0xFFF9A825), const Color(0xFFEF6C00)]
                            : [const Color(0xFF43A047), const Color(0xFF1B5E20)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (widget.isListening
                                  ? const Color(0xFFF9A825)
                                  : primaryColor)
                              .withOpacity(0.45),
                          blurRadius: widget.isListening ? 24 : 12,
                          spreadRadius: widget.isListening ? 6 : 2,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: widget.onTap,
                        customBorder: const CircleBorder(),
                        splashColor: Colors.white.withOpacity(0.3),
                        child: Center(
                          child: Icon(
                            widget.icon ??
                                (widget.isListening
                                    ? Icons.mic_rounded
                                    : Icons.mic_none_rounded),
                            color: Colors.white,
                            size: widget.radius * 0.95,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
