import 'package:flutter/material.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/services/auth.dart';
import 'package:frontend/pages/market/my_offers_page.dart';
import 'package:frontend/constants/colors.dart';

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
    final profileImageUrl = userData?.profileImageUrl;
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
                } else if (value == 'logout') {
                  await AuthService.signOut(context);
                }
              },
              itemBuilder: (context) => [
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
                PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(
                        Icons.logout,
                        color: theme.colorScheme.onSurface,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      const Text('Sair'),
                    ],
                  ),
                ),
              ],
              child: CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                backgroundImage: profileImageUrl != null
                    ? NetworkImage(profileImageUrl)
                    : null,
                child: profileImageUrl == null
                    ? Text(
                        _getInitials(displayName),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
