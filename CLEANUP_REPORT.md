# Cleanup Report

Date: 2025-09-28

We removed unused screens and components that are not reachable from `lib/main.dart` -> `MainTabView` navigation by stubbing them out (keeping symbols but no logic), plus an unused import.

Legacy screens stubbed (unused):
- `lib/view/login/sign_in_view.dart`
- `lib/view/login/sign_up_view.dart`
- `lib/view/login/social_login.dart`
- `lib/view/login/welcome_view.dart`
- `lib/view/card/cards_view.dart`
- `lib/view/add_subscription/add_subscription_view.dart`
- `lib/view/subscription_info/subscription_info_view.dart`

Kept (actively referenced):
- `home/`, `spending_budgets/`, `breakdown/`, `calender/`, `wallets/`, `settings/`.
- Common widgets used across active views.

Additional edits:
- Removed unused import of `subscription_cell.dart` from `calender_view.dart`.

Next steps:
- Physically delete the above files if you prefer slimmer repo size; analyzer now safe due to stubs.
- Remove lingering assets no longer used (e.g., `assets/img/welcome_screen.png`) and reflect changes in `pubspec.yaml`.
- Address easy lints: replace deprecated `.withOpacity()` with `.withValues(opacity: ...)`; either add `vector_math` in `pubspec.yaml` or remove its import in painters.
