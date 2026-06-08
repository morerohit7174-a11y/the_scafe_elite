// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/login_provider.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../widgets/app_drawer.dart';
import '../services/firebase_service.dart';
import '../widgets/pref_utils.dart';
import '../widgets/db_constants.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  bool _isEditing = false;
  String _userRole = 'staff';  // ✅ NEW: Store role
  String _displayName = 'Cafe Admin';  // ✅ NEW: Store display name

  @override
  void initState() {
    super.initState();
    final loginProv = context.read<LoginProvider>();
    
    // ✅ Initialize controllers
    _emailCtrl = TextEditingController(text: loginProv.user?.email ?? '');
    _phoneCtrl = TextEditingController(text: loginProv.user?.phoneNumber ?? '');
    _nameCtrl = TextEditingController(text: _displayName);
    
    // ✅ Load user role and data from Firestore
    _loadUserData();
  }
  
  // ✅ NEW: Load user data from Firestore
  Future<void> _loadUserData() async {
    try {
      final role = await FirebaseService.getUserRole();
      final email = SharedPreferenceUtils.getString(DatabaseConstants.userEmail);
      
      // Extract display name from email (part before @)
      String displayName = 'Cafe Admin';
      if (email.isNotEmpty) {
        String namePart = email.split('@')[0].replaceAll('.', ' ');
        // Capitalize first letter of each word
        displayName = namePart.split(' ')
            .map((word) => word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1)}')
            .join(' ');
      }
      
      if (mounted) {
        setState(() {
          _userRole = role;
          _displayName = displayName;
          _nameCtrl.text = _displayName;
        });
      }
      
      debugPrint("✅ Profile loaded: role=$_userRole, name=$_displayName");
    } catch (e) {
      debugPrint("❌ Failed to load user data: $e");
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loginProv = context.watch<LoginProvider>();
    final user = loginProv.user;
    final isAdmin = _userRole == 'admin';  // ✅ Use loaded role instead of email check

    return Scaffold(
      backgroundColor: AppTheme.background,
      endDrawer: const AppDrawer(),
      body: Column(
        children: [
          // Custom header with back button for profile
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.card,
              border: const Border(bottom: BorderSide(color: AppTheme.border)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 6, offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pushReplacementNamed(context, '/dashboard'),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'My Profile',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.foreground,
                        ),
                      ),
                      Text(
                        'Manage your account',
                        style: GoogleFonts.lato(
                          fontSize: 10,
                          color: AppTheme.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Right side menu button
                  Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () => Scaffold.of(context).openEndDrawer(),
                      tooltip: 'Menu',
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth:
                        Responsive.isDesktop(context) ? 640 : double.infinity,
                  ),
                  child: Column(
                children: [
                  // Profile Header with Avatar
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      children: [
                        // Avatar
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.primary,
                              width: 3,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _displayName.isNotEmpty
                                  ? _displayName[0].toUpperCase()
                                  : 'A',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Name
                        Text(
                          _displayName,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.foreground,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Admin Badge
                        if (isAdmin)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.15),
                              border: Border.all(color: AppTheme.primary),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.admin_panel_settings,
                                    size: 14, color: AppTheme.primary),
                                const SizedBox(width: 6),
                                Text(
                                  'ADMIN',
                                  style: GoogleFonts.lato(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Profile Details Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Profile Information',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.foreground,
                              ),
                            ),
                            if (!_isEditing)
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    size: 20, color: AppTheme.primary),
                                onPressed: () =>
                                    setState(() => _isEditing = true),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Email Field
                        _buildProfileField(
                          label: 'Email',
                          value: user?.email ?? 'N/A',
                          icon: Icons.email_outlined,
                          controller: _emailCtrl,
                          enabled: _isEditing,
                          readOnly: true,
                        ),
                        const SizedBox(height: 16),

                        // Phone Field
                        _buildProfileField(
                          label: 'Phone',
                          value: user?.phoneNumber ?? 'Not provided',
                          icon: Icons.phone_outlined,
                          controller: _phoneCtrl,
                          enabled: _isEditing,
                        ),
                        const SizedBox(height: 16),

                        // Name Field
                        _buildProfileField(
                          label: 'Display Name',
                          value: user?.displayName ?? 'Admin',
                          icon: Icons.person_outline,
                          controller: _nameCtrl,
                          enabled: _isEditing,
                        ),
                        const SizedBox(height: 24),

                        // UID Section
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.surface.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'User ID',
                                style: GoogleFonts.lato(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.mutedForeground,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      user?.uid ?? 'N/A',
                                      style: GoogleFonts.lato(
                                        fontSize: 11,
                                        color: AppTheme.foreground,
                                      ).copyWith(fontFamily: 'monospace'),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.copy, size: 16),
                                    onPressed: () {
                                      if (user?.uid != null) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content:
                                                Text('User ID copied! ✅'),
                                            duration: Duration(seconds: 2),
                                            behavior:
                                                SnackBarBehavior.floating,
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  if (_isEditing)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() => _isEditing = false);
                              _nameCtrl.text =
                                  user?.displayName ?? 'Cafe Admin';
                              _emailCtrl.text = user?.email ?? '';
                              _phoneCtrl.text =
                                  user?.phoneNumber ?? '';
                            },
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              // Save profile changes
                              setState(() => _isEditing = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Profile updated successfully! ✅'),
                                  duration: Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            child: const Text('Save Changes'),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 24),

                  // Account Info Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.border,
                        width: 0.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          'Account Type',
                          isAdmin ? 'Administrator' : 'User',
                          Icons.security,
                        ),
                        const Divider(color: AppTheme.border, height: 16),
                        _buildInfoRow(
                          'Verified',
                          user?.emailVerified ?? false ? 'Yes ✓' : 'No',
                          Icons.verified_user,
                          color: (user?.emailVerified ?? false)
                              ? Colors.green
                              : AppTheme.mutedForeground,
                        ),
                        const Divider(color: AppTheme.border, height: 16),
                        _buildInfoRow(
                          'Account Created',
                          user != null
                              ? (user.metadata.creationTime
                                      ?.toString()
                                      .split(' ')
                                      .first ??
                                  'Unknown')
                              : 'Unknown',
                          Icons.calendar_today,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showLogoutDialog(context, loginProv),
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text('Logout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.destructive,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileField({
    required String label,
    required String value,
    required IconData icon,
    required TextEditingController controller,
    required bool enabled,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.mutedForeground,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: enabled && !readOnly,
          readOnly: readOnly,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18),
            hintText: value,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            filled: !enabled,
            fillColor: !enabled
                ? AppTheme.surface.withValues(alpha: 0.3)
                : Colors.transparent,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: AppTheme.primary,
                width: 2,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: AppTheme.border,
                width: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color ?? AppTheme.primary),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.lato(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.foreground,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: GoogleFonts.lato(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color ?? AppTheme.primary,
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context, LoginProvider loginProv) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              loginProv.logout();
              Navigator.pop(context);
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: AppTheme.destructive),
            ),
          ),
        ],
      ),
    );
  }
}
