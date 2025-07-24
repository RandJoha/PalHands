import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AnimatedHandshake extends StatefulWidget {
  final double size;
  final Color? color;
  final Duration animationDuration;

  const AnimatedHandshake({
    super.key,
    this.size = 100.0,
    this.color,
    this.animationDuration = const Duration(milliseconds: 2000),
  });

  @override
  State<AnimatedHandshake> createState() => _AnimatedHandshakeState();
}

class _AnimatedHandshakeState extends State<AnimatedHandshake>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    // Rotation animation - handshake movement
    _rotationAnimation = Tween<double>(
      begin: -0.1,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    // Scale animation - slight size change
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    // Slide animation - subtle movement
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0.05, -0.02),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    // Start the animation
    _startAnimation();
  }

  void _startAnimation() {
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = widget.color ?? AppColors.primary;
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: SlideTransition(
              position: _slideAnimation,
              child: Icon(
                Icons.handshake,
                size: widget.size,
                color: iconColor,
              ),
            ),
          ),
        );
      },
    );
  }
}

// Alternative animated handshake with more complex movement
class ComplexAnimatedHandshake extends StatefulWidget {
  final double size;
  final Color? color;
  final Duration animationDuration;

  const ComplexAnimatedHandshake({
    super.key,
    this.size = 100.0,
    this.color,
    this.animationDuration = const Duration(milliseconds: 3000),
  });

  @override
  State<ComplexAnimatedHandshake> createState() => _ComplexAnimatedHandshakeState();
}

class _ComplexAnimatedHandshakeState extends State<ComplexAnimatedHandshake>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    // More complex rotation
    _rotationAnimation = Tween<double>(
      begin: -0.15,
      end: 0.15,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    // Bounce scale effect
    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.bounceOut,
    ));

    // Circular movement
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0.08, -0.05),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    // Bounce animation
    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.bounceInOut,
    ));

    // Start the animation
    _startAnimation();
  }

  void _startAnimation() {
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = widget.color ?? AppColors.primary;
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: SlideTransition(
              position: _slideAnimation,
              child: Transform.translate(
                offset: Offset(0, -5 * _bounceAnimation.value),
                child: Icon(
                  Icons.handshake,
                  size: widget.size,
                  color: iconColor,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
} 