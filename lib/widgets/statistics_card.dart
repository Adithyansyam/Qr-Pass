import 'package:flutter/material.dart';
import 'package:onam_pass/utils/constants.dart';

/// Displays a stat (label + number) in a styled card.
class StatisticsCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;

  const StatisticsCard({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: color,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: OnamColors.textMedium,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// A row of three stats: Total / Pending / Approved.
class StatisticsRow extends StatelessWidget {
  final int total;
  final int pending;
  final int approved;

  const StatisticsRow({
    super.key,
    required this.total,
    required this.pending,
    required this.approved,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: StatisticsCard(
            label: 'Total',
            value: total,
            color: OnamColors.green,
            icon: Icons.people_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StatisticsCard(
            label: 'Pending',
            value: pending,
            color: OnamColors.gold,
            icon: Icons.hourglass_top_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StatisticsCard(
            label: 'Approved',
            value: approved,
            color: OnamColors.greenLight,
            icon: Icons.check_circle_rounded,
          ),
        ),
      ],
    );
  }
}
