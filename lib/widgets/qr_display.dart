import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:onam_pass/utils/constants.dart';

/// Displays a styled QR code with an Onam-inspired border decoration.
class QrDisplay extends StatelessWidget {
  final String data;
  final double size;

  const QrDisplay({
    super.key,
    required this.data,
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: OnamColors.gold.withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: OnamColors.gold.withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Decorative top row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Icon(
                  Icons.circle,
                  size: 6,
                  color: i == 2
                      ? OnamColors.gold
                      : OnamColors.gold.withOpacity(0.4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // QR code
          QrImageView(
            data: data,
            version: QrVersions.auto,
            size: size,
            backgroundColor: Colors.white,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: Color(0xFF1B6B36),
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: Color(0xFF1A1A1A),
            ),
          ),

          const SizedBox(height: 12),

          // Pass ID label below QR
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: OnamColors.green.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              data,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: OnamColors.green,
                letterSpacing: 2,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Decorative bottom row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Icon(
                  Icons.circle,
                  size: 6,
                  color: i == 2
                      ? OnamColors.gold
                      : OnamColors.gold.withOpacity(0.4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
