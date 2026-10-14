import 'package:flutter/cupertino.dart';

OverlayEntry? _currentToast;

/// 显示一个 Toast（自动 1.7 秒后消失）
void showToast(BuildContext context, String message) {
  if (message.isEmpty) return;

  // 先移除已有的 toast，避免叠加
  _currentToast?.remove();
  _currentToast = null;

  final overlay = Overlay.of(context);
  final entry = OverlayEntry(builder: (_) => _ToastWidget(message: message));
  _currentToast = entry;
  overlay.insert(entry);

  Future.delayed(const Duration(milliseconds: 1700), () {
    if (_currentToast == entry) {
      entry.remove();
      _currentToast = null;
    }
  });
}

class _ToastWidget extends StatefulWidget {
  final String message;
  const _ToastWidget({required this.message});

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _opacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _offset = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 110 + bottomInset,
      child: IgnorePointer(
        child: FadeTransition(
          opacity: _opacity,
          child: SlideTransition(
            position: _offset,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 11,
                ),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.86,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xED1E2231),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  widget.message,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: CupertinoColors.white,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
