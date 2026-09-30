import 'package:flutter/material.dart';

class BrandName extends StatelessWidget {
  const BrandName({super.key, this.style});

  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseStyle = style ?? Theme.of(context).textTheme.titleLarge;

    return RichText(
      text: TextSpan(
        style: baseStyle?.copyWith(fontWeight: FontWeight.w800),
        children: [
          TextSpan(
            text: 'Vault',
            style: TextStyle(color: colorScheme.primary),
          ),
          TextSpan(
            text: 'Sync',
            style: TextStyle(color: colorScheme.tertiary),
          ),
        ],
      ),
    );
  }
}
