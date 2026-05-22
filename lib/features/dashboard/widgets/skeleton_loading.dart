// lib/features/dashboard/widgets/skeleton_loading.dart

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class SkeletonLoading extends StatefulWidget {
  const SkeletonLoading({super.key});

  @override
  State<SkeletonLoading> createState() => _SkeletonLoadingState();
}

class _SkeletonLoadingState extends State<SkeletonLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _shimmerBox(width: 150, height: 28),
                    const SizedBox(height: 8),
                    _shimmerBox(width: 210, height: 14),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    _shimmerBox(width: 130, height: 34, radius: 999),
                    const SizedBox(width: 10),
                    _shimmerBox(width: 120, height: 34, radius: 999),
                    const SizedBox(width: 10),
                    _shimmerBox(width: 92, height: 34, radius: 999),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _shimmerCard(height: 138, margin: 16),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Expanded(child: _shimmerCard(height: 110, margin: 4)),
                    Expanded(child: _shimmerCard(height: 110, margin: 4)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Expanded(child: _shimmerCard(height: 110, margin: 4)),
                    Expanded(child: _shimmerCard(height: 110, margin: 4)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Expanded(child: _shimmerCard(height: 110, margin: 4)),
                    Expanded(child: _shimmerCard(height: 110, margin: 4)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _shimmerCard(height: 178, margin: 16),
              const SizedBox(height: 8),
              _shimmerCard(height: 320, margin: 16),
              const SizedBox(height: 8),
              _shimmerCard(height: 320, margin: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _shimmerBox({
    required double width,
    required double height,
    double radius = 8,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          stops: [
            (_animation.value - 0.3).clamp(0.0, 1.0),
            _animation.value.clamp(0.0, 1.0),
            (_animation.value + 0.3).clamp(0.0, 1.0),
          ],
          colors: const [
            AppColors.surface,
            AppColors.quaternaria,
            AppColors.surface,
          ],
        ),
      ),
    );
  }

  Widget _shimmerCard({required double height, double margin = 16}) {
    return Container(
      width: double.infinity,
      height: height,
      margin: EdgeInsets.symmetric(horizontal: margin),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.divider),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          stops: [
            (_animation.value - 0.3).clamp(0.0, 1.0),
            _animation.value.clamp(0.0, 1.0),
            (_animation.value + 0.3).clamp(0.0, 1.0),
          ],
          colors: const [
            AppColors.surface,
            AppColors.quaternaria,
            AppColors.surface,
          ],
        ),
      ),
    );
  }
}