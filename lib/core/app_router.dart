import "package:ciyue/ui/pages/writing_check/writing_check.dart";
import "package:ciyue/ui/core/word_display.dart";
import "package:ciyue/ui/pages/main/main.dart";
import "package:ciyue/ui/pages/settings/about.dart";
import "package:ciyue/ui/pages/settings/ai_settings.dart";
import "package:ciyue/ui/pages/settings/appearance.dart";
import "package:ciyue/ui/pages/settings/audio.dart";
import "package:ciyue/ui/pages/settings/auto_export.dart";
import "package:ciyue/ui/pages/settings/backup.dart";
import "package:ciyue/ui/pages/settings/history.dart";
import "package:ciyue/ui/pages/settings/manage_dictionaries/main.dart";
import "package:ciyue/ui/pages/settings/manage_dictionaries/properties.dart";
import "package:ciyue/ui/pages/settings/manage_dictionaries/settings_dictionary.dart";
import "package:ciyue/ui/pages/settings/other.dart";
import "package:ciyue/ui/pages/settings/privacy_policy.dart";
import "package:ciyue/ui/pages/settings/terms_of_service.dart";
import "package:ciyue/ui/pages/settings/update.dart";
import "package:ciyue/ui/core/ai_explanation_edit_page.dart";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:ciyue/viewModels/ai_explanation.dart";
import "package:ciyue/ui/pages/settings/storage_management.dart";
import "package:ciyue/viewModels/storage_management.dart";
import "package:provider/provider.dart";

final navigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: navigatorKey,
  routes: [
    GoRoute(
      path: "/",
      builder: (context, state) {
        return const Home();
      },
    ),
    GoRoute(
      path: "/word",
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, String>;
        return slideTransitionPageBuilder(
          key: state.pageKey,
          child: WordDisplay(word: extra["word"]!),
        );
      },
    ),
    GoRoute(
      path: "/edit_ai_explanation",
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return slideTransitionPageBuilder(
          key: state.pageKey,
          child: AIExplanationEditPage(
            word: extra["word"]! as String,
            initialExplanation: extra["initialExplanation"]! as String,
            aiExplanationModel:
                extra["aiExplanationModel"] as AIExplanationModel,
          ),
        );
      },
    ),
    GoRoute(
        path: "/description/:dictId",
        builder: (context, state) => WebviewDisplayDescription(
              dictId: int.parse(state.pathParameters["dictId"]!),
            )),
    GoRoute(
      path: "/settings/autoExport",
      pageBuilder: (context, state) => slideTransitionPageBuilder(
        key: state.pageKey,
        child: const AutoExportSettingsPage(),
      ),
    ),
    GoRoute(
      path: "/settings/dictionaries",
      pageBuilder: (context, state) => slideTransitionPageBuilder(
        key: state.pageKey,
        child: const ManageDictionariesPage(),
      ),
    ),
    GoRoute(
      path: "/settings/ai_settings",
      pageBuilder: (context, state) => slideTransitionPageBuilder(
        key: state.pageKey,
        child: const AiSettingsPage(),
      ),
    ),
    GoRoute(
      path: "/settings/terms_of_service",
      pageBuilder: (context, state) => slideTransitionPageBuilder(
        key: state.pageKey,
        child: const TermsOfServicePage(),
      ),
    ),
    GoRoute(
      path: "/settings/privacy_policy",
      pageBuilder: (context, state) => slideTransitionPageBuilder(
        key: state.pageKey,
        child: const PrivacyPolicyPage(),
      ),
    ),
    GoRoute(
      path: "/settings/audio",
      pageBuilder: (context, state) => slideTransitionPageBuilder(
        key: state.pageKey,
        child: const AudioSettingsPage(),
      ),
    ),
    GoRoute(
      path: "/settings/appearance",
      pageBuilder: (context, state) => slideTransitionPageBuilder(
        key: state.pageKey,
        child: const AppearanceSettingsPage(),
      ),
    ),
    GoRoute(
      path: "/settings/backup",
      pageBuilder: (context, state) => slideTransitionPageBuilder(
        key: state.pageKey,
        child: const BackupSettingsPage(),
      ),
    ),
    GoRoute(
      path: "/settings/update",
      pageBuilder: (context, state) => slideTransitionPageBuilder(
        key: state.pageKey,
        child: const UpdateSettingsPage(),
      ),
    ),
    GoRoute(
      path: "/settings/other",
      pageBuilder: (context, state) => slideTransitionPageBuilder(
        key: state.pageKey,
        child: const OtherSettingsPage(),
      ),
    ),
    GoRoute(
      path: "/settings/about",
      pageBuilder: (context, state) => slideTransitionPageBuilder(
        key: state.pageKey,
        child: const AboutSettingsPage(),
      ),
    ),
    GoRoute(
      path: "/settings/history",
      pageBuilder: (context, state) => slideTransitionPageBuilder(
        key: state.pageKey,
        child: const HistorySettingsPage(),
      ),
    ),
    GoRoute(
      path: "/settings/dictionary/:dictId",
      pageBuilder: (context, state) => slideTransitionPageBuilder(
        key: state.pageKey,
        child: SettingsDictionaryPage(
          dictId: int.parse(state.pathParameters["dictId"]!),
        ),
      ),
    ),
    GoRoute(
      path: "/settings/storage_management",
      pageBuilder: (context, state) => slideTransitionPageBuilder(
        key: state.pageKey,
        child: ChangeNotifierProvider(
          create: (context) => StorageManagementViewModel(),
          child: const StorageManagementPage(),
        ),
      ),
    ),
    GoRoute(
        path: "/properties",
        builder: (context, state) => PropertiesDictionaryPage(
              path: (state.extra as Map<String, dynamic>)["path"],
              id: (state.extra as Map<String, dynamic>)["id"],
            )),
    GoRoute(
      path: "/writing_check",
      pageBuilder: (context, state) => slideTransitionPageBuilder(
        key: state.pageKey,
        child: const WritingCheckPage(),
      ),
    ),
  ],
);

CustomTransitionPage<void> slideTransitionPageBuilder({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      );
    },
  );
}
