                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left: Logo
                        Row(
                          children: [
                            if (user == null)
                              IconButton(
                                onPressed: () async {
                                  print('Clearing public report cache...');
                                  await _cacheManager.clearLastViewedReport();
                                  print(
                                      'Public report cache cleared successfully');
                                  setState(() {
                                    _reportPage = null;
                                    searchController.clear();
                                    searchResults = [];
                                  });
                                  _hideSearchResults();
                                  context.go('/');
                                },
                                icon: const Icon(
                                  Icons.home,
                                  size: 24,
                                  color: Color(0xFF1E293B),
                                ),
                                tooltip: 'Home',
                              )
                            else if (_isMenuCollapsed)
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    _isMenuCollapsed = false;
                                  });
                                },
                                icon: const Icon(
                                  Icons.menu,
                                  size: 24,
                                  color: Color(0xFF1E293B),
                                ),
                                tooltip: 'Expand Menu',
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
                        ),
                        // Middle: Search Bar (only show when report is open)
                        if (_reportPage != null)
                          Expanded(
                            child: Center(
                              child: CustomSearchBar(
                                key: _searchBarKey,
                                controller: searchController,
                                focusNode: _searchFocusNode,
                                onChanged: _onSearchChanged,
                                hintText: 'Search for a company...',
                                onClear: () {
                                  searchController.clear();
                                  searchResults = [];
                                  setState(() {});
                                },
                              ),
                            ),
                          ),
                        // Right: Action Buttons
                        LayoutBuilder(
                          builder: (context, constraints) {
                            return Row(
                              children: [
                                if (user == null) ...[
                                  // Sign Up Button
                                  SizedBox(
                                    height: 40,
                                    child: OutlinedButton(
                                      onPressed: () {
                                        context.go('/signup');
                                      },
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
                                  ),
                                  const SizedBox(width: 12),
                                  // Sign In Button
                                  SizedBox(
                                    height: 40,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        context.go('/signin');
                                      },
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
                                  ),
                                ] else ...[
                                  // Membership Badge - Only show for paid plans and screen width > 500
                                  if (constraints.maxWidth > 500 && _currentSubscription.isPaid)
                                    Container(
                                      margin: const EdgeInsets.only(right: 12),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1E3A8A)
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFF1E3A8A)
                                              .withOpacity(0.2),
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
                                            '${_currentSubscription.value.toUpperCase()} PLAN',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1E3A8A),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  // Feedback Button
                                  Container(
                                    margin: const EdgeInsets.only(right: 12),
                                    child: IconButton(
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) =>
                                              const FeedbackPopup(),
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.feedback_outlined,
                                        size: 24,
                                        color: Color(0xFF1E293B),
                                      ),
                                      tooltip: 'Send Feedback',
                                    ),
                                  ),
                                  // User Menu
                                  Container(
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
                                      icon: user?.photoURL != null
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Image.network(
                                                user!.photoURL!,
                                                width: 40,
                                                height: 40,
                                                fit: BoxFit.cover,
                                                cacheWidth: 80,
                                                cacheHeight: 80,
                                                loadingBuilder: (context, child,
                                                    loadingProgress) {
                                                  if (loadingProgress == null)
                                                    return child;
                                                  return Container(
                                                    width: 40,
                                                    height: 40,
                                                    decoration: BoxDecoration(
                                                      color:
                                                          const Color(0xFFF1F5F9),
                                                      borderRadius:
                                                          BorderRadius.circular(20),
                                                    ),
                                                    child: const Icon(
                                                      Icons.person_outline,
                                                      size: 24,
                                                      color: Color(0xFF1E293B),
                                                    ),
                                                  );
                                                },
                                                errorBuilder:
                                                    (context, error, stackTrace) {
                                                  print(
                                                      'Error loading dropdown profile image: $error');
                                                  return Container(
                                                    width: 40,
                                                    height: 40,
                                                    decoration: BoxDecoration(
                                                      color:
                                                          const Color(0xFFF1F5F9),
                                                      borderRadius:
                                                          BorderRadius.circular(20),
                                                    ),
                                                    child: const Icon(
                                                      Icons.person_outline,
                                                      size: 24,
                                                      color: Color(0xFF1E293B),
                                                    ),
                                                  );
                                                },
                                              ),
                                            )
                                          : Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF1F5F9),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: const Icon(
                                                Icons.person_outline,
                                                size: 24,
                                                color: Color(0xFF1E293B),
                                              ),
                                            ),
                                      position: PopupMenuPosition.under,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      elevation: 4,
                                      color: Colors.white,
                                      itemBuilder: (BuildContext context) => [
                                        PopupMenuItem<String>(
                                          enabled: false,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 12),
                                          child: Row(
                                            children: [
                                              if (user?.photoURL != null)
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  child: Image.network(
                                                    user!.photoURL!,
                                                    width: 40,
                                                    height: 40,
                                                    fit: BoxFit.cover,
                                                    cacheWidth: 80,
                                                    cacheHeight: 80,
                                                    loadingBuilder: (context, child,
                                                        loadingProgress) {
                                                      if (loadingProgress == null)
                                                        return child;
                                                      return Container(
                                                        width: 40,
                                                        height: 40,
                                                        decoration: BoxDecoration(
                                                          color: const Color(
                                                              0xFFF1F5F9),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                  20),
                                                        ),
                                                        child: const Icon(
                                                          Icons.person_outline,
                                                          size: 24,
                                                          color: Color(0xFF1E293B),
                                                        ),
                                                      );
                                                    },
                                                    errorBuilder: (context, error,
                                                        stackTrace) {
                                                      print(
                                                          'Error loading dropdown profile image: $error');
                                                      return Container(
                                                        width: 40,
                                                        height: 40,
                                                        decoration: BoxDecoration(
                                                          color: const Color(
                                                              0xFFF1F5F9),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                  20),
                                                        ),
                                                        child: const Icon(
                                                          Icons.person_outline,
                                                          size: 24,
                                                          color: Color(0xFF1E293B),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                )
                                              else
                                                Container(
                                                  width: 40,
                                                  height: 40,
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFF1F5F9),
                                                    borderRadius:
                                                        BorderRadius.circular(20),
                                                  ),
                                                  child: const Icon(
                                                    Icons.person_outline,
                                                    size: 24,
                                                    color: Color(0xFF1E293B),
                                                  ),
                                                ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
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
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem<String>(
                                          value: 'upgrade',
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 12),
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
                                        ),
                                        PopupMenuItem<String>(
                                          value: 'settings',
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 12),
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
                                        ),
                                        PopupMenuItem<String>(
                                          value: 'signout',
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 12),
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
                                        ),
                                      ],
                                      onSelected: (String value) async {
                                        if (value == 'signout') {
                                          _handleSignOut();
                                        } else if (value == 'upgrade') {
                                          if (context.mounted) {
                                            context.push('/pricing');
                                          }
                                        } else if (value == 'settings') {
                                          if (context.mounted) {
                                            showDialog(
                                              context: context,
                                              builder: (context) => SettingsPopup(
                                                onLogout: _handleSignOut,
                                              ),
                                            );
                                          }
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                      ],
                    ), 