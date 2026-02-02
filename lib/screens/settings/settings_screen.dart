import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/language_selector.dart';
import '../../widgets/voice_settings_widget.dart';
import '../../l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _voiceInputEnabled = false;
  bool _darkModeEnabled = false;
  bool _locationTrackingEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                AnimationConfiguration.staggeredList(
                  position: 0,
                  duration: const Duration(milliseconds: 600),
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(child: _buildHeader()),
                  ),
                ),

                const SizedBox(height: 24),

                // General Settings
                AnimationConfiguration.staggeredList(
                  position: 1,
                  duration: const Duration(milliseconds: 600),
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: _buildSettingsSection(
                        AppLocalizations.of(context)?.general ?? 'General', 
                        Icons.settings, [
                        _buildLanguageSetting(),
                        _buildNotificationSetting(),
                        _buildDarkModeSetting(),
                      ]),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Privacy Settings
                AnimationConfiguration.staggeredList(
                  position: 2,
                  duration: const Duration(milliseconds: 600),
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: _buildSettingsSection(
                        AppLocalizations.of(context)?.privacySecurity ?? 'Privacy & Security',
                        Icons.security,
                        [
                          _buildLocationTrackingSetting(),
                          _buildDataUsageSetting(),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Accessibility Settings
                AnimationConfiguration.staggeredList(
                  position: 3,
                  duration: const Duration(milliseconds: 600),
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: _buildSettingsSection(
                        AppLocalizations.of(context)?.accessibility ?? 'Accessibility',
                        Icons.accessibility,
                        [
                          VoiceSettingsWidget(
                            voiceInputEnabled: _voiceInputEnabled,
                            onVoiceInputChanged: (value) {
                              setState(() {
                                _voiceInputEnabled = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Account Section
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    if (!authProvider.isGuest) {
                      return Column(
                        children: [
                          AnimationConfiguration.staggeredList(
                            position: 4,
                            duration: const Duration(milliseconds: 600),
                            child: SlideAnimation(
                              verticalOffset: 50.0,
                              child: FadeInAnimation(
                                child: _buildSettingsSection('Account', Icons.account_circle, [
                                  ListTile(
                                    leading: const Icon(Icons.logout, color: Colors.red),
                                    title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
                                    onTap: () async {
                                      final confirmed = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Sign Out'),
                                          content: const Text('Are you sure you want to sign out?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, false),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, true),
                                              child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
                                            ),
                                          ],
                                        ),
                                      );
                                      
                                      if (confirmed == true) {
                                        await authProvider.signOut();
                                      }
                                    },
                                  ),
                                ]),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

                // About Section
                AnimationConfiguration.staggeredList(
                  position: 5,
                  duration: const Duration(milliseconds: 600),
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: _buildSettingsSection('About', Icons.info, [
                        _buildAboutItem(
                          'App Version',
                          '1.0.0',
                          Icons.info_outline,
                        ),
                        _buildAboutItem(
                          'Terms of Service',
                          '',
                          Icons.description,
                        ),
                        _buildAboutItem(
                          'Privacy Policy',
                          '',
                          Icons.privacy_tip,
                        ),
                        _buildAboutItem(
                          'Contact Support',
                          '',
                          Icons.support_agent,
                        ),
                      ]),
                    ),
                  ),
                ),

                const SizedBox(height: 100), // Space for bottom navigation
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;
        final userName = user?.name ?? 'Guest User';
        final userEmail = user?.email ?? 'guest@example.com';
        
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                backgroundImage: user?.profileImage != null 
                    ? NetworkImage(user!.profileImage!) 
                    : null,
                child: user?.profileImage == null 
                    ? Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userEmail,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (!authProvider.isGuest)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${user?.points ?? 0} Points',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingsSection(
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSetting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const LanguageSelector(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildNotificationSetting() {
    return _buildSwitchSetting(
      AppLocalizations.of(context)?.notifications ?? 'Notifications',
      AppLocalizations.of(context)?.receiveUpdates ?? 'Receive updates about your reported issues',
      Icons.notifications,
      _notificationsEnabled,
      (value) {
        setState(() {
          _notificationsEnabled = value;
        });
      },
    );
  }

  Widget _buildDarkModeSetting() {
    return _buildSwitchSetting(
      AppLocalizations.of(context)?.darkMode ?? 'Dark Mode',
      AppLocalizations.of(context)?.useDarkTheme ?? 'Use dark theme throughout the app',
      Icons.dark_mode,
      _darkModeEnabled,
      (value) {
        setState(() {
          _darkModeEnabled = value;
        });
      },
    );
  }

  Widget _buildLocationTrackingSetting() {
    return _buildSwitchSetting(
      AppLocalizations.of(context)?.locationTracking ?? 'Location Tracking',
      AppLocalizations.of(context)?.allowLocationAccess ?? 'Allow location access for issue reporting',
      Icons.location_on,
      _locationTrackingEnabled,
      (value) {
        setState(() {
          _locationTrackingEnabled = value;
        });
      },
    );
  }

  Widget _buildDataUsageSetting() {
    return _buildListTile(
      'Data Usage',
      'Manage how the app uses your data',
      Icons.data_usage,
      () {
        // Navigate to data usage settings
      },
    );
  }

  Widget _buildAboutItem(String title, String subtitle, IconData icon) {
    return _buildListTile(title, subtitle, icon, () {
      // Handle about item tap
    });
  }

  Widget _buildSwitchSetting(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        title: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: subtitle.isNotEmpty
            ? Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              )
            : null,
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
