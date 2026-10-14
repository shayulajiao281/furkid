import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';

class MainShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;
  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminders = ref.watch(appStateProvider).reminders;
    final badge = reminders
        .where((r) => !r.done && daysUntil(r.date) <= 7)
        .length;

    final bottom = MediaQuery.of(context).padding.bottom;

    return CupertinoPageScaffold(
      child: Column(
        children: [
          Expanded(child: navigationShell),
          // ============ Tabbar 76px + 安全区 ============
          ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                height: 76 + bottom,
                padding: EdgeInsets.only(top: 10, bottom: bottom),
                decoration: const BoxDecoration(
                  color: Color(0xF0FFFFFF), // rgba(255,255,255,.94)
                  border: Border(
                    top: BorderSide(
                      color: Color(0x12141928), // rgba(20,25,40,.07)
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    _tab(context, 0, '🐾', '宠物', false),
                    _tab(context, 1, '🔔', '提醒', false, badge: badge),
                    _tab(context, 2, '⚖️', '体重', false),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tab(
    BuildContext context,
    int index,
    String emoji,
    String label,
    bool _, {
    int badge = 0,
  }) {
    final active = navigationShell.currentIndex == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          //添加触动效果
          HapticFeedback.selectionClick();
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                // 图标 22px + 未选中灰度 + opacity .42
                Opacity(
                  opacity: active ? 1 : 0.42,
                  child: ColorFiltered(
                    colorFilter: active
                        ? const ColorFilter.mode(
                            Color(0x00000000),
                            BlendMode.dst,
                          )
                        : const ColorFilter.matrix([
                            0.2126,
                            0.7152,
                            0.0722,
                            0,
                            0,
                            0.2126,
                            0.7152,
                            0.0722,
                            0,
                            0,
                            0.2126,
                            0.7152,
                            0.0722,
                            0,
                            0,
                            0,
                            0,
                            0,
                            1,
                            0,
                          ]),
                    child: Transform.translate(
                      offset: Offset(0, active ? -1 : 0),
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 22, height: 1),
                      ),
                    ),
                  ),
                ),
                // 徽标
                if (badge > 0)
                  Positioned(
                    top: -2,
                    left: 12,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 16),
                      height: 16,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: AppColors.red,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: CupertinoColors.white,
                          width: 2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        badge > 99 ? '99+' : '$badge',
                        style: const TextStyle(
                          fontSize: 10,
                          color: CupertinoColors.white,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                color: active ? AppColors.primary : AppColors.muted,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
