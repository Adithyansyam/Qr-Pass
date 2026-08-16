import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:onam_pass/models/student.dart';
import 'package:onam_pass/screens/generate_pass_screen.dart';
import 'package:onam_pass/widgets/qr_display.dart';
import 'package:onam_pass/utils/constants.dart';

/// Displays a generated student pass with QR code.
/// Allows saving and sharing the pass as an image.
class PassScreen extends StatefulWidget {
  final Student student;

  const PassScreen({super.key, required this.student});

  @override
  State<PassScreen> createState() => _PassScreenState();
}

class _PassScreenState extends State<PassScreen>
    with SingleTickerProviderStateMixin {
  final _repaintKey = GlobalKey();
  bool _isSaving = false;

  late final AnimationController _animCtrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _scaleAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  /// Capture the pass card as a PNG image.
  Future<File?> _capturePassImage() async {
    try {
      final boundary = _repaintKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/onam_pass_${widget.student.passId}.png');
      await file.writeAsBytes(pngBytes);
      return file;
    } catch (e) {
      return null;
    }
  }

  Future<void> _savePass() async {
    setState(() => _isSaving = true);
    final file = await _capturePassImage();
    setState(() => _isSaving = false);

    if (!mounted) return;
    if (file != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pass saved to ${file.path}'),
          backgroundColor: OnamColors.green,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save pass image.'),
          backgroundColor: OnamColors.error,
        ),
      );
    }
  }

  Future<void> _sharePass() async {
    setState(() => _isSaving = true);
    final file = await _capturePassImage();
    setState(() => _isSaving = false);

    if (file != null) {
      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            'Onam Pass — ${widget.student.name} | ${widget.student.passId}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.student;

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
          'Onam Pass',
          style: TextStyle(
            color: OnamColors.textDark,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: OnamColors.gold,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            children: [
              // ── Pass Card (capturable) ──
              ScaleTransition(
                scale: _scaleAnim,
                child: RepaintBoundary(
                  key: _repaintKey,
                  child: _PassCard(student: s),
                ),
              ),

              const SizedBox(height: 28),

              // ── Action Buttons ──
              Row(
                children: [
                  Expanded(
                    child: _OutlineBtn(
                      icon: Icons.download_rounded,
                      label: 'Save',
                      onTap: _isSaving ? null : _savePass,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _OutlineBtn(
                      icon: Icons.share_rounded,
                      label: 'Share',
                      onTap: _isSaving ? null : _sharePass,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add_rounded),
                  label: const Text(
                    'Generate Another Pass',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: OnamColors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const GeneratePassScreen()),
                    );
                  },
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

/// The printable/shareable pass card layout.
class _PassCard extends StatelessWidget {
  final Student student;
  const _PassCard({required this.student});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: OnamColors.gold.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          // Green header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [OnamColors.greenDark, OnamColors.green],
              ),
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                const Text('🌸', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ONAM PASS',
                        style: TextStyle(
                          color: OnamColors.gold,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                        ),
                      ),
                      Text(
                        'College Onam Event 2025',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: OnamColors.gold,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'PENDING',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                _PassField(
                  label: 'STUDENT NAME',
                  value: student.name,
                  large: true,
                ),
                const Divider(height: 24, color: Color(0xFFF0F0F0)),

                Row(
                  children: [
                    Expanded(
                      child: _PassField(
                        label: 'CLASS',
                        value: student.className,
                      ),
                    ),
                    if (student.rollNumber != null &&
                        student.rollNumber!.isNotEmpty)
                      Expanded(
                        child: _PassField(
                          label: 'ROLL NO.',
                          value: student.rollNumber!,
                        ),
                      ),
                  ],
                ),

                if (student.department != null &&
                    student.department!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _PassField(
                    label: 'DEPARTMENT',
                    value: student.department!,
                  ),
                ],

                const Divider(height: 24, color: Color(0xFFF0F0F0)),

                // Pass ID
                _PassField(
                  label: 'PASS ID',
                  value: student.passId,
                  monospace: true,
                  valueColor: OnamColors.green,
                ),

                const SizedBox(height: 20),

                // QR Code
                Center(
                  child: QrDisplay(
                    data: student.passId,
                    size: 180,
                  ),
                ),

                const SizedBox(height: 16),

                // Footer
                Center(
                  child: Text(
                    'Scan QR to verify entry',
                    style: TextStyle(
                      fontSize: 11,
                      color: OnamColors.textLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PassField extends StatelessWidget {
  final String label;
  final String value;
  final bool large;
  final bool monospace;
  final Color? valueColor;

  const _PassField({
    required this.label,
    required this.value,
    this.large = false,
    this.monospace = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: OnamColors.textLight,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: large ? 22 : 15,
            fontWeight: large ? FontWeight.w800 : FontWeight.w600,
            color: valueColor ?? OnamColors.textDark,
            fontFamily: monospace ? 'monospace' : null,
            letterSpacing: monospace ? 1.5 : null,
          ),
        ),
      ],
    );
  }
}

class _OutlineBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _OutlineBtn({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: OnamColors.green,
        side: const BorderSide(color: OnamColors.green),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}
