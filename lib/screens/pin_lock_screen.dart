import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/glass_container.dart';
import '../services/biometric_service.dart';

class PinLockScreen extends StatefulWidget {
  final Widget child;
  const PinLockScreen({super.key, required this.child});

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  String _input = '';
  bool _unlocked = false;
  final String _correctPin = '1234'; // Default PIN, could be configurable later
  final BiometricService _biometricService = BiometricService();
  bool _isBiometricAvailable = false;
  bool _isBiometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    try {
      final available = await _biometricService.isBiometricAvailable();
      final enabled = await _biometricService.isEnabled();
      setState(() {
        _isBiometricAvailable = available;
        _isBiometricEnabled = enabled;
      });
      if (available && enabled) {
        // Delay slightly for UI to settle
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && !_unlocked) {
            _authenticateBiometrically();
          }
        });
      }
    } catch (e) {
      debugPrint('Biometric check error: $e');
    }
  }

  Future<void> _authenticateBiometrically() async {
    final authenticated = await _biometricService.authenticate();
    if (authenticated) {
      setState(() => _unlocked = true);
    }
  }

  void _onKeyTap(String key) {
    if (_input.length < 4) {
      setState(() => _input += key);
      if (_input.length == 4) {
        if (_input == _correctPin) {
          setState(() => _unlocked = true);
        } else {
          Future.delayed(const Duration(milliseconds: 300), () {
            setState(() => _input = '');
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Incorrect PIN'), backgroundColor: Colors.redAccent),
            );
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_unlocked) return widget.child;

    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(color: const Color(0xFF050B0E)),
          Positioned(top: -100, right: -100, child: _glow(400, Colors.cyanAccent.withValues(alpha: 0.1))),
          Positioned(bottom: -100, left: -100, child: _glow(400, Colors.purpleAccent.withValues(alpha: 0.1))),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_person_rounded, color: Colors.cyanAccent, size: 64)
                    .animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                const SizedBox(height: 20),
                Text('BRIGHTWAY SALES', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                Text('SECURE ACCESS', style: GoogleFonts.outfit(fontSize: 12, color: Colors.white38, letterSpacing: 2)),
                const SizedBox(height: 40),
                
                // PIN Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (i) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 16, height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _input.length > i ? Colors.cyanAccent : Colors.white12,
                      border: Border.all(color: _input.length > i ? Colors.cyanAccent : Colors.white24),
                    ),
                  ).animate(target: _input.length > i ? 1 : 0).scale(duration: 200.ms)),
                ),
                
                const SizedBox(height: 50),
                
                // Numpad
                SizedBox(
                  width: 280,
                  child: GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                    children: [
                      ...['1', '2', '3', '4', '5', '6', '7', '8', '9'].map(_numBtn),
                      (_isBiometricAvailable && _isBiometricEnabled)
                        ? IconButton(
                            onPressed: _authenticateBiometrically,
                            icon: const Icon(Icons.fingerprint_rounded, color: Colors.cyanAccent, size: 40),
                          ).animate().fadeIn().scale()
                        : const SizedBox(),
                      _numBtn('0'),
                      IconButton(
                        onPressed: () => setState(() => _input = _input.isNotEmpty ? _input.substring(0, _input.length - 1) : ''),
                        icon: const Icon(Icons.backspace_rounded, color: Colors.white30),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _numBtn(String text) => GestureDetector(
    onTap: () => _onKeyTap(text),
    child: GlassContainer(
      padding: const EdgeInsets.all(20), borderRadius: 20, opacity: 0.05,
      child: Center(child: Text(text, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white))),
    ),
  );

  Widget _glow(double size, Color color) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    child: RepaintBoundary(child: const SizedBox.expand()),
  );
}
