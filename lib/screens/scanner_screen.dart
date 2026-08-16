import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:onam_pass/screens/approval_screen.dart';
import 'package:onam_pass/services/qr_service.dart';
import 'package:onam_pass/services/supabase_service.dart';
import 'package:onam_pass/utils/constants.dart';

/// Full-screen QR scanner screen.
/// Scans a QR code, extracts the pass ID, fetches the student from Supabase,
/// and navigates to [ApprovalScreen].
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with WidgetsBindingObserver {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _isProcessing = false;
  bool _torchOn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _controller.stop();
    } else if (state == AppLifecycleState.resumed) {
      _controller.start();
    }
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    final scanned = barcode.rawValue!.trim().toUpperCase();

    // Validate format
    if (!QrService.isValidPassIdFormat(scanned)) {
      _showInvalidSnackbar('Invalid QR format');
      return;
    }

    setState(() => _isProcessing = true);
    await _controller.stop();

    try {
      final student = await SupabaseService.fetchPass(scanned);

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ApprovalScreen(
            passId: scanned,
            student: student,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Connection error. Please try again.'),
          backgroundColor: OnamColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
        _controller.start();
      }
    }
  }

  void _showInvalidSnackbar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: OnamColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera feed
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // Overlay
          _ScannerOverlay(isProcessing: _isProcessing),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Back button
                  _CircleBtn(
                    icon: Icons.arrow_back_ios_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  const Text(
                    'Scan Pass',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  // Torch button
                  _CircleBtn(
                    icon: _torchOn
                        ? Icons.flash_on_rounded
                        : Icons.flash_off_rounded,
                    active: _torchOn,
                    onTap: () {
                      _controller.toggleTorch();
                      setState(() => _torchOn = !_torchOn);
                    },
                  ),
                ],
              ),
            ),
          ),

          // Loading overlay
          if (_isProcessing)
            Container(
              color: Colors.black45,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: OnamColors.gold),
                    SizedBox(height: 16),
                    Text(
                      'Loading pass...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The scanning overlay with a finder frame.
class _ScannerOverlay extends StatelessWidget {
  final bool isProcessing;
  const _ScannerOverlay({required this.isProcessing});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const frameSize = 260.0;
    final frameTop = (size.height - frameSize) / 2 - 40;

    return Stack(
      children: [
        // Dark overlay (four rectangles around the frame)
        CustomPaint(
          size: size,
          painter: _OverlayPainter(
            frameTop: frameTop,
            frameSize: frameSize,
          ),
        ),

        // Frame border
        Positioned(
          left: (size.width - frameSize) / 2,
          top: frameTop,
          child: Container(
            width: frameSize,
            height: frameSize,
            decoration: BoxDecoration(
              border: Border.all(
                color: isProcessing ? OnamColors.gold : Colors.white,
                width: 2.5,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),

        // Corner accents
        ..._cornerAccents(size, frameTop, frameSize),

        // Bottom hint
        Positioned(
          left: 0,
          right: 0,
          top: frameTop + frameSize + 28,
          child: Column(
            children: [
              Text(
                isProcessing ? 'Fetching pass...' : 'Point camera at QR code',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'The pass ID will be verified from the database',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _cornerAccents(Size size, double frameTop, double frameSize) {
    const accentSize = 28.0;
    const accentWidth = 3.5;
    final left = (size.width - frameSize) / 2;

    Widget corner(double x, double y, bool flipH, bool flipV) {
      return Positioned(
        left: x,
        top: y,
        child: Transform.scale(
          scaleX: flipH ? -1 : 1,
          scaleY: flipV ? -1 : 1,
          child: Container(
            width: accentSize,
            height: accentSize,
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: OnamColors.gold, width: accentWidth),
                left: BorderSide(color: OnamColors.gold, width: accentWidth),
              ),
              borderRadius:
                  BorderRadius.only(topLeft: Radius.circular(8)),
            ),
          ),
        ),
      );
    }

    return [
      corner(left, frameTop, false, false),
      corner(left + frameSize - accentSize, frameTop, true, false),
      corner(left, frameTop + frameSize - accentSize, false, true),
      corner(
          left + frameSize - accentSize, frameTop + frameSize - accentSize, true, true),
    ];
  }
}

class _OverlayPainter extends CustomPainter {
  final double frameTop;
  final double frameSize;

  _OverlayPainter({required this.frameTop, required this.frameSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black54;
    final frameLeft = (size.width - frameSize) / 2;

    // Top
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, frameTop),
      paint,
    );
    // Bottom
    canvas.drawRect(
      Rect.fromLTWH(0, frameTop + frameSize, size.width,
          size.height - frameTop - frameSize),
      paint,
    );
    // Left
    canvas.drawRect(
      Rect.fromLTWH(0, frameTop, frameLeft, frameSize),
      paint,
    );
    // Right
    canvas.drawRect(
      Rect.fromLTWH(frameLeft + frameSize, frameTop,
          size.width - frameLeft - frameSize, frameSize),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool active;

  const _CircleBtn({
    required this.icon,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: active
              ? OnamColors.gold.withOpacity(0.3)
              : Colors.black38,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}
