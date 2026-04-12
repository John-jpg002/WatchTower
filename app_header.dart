// lib/widgets/app_header.dart
import 'package:flutter/material.dart';
import '../utils/constants.dart';

class WatchtowerAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  const WatchtowerAppBar({super.key, this.title = ''});

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.headerBlue.withOpacity(0.85),
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cyanDark,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.remove_red_eye,
              color: AppColors.cyan, size: 22),
        ),
      ),
      actions: [
        Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: AppColors.textPrimary),
            onPressed: () => Scaffold.of(context).openEndDrawer(),
          ),
        ),
      ],
    );
  }
}
