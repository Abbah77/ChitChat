import 'package:flutter/material.dart';

class ReactionAnimationWidget extends StatefulWidget {
  final String reaction;
  
  const ReactionAnimationWidget({super.key, required this.reaction});
  
  @override
  State<ReactionAnimationWidget> createState() => _ReactionAnimationWidgetState();
}

class _ReactionAnimationWidgetState extends State<ReactionAnimationWidget> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _opacity;
  late Animation<Offset> _position;
  
  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _scale = Tween<double>(begin: 0.5, end: 1.5).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );
    
    _opacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );
    
    _position = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0, -100),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    _controller.forward().then((_) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.translate(
            offset: _position.value,
            child: Transform.scale(
              scale: _scale.value,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
                child: _getReactionIcon(),
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _getReactionIcon() {
    switch (widget.reaction) {
      case 'heart':
        return const Icon(Icons.favorite, color: Colors.red, size: 32);
      case 'emoji':
        return const Icon(Icons.emoji_emotions, color: Colors.yellow, size: 32);
      default:
        return const Icon(Icons.thumb_up, color: Colors.blue, size: 32);
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}