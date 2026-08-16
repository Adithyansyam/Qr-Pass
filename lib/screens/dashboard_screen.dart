import 'package:flutter/material.dart';
import 'package:onam_pass/models/student.dart';
import 'package:onam_pass/services/supabase_service.dart';
import 'package:onam_pass/services/auth_service.dart';
import 'package:onam_pass/utils/constants.dart';
import 'package:intl/intl.dart';

/// Admin dashboard: live stats + student search.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _searchCtrl = TextEditingController();

  Map<String, int> _stats = {'total': 0, 'pending': 0, 'approved': 0};
  List<Student> _searchResults = [];
  bool _statsLoading = true;
  bool _searchLoading = false;
  String? _searchError;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    setState(() => _statsLoading = true);
    try {
      final s = await SupabaseService.getStatistics();
      if (mounted) setState(() => _stats = s);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _statsLoading = false);
    }
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() {
      _searchLoading = true;
      _searchError = null;
    });

    try {
      final results = await SupabaseService.searchStudents(query);
      if (mounted) setState(() => _searchResults = results);
    } catch (e) {
      if (mounted) setState(() => _searchError = 'Search failed. Please try again.');
    } finally {
      if (mounted) setState(() => _searchLoading = false);
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
          'Dashboard',
          style: TextStyle(
            color: OnamColors.textDark,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: OnamColors.green),
            onPressed: _loadStats,
            tooltip: 'Refresh stats',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Stats Section ──
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [OnamColors.greenDark, OnamColors.green],
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '🌸 ONAM EVENT',
                          style: TextStyle(
                            color: OnamColors.gold,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Logged in as: ${AuthService.currentUserEmail ?? "Staff"}',
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 12),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Stats row
                  if (_statsLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child:
                            CircularProgressIndicator(color: OnamColors.gold),
                      ),
                    )
                  else
                    Row(
                      children: [
                        _StatBox(
                          label: 'Total',
                          value: _stats['total']!,
                          color: OnamColors.green,
                          icon: Icons.people_rounded,
                        ),
                        const SizedBox(width: 10),
                        _StatBox(
                          label: 'Pending',
                          value: _stats['pending']!,
                          color: OnamColors.gold,
                          icon: Icons.hourglass_top_rounded,
                        ),
                        const SizedBox(width: 10),
                        _StatBox(
                          label: 'Approved',
                          value: _stats['approved']!,
                          color: OnamColors.greenLight,
                          icon: Icons.check_circle_rounded,
                        ),
                      ],
                    ),

                  const SizedBox(height: 20),

                  // Search bar
                  const Text(
                    'SEARCH STUDENTS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: OnamColors.textLight,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),

                  TextField(
                    controller: _searchCtrl,
                    onChanged: _search,
                    style: const TextStyle(fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Name, class, pass ID, or roll number...',
                      hintStyle:
                          TextStyle(color: OnamColors.textLight.withOpacity(0.7)),
                      prefixIcon:
                          const Icon(Icons.search_rounded, color: OnamColors.green),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded,
                                  color: OnamColors.textLight),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _searchResults = []);
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
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
                        borderSide: const BorderSide(
                            color: OnamColors.green, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Search Results ──
            Expanded(
              child: _buildResultsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList() {
    if (_searchLoading) {
      return const Center(
        child: CircularProgressIndicator(color: OnamColors.gold),
      );
    }

    if (_searchError != null) {
      return Center(
        child: Text(
          _searchError!,
          style: const TextStyle(color: OnamColors.error),
        ),
      );
    }

    if (_searchCtrl.text.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_rounded, size: 48, color: OnamColors.textLight),
            SizedBox(height: 12),
            Text(
              'Search for a student above',
              style: TextStyle(color: OnamColors.textLight, fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return const Center(
        child: Text(
          'No students found.',
          style: TextStyle(color: OnamColors.textLight),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: _searchResults.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _StudentListTile(student: _searchResults[i]),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;

  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: color,
                height: 1,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: OnamColors.textMedium,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentListTile extends StatelessWidget {
  final Student student;
  const _StudentListTile({required this.student});

  String _formatDate(DateTime dt) {
    return DateFormat('dd MMM, h:mm a').format(dt.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final isApproved = student.isApproved;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isApproved
              ? OnamColors.greenLight.withOpacity(0.3)
              : OnamColors.gold.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  student.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: OnamColors.textDark,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isApproved
                      ? OnamColors.greenLight.withOpacity(0.1)
                      : OnamColors.gold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  student.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isApproved ? OnamColors.greenLight : OnamColors.gold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${student.className}${student.rollNumber != null ? ' • Roll ${student.rollNumber}' : ''}',
            style: const TextStyle(
              color: OnamColors.textMedium,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            student.passId,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: OnamColors.green,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Created: ${_formatDate(student.createdAt)}',
            style: const TextStyle(
              fontSize: 11,
              color: OnamColors.textLight,
            ),
          ),
          if (isApproved && student.approvedAt != null)
            Text(
              'Approved: ${_formatDate(student.approvedAt!)}',
              style: const TextStyle(
                fontSize: 11,
                color: OnamColors.greenLight,
              ),
            ),
        ],
      ),
    );
  }
}
