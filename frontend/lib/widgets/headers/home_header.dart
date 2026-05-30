// Autor: Allan Giovanni Matias Paes - 25008211
import 'package:flutter/material.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/pages/home_page.dart';
import 'package:frontend/pages/profile/mfa_setup_page.dart';
import 'package:frontend/pages/profile/profile_page.dart';
import 'package:frontend/services/auth.dart';
import 'package:frontend/pages/market/my_offers_page.dart';
import 'package:frontend/constants/colors.dart';

import '../../states/user_state.dart';

class AppHeader extends StatelessWidget {
  final String title;
  final UserProfile? userData;
  final bool isDark;
  final List<Widget>? actions;

  const AppHeader({
    super.key,
    required this.title,
    this.userData,
    required this.isDark,
    this.actions,
  });

  String _getInitials(String name) {
    List<String> names = name.trim().split(" ");
    String initials = "";
    if (names.isNotEmpty) {
      if (names[0].isNotEmpty) initials += names[0][0];
      if (names.length > 1 && names[names.length - 1].isNotEmpty) {
        initials += names[names.length - 1][0];
      }
    }
    if (initials.isEmpty) return "U";
    return initials.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = userData?.name ?? "Usuário";

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        Row(
          children: [
            if (actions != null) ...actions!,
            IconButton(
              icon: Icon(
                isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                color: theme.colorScheme.onSurface,
              ),
              onPressed: () {
                themeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark;
              },
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              offset: const Offset(0, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              onSelected: (value) async {
                if (value == 'offers') {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const MyOffersView(),
                    ),
                  );
                } else if (value == 'profile') {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => HomePage(
                        userName: userData?.name ?? 'Usuário',
                            initialIndex: 5,
                      ),
                    ),
                  );
                } else if (value == 'security'){
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const MfaSetupPage()
                    ),
                  );
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(
                        Icons.person_2_outlined,
                        color: theme.colorScheme.onSurface,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      const Text('Meu Perfil'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(value: 'security',
                  child: Row(
                    children: [
                      Icon(Icons.security_outlined,
                      color: theme.colorScheme.onSurface,
                      size: 20
                      ),
                      const SizedBox(width: 12),
                      const Text('Segurança'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'offers',

                  child: Row(
                    children: [
                      Icon(
                        Icons.local_offer_outlined,
                        color: theme.colorScheme.onSurface,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      const Text('Minhas Ofertas'),
                    ],
                  ),
                ),

              ],
              child: ValueListenableBuilder<String?>(
                valueListenable: UserState.profilePictureUrlNotifier,
                builder: (context, profileUrl, _) {
                  return CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    backgroundImage: profileUrl != null && profileUrl.isNotEmpty
                        ? NetworkImage(profileUrl)
                        : null,
                    child: profileUrl == null || profileUrl.isEmpty
                        ? Text(
                            _getInitials(displayName),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
