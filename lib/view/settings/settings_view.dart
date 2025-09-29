import 'package:flutter/material.dart';
import 'package:trackizer/view/settings/edit_profile_view.dart';

import '../../common/color_extension.dart';
import '../../common_widget/icon_item_row.dart';
import 'package:trackizer/storage/sync_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trackizer/common/supabase_config.dart';
import 'package:trackizer/storage/storage_service.dart';
import 'package:trackizer/common/supabase_checks.dart';
import 'package:trackizer/common/net_diagnostics.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  bool isActive = false;
  String userName = "Code For Any";
  String userEmail = "codeforany@gmail.com";
  String avatarPath = "assets/img/u1.png";
  String selectedCurrency = "₹ INR";
  bool isDarkTheme = true;
  int _pending = 0;
  String? _cloudHint;

  @override
  void initState() {
    super.initState();
    _refreshPending();
  }

  Future<void> _refreshPending() async {
    final c = await SyncService().pendingCount();
    if (mounted) setState(() => _pending = c);
  }

  @override
  Widget build(BuildContext context) {
  final bool supaEnabled = SupabaseConfig.isConfigured;
    final bool isLoggedIn = supaEnabled &&
        (Supabase.instance.client.auth.currentUser != null);
    return Scaffold(
      backgroundColor: TColor.gray,
      body: SingleChildScrollView(
        child: SafeArea(
          child: Column(children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: Image.asset("assets/img/back.png",
                            width: 25, height: 25, color: TColor.gray30))
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Settings",
                      style: TextStyle(color: TColor.gray30, fontSize: 16),
                    )
                  ],
                ),
              ],
            ),
            const SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  avatarPath,
                  width: 70,
                  height: 70,
                )
              ],
            ),
            const SizedBox(
              height: 8,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  userName,
                  style: TextStyle(
                      color: TColor.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700),
                )
              ],
            ),
            const SizedBox(
              height: 4,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  userEmail,
                  style: TextStyle(
                      color: TColor.gray30,
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                )
              ],
            ),
            const SizedBox(
              height: 15,
            ),
            InkWell(
              borderRadius: BorderRadius.circular(15),
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProfileView(
                      name: userName,
                      email: userEmail,
                      avatarPath: avatarPath,
                    ),
                  ),
                );
                if (result != null && result is Map) {
                  setState(() {
                    userName = result['name'] ?? userName;
                    userEmail = result['email'] ?? userEmail;
                    avatarPath = result['avatarPath'] ?? avatarPath;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: TColor.border.withValues(alpha: 0.15),
                  ),
                  color: TColor.gray60.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  "Edit profile",
                  style: TextStyle(
                      color: TColor.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 15, bottom: 8),
                    child: Text(
                      "General",
                      style: TextStyle(
                          color: TColor.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: TColor.border.withValues(alpha: 0.1),
                      ),
                      color: TColor.gray60.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        IconItemRow(
                          title: "Security",
                          icon: "assets/img/face_id.png",
                          value: "FaceID",
                        ),
                        IconItemSwitchRow(
                          title: "iCloud Sync",
                          icon: "assets/img/icloud.png",
                          value: isActive,
                          didChange: (newVal) {
                            setState(() {
                              isActive = newVal;
                            });
                          },
                        ),
                        // Manual local reset
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(children: [
                                const Icon(Icons.delete_forever, color: Colors.white70),
                                const SizedBox(width: 8),
                                Text("Reset local data", style: TextStyle(color: TColor.white, fontWeight: FontWeight.w600)),
                              ]),
                              TextButton(
                                onPressed: () async {
                                  await StorageService.clearAllLocal(includeQueue: true);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Local data cleared')),
                                    );
                                  }
                                },
                                child: const Text('Clear'),
                              )
                            ],
                          ),
                        ),
                        if (supaEnabled)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(children: [
                                  const Icon(Icons.sync, color: Colors.white70),
                                  const SizedBox(width: 8),
                                  Text("Sync now", style: TextStyle(color: TColor.white, fontWeight: FontWeight.w600)),
                                ]),
                                TextButton(
                                  onPressed: () async { await SyncService().syncNow(); },
                                  child: const Text('Run'),
                                )
                              ],
                            ),
                          ),
                        if (supaEnabled)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(children: [
                                  const Icon(Icons.verified, color: Colors.white70),
                                  const SizedBox(width: 8),
                                  Text("Check cloud setup", style: TextStyle(color: TColor.white, fontWeight: FontWeight.w600)),
                                ]),
                                TextButton(
                                  onPressed: () async {
                                    final res = await checkSupabaseSetup();
                                    if (!mounted) return;
                                    final ok = res.values.every((v) => v == 'ok');
                                    String msg;
                                    if (ok) {
                                      msg = 'All tables accessible';
                                      _cloudHint = null;
                                    } else {
                                      msg = res.entries.map((e) => '${e.key}: ${e.value}').join(' | ');
                                      if (msg.contains('Could not find the table')) {
                                        _cloudHint = 'Run supabase/bootstrap.sql in your Supabase SQL editor to create tables & policies';
                                      }
                                    }
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(msg), duration: const Duration(seconds: 4)),
                                    );
                                  },
                                  child: const Text('Verify'),
                                )
                              ],
                            ),
                          ),
                        if (supaEnabled)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(children: [
                                  const Icon(Icons.network_check, color: Colors.white70),
                                  const SizedBox(width: 8),
                                  Text("Network diagnostics", style: TextStyle(color: TColor.white, fontWeight: FontWeight.w600)),
                                ]),
                                TextButton(
                                  onPressed: () async {
                                    final r = await diagnoseSupabaseConnectivity();
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(r.toString()), duration: const Duration(seconds: 6)),
                                    );
                                  },
                                  child: const Text('Run'),
                                )
                              ],
                            ),
                          ),
                        if (supaEnabled)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(children: [
                                  const Icon(Icons.pending_actions, color: Colors.white70),
                                  const SizedBox(width: 8),
                                  Text("Queued changes", style: TextStyle(color: TColor.white, fontWeight: FontWeight.w600)),
                                ]),
                                TextButton(
                                  onPressed: () async { await _refreshPending(); },
                                  child: Text('$_pending'),
                                )
                              ],
                            ),
                          ),
                        if (_cloudHint != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: Text(_cloudHint!, style: TextStyle(color: Colors.amber.shade200, fontSize: 12)),
                          ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.only(top: 20, bottom: 8),
                    child: Text(
                      "My subscription",
                      style: TextStyle(
                          color: TColor.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: TColor.border.withValues(alpha: 0.1),
                      ),
                      color: TColor.gray60.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        IconItemRow(
                          title: "Sorting",
                          icon: "assets/img/sorting.png",
                          value: "Date",
                        ),

                        IconItemRow(
                          title: "Summary",
                          icon: "assets/img/chart.png",
                          value: "Average",
                        ),

                        IconItemRow(
                          title: "Default currency",
                          icon: "assets/img/money.png",
                          value: "USD (\$)",
                        ),
                        
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.only(top: 20, bottom: 8),
                    child: Text(
                      "Appearance",
                      style: TextStyle(
                          color: TColor.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: TColor.border.withValues(alpha: 0.1),
                      ),
                      color: TColor.gray60.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        IconItemRow(
                          title: "App icon",
                          icon: "assets/img/app_icon.png",
                          value: "Default",
                        ),
                        IconItemRow(
                          title: "Theme",
                          icon: "assets/img/light_theme.png",
                          value: "Dark",
                        ),
                        IconItemRow(
                          title: "Font",
                          icon: "assets/img/font.png",
                          value: "Inter",
                        ),
                        if (isLoggedIn)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(children: [
                                  const Icon(Icons.logout, color: Colors.white70),
                                  const SizedBox(width: 8),
                                  Text("Logout", style: TextStyle(color: TColor.white, fontWeight: FontWeight.w600)),
                                ]),
                                TextButton(
                                  onPressed: () async {
                                    // Always attempt to sync before signing out to avoid data loss
                                    await SyncService().syncNow();
                                    final pendingAfter = await SyncService().pendingCount();
                                    if (!mounted) return;
                                    if (pendingAfter > 0) {
                                      // Abort sign out if still pending (likely offline or server error)
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Can\'t sign out yet'),
                                          content: Text('You still have $pendingAfter change(s) waiting to sync. Please connect to the internet and try again.'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(ctx).pop(),
                                              child: const Text('OK'),
                                            ),
                                          ],
                                        ),
                                      );
                                      await _refreshPending();
                                      return;
                                    }
                                    // Clear local data for a clean slate across users only after successful sync
                                    await StorageService.clearAllLocal(includeQueue: true);
                                    await Supabase.instance.client.auth.signOut();
                                    if (mounted) Navigator.pop(context);
                                  },
                                  child: const Text('Sign out'),
                                )
                              ],
                            ),
                          ),
                        if (!supaEnabled)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    "Cloud sync disabled. Run app with SUPABASE_URL and SUPABASE_ANON_KEY to enable login and sync.",
                                    style: TextStyle(color: TColor.gray30, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.only(top: 20, bottom: 8),
                    child: Text(
                      "Preferences",
                      style: TextStyle(
                          color: TColor.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: TColor.border.withValues(alpha: 0.1),
                      ),
                      color: TColor.gray60.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.currency_rupee, color: TColor.primary20),
                                SizedBox(width: 8),
                                Text("Currency", style: TextStyle(color: TColor.white, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            DropdownButton<String>(
                              value: selectedCurrency,
                              dropdownColor: TColor.gray80,
                              style: TextStyle(color: Colors.white),
                              items: [
                                DropdownMenuItem(value: "₹ INR", child: Text("₹ INR")),
                                DropdownMenuItem(value: "\$ USD", child: Text("\$ USD")),
                                DropdownMenuItem(value: "€ EUR", child: Text("€ EUR")),
                                DropdownMenuItem(value: "£ GBP", child: Text("£ GBP")),
                                DropdownMenuItem(value: "¥ JPY", child: Text("¥ JPY")),
                              ],
                              onChanged: (val) {
                                setState(() {
                                  selectedCurrency = val ?? selectedCurrency;
                                });
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.dark_mode, color: TColor.primary20),
                                SizedBox(width: 8),
                                Text("Dark Theme", style: TextStyle(color: TColor.white, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            Switch(
                              value: isDarkTheme,
                              activeColor: TColor.primary20,
                              onChanged: (val) {
                                setState(() {
                                  isDarkTheme = val;
                                  // TODO: Apply theme change globally
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          ]),
        ),
      ),
    );
  }
}
