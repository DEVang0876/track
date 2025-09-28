import 'package:flutter/material.dart';
import 'package:trackizer/view/settings/edit_profile_view.dart';

import '../../common/color_extension.dart';
import '../../common_widget/icon_item_row.dart';
import 'package:trackizer/storage/sync_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  @override
  Widget build(BuildContext context) {
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
                                onPressed: () async { await Supabase.instance.client.auth.signOut(); if (mounted) Navigator.pop(context); },
                                child: const Text('Sign out'),
                              )
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
