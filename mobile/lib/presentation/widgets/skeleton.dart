import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Bloco cinza base para montar skeletons.
class SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  const SkeletonBox({
    super.key,
    this.width = double.infinity,
    this.height = 12,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Envolve conteudo com o efeito shimmer usando cores do tema.
class Skeleton extends StatelessWidget {
  final Widget child;
  const Skeleton({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.white12 : Colors.grey.shade300,
      highlightColor: isDark ? Colors.white24 : Colors.grey.shade100,
      period: const Duration(milliseconds: 1300),
      child: child,
    );
  }
}

/// Lista de cards em estado de carregamento (placeholder premium).
class ListSkeleton extends StatelessWidget {
  final int items;
  const ListSkeleton({super.key, this.items = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: items,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Skeleton(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              SkeletonBox(width: 46, height: 46, radius: 12),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 130, height: 13),
                    SizedBox(height: 9),
                    SkeletonBox(width: double.infinity, height: 10),
                    SizedBox(height: 8),
                    SkeletonBox(width: 90, height: 10),
                  ],
                ),
              ),
              SizedBox(width: 12),
              SkeletonBox(width: 60, height: 22, radius: 11),
            ],
          ),
        ),
      ),
    );
  }
}
