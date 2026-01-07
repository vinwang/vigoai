import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'utils/app_logger.dart';
import 'providers/chat_provider.dart';
import 'providers/conversation_provider.dart';
import 'providers/video_merge_provider.dart';
import 'models/screenplay_draft.dart';
import 'screens/chat_screen.dart';
import 'screens/screenplay_review_screen.dart';
import 'screens/log_viewer_screen.dart';
import 'screens/settings_screen.dart';
import 'services/api_config_service.dart';

void main() async {
  // 确保 Flutter 绑定初始化（必须在所有插件操作之前）
  WidgetsFlutterBinding.ensureInitialized();
  // DartPluginRegistrant.ensureInitialized();

  // 初始化日志系统
  await AppLogger.initialize();

  // 初始化 API 配置服务
  await ApiConfigService.initialize();

  runApp(const DirectorAIApp());

  // 监听应用生命周期
  WidgetsBinding.instance.addObserver(AppLifecycleObserver(
    onDetached: () async {
      await AppLogger.dispose();
    },
  ));
}

/// 应用生命周期观察者
class AppLifecycleObserver with WidgetsBindingObserver {
  final VoidCallback onDetached;

  AppLifecycleObserver({required this.onDetached});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      onDetached();
    }
  }
}

class DirectorAIApp extends StatelessWidget {
  const DirectorAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => ConversationProvider()),
        ChangeNotifierProvider(create: (_) => VideoMergeProvider()),
      ],
      child: MaterialApp(
        title: 'VigoAI',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          // 科技感主题 - 蓝青色系
          primaryColor: const Color(0xFF0EA5E9), // 科技蓝
          scaffoldBackgroundColor: const Color(0xFFF0F9FF), // 浅蓝灰背景
          brightness: Brightness.light,

          // 科技风格颜色方案
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF0EA5E9), // 科技蓝 (Sky Blue)
            secondary: Color(0xFF06B6D4), // 青色 (Cyan)
            tertiary: Color(0xFF3B82F6), // 深蓝 (Blue)
            surface: Color(0xFFFFFFFF), // 白色卡片
            background: Color(0xFFF0F9FF), // 浅蓝灰背景
            error: Color(0xFFEF4444),
            onPrimary: Colors.white,
            onSurface: Color(0xFF0F172A), // 深色文字
            onBackground: Color(0xFF0F172A),
          ),

          // AppBar - 科技感毛玻璃效果
          appBarTheme: AppBarTheme(
            centerTitle: true,
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: Colors.white.withOpacity(0.85),
            foregroundColor: const Color(0xFF0EA5E9),
            titleTextStyle: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 17,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
            ),
            iconTheme: const IconThemeData(color: Color(0xFF0EA5E9)),
            systemOverlayStyle: const SystemUiOverlayStyle(
              statusBarBrightness: Brightness.light,
              statusBarIconBrightness: Brightness.dark,
            ),
          ),

          // 卡片样式
          cardTheme: CardThemeData(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide.none,
            ),
            color: Colors.white,
            clipBehavior: Clip.antiAlias,
          ),

          // 输入框样式
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFFF3F4F6),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF0EA5E9), width: 2),
            ),
            hintStyle: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 16,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),

          // 按钮样式
          filledButtonTheme: FilledButtonThemeData(
            style: ButtonStyle(
              backgroundColor: const WidgetStatePropertyAll(Color(0xFF0EA5E9)),
              foregroundColor: const WidgetStatePropertyAll(Colors.white),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
              textStyle: const WidgetStatePropertyAll(
                TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ),

          // 文本按钮样式
          textButtonTheme: TextButtonThemeData(
            style: ButtonStyle(
              foregroundColor: const WidgetStatePropertyAll(Color(0xFF0EA5E9)),
              padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              textStyle: const WidgetStatePropertyAll(
                TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // 图标样式
          iconTheme: const IconThemeData(
            color: Color(0xFF0EA5E9),
            size: 24,
          ),

          // FloatingActionButton
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: const Color(0xFF0EA5E9),
            foregroundColor: Colors.white,
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),

          // 分割线样式
          dividerTheme: const DividerThemeData(
            color: Color(0xFFE5E7EB),
            thickness: 1,
          ),

          // 文字样式 - 调整为常规大小
          textTheme: const TextTheme(
            headlineLarge: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
              color: Color(0xFF0F172A),
            ),
            headlineMedium: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
              color: Color(0xFF0F172A),
            ),
            titleLarge: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.4,
              color: Color(0xFF0F172A),
            ),
            titleMedium: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
              color: Color(0xFF0F172A),
            ),
            bodyLarge: TextStyle(
              fontSize: 16,
              letterSpacing: -0.3,
              color: Color(0xFF0F172A),
            ),
            bodyMedium: TextStyle(
              fontSize: 14,
              letterSpacing: -0.2,
              color: Color(0xFF0F172A),
            ),
            bodySmall: TextStyle(
              fontSize: 12,
              letterSpacing: -0.1,
              color: Color(0xFF8E8E93),
            ),
          ),

          // 列表样式
          listTileTheme: const ListTileThemeData(
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            titleTextStyle: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: Color(0xFF0F172A),
            ),
            subtitleTextStyle: TextStyle(
              fontSize: 13,
              color: Color(0xFF8E8E93),
            ),
          ),

          // iOS 对话框
          dialogTheme: const DialogThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(14)),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
          ),

          // 底部表单样式
          bottomSheetTheme: const BottomSheetThemeData(
            backgroundColor: Color(0xFFF3F4F6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
          ),
        ),
        home: const ChatScreen(),
        routes: {
          '/settings': (context) => const SettingsScreen(),
          '/screenplay-review': (context) {
            // 从路由参数获取剧本草稿
            final args = ModalRoute.of(context)?.settings.arguments;
            if (args is ScreenplayReviewScreenArgs) {
              return ScreenplayReviewScreen(
                draft: args.draft,
                onConfirm: args.onConfirm,
                onRegenerate: args.onRegenerate,
                onRegenerateCharacterSheets: args.onRegenerateCharacterSheets,
              );
            }
            // 兼容旧版本，从 Provider 获取
            final provider = context.read<ChatProvider>();
            if (provider.currentDraft != null) {
              return ScreenplayReviewScreen(
                draft: provider.currentDraft!,
                onConfirm: (draft) async {
                  await provider.confirmDraft();
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
                onRegenerate: (feedback) async {
                  return await provider.regenerateDraft(feedback);
                },
                onRegenerateCharacterSheets: () async {
                  await provider.regenerateCharacterSheets();
                },
              );
            }
            return const Scaffold(body: Center(child: Text('没有找到剧本')));
          },
          '/logs': (context) => const LogViewerScreen(),
        },
      ),
    );
  }
}

/// 剧本确认页面的路由参数
class ScreenplayReviewScreenArgs {
  final ScreenplayDraft draft;
  final Function(ScreenplayDraft) onConfirm;
  final Future<ScreenplayDraft> Function(String? feedback)? onRegenerate;
  final Future<void> Function()? onRegenerateCharacterSheets; // 新增

  ScreenplayReviewScreenArgs({
    required this.draft,
    required this.onConfirm,
    this.onRegenerate,
    this.onRegenerateCharacterSheets,
  });
}
