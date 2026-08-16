import 'package:flutter/material.dart';
import 'package:onam_pass/services/auth_service.dart';
import 'package:onam_pass/services/supabase_service.dart';
import 'package:onam_pass/screens/generate_pass_screen.dart';
import 'package:onam_pass/screens/scanner_screen.dart';
import 'package:onam_pass/screens/dashboard_screen.dart';
import 'package:onam_pass/widgets/statistics_card.dart';
import 'package:onam_pass/utils/constants.dart';

/// Main home dashboard screen shown after login.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, int> _stats = {'total': 0, 'pending': 0, 'approved': 0};
  bool _statsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await SupabaseService.getStatistics();
      if (mounted) setState(() {
        _stats = stats;
        _statsLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _statsLoading = false);
    }
  }

  Future<void> _signOut() async {
    await AuthService.signOut();
    // AuthGate stream will handle navigation
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OnamColors.surface,
      body: SafeArea(
        child: RefreshIndicator(
          color: OnamColors.gold,
          onRefresh: _loadStats,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── App Bar Row ──
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome,',
                            style: TextStyle(
                              color: OnamColors.textLight,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            AuthService.currentUserEmail ?? 'Staff',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: OnamColors.textDark,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _signOut,
                      icon: const Icon(Icons.logout_rounded),
                      color: OnamColors.textMedium,
                      tooltip: 'Logout',
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Hero Header ──
                _HeroHeader(),

                const SizedBox(height: 28),

                // ── Statistics ──
                const Text(
                  'LIVE STATISTICS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: OnamColors.textLight,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),

                _statsLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(
                            color: OnamColors.gold,
                          ),
                        ),
                      )
                    : StatisticsRow(
                        total: _stats['total']!,
                        pending: _stats['pending']!,
                        approved: _stats['approved']!,
                      ),

                const SizedBox(height: 32),

                // ── Action Buttons ──
                const Text(
                  'ACTIONS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: OnamColors.textLight,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),

                _ActionButton(
                  icon: Icons.badge_rounded,
                  label: 'Generate Pass',
                  subtitle: 'Create a new student entry pass',
                  gradient: const LinearGradient(
                    colors: [OnamColors.green, OnamColors.greenLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const GeneratePassScreen()),
                  ),
                ),

                const SizedBox(height: 14),

                _ActionButton(
                  icon: Icons.qr_code_scanner_rounded,
                  label: 'Scan Pass',
                  subtitle: 'Scan & verify student entry',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7B4F00), OnamColors.gold],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ScannerScreen()),
                  ),
                ),

                const SizedBox(height: 14),

                _ActionButton(
                  icon: Icons.bar_chart_rounded,
                  label: 'View Dashboard',
                  subtitle: 'Full statistics & student search',
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF1A237E),
                      const Color(0xFF3949AB),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DashboardScreen()),
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

/// Top hero section with Onam branding.
class _HeroHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [OnamColors.greenDark, OnamColors.green],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: OnamColors.green.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🌸', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              const Text(
                'ONAM PASS',
                style: TextStyle(
                  color: OnamColors.gold,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Event Entry Management',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          // Decorative dots row (pookalam-inspired)
          Row(
            children: List.generate(
              8,
              (i) => Container(
                margin: const EdgeInsets.only(right: 6),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i % 2 == 0
                      ? OnamColors.gold.withOpacity(0.9)
                      : Colors.white.withOpacity(0.4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Large action button card.
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Gradient gradient;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white70,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
