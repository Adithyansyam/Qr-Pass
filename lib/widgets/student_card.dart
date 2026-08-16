import 'package:flutter/material.dart';
import 'package:onam_pass/models/student.dart';
import 'package:onam_pass/utils/constants.dart';

/// Displays a student's pass information in a styled card.
class StudentCard extends StatelessWidget {
  final Student student;
  final bool compact;

  const StudentCard({
    super.key,
    required this.student,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: OnamColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: OnamColors.gold.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header strip
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [OnamColors.green, OnamColors.greenLight],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Text(
                  '🌸 ONAM PASS',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    letterSpacing: 2,
                  ),
                ),
                const Spacer(),
                _StatusChip(status: student.status),
              ],
            ),
          ),

          // Body
          Padding(
            padding: EdgeInsets.all(compact ? 16 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(
                  icon: Icons.person_rounded,
                  label: 'Name',
                  value: student.name,
                  large: !compact,
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.school_rounded,
                  label: 'Class',
                  value: student.className,
                ),
                if (student.rollNumber != null &&
                    student.rollNumber!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.tag_rounded,
                    label: 'Roll Number',
                    value: student.rollNumber!,
                  ),
                ],
                if (student.department != null &&
                    student.department!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.business_rounded,
                    label: 'Department',
                    value: student.department!,
                  ),
                ],
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.qr_code_rounded,
                  label: 'Pass ID',
                  value: student.passId,
                  monospace: true,
                ),
                if (student.isApproved && student.approvedAt != null) ...[
                  const Divider(height: 24),
                  _InfoRow(
                    icon: Icons.check_circle_rounded,
                    label: 'Approved At',
                    value: _formatTime(student.approvedAt!),
                    valueColor: OnamColors.approved,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour > 12 ? local.hour - 12 : local.hour == 0 ? 12 : local.hour;
    final m = local.minute.toString().padLeft(2, '0');
    final ampm = local.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool large;
  final bool monospace;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.large = false,
    this.monospace = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: OnamColors.gold),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: OnamColors.textLight,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: large ? 20 : 15,
                  fontWeight: large ? FontWeight.w700 : FontWeight.w600,
                  color: valueColor ?? OnamColors.textDark,
                  fontFamily: monospace ? 'monospace' : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final isPending = status == PassStatus.pending;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isPending ? OnamColors.gold : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: isPending ? Colors.white : OnamColors.green,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
