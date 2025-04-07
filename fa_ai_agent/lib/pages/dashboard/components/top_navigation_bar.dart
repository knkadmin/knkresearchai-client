import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:go_router/go_router.dart';
import 'package:fa_ai_agent/models/subscription_type.dart';
import 'package:fa_ai_agent/widgets/settings_popup.dart';
import 'package:fa_ai_agent/widgets/custom_search_bar.dart';
import 'package:fa_ai_agent/widgets/feedback_popup.dart';

class TopNavigationBar extends StatelessWidget {
  final auth.User? user;
  final bool isMenuCollapsed;
  final VoidCallback onMenuToggle;
  final SubscriptionType currentSubscription;
  final VoidCallback onSignOut;
  final Widget? reportPage;
  final GlobalKey searchBarKey;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final Function(String) onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onClearReportView;

  const TopNavigationBar({
    super.key,
    required this.user,
    required this.isMenuCollapsed,
    required this.onMenuToggle,
    required this.currentSubscription,
    required this.onSignOut,
    required this.reportPage,
    required this.searchBarKey,
    required this.searchController,
    required this.searchFocusNode,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onClearReportView,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 65,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.black.withOpacity(0.05),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildLeftSection(context),
          if (reportPage != null) _buildSearchBar(),
          _buildRightSection(context),
        ],
      ),
    );
  }

  Widget _buildLeftSection(BuildContext context) {
    return Row(
      children: [
        if (user == null)
          IconButton(
            onPressed: () {
              if (context.mounted) {
                onClearReportView();
                context.go('/');
              }
            },
            icon: const Icon(
              Icons.home,
              size: 24,
              color: Color(0xFF1E293B),
            ),
            tooltip: 'Home',
          )
        else if (MediaQuery.of(context).size.width < 850 || isMenuCollapsed)
          IconButton(
            onPressed: onMenuToggle,
            icon: const Icon(
              Icons.menu,
              size: 24,
              color: Color(0xFF1E293B),
            ),
            tooltip: 'Toggle Menu',
          ),
        const SizedBox(width: 12),
        const Text(
          'KNK Research AI',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Expanded(
      child: Center(
        child: CustomSearchBar(
          key: searchBarKey,
          controller: searchController,
          focusNode: searchFocusNode,
          onChanged: onSearchChanged,
          hintText: 'Search for a company...',
          onClear: onClearSearch,
        ),
      ),
    );
  }

  Widget _buildRightSection(BuildContext context) {
    return Row(
      children: [
        if (user == null) ...[
          _buildSignUpButton(context),
          const SizedBox(width: 12),
          _buildSignInButton(context),
        ] else ...[
          if (MediaQuery.of(context).size.width > 1000 &&
              currentSubscription.isPaid)
            _buildMembershipBadge(),
          _buildFeedbackButton(context),
          _buildUserMenu(context),
        ],
      ],
    );
  }

  Widget _buildSignUpButton(BuildContext context) {
    return SizedBox(
      height: 40,
      child: OutlinedButton(
        onPressed: () => context.go('/signup'),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF1E2C3D),
          side: const BorderSide(
            color: Color(0xFF1E2C3D),
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text(
          'Sign Up',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSignInButton(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ElevatedButton(
        onPressed: () => context.go('/signin'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF2563EB),
                Color(0xFF1E40AF),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Container(
            width: 100,
            height: 40,
            alignment: Alignment.center,
            child: const Text(
              'Sign In',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMembershipBadge() {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A8A).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF1E3A8A).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.workspace_premium,
            size: 16,
            color: Color(0xFF1E3A8A),
          ),
          const SizedBox(width: 6),
          Text(
            '${currentSubscription.value.toUpperCase()} PLAN',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A8A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: IconButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const FeedbackPopup(),
          );
        },
        icon: const Icon(
          Icons.feedback_outlined,
          size: 24,
          color: Color(0xFF1E293B),
        ),
        tooltip: 'Send Feedback',
      ),
    );
  }

  Widget _buildUserMenu(BuildContext context) {
    final userName = user?.displayName ?? user?.email?.split('@')[0] ?? 'User';
    final userEmail = user?.email ?? '';

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.black.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: PopupMenuButton<String>(
        icon: _buildUserAvatar(),
        position: PopupMenuPosition.under,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 4,
        color: Colors.white,
        itemBuilder: (BuildContext context) => [
          _buildUserInfoMenuItem(context, userName, userEmail),
          _buildUpgradeMenuItem(),
          _buildSettingsMenuItem(),
          _buildSignOutMenuItem(),
        ],
        onSelected: (String value) async {
          if (value == 'signout') {
            onSignOut();
          } else if (value == 'upgrade') {
            if (context.mounted) {
              context.push('/pricing');
            }
          } else if (value == 'settings') {
            if (context.mounted) {
              showDialog(
                context: context,
                builder: (context) => SettingsPopup(
                  onLogout: onSignOut,
                ),
              );
            }
          }
        },
      ),
    );
  }

  Widget _buildUserAvatar() {
    return user?.photoURL != null
        ? ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              user!.photoURL!,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              cacheWidth: 80,
              cacheHeight: 80,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return _buildDefaultAvatar();
              },
              errorBuilder: (context, error, stackTrace) {
                print('Error loading dropdown profile image: $error');
                return _buildDefaultAvatar();
              },
            ),
          )
        : _buildDefaultAvatar();
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Icon(
        Icons.person_outline,
        size: 24,
        color: Color(0xFF1E293B),
      ),
    );
  }

  PopupMenuItem<String> _buildUserInfoMenuItem(
      BuildContext context, String userName, String userEmail) {
    return PopupMenuItem<String>(
      enabled: false,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildUserAvatar(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userEmail,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),
                if (MediaQuery.of(context).size.width <= 1000 &&
                    currentSubscription.isPaid)
                  _buildMobileMembershipBadge(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileMembershipBadge() {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF1E3A8A).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF1E3A8A).withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.workspace_premium,
              size: 14,
              color: Color(0xFF1E3A8A),
            ),
            const SizedBox(width: 4),
            Text(
              '${currentSubscription.value.toUpperCase()} PLAN',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A8A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildUpgradeMenuItem() {
    return PopupMenuItem<String>(
      value: 'upgrade',
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: const Row(
        children: [
          Icon(
            Icons.workspace_premium,
            size: 20,
            color: Color(0xFF1E293B),
          ),
          SizedBox(width: 8),
          Text(
            'Upgrade Plan',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildSettingsMenuItem() {
    return PopupMenuItem<String>(
      value: 'settings',
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: const Row(
        children: [
          Icon(
            Icons.settings,
            size: 20,
            color: Color(0xFF1E293B),
          ),
          SizedBox(width: 8),
          Text(
            'Settings',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildSignOutMenuItem() {
    return PopupMenuItem<String>(
      value: 'signout',
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: const Row(
        children: [
          Icon(
            Icons.logout,
            size: 20,
            color: Color(0xFF1E293B),
          ),
          SizedBox(width: 8),
          Text(
            'Sign Out',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }
}
