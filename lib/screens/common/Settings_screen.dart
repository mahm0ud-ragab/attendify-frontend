// Adaptive Settings Screen with Multi-Language Support ⚙️✨
// Automatically adapts to Blue (Student) or Purple (Lecturer)

import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../services/localization_service.dart';
import '../../main.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  final bool isLecturer;

  const SettingsScreen({
    super.key,
    required this.isLecturer,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _apiService = ApiService();
  final _storageService = StorageService();

  bool _notificationsEnabled = true;
  bool _biometricsEnabled = false;
  bool _isLoading = false;

  // Language options
  final List<LanguageOption> _languages = [
    LanguageOption('English', 'en', '🇬🇧'),
    LanguageOption('العربية', 'ar', '🇸🇦'),
    LanguageOption('Français', 'fr', '🇫🇷'),
    LanguageOption('Español', 'es', '🇪🇸'),
    LanguageOption('Deutsch', 'de', '🇩🇪'),
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // Load saved settings from storage
  Future<void> _loadSettings() async {
    try {
      final notificationPref = await _storageService.getBool('notifications_enabled');
      final biometricPref = await _storageService.getBool('biometrics_enabled');

      if (mounted) {
        setState(() {
          _notificationsEnabled = notificationPref ?? true;
          _biometricsEnabled = biometricPref ?? false;
        });
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  // Save settings to storage
  Future<void> _saveNotificationSetting(bool value) async {
    try {
      await _storageService.setBool('notifications_enabled', value);
      setState(() => _notificationsEnabled = value);
    } catch (e) {
      _showErrorSnackBar(context.loc?.error ?? 'Failed to save notification setting');
    }
  }

  Future<void> _saveBiometricSetting(bool value) async {
    try {
      await _storageService.setBool('biometrics_enabled', value);
      setState(() => _biometricsEnabled = value);
    } catch (e) {
      _showErrorSnackBar(context.loc?.error ?? 'Failed to save biometric setting');
    }
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await _showLogoutDialog();

    if (shouldLogout == true) {
      setState(() => _isLoading = true);

      try {
        await _apiService.logout();
        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
        );
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          _showErrorSnackBar(context.loc?.error ?? 'Logout failed. Please try again.');
        }
      }
    }
  }

  Future<bool?> _showLogoutDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => _LogoutDialog(
        isLecturer: widget.isLecturer,
      ),
    );
  }

  void _showLanguageDialog() {
    final currentLocale = MyApp.getLocale(context);

    showDialog(
      context: context,
      builder: (context) => _LanguageDialog(
        languages: _languages,
        currentLocaleCode: currentLocale?.languageCode ?? 'en',
        onLanguageSelected: (locale) {
          MyApp.setLocale(context, locale);
          Navigator.pop(context);
          _showSuccessSnackBar(context.loc?.success ?? 'Language changed successfully');
        },
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = _SettingsTheme.fromRole(widget.isLecturer);
    final loc = context.loc;

    return Scaffold(
      body: Stack(
        children: [
          // Gradient Background
          _GradientBackground(gradientColors: theme.gradientColors),

          // Pattern Overlay
             Positioned.fill(
            child: CustomPaint(painter: _CirclePatternPainter()),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                _buildHeader(loc),
                Expanded(
                  child: _buildContent(theme, loc),
                ),
              ],
            ),
          ),

          // Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(AppLocalizations? loc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Row(
        children: [
          _GlassIconButton(
            icon: Icons.arrow_back,
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(width: 16),
          Text(
            loc?.settings ?? 'Settings',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(_SettingsTheme theme, AppLocalizations? loc) {
    final currentLocale = MyApp.getLocale(context);
    final currentLanguage = _languages.firstWhere(
          (lang) => lang.code == (currentLocale?.languageCode ?? 'en'),
      orElse: () => _languages[0],
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // General Section
          _SettingsSectionHeader(title: loc?.general ?? 'GENERAL'),
          const SizedBox(height: 10),
          _GlassContainer(
            children: [
              _SettingsSwitchTile(
                title: loc?.notifications ?? 'Notifications',
                subtitle: loc?.notificationsSubtitle ?? 'Receive attendance alerts',
                value: _notificationsEnabled,
                onChanged: _saveNotificationSetting,
                icon: Icons.notifications_active_rounded,
                theme: theme,
              ),
              _SettingsDivider(),
              _SettingsSwitchTile(
                title: loc?.biometricLogin ?? 'Biometric Login',
                subtitle: loc?.biometricSubtitle ?? 'Use FaceID / Fingerprint',
                value: _biometricsEnabled,
                onChanged: _saveBiometricSetting,
                icon: Icons.fingerprint_rounded,
                theme: theme,
              ),
              _SettingsDivider(),
              _SettingsActionTile(
                title: loc?.language ?? 'Language',
                subtitle: currentLanguage.name,
                icon: Icons.language_rounded,
                onTap: _showLanguageDialog,
                theme: theme,
                trailing: Text(
                  currentLanguage.flag,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Support Section
          _SettingsSectionHeader(title: loc?.support ?? 'SUPPORT'),
          const SizedBox(height: 10),
          _GlassContainer(
            children: [
              _SettingsActionTile(
                title: loc?.helpCenter ?? 'Help Center',
                icon: Icons.help_outline_rounded,
                onTap: () => _showComingSoon(loc?.helpCenter ?? 'Help Center'),
                theme: theme,
              ),
              _SettingsDivider(),
              _SettingsActionTile(
                title: loc?.reportIssue ?? 'Report an Issue',
                icon: Icons.bug_report_rounded,
                onTap: () => _showComingSoon(loc?.reportIssue ?? 'Issue Reporting'),
                theme: theme,
              ),
              _SettingsDivider(),
              _SettingsActionTile(
                title: loc?.aboutApp ?? 'About Attendify',
                icon: Icons.info_outline_rounded,
                onTap: () => _showAboutDialog(loc),
                theme: theme,
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Logout Button
          _LogoutButton(
            onPressed: _handleLogout,
            isLoading: _isLoading,
            text: loc?.logout ?? 'Logout',
          ),

          const SizedBox(height: 20),
          Center(
            child: Text(
              '${loc?.version ?? 'Version'} 1.0.0',
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showAboutDialog(AppLocalizations? loc) {
    showAboutDialog(
      context: context,
      applicationName: 'Attendify',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2024 Attendify. All rights reserved.',
      applicationIcon: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: widget.isLecturer ? Colors.deepPurple : Colors.blue,
        ),
        child: const Icon(Icons.check_circle, color: Colors.white, size: 30),
      ),
    );
  }
}

// ============================================================================
// Language Option Model
// ============================================================================

class LanguageOption {
  final String name;
  final String code;
  final String flag;

  LanguageOption(this.name, this.code, this.flag);
}

// ============================================================================
// Theme Configuration
// ============================================================================

class _SettingsTheme {
  final List<Color> gradientColors;
  final Color accentColor;
  final Color iconColor;
  final Color activeToggleColor;

  const _SettingsTheme({
    required this.gradientColors,
    required this.accentColor,
    required this.iconColor,
    required this.activeToggleColor,
  });

  factory _SettingsTheme.fromRole(bool isLecturer) {
    if (isLecturer) {
      return _SettingsTheme(
        gradientColors: [
          Colors.deepPurple.shade900,
          Colors.deepPurple.shade800,
          Colors.purple.shade700,
        ],
        accentColor: Colors.deepPurple.shade100,
        iconColor: Colors.deepPurple.shade700,
        activeToggleColor: Colors.purpleAccent,
      );
    } else {
      return _SettingsTheme(
        gradientColors: [
          Colors.blue.shade700,
          Colors.blue.shade600,
          Colors.lightBlue.shade500,
        ],
        accentColor: Colors.lightBlue.shade100,
        iconColor: Colors.blue.shade700,
        activeToggleColor: Colors.cyanAccent,
      );
    }
  }
}

// ============================================================================
// Reusable Widgets
// ============================================================================

class _GradientBackground extends StatelessWidget {
  final List<Color> gradientColors;

  const _GradientBackground({required this.gradientColors});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
      ),
    );
  }
}

class _SettingsSectionHeader extends StatelessWidget {
  final String title;

  const _SettingsSectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _GlassContainer extends StatelessWidget {
  final List<Widget> children;

  const _GlassContainer({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final Function(bool) onChanged;
  final IconData icon;
  final _SettingsTheme theme;

  const _SettingsSwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.icon,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeColor: theme.activeToggleColor,
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey[600], fontSize: 13),
      ),
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.accentColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: theme.iconColor),
      ),
    );
  }
}

class _SettingsActionTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final _SettingsTheme theme;
  final Widget? trailing;

  const _SettingsActionTile({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.onTap,
    required this.theme,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.accentColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: theme.iconColor),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      subtitle: subtitle != null
          ? Text(
        subtitle!,
        style: TextStyle(color: Colors.grey[600], fontSize: 13),
      )
          : null,
      trailing: trailing ??
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: Colors.grey,
          ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, color: Colors.grey.withOpacity(0.2));
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;
  final String text;

  const _LogoutButton({
    required this.onPressed,
    required this.isLoading,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.withOpacity(0.2),
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.withOpacity(0.2),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isLoading
                  ? Colors.grey.withOpacity(0.3)
                  : Colors.red.withOpacity(0.5),
            ),
          ),
        ),
        child: isLoading
            ? const SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.redAccent),
          ),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded, color: Colors.redAccent),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoutDialog extends StatelessWidget {
  final bool isLecturer;

  const _LogoutDialog({required this.isLecturer});

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(loc?.logout ?? 'Logout'),
      content: Text(loc?.logoutConfirm ?? 'Are you sure you want to log out?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(loc?.cancel ?? 'Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            backgroundColor: isLecturer
                ? Colors.deepPurple.shade600
                : Colors.lightBlue.shade600,
          ),
          child: Text(loc?.logout ?? 'Logout'),
        ),
      ],
    );
  }
}

class _LanguageDialog extends StatelessWidget {
  final List<LanguageOption> languages;
  final String currentLocaleCode;
  final Function(Locale) onLanguageSelected;

  const _LanguageDialog({
    required this.languages,
    required this.currentLocaleCode,
    required this.onLanguageSelected,
  });

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(loc?.selectLanguage ?? 'Select Language'),
      contentPadding: const EdgeInsets.symmetric(vertical: 20),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: languages.length,
          itemBuilder: (context, index) {
            final language = languages[index];
            final isSelected = language.code == currentLocaleCode;

            return ListTile(
              leading: Text(
                language.flag,
                style: const TextStyle(fontSize: 28),
              ),
              title: Text(
                language.name,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              trailing: isSelected
                  ? Icon(Icons.check_circle, color: Colors.green.shade600)
                  : null,
              onTap: () => onLanguageSelected(Locale(language.code)),
            );
          },
        ),
      ),
    );
  }
}

// ============================================================================
// Background Pattern Painter
// ============================================================================

class _CirclePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.2), 60, paint);
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.8), 45, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}