import 'package:flutter/material.dart';
import 'package:onam_pass/models/student.dart';
import 'package:onam_pass/services/supabase_service.dart';
import 'package:onam_pass/services/auth_service.dart';
import 'package:onam_pass/widgets/confirm_slider.dart';
import 'package:onam_pass/widgets/student_card.dart';
import 'package:onam_pass/utils/constants.dart';

/// Shown after scanning a QR code.
/// Handles three states: PENDING (swipe to approve), APPROVED (already used),
/// and INVALID (not found in database).
class ApprovalScreen extends StatefulWidget {
  final String passId;
  final Student? student; // null = invalid pass

  const ApprovalScreen({
    super.key,
    required this.passId,
    required this.student,
  });

  @override
  State<ApprovalScreen> createState() => _ApprovalScreenState();
}

class _ApprovalScreenState extends State<ApprovalScreen>
    with SingleTickerProviderStateMixin {
  bool _isApproving = false;
  bool _approvalDone = false;
  Student? _student;

  late final AnimationController _successAnim;

  @override
  void initState() {
    super.initState();
    _student = widget.student;
    _successAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _successAnim.dispose();
    super.dispose();
  }

  Future<void> _approve() async {
    if (_isApproving) return;

    final staffId = AuthService.currentUserId;
    if (staffId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Authentication required. Please log in again.'),
          backgroundColor: OnamColors.error,
        ),
      );
      return;
    }

    setState(() => _isApproving = true);

    try {
      final result = await SupabaseService.approvePass(
        passId: widget.passId,
        staffUserId: staffId,
      );

      if (!mounted) return;

      switch (result) {
        case ApprovalResult.success:
          // Re-fetch updated student data
          final updated = await SupabaseService.fetchPass(widget.passId);
          setState(() {
            _student = updated ?? _student;
            _approvalDone = true;
          });
          _successAnim.forward();
          break;

        case ApprovalResult.alreadyApproved:
          final updated = await SupabaseService.fetchPass(widget.passId);
          setState(() => _student = updated ?? _student);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This pass was already approved by another scanner.'),
              backgroundColor: OnamColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
          break;

        case ApprovalResult.notFound:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pass not found. It may have been deleted.'),
              backgroundColor: OnamColors.error,
            ),
          );
          break;

        case ApprovalResult.error:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Approval failed. Please check your connection.'),
              backgroundColor: OnamColors.error,
            ),
          );
          break;
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: OnamColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isApproving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // INVALID PASS
    if (_student == null) {
      return _InvalidPassView(passId: widget.passId);
    }

    // SUCCESS screen
    if (_approvalDone) {
      return _SuccessView(student: _student!);
    }

    // ALREADY APPROVED
    if (_student!.isApproved) {
      return _AlreadyApprovedView(student: _student!);
    }

    // PENDING — show student info + swipe control
    return Scaffold(
      backgroundColor: OnamColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          color: OnamColors.textDark,
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Verify Pass',
          style: TextStyle(
            color: OnamColors.textDark,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            children: [
              // Pending banner
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: OnamColors.gold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: OnamColors.gold.withOpacity(0.4),
                  ),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.hourglass_top_rounded,
                        color: OnamColors.gold, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Pass is PENDING — swipe to approve entry',
                        style: TextStyle(
                          color: OnamColors.gold,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Student info card
              StudentCard(student: _student!),

              const SizedBox(height: 28),

              // Swipe slider label
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'CONFIRM ENTRY',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: OnamColors.textLight,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Swipe-to-confirm
              ConfirmSlider(
                onConfirmed: _approve,
                isLoading: _isApproving,
                enabled: !_isApproving,
                label: _isApproving ? 'Confirming...' : 'Slide to Confirm',
              ),

              if (_isApproving) ...[
                const SizedBox(height: 12),
                const Text(
                  'Confirming entry... please wait',
                  style: TextStyle(
                    color: OnamColors.textLight,
                    fontSize: 12,
                  ),
                ),
              ],

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// ─── INVALID PASS ─────────────────────────────────────────────────────────

class _InvalidPassView extends StatelessWidget {
  final String passId;
  const _InvalidPassView({required this.passId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A0000),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // X icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: OnamColors.error.withOpacity(0.15),
                  border:
                      Border.all(color: OnamColors.error.withOpacity(0.5), width: 2),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: OnamColors.error,
                  size: 52,
                ),
              ),
              const SizedBox(height: 28),

              const Text(
                '✕  INVALID PASS',
                style: TextStyle(
                  color: OnamColors.error,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 14),

              const Text(
                'This QR code is not registered\nfor the Onam event.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  passId,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontFamily: 'monospace',
                    fontSize: 13,
                    letterSpacing: 2,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: const Text(
                    'Scan Again',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: OnamColors.error,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ─── ALREADY APPROVED ─────────────────────────────────────────────────────

class _AlreadyApprovedView extends StatelessWidget {
  final Student student;
  const _AlreadyApprovedView({required this.student});

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour > 12
        ? local.hour - 12
        : local.hour == 0
            ? 12
            : local.hour;
    final m = local.minute.toString().padLeft(2, '0');
    final ampm = local.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A0F00),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          color: Colors.white70,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: Column(
            children: [
              // Warning icon
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.amber.withOpacity(0.15),
                  border: Border.all(
                      color: Colors.amber.withOpacity(0.5), width: 2),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.amber,
                  size: 46,
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                '⚠  PASS ALREADY APPROVED',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'This pass has already been used.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 28),

              // Student info
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.amber.withOpacity(0.3), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ApprRow(label: 'Name', value: student.name),
                    const Divider(
                        color: Colors.white12, height: 20),
                    _ApprRow(label: 'Class', value: student.className),
                    if (student.rollNumber != null &&
                        student.rollNumber!.isNotEmpty) ...[
                      const Divider(color: Colors.white12, height: 20),
                      _ApprRow(
                          label: 'Roll No.',
                          value: student.rollNumber!),
                    ],
                    const Divider(color: Colors.white12, height: 20),
                    _ApprRow(
                      label: 'Status',
                      value: 'APPROVED',
                      valueColor: Colors.greenAccent,
                    ),
                    if (student.approvedAt != null) ...[
                      const Divider(color: Colors.white12, height: 20),
                      _ApprRow(
                        label: 'Approved At',
                        value: _formatTime(student.approvedAt!),
                        valueColor: Colors.amber,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: const Text(
                    'Scan Another',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _ApprRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _ApprRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

/// ─── SUCCESS ──────────────────────────────────────────────────────────────

class _SuccessView extends StatefulWidget {
  final Student student;
  const _SuccessView({required this.student});

  @override
  State<_SuccessView> createState() => _SuccessViewState();
}

class _SuccessViewState extends State<_SuccessView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OnamColors.greenDark,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _scale,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.15),
                      border:
                          Border.all(color: Colors.white.withOpacity(0.4), width: 2),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 58,
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                const Text(
                  '✓  PASS APPROVED',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  widget.student.name,
                  style: const TextStyle(
                    color: OnamColors.gold,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.student.className,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 12),
                const Text(
                  'Entry confirmed successfully.',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 48),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                    label: const Text(
                      'Scan Next Pass',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: OnamColors.gold,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
