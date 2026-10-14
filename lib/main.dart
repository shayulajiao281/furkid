import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/app_state.dart';
import 'router/app_router.dart';
import 'services/notification_service.dart';
import 'theme/app_colors.dart';

Future<void> main() async {
  // ① Flutter 引擎初始化（异步 main 必须加）
  WidgetsFlutterBinding.ensureInitialized();

  // ② 初始化通知服务（会请求权限、初始化时区）
  await NotificationService.init();

  // ③ 预加载 SharedPreferences（持久化需要）
  final prefs = await SharedPreferences.getInstance();

  // ④ 启动 App，注入 prefs
  runApp(
    ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp.router(
      title: 'FurKid',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      theme: const CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: AppColors.primary,
      ),
    );
  }
}
