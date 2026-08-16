import 'package:flutter/material.dart';
import 'package:onam_pass/models/student.dart';
import 'package:onam_pass/services/supabase_service.dart';
import 'package:onam_pass/services/qr_service.dart';
import 'package:onam_pass/screens/pass_screen.dart';
import 'package:onam_pass/utils/constants.dart';

/// Form screen for entering student details and generating a pass.
class GeneratePassScreen extends StatefulWidget {
  const GeneratePassScreen({super.key});

  @override
  State<GeneratePassScreen> createState() => _GeneratePassScreenState();
}

class _GeneratePassScreenState extends State<GeneratePassScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _classCtrl = TextEditingController();
  final _rollCtrl = TextEditingController();
  final _deptCtrl = TextEditingController();

  bool _isGenerating = false;
  String? _errorMsg;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _classCtrl.dispose();
    _rollCtrl.dispose();
    _deptCtrl.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isGenerating = true;
      _errorMsg = null;
    });

    try {
      final passId = QrService.generatePassId();

      final student = Student(
        id: '', // assigned by Supabase
        passId: passId,
        name: _nameCtrl.text.trim(),
        className: _classCtrl.text.trim(),
        rollNumber: _rollCtrl.text.trim().isEmpty ? null : _rollCtrl.text.trim(),
        department: _deptCtrl.text.trim().isEmpty ? null : _deptCtrl.text.trim(),
        status: PassStatus.pending,
        createdAt: DateTime.now(),
      );

      final saved = await SupabaseService.generatePass(student);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => PassScreen(student: saved)),
      );
    } catch (e) {
      setState(() {
        _errorMsg = 'Failed to generate pass. Please check your connection and try again.';
      });
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Generate Pass',
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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [OnamColors.green, OnamColors.greenLight],
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: const [
                      Text('🎓', style: TextStyle(fontSize: 28)),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Student Details',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Fill in the details to generate an entry pass',
                              style:
                                  TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Error banner
                if (_errorMsg != null) ...[
                  _ErrorBanner(message: _errorMsg!),
                  const SizedBox(height: 16),
                ],

                // Name (required)
                _FormField(
                  controller: _nameCtrl,
                  label: 'Student Name',
                  hint: 'e.g. Adhithyan S',
                  icon: Icons.person_rounded,
                  required: true,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Student name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Class (required)
                _FormField(
                  controller: _classCtrl,
                  label: 'Class',
                  hint: 'e.g. S6 CSE',
                  icon: Icons.class_rounded,
                  required: true,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Class is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Roll Number (optional)
                _FormField(
                  controller: _rollCtrl,
                  label: 'Roll Number',
                  hint: 'e.g. 24 (optional)',
                  icon: Icons.tag_rounded,
                  required: false,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                // Department (optional)
                _FormField(
                  controller: _deptCtrl,
                  label: 'Department',
                  hint: 'e.g. Computer Science (optional)',
                  icon: Icons.business_rounded,
                  required: false,
                ),

                const SizedBox(height: 36),

                // Generate button
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton.icon(
                    onPressed: _isGenerating ? null : _generate,
                    icon: _isGenerating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.qr_code_rounded),
                    label: Text(
                      _isGenerating ? 'Generating pass...' : 'Generate Pass',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: OnamColors.green,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: OnamColors.green.withOpacity(0.6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Styled form field with label and icon.
class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool required;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const _FormField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.required = false,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: OnamColors.textMedium,
            ),
            children: required
                ? const [
                    TextSpan(
                      text: ' *',
                      style: TextStyle(color: OnamColors.error),
                    )
                  ]
                : [],
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(
            fontSize: 15,
            color: OnamColors.textDark,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: OnamColors.textLight.withOpacity(0.7),
              fontSize: 14,
            ),
            prefixIcon: Icon(icon, color: OnamColors.green, size: 20),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: OnamColors.green, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: OnamColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: OnamColors.error, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: OnamColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: OnamColors.error.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: OnamColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style:
                  const TextStyle(color: OnamColors.error, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
