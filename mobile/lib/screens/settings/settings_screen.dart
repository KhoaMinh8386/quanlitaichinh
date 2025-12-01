import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.settings),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildProfileSection(context, user),
            const SizedBox(height: 24),
          _buildSettingsSection(
            context,
            'Tài khoản',
            [
              _buildSettingsTile(
                icon: Icons.person_outline,
                title: AppStrings.profile,
                onTap: () {},
              ),
              _buildSettingsTile(
                icon: Icons.lock_outline,
                title: AppStrings.changePassword,
                onTap: () {},
              ),
            ],
          ),
            const SizedBox(height: 16),
            _buildSettingsSection(
              context,
              'Giao diện',
              [
                _buildSettingsTile(
                  icon: isDark ? Icons.dark_mode : Icons.light_mode,
                  title: 'Chế độ tối',
                  trailing: Switch(
                    value: isDark,
                    onChanged: (value) {
                      ref.read(themeModeProvider.notifier).toggleTheme();
                    },
                    activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
                    activeThumbColor: AppColors.primary,
                  ),
                  onTap: null,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSettingsSection(
              context,
              'Tùy chỉnh',
              [
                _buildSettingsTile(
                  icon: Icons.language,
                  title: AppStrings.language,
                  trailing: const Text('Tiếng Việt'),
                  onTap: () {},
                ),
                _buildSettingsTile(
                  icon: Icons.attach_money,
                  title: AppStrings.currency,
                  trailing: const Text('VND'),
                  onTap: () {},
                ),
                _buildSettingsTile(
                  icon: Icons.notifications_none,
                  title: AppStrings.notifications,
                  trailing: Switch(
                    value: true,
                    onChanged: (value) {},
                    activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
                    activeThumbColor: AppColors.primary,
                  ),
                  onTap: null,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSettingsSection(
              context,
              'Khác',
              [
                _buildSettingsTile(
                  icon: Icons.info_outline,
                  title: AppStrings.about,
                  onTap: () => _showAboutDialog(context),
                ),
                _buildSettingsTile(
                  icon: Icons.logout,
                  title: AppStrings.logout,
                  titleColor: AppColors.error,
                  onTap: () => _showLogoutDialog(context, ref),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context, user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(
              Icons.person,
              size: 32,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.fullName ?? 'User',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    Widget? trailing,
    Color? titleColor,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: titleColor ?? AppColors.textPrimary),
      title: Text(
        title,
        style: TextStyle(
          color: titleColor ?? AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: trailing ??
          (onTap != null
              ? const Icon(Icons.arrow_forward_ios, size: 16)
              : null),
      onTap: onTap,
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(AppStrings.about),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.appName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text('Phiên bản: 1.0.0'),
              SizedBox(height: 16),
              Text(
                'Ứng dụng quản lý tài chính cá nhân thông minh với tính năng tự động đồng bộ, phân tích chi tiêu và dự báo tài chính.',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(AppStrings.logout),
          content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(AppStrings.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                await ref.read(authStateProvider.notifier).logout();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
              ),
              child: const Text(AppStrings.logout),
            ),
          ],
        );
      },
    );
  }
}
