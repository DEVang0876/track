import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trackizer/view/auth/login_view.dart';
import 'package:trackizer/view/main_tab/main_tab_view.dart';
import 'package:trackizer/storage/sync_service.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Stream<AuthState> _authStream;
  Session? _session;
  String? _lastUserId;

  @override
  void initState() {
    super.initState();
    final client = Supabase.instance.client;
    _session = client.auth.currentSession;
    _authStream = client.auth.onAuthStateChange;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _authStream,
      builder: (context, snapshot) {
        // Prefer latest session if event fired otherwise fallback to initial
        final session = snapshot.data?.session ?? _session;
        final currentUserId = session?.user.id;
        // Trigger a sync whenever a user signs in or switches
        if (currentUserId != null && currentUserId != _lastUserId) {
          _lastUserId = currentUserId;
          Future.microtask(() => SyncService().syncNow());
        }
        // Reset tracker when signed out
        if (currentUserId == null) {
          _lastUserId = null;
        }
        if (session == null) {
          return const LoginView();
        }
        return const MainTabView();
      },
    );
  }
}
