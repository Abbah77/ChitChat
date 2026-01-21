import 'package:flutter/material.dart';

class TypingIndicator extends StatefulWidget {
  final Color color;
  final double dotSize;
  
  const TypingIndicator({
    super.key,
    this.color = Colors.blueAccent,
    this.dotSize = 4.0,
  });
  
  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _dotAnimations;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat();
    
    _dotAnimations = List.generate(3, (index) {
      return TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), 
            weight: 0.33, curve: Curves.easeInOut),
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), 
            weight: 0.33, curve: Curves.easeInOut),
        TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.0), 
            weight: 0.34),
      ]).animate(CurvedAnimation(
        parent: _controller,
        curve: Interval(index * 0.2, 1.0, curve: Curves.easeInOut),
      ));
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _dotAnimations[index],
            builder: (context, child) {
              return Opacity(
                opacity: _dotAnimations[index].value,
                child: Container(
                  width: widget.dotSize,
                  height: widget.dotSize,
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}