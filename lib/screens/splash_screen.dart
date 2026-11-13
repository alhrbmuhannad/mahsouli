import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/common.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.peach,
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.6, end: 1),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutBack,
          builder: (context, v, child) => Opacity(
            opacity: ((v - 0.6) / 0.4).clamp(0, 1),
            child: Transform.scale(scale: v, child: child),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BrandLogo(size: 96),
              SizedBox(height: 16),
              Text(
                'محصولي',
                style: TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: AppColors.brown),
              ),
              Text(
                'MAHSOULI',
                style: TextStyle(fontSize: 14, letterSpacing: 4, fontWeight: FontWeight.w700, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
