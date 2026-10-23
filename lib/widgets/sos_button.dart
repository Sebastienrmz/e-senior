import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../services/app_preferences.dart';

class SOSButton extends StatefulWidget {
  final VoidCallback onActivated;
  const SOSButton({super.key, required this.onActivated});
  @override
  State<SOSButton> createState() => _SOSButtonState();
}

class _SOSButtonState extends State<SOSButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _pressing = false;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..addStatusListener((s) {
            if (s == AnimationStatus.completed) {
              if (AppPreferences.vibration) HapticFeedback.heavyImpact();
              _reset();
              widget.onActivated();
            }
          });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _start() {
    if (AppPreferences.vibration) HapticFeedback.mediumImpact();
    setState(() => _pressing = true);
    _ctrl.forward(from: 0);
  }

  void _reset() {
    _ctrl.reset();
    if (mounted) setState(() => _pressing = false);
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onLongPressDown: (_) => _start(),
    onLongPress: () {},
    onLongPressEnd: (_) => _reset(),
    onLongPressCancel: _reset,
    child: AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) => Container(
        width: double.infinity,
        height: 88,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          color: _pressing ? AppTheme.sosRedDark : AppTheme.sosRed,
        ),
        child: Stack(
          children: [
            if (_pressing)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: _ctrl.value,
                      heightFactor: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusLg,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.emergency, color: Colors.white, size: 36),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      _pressing ? 'MAINTENEZ...' : 'SOS URGENCE',
                      style: const TextStyle(
                        fontSize: AppTheme.fs22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
